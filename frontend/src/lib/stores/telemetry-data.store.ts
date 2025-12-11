/**
 * Telemetry Data Store
 * Manages real-time telemetry data with 100-point buffer per device
 * Requirements: 3.1, 3.2, 3.3
 */

import { writable } from 'svelte/store';
import type { TelemetryPoint, TelemetryEvent } from '$lib/types/websocket';
import { getWebSocketClient } from '$lib/services/websocket.service';

const MAX_TELEMETRY_POINTS = 100;

// Store for telemetry data - Map<device_id, TelemetryPoint[]>
export const telemetryData = writable<Map<string, TelemetryPoint[]>>(new Map());

/**
 * Initialize telemetry data store with WebSocket event handling
 */
export function initializeTelemetryDataStore() {
  const wsClient = getWebSocketClient();
  
  // Handle telemetry events
  wsClient.on('telemetry', (event: TelemetryEvent) => {
    telemetryData.update(data => {
      const newData = new Map(data);
      const deviceId = event.data.device_id;
      
      // Get existing data points for this device
      let deviceData = newData.get(deviceId) || [];
      
      // Create new telemetry point
      const newPoint: TelemetryPoint = {
        timestamp: event.data.timestamp,
        sensors: event.data.sensors
      };
      
      // Add new point to the end
      deviceData = [...deviceData, newPoint];
      
      // Enforce 100-point buffer limit - remove oldest if exceeding limit
      if (deviceData.length > MAX_TELEMETRY_POINTS) {
        deviceData = deviceData.slice(-MAX_TELEMETRY_POINTS);
      }
      
      newData.set(deviceId, deviceData);
      return newData;
    });
  });
}

/**
 * Get telemetry data for a specific device
 */
export function getDeviceTelemetryData(deviceId: string): TelemetryPoint[] {
  let data: TelemetryPoint[] = [];
  telemetryData.subscribe(telemetryMap => {
    data = telemetryMap.get(deviceId) || [];
  })();
  return data;
}

/**
 * Get latest telemetry point for a device
 */
export function getLatestTelemetryPoint(deviceId: string): TelemetryPoint | undefined {
  const data = getDeviceTelemetryData(deviceId);
  return data.length > 0 ? data[data.length - 1] : undefined;
}

/**
 * Add telemetry point manually (for testing or initial data)
 */
export function addTelemetryPoint(deviceId: string, point: TelemetryPoint) {
  telemetryData.update(data => {
    const newData = new Map(data);
    let deviceData = newData.get(deviceId) || [];
    
    // Add new point
    deviceData = [...deviceData, point];
    
    // Enforce buffer limit
    if (deviceData.length > MAX_TELEMETRY_POINTS) {
      deviceData = deviceData.slice(-MAX_TELEMETRY_POINTS);
    }
    
    newData.set(deviceId, deviceData);
    return newData;
  });
}

/**
 * Clear telemetry data for a specific device
 */
export function clearDeviceTelemetryData(deviceId: string) {
  telemetryData.update(data => {
    const newData = new Map(data);
    newData.delete(deviceId);
    return newData;
  });
}

/**
 * Clear all telemetry data
 */
export function clearAllTelemetryData() {
  telemetryData.set(new Map());
}

/**
 * Get telemetry data count for a device
 */
export function getTelemetryDataCount(deviceId: string): number {
  return getDeviceTelemetryData(deviceId).length;
}