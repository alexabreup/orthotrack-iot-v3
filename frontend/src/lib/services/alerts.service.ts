/**
 * Serviço de gerenciamento de alertas
 */

import { apiClient } from './api';

export interface Alert {
	id: number;
	brace_id: number;
	device_serial?: string;
	patient_id?: number;
	patient_name?: string;
	type: string;
	severity: 'critical' | 'high' | 'medium' | 'low';
	title: string;
	message: string;
	value?: number;
	resolved: boolean;
	resolved_at?: string;
	resolved_by?: number;
	created_at: string;
	updated_at: string;
}

export interface AlertStatistics {
	total: number;
	by_severity: {
		critical: number;
		high: number;
		medium: number;
		low: number;
	};
	by_type: Record<string, number>;
	unresolved: number;
	resolved_today: number;
}

export interface AlertFilters {
	severity?: 'critical' | 'high' | 'medium' | 'low';
	type?: string;
	resolved?: boolean;
	patient_id?: number;
	device_id?: number;
	start_date?: string;
	end_date?: string;
}

export class AlertsService {
	async getAlerts(filters?: AlertFilters): Promise<Alert[]> {
		const params = new URLSearchParams();
		if (filters) {
			Object.entries(filters).forEach(([key, value]) => {
				if (value !== undefined && value !== null) {
					params.append(key, String(value));
				}
			});
		}
		
		const query = params.toString();
		return apiClient.get<Alert[]>(`/api/v1/alerts${query ? `?${query}` : ''}`);
	}

	async getAlert(id: number): Promise<Alert> {
		return apiClient.get<Alert>(`/api/v1/alerts/${id}`);
	}

	async resolveAlert(id: number): Promise<Alert> {
		return apiClient.put<Alert>(`/api/v1/alerts/${id}/resolve`);
	}

	async getStatistics(): Promise<AlertStatistics> {
		return apiClient.get<AlertStatistics>('/api/v1/alerts/statistics');
	}
}

export const alertsService = new AlertsService();


