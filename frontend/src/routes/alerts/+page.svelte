<script lang="ts">
	import { onMount } from 'svelte';
	import { alertsService } from '$lib/services/alerts.service';
	import AlertCard from '$lib/components/alerts/AlertCard.svelte';
	import AlertModal from '$lib/components/alerts/AlertModal.svelte';
	import { LoadingSpinner, ErrorMessage, Pagination, SearchBar } from '$lib/components/common';
	import Card from '$lib/components/ui/Card.svelte';
	import StatsCard from '$lib/components/dashboard/StatsCard.svelte';
	import { AlertCircle, TrendingUp, CheckCircle2 } from 'lucide-svelte';
	import type { Alert, AlertStatistics } from '$lib/types/alert';

	let alerts: Alert[] = [];
	let statistics: AlertStatistics | null = null;
	let loading = true;
	let error: string | null = null;
	let currentPage = 1;
	let totalPages = 1;
	let searchQuery = '';
	let selectedAlert: Alert | null = null;
	let modalOpen = false;
	let severityFilter: string | undefined = undefined;
	let resolvedFilter: boolean | undefined = undefined;

	onMount(() => {
		loadData();
	});

	async function loadData() {
		loading = true;
		error = null;
		try {
			const [alertsResponse, stats] = await Promise.all([
				alertsService.list({
					page: currentPage,
					severity: severityFilter as any,
					resolved: resolvedFilter,
				}),
				alertsService.getStatistics('24h'),
			]);
			alerts = alertsResponse.data;
			totalPages = alertsResponse.total_pages;
			statistics = stats;
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar alertas';
		} finally {
			loading = false;
		}
	}

	async function handleResolve(id: number, notes: string = '') {
		try {
			await alertsService.resolve(id, notes);
			await loadData();
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao resolver alerta';
		}
	}

	function openModal(alert: Alert) {
		selectedAlert = alert;
		modalOpen = true;
	}

	function closeModal() {
		modalOpen = false;
		selectedAlert = null;
	}
</script>

<div class="space-y-6">
	<div>
		<h1 class="text-3xl font-bold">Alertas</h1>
		<p class="mt-2 text-muted-foreground">Gerenciamento de alertas do sistema</p>
	</div>

	{#if statistics}
		<div class="grid grid-cols-1 gap-4 md:grid-cols-4">
			<StatsCard title="Total" value={statistics.total} icon={AlertCircle} />
			<StatsCard
				title="Críticos"
				value={statistics.by_severity.critical}
				icon={AlertCircle}
			/>
			<StatsCard title="Altos" value={statistics.by_severity.high} icon={TrendingUp} />
			<StatsCard
				title="Não Resolvidos"
				value={statistics.by_severity.critical + statistics.by_severity.high}
				icon={CheckCircle2}
			/>
		</div>
	{/if}

	<div class="flex gap-4">
		<div class="flex-1">
			<SearchBar placeholder="Buscar alertas..." onSearch={(q) => { searchQuery = q; loadData(); }} />
		</div>
		<select
			bind:value={severityFilter}
			on:change={loadData}
			class="rounded-md border border-input bg-background px-3 py-2 text-sm"
		>
			<option value={undefined}>Todas as severidades</option>
			<option value="critical">Crítico</option>
			<option value="high">Alto</option>
			<option value="medium">Médio</option>
			<option value="low">Baixo</option>
		</select>
		<select
			bind:value={resolvedFilter}
			on:change={loadData}
			class="rounded-md border border-input bg-background px-3 py-2 text-sm"
		>
			<option value={undefined}>Todos</option>
			<option value={false}>Não Resolvidos</option>
			<option value={true}>Resolvidos</option>
		</select>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<LoadingSpinner size="lg" />
		</div>
	{:else if error}
		<ErrorMessage message={error} onRetry={loadData} />
	{:else if alerts.length === 0}
		<Card class="p-12 text-center">
			<p class="text-muted-foreground">Nenhum alerta encontrado</p>
		</Card>
	{:else}
		<div class="space-y-4">
			{#each alerts as alert}
				<div role="button" tabindex="0" on:click={() => openModal(alert)} on:keydown={(e) => e.key === 'Enter' && openModal(alert)}>
					<AlertCard
						{alert}
						onResolve={async (id) => {
							await handleResolve(id);
						}}
					/>
				</div>
			{/each}
		</div>

		{#if totalPages > 1}
			<div class="mt-6">
				<Pagination
					currentPage={currentPage}
					totalPages={totalPages}
					onPageChange={(page) => {
						currentPage = page;
						loadData();
					}}
				/>
			</div>
		{/if}
	{/if}

	{#if selectedAlert}
		<AlertModal
			alert={selectedAlert}
			open={modalOpen}
			onClose={closeModal}
			onResolve={async (id, notes) => {
				await handleResolve(id, notes);
				closeModal();
			}}
		/>
	{/if}
</div>

