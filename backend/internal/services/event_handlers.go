package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"orthotrack-iot-v3/internal/models"
)

// DeviceStatusEvent represents a device status change event
type DeviceStatusEvent struct {
	DeviceID    string                 `json:"device_id"`
	Status      models.DeviceStatus    `json:"status"`
	Timestamp   int64                  `json:"timestamp"`
	BatteryLevel *int                  `json:"battery_level,omitempty"`
	SignalStrength *int                `json:"signal_strength,omitempty"`
	LastSeen    *time.Time             `json:"last_seen,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// AlertEvent represents a new alert event
type AlertEvent struct {
	AlertID     uint                   `json:"alert_id"`
	PatientID   uint                   `json:"patient_id"`
	PatientName string                 `json:"patient_name"`
	BraceID     *uint                  `json:"brace_id,omitempty"`
	Type        models.AlertType       `json:"type"`
	Severity    models.Severity        `json:"severity"`
	Title       string                 `json:"title"`
	Message     string                 `json:"message"`
	Timestamp   int64                  `json:"timestamp"`
	Value       *float64               `json:"value,omitempty"`
	Threshold   *float64               `json:"threshold,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// TelemetryEvent represents telemetry data event
type TelemetryEvent struct {
	DeviceID    string                 `json:"device_id"`
	PatientID   *uint                  `json:"patient_id,omitempty"`
	SessionID   *uint                  `json:"session_id,omitempty"`
	Timestamp   int64                  `json:"timestamp"`
	Sensors     TelemetrySensorData    `json:"sensors"`
	IsWearing   bool                   `json:"is_wearing"`
	Confidence  string                 `json:"confidence"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// TelemetrySensorData represents sensor data within telemetry
type TelemetrySensorData struct {
	Temperature      *float64 `json:"temperature,omitempty"`
	Humidity         *float64 `json:"humidity,omitempty"`
	BatteryLevel     *int     `json:"battery_level,omitempty"`
	Accelerometer    *AccelerometerData `json:"accelerometer,omitempty"`
	PressureDetected *bool    `json:"pressure_detected,omitempty"`
	PressureValue    *int     `json:"pressure_value,omitempty"`
	BraceClosed      *bool    `json:"brace_closed,omitempty"`
	MovementDetected *bool    `json:"movement_detected,omitempty"`
}

// AccelerometerData represents accelerometer sensor data
type AccelerometerData struct {
	X float64 `json:"x"`
	Y float64 `json:"y"`
	Z float64 `json:"z"`
}

// UsageSessionEvent represents usage session start/end events
type UsageSessionEvent struct {
	SessionID   uint                   `json:"session_id"`
	PatientID   uint                   `json:"patient_id"`
	DeviceID    string                 `json:"device_id"`
	EventType   string                 `json:"event_type"` // "start" or "end"
	Timestamp   int64                  `json:"timestamp"`
	Duration    *int                   `json:"duration,omitempty"` // only for end events, in seconds
	Confidence  float32                `json:"confidence"`
	Location    string                 `json:"location,omitempty"`
	Metadata    map[string]interface{} `json:"metadata,omitempty"`
}

// DashboardStatsEvent represents dashboard statistics update event
type DashboardStatsEvent struct {
	ActivePatients     int                    `json:"active_patients"`
	OnlineDevices      int                    `json:"online_devices"`
	ActiveAlerts       int                    `json:"active_alerts"`
	AverageCompliance  float32                `json:"average_compliance"`
	TotalSessions      int                    `json:"total_sessions"`
	TotalUsageHours    float32                `json:"total_usage_hours"`
	Timestamp          int64                  `json:"timestamp"`
	InstitutionID      *uint                  `json:"institution_id,omitempty"`
	Metadata           map[string]interface{} `json:"metadata,omitempty"`
}

// EventHandler provides methods to publish different types of events
type EventHandler struct {
	wsServer *WSServer
}

// NewEventHandler creates a new event handler
func NewEventHandler(wsServer *WSServer) *EventHandler {
	return &EventHandler{
		wsServer: wsServer,
	}
}

// PublishDeviceStatusEvent publishes a device status change event
func (eh *EventHandler) PublishDeviceStatusEvent(ctx context.Context, deviceID string, status models.DeviceStatus, brace *models.Brace) error {
	event := DeviceStatusEvent{
		DeviceID:  deviceID,
		Status:    status,
		Timestamp: time.Now().Unix(),
	}

	// Add additional data if brace is provided
	if brace != nil {
		event.BatteryLevel = brace.BatteryLevel
		event.SignalStrength = brace.SignalStrength
		event.LastSeen = brace.LastSeen
		
		// Add metadata
		event.Metadata = map[string]interface{}{
			"serial_number":    brace.SerialNumber,
			"mac_address":      brace.MacAddress,
			"firmware_version": brace.FirmwareVersion,
		}
	}

	// Route to device:{id} channel subscribers
	channel := fmt.Sprintf("device:%s", deviceID)
	
	log.Printf("Publishing device status event: device=%s, status=%s, channel=%s", 
		deviceID, status, channel)

	// Publish to WebSocket clients
	eh.wsServer.RouteEventToClients("device_status", channel, event)

	return nil
}

// PublishAlertEvent publishes a new alert event
func (eh *EventHandler) PublishAlertEvent(ctx context.Context, alert *models.Alert, patientName string) error {
	if alert.PatientID == nil {
		return fmt.Errorf("alert must have a patient ID")
	}

	event := AlertEvent{
		AlertID:     alert.ID,
		PatientID:   *alert.PatientID,
		PatientName: patientName,
		BraceID:     alert.BraceID,
		Type:        alert.Type,
		Severity:    alert.Severity,
		Title:       alert.Title,
		Message:     alert.Message,
		Timestamp:   alert.CreatedAt.Unix(),
		Value:       alert.Value,
		Threshold:   alert.Threshold,
	}

	// Add metadata
	event.Metadata = map[string]interface{}{
		"alert_uuid": alert.UUID.String(),
		"resolved":   alert.Resolved,
	}

	// Route to patient:{id} channel subscribers
	channel := fmt.Sprintf("patient:%d", *alert.PatientID)
	
	log.Printf("Publishing alert event: alert_id=%d, patient_id=%d, severity=%s, channel=%s", 
		alert.ID, *alert.PatientID, alert.Severity, channel)

	// Publish to WebSocket clients
	eh.wsServer.RouteEventToClients("alert_created", channel, event)

	return nil
}

// PublishTelemetryEvent publishes telemetry data event
func (eh *EventHandler) PublishTelemetryEvent(ctx context.Context, reading *models.SensorReading, deviceID string) error {
	event := TelemetryEvent{
		DeviceID:  deviceID,
		PatientID: reading.PatientID,
		SessionID: reading.SessionID,
		Timestamp: reading.Timestamp.Unix(),
		IsWearing: reading.IsWearing,
		Confidence: string(reading.ConfidenceLevel),
	}

	// Build sensor data
	sensors := TelemetrySensorData{
		Temperature:      reading.Temperature,
		Humidity:         reading.Humidity,
		PressureDetected: &reading.PressureDetected,
		PressureValue:    reading.PressureValue,
		BraceClosed:      &reading.BraceClosed,
		MovementDetected: &reading.MovementDetected,
	}

	// Add accelerometer data if available
	if reading.AccelX != nil && reading.AccelY != nil && reading.AccelZ != nil {
		sensors.Accelerometer = &AccelerometerData{
			X: *reading.AccelX,
			Y: *reading.AccelY,
			Z: *reading.AccelZ,
		}
	}

	event.Sensors = sensors

	// Add metadata
	event.Metadata = map[string]interface{}{
		"reading_uuid": reading.UUID.String(),
		"brace_id":     reading.BraceID,
	}

	// Route to device:{id} channel subscribers
	channel := fmt.Sprintf("device:%s", deviceID)
	
	log.Printf("Publishing telemetry event: device=%s, timestamp=%d, is_wearing=%t, channel=%s", 
		deviceID, event.Timestamp, event.IsWearing, channel)

	// Publish to WebSocket clients
	eh.wsServer.RouteEventToClients("telemetry", channel, event)

	return nil
}

// PublishUsageSessionEvent publishes usage session start/end events
func (eh *EventHandler) PublishUsageSessionEvent(ctx context.Context, session *models.UsageSession, eventType string, deviceID string) error {
	event := UsageSessionEvent{
		SessionID: session.ID,
		PatientID: session.PatientID,
		DeviceID:  deviceID,
		EventType: eventType,
		Timestamp: session.StartTime.Unix(),
		Confidence: session.StartConfidence,
		Location:  session.Location,
	}

	// For end events, include duration and use end time
	if eventType == "end" && session.EndTime != nil {
		event.Timestamp = session.EndTime.Unix()
		event.Duration = session.Duration
		if session.EndConfidence != nil {
			event.Confidence = *session.EndConfidence
		}
	}

	// Add metadata
	event.Metadata = map[string]interface{}{
		"session_uuid":      session.UUID.String(),
		"auto_detected":     session.AutoDetected,
		"compliance_score":  session.ComplianceScore,
		"comfort_score":     session.ComfortScore,
		"posture_score":     session.PostureScore,
		"is_active":         session.IsActive,
	}

	// Route to patient:{id} channel subscribers
	channel := fmt.Sprintf("patient:%d", session.PatientID)
	
	log.Printf("Publishing usage session event: session_id=%d, patient_id=%d, event_type=%s, channel=%s", 
		session.ID, session.PatientID, eventType, channel)

	// Publish to WebSocket clients
	eventTypeName := fmt.Sprintf("usage_session_%s", eventType)
	eh.wsServer.RouteEventToClients(eventTypeName, channel, event)

	return nil
}

// PublishDashboardStatsEvent publishes dashboard statistics update event
func (eh *EventHandler) PublishDashboardStatsEvent(ctx context.Context, stats DashboardStatsEvent) error {
	stats.Timestamp = time.Now().Unix()

	// Route to dashboard channel subscribers
	channel := "dashboard"
	
	log.Printf("Publishing dashboard stats event: active_patients=%d, online_devices=%d, active_alerts=%d, channel=%s", 
		stats.ActivePatients, stats.OnlineDevices, stats.ActiveAlerts, channel)

	// Publish to WebSocket clients
	eh.wsServer.RouteEventToClients("dashboard_stats", channel, stats)

	return nil
}

// Helper method to convert models.SensorReading to TelemetryEvent for easier testing
func (eh *EventHandler) ConvertSensorReadingToTelemetryEvent(reading *models.SensorReading, deviceID string) TelemetryEvent {
	event := TelemetryEvent{
		DeviceID:  deviceID,
		PatientID: reading.PatientID,
		SessionID: reading.SessionID,
		Timestamp: reading.Timestamp.Unix(),
		IsWearing: reading.IsWearing,
		Confidence: string(reading.ConfidenceLevel),
	}

	// Build sensor data
	sensors := TelemetrySensorData{
		Temperature:      reading.Temperature,
		Humidity:         reading.Humidity,
		PressureDetected: &reading.PressureDetected,
		PressureValue:    reading.PressureValue,
		BraceClosed:      &reading.BraceClosed,
		MovementDetected: &reading.MovementDetected,
	}

	// Add accelerometer data if available
	if reading.AccelX != nil && reading.AccelY != nil && reading.AccelZ != nil {
		sensors.Accelerometer = &AccelerometerData{
			X: *reading.AccelX,
			Y: *reading.AccelY,
			Z: *reading.AccelZ,
		}
	}

	event.Sensors = sensors

	// Add metadata
	event.Metadata = map[string]interface{}{
		"reading_uuid": reading.UUID.String(),
		"brace_id":     reading.BraceID,
	}

	return event
}

