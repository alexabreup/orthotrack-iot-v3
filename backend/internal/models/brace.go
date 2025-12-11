package models

import (
	"time"
	"gorm.io/gorm"
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"github.com/google/uuid"
)

// DeviceConfig representa a configuração JSON do dispositivo
type DeviceConfig map[string]interface{}

// Value implementa driver.Valuer para GORM
func (dc DeviceConfig) Value() (driver.Value, error) {
	return json.Marshal(dc)
}

// Scan implementa sql.Scanner para GORM
func (dc *DeviceConfig) Scan(value interface{}) error {
	if value == nil {
		*dc = make(DeviceConfig)
		return nil
	}

	bytes, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("cannot scan %T into DeviceConfig", value)
	}

	return json.Unmarshal(bytes, dc)
}

type Brace struct {
	ID              uint           `json:"id" gorm:"primaryKey"`
	UUID            uuid.UUID      `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	PatientID       *uint          `json:"patient_id,omitempty" gorm:"index"`
	
	// Identificação do Dispositivo
	DeviceID        string         `json:"device_id" gorm:"size:50;uniqueIndex;not null"` // ID único do ESP32
	APIKey          string         `json:"api_key" gorm:"size:100;uniqueIndex;not null"` // Chave de API para autenticação
	SerialNumber    string         `json:"serial_number" gorm:"size:100;uniqueIndex;not null"`
	MacAddress      string         `json:"mac_address" gorm:"size:17;uniqueIndex;not null"`
	Model           string         `json:"model" gorm:"size:50;default:ESP32-ORTHO-V1"`
	Version         string         `json:"version" gorm:"size:20;default:1.0"`
	
	// Status do Dispositivo
	Status          DeviceStatus   `json:"status" gorm:"type:varchar(20);default:offline;index"`
	BatteryLevel    *int           `json:"battery_level" gorm:"check:battery_level BETWEEN 0 AND 100"`
	BatteryVoltage  *float32       `json:"battery_voltage"`
	SignalStrength  *int           `json:"signal_strength"` // RSSI
	LastHeartbeat   *time.Time     `json:"last_heartbeat" gorm:"index"`
	LastSeen        *time.Time     `json:"last_seen" gorm:"index"`
	
	// Firmware e Configuração
	FirmwareVersion string         `json:"firmware_version" gorm:"size:20"`
	HardwareVersion string         `json:"hardware_version" gorm:"size:20"`
	Config          DeviceConfig   `json:"config" gorm:"type:jsonb"`
	CalibrationData DeviceConfig   `json:"calibration_data" gorm:"type:jsonb"`
	LastCalibration *time.Time     `json:"last_calibration"`
	
	// Estatísticas de Uso
	TotalUsageHours  float32       `json:"total_usage_hours" gorm:"default:0"`
	LastUsageStart   *time.Time    `json:"last_usage_start"`
	LastUsageEnd     *time.Time    `json:"last_usage_end"`
	CurrentSessionID *uint         `json:"current_session_id"`
	
	// Manutenção
	ManufacturedDate *time.Time    `json:"manufactured_date"`
	ActivatedDate    *time.Time    `json:"activated_date"`
	LastMaintenanceDate *time.Time `json:"last_maintenance_date"`
	MaintenanceNotes string        `json:"maintenance_notes" gorm:"type:text"`
	
	// Timestamps
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	DeletedAt       gorm.DeletedAt `json:"-" gorm:"index"`

	// Relacionamentos
	Patient       *Patient       `json:"patient,omitempty" gorm:"foreignKey:PatientID"`
	SensorReadings []SensorReading `json:"sensor_readings,omitempty" gorm:"foreignKey:BraceID"`
	Commands      []BraceCommand `json:"commands,omitempty" gorm:"foreignKey:BraceID"`
	Alerts        []Alert        `json:"alerts,omitempty" gorm:"foreignKey:BraceID"`
	UsageSessions []UsageSession `json:"usage_sessions,omitempty" gorm:"foreignKey:BraceID"`
}

type DeviceStatus string

const (
	DeviceStatusOnline      DeviceStatus = "online"
	DeviceStatusOffline     DeviceStatus = "offline"
	DeviceStatusMaintenance DeviceStatus = "maintenance"
	DeviceStatusActive      DeviceStatus = "active"
	DeviceStatusInactive    DeviceStatus = "inactive"
	DeviceStatusError       DeviceStatus = "error"
	DeviceStatusConfiguring DeviceStatus = "configuring"
	DeviceStatusUpdating    DeviceStatus = "updating"
)

type BraceCommand struct {
	ID          uint             `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID        `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	BraceID     uint             `json:"brace_id" gorm:"not null;index"`
	SentBy      uint             `json:"sent_by" gorm:"not null"` // MedicalStaff ID
	
	// Comando
	CommandType CommandType      `json:"command_type" gorm:"type:varchar(50);not null"`
	Parameters  DeviceConfig     `json:"parameters" gorm:"type:jsonb"`
	Priority    CommandPriority  `json:"priority" gorm:"type:varchar(20);default:normal"`
	
	// Status e Execução
	Status      CommandStatus    `json:"status" gorm:"type:varchar(20);default:pending"`
	SentAt      *time.Time       `json:"sent_at"`
	AcknowledgedAt *time.Time    `json:"acknowledged_at"`
	ExecutedAt  *time.Time       `json:"executed_at"`
	CompletedAt *time.Time       `json:"completed_at"`
	FailedAt    *time.Time       `json:"failed_at"`
	
	// Resposta
	Response    DeviceConfig     `json:"response" gorm:"type:jsonb"`
	ErrorMessage string          `json:"error_message" gorm:"type:text"`
	RetryCount  int              `json:"retry_count" gorm:"default:0"`
	MaxRetries  int              `json:"max_retries" gorm:"default:3"`
	
	// Timeout
	TimeoutAt   *time.Time       `json:"timeout_at"`
	TimeoutDuration int          `json:"timeout_duration" gorm:"default:300"` // seconds
	
	CreatedAt   time.Time        `json:"created_at"`
	UpdatedAt   time.Time        `json:"updated_at"`

	// Relacionamentos
	Brace Brace `json:"brace,omitempty" gorm:"foreignKey:BraceID"`
}

type CommandType string

const (
	CommandTypeConfigUpdate    CommandType = "config_update"
	CommandTypeFirmwareUpdate  CommandType = "firmware_update"
	CommandTypeReboot         CommandType = "reboot"
	CommandTypeCalibration    CommandType = "calibration"
	CommandTypeDataSync       CommandType = "data_sync"
	CommandTypeBatteryReport  CommandType = "battery_report"
	CommandTypeDiagnostic     CommandType = "diagnostic"
	CommandTypeStartSession   CommandType = "start_session"
	CommandTypeStopSession    CommandType = "stop_session"
	CommandTypeSetSampleRate  CommandType = "set_sample_rate"
	CommandTypeEnableDeepSleep CommandType = "enable_deep_sleep"
	CommandTypeDisableDeepSleep CommandType = "disable_deep_sleep"
	CommandTypeGetStatus      CommandType = "get_status"
	CommandTypeReset          CommandType = "reset"
)

type CommandStatus string

const (
	CommandStatusPending      CommandStatus = "pending"
	CommandStatusQueued       CommandStatus = "queued"
	CommandStatusSent         CommandStatus = "sent"
	CommandStatusAcknowledged CommandStatus = "acknowledged"
	CommandStatusExecuting    CommandStatus = "executing"
	CommandStatusCompleted    CommandStatus = "completed"
	CommandStatusFailed       CommandStatus = "failed"
	CommandStatusTimeout      CommandStatus = "timeout"
	CommandStatusCancelled    CommandStatus = "cancelled"
)

type CommandPriority string

const (
	CommandPriorityLow      CommandPriority = "low"
	CommandPriorityNormal   CommandPriority = "normal"
	CommandPriorityHigh     CommandPriority = "high"
	CommandPriorityCritical CommandPriority = "critical"
)

// Métodos para Brace
func (b *Brace) IsOnline() bool {
	if b.LastHeartbeat == nil {
		return false
	}
	return time.Since(*b.LastHeartbeat) < 5*time.Minute
}

func (b *Brace) IsActive() bool {
	return b.Status == DeviceStatusOnline || b.Status == DeviceStatusActive
}

func (b *Brace) GetBatteryStatus() string {
	if b.BatteryLevel == nil {
		return "unknown"
	}
	level := *b.BatteryLevel
	switch {
	case level >= 80:
		return "excellent"
	case level >= 60:
		return "good"
	case level >= 40:
		return "fair"
	case level >= 20:
		return "low"
	default:
		return "critical"
	}
}

func (b *Brace) NeedsCalibration() bool {
	if b.LastCalibration == nil {
		return true
	}
	return time.Since(*b.LastCalibration) > 7*24*time.Hour // 1 week
}

func (b *Brace) UpdateLastSeen() {
	now := time.Now()
	b.LastSeen = &now
	b.LastHeartbeat = &now
	b.Status = DeviceStatusOnline
}

func (b *Brace) UpdateHeartbeat() {
	now := time.Now()
	b.LastHeartbeat = &now
	b.LastSeen = &now
	if b.Status == DeviceStatusOffline {
		b.Status = DeviceStatusOnline
	}
}

func (b *Brace) SetOffline() {
	b.Status = DeviceStatusOffline
}

func (b *Brace) SetMaintenance(notes string) {
	b.Status = DeviceStatusMaintenance
	b.MaintenanceNotes = notes
	now := time.Now()
	b.LastMaintenanceDate = &now
}

func (b *Brace) StartUsageSession() {
	now := time.Now()
	b.LastUsageStart = &now
	b.LastUsageEnd = nil
}

func (b *Brace) EndUsageSession() {
	now := time.Now()
	b.LastUsageEnd = &now
	
	// Calculate session duration and add to total
	if b.LastUsageStart != nil {
		sessionDuration := now.Sub(*b.LastUsageStart)
		b.TotalUsageHours += float32(sessionDuration.Hours())
	}
}

// TableName especifica o nome da tabela
func (Brace) TableName() string {
	return "braces"
}

func (BraceCommand) TableName() string {
	return "brace_commands"
}