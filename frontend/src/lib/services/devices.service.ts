/**
 * Serviço de gerenciamento de dispositivos (braces)
 */

import { apiClient } from './api';
import type {
	Brace,
	CreateBraceData,
	UpdateBraceData,
	DevicesListParams,
	DevicesListResponse,
	DeviceCommand,
	CommandResponse,
	CommandsListResponse,
} from '$lib/types/device';

export class DevicesService {
	async list(params?: DevicesListParams): Promise<DevicesListResponse> {
		const queryParams = new URLSearchParams();
		if (params?.page) queryParams.append('page', params.page.toString());
		if (params?.limit) queryParams.append('limit', params.limit.toString());
		if (params?.status) queryParams.append('status', params.status);
		if (params?.patient_id) queryParams.append('patient_id', params.patient_id.toString());
		if (params?.search) queryParams.append('search', params.search);

		const query = queryParams.toString();
		return apiClient.get<DevicesListResponse>(`/api/v1/braces${query ? `?${query}` : ''}`);
	}

	async get(id: number): Promise<Brace> {
		return apiClient.get<Brace>(`/api/v1/braces/${id}`);
	}

	async create(data: CreateBraceData): Promise<Brace> {
		return apiClient.post<Brace>('/api/v1/braces', data);
	}

	async update(id: number, data: UpdateBraceData): Promise<Brace> {
		return apiClient.put<Brace>(`/api/v1/braces/${id}`, data);
	}

	async delete(id: number): Promise<void> {
		return apiClient.delete<void>(`/api/v1/braces/${id}`);
	}

	async getCommands(id: number): Promise<CommandsListResponse> {
		return apiClient.get<CommandsListResponse>(`/api/v1/braces/${id}/commands`);
	}

	async sendCommand(id: number, command: DeviceCommand): Promise<CommandResponse> {
		return apiClient.post<CommandResponse>(`/api/v1/braces/${id}/commands`, command);
	}
}

export const devicesService = new DevicesService();




