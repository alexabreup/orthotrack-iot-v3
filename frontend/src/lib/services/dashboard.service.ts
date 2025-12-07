/**
 * Serviço de dashboard
 */

import { apiClient } from './api';

export interface DashboardOverview {
	total_patients: number;
	total_devices: number;
	online_devices: number;
	offline_devices: number;
	active_alerts: number;
	critical_alerts: number;
	total_compliance_percent: number;
	avg_daily_usage_hours: number;
	recent_activity: ActivityItem[];
}

export interface ActivityItem {
	id: number;
	type: 'device_connected' | 'device_disconnected' | 'alert_created' | 'patient_created' | 'data_synced';
	description: string;
	timestamp: string;
	metadata?: Record<string, unknown>;
}

export interface RealtimeData {
	devices_online: number;
	devices_offline: number;
	active_sessions: number;
	alerts_unresolved: number;
	recent_telemetry: TelemetryPoint[];
}

export interface TelemetryPoint {
	device_id: number;
	device_serial: string;
	timestamp: string;
	temperature?: number;
	battery_level?: number;
	posture_detected?: string;
}

export class DashboardService {
	async getOverview(): Promise<DashboardOverview> {
		return apiClient.get<DashboardOverview>('/api/v1/dashboard/overview');
	}

	async getRealtimeData(): Promise<RealtimeData> {
		return apiClient.get<RealtimeData>('/api/v1/dashboard/realtime');
	}
}

export const dashboardService = new DashboardService();


