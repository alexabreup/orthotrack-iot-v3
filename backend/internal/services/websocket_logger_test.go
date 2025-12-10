package services

import (
	"testing"
	"time"
)

// Basic unit test for WebSocket logger functionality
func TestWSLogger_BasicFunctionality(t *testing.T) {
	logger := NewWSLogger()
	
	// Test connection tracking
	client := &Client{
		ID:            "test-client-1",
		UserID:        "123",
		InstitutionID: "456",
		Role:          "admin",
	}
	
	// Test connection establishment logging
	logger.LogConnectionEstablished(client, "192.168.1.100")
	
	// Verify connection is tracked
	duration := logger.GetConnectionDuration("test-client-1")
	if duration == nil {
		t.Fatalf("Expected connection to be tracked")
	}
	
	// Verify active connection count
	activeCount := logger.GetActiveConnectionCount()
	if activeCount != 1 {
		t.Fatalf("Expected 1 active connection, got %d", activeCount)
	}
	
	// Wait a bit to ensure duration is measurable
	time.Sleep(10 * time.Millisecond)
	
	// Test connection closure logging
	logger.LogConnectionClosed(client, "normal_closure")
	
	// Verify connection is no longer tracked
	durationAfter := logger.GetConnectionDuration("test-client-1")
	if durationAfter != nil {
		t.Fatalf("Expected connection to no longer be tracked")
	}
	
	// Verify active connection count is zero
	activeCountAfter := logger.GetActiveConnectionCount()
	if activeCountAfter != 0 {
		t.Fatalf("Expected 0 active connections, got %d", activeCountAfter)
	}
}

// Basic unit test for WebSocket metrics functionality
func TestWSMetrics_BasicFunctionality(t *testing.T) {
	metrics := NewWSMetrics()
	
	// Test connection metrics
	metrics.IncrementActiveConnections()
	activeCount := metrics.GetActiveConnections()
	if activeCount != 1 {
		t.Fatalf("Expected 1 active connection, got %d", activeCount)
	}
	
	totalCount := metrics.GetTotalConnections()
	if totalCount != 1 {
		t.Fatalf("Expected 1 total connection, got %d", totalCount)
	}
	
	// Test event metrics
	metrics.RecordEventSent(1000) // 1ms latency
	totalEvents := metrics.GetTotalEventsSent()
	if totalEvents != 1 {
		t.Fatalf("Expected 1 total event, got %d", totalEvents)
	}
	
	avgLatency := metrics.GetAverageLatency()
	if avgLatency != 1.0 { // 1000 microseconds = 1 millisecond
		t.Fatalf("Expected 1.0ms average latency, got %f", avgLatency)
	}
	
	// Test error metrics
	metrics.RecordConnectionError()
	errorCount := metrics.GetConnectionErrors()
	if errorCount != 1 {
		t.Fatalf("Expected 1 connection error, got %d", errorCount)
	}
	
	metrics.RecordAuthError()
	authErrorCount := metrics.GetAuthErrors()
	if authErrorCount != 1 {
		t.Fatalf("Expected 1 auth error, got %d", authErrorCount)
	}
	
	// Test disconnection
	metrics.DecrementActiveConnections()
	activeCountAfter := metrics.GetActiveConnections()
	if activeCountAfter != 0 {
		t.Fatalf("Expected 0 active connections after disconnect, got %d", activeCountAfter)
	}
	
	// Total connections should remain the same
	totalCountAfter := metrics.GetTotalConnections()
	if totalCountAfter != 1 {
		t.Fatalf("Expected total connections to remain 1, got %d", totalCountAfter)
	}
}

// Test metrics snapshot functionality
func TestWSMetrics_Snapshot(t *testing.T) {
	metrics := NewWSMetrics()
	
	// Set up some metrics
	metrics.IncrementActiveConnections()
	metrics.RecordEventSent(2000) // 2ms latency
	metrics.RecordConnectionError()
	
	// Get snapshot
	snapshot := metrics.GetSnapshot()
	
	// Verify snapshot data
	if snapshot.ActiveConnections != 1 {
		t.Fatalf("Expected 1 active connection in snapshot, got %d", snapshot.ActiveConnections)
	}
	
	if snapshot.TotalConnections != 1 {
		t.Fatalf("Expected 1 total connection in snapshot, got %d", snapshot.TotalConnections)
	}
	
	if snapshot.TotalEventsSent != 1 {
		t.Fatalf("Expected 1 total event in snapshot, got %d", snapshot.TotalEventsSent)
	}
	
	if snapshot.AverageLatencyMs != 2.0 {
		t.Fatalf("Expected 2.0ms average latency in snapshot, got %f", snapshot.AverageLatencyMs)
	}
	
	if snapshot.ConnectionErrors != 1 {
		t.Fatalf("Expected 1 connection error in snapshot, got %d", snapshot.ConnectionErrors)
	}
	
	// Verify timestamp is recent
	timeDiff := time.Since(snapshot.Timestamp)
	if timeDiff > 1*time.Second {
		t.Fatalf("Snapshot timestamp too old: %v", timeDiff)
	}
}