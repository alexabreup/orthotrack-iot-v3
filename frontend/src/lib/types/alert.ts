export type AlertType =
	| 'battery_low'
	| 'compliance_low'
	| 'temperature_high'
	| 'temperature_low'
	| 'device_offline'
	| 'sensor_error'
	| 'firmware_update'
	| 'usage_anomaly'
	| 'maintenance_required';

export type Severity = 'low' | 'medium' | 'high' | 'critical';

export interface Alert {
	id: number;
	uuid: string;
	patient_id?: number;
	brace_id?: number;
	session_id?: number;
	type: AlertType;
	severity: Severity;
	title: string;
	message: string;
	value?: number;
	threshold?: number;
	resolved: boolean;
	resolved_at?: string;
	resolved_by?: number;
	notes?: string;
	created_at: string;
	updated_at: string;
}

export interface AlertsListParams {
	page?: number;
	limit?: number;
	patient_id?: number;
	brace_id?: number;
	severity?: Severity;
	type?: AlertType;
	resolved?: boolean;
	start_date?: string;
	end_date?: string;
}

export interface AlertsListResponse {
	data: Alert[];
	total: number;
	page: number;
	limit: number;
	total_pages: number;
}

export interface AlertStatistics {
	total: number;
	by_severity: Record<Severity, number>;
	by_type: Record<AlertType, number>;
	average_resolution_time?: number;
}




