/**
 * Serviço de dashboard
 */

import api from '$lib/api/client';

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
		return api.get<DashboardOverview>('/dashboard/overview');
	}

	async getRealtimeData(): Promise<RealtimeData> {
		return api.get<RealtimeData>('/dashboard/realtime');
	}

	async getRealtime(deviceId?: string): Promise<RealtimeData> {
		const url = deviceId
			? `/dashboard/realtime?device_id=${deviceId}`
			: '/dashboard/realtime';
		return api.get<RealtimeData>(url);
	}
}

export const dashboardService = new DashboardService();




