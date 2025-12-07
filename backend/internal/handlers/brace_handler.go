package handlers

import (
	"net/http"
	"strconv"

	"orthotrack-iot-v3/internal/models"
	"orthotrack-iot-v3/pkg/validators"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type BraceHandler struct {
	db *gorm.DB
}

func NewBraceHandler(db *gorm.DB) *BraceHandler {
	return &BraceHandler{db: db}
}

type CreateBraceRequest struct {
	DeviceID        string `json:"device_id" binding:"required"`
	SerialNumber    string `json:"serial_number" binding:"required"`
	MacAddress      string `json:"mac_address" binding:"required"`
	Model           string `json:"model"`
	Version         string `json:"version"`
	PatientID       *uint  `json:"patient_id"`
}

type UpdateBraceRequest struct {
	PatientID       *uint   `json:"patient_id"`
	Status          *string `json:"status"`
	BatteryLevel    *int    `json:"battery_level"`
	FirmwareVersion *string `json:"firmware_version"`
	Config          *models.DeviceConfig `json:"config"`
}

func (h *BraceHandler) GetBraces(c *gin.Context) {
	var braces []models.Brace
	
	query := h.db.Model(&models.Brace{}).Preload("Patient")
	
	// Filtros
	if patientID := c.Query("patient_id"); patientID != "" {
		query = query.Where("patient_id = ?", patientID)
	}
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}
	if deviceID := c.Query("device_id"); deviceID != "" {
		query = query.Where("device_id = ?", deviceID)
	}
	
	// Paginação
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	offset := (page - 1) * limit
	
	var total int64
	query.Count(&total)
	
	if err := query.Offset(offset).Limit(limit).Find(&braces).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{
		"data": braces,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	})
}

func (h *BraceHandler) GetBrace(c *gin.Context) {
	id := c.Param("id")
	
	var brace models.Brace
	if err := h.db.Preload("Patient").First(&brace, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Brace not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, brace)
}

func (h *BraceHandler) CreateBrace(c *gin.Context) {
	var req CreateBraceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	// Validações
	if err := validators.ValidateDeviceID(req.DeviceID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := validators.ValidateMacAddress(req.MacAddress); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	if err := validators.ValidateSerialNumber(req.SerialNumber); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	// Verificar se device_id já existe
	var existing models.Brace
	if err := h.db.Where("device_id = ?", req.DeviceID).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Dispositivo com este device_id já existe"})
		return
	}
	
	// Verificar se serial_number já existe
	if err := h.db.Where("serial_number = ?", req.SerialNumber).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Dispositivo com este serial_number já existe"})
		return
	}
	
	// Verificar se mac_address já existe
	if err := h.db.Where("mac_address = ?", req.MacAddress).First(&existing).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "Dispositivo com este mac_address já existe"})
		return
	}
	
	brace := models.Brace{
		DeviceID:     req.DeviceID,
		SerialNumber: req.SerialNumber,
		MacAddress:   req.MacAddress,
		Model:        req.Model,
		Version:      req.Version,
		PatientID:    req.PatientID,
		Status:       models.DeviceStatusOffline,
	}
	
	if brace.Model == "" {
		brace.Model = "ESP32-ORTHO-V1"
	}
	if brace.Version == "" {
		brace.Version = "1.0"
	}
	
	if err := h.db.Create(&brace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusCreated, brace)
}

func (h *BraceHandler) UpdateBrace(c *gin.Context) {
	id := c.Param("id")
	
	var brace models.Brace
	if err := h.db.First(&brace, id).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"error": "Brace not found"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	var req UpdateBraceRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	
	if req.PatientID != nil {
		brace.PatientID = req.PatientID
	}
	if req.Status != nil {
		brace.Status = models.DeviceStatus(*req.Status)
	}
	if req.BatteryLevel != nil {
		brace.BatteryLevel = req.BatteryLevel
	}
	if req.FirmwareVersion != nil {
		brace.FirmwareVersion = *req.FirmwareVersion
	}
	if req.Config != nil {
		brace.Config = *req.Config
	}
	
	if err := h.db.Save(&brace).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, brace)
}

func (h *BraceHandler) DeleteBrace(c *gin.Context) {
	id := c.Param("id")
	
	if err := h.db.Delete(&models.Brace{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	
	c.JSON(http.StatusOK, gin.H{"message": "Brace deleted successfully"})
}

