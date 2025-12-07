package services

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"orthotrack-iot-v3/internal/config"

	mqtt "github.com/eclipse/paho.mqtt.golang"
)

type MQTTService struct {
	client    mqtt.Client
	config    *config.Config
	iotService *IoTService
	connected bool
}

type MessageHandler func(topic string, payload []byte) error

func NewMQTTService(cfg *config.Config) *MQTTService {
	opts := mqtt.NewClientOptions()
	opts.AddBroker(cfg.MQTT.BrokerURL)
	opts.SetClientID(cfg.MQTT.ClientID)
	
	if cfg.MQTT.Username != "" {
		opts.SetUsername(cfg.MQTT.Username)
		opts.SetPassword(cfg.MQTT.Password)
	}

	// Configurações de conexão
	opts.SetAutoReconnect(true)
	opts.SetCleanSession(true)
	opts.SetConnectRetry(true)
	opts.SetConnectTimeout(30 * time.Second)
	opts.SetKeepAlive(60 * time.Second)
	opts.SetPingTimeout(10 * time.Second)

	service := &MQTTService{
		config: cfg,
	}

	// Callbacks
	opts.SetOnConnectHandler(service.onConnect)
	opts.SetConnectionLostHandler(service.onConnectionLost)

	service.client = mqtt.NewClient(opts)

	return service
}

func (s *MQTTService) SetIoTService(iot *IoTService) {
	s.iotService = iot
}

func (s *MQTTService) Connect() error {
	log.Printf("Connecting to MQTT broker: %s", s.config.MQTT.BrokerURL)
	
	token := s.client.Connect()
	token.Wait()
	
	if token.Error() != nil {
		return fmt.Errorf("failed to connect to MQTT broker: %v", token.Error())
	}

	s.connected = true
	log.Printf("Successfully connected to MQTT broker")
	
	// Subscrever aos tópicos
	s.subscribeToTopics()
	
	return nil
}

func (s *MQTTService) Disconnect() {
	if s.client.IsConnected() {
		log.Printf("Disconnecting from MQTT broker")
		s.client.Disconnect(250)
		s.connected = false
	}
}

func (s *MQTTService) IsConnected() bool {
	return s.client.IsConnected() && s.connected
}

func (s *MQTTService) onConnect(client mqtt.Client) {
	log.Printf("MQTT client connected")
	s.connected = true
}

func (s *MQTTService) onConnectionLost(client mqtt.Client, err error) {
	log.Printf("MQTT connection lost: %v", err)
	s.connected = false
}

func (s *MQTTService) subscribeToTopics() {
	// Subscrever aos tópicos de telemetria
	topics := map[string]MessageHandler{
		"orthotrack/+/telemetry":        s.handleTelemetry,
		"orthotrack/+/status":           s.handleDeviceStatus,
		"orthotrack/+/heartbeat":        s.handleHeartbeat,
		"orthotrack/+/commands/response": s.handleCommandResponse,
		"orthotrack/+/alerts":           s.handleDeviceAlert,
	}

	for topic, handler := range topics {
		token := s.client.Subscribe(topic, 1, s.createMessageHandler(handler))
		token.Wait()
		
		if token.Error() != nil {
			log.Printf("Failed to subscribe to topic %s: %v", topic, token.Error())
		} else {
			log.Printf("Subscribed to topic: %s", topic)
		}
	}
}

func (s *MQTTService) createMessageHandler(handler MessageHandler) mqtt.MessageHandler {
	return func(client mqtt.Client, msg mqtt.Message) {
		go func() {
			if err := handler(msg.Topic(), msg.Payload()); err != nil {
				log.Printf("Error handling message from topic %s: %v", msg.Topic(), err)
			}
		}()
	}
}

func (s *MQTTService) handleTelemetry(topic string, payload []byte) error {
	log.Printf("Received telemetry from topic: %s", topic)

	var data TelemetryData
	if err := json.Unmarshal(payload, &data); err != nil {
		return fmt.Errorf("failed to unmarshal telemetry data: %v", err)
	}

	// Validar timestamp
	if data.Timestamp.IsZero() {
		data.Timestamp = time.Now()
	}

	// Processar telemetria via IoT service
	if s.iotService != nil {
		ctx := context.Background()
		return s.iotService.ProcessTelemetry(ctx, data)
	}

	return nil
}

func (s *MQTTService) handleDeviceStatus(topic string, payload []byte) error {
	log.Printf("Received device status from topic: %s", topic)

	var statusData struct {
		DeviceID         string    `json:"device_id"`
		Status           string    `json:"status"`
		BatteryLevel     *int      `json:"battery_level,omitempty"`
		SignalQuality    *int      `json:"signal_quality,omitempty"`
		FirmwareVersion  string    `json:"firmware_version,omitempty"`
		LastSeen         time.Time `json:"last_seen,omitempty"`
		UptimeSeconds    *int      `json:"uptime_seconds,omitempty"`
	}

	if err := json.Unmarshal(payload, &statusData); err != nil {
		return fmt.Errorf("failed to unmarshal status data: %v", err)
	}

	if s.iotService != nil {
		ctx := context.Background()
		return s.iotService.UpdateDeviceStatus(ctx, statusData.DeviceID, statusData.Status, statusData.BatteryLevel, statusData.SignalQuality, statusData.FirmwareVersion)
	}

	log.Printf("Device %s status: %s", statusData.DeviceID, statusData.Status)
	return nil
}

func (s *MQTTService) handleHeartbeat(topic string, payload []byte) error {
	var heartbeat struct {
		DeviceID  string    `json:"device_id"`
		Timestamp time.Time `json:"timestamp"`
		Battery   *int      `json:"battery,omitempty"`
	}

	if err := json.Unmarshal(payload, &heartbeat); err != nil {
		return fmt.Errorf("failed to unmarshal heartbeat: %v", err)
	}

	log.Printf("Heartbeat from device: %s", heartbeat.DeviceID)

	// Atualizar último visto do dispositivo
	if s.iotService != nil {
		ctx := context.Background()
		return s.iotService.UpdateDeviceHeartbeat(ctx, heartbeat.DeviceID, heartbeat.Timestamp, heartbeat.Battery)
	}

	return nil
}

func (s *MQTTService) handleCommandResponse(topic string, payload []byte) error {
	log.Printf("Received command response from topic: %s", topic)

	var response struct {
		DeviceID    string                 `json:"device_id"`
		CommandID   uint                   `json:"command_id"`
		Status      string                 `json:"status"`
		Message     string                 `json:"message,omitempty"`
		Result      map[string]interface{} `json:"result,omitempty"`
		Timestamp   time.Time              `json:"timestamp"`
	}

	if err := json.Unmarshal(payload, &response); err != nil {
		return fmt.Errorf("failed to unmarshal command response: %v", err)
	}

	log.Printf("Command %d response from device %s: %s", 
		response.CommandID, response.DeviceID, response.Status)

	// Processar resposta do comando através do IoT service
	if s.iotService != nil {
		ctx := context.Background()
		
		// Converter result para DeviceConfig (pode necessitar ajustes baseado na estrutura real)
		var deviceConfig map[string]interface{}
		if response.Result != nil {
			deviceConfig = response.Result
		} else {
			deviceConfig = make(map[string]interface{})
		}
		
		return s.iotService.ProcessCommandResponse(ctx, response.CommandID, response.Status, deviceConfig, response.Message)
	}
	
	return nil
}

func (s *MQTTService) handleDeviceAlert(topic string, payload []byte) error {
	log.Printf("Received device alert from topic: %s", topic)

	var alert struct {
		DeviceID   string                 `json:"device_id"`
		Type       string                 `json:"type"`
		Severity   string                 `json:"severity"`
		Message    string                 `json:"message"`
		Value      *float64               `json:"value,omitempty"`
		Metadata   map[string]interface{} `json:"metadata,omitempty"`
		Timestamp  time.Time              `json:"timestamp"`
	}

	if err := json.Unmarshal(payload, &alert); err != nil {
		return fmt.Errorf("failed to unmarshal device alert: %v", err)
	}

	log.Printf("Alert from device %s: %s - %s", 
		alert.DeviceID, alert.Type, alert.Message)

	// Processar alerta do dispositivo através do IoT service
	if s.iotService != nil {
		ctx := context.Background()
		return s.iotService.ProcessDeviceAlert(ctx, alert.DeviceID, alert.Type, alert.Severity, alert.Message, alert.Value, alert.Metadata)
	}

	return nil
}

// PublishCommand publica um comando para um dispositivo
func (s *MQTTService) PublishCommand(topic string, command interface{}) error {
	if !s.IsConnected() {
		return fmt.Errorf("MQTT client not connected")
	}

	payload, err := json.Marshal(command)
	if err != nil {
		return fmt.Errorf("failed to marshal command: %v", err)
	}

	token := s.client.Publish(topic, 1, false, payload)
	token.Wait()

	if token.Error() != nil {
		return fmt.Errorf("failed to publish command: %v", token.Error())
	}

	log.Printf("Command published to topic: %s", topic)
	return nil
}

// PublishMessage publica uma mensagem genérica
func (s *MQTTService) PublishMessage(topic string, payload []byte, qos byte) error {
	if !s.IsConnected() {
		return fmt.Errorf("MQTT client not connected")
	}

	token := s.client.Publish(topic, qos, false, payload)
	token.Wait()

	if token.Error() != nil {
		return fmt.Errorf("failed to publish message: %v", token.Error())
	}

	return nil
}

// Subscribe subscreve a um tópico adicional
func (s *MQTTService) Subscribe(topic string, qos byte, handler MessageHandler) error {
	if !s.IsConnected() {
		return fmt.Errorf("MQTT client not connected")
	}

	token := s.client.Subscribe(topic, qos, s.createMessageHandler(handler))
	token.Wait()

	if token.Error() != nil {
		return fmt.Errorf("failed to subscribe to topic %s: %v", topic, token.Error())
	}

	log.Printf("Subscribed to topic: %s", topic)
	return nil
}

// Unsubscribe remove a subscrição de um tópico
func (s *MQTTService) Unsubscribe(topic string) error {
	if !s.IsConnected() {
		return fmt.Errorf("MQTT client not connected")
	}

	token := s.client.Unsubscribe(topic)
	token.Wait()

	if token.Error() != nil {
		return fmt.Errorf("failed to unsubscribe from topic %s: %v", topic, token.Error())
	}

	log.Printf("Unsubscribed from topic: %s", topic)
	return nil
}