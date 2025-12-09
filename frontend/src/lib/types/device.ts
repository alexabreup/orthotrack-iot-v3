export type DeviceStatus = 'online' | 'offline' | 'maintenance' | 'error';

export interface Brace {
	id: number;
	uuid: string;
	patient_id?: number;
	device_id: string;
	serial_number: string;
	mac_address: string;
	model?: string;
	version?: string;
	status: DeviceStatus;
	battery_level?: number;
	battery_voltage?: number;
	signal_strength?: number;
	last_heartbeat?: string;
	last_seen?: string;
	firmware_version?: string;
	hardware_version?: string;
	config?: Record<string, any>;
	calibration_data?: Record<string, any>;
	total_usage_hours?: number;
	last_usage_start?: string;
	last_usage_end?: string;
	created_at: string;
	updated_at: string;
}

export interface CreateBraceData {
	device_id: string;
	serial_number: string;
	mac_address: string;
	model?: string;
	version?: string;
	patient_id?: number;
	status?: DeviceStatus;
	firmware_version?: string;
	hardware_version?: string;
}

export interface UpdateBraceData extends Partial<CreateBraceData> {}

export interface DevicesListParams {
	page?: number;
	limit?: number;
	status?: DeviceStatus;
	patient_id?: number;
	search?: string;
}

export interface DevicesListResponse {
	data: Brace[];
	total: number;
	page: number;
	limit: number;
	total_pages: number;
}

export interface DeviceCommand {
	command_type: 'update_config' | 'restart' | 'calibrate' | 'update_firmware';
	parameters?: Record<string, any>;
	priority?: 'low' | 'normal' | 'high';
}

export interface CommandResponse {
	id: number;
	brace_id: number;
	command_type: string;
	parameters?: Record<string, any>;
	status: 'pending' | 'completed' | 'failed';
	response?: Record<string, any>;
	created_at: string;
	updated_at: string;
}

export interface CommandsListResponse {
	data: CommandResponse[];
	total: number;
}








