/**
 * Active Alerts Store
 * Manages real-time alert notifications
 * Requirements: 2.1
 */

import { writable } from 'svelte/store';
import type { Alert } from '$lib/types/alert';
import type { AlertEvent } from '$lib/types/websocket';
import { getWebSocketClient } from '$lib/services/websocket.service';

// Store for active alerts - Alert[]
export const activeAlerts = writable<Alert[]>([]);

/**
 * Initialize active alerts store with WebSocket event handling
 */
export function initializeActiveAlertsStore() {
  const wsClient = getWebSocketClient();
  
  // Handle alert created events
  wsClient.on('alert_created', (event: AlertEvent) => {
    activeAlerts.update(alerts => {
      // Create new alert from event data
      const newAlert: Alert = {
        id: parseInt(event.data.alert_id) || 0, // Convert string to number, fallback to 0
        uuid: event.data.alert_id,
        patient_id: parseInt(event.data.patient_id) || undefined,
        brace_id: undefined, // Not provided in event
        session_id: undefined, // Not provided in event
        type: 'device_offline', // Default type, should be provided in event
        severity: event.data.severity as 'low' | 'medium' | 'high' | 'critical',
        title: `Alert for ${event.data.patient_name}`,
        message: event.data.message,
        value: undefined,
        threshold: undefined,
        resolved: false,
        resolved_at: undefined,
        resolved_by: undefined,
        notes: undefined,
        created_at: new Date(event.data.timestamp).toISOString(),
        updated_at: new Date(event.data.timestamp).toISOString()
      };
      
      // Add new alert to the beginning of the array (most recent first)
      return [newAlert, ...alerts];
    });
  });
}

/**
 * Add alert manually (for testing or initial data)
 */
export function addAlert(alert: Alert) {
  activeAlerts.update(alerts => [alert, ...alerts]);
}

/**
 * Remove alert by ID
 */
export function removeAlert(alertId: number) {
  activeAlerts.update(alerts => alerts.filter(alert => alert.id !== alertId));
}

/**
 * Mark alert as resolved
 */
export function resolveAlert(alertId: number, resolvedBy?: number, notes?: string) {
  activeAlerts.update(alerts => 
    alerts.map(alert => 
      alert.id === alertId 
        ? {
            ...alert,
            resolved: true,
            resolved_at: new Date().toISOString(),
            resolved_by: resolvedBy,
            notes: notes
          }
        : alert
    )
  );
}

/**
 * Get alerts by patient ID
 */
export function getAlertsByPatient(patientId: number): Alert[] {
  let patientAlerts: Alert[] = [];
  activeAlerts.subscribe(alerts => {
    patientAlerts = alerts.filter(alert => alert.patient_id === patientId);
  })();
  return patientAlerts;
}

/**
 * Get alerts by severity
 */
export function getAlertsBySeverity(severity: 'low' | 'medium' | 'high' | 'critical'): Alert[] {
  let severityAlerts: Alert[] = [];
  activeAlerts.subscribe(alerts => {
    severityAlerts = alerts.filter(alert => alert.severity === severity);
  })();
  return severityAlerts;
}

/**
 * Get unresolved alerts count
 */
export function getUnresolvedAlertsCount(): number {
  let count = 0;
  activeAlerts.subscribe(alerts => {
    count = alerts.filter(alert => !alert.resolved).length;
  })();
  return count;
}

/**
 * Clear all alerts
 */
export function clearAllAlerts() {
  activeAlerts.set([]);
}