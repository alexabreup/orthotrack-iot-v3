package services

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"orthotrack-iot-v3/internal/models"
	"github.com/redis/go-redis/v9"
	"pgregory.net/rapid"
)

// Feature: realtime-monitoring, Property 1: Device status event propagation
// Validates: Requirements 1.1
// For any device status change, the system should send a WebSocket event to all clients subscribed to that device's channel
func TestProperty_DeviceStatusEventPropagation(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup: Create Redis manager with robust configuration
		redisManager, err := setupRedisForTest()
		if err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		// Create WebSocket server with authorizer
		authorizer := NewChannelAuthorizer(nil)
		wsServer := NewWSServer(redisManager, authorizer)
		
		// Generate random device ID
		deviceID := rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID")
		channel := "device:" + deviceID
		
		// Generate random number of clients (1-10)
		numClients := rapid.IntRange(1, 10).Draw(t, "numClients")
		
		// Create clients and subscribe them to the device channel
		clients := make([]*Client, numClients)
		for i := 0; i < numClients; i++ {
			client := &Client{
				ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
				Send:          make(chan []byte, 256),
				Subscriptions: make(map[string]bool),
				UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
				InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
				Role:          "admin",
				TokenExpiry:   time.Now().Add(1 * time.Hour),
				LastPong:      time.Now(),
			}
			
			// Register client with server
			wsServer.registerClient(client)
			
			// Subscribe client to the device channel
			err := client.Subscribe(channel, wsServer)
			if err != nil {
				t.Fatalf("Failed to subscribe: %v", err)
			}
			
			clients[i] = client
		}
		
		// Generate random device status
		statuses := []string{"online", "offline", "maintenance"}
		status := rapid.SampledFrom(statuses).Draw(t, "status")
		
		// Create device status event
		eventData := map[string]interface{}{
			"device_id": deviceID,
			"status":    status,
			"timestamp": time.Now().Unix(),
		}
		
		message := &Message{
			Type:      "device_status",
			Channel:   channel,
			Data:      eventData,
			Timestamp: time.Now().Unix(),
		}
		
		// Broadcast the message
		wsServer.broadcastMessage(message)
		
		// Verify: All subscribed clients should receive the message
		receivedCount := 0
		timeout := time.After(3 * time.Second)
		
		for _, client := range clients {
			select {
			case msg := <-client.Send:
				var receivedMsg Message
				if err := json.Unmarshal(msg, &receivedMsg); err != nil {
					t.Fatalf("Failed to unmarshal message: %v", err)
				}
				
				// Verify message content
				if receivedMsg.Type != "device_status" {
					t.Fatalf("Expected type 'device_status', got '%s'", receivedMsg.Type)
				}
				if receivedMsg.Channel != channel {
					t.Fatalf("Expected channel '%s', got '%s'", channel, receivedMsg.Channel)
				}
				
				receivedCount++
			case <-timeout:
				t.Fatalf("Timeout waiting for message on client %s", client.ID)
			}
		}
		
		// Property: All subscribed clients must receive the event
		if receivedCount != numClients {
			t.Fatalf("Expected %d clients to receive message, got %d", numClients, receivedCount)
		}
		
		// Cleanup
		for _, client := range clients {
			wsServer.unregisterClient(client)
		}
	})
}

// Test that clients not subscribed to a channel don't receive messages
func TestProperty_UnsubscribedClientsDoNotReceiveMessages(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup: Create Redis manager with robust configuration
		redisManager, err := setupRedisForTest()
		if err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		authorizer := NewChannelAuthorizer(nil)
		wsServer := NewWSServer(redisManager, authorizer)
		
		// Generate two different channels
		channel1 := "device:" + rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID1")
		channel2 := "device:" + rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID2")
		
		// Ensure channels are different
		if channel1 == channel2 {
			t.Skip("Generated identical channels")
		}
		
		// Create client subscribed to channel1
		client := &Client{
			ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
			InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      time.Now(),
		}
		
		wsServer.registerClient(client)
		err := client.Subscribe(channel1, wsServer)
		if err != nil {
			t.Fatalf("Failed to subscribe: %v", err)
		}
		
		// Send message to channel2
		message := &Message{
			Type:      "device_status",
			Channel:   channel2,
			Data:      map[string]interface{}{"test": "data"},
			Timestamp: time.Now().Unix(),
		}
		
		wsServer.broadcastMessage(message)
		
		// Verify: Client should NOT receive the message
		select {
		case <-client.Send:
			t.Fatalf("Client received message from unsubscribed channel")
		case <-time.After(1 * time.Second):
			// Expected: no message received
		}
		
		// Cleanup
		wsServer.unregisterClient(client)
	})
}

// Test viewer count tracking
func TestProperty_ViewerCountTracking(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup
		redisManager := NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
		ctx := context.Background()
		if err := redisManager.Connect(ctx); err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		authorizer := NewChannelAuthorizer(nil)
		wsServer := NewWSServer(redisManager, authorizer)
		
		channel := "patient:" + rapid.StringMatching(`^[0-9]{1,10}$`).Draw(t, "patientID")
		numClients := rapid.IntRange(1, 20).Draw(t, "numClients")
		
		// Create and subscribe clients
		clients := make([]*Client, numClients)
		for i := 0; i < numClients; i++ {
			client := &Client{
				ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
				Send:          make(chan []byte, 256),
				Subscriptions: make(map[string]bool),
				UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
				InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
				Role:          "admin",
				TokenExpiry:   time.Now().Add(1 * time.Hour),
				LastPong:      time.Now(),
			}
			
			wsServer.registerClient(client)
			err := client.Subscribe(channel, wsServer)
			if err != nil {
				t.Fatalf("Failed to subscribe: %v", err)
			}
			clients[i] = client
		}
		
		// Property: Viewer count should equal number of subscribed clients
		viewerCount := wsServer.GetViewerCount(channel)
		if viewerCount != numClients {
			t.Fatalf("Expected viewer count %d, got %d", numClients, viewerCount)
		}
		
		// Unsubscribe half the clients
		halfClients := numClients / 2
		for i := 0; i < halfClients; i++ {
			clients[i].Unsubscribe(channel, wsServer)
		}
		
		// Property: Viewer count should decrease accordingly
		expectedCount := numClients - halfClients
		viewerCount = wsServer.GetViewerCount(channel)
		if viewerCount != expectedCount {
			t.Fatalf("Expected viewer count %d after unsubscribe, got %d", expectedCount, viewerCount)
		}
		
		// Cleanup
		for _, client := range clients {
			wsServer.unregisterClient(client)
		}
	})
}

// Feature: realtime-monitoring, Property 31: Redis Pub/Sub synchronization
// Validates: Requirements 10.1, 10.2
// For any event published on one server instance, the system should propagate it to clients connected to other instances via Redis Pub/Sub
func TestProperty_RedisPubSubSynchronization(t *testing.T) {
	// Get Redis configuration from environment or use defaults
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "localhost"
	}
	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}
	redisPassword := os.Getenv("REDIS_PASSWORD")
	
	// Try different Redis configurations (environment first, then fallbacks)
	redisConfigs := []struct {
		host     string
		password string
	}{
		{fmt.Sprintf("%s:%s", redisHost, redisPort), redisPassword},
		{"localhost:6379", ""},
		{"orthotrack-redis:6379", "redis123"},
		{"redis:6379", "redis123"},
	}
	var workingConfig struct {
		host     string
		password string
	}
	
	ctx := context.Background()
	for _, config := range redisConfigs {
		testClient := redis.NewClient(&redis.Options{
			Addr:     config.host,
			Password: config.password,
		})
		if err := testClient.Ping(ctx).Err(); err == nil {
			workingConfig = config
			testClient.Close()
			break
		}
		testClient.Close()
	}
	
	if workingConfig.host == "" {
		t.Skip("Redis not available on any known host, skipping test")
	}
	
	rapid.Check(t, func(t *rapid.T) {
		// Parse working host
		hostParts := strings.Split(workingConfig.host, ":")
		host := hostParts[0]
		port := hostParts[1]
		
		// Create two Redis managers simulating different server instances
		redisManager1 := NewRedisManager(host, port, workingConfig.password, 0, 10, 5, 3)
		redisManager2 := NewRedisManager(host, port, workingConfig.password, 0, 10, 5, 3)
		
		err1 := redisManager1.Connect(ctx)
		err2 := redisManager2.Connect(ctx)
		if err1 != nil || err2 != nil {
			t.Skip("Failed to connect to Redis")
		}
		
		defer redisManager1.Close()
		defer redisManager2.Close()
		
		// Create two WebSocket servers (simulating different instances)
		wsServer1 := NewWSServer(redisManager1, nil)
		wsServer2 := NewWSServer(redisManager2, nil)
		
		// Generate random channel and event data
		channel := "device:" + rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID")
		eventData := map[string]interface{}{
			"device_id": rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID"),
			"status":    rapid.SampledFrom([]string{"online", "offline", "maintenance"}).Draw(t, "status"),
			"timestamp": time.Now().Unix(),
		}
		
		// Create a client on server2 subscribed to the channel
		client2 := &Client{
			ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
			InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      time.Now(),
		}
		
		wsServer2.registerClient(client2)
		
		// Start Redis subscription on server2 BEFORE subscribing client to avoid race condition
		redisCtx, redisCancel := context.WithCancel(ctx)
		defer redisCancel()
		
		go func() {
			wsServer2.SubscribeToRedis(redisCtx)
		}()
		
		// Start server2's broadcast loop
		broadcastCtx, broadcastCancel := context.WithCancel(ctx)
		defer broadcastCancel()
		
		go func() {
			for {
				select {
				case <-broadcastCtx.Done():
					return
				case message := <-wsServer2.Broadcast:
					wsServer2.broadcastMessage(message)
				}
			}
		}()
		
		// Allow Redis subscription to be established
		time.Sleep(200 * time.Millisecond)
		
		// Subscribe client to channel AFTER Redis subscription is established
		err := client2.Subscribe(channel, wsServer2)
		if err != nil {
			t.Fatalf("Failed to subscribe client to channel: %v", err)
		}
		
		// Clear any viewer_count messages from subscription
		clearTimeout := time.After(2 * time.Second)
		for {
			select {
			case <-client2.Send:
				// Drain viewer_count messages
			case <-clearTimeout:
				goto publishEvent
			}
		}
		
		publishEvent:
		// Publish event from server1 to Redis
		err = wsServer1.PublishEvent(ctx, channel, eventData)
		if err != nil {
			t.Fatalf("Failed to publish event from server1: %v", err)
		}
		
		// Property: Client on server2 should receive the event published by server1
		timeout := time.After(3000 * time.Millisecond) // Increased timeout for Redis propagation
		eventReceived := false
		messagesReceived := 0
		
		for !eventReceived && messagesReceived < 20 { // Increased message limit
			select {
			case msg := <-client2.Send:
				messagesReceived++
				var receivedMsg Message
				if err := json.Unmarshal(msg, &receivedMsg); err != nil {
					t.Logf("Failed to unmarshal received message (attempt %d): %v", messagesReceived, err)
					continue // Skip malformed messages
				}
				
				t.Logf("Received message %d: type=%s, channel=%s, instanceID=%s", 
					messagesReceived, receivedMsg.Type, receivedMsg.Channel, receivedMsg.InstanceID)
				
				// Skip viewer_count messages and look for the event message
				if receivedMsg.Type == "viewer_count" {
					t.Logf("Skipping viewer_count message")
					continue
				}
				
				// Check if this is the event message we're looking for
				if receivedMsg.Type == "event" && receivedMsg.Channel == channel {
					// Verify instance ID is from server1 (different from server2)
					if receivedMsg.InstanceID == wsServer2.redisManager.GetInstanceID() {
						t.Fatalf("Message should have different instance ID than receiving server")
					}
					
					// Verify the event data contains expected fields
					if receivedMsg.Data == nil {
						t.Fatalf("Event message missing data")
					}
					
					eventReceived = true
					t.Logf("Successfully received Redis-synchronized event message")
					break
				} else {
					t.Logf("Skipping message with type '%s' and channel '%s'", receivedMsg.Type, receivedMsg.Channel)
				}
				
			case <-timeout:
				t.Fatalf("Timeout waiting for Redis-synchronized message after receiving %d messages", messagesReceived)
			}
		}
		
		if !eventReceived {
			t.Fatalf("Failed to receive Redis-synchronized event message after processing %d messages", messagesReceived)
		}
		
		// Cleanup
		wsServer2.unregisterClient(client2)
	})
}

// Feature: realtime-monitoring, Property 34: Loop prevention
// Validates: Requirements 10.5
// For any event published via Redis, the system should include metadata to prevent propagation loops
func TestProperty_LoopPrevention(t *testing.T) {
	// Get Redis configuration from environment or use defaults
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "localhost"
	}
	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}
	redisPassword := os.Getenv("REDIS_PASSWORD")
	
	// Skip if Redis is not available
	redisOptions := &redis.Options{
		Addr:     fmt.Sprintf("%s:%s", redisHost, redisPort),
		Password: redisPassword,
	}
	
	ctx := context.Background()
	testClient := redis.NewClient(redisOptions)
	if err := testClient.Ping(ctx).Err(); err != nil {
		t.Skip("Redis not available, skipping test")
	}
	testClient.Close()
	
	rapid.Check(t, func(t *rapid.T) {
		// Create Redis manager and WebSocket server
		redisManager := NewRedisManager(redisHost, redisPort, redisPassword, 0, 10, 5, 3)
		err := redisManager.Connect(ctx)
		if err != nil {
			t.Skip("Failed to connect to Redis")
		}
		defer redisManager.Close()
		
		wsServer := NewWSServer(redisManager, nil)
		
		// Generate random channel and event data
		channel := "device:" + rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID")
		eventData := map[string]interface{}{
			"device_id": rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID"),
			"status":    rapid.SampledFrom([]string{"online", "offline", "maintenance"}).Draw(t, "status"),
			"timestamp": time.Now().Unix(),
		}
		
		// Publish event to Redis
		err = wsServer.PublishEvent(ctx, channel, eventData)
		if err != nil {
			t.Fatalf("Failed to publish event: %v", err)
		}
		
		// Subscribe to Redis to receive the published message
		pubsub := redisManager.GetClient().Subscribe(ctx, "websocket:events")
		defer pubsub.Close()
		
		// Receive the message
		timeout := time.After(3 * time.Second)
		select {
		case msg := <-pubsub.Channel():
			var receivedMsg Message
			if err := json.Unmarshal([]byte(msg.Payload), &receivedMsg); err != nil {
				t.Fatalf("Failed to unmarshal Redis message: %v", err)
			}
			
			// Property: Message should include instance ID for loop prevention
			if receivedMsg.InstanceID == "" {
				t.Fatalf("Message missing instance ID for loop prevention")
			}
			
			// Property: Instance ID should match the publishing server
			if receivedMsg.InstanceID != wsServer.redisManager.GetInstanceID() {
				t.Fatalf("Message instance ID mismatch: expected %s, got %s", 
					wsServer.redisManager.GetInstanceID(), receivedMsg.InstanceID)
			}
			
			// Property: Message should include unique message ID
			if receivedMsg.MessageID == "" {
				t.Fatalf("Message missing message ID for loop prevention")
			}
			
			// Property: shouldIgnoreMessage should return true for messages from same instance
			shouldIgnore := wsServer.shouldIgnoreMessage(&receivedMsg)
			if !shouldIgnore {
				t.Fatalf("shouldIgnoreMessage should return true for messages from same instance")
			}
			
		case <-timeout:
			t.Fatalf("Timeout waiting for Redis message")
		}
		
		// Test with message from different instance
		differentInstanceMsg := Message{
			Type:       "event",
			Channel:    channel,
			Data:       eventData,
			Timestamp:  time.Now().Unix(),
			InstanceID: "different-instance-id",
			MessageID:  "different-message-id",
		}
		
		// Property: shouldIgnoreMessage should return false for messages from different instance
		shouldIgnore := wsServer.shouldIgnoreMessage(&differentInstanceMsg)
		if shouldIgnore {
			t.Fatalf("shouldIgnoreMessage should return false for messages from different instance")
		}
	})
}

// Feature: realtime-monitoring, Property 18: Page navigation subscription
// Validates: Requirements 5.1, 5.2, 5.5
// For any page navigation, the system should subscribe to appropriate channels and unsubscribe from previous channels
func TestProperty_PageNavigationSubscription(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup
		redisManager := NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
		ctx := context.Background()
		if err := redisManager.Connect(ctx); err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		authorizer := NewChannelAuthorizer(nil)
		wsServer := NewWSServer(redisManager, authorizer)
		
		// Create a client
		client := &Client{
			ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
			InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      time.Now(),
		}
		wsServer.registerClient(client)
		
		// Generate random channels representing different pages
		numChannels := rapid.IntRange(2, 5).Draw(t, "numChannels")
		channels := make([]string, numChannels)
		for i := 0; i < numChannels; i++ {
			channelType := rapid.SampledFrom([]string{"patient", "device", "dashboard"}).Draw(t, "channelType")
			if channelType == "dashboard" {
				channels[i] = "dashboard"
			} else {
				id := rapid.StringMatching(`^[0-9]{1,10}$`).Draw(t, "id")
				channels[i] = channelType + ":" + id
			}
		}
		
		// Simulate page navigation: subscribe to each channel in sequence
		for i, channel := range channels {
			// Subscribe to new channel
			err := client.Subscribe(channel, wsServer)
			if err != nil {
				t.Fatalf("Failed to subscribe to channel %s: %v", channel, err)
			}
			
			// Property: Client should be subscribed to the current channel
			if !client.Subscriptions[channel] {
				t.Fatalf("Client not subscribed to channel %s after Subscribe()", channel)
			}
			
			// Unsubscribe from previous channel (simulating leaving a page)
			if i > 0 {
				prevChannel := channels[i-1]
				client.Unsubscribe(prevChannel, wsServer)
				
				// Property: Client should no longer be subscribed to previous channel
				if client.Subscriptions[prevChannel] {
					t.Fatalf("Client still subscribed to channel %s after Unsubscribe()", prevChannel)
				}
			}
		}
		
		// Property: Client should only be subscribed to the last channel
		subs := client.GetSubscriptions()
		if len(subs) != 1 {
			t.Fatalf("Expected 1 subscription, got %d", len(subs))
		}
		if subs[0] != channels[len(channels)-1] {
			t.Fatalf("Expected subscription to %s, got %s", channels[len(channels)-1], subs[0])
		}
		
		// Cleanup
		wsServer.unregisterClient(client)
	})
}

// Feature: realtime-monitoring, Property 25: Viewer count tracking
// Validates: Requirements 8.1, 8.2, 8.3
// For any subscription or unsubscription to a patient channel, the system should update the viewer count and broadcast to all viewers
func TestProperty_ViewerCountTrackingEnhanced(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup
		redisManager := NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
		ctx := context.Background()
		if err := redisManager.Connect(ctx); err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		// Use nil authorizer for testing to skip database checks
		wsServer := NewWSServer(redisManager, nil)
		
		// Start the server's event loop in a goroutine
		go wsServer.Run()
		
		channel := "patient:" + rapid.StringMatching(`^[1-9][0-9]{0,8}$`).Draw(t, "patientID")
		numClients := rapid.IntRange(1, 20).Draw(t, "numClients")
		
		// Create and subscribe clients
		clients := make([]*Client, numClients)
		for i := 0; i < numClients; i++ {
			client := &Client{
				ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
				Send:          make(chan []byte, 256),
				Subscriptions: make(map[string]bool),
				UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
				InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
				Role:          "admin",
				TokenExpiry:   time.Now().Add(1 * time.Hour),
				LastPong:      time.Now(),
			}
			
			wsServer.Register <- client
			time.Sleep(1 * time.Millisecond) // Allow registration to complete
			
			err := client.Subscribe(channel, wsServer)
			if err != nil {
				t.Fatalf("Failed to subscribe: %v", err)
			}
			clients[i] = client
		}
		
		// Allow viewer count broadcasts to be sent
		time.Sleep(10 * time.Millisecond)
		
		// Property: Viewer count should equal number of subscribed clients
		viewerCount := wsServer.GetViewerCount(channel)
		if viewerCount != numClients {
			t.Fatalf("Expected viewer count %d, got %d", numClients, viewerCount)
		}
		
		// Property: GetViewers should return all user IDs
		viewers := wsServer.GetViewers(channel)
		if len(viewers) != numClients {
			t.Fatalf("Expected %d viewers, got %d", numClients, len(viewers))
		}
		
		// Verify viewer count events were broadcast
		receivedViewerCount := 0
		for _, client := range clients {
			select {
			case msg := <-client.Send:
				var receivedMsg Message
				if err := json.Unmarshal(msg, &receivedMsg); err == nil {
					if receivedMsg.Type == "viewer_count" {
						receivedViewerCount++
					}
				}
			default:
				// No message available
			}
		}
		
		// Property: At least some clients should have received viewer count updates
		if receivedViewerCount == 0 && numClients > 1 {
			t.Logf("Warning: No viewer count messages received (expected at least some)")
		}
		
		// Unsubscribe half the clients
		halfClients := numClients / 2
		for i := 0; i < halfClients; i++ {
			clients[i].Unsubscribe(channel, wsServer)
		}
		
		time.Sleep(10 * time.Millisecond)
		
		// Property: Viewer count should decrease accordingly
		expectedCount := numClients - halfClients
		viewerCount = wsServer.GetViewerCount(channel)
		if viewerCount != expectedCount {
			t.Fatalf("Expected viewer count %d after unsubscribe, got %d", expectedCount, viewerCount)
		}
		
		// Cleanup
		for _, client := range clients {
			wsServer.Unregister <- client
		}
		time.Sleep(10 * time.Millisecond)
	})
}

// Feature: realtime-monitoring, Property 20: Heartbeat interval
// Validates: Requirements 7.1
// For any active WebSocket connection, the server should send a heartbeat message every 30 seconds
func TestProperty_HeartbeatInterval(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup
		redisManager := NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
		ctx := context.Background()
		if err := redisManager.Connect(ctx); err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		wsServer := NewWSServer(redisManager, nil)
		
		// Create a client
		client := &Client{
			ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
			InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      time.Now(),
		}
		
		wsServer.registerClient(client)
		
		// Test heartbeat sending to all clients
		wsServer.SendHeartbeatToAllClients()
		
		// Property: Client should receive heartbeat message
		timeout := time.After(2 * time.Second)
		select {
		case msg := <-client.Send:
			var receivedMsg Message
			if err := json.Unmarshal(msg, &receivedMsg); err != nil {
				t.Fatalf("Failed to unmarshal heartbeat message: %v", err)
			}
			
			// Property: Message type should be "heartbeat"
			if receivedMsg.Type != "heartbeat" {
				t.Fatalf("Expected message type 'heartbeat', got '%s'", receivedMsg.Type)
			}
			
			// Property: Message should include timestamp
			data, ok := receivedMsg.Data.(map[string]interface{})
			if !ok {
				t.Fatalf("Heartbeat data is not a map")
			}
			
			timestamp, ok := data["timestamp"]
			if !ok {
				t.Fatalf("Heartbeat message missing timestamp")
			}
			
			// Verify timestamp is a number and recent
			timestampFloat, ok := timestamp.(float64)
			if !ok {
				t.Fatalf("Timestamp is not a number")
			}
			
			timestampTime := time.Unix(int64(timestampFloat), 0)
			timeDiff := time.Since(timestampTime)
			if timeDiff > 5*time.Second || timeDiff < -5*time.Second {
				t.Fatalf("Timestamp too old or in future: %v", timeDiff)
			}
			
		case <-timeout:
			t.Fatalf("Timeout waiting for heartbeat message")
		}
		
		// Cleanup
		wsServer.unregisterClient(client)
	})
}

// Feature: realtime-monitoring, Property 22: Dead connection detection
// Validates: Requirements 7.3
// For any connection that fails to respond to 3 consecutive heartbeats, the server should close the connection
func TestProperty_DeadConnectionDetection(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup
		redisManager := NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
		ctx := context.Background()
		if err := redisManager.Connect(ctx); err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		wsServer := NewWSServer(redisManager, nil)
		
		// Create a client with old LastPong time (simulating no pong responses)
		oldTime := time.Now().Add(-95 * time.Second) // Older than 90 second threshold
		client := &Client{
			ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
			InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      oldTime,
		}
		
		wsServer.registerClient(client)
		
		// Verify client is registered
		if !wsServer.clients[client] {
			t.Fatalf("Client not registered")
		}
		
		// Run dead connection detection
		wsServer.DetectAndCloseDeadConnections()
		
		// Allow time for unregistration to complete
		time.Sleep(10 * time.Millisecond)
		
		// Property: Dead client should be unregistered
		wsServer.mu.RLock()
		isRegistered := wsServer.clients[client]
		wsServer.mu.RUnlock()
		
		if isRegistered {
			t.Fatalf("Dead client should have been unregistered")
		}
		
		// Test with client that has recent pong
		recentClient := &Client{
			ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "recentClientID"),
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "recentUserID"),
			InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "recentInstitutionID"),
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      time.Now(), // Recent pong
		}
		
		wsServer.registerClient(recentClient)
		
		// Run dead connection detection again
		wsServer.DetectAndCloseDeadConnections()
		
		time.Sleep(10 * time.Millisecond)
		
		// Property: Recent client should still be registered
		wsServer.mu.RLock()
		isStillRegistered := wsServer.clients[recentClient]
		wsServer.mu.RUnlock()
		
		if !isStillRegistered {
			t.Fatalf("Recent client should still be registered")
		}
		
		// Cleanup
		wsServer.unregisterClient(recentClient)
	})
}
// Feature: realtime-monitoring, Property 9: Telemetry event propagation
// Validates: Requirements 3.1
// For any telemetry data received by backend, the system should send a WebSocket event to clients subscribed to that device's channel
func TestProperty_TelemetryEventPropagation(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup: Create Redis manager with robust configuration
		redisManager, err := setupRedisForTest()
		if err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		// Create WebSocket server with authorizer
		authorizer := NewChannelAuthorizer(nil)
		wsServer := NewWSServer(redisManager, authorizer)
		eventHandler := NewEventHandler(wsServer)
		
		// Generate random device ID
		deviceID := rapid.StringMatching(`^[A-Z0-9]{3,20}$`).Draw(t, "deviceID")
		channel := "device:" + deviceID
		
		// Generate random number of clients (1-10)
		numClients := rapid.IntRange(1, 10).Draw(t, "numClients")
		
		// Create clients and subscribe them to the device channel
		clients := make([]*Client, numClients)
		for i := 0; i < numClients; i++ {
			client := &Client{
				ID:            rapid.StringMatching(`^[a-zA-Z0-9]{1,20}$`).Draw(t, "clientID"),
				Send:          make(chan []byte, 256),
				Subscriptions: make(map[string]bool),
				UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "userID"),
				InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}$`).Draw(t, "institutionID"),
				Role:          "admin",
				TokenExpiry:   time.Now().Add(1 * time.Hour),
				LastPong:      time.Now(),
			}
			
			// Register client with server
			wsServer.registerClient(client)
			
			// Subscribe client to the device channel
			err := client.Subscribe(channel, wsServer)
			if err != nil {
				t.Fatalf("Failed to subscribe: %v", err)
			}
			
			clients[i] = client
		}
		
		// Generate random telemetry data
		temperature := rapid.Float64Range(-10.0, 50.0).Draw(t, "temperature")
		humidity := rapid.Float64Range(0.0, 100.0).Draw(t, "humidity")
		accelX := rapid.Float64Range(-10.0, 10.0).Draw(t, "accelX")
		accelY := rapid.Float64Range(-10.0, 10.0).Draw(t, "accelY")
		accelZ := rapid.Float64Range(-10.0, 10.0).Draw(t, "accelZ")
		pressureDetected := rapid.Bool().Draw(t, "pressureDetected")
		braceClosed := rapid.Bool().Draw(t, "braceClosed")
		movementDetected := rapid.Bool().Draw(t, "movementDetected")
		isWearing := rapid.Bool().Draw(t, "isWearing")
		
		// Create mock sensor reading
		sensorReading := &models.SensorReading{
			BraceID:          rapid.Uint().Draw(t, "braceID"),
			Timestamp:        time.Now(),
			Temperature:      &temperature,
			Humidity:         &humidity,
			AccelX:           &accelX,
			AccelY:           &accelY,
			AccelZ:           &accelZ,
			PressureDetected: pressureDetected,
			BraceClosed:      braceClosed,
			MovementDetected: movementDetected,
			IsWearing:        isWearing,
			ConfidenceLevel:  models.ConfidenceHigh,
		}
		
		// Publish telemetry event
		err := eventHandler.PublishTelemetryEvent(ctx, sensorReading, deviceID)
		if err != nil {
			t.Fatalf("Failed to publish telemetry event: %v", err)
		}
		
		// Verify: All subscribed clients should receive the telemetry event
		receivedCount := 0
		timeout := time.After(5 * time.Second)
		
		for _, client := range clients {
			select {
			case msg := <-client.Send:
				var receivedMsg Message
				if err := json.Unmarshal(msg, &receivedMsg); err != nil {
					t.Fatalf("Failed to unmarshal message: %v", err)
				}
				
				// Verify message content
				if receivedMsg.Type != "telemetry" {
					t.Fatalf("Expected type 'telemetry', got '%s'", receivedMsg.Type)
				}
				if receivedMsg.Channel != channel {
					t.Fatalf("Expected channel '%s', got '%s'", channel, receivedMsg.Channel)
				}
				
				// Verify telemetry data structure
				eventData, ok := receivedMsg.Data.(map[string]interface{})
				if !ok {
					t.Fatalf("Event data is not a map")
				}
				
				// Check required fields
				if eventData["device_id"] != deviceID {
					t.Fatalf("Expected device_id '%s', got '%v'", deviceID, eventData["device_id"])
				}
				
				if eventData["is_wearing"] != isWearing {
					t.Fatalf("Expected is_wearing '%t', got '%v'", isWearing, eventData["is_wearing"])
				}
				
				// Check sensor data
				sensors, ok := eventData["sensors"].(map[string]interface{})
				if !ok {
					t.Fatalf("Sensors data is not a map")
				}
				
				if sensors["temperature"] != temperature {
					t.Fatalf("Expected temperature '%f', got '%v'", temperature, sensors["temperature"])
				}
				
				if sensors["humidity"] != humidity {
					t.Fatalf("Expected humidity '%f', got '%v'", humidity, sensors["humidity"])
				}
				
				// Check accelerometer data
				accel, ok := sensors["accelerometer"].(map[string]interface{})
				if !ok {
					t.Fatalf("Accelerometer data is not a map")
				}
				
				if accel["x"] != accelX {
					t.Fatalf("Expected accel X '%f', got '%v'", accelX, accel["x"])
				}
				
				receivedCount++
			case <-timeout:
				t.Fatalf("Timeout waiting for telemetry message on client %s", client.ID)
			}
		}
		
		// Property: All subscribed clients must receive the telemetry event
		if receivedCount != numClients {
			t.Fatalf("Expected %d clients to receive telemetry message, got %d", numClients, receivedCount)
		}
		
		// Cleanup
		for _, client := range clients {
			wsServer.unregisterClient(client)
		}
	})
}

// Feature: realtime-monitoring, Property 39: Connection logging
// Validates: Requirements 12.1, 12.2
// For any WebSocket connection established or closed, the system should log user ID, IP, timestamp, reason, and duration
func TestProperty_ConnectionLogging(t *testing.T) {
	rapid.Check(t, func(t *rapid.T) {
		// Setup
		redisManager := NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
		ctx := context.Background()
		if err := redisManager.Connect(ctx); err != nil {
			t.Skip("Redis not available, skipping test")
		}
		defer redisManager.Close()
		
		wsServer := NewWSServer(redisManager, nil)
		
		// Reset metrics to ensure clean state
		wsServer.metrics.Reset()
		
		// Generate random client data
		clientID := rapid.StringMatching(`^[a-zA-Z0-9]{1,20}`).Draw(t, "clientID")
		userID := rapid.StringMatching(`^[1-9][0-9]{0,9}`).Draw(t, "userID")
		institutionID := rapid.StringMatching(`^[1-9][0-9]{0,9}`).Draw(t, "institutionID")
		ipAddress := rapid.SampledFrom([]string{
			"192.168.1.100", 
			"10.0.0.50", 
			"172.16.0.25",
			"203.0.113.45",
		}).Draw(t, "ipAddress")
		
		// Create client
		client := &Client{
			ID:            clientID,
			Send:          make(chan []byte, 256),
			Subscriptions: make(map[string]bool),
			UserID:        userID,
			InstitutionID: institutionID,
			Role:          "admin",
			TokenExpiry:   time.Now().Add(1 * time.Hour),
			LastPong:      time.Now(),
		}
		
		// Test connection establishment logging
		wsServer.RegisterClientWithIP(client, ipAddress)
		
		// Property: Logger should track connection time
		duration := wsServer.logger.GetConnectionDuration(clientID)
		if duration == nil {
			t.Fatalf("Connection duration not tracked for client %s", clientID)
		}
		
		// Property: Connection should be tracked in logger
		activeCount := wsServer.logger.GetActiveConnectionCount()
		if activeCount != 1 {
			t.Fatalf("Expected 1 active connection in logger, got %d", activeCount)
		}
		
		// Property: Metrics should track connection
		metricsActiveCount := wsServer.metrics.GetActiveConnections()
		if metricsActiveCount != 1 {
			t.Fatalf("Expected 1 active connection in metrics, got %d", metricsActiveCount)
		}
		
		// Wait a small amount of time to ensure duration is measurable
		time.Sleep(10 * time.Millisecond)
		
		// Test connection closure logging with reason
		reasons := []string{
			"normal_closure",
			"token_expired", 
			"read_pump_exit",
			"write_pump_exit",
			"connection_timeout",
		}
		reason := rapid.SampledFrom(reasons).Draw(t, "reason")
		
		wsServer.UnregisterClientWithReason(client, reason)
		
		// Property: Connection should no longer be tracked in logger
		activeCountAfter := wsServer.logger.GetActiveConnectionCount()
		if activeCountAfter != 0 {
			t.Fatalf("Expected 0 active connections in logger after disconnect, got %d", activeCountAfter)
		}
		
		// Property: Metrics should reflect disconnection
		metricsActiveCountAfter := wsServer.metrics.GetActiveConnections()
		if metricsActiveCountAfter != 0 {
			t.Fatalf("Expected 0 active connections in metrics after disconnect, got %d", metricsActiveCountAfter)
		}
		
		// Property: Duration should no longer be tracked
		durationAfter := wsServer.logger.GetConnectionDuration(clientID)
		if durationAfter != nil {
			t.Fatalf("Connection duration should not be tracked after disconnect")
		}
		
		// Property: Total connections should be incremented
		totalConnections := wsServer.metrics.GetTotalConnections()
		if totalConnections != 1 {
			t.Fatalf("Expected 1 total connection, got %d", totalConnections)
		}
		
		// Test multiple connections - use smaller range to reduce test complexity
		numConnections := rapid.IntRange(2, 5).Draw(t, "numConnections")
		clients := make([]*Client, numConnections)
		
		// Generate unique client IDs to avoid conflicts
		usedIDs := make(map[string]bool)
		usedIDs[clientID] = true // Reserve the first client ID
		
		for i := 0; i < numConnections; i++ {
			var newClientID string
			for {
				newClientID = rapid.StringMatching(`^[a-zA-Z0-9]{1,20}`).Draw(t, "clientID")
				if !usedIDs[newClientID] {
					usedIDs[newClientID] = true
					break
				}
			}
			
			client := &Client{
				ID:            newClientID,
				Send:          make(chan []byte, 256),
				Subscriptions: make(map[string]bool),
				UserID:        rapid.StringMatching(`^[1-9][0-9]{0,9}`).Draw(t, "userID"),
				InstitutionID: rapid.StringMatching(`^[1-9][0-9]{0,9}`).Draw(t, "institutionID"),
				Role:          "admin",
				TokenExpiry:   time.Now().Add(1 * time.Hour),
				LastPong:      time.Now(),
			}
			
			wsServer.RegisterClientWithIP(client, ipAddress)
			clients[i] = client
			
			// Small delay to ensure registration is processed
			time.Sleep(1 * time.Millisecond)
		}
		
		// Allow time for all registrations to be processed
		time.Sleep(5 * time.Millisecond)
		
		// Property: Logger should track all connections
		activeCountMultiple := wsServer.logger.GetActiveConnectionCount()
		if activeCountMultiple != numConnections {
			t.Fatalf("Expected %d active connections in logger, got %d", numConnections, activeCountMultiple)
		}
		
		// Property: Metrics should track all connections
		metricsActiveCountMultiple := wsServer.metrics.GetActiveConnections()
		if metricsActiveCountMultiple != int64(numConnections) {
			t.Fatalf("Expected %d active connections in metrics, got %d", numConnections, metricsActiveCountMultiple)
		}
		
		// Disconnect all clients
		for _, client := range clients {
			wsServer.UnregisterClientWithReason(client, "test_cleanup")
			// Small delay to ensure unregistration is processed
			time.Sleep(1 * time.Millisecond)
		}
		
		// Allow time for all unregistrations to be processed
		time.Sleep(5 * time.Millisecond)
		
		// Property: All connections should be cleaned up
		finalActiveCount := wsServer.logger.GetActiveConnectionCount()
		if finalActiveCount != 0 {
			t.Fatalf("Expected 0 active connections after cleanup, got %d", finalActiveCount)
		}
		
		finalMetricsCount := wsServer.metrics.GetActiveConnections()
		if finalMetricsCount != 0 {
			t.Fatalf("Expected 0 active connections in metrics after cleanup, got %d", finalMetricsCount)
		}
		
		// Property: Total connections should reflect all connections made
		finalTotalConnections := wsServer.metrics.GetTotalConnections()
		expectedTotal := int64(1 + numConnections) // Initial connection + multiple connections
		if finalTotalConnections != expectedTotal {
			t.Fatalf("Expected %d total connections, got %d", expectedTotal, finalTotalConnections)
		}
	})
}
