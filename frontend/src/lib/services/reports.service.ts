/**
 * Serviço de relatórios
 */

import { apiClient } from './api';
import type {
	ComplianceReport,
	UsageReport,
	ComplianceReportParams,
	UsageReportParams,
} from '$lib/types/api';

export class ReportsService {
	async compliance(params: ComplianceReportParams): Promise<ComplianceReport> {
		const queryParams = new URLSearchParams();
		queryParams.append('start_date', params.start_date);
		queryParams.append('end_date', params.end_date);
		if (params.patient_id) {
			queryParams.append('patient_id', params.patient_id.toString());
		}

		return apiClient.get<ComplianceReport>(
			`/api/v1/reports/compliance?${queryParams.toString()}`
		);
	}

	async usage(params: UsageReportParams): Promise<UsageReport> {
		const queryParams = new URLSearchParams();
		queryParams.append('start_date', params.start_date);
		queryParams.append('end_date', params.end_date);
		if (params.patient_id) {
			queryParams.append('patient_id', params.patient_id.toString());
		}
		if (params.brace_id) {
			queryParams.append('brace_id', params.brace_id.toString());
		}

		return apiClient.get<UsageReport>(`/api/v1/reports/usage?${queryParams.toString()}`);
	}
}

export const reportsService = new ReportsService();




