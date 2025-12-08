<script lang="ts">
	import { onMount } from 'svelte';
	import { dashboardService } from '$lib/services/dashboard.service';
	import { alertsService } from '$lib/services/alerts.service';
	import StatsCard from '$lib/components/dashboard/StatsCard.svelte';
	import AlertList from '$lib/components/dashboard/AlertList.svelte';
	import { LoadingSpinner } from '$lib/components/common';
	import Card from '$lib/components/ui/Card.svelte';
	import { Users, Smartphone, AlertCircle, TrendingUp } from 'lucide-svelte';
	import type { DashboardOverview } from '$lib/services/dashboard.service';
	import type { Alert } from '$lib/types/alert';
	
	let overview: DashboardOverview | null = null;
	let recentAlerts: Alert[] = [];
	let loading = true;
	let error = '';
	
	onMount(async () => {
		await loadData();
	});
	
	async function loadData() {
		loading = true;
		error = '';
		
		try {
			const [overviewData, alertsData] = await Promise.all([
				dashboardService.getOverview(),
				alertsService.list({ resolved: false, severity: 'critical', limit: 5 }),
			]);
			overview = overviewData;
			recentAlerts = alertsData.data || [];
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar dados';
		} finally {
			loading = false;
		}
	}
</script>

<div>
	<div class="mb-8">
		<h1 class="text-3xl font-bold">Dashboard</h1>
		<p class="mt-2 text-muted-foreground">Visão geral da plataforma OrthoTrack</p>
	</div>
	
	{#if loading}
		<div class="flex items-center justify-center py-12">
			<LoadingSpinner size="lg" />
		</div>
	{:else if error}
		<div class="rounded-lg border border-destructive bg-destructive/10 p-4 text-destructive">
			{error}
		</div>
	{:else if overview}
		<!-- Statistics Cards -->
		<div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
			<StatsCard
				title="Total de Pacientes"
				value={overview.total_patients || 0}
				icon={Users}
			/>
			<StatsCard
				title="Dispositivos Online"
				value={overview.online_devices || 0}
				description={`de ${overview.total_devices || 0} total`}
				icon={Smartphone}
			/>
			<StatsCard
				title="Alertas Ativos"
				value={overview.active_alerts || 0}
				description={`${overview.critical_alerts || 0} críticos`}
				icon={AlertCircle}
			/>
			<StatsCard
				title="Compliance Médio"
				value={`${(overview.total_compliance_percent || 0).toFixed(1)}%`}
				description={`${(overview.avg_daily_usage_hours || 0).toFixed(1)}h/dia`}
				icon={TrendingUp}
			/>
		</div>
		
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Recent Alerts -->
			<AlertList alerts={recentAlerts} maxItems={5} />
			
			<!-- Recent Activity -->
			<Card class="p-6">
				<h2 class="mb-4 text-xl font-semibold">Atividade Recente</h2>
				{#if !overview.recent_activity || overview.recent_activity.length === 0}
					<p class="text-center text-sm text-muted-foreground py-8">
						Nenhuma atividade recente
					</p>
				{:else}
					<div class="space-y-3">
						{#each overview.recent_activity.slice(0, 5) as activity}
							<div class="flex items-start gap-3 rounded-lg border border-border p-3">
								<div class="mt-0.5">
									{#if activity.type === 'device_connected'}
										<span class="text-success">✓</span>
									{:else if activity.type === 'alert_created'}
										<span class="text-destructive">⚠</span>
									{:else}
										<span class="text-info">ℹ</span>
									{/if}
								</div>
								<div class="flex-1">
									<p class="text-sm">{activity.description}</p>
									<p class="mt-1 text-xs text-muted-foreground">
										{new Date(activity.timestamp).toLocaleString('pt-BR')}
									</p>
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</Card>
		</div>
	{/if}
</div>

