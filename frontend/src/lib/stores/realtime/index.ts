/**
 * Real-time Stores Index
 * Exports all real-time monitoring stores
 */

// Device statuses store
export {
  deviceStatuses,
  initializeDeviceStatusesStore,
  getDeviceStatus,
  updateDeviceStatus,
  clearDeviceStatuses
} from '../device-statuses.store';

// Telemetry data store
export {
  telemetryData,
  initializeTelemetryDataStore,
  getDeviceTelemetryData,
  getLatestTelemetryPoint,
  addTelemetryPoint,
  clearDeviceTelemetryData,
  clearAllTelemetryData,
  getTelemetryDataCount
} from '../telemetry-data.store';

// Active alerts store
export {
  activeAlerts,
  initializeActiveAlertsStore,
  addAlert,
  removeAlert,
  resolveAlert,
  getAlertsByPatient,
  getAlertsBySeverity,
  getUnresolvedAlertsCount,
  clearAllAlerts
} from '../active-alerts.store';

// Dashboard stats store
export {
  dashboardStats,
  initializeDashboardStatsStore,
  updateDashboardStats,
  incrementActivePatients,
  decrementActivePatients,
  incrementOnlineDevices,
  decrementOnlineDevices,
  incrementActiveAlerts,
  decrementActiveAlerts,
  updateAverageCompliance,
  resetDashboardStats,
  getCurrentDashboardStats
} from '../dashboard-stats.store';

// Viewer counts store
export {
  viewerCounts,
  viewerNames,
  initializeViewerCountsStore,
  getViewerCount,
  getViewerNames,
  hasMultipleViewers,
  updateViewerCount,
  clearViewerCount,
  clearAllViewerCounts,
  getChannelsWithViewers,
  getTotalViewerCount
} from '../viewer-counts.store';

// Initialize all stores
export function initializeAllRealtimeStores() {
  initializeDeviceStatusesStore();
  initializeTelemetryDataStore();
  initializeActiveAlertsStore();
  initializeDashboardStatsStore();
  initializeViewerCountsStore();
}