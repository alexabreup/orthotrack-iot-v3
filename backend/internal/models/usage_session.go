package models

import (
	"time"
	"gorm.io/gorm"
	"github.com/google/uuid"
)

// UsageSession representa uma sessão de uso do colete ortopédico
type UsageSession struct {
	ID        uint      `json:"id" gorm:"primaryKey"`
	UUID      uuid.UUID `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	
	// Relacionamentos
	BraceID   uint `json:"brace_id" gorm:"not null;index"`
	PatientID uint `json:"patient_id" gorm:"not null;index"`
	
	// Informações da Sessão
	StartTime    time.Time  `json:"start_time" gorm:"not null;index"`
	EndTime      *time.Time `json:"end_time" gorm:"index"`
	Duration     *int       `json:"duration"` // duração em segundos
	IsActive     bool       `json:"is_active" gorm:"default:true;index"`
	
	// Detecção Automática
	AutoDetected         bool    `json:"auto_detected" gorm:"default:true"`
	StartConfidence      float32 `json:"start_confidence"` // 0.0 - 1.0
	EndConfidence        *float32 `json:"end_confidence"`   // 0.0 - 1.0
	
	// Métricas de Qualidade
	ComplianceScore      float32 `json:"compliance_score"` // 0.0 - 100.0
	ComfortScore         float32 `json:"comfort_score"`    // 0.0 - 100.0
	PostureScore         float32 `json:"posture_score"`    // 0.0 - 100.0
	MovementScore        float32 `json:"movement_score"`   // 0.0 - 100.0
	
	// Estatísticas de Movimento
	AvgAcceleration      float32 `json:"avg_acceleration"`
	MaxAcceleration      float32 `json:"max_acceleration"`
	MovementVariability  float32 `json:"movement_variability"`
	RestPeriods          int     `json:"rest_periods"`
	ActivePeriods        int     `json:"active_periods"`
	
	// Estatísticas de Postura
	GoodPosturePct       float32 `json:"good_posture_pct"`     // % tempo com boa postura
	FairPosturePct       float32 `json:"fair_posture_pct"`     // % tempo com postura regular
	PoorPosturePct       float32 `json:"poor_posture_pct"`     // % tempo com postura ruim
	PostureAlerts        int     `json:"posture_alerts"`       // número de alertas de postura
	
	// Estatísticas de Conforto
	ComfortIssues        int     `json:"comfort_issues"`       // número de problemas de conforto
	AdjustmentEvents     int     `json:"adjustment_events"`    // número de ajustes detectados
	PressureWarnings     int     `json:"pressure_warnings"`    // avisos de pressão excessiva
	
	// Dados Ambientais
	AvgTemperature       *float32 `json:"avg_temperature"`
	MinTemperature       *float32 `json:"min_temperature"`
	MaxTemperature       *float32 `json:"max_temperature"`
	AvgHumidity          *float32 `json:"avg_humidity"`
	
	// Bateria durante a sessão
	StartBatteryLevel    *int     `json:"start_battery_level"`
	EndBatteryLevel      *int     `json:"end_battery_level"`
	BatteryConsumed      *float32 `json:"battery_consumed"`
	
	// Notas e Observações
	Notes                string   `json:"notes" gorm:"type:text"`
	PatientReported      bool     `json:"patient_reported"` // Se foi reportado pelo paciente
	Issues               string   `json:"issues" gorm:"type:text"`
	
	// Validação médica
	ValidatedBy          *uint    `json:"validated_by"` // MedicalStaff ID
	ValidatedAt          *time.Time `json:"validated_at"`
	ValidationNotes      string   `json:"validation_notes" gorm:"type:text"`
	
	// Dados de Localização (se aplicável)
	Location             string   `json:"location" gorm:"size:100"` // home, school, hospital, etc.
	Timezone             string   `json:"timezone" gorm:"size:50;default:America/Sao_Paulo"`
	
	CreatedAt            time.Time      `json:"created_at"`
	UpdatedAt            time.Time      `json:"updated_at"`
	DeletedAt            gorm.DeletedAt `json:"-" gorm:"index"`
	
	// Relacionamentos
	Brace        Brace        `json:"brace" gorm:"foreignKey:BraceID"`
	Patient      Patient      `json:"patient" gorm:"foreignKey:PatientID"`
	Validator    *MedicalStaff `json:"validator,omitempty" gorm:"foreignKey:ValidatedBy"`
	SensorReadings []SensorReading `json:"sensor_readings,omitempty" gorm:"foreignKey:SessionID"`
	SessionAlerts []Alert      `json:"session_alerts,omitempty" gorm:"foreignKey:SessionID"`
}

// DailyCompliance representa o compliance diário de um paciente
type DailyCompliance struct {
	ID           uint      `json:"id" gorm:"primaryKey"`
	UUID         uuid.UUID `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	
	// Relacionamentos
	PatientID    uint      `json:"patient_id" gorm:"not null;index"`
	BraceID      uint      `json:"brace_id" gorm:"not null;index"`
	
	// Data
	Date         time.Time `json:"date" gorm:"type:date;not null;index"`
	
	// Metas vs Realizado
	TargetMinutes     int     `json:"target_minutes" gorm:"not null"`      // Meta em minutos
	ActualMinutes     int     `json:"actual_minutes" gorm:"default:0"`     // Realizado em minutos
	CompliancePercent float32 `json:"compliance_percent" gorm:"default:0"` // % de compliance
	
	// Sessões do dia
	SessionCount      int     `json:"session_count" gorm:"default:0"`
	LongestSession    *int    `json:"longest_session"`    // duração da sessão mais longa
	ShortestSession   *int    `json:"shortest_session"`   // duração da sessão mais curta
	AvgSessionLength  *float32 `json:"avg_session_length"` // duração média das sessões
	
	// Qualidade do uso
	AvgComplianceScore float32 `json:"avg_compliance_score"` // 0.0 - 100.0
	AvgComfortScore    float32 `json:"avg_comfort_score"`    // 0.0 - 100.0
	AvgPostureScore    float32 `json:"avg_posture_score"`    // 0.0 - 100.0
	
	// Horários de uso
	FirstUsageTime    *time.Time `json:"first_usage_time"`    // primeiro uso do dia
	LastUsageTime     *time.Time `json:"last_usage_time"`     // último uso do dia
	NightUsageMinutes *int       `json:"night_usage_minutes"` // uso durante a noite
	DayUsageMinutes   *int       `json:"day_usage_minutes"`   // uso durante o dia
	
	// Problemas detectados
	PostureAlerts     int `json:"posture_alerts"`
	ComfortIssues     int `json:"comfort_issues"`
	BatteryWarnings   int `json:"battery_warnings"`
	DeviceDisconnects int `json:"device_disconnects"`
	
	// Status do dia
	IsCompliant       bool   `json:"is_compliant"`                             // atingiu meta
	Status            string `json:"status" gorm:"size:20;default:incomplete"` // incomplete, complete, missed
	Notes             string `json:"notes" gorm:"type:text"`
	
	// Dados reportados pelo paciente
	PatientRating     *int    `json:"patient_rating"`     // 1-5 rating do paciente
	PatientFeedback   string  `json:"patient_feedback" gorm:"type:text"`
	PainLevel         *int    `json:"pain_level"`         // 0-10 escala de dor
	ComfortLevel      *int    `json:"comfort_level"`      // 1-5 nível de conforto
	
	CreatedAt         time.Time      `json:"created_at"`
	UpdatedAt         time.Time      `json:"updated_at"`
	DeletedAt         gorm.DeletedAt `json:"-" gorm:"index"`
	
	// Relacionamentos
	Patient      Patient       `json:"patient" gorm:"foreignKey:PatientID"`
	Brace        Brace         `json:"brace" gorm:"foreignKey:BraceID"`
	Sessions     []UsageSession `json:"sessions,omitempty" gorm:"foreignKey:PatientID;where:DATE(start_time) = ?"`
}

// Métodos para UsageSession
func (us *UsageSession) CalculateDuration() {
	if us.EndTime != nil {
		duration := int(us.EndTime.Sub(us.StartTime).Seconds())
		us.Duration = &duration
	}
}

func (us *UsageSession) GetDurationHours() float64 {
	if us.Duration == nil {
		if us.IsActive {
			// Sessão ativa - calcular duração atual
			return time.Since(us.StartTime).Hours()
		}
		return 0
	}
	return float64(*us.Duration) / 3600.0
}

func (us *UsageSession) GetDurationMinutes() int {
	if us.Duration == nil {
		if us.IsActive {
			return int(time.Since(us.StartTime).Minutes())
		}
		return 0
	}
	return *us.Duration / 60
}

func (us *UsageSession) IsValidSession() bool {
	duration := us.GetDurationMinutes()
	return duration >= 5 // mínimo 5 minutos para ser considerada sessão válida
}

func (us *UsageSession) GetQualityScore() float32 {
	// Média ponderada dos scores
	return (us.ComplianceScore*0.4 + us.ComfortScore*0.3 + us.PostureScore*0.3)
}

func (us *UsageSession) EndSession() {
	now := time.Now()
	us.EndTime = &now
	us.IsActive = false
	us.CalculateDuration()
}

// Métodos para DailyCompliance
func (dc *DailyCompliance) CalculateCompliance() {
	if dc.TargetMinutes > 0 {
		dc.CompliancePercent = float32(dc.ActualMinutes) / float32(dc.TargetMinutes) * 100
		dc.IsCompliant = dc.CompliancePercent >= 80.0 // 80% considerado compliant
	}
}

func (dc *DailyCompliance) GetComplianceStatus() string {
	switch {
	case dc.CompliancePercent >= 100:
		return "excellent"
	case dc.CompliancePercent >= 90:
		return "very_good"
	case dc.CompliancePercent >= 80:
		return "good"
	case dc.CompliancePercent >= 60:
		return "fair"
	case dc.CompliancePercent >= 40:
		return "poor"
	default:
		return "very_poor"
	}
}

func (dc *DailyCompliance) GetRemainingMinutes() int {
	remaining := dc.TargetMinutes - dc.ActualMinutes
	if remaining < 0 {
		return 0
	}
	return remaining
}

func (dc *DailyCompliance) AddSession(session UsageSession) {
	if session.Duration != nil {
		minutes := *session.Duration / 60
		dc.ActualMinutes += minutes
		dc.SessionCount++
		
		// Atualizar estatísticas
		if dc.LongestSession == nil || minutes > *dc.LongestSession {
			dc.LongestSession = &minutes
		}
		if dc.ShortestSession == nil || minutes < *dc.ShortestSession {
			dc.ShortestSession = &minutes
		}
		
		// Calcular média
		avgMinutes := float32(dc.ActualMinutes) / float32(dc.SessionCount)
		dc.AvgSessionLength = &avgMinutes
		
		// Atualizar horários
		if dc.FirstUsageTime == nil || session.StartTime.Before(*dc.FirstUsageTime) {
			dc.FirstUsageTime = &session.StartTime
		}
		if dc.LastUsageTime == nil || session.StartTime.After(*dc.LastUsageTime) {
			if session.EndTime != nil {
				dc.LastUsageTime = session.EndTime
			} else {
				dc.LastUsageTime = &session.StartTime
			}
		}
		
		// Recalcular compliance
		dc.CalculateCompliance()
	}
}

// TableNames
func (UsageSession) TableName() string {
	return "usage_sessions"
}

func (DailyCompliance) TableName() string {
	return "daily_compliance"
}