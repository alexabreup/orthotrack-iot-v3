package models

import (
	"time"
	"github.com/google/uuid"
)

type Alert struct {
	ID          uint        `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID  `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	PatientID   *uint       `json:"patient_id,omitempty" gorm:"index"`
	BraceID     *uint       `json:"brace_id,omitempty" gorm:"index"`
	SessionID   *uint       `json:"session_id,omitempty" gorm:"index"`
	Type        AlertType   `json:"type" gorm:"type:varchar(50);not null;index"`
	Severity    Severity    `json:"severity" gorm:"type:varchar(20);not null;index"`
	Title       string      `json:"title" gorm:"size:200;not null"`
	Message     string      `json:"message" gorm:"type:text;not null"`
	Value       *float64    `json:"value,omitempty"` // Valor que causou o alerta
	Threshold   *float64    `json:"threshold,omitempty"` // Limite configurado
	Resolved    bool        `json:"resolved" gorm:"default:false;index"`
	ResolvedAt  *time.Time  `json:"resolved_at,omitempty"`
	ResolvedBy  *uint       `json:"resolved_by,omitempty"`
	Notes       string      `json:"notes,omitempty" gorm:"type:text"`
	CreatedAt   time.Time   `json:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at"`

	// Relacionamentos
	Patient *Patient      `json:"patient,omitempty" gorm:"foreignKey:PatientID"`
	Brace   *Brace        `json:"brace,omitempty" gorm:"foreignKey:BraceID"`
	Session *UsageSession `json:"session,omitempty" gorm:"foreignKey:SessionID"`
}

type AlertType string

const (
	AlertTypeBatteryLow      AlertType = "battery_low"
	AlertTypeComplianceLow   AlertType = "compliance_low"
	AlertTypeTemperatureHigh AlertType = "temperature_high"
	AlertTypeTemperatureLow  AlertType = "temperature_low"
	AlertTypeDeviceOffline   AlertType = "device_offline"
	AlertTypeSensorError     AlertType = "sensor_error"
	AlertTypeFirmwareUpdate  AlertType = "firmware_update"
	AlertTypeUsageAnomaly    AlertType = "usage_anomaly"
	AlertTypeMaintenance     AlertType = "maintenance_required"
)

type Severity string

const (
	SeverityLow      Severity = "low"
	SeverityMedium   Severity = "medium"
	SeverityHigh     Severity = "high"
	SeverityCritical Severity = "critical"
)

type AlertRule struct {
	ID          uint        `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID   `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	Name        string      `json:"name" gorm:"size:100;not null"`
	Type        AlertType   `json:"type" gorm:"type:varchar(50);not null"`
	Severity    Severity    `json:"severity" gorm:"type:varchar(20);not null"`
	Enabled     bool        `json:"enabled" gorm:"default:true"`
	Threshold   float64     `json:"threshold"`
	Operator    Operator    `json:"operator" gorm:"type:varchar(10);not null"`
	Duration    *int        `json:"duration,omitempty"` // Duração em minutos
	Description string      `json:"description,omitempty" gorm:"type:text"`
	CreatedAt   time.Time   `json:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at"`
}

type Operator string

const (
	OperatorGreater      Operator = ">"
	OperatorLess         Operator = "<"
	OperatorEqual        Operator = "="
	OperatorGreaterEqual Operator = ">="
	OperatorLessEqual    Operator = "<="
	OperatorNotEqual     Operator = "!="
)

type AlertNotification struct {
	ID          uint               `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID          `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	AlertID     uint               `json:"alert_id" gorm:"not null;index"`
	Channel     NotificationChannel `json:"channel" gorm:"type:varchar(20);not null"`
	Recipient   string             `json:"recipient" gorm:"size:200;not null"`
	Status      NotificationStatus  `json:"status" gorm:"type:varchar(20);default:'pending'"`
	SentAt      *time.Time         `json:"sent_at,omitempty"`
	Error       string             `json:"error,omitempty" gorm:"type:text"`
	Attempts    int                `json:"attempts" gorm:"default:0"`
	CreatedAt   time.Time          `json:"created_at"`
	UpdatedAt   time.Time          `json:"updated_at"`

	// Relacionamentos
	Alert Alert `json:"alert,omitempty" gorm:"foreignKey:AlertID"`
}

type NotificationChannel string

const (
	NotificationChannelEmail    NotificationChannel = "email"
	NotificationChannelSMS      NotificationChannel = "sms"
	NotificationChannelPush     NotificationChannel = "push"
	NotificationChannelWebhook  NotificationChannel = "webhook"
	NotificationChannelWhatsApp NotificationChannel = "whatsapp"
)

type NotificationStatus string

const (
	NotificationStatusPending NotificationStatus = "pending"
	NotificationStatusSent    NotificationStatus = "sent"
	NotificationStatusFailed  NotificationStatus = "failed"
	NotificationStatusRetry   NotificationStatus = "retry"
)

// Métodos para Alert
func (a *Alert) Resolve(resolvedBy *uint, notes string) {
	now := time.Now()
	a.Resolved = true
	a.ResolvedAt = &now
	a.ResolvedBy = resolvedBy
	if notes != "" {
		a.Notes = notes
	}
}

func (a *Alert) GetSeverityColor() string {
	switch a.Severity {
	case SeverityCritical:
		return "#dc2626" // red-600
	case SeverityHigh:
		return "#ea580c" // orange-600
	case SeverityMedium:
		return "#ca8a04" // yellow-600
	case SeverityLow:
		return "#16a34a" // green-600
	default:
		return "#6b7280" // gray-500
	}
}

func (a *Alert) GetTypeDescription() string {
	switch a.Type {
	case AlertTypeBatteryLow:
		return "Bateria Baixa"
	case AlertTypeComplianceLow:
		return "Baixa Compliance"
	case AlertTypeTemperatureHigh:
		return "Temperatura Alta"
	case AlertTypeTemperatureLow:
		return "Temperatura Baixa"
	case AlertTypeDeviceOffline:
		return "Dispositivo Offline"
	case AlertTypeSensorError:
		return "Erro no Sensor"
	case AlertTypeFirmwareUpdate:
		return "Atualização de Firmware"
	case AlertTypeUsageAnomaly:
		return "Anomalia no Uso"
	case AlertTypeMaintenance:
		return "Manutenção Necessária"
	default:
		return "Alerta Desconhecido"
	}
}

// Métodos para AlertRule
func (ar *AlertRule) CheckThreshold(value float64) bool {
	switch ar.Operator {
	case OperatorGreater:
		return value > ar.Threshold
	case OperatorLess:
		return value < ar.Threshold
	case OperatorEqual:
		return value == ar.Threshold
	case OperatorGreaterEqual:
		return value >= ar.Threshold
	case OperatorLessEqual:
		return value <= ar.Threshold
	case OperatorNotEqual:
		return value != ar.Threshold
	default:
		return false
	}
}

// Métodos para AlertNotification
func (an *AlertNotification) MarkAsSent() {
	now := time.Now()
	an.Status = NotificationStatusSent
	an.SentAt = &now
	an.Error = ""
}

func (an *AlertNotification) MarkAsFailed(err string) {
	an.Status = NotificationStatusFailed
	an.Error = err
	an.Attempts++
}

func (an *AlertNotification) ShouldRetry() bool {
	return an.Status == NotificationStatusFailed && an.Attempts < 3
}

// TableName especifica o nome das tabelas
func (Alert) TableName() string {
	return "alerts"
}

func (AlertRule) TableName() string {
	return "alert_rules"
}

func (AlertNotification) TableName() string {
	return "alert_notifications"
}