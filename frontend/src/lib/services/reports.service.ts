/**
 * Serviço de relatórios
 */

import api from '$lib/api/client';
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

		return api.get<ComplianceReport>(
			`/reports/compliance?${queryParams.toString()}`
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

		return api.get<UsageReport>(`/reports/usage?${queryParams.toString()}`);
	}
}

export const reportsService = new ReportsService();








