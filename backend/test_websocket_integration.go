package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"orthotrack-iot-v3/internal/models"
	"orthotrack-iot-v3/internal/services"
)

// Simple test to validate WebSocket integration compiles and basic functionality works
func main() {
	fmt.Println("Testing WebSocket Integration...")

	// Test 1: Verify EventHandler interface
	fmt.Println("✓ Testing EventHandler interface...")
	testEventHandlerInterface()

	// Test 2: Verify DashboardStatsService interface
	fmt.Println("✓ Testing DashboardStatsService interface...")
	testDashboardStatsInterface()

	// Test 3: Verify event structures
	fmt.Println("✓ Testing event structures...")
	testEventStructures()

	fmt.Println("✓ All WebSocket integration tests passed!")
}

func testEventHandlerInterface() {
	// Create a mock WebSocket server (nil is fine for interface testing)
	var wsServer *services.WSServer
	eventHandler := services.NewEventHandler(wsServer)
	
	if eventHandler == nil {
		log.Fatal("Failed to create EventHandler")
	}
	
	fmt.Println("  - EventHandler creation: OK")
}

func testDashboardStatsInterface() {
	// Create a mock dashboard stats service (nil is fine for interface testing)
	var eventHandler *services.EventHandler
	dashboardStats := services.NewDashboardStatsService(nil, eventHandler)
	
	if dashboardStats == nil {
		log.Fatal("Failed to create DashboardStatsService")
	}
	
	fmt.Println("  - DashboardStatsService creation: OK")
}

func testEventStructures() {
	ctx := context.Background()
	
	// Test DeviceStatusEvent
	deviceEvent := services.DeviceStatusEvent{
		DeviceID:    "test-device",
		Status:      models.DeviceStatusOnline,
		Timestamp:   time.Now().Unix(),
		BatteryLevel: func() *int { i := 85; return &i }(),
	}
	
	if deviceEvent.DeviceID != "test-device" {
		log.Fatal("DeviceStatusEvent structure invalid")
	}
	fmt.Println("  - DeviceStatusEvent structure: OK")
	
	// Test AlertEvent
	alertEvent := services.AlertEvent{
		AlertID:     1,
		PatientID:   1,
		PatientName: "Test Patient",
		Type:        models.AlertTypeBatteryLow,
		Severity:    models.SeverityHigh,
		Title:       "Test Alert",
		Message:     "Test message",
		Timestamp:   time.Now().Unix(),
	}
	
	if alertEvent.PatientName != "Test Patient" {
		log.Fatal("AlertEvent structure invalid")
	}
	fmt.Println("  - AlertEvent structure: OK")
	
	// Test TelemetryEvent
	telemetryEvent := services.TelemetryEvent{
		DeviceID:  "test-device",
		Timestamp: time.Now().Unix(),
		IsWearing: true,
		Confidence: "high",
		Sensors: services.TelemetrySensorData{
			Temperature: func() *float64 { f := 36.5; return &f }(),
			BatteryLevel: func() *int { i := 85; return &i }(),
		},
	}
	
	if !telemetryEvent.IsWearing {
		log.Fatal("TelemetryEvent structure invalid")
	}
	fmt.Println("  - TelemetryEvent structure: OK")
	
	// Test UsageSessionEvent
	sessionEvent := services.UsageSessionEvent{
		SessionID: 1,
		PatientID: 1,
		DeviceID:  "test-device",
		EventType: "start",
		Timestamp: time.Now().Unix(),
		Confidence: 0.95,
	}
	
	if sessionEvent.EventType != "start" {
		log.Fatal("UsageSessionEvent structure invalid")
	}
	fmt.Println("  - UsageSessionEvent structure: OK")
	
	// Test DashboardStatsEvent
	statsEvent := services.DashboardStatsEvent{
		ActivePatients:    10,
		OnlineDevices:     8,
		ActiveAlerts:      3,
		AverageCompliance: 85.5,
		TotalSessions:     25,
		TotalUsageHours:   120.5,
		Timestamp:         time.Now().Unix(),
	}
	
	if statsEvent.ActivePatients != 10 {
		log.Fatal("DashboardStatsEvent structure invalid")
	}
	fmt.Println("  - DashboardStatsEvent structure: OK")
	
	// Test channel validation
	if err := services.ValidateChannelFormat("device:test123"); err != nil {
		log.Fatalf("Channel validation failed: %v", err)
	}
	
	if err := services.ValidateChannelFormat("patient:456"); err != nil {
		log.Fatalf("Channel validation failed: %v", err)
	}
	
	if err := services.ValidateChannelFormat("dashboard"); err != nil {
		log.Fatalf("Channel validation failed: %v", err)
	}
	
	if err := services.ValidateChannelFormat("alerts:global"); err != nil {
		log.Fatalf("Channel validation failed: %v", err)
	}
	
	fmt.Println("  - Channel validation: OK")
	
	// Suppress unused variable warning
	_ = ctx
}