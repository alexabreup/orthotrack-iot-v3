package services

import (
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"
)

// ConnectionEvent represents a connection lifecycle event
type ConnectionEvent struct {
	Type          string    `json:"type"`           // "connected" or "disconnected"
	ClientID      string    `json:"client_id"`
	UserID        string    `json:"user_id"`
	InstitutionID string    `json:"institution_id"`
	Role          string    `json:"role"`
	IPAddress     string    `json:"ip_address"`
	Timestamp     time.Time `json:"timestamp"`
	Duration      *int64    `json:"duration,omitempty"` // in milliseconds, only for disconnect
	Reason        string    `json:"reason,omitempty"`   // only for disconnect
}

// EventLog represents an event sent to clients
type EventLog struct {
	Type           string    `json:"type"`
	Channel        string    `json:"channel"`
	RecipientCount int       `json:"recipient_count"`
	Timestamp      time.Time `json:"timestamp"`
	InstanceID     string    `json:"instance_id"`
	MessageID      string    `json:"message_id,omitempty"`
}

// ErrorLog represents a connection error
type ErrorLog struct {
	Type      string    `json:"type"`
	ClientID  string    `json:"client_id,omitempty"`
	UserID    string    `json:"user_id,omitempty"`
	Error     string    `json:"error"`
	StackTrace string   `json:"stack_trace,omitempty"`
	Timestamp time.Time `json:"timestamp"`
	Context   map[string]interface{} `json:"context,omitempty"`
}

// WSLogger handles WebSocket logging
type WSLogger struct {
	mu sync.RWMutex
	// Connection tracking for duration calculation
	connectionTimes map[string]time.Time
}

// NewWSLogger creates a new WebSocket logger
func NewWSLogger() *WSLogger {
	return &WSLogger{
		connectionTimes: make(map[string]time.Time),
	}
}

// LogConnectionEstablished logs when a client connection is established
func (l *WSLogger) LogConnectionEstablished(client *Client, ipAddress string) {
	l.mu.Lock()
	l.connectionTimes[client.ID] = time.Now()
	l.mu.Unlock()

	event := ConnectionEvent{
		Type:          "connected",
		ClientID:      client.ID,
		UserID:        client.UserID,
		InstitutionID: client.InstitutionID,
		Role:          client.Role,
		IPAddress:     ipAddress,
		Timestamp:     time.Now(),
	}

	eventJSON, err := json.Marshal(event)
	if err != nil {
		log.Printf("Failed to marshal connection event: %v", err)
		return
	}

	log.Printf("CONNECTION_ESTABLISHED: %s", string(eventJSON))
}

// LogConnectionClosed logs when a client connection is closed
func (l *WSLogger) LogConnectionClosed(client *Client, reason string) {
	l.mu.Lock()
	connectTime, exists := l.connectionTimes[client.ID]
	if exists {
		delete(l.connectionTimes, client.ID)
	}
	l.mu.Unlock()

	var duration *int64
	if exists {
		durationMs := time.Since(connectTime).Milliseconds()
		duration = &durationMs
	}

	event := ConnectionEvent{
		Type:          "disconnected",
		ClientID:      client.ID,
		UserID:        client.UserID,
		InstitutionID: client.InstitutionID,
		Role:          client.Role,
		Timestamp:     time.Now(),
		Duration:      duration,
		Reason:        reason,
	}

	eventJSON, err := json.Marshal(event)
	if err != nil {
		log.Printf("Failed to marshal disconnection event: %v", err)
		return
	}

	log.Printf("CONNECTION_CLOSED: %s", string(eventJSON))
}

// LogEventSent logs when an event is sent to clients
func (l *WSLogger) LogEventSent(eventType, channel string, recipientCount int, instanceID, messageID string) {
	event := EventLog{
		Type:           eventType,
		Channel:        channel,
		RecipientCount: recipientCount,
		Timestamp:      time.Now(),
		InstanceID:     instanceID,
		MessageID:      messageID,
	}

	eventJSON, err := json.Marshal(event)
	if err != nil {
		log.Printf("Failed to marshal event log: %v", err)
		return
	}

	log.Printf("EVENT_SENT: %s", string(eventJSON))
}

// LogConnectionError logs connection errors with stack traces
func (l *WSLogger) LogConnectionError(clientID, userID, errorMsg, stackTrace string, context map[string]interface{}) {
	errorLog := ErrorLog{
		Type:       "connection_error",
		ClientID:   clientID,
		UserID:     userID,
		Error:      errorMsg,
		StackTrace: stackTrace,
		Timestamp:  time.Now(),
		Context:    context,
	}

	errorJSON, err := json.Marshal(errorLog)
	if err != nil {
		log.Printf("Failed to marshal error log: %v", err)
		return
	}

	log.Printf("CONNECTION_ERROR: %s", string(errorJSON))
}

// LogWebSocketError logs WebSocket-specific errors
func (l *WSLogger) LogWebSocketError(clientID, userID string, err error, context map[string]interface{}) {
	// Get stack trace if available
	stackTrace := fmt.Sprintf("%+v", err)
	
	l.LogConnectionError(clientID, userID, err.Error(), stackTrace, context)
}

// LogAuthenticationError logs authentication failures
func (l *WSLogger) LogAuthenticationError(clientID, reason string, context map[string]interface{}) {
	errorLog := ErrorLog{
		Type:      "authentication_error",
		ClientID:  clientID,
		Error:     reason,
		Timestamp: time.Now(),
		Context:   context,
	}

	errorJSON, err := json.Marshal(errorLog)
	if err != nil {
		log.Printf("Failed to marshal auth error log: %v", err)
		return
	}

	log.Printf("AUTHENTICATION_ERROR: %s", string(errorJSON))
}

// LogAuthorizationError logs authorization failures
func (l *WSLogger) LogAuthorizationError(clientID, userID, channel, reason string) {
	context := map[string]interface{}{
		"channel": channel,
		"reason":  reason,
	}

	errorLog := ErrorLog{
		Type:      "authorization_error",
		ClientID:  clientID,
		UserID:    userID,
		Error:     fmt.Sprintf("Authorization failed for channel %s: %s", channel, reason),
		Timestamp: time.Now(),
		Context:   context,
	}

	errorJSON, err := json.Marshal(errorLog)
	if err != nil {
		log.Printf("Failed to marshal auth error log: %v", err)
		return
	}

	log.Printf("AUTHORIZATION_ERROR: %s", string(errorJSON))
}

// GetConnectionDuration returns the duration of a connection if it exists
func (l *WSLogger) GetConnectionDuration(clientID string) *time.Duration {
	l.mu.RLock()
	defer l.mu.RUnlock()
	
	if connectTime, exists := l.connectionTimes[clientID]; exists {
		duration := time.Since(connectTime)
		return &duration
	}
	return nil
}

// GetActiveConnectionCount returns the number of tracked active connections
func (l *WSLogger) GetActiveConnectionCount() int {
	l.mu.RLock()
	defer l.mu.RUnlock()
	return len(l.connectionTimes)
}