package handlers

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"orthotrack-iot-v3/internal/models"
	"orthotrack-iot-v3/internal/services"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

type IoTHandler struct {
	iotService   *services.IoTService
	alertService *services.AlertService
	upgrader     websocket.Upgrader
	clients      map[*websocket.Conn]bool
	clientsMutex sync.RWMutex
	broadcast    chan []byte
}

func NewIoTHandler(iotService *services.IoTService, alertService *services.AlertService) *IoTHandler {
	handler := &IoTHandler{
		iotService:   iotService,
		alertService: alertService,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins in development
			},
		},
		clients:   make(map[*websocket.Conn]bool),
		broadcast: make(chan []byte),
	}
	
	// Start WebSocket broadcast goroutine
	go handler.handleBroadcasts()
	
	return handler
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
		DeviceID      string `json:"device_id" binding:"required"`
		Status        string `json:"status"`
		BatteryLevel  *int   `json:"battery_level"`
		SignalStrength *int `json:"signal_strength"`
	}

	if err := c.ShouldBindJSON(&status); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Atualizar status do dispositivo via telemetria
	telemetry := services.TelemetryData{
		DeviceID:     status.DeviceID,
		Status:       status.Status,
		BatteryLevel: status.BatteryLevel,
		Timestamp:    time.Now(),
	}

	ctx := context.Background()
	if err := h.iotService.ProcessTelemetry(ctx, telemetry); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
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
	// Processar alerta
	if err := h.alertService.CreateAlert(ctx, &alert); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
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
	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("Failed to upgrade connection: %v", err)
		return
	}
	defer conn.Close()

	// Register client
	h.clientsMutex.Lock()
	h.clients[conn] = true
	h.clientsMutex.Unlock()

	// Clean up when client disconnects
	defer func() {
		h.clientsMutex.Lock()
		delete(h.clients, conn)
		h.clientsMutex.Unlock()
	}()

	// Send initial status
	h.sendInitialStatus(conn)

	// Keep connection alive and handle incoming messages
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			log.Printf("WebSocket read error: %v", err)
			break
		}
		// Echo received messages or handle specific commands
	}
}

func (h *IoTHandler) handleBroadcasts() {
	for {
		message := <-h.broadcast
		h.clientsMutex.RLock()
		for client := range h.clients {
			err := client.WriteMessage(websocket.TextMessage, message)
			if err != nil {
				log.Printf("WebSocket write error: %v", err)
				client.Close()
				delete(h.clients, client)
			}
		}
		h.clientsMutex.RUnlock()
	}
}

func (h *IoTHandler) sendInitialStatus(conn *websocket.Conn) {
	// Send current system status
	status := map[string]interface{}{
		"type":      "status",
		"timestamp": time.Now(),
		"message":   "Connected to OrtoTrack IoT Platform",
	}
	
	if data, err := json.Marshal(status); err == nil {
		conn.WriteMessage(websocket.TextMessage, data)
	}
}

func (h *IoTHandler) BroadcastRealtimeData(data interface{}) {
	if jsonData, err := json.Marshal(data); err == nil {
		select {
		case h.broadcast <- jsonData:
		default:
			// Channel is full, skip this broadcast
		}
	}
}

