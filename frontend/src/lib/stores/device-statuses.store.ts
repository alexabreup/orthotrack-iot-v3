/**
 * Device Statuses Store
 * Manages real-time device status updates via WebSocket
 * Requirements: 1.1, 1.2
 */

import { writable } from 'svelte/store';
import type { DeviceStatus, DeviceStatusEvent } from '$lib/types/websocket';
import { getWebSocketClient } from '$lib/services/websocket.service';

// Store for device statuses - Map<device_id, DeviceStatus>
export const deviceStatuses = writable<Map<string, DeviceStatus>>(new Map());

/**
 * Initialize device statuses store with WebSocket event handling
 */
export function initializeDeviceStatusesStore() {
  const wsClient = getWebSocketClient();
  
  // Handle device status events
  wsClient.on('device_status', (event: DeviceStatusEvent) => {
    deviceStatuses.update(statuses => {
      const newStatuses = new Map(statuses);
      newStatuses.set(event.data.device_id, {
        device_id: event.data.device_id,
        status: event.data.status,
        timestamp: event.data.timestamp,
        battery_level: event.data.battery_level
      });
      return newStatuses;
    });
  });
}

/**
 * Get device status by ID
 */
export function getDeviceStatus(deviceId: string): DeviceStatus | undefined {
  let status: DeviceStatus | undefined;
  deviceStatuses.subscribe(statuses => {
    status = statuses.get(deviceId);
  })();
  return status;
}

/**
 * Update device status manually (for testing or initial data)
 */
export function updateDeviceStatus(deviceId: string, status: DeviceStatus) {
  deviceStatuses.update(statuses => {
    const newStatuses = new Map(statuses);
    newStatuses.set(deviceId, status);
    return newStatuses;
  });
}

/**
 * Clear all device statuses
 */
export function clearDeviceStatuses() {
  deviceStatuses.set(new Map());
}