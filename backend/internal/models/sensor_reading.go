package models

import (
	"time"
	"github.com/google/uuid"
)

type SensorReading struct {
	ID         uint      `json:"id" gorm:"primaryKey"`
	UUID       uuid.UUID `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	BraceID    uint      `json:"brace_id" gorm:"not null;index:idx_brace_timestamp"`
	PatientID  *uint     `json:"patient_id,omitempty" gorm:"index"`
	SessionID  *uint     `json:"session_id,omitempty" gorm:"index"`
	Timestamp  time.Time `json:"timestamp" gorm:"not null;index:idx_brace_timestamp;index:idx_timestamp"`

	// Sensores MPU6050 (Acelerômetro e Giroscópio)
	AccelX           *float64 `json:"accel_x,omitempty"`
	AccelY           *float64 `json:"accel_y,omitempty"`
	AccelZ           *float64 `json:"accel_z,omitempty"`
	GyroX            *float64 `json:"gyro_x,omitempty"`
	GyroY            *float64 `json:"gyro_y,omitempty"`
	GyroZ            *float64 `json:"gyro_z,omitempty"`
	MovementDetected bool     `json:"movement_detected" gorm:"default:false"`

	// Sensor de Temperatura e Umidade (DHT22)
	Temperature *float64 `json:"temperature,omitempty"`
	Humidity    *float64 `json:"humidity,omitempty"`

	// Sensor de Pressão/Toque (FSR)
	PressureDetected bool `json:"pressure_detected" gorm:"default:false"`
	PressureValue    *int `json:"pressure_value,omitempty"` // 0-1023

	// Sensor Hall/Magnético  
	BraceClosed bool `json:"brace_closed" gorm:"default:false"` // Colete fechado corretamente

	// Status de uso calculado
	IsWearing        bool             `json:"is_wearing" gorm:"default:false;index"` // Paciente está usando o colete
	ConfidenceLevel  ConfidenceLevel  `json:"confidence_level,omitempty" gorm:"type:varchar(10)"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// Relacionamentos
	Brace   Brace         `json:"brace,omitempty" gorm:"foreignKey:BraceID"`
	Patient *Patient      `json:"patient,omitempty" gorm:"foreignKey:PatientID"`
	Session *UsageSession `json:"session,omitempty" gorm:"foreignKey:SessionID"`
}

type ConfidenceLevel string

const (
	ConfidenceLow    ConfidenceLevel = "low"
	ConfidenceMedium ConfidenceLevel = "medium"
	ConfidenceHigh   ConfidenceLevel = "high"
)

// Métodos para SensorReading
func (sr *SensorReading) CalculateWearing() {
	// Lógica básica para determinar se está usando o colete
	// Baseada em pressão, posição e fechamento do colete
	
	wearing := false
	confidence := ConfidenceLow

	// Se há pressão detectada e o colete está fechado
	if sr.PressureDetected && sr.BraceClosed {
		wearing = true
		confidence = ConfidenceHigh
	} else if sr.PressureDetected || sr.BraceClosed {
		// Se apenas um dos sensores indica uso do colete
		wearing = true
		confidence = ConfidenceMedium
	}

	// Verificar se há movimento consistente com uso
	if sr.MovementDetected && (sr.AccelX != nil || sr.AccelY != nil || sr.AccelZ != nil) {
		if wearing {
			confidence = ConfidenceHigh
		} else {
			wearing = true
			confidence = ConfidenceLow
		}
	}

	sr.IsWearing = wearing
	sr.ConfidenceLevel = confidence
}

// TableName especifica o nome das tabelas
func (SensorReading) TableName() string {
	return "sensor_readings"
}