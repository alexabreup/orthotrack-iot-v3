/**
 * Serviço de gerenciamento de pacientes
 */

import { apiClient } from './api';

export interface Patient {
	id: number;
	uuid: string;
	name: string;
	date_of_birth: string;
	gender: string;
	diagnosis?: string;
	prescribed_hours_per_day?: number;
	start_date?: string;
	created_at: string;
	updated_at: string;
}

export interface CreatePatientRequest {
	name: string;
	date_of_birth: string;
	gender: 'M' | 'F' | 'Other';
	diagnosis?: string;
	prescribed_hours_per_day?: number;
	start_date?: string;
}

export interface UpdatePatientRequest extends Partial<CreatePatientRequest> {}

export interface ComplianceReport {
	patient_id: number;
	date: string;
	target_minutes: number;
	actual_minutes: number;
	compliance_percent: number;
	session_count: number;
}

export class PatientsService {
	async getPatients(): Promise<Patient[]> {
		return apiClient.get<Patient[]>('/api/v1/patients');
	}

	async getPatient(id: number): Promise<Patient> {
		return apiClient.get<Patient>(`/api/v1/patients/${id}`);
	}

	async createPatient(data: CreatePatientRequest): Promise<Patient> {
		return apiClient.post<Patient>('/api/v1/patients', data);
	}

	async updatePatient(id: number, data: UpdatePatientRequest): Promise<Patient> {
		return apiClient.put<Patient>(`/api/v1/patients/${id}`, data);
	}

	async deletePatient(id: number): Promise<void> {
		return apiClient.delete<void>(`/api/v1/patients/${id}`);
	}

	async getComplianceReport(patientId: number, startDate?: string, endDate?: string): Promise<ComplianceReport[]> {
		const params = new URLSearchParams();
		if (startDate) params.append('start_date', startDate);
		if (endDate) params.append('end_date', endDate);
		
		const query = params.toString();
		return apiClient.get<ComplianceReport[]>(`/api/v1/reports/compliance?patient_id=${patientId}${query ? `&${query}` : ''}`);
	}
}

export const patientsService = new PatientsService();


