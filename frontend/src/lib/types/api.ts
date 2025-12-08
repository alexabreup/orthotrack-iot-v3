export interface ApiResponse<T> {
	data: T;
	message?: string;
}

export interface PaginatedResponse<T> {
	data: T[];
	total: number;
	page: number;
	limit: number;
	total_pages: number;
}

export interface AuthResponse {
	token: string;
	expires_at: string;
	user: User;
}

export interface User {
	id: number;
	uuid: string;
	name: string;
	email: string;
	role: 'admin' | 'physician' | 'nurse' | 'technician';
	institution_id: number;
	created_at: string;
	updated_at: string;
}

export interface DashboardOverview {
	total_patients: number;
	active_patients: number;
	total_braces: number;
	online_braces: number;
	active_alerts: number;
	today_sessions: number;
	avg_compliance_today: number;
}

export interface ComplianceReport {
	patient_id?: number;
	start_date: string;
	end_date: string;
	daily_compliance: Array<{
		date: string;
		compliance_percent: number;
		target_minutes: number;
		actual_minutes: number;
	}>;
	overall_compliance: number;
	statistics: {
		avg_daily_compliance: number;
		best_day: string;
		worst_day: string;
		total_days: number;
		compliant_days: number;
	};
}

export interface UsageReport {
	patient_id?: number;
	brace_id?: number;
	start_date: string;
	end_date: string;
	sessions: Array<{
		id: number;
		start_time: string;
		end_time?: string;
		duration?: number;
		compliance_score: number;
		comfort_score: number;
		posture_score: number;
	}>;
	statistics: {
		total_sessions: number;
		total_hours: number;
		avg_session_duration: number;
		avg_compliance_score: number;
	};
}

export interface ComplianceReportParams {
	patient_id?: number;
	start_date: string;
	end_date: string;
}

export interface UsageReportParams {
	patient_id?: number;
	brace_id?: number;
	start_date: string;
	end_date: string;
}




