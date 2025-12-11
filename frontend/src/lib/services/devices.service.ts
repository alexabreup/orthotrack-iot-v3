/**
 * Serviço de gerenciamento de dispositivos (braces)
 */

import api from '$lib/api/client';
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
		return api.get<DevicesListResponse>(`/braces${query ? `?${query}` : ''}`);
	}

	async get(id: number): Promise<Brace> {
		return api.get<Brace>(`/braces/${id}`);
	}

	async create(data: CreateBraceData): Promise<Brace> {
		return api.post<Brace>('/braces', data);
	}

	async update(id: number, data: UpdateBraceData): Promise<Brace> {
		return api.put<Brace>(`/braces/${id}`, data);
	}

	async delete(id: number): Promise<void> {
		return api.delete<void>(`/braces/${id}`);
	}

	async getCommands(id: number): Promise<CommandsListResponse> {
		return api.get<CommandsListResponse>(`/braces/${id}/commands`);
	}

	async sendCommand(id: number, command: DeviceCommand): Promise<CommandResponse> {
		return api.post<CommandResponse>(`/braces/${id}/commands`, command);
	}
}

export const devicesService = new DevicesService();




