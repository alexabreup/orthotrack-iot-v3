<script lang="ts">
	import { onMount } from 'svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import { LoadingSpinner, ErrorMessage } from '$lib/components/common';
	import ExportButton from './ExportButton.svelte';
	import { formatDate, formatDuration, formatPercentage } from '$lib/utils/formatters';
	import type { UsageReport } from '$lib/types/api';

	export let patientId: number | undefined = undefined;
	export let braceId: number | undefined = undefined;
	export let startDate: string;
	export let endDate: string;
	export let onLoad: (() => Promise<UsageReport>) | null = null;

	let report: UsageReport | null = null;
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
		<CardTitle>Relatório de Uso</CardTitle>
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
						<p class="text-sm text-muted-foreground">Total de Sessões</p>
						<p class="text-2xl font-bold">{report.statistics.total_sessions}</p>
					</div>
					<div>
						<p class="text-sm text-muted-foreground">Total de Horas</p>
						<p class="text-2xl font-bold">{report.statistics.total_hours.toFixed(1)}h</p>
					</div>
					<div>
						<p class="text-sm text-muted-foreground">Duração Média</p>
						<p class="text-2xl font-bold">
							{formatDuration(report.statistics.avg_session_duration)}
						</p>
					</div>
				</div>

				<div>
					<h3 class="mb-4 text-lg font-semibold">Sessões de Uso</h3>
					<div class="space-y-2">
						{#each report.sessions as session}
							<div class="flex items-center justify-between rounded-lg border border-border p-3">
								<div>
									<p class="font-medium">{formatDate(session.start_time)}</p>
									{#if session.end_time}
										<p class="text-sm text-muted-foreground">
											{formatDuration(session.duration || 0)}
										</p>
									{:else}
										<p class="text-sm text-muted-foreground">Em andamento</p>
									{/if}
								</div>
								<div class="text-right">
									<p class="text-sm text-muted-foreground">Compliance</p>
									<p class="font-semibold">{formatPercentage(session.compliance_score)}</p>
								</div>
							</div>
						{/each}
					</div>
				</div>
			</div>
		{/if}
	</CardContent>
</Card>


