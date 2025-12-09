export interface Patient {
	id: number;
	uuid: string;
	external_id: string;
	institution_id: number;
	medical_staff_id?: number;
	name: string;
	date_of_birth?: string;
	gender?: 'M' | 'F';
	cpf?: string;
	email?: string;
	phone?: string;
	guardian_name?: string;
	guardian_phone?: string;
	medical_record?: string;
	diagnosis_code?: string;
	severity_level?: number;
	scoliosis_type?: string;
	prescription_hours?: number;
	daily_usage_target_minutes?: number;
	treatment_start: string;
	treatment_end?: string;
	prescription_notes?: string;
	status: 'active' | 'inactive' | 'completed' | 'suspended';
	is_active: boolean;
	next_appointment?: string;
	created_at: string;
	updated_at: string;
}

export interface CreatePatientData {
	external_id: string;
	name: string;
	date_of_birth?: string;
	gender?: 'M' | 'F';
	cpf?: string;
	email?: string;
	phone?: string;
	guardian_name?: string;
	guardian_phone?: string;
	medical_record?: string;
	diagnosis_code?: string;
	severity_level?: number;
	scoliosis_type?: string;
	prescription_hours?: number;
	daily_usage_target_minutes?: number;
	treatment_start: string;
	treatment_end?: string;
	prescription_notes?: string;
	status?: 'active' | 'inactive' | 'completed' | 'suspended';
}

export interface UpdatePatientData extends Partial<CreatePatientData> {}

export interface PatientsListParams {
	page?: number;
	limit?: number;
	institution_id?: number;
	status?: string;
	is_active?: boolean;
	search?: string;
}

export interface PatientsListResponse {
	data: Patient[];
	total: number;
	page: number;
	limit: number;
	total_pages: number;
}








