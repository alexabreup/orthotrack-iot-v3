package models

import (
	"time"
	"github.com/google/uuid"
)

// AuditLog para compliance LGPD
type AuditLog struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID      `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	
	// Dados do acesso
	UserID      *uint          `json:"user_id" gorm:"index"`
	UserEmail   string         `json:"user_email" gorm:"size:100"`
	UserRole    string         `json:"user_role" gorm:"size:50"`
	
	// Dados acessados
	ResourceType string        `json:"resource_type" gorm:"size:50;not null"` // patient, brace, alert, etc.
	ResourceID   uint          `json:"resource_id" gorm:"not null;index"`
	PatientID    *uint         `json:"patient_id" gorm:"index"` // Para facilitar queries por paciente
	
	// Ação realizada
	Action      string         `json:"action" gorm:"size:50;not null"` // VIEW, UPDATE, CREATE, DELETE, EXPORT
	Details     string         `json:"details" gorm:"type:text"`
	
	// Contexto técnico
	IPAddress   string         `json:"ip_address" gorm:"size:45"`
	UserAgent   string         `json:"user_agent" gorm:"type:text"`
	RequestPath string         `json:"request_path" gorm:"size:255"`
	
	// LGPD específico
	LegalBasis  string         `json:"legal_basis" gorm:"size:100"` // legitimate_interest, consent, etc.
	DataTypes   string         `json:"data_types" gorm:"type:text"` // Tipos de dados acessados
	
	Timestamp   time.Time      `json:"timestamp" gorm:"not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
}

// ConsentLog para rastrear consentimentos LGPD
type ConsentLog struct {
	ID          uint           `json:"id" gorm:"primaryKey"`
	UUID        uuid.UUID      `json:"uuid" gorm:"type:uuid;default:gen_random_uuid();uniqueIndex"`
	
	PatientID   uint           `json:"patient_id" gorm:"not null;index"`
	
	// Dados do consentimento
	ConsentType string         `json:"consent_type" gorm:"size:100;not null"` // data_processing, medical_treatment, etc.
	Status      string         `json:"status" gorm:"size:20;not null"` // given, withdrawn, updated
	
	// Contexto
	GivenBy     string         `json:"given_by" gorm:"size:100"` // Nome do responsável/paciente
	GivenByType string         `json:"given_by_type" gorm:"size:20"` // patient, guardian, legal_representative
	Method      string         `json:"method" gorm:"size:50"` // digital_signature, paper_form, verbal
	
	// Documento
	DocumentHash string        `json:"document_hash" gorm:"size:64"` // SHA256 do documento de consentimento
	DocumentPath string        `json:"document_path" gorm:"size:500"` // Caminho do arquivo
	
	// Legal
	LegalBasis   string        `json:"legal_basis" gorm:"size:100;not null"`
	Purpose      string        `json:"purpose" gorm:"type:text;not null"`
	DataTypes    string        `json:"data_types" gorm:"type:text"`
	RetentionPeriod string     `json:"retention_period" gorm:"size:100"`
	
	// Metadados
	IPAddress    string        `json:"ip_address" gorm:"size:45"`
	UserAgent    string        `json:"user_agent" gorm:"type:text"`
	
	Timestamp    time.Time     `json:"timestamp" gorm:"not null;index"`
	ExpiresAt    *time.Time    `json:"expires_at"`
	CreatedAt    time.Time     `json:"created_at"`
	
	// Relacionamentos
	Patient      Patient       `json:"patient,omitempty" gorm:"foreignKey:PatientID"`
}

// Métodos para AuditLog
func (a *AuditLog) IsPatientDataAccess() bool {
	return a.PatientID != nil
}

func (a *AuditLog) IsPersonalDataAccess() bool {
	sensitiveResources := []string{"patient", "medical_record", "contact_info"}
	for _, resource := range sensitiveResources {
		if a.ResourceType == resource {
			return true
		}
	}
	return false
}

// Métodos para ConsentLog
func (c *ConsentLog) IsActive() bool {
	if c.Status != "given" {
		return false
	}
	if c.ExpiresAt != nil && c.ExpiresAt.Before(time.Now()) {
		return false
	}
	return true
}

func (c *ConsentLog) IsExpired() bool {
	return c.ExpiresAt != nil && c.ExpiresAt.Before(time.Now())
}

// TableName especifica o nome da tabela
func (AuditLog) TableName() string {
	return "audit_logs"
}

func (ConsentLog) TableName() string {
	return "consent_logs"
}