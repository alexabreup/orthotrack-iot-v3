/**
 * Serviço de gerenciamento de alertas
 */

import api from '$lib/api/client';
import type {
	Alert,
	AlertsListParams,
	AlertsListResponse,
	AlertStatistics,
} from '$lib/types/alert';

export class AlertsService {
	async list(params?: AlertsListParams): Promise<AlertsListResponse> {
		const queryParams = new URLSearchParams();
		if (params?.page) queryParams.append('page', params.page.toString());
		if (params?.limit) queryParams.append('limit', params.limit.toString());
		if (params?.patient_id) queryParams.append('patient_id', params.patient_id.toString());
		if (params?.brace_id) queryParams.append('brace_id', params.brace_id.toString());
		if (params?.severity) queryParams.append('severity', params.severity);
		if (params?.type) queryParams.append('type', params.type);
		if (params?.resolved !== undefined) queryParams.append('resolved', params.resolved.toString());
		if (params?.start_date) queryParams.append('start_date', params.start_date);
		if (params?.end_date) queryParams.append('end_date', params.end_date);

		const query = queryParams.toString();
		return api.get<AlertsListResponse>(`/alerts${query ? `?${query}` : ''}`);
	}

	async get(id: number): Promise<Alert> {
		return api.get<Alert>(`/alerts/${id}`);
	}

	async resolve(id: number, notes?: string): Promise<Alert> {
		return api.put<Alert>(`/alerts/${id}/resolve`, { notes });
	}

	async getStatistics(period: string = '24h'): Promise<AlertStatistics> {
		return api.get<AlertStatistics>(`/alerts/statistics?period=${period}`);
	}
}

export const alertsService = new AlertsService();




