package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"orthotrack-iot-v3/internal/models"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type AlertService struct {
	db    *gorm.DB
	redis *redis.Client
	dashboardStatsService *DashboardStatsService
}

func NewAlertService(db *gorm.DB, redis *redis.Client) *AlertService {
	return &AlertService{
		db:    db,
		redis: redis,
	}
}

func (s *AlertService) SetDashboardStatsService(dashboardStatsService *DashboardStatsService) {
	s.dashboardStatsService = dashboardStatsService
}

func (s *AlertService) GetDB() *gorm.DB {
	return s.db
}

// CreateAlert cria um novo alerta se não existir um similar recente
func (s *AlertService) CreateAlert(ctx context.Context, alert *models.Alert) error {
	// Verificar se já existe um alerta similar não resolvido nas últimas 2 horas
	cutoff := time.Now().Add(-2 * time.Hour)
	
	var existingAlert models.Alert
	err := s.db.Where(
		"brace_id = ? AND type = ? AND resolved = false AND created_at > ?", 
		alert.BraceID, alert.Type, cutoff,
	).First(&existingAlert).Error

	if err == nil {
		// Alerta similar já existe, apenas atualizar valor se necessário
		if alert.Value != nil {
			existingAlert.Value = alert.Value
			existingAlert.UpdatedAt = time.Now()
			return s.db.Save(&existingAlert).Error
		}
		return nil
	}

	if err != gorm.ErrRecordNotFound {
		return fmt.Errorf("error checking existing alerts: %v", err)
	}

	// Criar novo alerta
	if err := s.db.Create(alert).Error; err != nil {
		return fmt.Errorf("error creating alert: %v", err)
	}

	log.Printf("Alert created: %s for device %v", alert.Title, alert.BraceID)

	// Cache do alerta
	s.cacheAlert(ctx, alert)

	// Publicar alerta em tempo real
	s.publishAlertRealtime(ctx, alert)

	// Processar notificações
	go s.processAlertNotifications(ctx, alert)

	// Trigger dashboard stats recalculation on alert creation
	if s.dashboardStatsService != nil {
		// Get institution ID from patient if available
		var institutionID *uint
		if alert.PatientID != nil {
			var patient models.Patient
			if err := s.db.Select("institution_id").First(&patient, *alert.PatientID).Error; err == nil {
				institutionID = &patient.InstitutionID
			}
		}
		s.dashboardStatsService.RecalculateStatsOnAlertChange(ctx, institutionID)
	}

	return nil
}

// GetAlerts retorna alertas com filtros opcionais
func (s *AlertService) GetAlerts(ctx context.Context, filters AlertFilters) ([]models.Alert, error) {
	query := s.db.Preload("Patient").Preload("Brace")

	if filters.PatientID != nil {
		query = query.Where("patient_id = ?", *filters.PatientID)
	}

	if filters.BraceID != nil {
		query = query.Where("brace_id = ?", *filters.BraceID)
	}

	if filters.Type != "" {
		query = query.Where("type = ?", filters.Type)
	}

	if filters.Severity != "" {
		query = query.Where("severity = ?", filters.Severity)
	}

	if filters.Resolved != nil {
		query = query.Where("resolved = ?", *filters.Resolved)
	}

	if !filters.StartDate.IsZero() {
		query = query.Where("created_at >= ?", filters.StartDate)
	}

	if !filters.EndDate.IsZero() {
		query = query.Where("created_at <= ?", filters.EndDate)
	}

	// Ordenação
	query = query.Order("created_at DESC")

	// Paginação
	if filters.Limit > 0 {
		query = query.Limit(filters.Limit)
	}

	if filters.Offset > 0 {
		query = query.Offset(filters.Offset)
	}

	var alerts []models.Alert
	err := query.Find(&alerts).Error
	
	return alerts, err
}

// ResolveAlert resolve um alerta
func (s *AlertService) ResolveAlert(ctx context.Context, alertID uint, resolvedBy *uint, notes string) error {
	var alert models.Alert
	if err := s.db.First(&alert, alertID).Error; err != nil {
		return fmt.Errorf("alert not found: %v", err)
	}

	if alert.Resolved {
		return fmt.Errorf("alert already resolved")
	}

	alert.Resolve(resolvedBy, notes)

	if err := s.db.Save(&alert).Error; err != nil {
		return fmt.Errorf("error resolving alert: %v", err)
	}

	log.Printf("Alert %d resolved by user %v", alertID, resolvedBy)

	// Limpar do cache de alertas ativos
	s.clearAlertCache(ctx, &alert)

	// Publicar resolução em tempo real
	s.publishAlertResolved(ctx, &alert)

	// Trigger dashboard stats recalculation on alert resolution
	if s.dashboardStatsService != nil {
		// Get institution ID from patient if available
		var institutionID *uint
		if alert.PatientID != nil {
			var patient models.Patient
			if err := s.db.Select("institution_id").First(&patient, *alert.PatientID).Error; err == nil {
				institutionID = &patient.InstitutionID
			}
		}
		s.dashboardStatsService.RecalculateStatsOnAlertChange(ctx, institutionID)
	}

	return nil
}

// GetActiveAlerts retorna alertas não resolvidos
func (s *AlertService) GetActiveAlerts(ctx context.Context) ([]models.Alert, error) {
	// Tentar buscar do cache primeiro
	cacheKey := "alerts:active"
	cached, err := s.redis.Get(ctx, cacheKey).Result()
	
	if err == nil {
		var alerts []models.Alert
		if err := json.Unmarshal([]byte(cached), &alerts); err == nil {
			return alerts, nil
		}
	}

	// Buscar do banco
	var alerts []models.Alert
	err = s.db.Preload("Patient").Preload("Brace").
		Where("resolved = false").
		Order("severity DESC, created_at DESC").
		Find(&alerts).Error

	if err != nil {
		return nil, err
	}

	// Cache por 5 minutos
	if alertsJSON, err := json.Marshal(alerts); err == nil {
		s.redis.Set(ctx, cacheKey, alertsJSON, 5*time.Minute)
	}

	return alerts, nil
}

// GetAlertStatistics retorna estatísticas de alertas
func (s *AlertService) GetAlertStatistics(ctx context.Context, period time.Duration) (*AlertStatistics, error) {
	cutoff := time.Now().Add(-period)
	
	stats := &AlertStatistics{
		Period:    period,
		StartDate: cutoff,
		EndDate:   time.Now(),
	}

	// Total de alertas no período
	err := s.db.Model(&models.Alert{}).
		Where("created_at >= ?", cutoff).
		Count(&stats.TotalAlerts).Error
	if err != nil {
		return nil, err
	}

	// Alertas ativos
	err = s.db.Model(&models.Alert{}).
		Where("resolved = false").
		Count(&stats.ActiveAlerts).Error
	if err != nil {
		return nil, err
	}

	// Alertas por severidade
	var severityStats []struct {
		Severity string
		Count    int64
	}

	err = s.db.Model(&models.Alert{}).
		Select("severity, count(*) as count").
		Where("created_at >= ?", cutoff).
		Group("severity").
		Scan(&severityStats).Error

	if err != nil {
		return nil, err
	}

	stats.BySeverity = make(map[string]int64)
	for _, stat := range severityStats {
		stats.BySeverity[stat.Severity] = stat.Count
	}

	// Alertas por tipo
	var typeStats []struct {
		Type  string
		Count int64
	}

	err = s.db.Model(&models.Alert{}).
		Select("type, count(*) as count").
		Where("created_at >= ?", cutoff).
		Group("type").
		Scan(&typeStats).Error

	if err != nil {
		return nil, err
	}

	stats.ByType = make(map[string]int64)
	for _, stat := range typeStats {
		stats.ByType[stat.Type] = stat.Count
	}

	// Tempo médio de resolução (em horas)
	var avgResolution struct {
		AvgHours float64
	}

	err = s.db.Model(&models.Alert{}).
		Select("AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600) as avg_hours").
		Where("resolved = true AND created_at >= ?", cutoff).
		Scan(&avgResolution).Error

	if err == nil {
		stats.AverageResolutionHours = avgResolution.AvgHours
	}

	return stats, nil
}

// Métodos auxiliares

func (s *AlertService) cacheAlert(ctx context.Context, alert *models.Alert) {
	key := fmt.Sprintf("alert:%d", alert.ID)
	
	alertJSON, err := json.Marshal(alert)
	if err != nil {
		log.Printf("Error marshaling alert for cache: %v", err)
		return
	}

	err = s.redis.Set(ctx, key, alertJSON, 24*time.Hour).Err()
	if err != nil {
		log.Printf("Error caching alert: %v", err)
	}

	// Invalidar cache de alertas ativos
	s.redis.Del(ctx, "alerts:active")
}

func (s *AlertService) clearAlertCache(ctx context.Context, alert *models.Alert) {
	key := fmt.Sprintf("alert:%d", alert.ID)
	s.redis.Del(ctx, key)
	
	// Invalidar cache de alertas ativos
	s.redis.Del(ctx, "alerts:active")
}

func (s *AlertService) publishAlertRealtime(ctx context.Context, alert *models.Alert) {
	channel := "realtime:alerts"
	
	alertJSON, err := json.Marshal(alert)
	if err != nil {
		log.Printf("Error marshaling alert for realtime: %v", err)
		return
	}

	err = s.redis.Publish(ctx, channel, alertJSON).Err()
	if err != nil {
		log.Printf("Error publishing alert to realtime: %v", err)
	}
}

func (s *AlertService) publishAlertResolved(ctx context.Context, alert *models.Alert) {
	channel := "realtime:alerts:resolved"
	
	message := map[string]interface{}{
		"alert_id":    alert.ID,
		"resolved_at": alert.ResolvedAt,
		"resolved_by": alert.ResolvedBy,
	}

	messageJSON, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshaling alert resolution for realtime: %v", err)
		return
	}

	err = s.redis.Publish(ctx, channel, messageJSON).Err()
	if err != nil {
		log.Printf("Error publishing alert resolution to realtime: %v", err)
	}
}

func (s *AlertService) processAlertNotifications(ctx context.Context, alert *models.Alert) {
	// TODO: Implementar sistema de notificações
	// - Email
	// - SMS  
	// - Push notifications
	// - Webhook
	// - WhatsApp

	log.Printf("Processing notifications for alert: %s", alert.Title)
}

// Tipos auxiliares

type AlertFilters struct {
	PatientID *uint
	BraceID   *uint
	Type      string
	Severity  string
	Resolved  *bool
	StartDate time.Time
	EndDate   time.Time
	Limit     int
	Offset    int
}

type AlertStatistics struct {
	Period                  time.Duration     `json:"period"`
	StartDate               time.Time         `json:"start_date"`
	EndDate                 time.Time         `json:"end_date"`
	TotalAlerts             int64             `json:"total_alerts"`
	ActiveAlerts            int64             `json:"active_alerts"`
	BySeverity              map[string]int64  `json:"by_severity"`
	ByType                  map[string]int64  `json:"by_type"`
	AverageResolutionHours  float64           `json:"average_resolution_hours"`
}