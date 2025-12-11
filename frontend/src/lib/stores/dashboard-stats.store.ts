/**
 * Dashboard Statistics Store
 * Manages real-time dashboard statistics updates
 * Requirements: 6.1
 */

import { writable } from 'svelte/store';
import type { DashboardStats, DashboardStatsEvent } from '$lib/types/websocket';
import { getWebSocketClient } from '$lib/services/websocket.service';

// Initial dashboard stats
const initialStats: DashboardStats = {
  active_patients: 0,
  online_devices: 0,
  active_alerts: 0,
  average_compliance: 0,
  timestamp: Date.now()
};

// Store for dashboard statistics
export const dashboardStats = writable<DashboardStats>(initialStats);

/**
 * Initialize dashboard stats store with WebSocket event handling
 */
export function initializeDashboardStatsStore() {
  const wsClient = getWebSocketClient();
  
  // Handle dashboard statistics events
  wsClient.on('dashboard_stats', (event: DashboardStatsEvent) => {
    dashboardStats.set({
      active_patients: event.data.active_patients,
      online_devices: event.data.online_devices,
      active_alerts: event.data.active_alerts,
      average_compliance: event.data.average_compliance,
      timestamp: event.data.timestamp
    });
  });
}

/**
 * Update dashboard stats manually (for testing or initial data)
 */
export function updateDashboardStats(stats: Partial<DashboardStats>) {
  dashboardStats.update(currentStats => ({
    ...currentStats,
    ...stats,
    timestamp: Date.now()
  }));
}

/**
 * Increment active patients count
 */
export function incrementActivePatients() {
  dashboardStats.update(stats => ({
    ...stats,
    active_patients: stats.active_patients + 1,
    timestamp: Date.now()
  }));
}

/**
 * Decrement active patients count
 */
export function decrementActivePatients() {
  dashboardStats.update(stats => ({
    ...stats,
    active_patients: Math.max(0, stats.active_patients - 1),
    timestamp: Date.now()
  }));
}

/**
 * Increment online devices count
 */
export function incrementOnlineDevices() {
  dashboardStats.update(stats => ({
    ...stats,
    online_devices: stats.online_devices + 1,
    timestamp: Date.now()
  }));
}

/**
 * Decrement online devices count
 */
export function decrementOnlineDevices() {
  dashboardStats.update(stats => ({
    ...stats,
    online_devices: Math.max(0, stats.online_devices - 1),
    timestamp: Date.now()
  }));
}

/**
 * Increment active alerts count
 */
export function incrementActiveAlerts() {
  dashboardStats.update(stats => ({
    ...stats,
    active_alerts: stats.active_alerts + 1,
    timestamp: Date.now()
  }));
}

/**
 * Decrement active alerts count
 */
export function decrementActiveAlerts() {
  dashboardStats.update(stats => ({
    ...stats,
    active_alerts: Math.max(0, stats.active_alerts - 1),
    timestamp: Date.now()
  }));
}

/**
 * Update average compliance
 */
export function updateAverageCompliance(compliance: number) {
  dashboardStats.update(stats => ({
    ...stats,
    average_compliance: Math.max(0, Math.min(100, compliance)), // Clamp between 0-100
    timestamp: Date.now()
  }));
}

/**
 * Reset dashboard stats to initial values
 */
export function resetDashboardStats() {
  dashboardStats.set({
    ...initialStats,
    timestamp: Date.now()
  });
}

/**
 * Get current dashboard stats (synchronous)
 */
export function getCurrentDashboardStats(): DashboardStats {
  let currentStats = initialStats;
  dashboardStats.subscribe(stats => {
    currentStats = stats;
  })();
  return currentStats;
}