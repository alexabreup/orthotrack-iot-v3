/**
 * Serviço de gerenciamento de pacientes
 */

import api from '$lib/api/client';
import type {
	Patient,
	CreatePatientData,
	UpdatePatientData,
	PatientsListParams,
	PatientsListResponse,
} from '$lib/types/patient';

export class PatientsService {
	async list(params?: PatientsListParams): Promise<PatientsListResponse> {
		const queryParams = new URLSearchParams();
		if (params?.page) queryParams.append('page', params.page.toString());
		if (params?.limit) queryParams.append('limit', params.limit.toString());
		if (params?.institution_id) queryParams.append('institution_id', params.institution_id.toString());
		if (params?.status) queryParams.append('status', params.status);
		if (params?.is_active !== undefined) queryParams.append('is_active', params.is_active.toString());
		if (params?.search) queryParams.append('search', params.search);

		const query = queryParams.toString();
		return api.get<PatientsListResponse>(`/patients${query ? `?${query}` : ''}`);
	}

	async get(id: number): Promise<Patient> {
		return api.get<Patient>(`/patients/${id}`);
	}

	async create(data: CreatePatientData): Promise<Patient> {
		return api.post<Patient>('/patients', data);
	}

	async update(id: number, data: UpdatePatientData): Promise<Patient> {
		return api.put<Patient>(`/patients/${id}`, data);
	}

	async delete(id: number): Promise<void> {
		return api.delete<void>(`/patients/${id}`);
	}
}

export const patientsService = new PatientsService();




