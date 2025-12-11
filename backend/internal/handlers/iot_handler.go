package handlers

import (
	"context"
	"log"
	"net/http"
	"strconv"
	"time"

	"orthotrack-iot-v3/internal/models"
	"orthotrack-iot-v3/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

type IoTHandler struct {
	iotService   *services.IoTService
	alertService *services.AlertService
	wsServer     *services.WSServer
	eventHandler *services.EventHandler
	upgrader     websocket.Upgrader
}

func NewIoTHandler(iotService *services.IoTService, alertService *services.AlertService) *IoTHandler {
	return &IoTHandler{
		iotService:   iotService,
		alertService: alertService,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins in development
			},
			ReadBufferSize:  1024,
			WriteBufferSize: 1024,
		},
	}
}

// SetWSServer sets the WebSocket server for the handler
func (h *IoTHandler) SetWSServer(wsServer *services.WSServer) {
	h.wsServer = wsServer
}

// SetEventHandler sets the event handler for the handler
func (h *IoTHandler) SetEventHandler(eventHandler *services.EventHandler) {
	h.eventHandler = eventHandler
}

func (h *IoTHandler) ReceiveTelemetry(c *gin.Context) {
	var data services.TelemetryData
	if err := c.ShouldBindJSON(&data); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	// Processar telemetria através do serviço IoT
	if err := h.iotService.ProcessTelemetry(ctx, data); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Telemetry received"})
}

func (h *IoTHandler) ReceiveDeviceStatus(c *gin.Context) {
	var status struct {
		DeviceID       string `json:"device_id" binding:"required"`
		Status         string `json:"status"`
		BatteryLevel   *int   `json:"battery_level"`
		SignalStrength *int   `json:"signal_strength"`
		FirmwareVersion string `json:"firmware_version"`
	}

	if err := c.ShouldBindJSON(&status); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	
	// Update device status in database
	if err := h.iotService.UpdateDeviceStatus(ctx, status.DeviceID, status.Status, 
		status.BatteryLevel, status.SignalStrength, status.FirmwareVersion); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Get updated brace information for WebSocket event
	var brace models.Brace
	if err := h.iotService.GetDB().Where("device_id = ?", status.DeviceID).First(&brace).Error; err != nil {
		log.Printf("Warning: Could not find brace for WebSocket event: %v", err)
	} else {
		// Publish WebSocket event for device status change
		if h.eventHandler != nil {
			deviceStatus := models.DeviceStatus(status.Status)
			if err := h.eventHandler.PublishDeviceStatusEvent(ctx, status.DeviceID, deviceStatus, &brace); err != nil {
				log.Printf("Warning: Failed to publish device status event: %v", err)
			}
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Status updated"})
}

func (h *IoTHandler) ReceiveDeviceAlert(c *gin.Context) {
	var alert models.Alert
	if err := c.ShouldBindJSON(&alert); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	
	// Create alert in database
	if err := h.alertService.CreateAlert(ctx, &alert); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Get patient name for WebSocket event
	var patientName string
	if alert.PatientID != nil {
		var patient models.Patient
		if err := h.iotService.GetDB().Select("name").First(&patient, *alert.PatientID).Error; err == nil {
			patientName = patient.Name
		}
	}

	// Publish WebSocket event for new alert
	if h.eventHandler != nil {
		if err := h.eventHandler.PublishAlertEvent(ctx, &alert, patientName); err != nil {
			log.Printf("Warning: Failed to publish alert event: %v", err)
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert received"})
}

func (h *IoTHandler) ReceiveCommandResponse(c *gin.Context) {
	var response struct {
		CommandID uint   `json:"command_id" binding:"required"`
		Status    string `json:"status" binding:"required"`
		Response  models.DeviceConfig `json:"response"`
		Error     string `json:"error"`
	}

	if err := c.ShouldBindJSON(&response); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx := context.Background()
	if err := h.iotService.ProcessCommandResponse(ctx, response.CommandID, response.Status, response.Response, response.Error); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Command response received"})
}

func (h *IoTHandler) SendCommand(c *gin.Context) {
	braceID := c.Param("id")
	
	var req struct {
		CommandType string            `json:"command_type" binding:"required"`
		Parameters  models.DeviceConfig `json:"parameters"`
		Priority    string            `json:"priority"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Buscar brace
	var brace models.Brace
	if err := h.iotService.GetDB().First(&brace, braceID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Brace not found"})
		return
	}

	// Criar comando
	userID, _ := c.Get("user_id")
	command := models.BraceCommand{
		BraceID:     brace.ID,
		SentBy:      userID.(uint),
		CommandType: models.CommandType(req.CommandType),
		Parameters:  req.Parameters,
		Status:      models.CommandStatusPending,
		Priority:    models.CommandPriority(req.Priority),
	}

	if command.Priority == "" {
		command.Priority = models.CommandPriorityNormal
	}

	if err := h.iotService.GetDB().Create(&command).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// Enviar comando via MQTT
	ctx := context.Background()
	if err := h.iotService.SendCommand(ctx, brace.DeviceID, command); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, command)
}

func (h *IoTHandler) GetCommands(c *gin.Context) {
	braceID := c.Param("id")
	status := c.Query("status")

	query := h.iotService.GetDB().Model(&models.BraceCommand{}).Where("brace_id = ?", braceID)

	if status != "" {
		query = query.Where("status = ?", status)
	}

	var commands []models.BraceCommand
	if err := query.Order("created_at DESC").Find(&commands).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, commands)
}

func (h *IoTHandler) GetAlerts(c *gin.Context) {
	ctx := context.Background()

	filters := services.AlertFilters{}

	if patientID := c.Query("patient_id"); patientID != "" {
		if id, err := strconv.ParseUint(patientID, 10, 32); err == nil {
			pid := uint(id)
			filters.PatientID = &pid
		}
	}
	if braceID := c.Query("brace_id"); braceID != "" {
		if id, err := strconv.ParseUint(braceID, 10, 32); err == nil {
			bid := uint(id)
			filters.BraceID = &bid
		}
	}
	if severity := c.Query("severity"); severity != "" {
		filters.Severity = severity
	}
	if resolved := c.Query("resolved"); resolved != "" {
		r := resolved == "true"
		filters.Resolved = &r
	}

	// Paginação
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	filters.Offset = (page - 1) * limit
	filters.Limit = limit

	alerts, err := h.alertService.GetAlerts(ctx, filters)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": alerts,
		"pagination": gin.H{
			"page":  page,
			"limit": limit,
		},
	})
}

func (h *IoTHandler) ResolveAlert(c *gin.Context) {
	id := c.Param("id")
	alertID, err := strconv.ParseUint(id, 10, 32)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid alert ID"})
		return
	}
	
	userID, _ := c.Get("user_id")
	var resolvedBy *uint
	if uid, ok := userID.(uint); ok {
		resolvedBy = &uid
	}

	var req struct {
		Notes string `json:"notes"`
	}
	c.ShouldBindJSON(&req)

	ctx := context.Background()
	if err := h.alertService.ResolveAlert(ctx, uint(alertID), resolvedBy, req.Notes); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alert resolved"})
}

func (h *IoTHandler) GetAlertStatistics(c *gin.Context) {
	periodStr := c.DefaultQuery("period", "24h")
	period, _ := time.ParseDuration(periodStr)
	if period == 0 {
		period = 24 * time.Hour
	}

	ctx := context.Background()
	stats, err := h.alertService.GetAlertStatistics(ctx, period)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, stats)
}

func (h *IoTHandler) HandleWebSocket(c *gin.Context) {
	// Upgrade HTTP connection to WebSocket
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to upgrade to WebSocket"})
		return
	}

	// Create new client
	client := &services.Client{
		ID:            uuid.New().String(),
		Conn:          conn,
		Send:          make(chan []byte, 256),
		Subscriptions: make(map[string]bool),
		UserID:        "", // Will be set after authentication
		LastPong:      time.Now(),
	}

	// Register client with WebSocket server
	if h.wsServer != nil {
		h.wsServer.Register <- client

		// Start client read and write pumps
		go client.WritePump(h.wsServer)
		go client.ReadPump(h.wsServer)
	} else {
		log.Printf("WebSocket server not initialized")
		conn.Close()
	}
}

