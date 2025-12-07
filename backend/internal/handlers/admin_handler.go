package handlers

import (
	"bytes"
	"context"
	"encoding/csv"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"orthotrack-iot-v3/internal/models"
	"orthotrack-iot-v3/internal/services"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type AdminHandler struct {
	db           *gorm.DB
	iotService   *services.IoTService
	alertService *services.AlertService
}

func NewAdminHandler(db *gorm.DB, iotService *services.IoTService, alertService *services.AlertService) *AdminHandler {
	return &AdminHandler{
		db:           db,
		iotService:   iotService,
		alertService: alertService,
	}
}

// GetPatients - Alias para PatientHandler
func (h *AdminHandler) GetPatients(c *gin.Context) {
	handler := NewPatientHandler(h.db)
	handler.GetPatients(c)
}

func (h *AdminHandler) CreatePatient(c *gin.Context) {
	handler := NewPatientHandler(h.db)
	handler.CreatePatient(c)
}

func (h *AdminHandler) GetPatient(c *gin.Context) {
	handler := NewPatientHandler(h.db)
	handler.GetPatient(c)
}

func (h *AdminHandler) UpdatePatient(c *gin.Context) {
	handler := NewPatientHandler(h.db)
	handler.UpdatePatient(c)
}

func (h *AdminHandler) DeletePatient(c *gin.Context) {
	handler := NewPatientHandler(h.db)
	handler.DeletePatient(c)
}

// GetOrteses - Lista dispositivos (braces)
func (h *AdminHandler) GetOrteses(c *gin.Context) {
	handler := NewBraceHandler(h.db)
	handler.GetBraces(c)
}

func (h *AdminHandler) CreateOrtese(c *gin.Context) {
	handler := NewBraceHandler(h.db)
	handler.CreateBrace(c)
}

func (h *AdminHandler) GetOrtese(c *gin.Context) {
	handler := NewBraceHandler(h.db)
	handler.GetBrace(c)
}

func (h *AdminHandler) UpdateOrtese(c *gin.Context) {
	handler := NewBraceHandler(h.db)
	handler.UpdateBrace(c)
}

func (h *AdminHandler) DeleteOrtese(c *gin.Context) {
	handler := NewBraceHandler(h.db)
	handler.DeleteBrace(c)
}

// GetComplianceReport - Relatório de compliance
func (h *AdminHandler) GetComplianceReport(c *gin.Context) {
	patientID := c.Query("patient_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	query := h.db.Model(&models.DailyCompliance{}).Preload("Patient")

	if patientID != "" {
		query = query.Where("patient_id = ?", patientID)
	}

	if startDate != "" {
		if date, err := time.Parse("2006-01-02", startDate); err == nil {
			query = query.Where("date >= ?", date)
		}
	}

	if endDate != "" {
		if date, err := time.Parse("2006-01-02", endDate); err == nil {
			query = query.Where("date <= ?", date)
		}
	}

	var compliance []models.DailyCompliance
	if err := query.Order("date DESC").Find(&compliance).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, compliance)
}

// GetUsageReport - Relatório de uso
func (h *AdminHandler) GetUsageReport(c *gin.Context) {
	patientID := c.Query("patient_id")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	query := h.db.Model(&models.UsageSession{}).Preload("Patient").Preload("Brace")

	if patientID != "" {
		query = query.Where("patient_id = ?", patientID)
	}

	if startDate != "" {
		if date, err := time.Parse("2006-01-02", startDate); err == nil {
			query = query.Where("start_time >= ?", date)
		}
	}

	if endDate != "" {
		if date, err := time.Parse("2006-01-02", endDate); err == nil {
			query = query.Where("start_time <= ?", date)
		}
	}

	var sessions []models.UsageSession
	if err := query.Order("start_time DESC").Find(&sessions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, sessions)
}

// ExportData - Exportar dados
func (h *AdminHandler) ExportData(c *gin.Context) {
	exportType := c.Query("type") // patients, sessions, compliance, alerts
	format := c.DefaultQuery("format", "json") // json, csv
	
	// Definir filtros de data
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")
	
	switch exportType {
	case "patients":
		h.exportPatients(c, format, startDate, endDate)
	case "sessions":
		h.exportSessions(c, format, startDate, endDate)
	case "alerts":
		h.exportAlerts(c, format, startDate, endDate)
	case "compliance":
		h.exportCompliance(c, format, startDate, endDate)
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid export type"})
	}
}

// GetDashboardOverview - Visão geral do dashboard
func (h *AdminHandler) GetDashboardOverview(c *gin.Context) {
	ctx := context.Background()

	// Estatísticas gerais
	var stats struct {
		TotalPatients      int64 `json:"total_patients"`
		ActivePatients     int64 `json:"active_patients"`
		TotalBraces        int64 `json:"total_braces"`
		OnlineBraces       int64 `json:"online_braces"`
		ActiveAlerts       int64 `json:"active_alerts"`
		TodaySessions      int64 `json:"today_sessions"`
		AvgComplianceToday float64 `json:"avg_compliance_today"`
	}

	// Contar pacientes
	h.db.Model(&models.Patient{}).Where("is_active = ?", true).Count(&stats.ActivePatients)
	h.db.Model(&models.Patient{}).Count(&stats.TotalPatients)

	// Contar braces
	h.db.Model(&models.Brace{}).Count(&stats.TotalBraces)
	h.db.Model(&models.Brace{}).Where("status = ?", "online").Count(&stats.OnlineBraces)

	// Alertas ativos
	alerts, _ := h.alertService.GetActiveAlerts(ctx)
	stats.ActiveAlerts = int64(len(alerts))

	// Sessões de hoje
	today := time.Now().Truncate(24 * time.Hour)
	h.db.Model(&models.UsageSession{}).
		Where("start_time >= ?", today).
		Count(&stats.TodaySessions)

	// Compliance médio de hoje
	var avgCompliance float64
	h.db.Model(&models.DailyCompliance{}).
		Where("date = ?", today.Format("2006-01-02")).
		Select("AVG(compliance_percent)").
		Scan(&avgCompliance)
	stats.AvgComplianceToday = avgCompliance

	c.JSON(http.StatusOK, stats)
}

// GetRealtimeData - Dados em tempo real
func (h *AdminHandler) GetRealtimeData(c *gin.Context) {
	deviceID := c.Query("device_id")

	ctx := context.Background()

	if deviceID != "" {
		// Dados de um dispositivo específico
		telemetry, err := h.iotService.GetDeviceStatus(ctx, deviceID)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, telemetry)
		return
	}

	// Lista de dispositivos conectados
	devices, err := h.iotService.GetConnectedDevices(ctx)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, devices)
}

// exportPatients exporta dados dos pacientes
func (h *AdminHandler) exportPatients(c *gin.Context, format, startDate, endDate string) {
	var patients []models.Patient
	query := h.db.Preload("Braces")
	
	if startDate != "" {
		if start, err := time.Parse("2006-01-02", startDate); err == nil {
			query = query.Where("created_at >= ?", start)
		}
	}
	if endDate != "" {
		if end, err := time.Parse("2006-01-02", endDate); err == nil {
			query = query.Where("created_at <= ?", end)
		}
	}
	
	if err := query.Find(&patients).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	if format == "csv" {
		h.exportPatientsCSV(c, patients)
	} else {
		c.JSON(http.StatusOK, gin.H{"data": patients, "count": len(patients)})
	}
}

// exportSessions exporta dados das sessões de uso
func (h *AdminHandler) exportSessions(c *gin.Context, format, startDate, endDate string) {
	var sessions []models.UsageSession
	query := h.db.Preload("Patient").Preload("Brace")
	
	if startDate != "" {
		if start, err := time.Parse("2006-01-02", startDate); err == nil {
			query = query.Where("start_time >= ?", start)
		}
	}
	if endDate != "" {
		if end, err := time.Parse("2006-01-02", endDate); err == nil {
			query = query.Where("start_time <= ?", end)
		}
	}
	
	if err := query.Find(&sessions).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	if format == "csv" {
		h.exportSessionsCSV(c, sessions)
	} else {
		c.JSON(http.StatusOK, gin.H{"data": sessions, "count": len(sessions)})
	}
}

// exportAlerts exporta dados dos alertas
func (h *AdminHandler) exportAlerts(c *gin.Context, format, startDate, endDate string) {
	var alerts []models.Alert
	query := h.db.Preload("Patient").Preload("Brace")
	
	if startDate != "" {
		if start, err := time.Parse("2006-01-02", startDate); err == nil {
			query = query.Where("created_at >= ?", start)
		}
	}
	if endDate != "" {
		if end, err := time.Parse("2006-01-02", endDate); err == nil {
			query = query.Where("created_at <= ?", end)
		}
	}
	
	if err := query.Find(&alerts).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	if format == "csv" {
		h.exportAlertsCSV(c, alerts)
	} else {
		c.JSON(http.StatusOK, gin.H{"data": alerts, "count": len(alerts)})
	}
}

// exportCompliance exporta dados de compliance
func (h *AdminHandler) exportCompliance(c *gin.Context, format, startDate, endDate string) {
	var compliance []models.DailyCompliance
	query := h.db.Preload("Patient").Preload("Brace")
	
	if startDate != "" {
		query = query.Where("date >= ?", startDate)
	}
	if endDate != "" {
		query = query.Where("date <= ?", endDate)
	}
	
	if err := query.Find(&compliance).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	if format == "csv" {
		h.exportComplianceCSV(c, compliance)
	} else {
		c.JSON(http.StatusOK, gin.H{"data": compliance, "count": len(compliance)})
	}
}

// exportPatientsCSV exporta pacientes em formato CSV
func (h *AdminHandler) exportPatientsCSV(c *gin.Context, patients []models.Patient) {
	var buf bytes.Buffer
	writer := csv.NewWriter(&buf)
	
	// Header
	writer.Write([]string{"ID", "Nome", "Email", "Telefone", "Data Nascimento", "Gênero", "CPF", "Ativo", "Data Criação"})
	
	// Data
	for _, p := range patients {
		record := []string{
			strconv.Itoa(int(p.ID)),
			p.Name,
			p.Email,
			p.Phone,
			func() string {
				if p.DateOfBirth != nil {
					return p.DateOfBirth.Format("2006-01-02")
				}
				return ""
			}(),
			p.Gender,
			p.CPF,
			fmt.Sprintf("%t", p.IsActive),
			p.CreatedAt.Format("2006-01-02 15:04:05"),
		}
		writer.Write(record)
	}
	
	writer.Flush()
	
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=patients.csv")
	c.String(http.StatusOK, buf.String())
}

// exportSessionsCSV exporta sessões em formato CSV
func (h *AdminHandler) exportSessionsCSV(c *gin.Context, sessions []models.UsageSession) {
	var buf bytes.Buffer
	writer := csv.NewWriter(&buf)
	
	// Header
	writer.Write([]string{"ID", "Paciente", "Dispositivo", "Início", "Fim", "Duração (min)", "Compliance %", "Ativo"})
	
	// Data
	for _, s := range sessions {
		patientName := s.Patient.Name
		deviceID := s.Brace.DeviceID
		
		endTime := ""
		duration := ""
		if s.EndTime != nil {
			endTime = s.EndTime.Format("2006-01-02 15:04:05")
			if !s.StartTime.IsZero() {
				duration = fmt.Sprintf("%.0f", s.EndTime.Sub(s.StartTime).Minutes())
			}
		}
		
		record := []string{
			strconv.Itoa(int(s.ID)),
			patientName,
			deviceID,
			s.StartTime.Format("2006-01-02 15:04:05"),
			endTime,
			duration,
			fmt.Sprintf("%.1f", s.ComplianceScore),
			fmt.Sprintf("%t", s.IsActive),
		}
		writer.Write(record)
	}
	
	writer.Flush()
	
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=sessions.csv")
	c.String(http.StatusOK, buf.String())
}

// exportAlertsCSV exporta alertas em formato CSV
func (h *AdminHandler) exportAlertsCSV(c *gin.Context, alerts []models.Alert) {
	var buf bytes.Buffer
	writer := csv.NewWriter(&buf)
	
	// Header
	writer.Write([]string{"ID", "Paciente", "Dispositivo", "Tipo", "Severidade", "Título", "Mensagem", "Valor", "Resolvido", "Data Criação"})
	
	// Data
	for _, a := range alerts {
		patientName := ""
		if a.Patient != nil {
			patientName = a.Patient.Name
		}
		
		deviceID := ""
		if a.Brace != nil {
			deviceID = a.Brace.DeviceID
		}
		
		value := ""
		if a.Value != nil {
			value = fmt.Sprintf("%.2f", *a.Value)
		}
		
		record := []string{
			strconv.Itoa(int(a.ID)),
			patientName,
			deviceID,
			string(a.Type),
			string(a.Severity),
			a.Title,
			a.Message,
			value,
			fmt.Sprintf("%t", a.Resolved),
			a.CreatedAt.Format("2006-01-02 15:04:05"),
		}
		writer.Write(record)
	}
	
	writer.Flush()
	
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=alerts.csv")
	c.String(http.StatusOK, buf.String())
}

// exportComplianceCSV exporta compliance em formato CSV
func (h *AdminHandler) exportComplianceCSV(c *gin.Context, compliance []models.DailyCompliance) {
	var buf bytes.Buffer
	writer := csv.NewWriter(&buf)
	
	// Header
	writer.Write([]string{"ID", "Paciente", "Dispositivo", "Data", "Uso Diário (min)", "Compliance %", "Objetivo (min)"})
	
	// Data
	for _, c := range compliance {
		patientName := c.Patient.Name
		deviceID := c.Brace.DeviceID
		
		record := []string{
			strconv.Itoa(int(c.ID)),
			patientName,
			deviceID,
			c.Date.Format("2006-01-02"),
			strconv.Itoa(c.ActualMinutes),
			fmt.Sprintf("%.1f", c.CompliancePercent),
			strconv.Itoa(c.TargetMinutes),
		}
		writer.Write(record)
	}
	
	writer.Flush()
	
	c.Header("Content-Type", "text/csv")
	c.Header("Content-Disposition", "attachment; filename=compliance.csv")
	c.String(http.StatusOK, buf.String())
}








