<script lang="ts">
	import { onMount } from 'svelte';
	import ComplianceReport from '$lib/components/reports/ComplianceReport.svelte';
	import UsageReport from '$lib/components/reports/UsageReport.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import { reportsService } from '$lib/services/reports.service';
	import { patientsService } from '$lib/services/patients.service';
	import type { Patient } from '$lib/types/patient';

	let reportType: 'compliance' | 'usage' = 'compliance';
	let patientId: number | undefined = undefined;
	let startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
	let endDate = new Date().toISOString().split('T')[0];
	let patients: Patient[] = [];

	onMount(async () => {
		try {
			const response = await patientsService.list({ limit: 100 });
			patients = response.data;
		} catch (err) {
			console.error('Erro ao carregar pacientes:', err);
		}
	});

	async function loadComplianceReport() {
		return reportsService.compliance({
			patient_id: patientId,
			start_date: startDate,
			end_date: endDate,
		});
	}

	async function loadUsageReport() {
		return reportsService.usage({
			patient_id: patientId,
			start_date: startDate,
			end_date: endDate,
		});
	}
</script>

<div class="space-y-6">
	<div>
		<h1 class="text-3xl font-bold">Relatórios</h1>
		<p class="mt-2 text-muted-foreground">Gere relatórios de compliance e uso</p>
	</div>

	<Card class="p-6">
		<div class="space-y-4">
			<div class="flex gap-4">
				<Button
					variant={reportType === 'compliance' ? 'default' : 'outline'}
					on:click={() => (reportType = 'compliance')}
				>
					Compliance
				</Button>
				<Button
					variant={reportType === 'usage' ? 'default' : 'outline'}
					on:click={() => (reportType = 'usage')}
				>
					Uso
				</Button>
			</div>

			<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
				<div>
					<label for="patient" class="mb-2 block text-sm font-medium">Paciente (opcional)</label>
					<select
						id="patient"
						bind:value={patientId}
						class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
					>
						<option value={undefined}>Todos os pacientes</option>
						{#each patients as patient}
							<option value={patient.id}>{patient.name}</option>
						{/each}
					</select>
				</div>

				<div>
					<label for="start_date" class="mb-2 block text-sm font-medium">Data Inicial</label>
					<input
						id="start_date"
						type="date"
						bind:value={startDate}
						class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
					/>
				</div>

				<div>
					<label for="end_date" class="mb-2 block text-sm font-medium">Data Final</label>
					<input
						id="end_date"
						type="date"
						bind:value={endDate}
						class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
					/>
				</div>
			</div>
		</div>
	</Card>

	{#if reportType === 'compliance'}
		<ComplianceReport
			{patientId}
			{startDate}
			{endDate}
			onLoad={loadComplianceReport}
		/>
	{:else}
		<UsageReport {patientId} {startDate} {endDate} onLoad={loadUsageReport} />
	{/if}
</div>

