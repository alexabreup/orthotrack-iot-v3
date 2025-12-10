package services

import (
	"context"
	"log"
	"time"

	"orthotrack-iot-v3/internal/models"

	"gorm.io/gorm"
)

// DashboardStatsService handles calculation and publishing of dashboard statistics
type DashboardStatsService struct {
	db           *gorm.DB
	eventHandler *EventHandler
}

// NewDashboardStatsService creates a new dashboard statistics service
func NewDashboardStatsService(db *gorm.DB, eventHandler *EventHandler) *DashboardStatsService {
	return &DashboardStatsService{
		db:           db,
		eventHandler: eventHandler,
	}
}

// CalculateAndPublishStats calculates current dashboard statistics and publishes them via WebSocket
func (s *DashboardStatsService) CalculateAndPublishStats(ctx context.Context, institutionID *uint) error {
	stats, err := s.CalculateStats(ctx, institutionID)
	if err != nil {
		return err
	}

	// Publish WebSocket event
	if s.eventHandler != nil {
		if err := s.eventHandler.PublishDashboardStatsEvent(ctx, *stats); err != nil {
			log.Printf("Warning: Failed to publish dashboard stats event: %v", err)
		}
	}

	return nil
}

// CalculateStats calculates current dashboard statistics
func (s *DashboardStatsService) CalculateStats(ctx context.Context, institutionID *uint) (*DashboardStatsEvent, error) {
	stats := &DashboardStatsEvent{
		InstitutionID: institutionID,
		Timestamp:     time.Now().Unix(),
	}

	// Build base query with institution filter if provided
	baseQuery := s.db
	if institutionID != nil {
		baseQuery = baseQuery.Where("institution_id = ?", *institutionID)
	}

	// Calculate active patients (patients with is_active = true)
	var activePatients int64
	if err := baseQuery.Model(&models.Patient{}).Where("is_active = ?", true).Count(&activePatients).Error; err != nil {
		log.Printf("Error counting active patients: %v", err)
	}
	stats.ActivePatients = int(activePatients)

	// Calculate online devices (devices with status = 'online' and recent heartbeat)
	cutoff := time.Now().Add(-5 * time.Minute) // Consider online if heartbeat within 5 minutes
	var onlineDevices int64
	deviceQuery := s.db.Model(&models.Brace{}).Where("status = ? AND last_heartbeat > ?", models.DeviceStatusOnline, cutoff)
	if institutionID != nil {
		// Join with patients table to filter by institution
		deviceQuery = deviceQuery.Joins("JOIN patients ON braces.patient_id = patients.id").
			Where("patients.institution_id = ?", *institutionID)
	}
	if err := deviceQuery.Count(&onlineDevices).Error; err != nil {
		log.Printf("Error counting online devices: %v", err)
	}
	stats.OnlineDevices = int(onlineDevices)

	// Calculate active alerts (unresolved alerts)
	var activeAlerts int64
	alertQuery := s.db.Model(&models.Alert{}).Where("resolved = ?", false)
	if institutionID != nil {
		// Join with patients table to filter by institution
		alertQuery = alertQuery.Joins("JOIN patients ON alerts.patient_id = patients.id").
			Where("patients.institution_id = ?", *institutionID)
	}
	if err := alertQuery.Count(&activeAlerts).Error; err != nil {
		log.Printf("Error counting active alerts: %v", err)
	}
	stats.ActiveAlerts = int(activeAlerts)

	// Calculate average compliance for today
	today := time.Now().Truncate(24 * time.Hour)
	tomorrow := today.Add(24 * time.Hour)
	
	var avgCompliance float64
	complianceQuery := baseQuery.Model(&models.UsageSession{}).
		Select("AVG(compliance_score)").
		Where("start_time >= ? AND start_time < ? AND compliance_score IS NOT NULL", today, tomorrow)
	
	if err := complianceQuery.Scan(&avgCompliance).Error; err != nil {
		log.Printf("Error calculating average compliance: %v", err)
	}
	stats.AverageCompliance = float32(avgCompliance)

	// Calculate total sessions today
	var totalSessions int64
	sessionQuery := baseQuery.Model(&models.UsageSession{}).
		Where("start_time >= ? AND start_time < ?", today, tomorrow)
	
	if err := sessionQuery.Count(&totalSessions).Error; err != nil {
		log.Printf("Error counting total sessions: %v", err)
	}
	stats.TotalSessions = int(totalSessions)

	// Calculate total usage hours today
	var totalMinutes int64
	usageQuery := baseQuery.Model(&models.UsageSession{}).
		Select("COALESCE(SUM(duration), 0)").
		Where("start_time >= ? AND start_time < ? AND duration IS NOT NULL", today, tomorrow)
	
	if err := usageQuery.Scan(&totalMinutes).Error; err != nil {
		log.Printf("Error calculating total usage hours: %v", err)
	}
	stats.TotalUsageHours = float32(totalMinutes) / 60.0 // Convert minutes to hours

	log.Printf("Calculated dashboard stats: active_patients=%d, online_devices=%d, active_alerts=%d, avg_compliance=%.2f",
		stats.ActivePatients, stats.OnlineDevices, stats.ActiveAlerts, stats.AverageCompliance)

	return stats, nil
}

// RecalculateStatsOnPatientChange recalculates stats when patient data changes
func (s *DashboardStatsService) RecalculateStatsOnPatientChange(ctx context.Context, institutionID *uint) {
	if err := s.CalculateAndPublishStats(ctx, institutionID); err != nil {
		log.Printf("Error recalculating stats on patient change: %v", err)
	}
}

// RecalculateStatsOnDeviceChange recalculates stats when device status changes
func (s *DashboardStatsService) RecalculateStatsOnDeviceChange(ctx context.Context, institutionID *uint) {
	if err := s.CalculateAndPublishStats(ctx, institutionID); err != nil {
		log.Printf("Error recalculating stats on device change: %v", err)
	}
}

// RecalculateStatsOnAlertChange recalculates stats when alert status changes
func (s *DashboardStatsService) RecalculateStatsOnAlertChange(ctx context.Context, institutionID *uint) {
	if err := s.CalculateAndPublishStats(ctx, institutionID); err != nil {
		log.Printf("Error recalculating stats on alert change: %v", err)
	}
}

// RecalculateStatsOnSessionChange recalculates stats when usage session changes
func (s *DashboardStatsService) RecalculateStatsOnSessionChange(ctx context.Context, institutionID *uint) {
	if err := s.CalculateAndPublishStats(ctx, institutionID); err != nil {
		log.Printf("Error recalculating stats on session change: %v", err)
	}
}

// StartPeriodicStatsUpdate starts a goroutine that periodically updates dashboard statistics
func (s *DashboardStatsService) StartPeriodicStatsUpdate(ctx context.Context, interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				log.Printf("Dashboard stats periodic update stopped")
				return
			case <-ticker.C:
				// Calculate stats for all institutions (nil means global)
				if err := s.CalculateAndPublishStats(ctx, nil); err != nil {
					log.Printf("Error in periodic stats update: %v", err)
				}
			}
		}
	}()
	log.Printf("Dashboard stats periodic update started (interval: %v)", interval)
}