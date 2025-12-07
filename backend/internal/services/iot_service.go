package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"orthotrack-iot-v3/internal/config"
	"orthotrack-iot-v3/internal/models"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"
)

type IoTService struct {
	db          *gorm.DB
	redis       *redis.Client
	config      *config.Config
	mqttService *MQTTService
	alertService *AlertService
}

type TelemetryData struct {
	DeviceID    string                 `json:"device_id"`
	Timestamp   time.Time              `json:"timestamp"`
	Sensors     map[string]SensorData  `json:"sensors"`
	BatteryLevel *int                  `json:"battery_level,omitempty"`
	Status      string                 `json:"status,omitempty"`
}

type SensorData struct {
	Type  string      `json:"type"`
	Value interface{} `json:"value"`
	Unit  string      `json:"unit,omitempty"`
}

func NewIoTService(db *gorm.DB, redis *redis.Client, config *config.Config) *IoTService {
	return &IoTService{
		db:     db,
		redis:  redis,
		config: config,
	}
}

func (s *IoTService) SetMQTTService(mqtt *MQTTService) {
	s.mqttService = mqtt
}

func (s *IoTService) SetAlertService(alert *AlertService) {
	s.alertService = alert
}

func (s *IoTService) GetDB() *gorm.DB {
	return s.db
}

// ProcessTelemetry processa dados de telemetria recebidos
func (s *IoTService) ProcessTelemetry(ctx context.Context, data TelemetryData) error {
	log.Printf("Processing telemetry for device: %s", data.DeviceID)

	// Buscar dispositivo no banco
	var brace models.Brace
	if err := s.db.Where("device_id = ?", data.DeviceID).First(&brace).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			log.Printf("Device not found: %s", data.DeviceID)
			return fmt.Errorf("device not found: %s", data.DeviceID)
		}
		return fmt.Errorf("error finding device: %v", err)
	}

	// Atualizar última comunicação
	brace.UpdateHeartbeat()
	if data.BatteryLevel != nil {
		brace.BatteryLevel = data.BatteryLevel
	}

	if err := s.db.Save(&brace).Error; err != nil {
		return fmt.Errorf("error updating device: %v", err)
	}

	// Criar leitura de sensor
	sensorReading := s.createSensorReading(&brace, data)
	if err := s.db.Create(&sensorReading).Error; err != nil {
		return fmt.Errorf("error creating sensor reading: %v", err)
	}

	// Cache dos dados mais recentes
	s.cacheTelemetryData(ctx, data.DeviceID, data)

	// Processar alertas
	s.processAlerts(ctx, &brace, &sensorReading, data)

	// Atualizar sessão de uso se necessário
	s.updateUsageSession(ctx, &brace, &sensorReading)

	// Publicar dados em tempo real via WebSocket
	s.publishRealtimeData(ctx, data.DeviceID, data)

	return nil
}

func (s *IoTService) createSensorReading(brace *models.Brace, data TelemetryData) models.SensorReading {
	reading := models.SensorReading{
		BraceID:   brace.ID,
		PatientID: brace.PatientID,
		Timestamp: data.Timestamp,
	}

	// Processar cada sensor
	for sensorType, sensorData := range data.Sensors {
		switch sensorType {
		case "accelerometer":
			if axes, ok := sensorData.Value.(map[string]interface{}); ok {
				if x, ok := axes["x"].(float64); ok {
					reading.AccelX = &x
				}
				if y, ok := axes["y"].(float64); ok {
					reading.AccelY = &y
				}
				if z, ok := axes["z"].(float64); ok {
					reading.AccelZ = &z
				}
			}

		case "gyroscope":
			if axes, ok := sensorData.Value.(map[string]interface{}); ok {
				if x, ok := axes["x"].(float64); ok {
					reading.GyroX = &x
				}
				if y, ok := axes["y"].(float64); ok {
					reading.GyroY = &y
				}
				if z, ok := axes["z"].(float64); ok {
					reading.GyroZ = &z
				}
			}

		case "temperature":
			if temp, ok := sensorData.Value.(float64); ok {
				reading.Temperature = &temp
			}

		case "humidity":
			if hum, ok := sensorData.Value.(float64); ok {
				reading.Humidity = &hum
			}

		case "pressure":
			if pressure, ok := sensorData.Value.(map[string]interface{}); ok {
				if detected, ok := pressure["detected"].(bool); ok {
					reading.PressureDetected = detected
				}
				if value, ok := pressure["value"].(float64); ok {
					intValue := int(value)
					reading.PressureValue = &intValue
				}
			}

		case "magnetic":
			if mag, ok := sensorData.Value.(map[string]interface{}); ok {
				if closed, ok := mag["brace_closed"].(bool); ok {
					reading.BraceClosed = closed
				}
			}

		case "movement":
			if detected, ok := sensorData.Value.(bool); ok {
				reading.MovementDetected = detected
			}
		}
	}

	// Calcular se está usando o aparelho
	reading.CalculateWearing()

	return reading
}

func (s *IoTService) processAlerts(ctx context.Context, brace *models.Brace, reading *models.SensorReading, data TelemetryData) {
	if s.alertService == nil {
		return
	}

	// Verificar bateria baixa
	if brace.BatteryLevel != nil && *brace.BatteryLevel < s.config.IoT.AlertThresholds.BatteryLow {
		s.alertService.CreateAlert(ctx, &models.Alert{
			BraceID:   &brace.ID,
			PatientID: brace.PatientID,
			Type:      models.AlertTypeBatteryLow,
			Severity:  models.SeverityHigh,
			Title:     "Bateria Baixa",
			Message:   fmt.Sprintf("Bateria do dispositivo %s está em %d%%", brace.DeviceID, *brace.BatteryLevel),
			Value:     nil,
			Threshold: nil,
		})
	}

	// Verificar temperatura
	if reading.Temperature != nil {
		temp := *reading.Temperature
		if temp > s.config.IoT.AlertThresholds.TempHigh {
			s.alertService.CreateAlert(ctx, &models.Alert{
				BraceID:   &brace.ID,
				PatientID: brace.PatientID,
				Type:      models.AlertTypeTemperatureHigh,
				Severity:  models.SeverityMedium,
				Title:     "Temperatura Alta",
				Message:   fmt.Sprintf("Temperatura do dispositivo %s está em %.1f°C", brace.DeviceID, temp),
				Value:     &temp,
				Threshold: &s.config.IoT.AlertThresholds.TempHigh,
			})
		} else if temp < s.config.IoT.AlertThresholds.TempLow {
			s.alertService.CreateAlert(ctx, &models.Alert{
				BraceID:   &brace.ID,
				PatientID: brace.PatientID,
				Type:      models.AlertTypeTemperatureLow,
				Severity:  models.SeverityMedium,
				Title:     "Temperatura Baixa",
				Message:   fmt.Sprintf("Temperatura do dispositivo %s está em %.1f°C", brace.DeviceID, temp),
				Value:     &temp,
				Threshold: &s.config.IoT.AlertThresholds.TempLow,
			})
		}
	}
}

func (s *IoTService) updateUsageSession(ctx context.Context, brace *models.Brace, reading *models.SensorReading) {
	if !reading.IsWearing {
		// Se não está usando, finalizar sessão ativa se existir
		if brace.PatientID != nil {
			s.endActiveSession(ctx, *brace.PatientID, brace.ID)
		}
		return
	}

	if brace.PatientID == nil {
		return
	}

	// Se está usando, verificar se há sessão ativa
	var activeSession models.UsageSession
	err := s.db.Where("brace_id = ? AND patient_id = ? AND is_active = ?", 
		brace.ID, *brace.PatientID, true).
		First(&activeSession).Error

	if err == gorm.ErrRecordNotFound {
		// Criar nova sessão
		newSession := models.UsageSession{
			PatientID: *brace.PatientID,
			BraceID:   brace.ID,
			StartTime: reading.Timestamp,
			IsActive:  true,
			AutoDetected: true,
		}

		if err := s.db.Create(&newSession).Error; err != nil {
			log.Printf("Error creating usage session: %v", err)
		} else {
			log.Printf("Started new usage session for device %s", brace.DeviceID)
		}
	}
}

func (s *IoTService) endActiveSession(ctx context.Context, patientID uint, braceID uint) {
	var activeSession models.UsageSession
	err := s.db.Where("brace_id = ? AND patient_id = ? AND is_active = ?", 
		braceID, patientID, true).
		First(&activeSession).Error

	if err == nil {
		activeSession.EndSession()
		if err := s.db.Save(&activeSession).Error; err != nil {
			log.Printf("Error ending usage session: %v", err)
		} else {
			duration := activeSession.GetDurationMinutes()
			log.Printf("Ended usage session for brace %d, duration: %d minutes", 
				braceID, duration)
		}
	}
}

func (s *IoTService) cacheTelemetryData(ctx context.Context, deviceID string, data TelemetryData) {
	key := fmt.Sprintf("telemetry:%s", deviceID)
	
	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling telemetry data: %v", err)
		return
	}

	// Cache por 1 hora
	err = s.redis.Set(ctx, key, jsonData, time.Hour).Err()
	if err != nil {
		log.Printf("Error caching telemetry data: %v", err)
	}
}

func (s *IoTService) publishRealtimeData(ctx context.Context, deviceID string, data TelemetryData) {
	// Publicar dados para WebSocket via Redis pub/sub
	channel := fmt.Sprintf("realtime:telemetry:%s", deviceID)
	
	jsonData, err := json.Marshal(data)
	if err != nil {
		log.Printf("Error marshaling realtime data: %v", err)
		return
	}

	err = s.redis.Publish(ctx, channel, jsonData).Err()
	if err != nil {
		log.Printf("Error publishing realtime data: %v", err)
	}

	// Também publicar no canal geral
	err = s.redis.Publish(ctx, "realtime:telemetry", jsonData).Err()
	if err != nil {
		log.Printf("Error publishing to general realtime channel: %v", err)
	}
}

// GetDeviceStatus retorna o status atual do dispositivo
func (s *IoTService) GetDeviceStatus(ctx context.Context, deviceID string) (*TelemetryData, error) {
	key := fmt.Sprintf("telemetry:%s", deviceID)
	
	data, err := s.redis.Get(ctx, key).Result()
	if err == redis.Nil {
		return nil, fmt.Errorf("no telemetry data found for device: %s", deviceID)
	}
	if err != nil {
		return nil, fmt.Errorf("error retrieving telemetry data: %v", err)
	}

	var telemetry TelemetryData
	if err := json.Unmarshal([]byte(data), &telemetry); err != nil {
		return nil, fmt.Errorf("error unmarshaling telemetry data: %v", err)
	}

	return &telemetry, nil
}

// SendCommand envia comando para o dispositivo via MQTT
func (s *IoTService) SendCommand(ctx context.Context, deviceID string, command models.BraceCommand) error {
	if s.mqttService == nil {
		return fmt.Errorf("MQTT service not available")
	}

	// Criar payload do comando
	payload := map[string]interface{}{
		"command_id": command.ID,
		"type":       command.CommandType,
		"parameters": command.Parameters,
		"timestamp":  time.Now(),
	}

	// Publicar no tópico do dispositivo
	topic := fmt.Sprintf("orthotrack/%s/commands", deviceID)
	return s.mqttService.PublishCommand(topic, payload)
}

// GetConnectedDevices retorna lista de dispositivos conectados
func (s *IoTService) GetConnectedDevices(ctx context.Context) ([]models.Brace, error) {
	var devices []models.Brace
	
	// Dispositivos que tiveram comunicação nas últimas 2 horas
	cutoff := time.Now().Add(-2 * time.Hour)
	
	err := s.db.Preload("Patient").
		Where("last_heartbeat > ? AND status = ?", cutoff, models.DeviceStatusOnline).
		Find(&devices).Error

	return devices, err
}

// ProcessCommandResponse processa a resposta de um comando enviado a um dispositivo
func (s *IoTService) ProcessCommandResponse(ctx context.Context, commandID uint, status string, response models.DeviceConfig, errorMsg string) error {
	log.Printf("Processing command response for command ID: %d", commandID)

	// Buscar comando no banco
	var command models.BraceCommand
	if err := s.db.First(&command, commandID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return fmt.Errorf("command not found: %d", commandID)
		}
		return fmt.Errorf("error finding command: %v", err)
	}

	// Atualizar comando com a resposta
	now := time.Now()
	command.Status = models.CommandStatus(status)
	command.Response = response
	command.CompletedAt = &now
	
	if errorMsg != "" {
		command.ErrorMessage = errorMsg
	}

	if err := s.db.Save(&command).Error; err != nil {
		return fmt.Errorf("error updating command: %v", err)
	}

	// Se o comando foi executado com sucesso e alterou a configuração do dispositivo
	if status == string(models.CommandStatusCompleted) {
		// Atualizar a configuração do dispositivo na base de dados
		var brace models.Brace
		if err := s.db.First(&brace, command.BraceID).Error; err == nil {
			brace.Config = response
			s.db.Save(&brace)
		}
	}

	// Log da execução
	log.Printf("Command %d processed successfully with status: %s", commandID, status)
	
	return nil
}

// UpdateDeviceStatus atualiza o status de um dispositivo
func (s *IoTService) UpdateDeviceStatus(ctx context.Context, deviceID, status string, batteryLevel, signalStrength *int, firmwareVersion string) error {
	log.Printf("Updating device status for %s: %s", deviceID, status)

	var brace models.Brace
	if err := s.db.Where("device_id = ?", deviceID).First(&brace).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			log.Printf("Device not found: %s", deviceID)
			return fmt.Errorf("device not found: %s", deviceID)
		}
		return fmt.Errorf("error finding device: %v", err)
	}

	// Atualizar campos
	brace.Status = models.DeviceStatus(status)
	now := time.Now()
	brace.LastHeartbeat = &now
	
	if batteryLevel != nil {
		brace.BatteryLevel = batteryLevel
	}
	
	if signalStrength != nil {
		brace.SignalStrength = signalStrength
	}
	
	if firmwareVersion != "" {
		brace.FirmwareVersion = firmwareVersion
	}

	return s.db.Save(&brace).Error
}

// UpdateDeviceHeartbeat atualiza o heartbeat de um dispositivo
func (s *IoTService) UpdateDeviceHeartbeat(ctx context.Context, deviceID string, timestamp time.Time, batteryLevel *int) error {
	log.Printf("Updating heartbeat for device: %s", deviceID)

	var brace models.Brace
	if err := s.db.Where("device_id = ?", deviceID).First(&brace).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			log.Printf("Device not found: %s", deviceID)
			return fmt.Errorf("device not found: %s", deviceID)
		}
		return fmt.Errorf("error finding device: %v", err)
	}

	// Usar timestamp fornecido ou tempo atual
	if timestamp.IsZero() {
		timestamp = time.Now()
	}
	
	brace.LastHeartbeat = &timestamp
	
	if batteryLevel != nil {
		brace.BatteryLevel = batteryLevel
	}

	return s.db.Save(&brace).Error
}

// ProcessDeviceAlert processa um alerta originado do dispositivo
func (s *IoTService) ProcessDeviceAlert(ctx context.Context, deviceID, alertType, severity, message string, value *float64, metadata map[string]interface{}) error {
	log.Printf("Processing device alert from %s: %s", deviceID, alertType)

	var brace models.Brace
	if err := s.db.Where("device_id = ?", deviceID).First(&brace).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			log.Printf("Device not found: %s", deviceID)
			return fmt.Errorf("device not found: %s", deviceID)
		}
		return fmt.Errorf("error finding device: %v", err)
	}

	// Criar alerta
	alert := &models.Alert{
		BraceID:   &brace.ID,
		PatientID: brace.PatientID,
		Type:      models.AlertType(alertType),
		Severity:  models.Severity(severity),
		Title:     fmt.Sprintf("Alerta do Dispositivo %s", brace.DeviceID),
		Message:   message,
		Value:     value,
	}

	if s.alertService != nil {
		return s.alertService.CreateAlert(ctx, alert)
	}

	// Fallback: criar direto no banco
	return s.db.Create(alert).Error
}