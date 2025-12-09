/**
 * Constantes do sistema
 */

export const ALERT_TYPES = {
	battery_low: 'Bateria Baixa',
	compliance_low: 'Compliance Baixa',
	temperature_high: 'Temperatura Alta',
	temperature_low: 'Temperatura Baixa',
	device_offline: 'Dispositivo Offline',
	sensor_error: 'Erro de Sensor',
	firmware_update: 'Atualização de Firmware',
	usage_anomaly: 'Anomalia de Uso',
	maintenance_required: 'Manutenção Necessária',
} as const;

export const ALERT_SEVERITY_COLORS = {
	low: 'text-muted-foreground bg-secondary',
	medium: 'text-warning bg-warning/10',
	high: 'text-destructive bg-destructive/10',
	critical: 'text-destructive bg-destructive/20 border border-destructive',
} as const;

export const ALERT_ICONS = {
	battery_low: '🔋',
	compliance_low: '📉',
	temperature_high: '🌡️',
	temperature_low: '🌡️',
	device_offline: '📴',
	sensor_error: '⚠️',
	firmware_update: '🔄',
	usage_anomaly: '📊',
	maintenance_required: '🔧',
} as const;

export const DEVICE_STATUS_COLORS = {
	online: 'text-online bg-online/10',
	offline: 'text-offline bg-offline/10',
	maintenance: 'text-warning bg-warning/10',
	error: 'text-destructive bg-destructive/10',
} as const;

export const PATIENT_STATUS_COLORS = {
	active: 'text-success bg-success/10',
	inactive: 'text-muted-foreground bg-secondary',
	completed: 'text-info bg-info/10',
	suspended: 'text-warning bg-warning/10',
} as const;

export const PAGINATION_DEFAULT = {
	page: 1,
	limit: 20,
} as const;

export const REALTIME_POLL_INTERVAL = 30000; // 30 segundos








