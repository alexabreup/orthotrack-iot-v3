export type ConfidenceLevel = 'low' | 'medium' | 'high';

export interface SensorReading {
	id: number;
	uuid: string;
	brace_id: number;
	patient_id?: number;
	session_id?: number;
	timestamp: string;
	accel_x?: number;
	accel_y?: number;
	accel_z?: number;
	gyro_x?: number;
	gyro_y?: number;
	gyro_z?: number;
	movement_detected: boolean;
	temperature?: number;
	humidity?: number;
	pressure_detected: boolean;
	pressure_value?: number;
	brace_closed: boolean;
	is_wearing: boolean;
	confidence_level: ConfidenceLevel;
}

export interface TelemetryData {
	device_id: string;
	timestamp: string;
	sensors: {
		accelerometer?: {
			type: string;
			value: { x: number; y: number; z: number };
			unit: string;
		};
		gyroscope?: {
			type: string;
			value: { x: number; y: number; z: number };
			unit: string;
		};
		temperature?: {
			type: string;
			value: number;
			unit: string;
		};
		humidity?: {
			type: string;
			value: number;
			unit: string;
		};
		pressure?: {
			type: string;
			value: number;
			unit: string;
		};
	};
	battery_level?: number;
	status?: string;
}

export interface RealtimeData {
	telemetry: Record<string, SensorReading>;
	alerts: any[];
}




