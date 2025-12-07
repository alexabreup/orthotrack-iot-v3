package models

import (
	"time"
	"gorm.io/gorm"
	"github.com/google/uuid"
)

type Patient struct {
	ID                      uint             `json:"id" gorm:"primaryKey"`
	UUID                    uuid.UUID        `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	ExternalID              string           `json:"external_id" gorm:"size:50;uniqueIndex;not null"` // ID da AACD
	InstitutionID           uint             `json:"institution_id" gorm:"not null;index"`
	MedicalStaffID          *uint            `json:"medical_staff_id,omitempty" gorm:"index"`
	
	// Dados Pessoais
	Name                    string           `json:"name" gorm:"size:100;not null"`
	DateOfBirth             *time.Time       `json:"date_of_birth,omitempty"`
	Gender                  string           `json:"gender" gorm:"size:1;check:gender IN ('M','F')"`
	CPF                     string           `json:"cpf" gorm:"size:14;uniqueIndex"`
	Email                   string           `json:"email" gorm:"size:100"`
	Phone                   string           `json:"phone" gorm:"size:20"`
	GuardianName            string           `json:"guardian_name" gorm:"size:100"`
	GuardianPhone           string           `json:"guardian_phone" gorm:"size:20"`
	
	// Dados Médicos
	MedicalRecord           string           `json:"medical_record" gorm:"size:50;uniqueIndex;not null"`
	DiagnosisCode           string           `json:"diagnosis_code" gorm:"size:20"`
	SeverityLevel           int              `json:"severity_level" gorm:"check:severity_level BETWEEN 1 AND 5"`
	ScoliosisType           string           `json:"scoliosis_type" gorm:"size:50"`
	
	// Prescrição
	PrescriptionHours       int              `json:"prescription_hours" gorm:"default:16"` // Horas/dia prescritas
	DailyUsageTargetMinutes int              `json:"daily_usage_target_minutes" gorm:"default:960"` // 16 horas em minutos
	TreatmentStart          time.Time        `json:"treatment_start"`
	TreatmentEnd            *time.Time       `json:"treatment_end,omitempty"`
	BracePrescriptionDate   *time.Time       `json:"brace_prescription_date,omitempty"`
	PrescriptionNotes       string           `json:"prescription_notes" gorm:"type:text"`
	
	// Agendamentos
	NextAppointment         *time.Time       `json:"next_appointment,omitempty"`
	LastAppointment         *time.Time       `json:"last_appointment,omitempty"`
	
	// Status
	Status                  string           `json:"status" gorm:"size:20;default:active;check:status IN ('active','inactive','completed','suspended')"`
	IsActive                bool             `json:"is_active" gorm:"default:true"`
	
	CreatedAt               time.Time        `json:"created_at"`
	UpdatedAt               time.Time        `json:"updated_at"`
	DeletedAt               gorm.DeletedAt   `json:"-" gorm:"index"`

	// Relacionamentos
	Institution    Institution   `json:"institution,omitempty" gorm:"foreignKey:InstitutionID"`
	MedicalStaff   *MedicalStaff `json:"medical_staff,omitempty" gorm:"foreignKey:MedicalStaffID"`
	Brace          *Brace        `json:"brace,omitempty" gorm:"foreignKey:PatientID"` // Colete ortopédico
	UsageSessions  []UsageSession `json:"usage_sessions,omitempty" gorm:"foreignKey:PatientID"`
	DailyCompliance []DailyCompliance `json:"daily_compliance,omitempty" gorm:"foreignKey:PatientID"`
	Alerts         []Alert       `json:"alerts,omitempty" gorm:"foreignKey:PatientID"`
}

type Institution struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID      `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	Name        string         `json:"name" gorm:"size:200;not null"`
	Code        string         `json:"code" gorm:"size:20;uniqueIndex;not null"` // Código da instituição
	CNPJ        string         `json:"cnpj" gorm:"size:18;uniqueIndex"`
	Address     string         `json:"address" gorm:"type:text"`
	City        string         `json:"city" gorm:"size:100"`
	State       string         `json:"state" gorm:"size:2"`
	ZipCode     string         `json:"zip_code" gorm:"size:9"`
	Phone       string         `json:"phone" gorm:"size:20"`
	Email       string         `json:"email" gorm:"size:100"`
	Website     string         `json:"website" gorm:"size:200"`
	Type        string         `json:"type" gorm:"size:50;default:hospital"` // hospital, clinic, center
	Status      string         `json:"status" gorm:"size:20;default:active;check:status IN ('active','inactive')"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// Relacionamentos
	Patients []Patient `json:"patients,omitempty" gorm:"foreignKey:InstitutionID"`
	MedicalStaff []MedicalStaff `json:"medical_staff,omitempty" gorm:"foreignKey:InstitutionID"`
}

type MedicalStaff struct {
	ID            uint           `json:"id" gorm:"primaryKey"`
	UUID          uuid.UUID      `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	InstitutionID uint           `json:"institution_id" gorm:"not null;index"`
	
	// Dados Pessoais
	Name          string         `json:"name" gorm:"size:100;not null"`
	Email         string         `json:"email" gorm:"size:100;uniqueIndex;not null"`
	Phone         string         `json:"phone" gorm:"size:20"`
	
	// Dados Profissionais
	CRM           string         `json:"crm" gorm:"size:20;uniqueIndex"`
	CRMState      string         `json:"crm_state" gorm:"size:2"`
	Specialty     string         `json:"specialty" gorm:"size:100"`
	Role          string         `json:"role" gorm:"size:50;default:physician"` // physician, physiotherapist, technician, admin
	Department    string         `json:"department" gorm:"size:100"`
	
	// Autenticação
	PasswordHash  string         `json:"-" gorm:"size:255;not null"` // Never return password hash
	LastLogin     *time.Time     `json:"last_login,omitempty"`
	IsActive      bool           `json:"is_active" gorm:"default:true"`
	Permissions   string         `json:"permissions" gorm:"type:text"` // JSON permissions
	
	CreatedAt     time.Time      `json:"created_at"`
	UpdatedAt     time.Time      `json:"updated_at"`
	DeletedAt     gorm.DeletedAt `json:"-" gorm:"index"`

	// Relacionamentos
	Institution Institution `json:"institution,omitempty" gorm:"foreignKey:InstitutionID"`
	Patients    []Patient   `json:"patients,omitempty" gorm:"foreignKey:MedicalStaffID"`
}

// TableName especifica o nome da tabela para cada modelo
func (Patient) TableName() string {
	return "patients"
}

func (Institution) TableName() string {
	return "institutions"
}

func (MedicalStaff) TableName() string {
	return "medical_staff"
}