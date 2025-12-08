package handlers

import (
	"net/http"
	"strconv"
	"time"

	"orthotrack-iot-v3/internal/models"
	"orthotrack-iot-v3/pkg/validators"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PatientHandler struct {
	db *gorm.DB
}

func NewPatientHandler(db *gorm.DB) *PatientHandler {
	return &PatientHandler{db: db}
}

type CreatePatientRequest struct {
	ExternalID            string     `json:"external_id" binding:"required"`
	Name                  string     `json:"name" binding:"required"`
	DateOfBirth           *time.Time `json:"date_of_birth"`
	Gender                string     `json:"gender"`
	CPF                   string     `json:"cpf"`
	Email                 string     `json:"email"`
	Phone                 string     `json:"phone"`
	GuardianName          string     `json:"guardian_name"`
	GuardianPhone         string     `json:"guardian_phone"`
	MedicalRecord         string     `json:"medical_record"`
	DiagnosisCode         string     `json:"diagnosis_code"`
	SeverityLevel         int        `json:"severity_level"`
	ScoliosisType         string     `json:"scoliosis_type"`
	PrescriptionHours     int        `json:"prescription_hours"`
	DailyUsageTargetMinutes int       `json:"daily_usage_target_minutes"`
	TreatmentStart        *time.Time  `json:"treatment_start"`
	PrescriptionNotes     string     `json:"prescription_notes"`
}

type UpdatePatientRequest struct {
	Name                  *string    `json:"name"`
	DateOfBirth           *time.Time `json:"date_of_birth"`
	Gender                *string    `json:"gender"`
	CPF                   *string    `json:"cpf"`
	Email                 *string    `json:"email"`
	Phone                 *string    `json:"phone"`
	GuardianName          *string    `json:"guardian_name"`
	GuardianPhone         *string    `json:"guardian_phone"`
	DiagnosisCode         *string    `json:"diagnosis_code"`
	SeverityLevel         *int       `json:"severity_level"`
	ScoliosisType         *string    `json:"scoliosis_type"`
	PrescriptionHours     *int       `json:"prescription_hours"`
	DailyUsageTargetMinutes *int     `json:"daily_usage_target_minutes"`
	Status                *string    `json:"status"`
	IsActive              *bool      `json:"is_active"`
	NextAppointment       *time.Time `json:"next_appointment"`
	PrescriptionNotes     *string    `json:"prescription_notes"`
}

func (h *PatientHandler) GetPatients(c *gin.Context) {
	var patients []models.Patient
	
	query := h.db.Model(&models.Patient{}).Preload("Institution").Preload("MedicalStaff")
	
	// Filtros
	if institutionID := c.Query("institution_id"); institutionID != "" {
		query = query.Where("institution_id = ?", institutionID)
	}
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if isActive := c.Query("is_active"); isActive != "" {
		query = query.Where("is_active = ?", isActive == "true")
	}
	if search := c.Query("search"); search != "" {
		query = query.Where("name ILIKE ? OR external_id ILIKE ? OR medical_record ILIKE ?", 
			"%"+search+"%", "%"+search+"%", "%"+search+"%")
	}
	
	// Paginação
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit
	
	var total int64
	query.Count(&total)
	
	if err := query.Offset(offset).Limit(limit).Find(&patients).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"data": patients,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	})
}

func (h *PatientHandler) GetPatient(c *gin.Context) {
	id := c.Param("id")
	
	var patient models.Patient
	if err := h.db.Preload("Institution").Preload("MedicalStaff").First(&patient, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Patient not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, patient)
}

func (h *PatientHandler) CreatePatient(c *gin.Context) {
	var req CreatePatientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	// Validações
	if err := validators.ValidateRequired(req.ExternalID, "external_id"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := validators.ValidateRequired(req.Name, "name"); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	// Medical record é opcional, mas se fornecido não pode ser vazio
	if req.MedicalRecord != "" {
		if err := validators.ValidateRequired(req.MedicalRecord, "medical_record"); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.CPF != "" {
		if err := validators.ValidateCPF(req.CPF); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.Email != "" {
		if err := validators.ValidateEmail(req.Email); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.Phone != "" {
		if err := validators.ValidatePhone(req.Phone); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.Gender != "" {
		if err := validators.ValidateGender(req.Gender); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.DateOfBirth != nil {
		if err := validators.ValidateDateOfBirth(req.DateOfBirth); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.SeverityLevel > 0 {
		if err := validators.ValidateSeverityLevel(req.SeverityLevel); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.PrescriptionHours > 0 {
		if err := validators.ValidatePrescriptionHours(req.PrescriptionHours); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	if req.DailyUsageTargetMinutes > 0 {
		if err := validators.ValidateDailyUsageTarget(req.DailyUsageTargetMinutes); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}
	
	// Verificar se external_id já existe
	var existing models.Patient
	if err := h.db.Where("external_id = ?", req.ExternalID).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Paciente com este external_id já existe"})
		return
	}
	
	// Verificar se medical_record já existe (apenas se foi fornecido)
	if req.MedicalRecord != "" {
		if err := h.db.Where("medical_record = ?", req.MedicalRecord).First(&existing).Error; err == nil {
			c.JSON(http.StatusConflict, gin.H{"error": "Paciente com este prontuário já existe"})
			return
		}
	}
	
	// Obter institution_id do token JWT
	institutionID, exists := c.Get("institution_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Institution ID not found"})
		return
	}
	
	patient := models.Patient{
		ExternalID:              req.ExternalID,
		InstitutionID:           institutionID.(uint),
		Name:                    req.Name,
		DateOfBirth:             req.DateOfBirth,
		Gender:                  req.Gender,
		CPF:                     req.CPF,
		Email:                   req.Email,
		Phone:                   req.Phone,
		GuardianName:            req.GuardianName,
		GuardianPhone:           req.GuardianPhone,
		MedicalRecord:           req.MedicalRecord,
		DiagnosisCode:           req.DiagnosisCode,
		SeverityLevel:           req.SeverityLevel,
		ScoliosisType:           req.ScoliosisType,
		PrescriptionHours:       req.PrescriptionHours,
		DailyUsageTargetMinutes: req.DailyUsageTargetMinutes,
		TreatmentStart:          req.TreatmentStart,
		PrescriptionNotes:       req.PrescriptionNotes,
		Status:                  "active",
		IsActive:                true,
	}
	
	if patient.PrescriptionHours == 0 {
		patient.PrescriptionHours = 16
	}
	if patient.DailyUsageTargetMinutes == 0 {
		patient.DailyUsageTargetMinutes = 960 // 16 horas
	}
	
	if err := h.db.Create(&patient).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusCreated, patient)
}

func (h *PatientHandler) UpdatePatient(c *gin.Context) {
	id := c.Param("id")
	
	var patient models.Patient
	if err := h.db.First(&patient, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Patient not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	var req UpdatePatientRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	// Atualizar campos fornecidos
	if req.Name != nil {
		patient.Name = *req.Name
	}
	if req.DateOfBirth != nil {
		patient.DateOfBirth = req.DateOfBirth
	}
	if req.Gender != nil {
		patient.Gender = *req.Gender
	}
	if req.CPF != nil {
		patient.CPF = *req.CPF
	}
	if req.Email != nil {
		patient.Email = *req.Email
	}
	if req.Phone != nil {
		patient.Phone = *req.Phone
	}
	if req.Status != nil {
		patient.Status = *req.Status
	}
	if req.IsActive != nil {
		patient.IsActive = *req.IsActive
	}
	if req.NextAppointment != nil {
		patient.NextAppointment = req.NextAppointment
	}
	if req.PrescriptionNotes != nil {
		patient.PrescriptionNotes = *req.PrescriptionNotes
	}
	
	if err := h.db.Save(&patient).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, patient)
}

func (h *PatientHandler) DeletePatient(c *gin.Context) {
	id := c.Param("id")
	
	if err := h.db.Delete(&models.Patient{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"message": "Patient deleted successfully"})
}

