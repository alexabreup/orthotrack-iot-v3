package services

import (
	"encoding/json"
	"net/http"
	"sync"
	"sync/atomic"
	"time"
)

// WSMetrics tracks WebSocket server metrics
type WSMetrics struct {
	mu sync.RWMutex
	
	// Connection metrics
	activeConnections int64
	totalConnections  int64
	
	// Event metrics
	eventsPerSecond   int64
	totalEventsSent   int64
	lastEventTime     time.Time
	
	// Latency tracking
	latencySum        int64 // in microseconds
	latencyCount      int64
	
	// Error metrics
	connectionErrors  int64
	authErrors        int64
	
	// Performance metrics
	startTime         time.Time
	
	// Event rate calculation
	eventCounts       []int64
	eventCountIndex   int
	eventCountWindow  int
}

// NewWSMetrics creates a new metrics tracker
func NewWSMetrics() *WSMetrics {
	return &WSMetrics{
		startTime:        time.Now(),
		eventCountWindow: 60, // 60 seconds window for events per second calculation
		eventCounts:      make([]int64, 60),
	}
}

// IncrementActiveConnections increments the active connection count
func (m *WSMetrics) IncrementActiveConnections() {
	atomic.AddInt64(&m.activeConnections, 1)
	atomic.AddInt64(&m.totalConnections, 1)
}

// DecrementActiveConnections decrements the active connection count
func (m *WSMetrics) DecrementActiveConnections() {
	atomic.AddInt64(&m.activeConnections, -1)
}

// RecordEventSent records that an event was sent
func (m *WSMetrics) RecordEventSent(latencyMicros int64) {
	atomic.AddInt64(&m.totalEventsSent, 1)
	
	// Update latency tracking
	atomic.AddInt64(&m.latencySum, latencyMicros)
	atomic.AddInt64(&m.latencyCount, 1)
	
	// Update events per second calculation
	m.mu.Lock()
	m.lastEventTime = time.Now()
	currentSecond := int(time.Now().Unix()) % m.eventCountWindow
	if currentSecond != m.eventCountIndex {
		// Reset counter for new second
		m.eventCounts[currentSecond] = 0
		m.eventCountIndex = currentSecond
	}
	m.eventCounts[currentSecond]++
	m.mu.Unlock()
}

// RecordConnectionError records a connection error
func (m *WSMetrics) RecordConnectionError() {
	atomic.AddInt64(&m.connectionErrors, 1)
}

// RecordAuthError records an authentication/authorization error
func (m *WSMetrics) RecordAuthError() {
	atomic.AddInt64(&m.authErrors, 1)
}

// GetActiveConnections returns the current number of active connections
func (m *WSMetrics) GetActiveConnections() int64 {
	return atomic.LoadInt64(&m.activeConnections)
}

// GetTotalConnections returns the total number of connections since start
func (m *WSMetrics) GetTotalConnections() int64 {
	return atomic.LoadInt64(&m.totalConnections)
}

// GetEventsPerSecond calculates the current events per second rate
func (m *WSMetrics) GetEventsPerSecond() float64 {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	var total int64
	for _, count := range m.eventCounts {
		total += count
	}
	
	return float64(total) / float64(m.eventCountWindow)
}

// GetAverageLatency returns the average event latency in milliseconds
func (m *WSMetrics) GetAverageLatency() float64 {
	sum := atomic.LoadInt64(&m.latencySum)
	count := atomic.LoadInt64(&m.latencyCount)
	
	if count == 0 {
		return 0
	}
	
	// Convert from microseconds to milliseconds
	return float64(sum) / float64(count) / 1000.0
}

// GetTotalEventsSent returns the total number of events sent
func (m *WSMetrics) GetTotalEventsSent() int64 {
	return atomic.LoadInt64(&m.totalEventsSent)
}

// GetConnectionErrors returns the total number of connection errors
func (m *WSMetrics) GetConnectionErrors() int64 {
	return atomic.LoadInt64(&m.connectionErrors)
}

// GetAuthErrors returns the total number of authentication errors
func (m *WSMetrics) GetAuthErrors() int64 {
	return atomic.LoadInt64(&m.authErrors)
}

// GetUptime returns the server uptime
func (m *WSMetrics) GetUptime() time.Duration {
	return time.Since(m.startTime)
}

// MetricsSnapshot represents a point-in-time snapshot of metrics
type MetricsSnapshot struct {
	Timestamp         time.Time `json:"timestamp"`
	ActiveConnections int64     `json:"active_connections"`
	TotalConnections  int64     `json:"total_connections"`
	EventsPerSecond   float64   `json:"events_per_second"`
	TotalEventsSent   int64     `json:"total_events_sent"`
	AverageLatencyMs  float64   `json:"average_latency_ms"`
	ConnectionErrors  int64     `json:"connection_errors"`
	AuthErrors        int64     `json:"auth_errors"`
	UptimeSeconds     int64     `json:"uptime_seconds"`
}

// GetSnapshot returns a snapshot of current metrics
func (m *WSMetrics) GetSnapshot() MetricsSnapshot {
	return MetricsSnapshot{
		Timestamp:         time.Now(),
		ActiveConnections: m.GetActiveConnections(),
		TotalConnections:  m.GetTotalConnections(),
		EventsPerSecond:   m.GetEventsPerSecond(),
		TotalEventsSent:   m.GetTotalEventsSent(),
		AverageLatencyMs:  m.GetAverageLatency(),
		ConnectionErrors:  m.GetConnectionErrors(),
		AuthErrors:        m.GetAuthErrors(),
		UptimeSeconds:     int64(m.GetUptime().Seconds()),
	}
}

// StartMetricsCollection starts background metrics collection
func (m *WSMetrics) StartMetricsCollection() {
	// Reset event counts every second
	ticker := time.NewTicker(1 * time.Second)
	go func() {
		defer ticker.Stop()
		for range ticker.C {
			m.mu.Lock()
			currentSecond := int(time.Now().Unix()) % m.eventCountWindow
			if currentSecond != m.eventCountIndex {
				// Clear old counts as we move to new seconds
				for i := (m.eventCountIndex + 1) % m.eventCountWindow; i != currentSecond; i = (i + 1) % m.eventCountWindow {
					m.eventCounts[i] = 0
				}
				m.eventCountIndex = currentSecond
			}
			m.mu.Unlock()
		}
	}()
}

// ServeMetricsHTTP serves metrics via HTTP endpoint
func (m *WSMetrics) ServeMetricsHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	snapshot := m.GetSnapshot()
	
	if err := json.NewEncoder(w).Encode(snapshot); err != nil {
		http.Error(w, "Failed to encode metrics", http.StatusInternalServerError)
		return
	}
}

// Reset resets all metrics (useful for testing)
func (m *WSMetrics) Reset() {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	atomic.StoreInt64(&m.activeConnections, 0)
	atomic.StoreInt64(&m.totalConnections, 0)
	atomic.StoreInt64(&m.eventsPerSecond, 0)
	atomic.StoreInt64(&m.totalEventsSent, 0)
	atomic.StoreInt64(&m.latencySum, 0)
	atomic.StoreInt64(&m.latencyCount, 0)
	atomic.StoreInt64(&m.connectionErrors, 0)
	atomic.StoreInt64(&m.authErrors, 0)
	
	m.startTime = time.Now()
	m.eventCounts = make([]int64, m.eventCountWindow)
	m.eventCountIndex = 0
}