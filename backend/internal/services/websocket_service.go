package services

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/redis/go-redis/v9"
)

// Message represents a WebSocket message
type Message struct {
	Type      string      `json:"type"`
	Channel   string      `json:"channel"`
	Data      interface{} `json:"data"`
	Timestamp int64       `json:"timestamp"`
	// Metadata for loop prevention
	InstanceID string `json:"instance_id,omitempty"`
	MessageID  string `json:"message_id,omitempty"`
}

// RedisManager handles Redis connection and reconnection logic
type RedisManager struct {
	client     *redis.Client
	config     *redis.Options
	instanceID string
	mu         sync.RWMutex
	connected  bool
}

// NewRedisManager creates a new Redis manager with connection pooling
func NewRedisManager(host, port, password string, db, poolSize, minIdleConns, maxRetries int) *RedisManager {
	// Generate unique instance ID
	instanceID := generateInstanceID()
	
	options := &redis.Options{
		Addr:         fmt.Sprintf("%s:%s", host, port),
		Password:     password,
		DB:           db,
		PoolSize:     poolSize,
		MinIdleConns: minIdleConns,
		MaxRetries:   maxRetries,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolTimeout:  4 * time.Second,
		ConnMaxIdleTime: 5 * time.Minute,
	}
	
	client := redis.NewClient(options)
	
	return &RedisManager{
		client:     client,
		config:     options,
		instanceID: instanceID,
		connected:  false,
	}
}

// Connect establishes connection to Redis with retry logic
func (rm *RedisManager) Connect(ctx context.Context) error {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	
	// Test connection
	_, err := rm.client.Ping(ctx).Result()
	if err != nil {
		log.Printf("Failed to connect to Redis: %v", err)
		return err
	}
	
	rm.connected = true
	log.Printf("Redis connection established (instance: %s)", rm.instanceID)
	return nil
}

// IsConnected returns the connection status
func (rm *RedisManager) IsConnected() bool {
	rm.mu.RLock()
	defer rm.mu.RUnlock()
	return rm.connected
}

// GetClient returns the Redis client
func (rm *RedisManager) GetClient() *redis.Client {
	return rm.client
}

// GetInstanceID returns the unique instance ID
func (rm *RedisManager) GetInstanceID() string {
	return rm.instanceID
}

// Reconnect attempts to reconnect to Redis
func (rm *RedisManager) Reconnect(ctx context.Context) error {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	
	// Close existing connection
	if rm.client != nil {
		rm.client.Close()
	}
	
	// Create new client
	rm.client = redis.NewClient(rm.config)
	
	// Test connection
	_, err := rm.client.Ping(ctx).Result()
	if err != nil {
		rm.connected = false
		return err
	}
	
	rm.connected = true
	log.Printf("Redis reconnection successful (instance: %s)", rm.instanceID)
	return nil
}

// StartHealthCheck starts a goroutine to monitor Redis connection health
func (rm *RedisManager) StartHealthCheck(ctx context.Context) {
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if !rm.IsConnected() {
					log.Printf("Redis connection lost, attempting reconnection...")
					if err := rm.Reconnect(ctx); err != nil {
						log.Printf("Redis reconnection failed: %v", err)
					}
				} else {
					// Ping to verify connection is still alive
					if _, err := rm.client.Ping(ctx).Result(); err != nil {
						log.Printf("Redis ping failed: %v", err)
						rm.mu.Lock()
						rm.connected = false
						rm.mu.Unlock()
					}
				}
			}
		}
	}()
}

// Close closes the Redis connection
func (rm *RedisManager) Close() error {
	rm.mu.Lock()
	defer rm.mu.Unlock()
	
	if rm.client != nil {
		err := rm.client.Close()
		rm.connected = false
		return err
	}
	return nil
}

// generateInstanceID creates a unique identifier for this server instance
func generateInstanceID() string {
	bytes := make([]byte, 8)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// Client represents a WebSocket client connection
type Client struct {
	ID            string
	Conn          *websocket.Conn
	Send          chan []byte
	Subscriptions map[string]bool
	UserID        string
	InstitutionID string
	Role          string
	TokenExpiry   time.Time
	LastPong      time.Time
	mu            sync.RWMutex
}

// WSServer manages WebSocket connections and message broadcasting
type WSServer struct {
	clients      map[*Client]bool
	Broadcast    chan *Message
	Register     chan *Client
	Unregister   chan *Client
	redisManager *RedisManager
	authorizer   *ChannelAuthorizer
	logger       *WSLogger
	metrics      *WSMetrics
	mu           sync.RWMutex
	ctx          context.Context
	cancel       context.CancelFunc
}

// NewWSServer creates a new WebSocket server instance
func NewWSServer(redisManager *RedisManager, authorizer *ChannelAuthorizer) *WSServer {
	ctx, cancel := context.WithCancel(context.Background())
	
	logger := NewWSLogger()
	metrics := NewWSMetrics()
	
	// Start metrics collection
	metrics.StartMetricsCollection()
	
	return &WSServer{
		clients:      make(map[*Client]bool),
		Broadcast:    make(chan *Message, 256),
		Register:     make(chan *Client),
		Unregister:   make(chan *Client),
		redisManager: redisManager,
		authorizer:   authorizer,
		logger:       logger,
		metrics:      metrics,
		ctx:          ctx,
		cancel:       cancel,
	}
}

// Run starts the WebSocket server's main event loop
func (s *WSServer) Run() {
	// Start Redis subscription
	s.StartRedisSubscription()
	
	// Start Redis health check
	s.redisManager.StartHealthCheck(s.ctx)
	
	// Start heartbeat sender
	s.StartHeartbeatSender()
	
	// Start dead connection detector
	s.StartDeadConnectionDetector()
	
	for {
		select {
		case <-s.ctx.Done():
			log.Printf("WebSocket server shutting down")
			return
		case client := <-s.Register:
			s.registerClient(client)
		case client := <-s.Unregister:
			s.unregisterClient(client)
		case message := <-s.Broadcast:
			s.broadcastMessage(message)
		}
	}
}

// StartHeartbeatSender starts a goroutine that sends heartbeat messages to all clients every 30 seconds
func (s *WSServer) StartHeartbeatSender() {
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-s.ctx.Done():
				log.Printf("Heartbeat sender stopped")
				return
			case <-ticker.C:
				s.SendHeartbeatToAllClients()
			}
		}
	}()
	log.Printf("Heartbeat sender started (30 second interval)")
}

// SendHeartbeatToAllClients sends heartbeat messages to all connected clients
func (s *WSServer) SendHeartbeatToAllClients() {
	s.mu.RLock()
	clients := make([]*Client, 0, len(s.clients))
	for client := range s.clients {
		clients = append(clients, client)
	}
	s.mu.RUnlock()
	
	timestamp := time.Now().Unix()
	heartbeat := Message{
		Type: "heartbeat",
		Data: map[string]interface{}{
			"timestamp": timestamp,
		},
		Timestamp: timestamp,
	}
	
	data, err := json.Marshal(heartbeat)
	if err != nil {
		log.Printf("Failed to marshal heartbeat message: %v", err)
		return
	}
	
	sentCount := 0
	for _, client := range clients {
		select {
		case client.Send <- data:
			sentCount++
		default:
			// Client's send channel is full, skip
			log.Printf("Client %s send channel full, skipping heartbeat", client.ID)
		}
	}
	
	log.Printf("Sent heartbeat to %d/%d clients", sentCount, len(clients))
}

// StartDeadConnectionDetector starts a goroutine that checks for dead connections every 30 seconds
func (s *WSServer) StartDeadConnectionDetector() {
	ticker := time.NewTicker(30 * time.Second)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-s.ctx.Done():
				log.Printf("Dead connection detector stopped")
				return
			case <-ticker.C:
				s.DetectAndCloseDeadConnections()
			}
		}
	}()
	log.Printf("Dead connection detector started (30 second interval)")
}

// DetectAndCloseDeadConnections checks for clients that haven't ponged in 90 seconds and closes them
func (s *WSServer) DetectAndCloseDeadConnections() {
	s.mu.RLock()
	clients := make([]*Client, 0, len(s.clients))
	for client := range s.clients {
		clients = append(clients, client)
	}
	s.mu.RUnlock()
	
	deadThreshold := 90 * time.Second // 3 heartbeats (30s each)
	now := time.Now()
	deadClients := make([]*Client, 0)
	
	for _, client := range clients {
		lastPong := client.GetLastPong()
		timeSinceLastPong := now.Sub(lastPong)
		
		if timeSinceLastPong > deadThreshold {
			deadClients = append(deadClients, client)
			log.Printf("Detected dead connection: client %s (last pong: %v ago)", 
				client.ID, timeSinceLastPong)
		}
	}
	
	// Close dead connections
	for _, client := range deadClients {
		log.Printf("Closing dead connection for client %s", client.ID)
		
		// Send close message with reason
		closeMsg := websocket.FormatCloseMessage(websocket.CloseGoingAway, "connection timeout")
		client.Conn.WriteMessage(websocket.CloseMessage, closeMsg)
		
		// Unregister the client (this will close the connection and clean up)
		s.Unregister <- client
	}
	
	if len(deadClients) > 0 {
		log.Printf("Closed %d dead connections", len(deadClients))
	}
}

// Shutdown gracefully shuts down the WebSocket server
func (s *WSServer) Shutdown() {
	log.Printf("Shutting down WebSocket server...")
	
	// Cancel context to stop goroutines
	s.cancel()
	
	// Close all client connections
	s.mu.Lock()
	for client := range s.clients {
		close(client.Send)
		client.Conn.Close()
	}
	s.mu.Unlock()
	
	// Close Redis connection
	if err := s.redisManager.Close(); err != nil {
		log.Printf("Error closing Redis connection: %v", err)
	}
	
	log.Printf("WebSocket server shutdown complete")
}

// RegisterClientWithIP adds a new client to the server with IP address logging
func (s *WSServer) RegisterClientWithIP(client *Client, ipAddress string) {
	s.mu.Lock()
	s.clients[client] = true
	s.mu.Unlock()
	
	// Log connection establishment
	s.logger.LogConnectionEstablished(client, ipAddress)
	
	// Update metrics
	s.metrics.IncrementActiveConnections()
	
	log.Printf("Client registered: %s (user: %s, IP: %s)", client.ID, client.UserID, ipAddress)
}

// registerClient adds a new client to the server (legacy method)
func (s *WSServer) registerClient(client *Client) {
	s.RegisterClientWithIP(client, "unknown")
}

// UnregisterClientWithReason removes a client from the server with reason logging
func (s *WSServer) UnregisterClientWithReason(client *Client, reason string) {
	s.mu.Lock()
	
	if _, ok := s.clients[client]; ok {
		// Get all subscriptions before removing client
		subscriptions := client.GetSubscriptions()
		
		delete(s.clients, client)
		close(client.Send)
		
		s.mu.Unlock()
		
		// Log connection closure
		s.logger.LogConnectionClosed(client, reason)
		
		// Update metrics
		s.metrics.DecrementActiveConnections()
		
		log.Printf("Client unregistered: %s (user: %s, reason: %s)", client.ID, client.UserID, reason)
		
		// Update viewer counts for all channels the client was subscribed to
		for _, channel := range subscriptions {
			s.broadcastViewerCount(channel)
		}
	} else {
		s.mu.Unlock()
	}
}

// unregisterClient removes a client from the server (legacy method)
func (s *WSServer) unregisterClient(client *Client) {
	s.UnregisterClientWithReason(client, "normal_closure")
}

// broadcastMessage sends a message to all subscribed clients
func (s *WSServer) broadcastMessage(message *Message) {
	startTime := time.Now()
	
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	// Route message to correct clients based on subscriptions
	targetClients := s.getTargetClients(message.Channel)
	
	if len(targetClients) == 0 {
		log.Printf("No clients subscribed to channel: %s", message.Channel)
		return
	}
	
	data, err := json.Marshal(message)
	if err != nil {
		log.Printf("Error marshaling message: %v", err)
		s.logger.LogConnectionError("", "", fmt.Sprintf("Failed to marshal message: %v", err), "", map[string]interface{}{
			"channel": message.Channel,
			"type":    message.Type,
		})
		return
	}
	
	sentCount := 0
	for _, client := range targetClients {
		select {
		case client.Send <- data:
			sentCount++
		default:
			// Client's send channel is full, skip
			log.Printf("Client %s send channel full, skipping message", client.ID)
		}
	}
	
	// Calculate latency and record metrics
	latency := time.Since(startTime)
	s.metrics.RecordEventSent(latency.Microseconds())
	
	// Log event sent
	s.logger.LogEventSent(message.Type, message.Channel, sentCount, s.redisManager.GetInstanceID(), message.MessageID)
	
	log.Printf("Broadcasted message to %d/%d clients on channel: %s", sentCount, len(targetClients), message.Channel)
}

// getTargetClients returns clients subscribed to a specific channel
func (s *WSServer) getTargetClients(channel string) []*Client {
	var targetClients []*Client
	
	for client := range s.clients {
		client.mu.RLock()
		isSubscribed := client.Subscriptions[channel]
		client.mu.RUnlock()
		
		if isSubscribed {
			targetClients = append(targetClients, client)
		}
	}
	
	return targetClients
}

// RouteEventToClients routes events to correct WebSocket clients based on subscriptions
func (s *WSServer) RouteEventToClients(eventType, channel string, data interface{}) {
	message := &Message{
		Type:      eventType,
		Channel:   channel,
		Data:      data,
		Timestamp: time.Now().Unix(),
	}
	
	// Send to local clients
	s.Broadcast <- message
	
	// Publish to Redis for other instances
	if s.redisManager.IsConnected() {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		
		if err := s.PublishEvent(ctx, channel, data); err != nil {
			log.Printf("Failed to publish event to Redis: %v", err)
		}
	}
}

// BroadcastToChannel sends a message to all clients subscribed to a specific channel
func (s *WSServer) BroadcastToChannel(channel string, eventType string, data interface{}) {
	s.RouteEventToClients(eventType, channel, data)
}

// BroadcastToMultipleChannels sends a message to multiple channels
func (s *WSServer) BroadcastToMultipleChannels(channels []string, eventType string, data interface{}) {
	for _, channel := range channels {
		s.RouteEventToClients(eventType, channel, data)
	}
}

// GetChannelSubscribers returns information about subscribers to a channel
func (s *WSServer) GetChannelSubscribers(channel string) map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	subscribers := make([]map[string]interface{}, 0)
	
	for client := range s.clients {
		client.mu.RLock()
		if client.Subscriptions[channel] {
			subscribers = append(subscribers, map[string]interface{}{
				"client_id":     client.ID,
				"user_id":       client.UserID,
				"institution_id": client.InstitutionID,
				"role":          client.Role,
			})
		}
		client.mu.RUnlock()
	}
	
	return map[string]interface{}{
		"channel":           channel,
		"subscriber_count":  len(subscribers),
		"subscribers":       subscribers,
		"instance_id":       s.redisManager.GetInstanceID(),
	}
}

// Subscribe adds a channel subscription for a client
func (c *Client) Subscribe(channel string, server *WSServer) error {
	// Validate channel format
	if err := ValidateChannelFormat(channel); err != nil {
		return fmt.Errorf("invalid channel format: %w", err)
	}

	// Check authorization
	if server.authorizer != nil {
		ctx := context.Background()
		if err := server.authorizer.CanSubscribe(ctx, c.UserID, c.InstitutionID, c.Role, channel); err != nil {
			return fmt.Errorf("authorization failed: %w", err)
		}
	}

	c.mu.Lock()
	c.Subscriptions[channel] = true
	c.mu.Unlock()
	
	log.Printf("Client %s subscribed to channel: %s", c.ID, channel)
	
	// Broadcast viewer count update
	server.broadcastViewerCount(channel)
	
	return nil
}

// Unsubscribe removes a channel subscription for a client
func (c *Client) Unsubscribe(channel string, server *WSServer) {
	c.mu.Lock()
	delete(c.Subscriptions, channel)
	c.mu.Unlock()
	
	log.Printf("Client %s unsubscribed from channel: %s", c.ID, channel)
	
	// Broadcast viewer count update
	if server != nil {
		server.broadcastViewerCount(channel)
	}
}

// GetSubscriptions returns all subscriptions for a client
func (c *Client) GetSubscriptions() []string {
	c.mu.RLock()
	defer c.mu.RUnlock()
	
	subs := make([]string, 0, len(c.Subscriptions))
	for channel := range c.Subscriptions {
		subs = append(subs, channel)
	}
	return subs
}

// ReadPump handles reading messages from the WebSocket connection
func (c *Client) ReadPump(server *WSServer) {
	defer func() {
		if r := recover(); r != nil {
			server.logger.LogConnectionError(c.ID, c.UserID, fmt.Sprintf("Panic in ReadPump: %v", r), fmt.Sprintf("%+v", r), nil)
			server.metrics.RecordConnectionError()
		}
		server.UnregisterClientWithReason(c, "read_pump_exit")
		c.Conn.Close()
	}()

	// Initialize LastPong to current time
	c.mu.Lock()
	c.LastPong = time.Now()
	c.mu.Unlock()

	c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.Conn.SetPongHandler(func(string) error {
		c.UpdateLastPong()
		c.Conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("WebSocket error: %v", err)
				server.logger.LogWebSocketError(c.ID, c.UserID, err, map[string]interface{}{
					"context": "read_message",
				})
				server.metrics.RecordConnectionError()
			}
			break
		}

		// Handle incoming messages (subscribe/unsubscribe commands)
		var msg map[string]interface{}
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("Error unmarshaling message: %v", err)
			server.logger.LogConnectionError(c.ID, c.UserID, fmt.Sprintf("Failed to unmarshal message: %v", err), "", map[string]interface{}{
				"raw_message": string(message),
			})
			continue
		}

		msgType, ok := msg["type"].(string)
		if !ok {
			server.logger.LogConnectionError(c.ID, c.UserID, "Message missing type field", "", map[string]interface{}{
				"message": msg,
			})
			continue
		}

		switch msgType {
		case "subscribe":
			if channel, ok := msg["channel"].(string); ok {
				if err := c.Subscribe(channel, server); err != nil {
					// Log authorization error
					server.logger.LogAuthorizationError(c.ID, c.UserID, channel, err.Error())
					server.metrics.RecordAuthError()
					
					// Send error message to client
					errorMsg := Message{
						Type:      "error",
						Channel:   channel,
						Data: map[string]interface{}{
							"error": err.Error(),
							"action": "subscribe",
						},
						Timestamp: time.Now().Unix(),
					}
					if data, err := json.Marshal(errorMsg); err == nil {
						select {
						case c.Send <- data:
						default:
						}
					}
					log.Printf("Subscription error for client %s to channel %s: %v", c.ID, channel, err)
				}
			}
		case "unsubscribe":
			if channel, ok := msg["channel"].(string); ok {
				c.Unsubscribe(channel, server)
			}
		case "pong":
			// Handle explicit pong messages from client (in addition to WebSocket pong frames)
			c.UpdateLastPong()
			log.Printf("Received pong message from client %s", c.ID)
		}
	}
}

// UpdateLastPong updates the last pong time for the client in a thread-safe manner
func (c *Client) UpdateLastPong() {
	c.mu.Lock()
	c.LastPong = time.Now()
	c.mu.Unlock()
	log.Printf("Updated last pong time for client %s", c.ID)
}

// GetLastPong returns the last pong time for the client in a thread-safe manner
func (c *Client) GetLastPong() time.Time {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.LastPong
}

// WritePump handles writing messages to the WebSocket connection
func (c *Client) WritePump(server *WSServer) {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		if r := recover(); r != nil {
			server.logger.LogConnectionError(c.ID, c.UserID, fmt.Sprintf("Panic in WritePump: %v", r), fmt.Sprintf("%+v", r), nil)
			server.metrics.RecordConnectionError()
		}
		ticker.Stop()
		c.Conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.Send:
			c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				// Channel closed
				c.Conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}

			w, err := c.Conn.NextWriter(websocket.TextMessage)
			if err != nil {
				server.logger.LogWebSocketError(c.ID, c.UserID, err, map[string]interface{}{
					"context": "next_writer",
				})
				server.metrics.RecordConnectionError()
				return
			}
			w.Write(message)

			// Add queued messages to the current websocket message
			n := len(c.Send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.Send)
			}

			if err := w.Close(); err != nil {
				server.logger.LogWebSocketError(c.ID, c.UserID, err, map[string]interface{}{
					"context": "close_writer",
				})
				server.metrics.RecordConnectionError()
				return
			}
		case <-ticker.C:
			// Check if token has expired
			if c.IsTokenExpired() {
				log.Printf("Token expired for client %s, closing connection", c.ID)
				server.logger.LogAuthenticationError(c.ID, "token_expired", map[string]interface{}{
					"user_id": c.UserID,
					"expiry":  c.TokenExpiry,
				})
				server.metrics.RecordAuthError()
				
				// Send reauthentication request
				if err := c.SendReauthenticationRequest(); err != nil {
					log.Printf("Failed to send reauthentication request: %v", err)
					server.logger.LogConnectionError(c.ID, c.UserID, fmt.Sprintf("Failed to send reauthentication request: %v", err), "", nil)
				}
				// Wait a moment for the message to be sent
				time.Sleep(100 * time.Millisecond)
				// Close connection with appropriate close code
				c.Conn.WriteMessage(websocket.CloseMessage, 
					websocket.FormatCloseMessage(websocket.ClosePolicyViolation, "token expired"))
				return
			}

			// Send heartbeat with timestamp
			if err := c.SendHeartbeat(); err != nil {
				log.Printf("Failed to send heartbeat to client %s: %v", c.ID, err)
				server.logger.LogWebSocketError(c.ID, c.UserID, err, map[string]interface{}{
					"context": "send_heartbeat",
				})
				server.metrics.RecordConnectionError()
				return
			}
		}
	}
}

// SendHeartbeat sends a heartbeat message to the client with timestamp
func (c *Client) SendHeartbeat() error {
	c.Conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
	
	heartbeat := Message{
		Type: "heartbeat",
		Data: map[string]interface{}{
			"timestamp": time.Now().Unix(),
		},
		Timestamp: time.Now().Unix(),
	}
	
	data, err := json.Marshal(heartbeat)
	if err != nil {
		return fmt.Errorf("failed to marshal heartbeat: %w", err)
	}
	
	if err := c.Conn.WriteMessage(websocket.TextMessage, data); err != nil {
		return fmt.Errorf("failed to write heartbeat message: %w", err)
	}
	
	log.Printf("Sent heartbeat to client %s", c.ID)
	return nil
}

// PublishEvent publishes an event to Redis for distribution across server instances
func (s *WSServer) PublishEvent(ctx context.Context, channel string, data interface{}) error {
	if !s.redisManager.IsConnected() {
		return fmt.Errorf("redis not connected")
	}

	// Generate unique message ID for loop prevention
	messageID := generateMessageID()
	
	message := Message{
		Type:       "event",
		Channel:    channel,
		Data:       data,
		Timestamp:  time.Now().Unix(),
		InstanceID: s.redisManager.GetInstanceID(),
		MessageID:  messageID,
	}

	messageJSON, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	// Publish to Redis with retry logic
	maxRetries := 3
	for i := 0; i < maxRetries; i++ {
		err = s.redisManager.GetClient().Publish(ctx, "websocket:events", messageJSON).Err()
		if err == nil {
			log.Printf("Published event to Redis: channel=%s, instance=%s, messageID=%s", 
				channel, s.redisManager.GetInstanceID(), messageID)
			return nil
		}
		
		log.Printf("Failed to publish to Redis (attempt %d/%d): %v", i+1, maxRetries, err)
		
		// Wait before retry
		if i < maxRetries-1 {
			time.Sleep(time.Duration(i+1) * 100 * time.Millisecond)
		}
	}
	
	return fmt.Errorf("failed to publish after %d retries: %w", maxRetries, err)
}

// PublishEventWithMetadata publishes an event with custom metadata
func (s *WSServer) PublishEventWithMetadata(ctx context.Context, eventType, channel string, data interface{}, metadata map[string]interface{}) error {
	if !s.redisManager.IsConnected() {
		return fmt.Errorf("redis not connected")
	}

	messageID := generateMessageID()
	
	// Merge metadata with data
	eventData := map[string]interface{}{
		"payload":  data,
		"metadata": metadata,
	}
	
	message := Message{
		Type:       eventType,
		Channel:    channel,
		Data:       eventData,
		Timestamp:  time.Now().Unix(),
		InstanceID: s.redisManager.GetInstanceID(),
		MessageID:  messageID,
	}

	messageJSON, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	return s.redisManager.GetClient().Publish(ctx, "websocket:events", messageJSON).Err()
}

// generateMessageID creates a unique identifier for messages
func generateMessageID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}

// SubscribeToRedis subscribes to Redis channels for cross-instance communication
func (s *WSServer) SubscribeToRedis(ctx context.Context, channels ...string) error {
	if !s.redisManager.IsConnected() {
		return fmt.Errorf("redis not connected")
	}

	// Default channels if none provided
	if len(channels) == 0 {
		channels = []string{"websocket:events"}
	}

	pubsub := s.redisManager.GetClient().Subscribe(ctx, channels...)
	defer pubsub.Close()

	log.Printf("Subscribed to Redis channels: %v (instance: %s)", channels, s.redisManager.GetInstanceID())

	// Start receiving messages
	ch := pubsub.Channel()
	
	for {
		select {
		case <-ctx.Done():
			log.Printf("Redis subscription context cancelled")
			return ctx.Err()
		case msg, ok := <-ch:
			if !ok {
				log.Printf("Redis subscription channel closed")
				return fmt.Errorf("redis subscription channel closed")
			}
			
			s.handleRedisMessage(msg)
		}
	}
}

// handleRedisMessage processes incoming Redis messages
func (s *WSServer) handleRedisMessage(msg *redis.Message) {
	var message Message
	if err := json.Unmarshal([]byte(msg.Payload), &message); err != nil {
		log.Printf("Error unmarshaling Redis message: %v", err)
		return
	}

	// Check metadata to prevent loops
	if s.shouldIgnoreMessage(&message) {
		log.Printf("Ignoring message from same instance: %s", message.InstanceID)
		return
	}

	log.Printf("Received Redis message: type=%s, channel=%s, instance=%s, messageID=%s", 
		message.Type, message.Channel, message.InstanceID, message.MessageID)

	// Broadcast to local WebSocket clients
	select {
	case s.Broadcast <- &message:
	default:
		log.Printf("Broadcast channel full, dropping message")
	}
}

// shouldIgnoreMessage checks if a message should be ignored to prevent loops
func (s *WSServer) shouldIgnoreMessage(message *Message) bool {
	// Ignore messages from the same instance
	if message.InstanceID == s.redisManager.GetInstanceID() {
		return true
	}
	
	// Additional loop prevention logic can be added here
	// For example, checking message age or maintaining a cache of recent message IDs
	
	return false
}

// StartRedisSubscription starts Redis subscription in a separate goroutine
func (s *WSServer) StartRedisSubscription() {
	go func() {
		for {
			select {
			case <-s.ctx.Done():
				log.Printf("Redis subscription stopped")
				return
			default:
				if err := s.SubscribeToRedis(s.ctx); err != nil {
					log.Printf("Redis subscription error: %v", err)
					
					// Wait before retrying
					select {
					case <-s.ctx.Done():
						return
					case <-time.After(5 * time.Second):
						log.Printf("Retrying Redis subscription...")
					}
				}
			}
		}
	}()
}

// GetActiveClients returns the number of active clients
func (s *WSServer) GetActiveClients() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.clients)
}

// GetViewerCount returns the number of clients subscribed to a channel
func (s *WSServer) GetViewerCount(channel string) int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	count := 0
	for client := range s.clients {
		client.mu.RLock()
		if client.Subscriptions[channel] {
			count++
		}
		client.mu.RUnlock()
	}
	return count
}

// GetViewers returns the user IDs of clients subscribed to a channel
func (s *WSServer) GetViewers(channel string) []string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	
	viewers := make([]string, 0)
	for client := range s.clients {
		client.mu.RLock()
		if client.Subscriptions[channel] {
			viewers = append(viewers, client.UserID)
		}
		client.mu.RUnlock()
	}
	return viewers
}

// broadcastViewerCount broadcasts viewer count changes to all subscribers of a channel
func (s *WSServer) broadcastViewerCount(channel string) {
	count := s.GetViewerCount(channel)
	viewers := s.GetViewers(channel)
	
	viewerCountMsg := &Message{
		Type:    "viewer_count",
		Channel: channel,
		Data: map[string]interface{}{
			"count":   count,
			"viewers": viewers,
		},
		Timestamp: time.Now().Unix(),
	}
	
	// Broadcast to all subscribers of this channel
	s.Broadcast <- viewerCountMsg
}

// IsTokenExpired checks if the client's token has expired
func (c *Client) IsTokenExpired() bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return time.Now().After(c.TokenExpiry)
}

// SendReauthenticationRequest sends a message to the client requesting reauthentication
func (c *Client) SendReauthenticationRequest() error {
	msg := Message{
		Type: "reauthentication_required",
		Data: map[string]interface{}{
			"reason": "token_expired",
			"message": "Your session has expired. Please reconnect with a valid token.",
		},
		Timestamp: time.Now().Unix(),
	}
	
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}
	
	select {
	case c.Send <- data:
		return nil
	default:
		return fmt.Errorf("send channel full")
	}
}

// GetMetrics returns the metrics instance
func (s *WSServer) GetMetrics() *WSMetrics {
	return s.metrics
}

// GetLogger returns the logger instance
func (s *WSServer) GetLogger() *WSLogger {
	return s.logger
}

// ServeMetrics serves the metrics endpoint
func (s *WSServer) ServeMetrics(w http.ResponseWriter, r *http.Request) {
	s.metrics.ServeMetricsHTTP(w, r)
}
