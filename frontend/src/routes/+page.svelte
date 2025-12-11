<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { dashboardService } from '$lib/services/dashboard.service';
	import { alertsService } from '$lib/services/alerts.service';
	import StatsCard from '$lib/components/dashboard/StatsCard.svelte';
	import AlertList from '$lib/components/dashboard/AlertList.svelte';
	import { LoadingSpinner } from '$lib/components/common';
	import Card from '$lib/components/ui/Card.svelte';
	import { Users, Smartphone, AlertCircle, TrendingUp } from 'lucide-svelte';
	import { getWebSocketClient } from '$lib/services/websocket.service';
	import { dashboardStats, initializeDashboardStatsStore } from '$lib/stores/dashboard-stats.store';
	import { activeAlerts, initializeActiveAlertsStore } from '$lib/stores/active-alerts.store';
	import type { DashboardOverview } from '$lib/services/dashboard.service';
	import type { Alert } from '$lib/types/alert';
	import type { DashboardStatsEvent } from '$lib/types/websocket';
	
	let overview: DashboardOverview | null = null;
	let recentAlerts: Alert[] = [];
	let loading = true;
	let error = '';
	
	onMount(async () => {
		await loadData();
		initializeRealTimeUpdates();
	});

	onDestroy(() => {
		cleanupRealTimeUpdates();
	});

	function initializeRealTimeUpdates() {
		// Initialize stores
		initializeDashboardStatsStore();
		initializeActiveAlertsStore();
		
		// Subscribe to dashboard channel
		const wsClient = getWebSocketClient();
		wsClient.subscribe('dashboard');

		// Handle dashboard stats events
		wsClient.on('dashboard_stats', (event: DashboardStatsEvent) => {
			// Stats will be automatically updated via the store
			console.log('Dashboard stats updated:', event.data);
		});
	}

	function cleanupRealTimeUpdates() {
		const wsClient = getWebSocketClient();
		wsClient.unsubscribe('dashboard');
	}
	
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
		<!-- Statistics Cards - Real-time Updates -->
		<div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
			<StatsCard
				title="Pacientes Ativos"
				value={$dashboardStats.active_patients || overview.total_patients || 0}
				icon={Users}
			/>
			<StatsCard
				title="Dispositivos Online"
				value={$dashboardStats.online_devices || overview.online_devices || 0}
				description={`de ${overview.total_devices || 0} total`}
				icon={Smartphone}
			/>
			<StatsCard
				title="Alertas Ativos"
				value={$dashboardStats.active_alerts || overview.active_alerts || 0}
				description={`${$activeAlerts.filter(a => a.severity === 'critical').length} críticos`}
				icon={AlertCircle}
			/>
			<StatsCard
				title="Compliance Médio"
				value={`${($dashboardStats.average_compliance || overview.total_compliance_percent || 0).toFixed(1)}%`}
				description={`${(overview.avg_daily_usage_hours || 0).toFixed(1)}h/dia`}
				icon={TrendingUp}
			/>
		</div>
		
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Recent Alerts - Real-time Updates -->
			<AlertList alerts={$activeAlerts.slice(0, 5)} maxItems={5} />
			
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

