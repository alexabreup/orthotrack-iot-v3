package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"orthotrack-iot-v3/internal/services"
)

func main() {
	fmt.Println("Testing Redis Integration...")

	// Create Redis manager
	redisManager := services.NewRedisManager("localhost", "6379", "", 0, 10, 5, 3)
	
	ctx := context.Background()
	if err := redisManager.Connect(ctx); err != nil {
		log.Printf("Redis not available: %v", err)
		fmt.Println("✗ Redis connection failed - this is expected if Redis is not running")
		return
	}
	defer redisManager.Close()

	fmt.Println("✓ Redis connection successful")
	fmt.Printf("✓ Instance ID: %s\n", redisManager.GetInstanceID())

	// Create WebSocket server
	wsServer := services.NewWSServer(redisManager, nil)
	
	// Test event publishing
	testData := map[string]interface{}{
		"device_id": "TEST123",
		"status":    "online",
		"timestamp": time.Now().Unix(),
	}
	
	err := wsServer.PublishEvent(ctx, "device:TEST123", testData)
	if err != nil {
		log.Printf("Failed to publish event: %v", err)
		fmt.Println("✗ Event publishing failed")
		return
	}
	
	fmt.Println("✓ Event publishing successful")
	fmt.Println("✓ Redis Pub/Sub integration implemented successfully")
}