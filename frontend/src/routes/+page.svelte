<script lang="ts">
	import { onMount } from 'svelte';
	import { dashboardService } from '$lib/services/dashboard.service';
	import { alertsService } from '$lib/services/alerts.service';
	import StatCard from '$lib/components/ui/StatCard.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	import type { DashboardOverview } from '$lib/services/dashboard.service';
	import type { Alert } from '$lib/services/alerts.service';
	
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
			[overview, recentAlerts] = await Promise.all([
				dashboardService.getOverview(),
				alertsService.getAlerts({ resolved: false, severity: 'critical' }),
			]);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar dados';
		} finally {
			loading = false;
		}
	}
	
	function getSeverityBadge(severity: string) {
		const variants = {
			critical: 'danger',
			high: 'warning',
			medium: 'info',
			low: 'success',
		} as const;
		return variants[severity as keyof typeof variants] || 'default';
	}
</script>

<div class="p-8">
	<div class="mb-8">
		<h1 class="text-3xl font-bold">Dashboard</h1>
		<p class="mt-2 text-muted-foreground">Visão geral da plataforma OrthoTrack</p>
	</div>
	
	{#if loading}
		<div class="flex items-center justify-center py-12">
			<div class="loading-spinner h-8 w-8"></div>
		</div>
	{:else if error}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4 text-red-800">
			{error}
		</div>
	{:else if overview}
		<!-- Statistics Cards -->
		<div class="mb-8 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-4">
			<StatCard
				title="Total de Pacientes"
				value={overview.total_patients}
				icon="👥"
			/>
			<StatCard
				title="Dispositivos Online"
				value={overview.online_devices}
				subtitle={`de ${overview.total_devices} total`}
				icon="📱"
			/>
			<StatCard
				title="Alertas Ativos"
				value={overview.active_alerts}
				subtitle={`${overview.critical_alerts} críticos`}
				icon="🚨"
			/>
			<StatCard
				title="Compliance Médio"
				value={`${overview.total_compliance_percent.toFixed(1)}%`}
				subtitle={`${overview.avg_daily_usage_hours.toFixed(1)}h/dia`}
				icon="📊"
			/>
		</div>
		
		<div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
			<!-- Recent Alerts -->
			<Card className="p-6">
				<h2 class="mb-4 text-xl font-semibold">Alertas Críticos Recentes</h2>
				{#if recentAlerts.length === 0}
					<p class="text-center text-sm text-muted-foreground py-8">
						Nenhum alerta crítico no momento
					</p>
				{:else}
					<div class="space-y-3">
						{#each recentAlerts.slice(0, 5) as alert}
							<div class="rounded-lg border p-4">
								<div class="flex items-start justify-between">
									<div class="flex-1">
										<div class="flex items-center gap-2 mb-1">
											<Badge variant={getSeverityBadge(alert.severity)}>
												{alert.severity}
											</Badge>
											<span class="text-sm font-medium">{alert.title}</span>
										</div>
										<p class="text-sm text-muted-foreground">{alert.message}</p>
										{#if alert.device_serial}
											<p class="mt-1 text-xs text-muted-foreground">
												Dispositivo: {alert.device_serial}
											</p>
										{/if}
									</div>
									<span class="text-xs text-muted-foreground">
										{new Date(alert.created_at).toLocaleString('pt-BR')}
									</span>
								</div>
							</div>
						{/each}
					</div>
					<div class="mt-4">
						<a href="/alerts" class="text-sm text-primary hover:underline">
							Ver todos os alertas →
						</a>
					</div>
				{/if}
			</Card>
			
			<!-- Recent Activity -->
			<Card className="p-6">
				<h2 class="mb-4 text-xl font-semibold">Atividade Recente</h2>
				{#if overview.recent_activity.length === 0}
					<p class="text-center text-sm text-muted-foreground py-8">
						Nenhuma atividade recente
					</p>
				{:else}
					<div class="space-y-3">
						{#each overview.recent_activity.slice(0, 5) as activity}
							<div class="flex items-start gap-3 rounded-lg border p-3">
								<div class="mt-0.5">
									{#if activity.type === 'device_connected'}
										<span class="text-green-600">✓</span>
									{:else if activity.type === 'alert_created'}
										<span class="text-red-600">⚠</span>
									{:else}
										<span class="text-blue-600">ℹ</span>
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

