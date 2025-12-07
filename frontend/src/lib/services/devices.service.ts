/**
 * Serviço de gerenciamento de dispositivos (braces)
 */

import { apiClient } from './api';

export interface Device {
	id: number;
	uuid: string;
	serial_number: string;
	patient_id?: number;
	patient_name?: string;
	status: 'online' | 'offline' | 'maintenance';
	battery_level?: number;
	signal_strength?: number;
	last_seen?: string;
	firmware_version?: string;
	created_at: string;
	updated_at: string;
}

export interface CreateDeviceRequest {
	serial_number: string;
	patient_id?: number;
	firmware_version?: string;
}

export interface UpdateDeviceRequest extends Partial<CreateDeviceRequest> {}

export interface DeviceCommand {
	id: number;
	device_id: number;
	command_type: string;
	parameters?: Record<string, unknown>;
	status: 'pending' | 'sent' | 'completed' | 'failed';
	response?: unknown;
	error?: string;
	created_at: string;
	updated_at: string;
}

export interface SendCommandRequest {
	command_type: string;
	parameters?: Record<string, unknown>;
}

export interface TelemetryData {
	device_id: string;
	timestamp: string;
	temperature?: number;
	humidity?: number;
	acceleration?: {
		x: number;
		y: number;
		z: number;
	};
	posture_detected?: string;
	battery_level?: number;
}

export class DevicesService {
	async getDevices(): Promise<Device[]> {
		return apiClient.get<Device[]>('/api/v1/braces');
	}

	async getDevice(id: number): Promise<Device> {
		return apiClient.get<Device>(`/api/v1/braces/${id}`);
	}

	async createDevice(data: CreateDeviceRequest): Promise<Device> {
		return apiClient.post<Device>('/api/v1/braces', data);
	}

	async updateDevice(id: number, data: UpdateDeviceRequest): Promise<Device> {
		return apiClient.put<Device>(`/api/v1/braces/${id}`, data);
	}

	async deleteDevice(id: number): Promise<void> {
		return apiClient.delete<void>(`/api/v1/braces/${id}`);
	}

	async getCommands(deviceId: number): Promise<DeviceCommand[]> {
		return apiClient.get<DeviceCommand[]>(`/api/v1/braces/${deviceId}/commands`);
	}

	async sendCommand(deviceId: number, command: SendCommandRequest): Promise<DeviceCommand> {
		return apiClient.post<DeviceCommand>(`/api/v1/braces/${deviceId}/commands`, command);
	}

	async getTelemetry(deviceId: number, startDate?: string, endDate?: string): Promise<TelemetryData[]> {
		const params = new URLSearchParams();
		if (startDate) params.append('start_date', startDate);
		if (endDate) params.append('end_date', endDate);
		
		const query = params.toString();
		return apiClient.get<TelemetryData[]>(`/api/v1/braces/${deviceId}/telemetry${query ? `?${query}` : ''}`);
	}
}

export const devicesService = new DevicesService();


