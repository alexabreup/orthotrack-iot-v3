<script lang="ts">
	import { onMount } from 'svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import { LoadingSpinner, ErrorMessage } from '$lib/components/common';
	import ExportButton from './ExportButton.svelte';
	import { formatDate, formatPercentage } from '$lib/utils/formatters';
	import type { ComplianceReport } from '$lib/types/api';

	export let patientId: number | undefined = undefined;
	export let startDate: string;
	export let endDate: string;
	export let onLoad: (() => Promise<ComplianceReport>) | null = null;

	let report: ComplianceReport | null = null;
	let loading = true;
	let error: string | null = null;

	onMount(async () => {
		if (onLoad) {
			await loadReport();
		}
	});

	async function loadReport() {
		if (!onLoad) return;
		loading = true;
		error = null;
		try {
			report = await onLoad();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar relatório';
		} finally {
			loading = false;
		}
	}

	function exportToCSV() {
		if (!report) return;
		// TODO: Implementar exportação CSV
		console.log('Exportando para CSV:', report);
	}
</script>

<Card>
	<CardHeader class="flex flex-row items-center justify-between">
		<CardTitle>Relatório de Compliance</CardTitle>
		{#if report}
			<ExportButton onExport={exportToCSV} format="csv" />
		{/if}
	</CardHeader>
	<CardContent>
		{#if loading}
			<div class="flex items-center justify-center py-12">
				<LoadingSpinner size="lg" />
			</div>
		{:else if error}
			<ErrorMessage message={error} onRetry={loadReport} />
		{:else if report}
			<div class="space-y-6">
				<div class="grid grid-cols-1 gap-4 md:grid-cols-3">
					<div>
						<p class="text-sm text-muted-foreground">Compliance Geral</p>
						<p class="text-2xl font-bold">{formatPercentage(report.overall_compliance)}</p>
					</div>
					<div>
						<p class="text-sm text-muted-foreground">Média Diária</p>
						<p class="text-2xl font-bold">
							{formatPercentage(report.statistics?.avg_daily_compliance)}
						</p>
					</div>
					<div>
						<p class="text-sm text-muted-foreground">Dias Compliantes</p>
						<p class="text-2xl font-bold">
							{report.statistics?.compliant_days || 0} / {report.statistics?.total_days || 0}
						</p>
					</div>
				</div>

				<div>
					<h3 class="mb-4 text-lg font-semibold">Compliance Diária</h3>
					<div class="space-y-2">
						{#each (report.daily_compliance || []) as daily}
							<div class="flex items-center justify-between rounded-lg border border-border p-3">
								<div>
									<p class="font-medium">{formatDate(daily.date)}</p>
									<p class="text-sm text-muted-foreground">
										{daily.actual_minutes}min / {daily.target_minutes}min
									</p>
								</div>
								<div class="text-right">
									<p class="font-semibold">{formatPercentage(daily.compliance_percent)}</p>
									<div class="mt-1 h-2 w-24 rounded-full bg-secondary">
										<div
											class="h-2 rounded-full bg-success transition-all"
											style="width: {daily.compliance_percent}%"
										></div>
									</div>
								</div>
							</div>
						{/each}
					</div>
				</div>
			</div>
		{/if}
	</CardContent>
</Card>


