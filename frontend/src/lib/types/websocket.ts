/**
 * WebSocket Event Types for Real-time Monitoring
 * Based on the design document specifications
 */

export interface DeviceStatusEvent {
  type: 'device_status';
  channel: string; // 'device:123'
  data: {
    device_id: string;
    status: 'online' | 'offline' | 'maintenance';
    timestamp: number;
    battery_level?: number;
  };
}

export interface AlertEvent {
  type: 'alert_created';
  channel: string; // 'patient:456'
  data: {
    alert_id: string;
    patient_id: string;
    patient_name: string;
    severity: 'info' | 'warning' | 'critical';
    message: string;
    timestamp: number;
  };
}

export interface TelemetryEvent {
  type: 'telemetry';
  channel: string; // 'device:123'
  data: {
    device_id: string;
    timestamp: number;
    sensors: {
      temperature?: number;
      battery_level?: number;
      accelerometer?: { x: number; y: number; z: number };
    };
  };
}

export interface UsageSessionEvent {
  type: 'usage_session_start' | 'usage_session_end';
  channel: string; // 'patient:456'
  data: {
    session_id: string;
    patient_id: string;
    device_id: string;
    timestamp: number;
    duration?: number; // only for end event
  };
}

export interface DashboardStatsEvent {
  type: 'dashboard_stats';
  channel: 'dashboard';
  data: {
    active_patients: number;
    online_devices: number;
    active_alerts: number;
    average_compliance: number;
    timestamp: number;
  };
}

export interface ViewerCountEvent {
  type: 'viewer_count';
  channel: string; // 'patient:456'
  data: {
    count: number;
    viewers: string[]; // user names
  };
}

export interface HeartbeatEvent {
  type: 'heartbeat';
  data: {
    timestamp: number;
  };
}

export interface PongEvent {
  type: 'pong';
  data: {
    timestamp: number;
  };
}

export type WebSocketEvent = 
  | DeviceStatusEvent 
  | AlertEvent 
  | TelemetryEvent 
  | UsageSessionEvent 
  | DashboardStatsEvent 
  | ViewerCountEvent 
  | HeartbeatEvent 
  | PongEvent;

// Data structures for stores
export interface DeviceStatus {
  device_id: string;
  status: 'online' | 'offline' | 'maintenance';
  timestamp: number;
  battery_level?: number;
}

export interface TelemetryPoint {
  timestamp: number;
  sensors: {
    temperature?: number;
    battery_level?: number;
    accelerometer?: { x: number; y: number; z: number };
  };
}

export interface DashboardStats {
  active_patients: number;
  online_devices: number;
  active_alerts: number;
  average_compliance: number;
  timestamp: number;
}