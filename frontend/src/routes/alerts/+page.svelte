<script lang="ts">
	import { onMount } from 'svelte';
	import { alertsStore } from '$lib/stores/alerts.store';
	import Button from '$lib/components/ui/Button.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	
	onMount(() => {
		alertsStore.fetchAlerts();
		alertsStore.fetchStatistics();
	});
	
	function getSeverityBadge(severity: string) {
		const variants = {
			critical: 'danger',
			high: 'warning',
			medium: 'info',
			low: 'success',
		} as const;
		return variants[severity as keyof typeof variants] || 'default';
	}
	
	async function handleResolve(alertId: number) {
		try {
			await alertsStore.resolveAlert(alertId);
		} catch (error) {
			console.error('Erro ao resolver alerta:', error);
		}
	}
</script>

<div class="p-8">
	<div class="mb-8">
		<h1 class="text-3xl font-bold">Alertas</h1>
		<p class="mt-2 text-muted-foreground">Gerenciamento de alertas do sistema</p>
	</div>
	
	{#if $alertsStore.statistics}
		<div class="mb-6 grid grid-cols-1 gap-4 md:grid-cols-4">
			<Card className="p-4">
				<div class="text-sm text-muted-foreground">Total</div>
				<div class="mt-1 text-2xl font-bold">{$alertsStore.statistics.total}</div>
			</Card>
			<Card className="p-4">
				<div class="text-sm text-muted-foreground">Críticos</div>
				<div class="mt-1 text-2xl font-bold text-red-600">
					{$alertsStore.statistics.by_severity.critical}
				</div>
			</Card>
			<Card className="p-4">
				<div class="text-sm text-muted-foreground">Altos</div>
				<div class="mt-1 text-2xl font-bold text-orange-600">
					{$alertsStore.statistics.by_severity.high}
				</div>
			</Card>
			<Card className="p-4">
				<div class="text-sm text-muted-foreground">Não Resolvidos</div>
				<div class="mt-1 text-2xl font-bold">{$alertsStore.statistics.unresolved}</div>
			</Card>
		</div>
	{/if}
	
	{#if $alertsStore.loading}
		<div class="flex items-center justify-center py-12">
			<div class="loading-spinner h-8 w-8"></div>
		</div>
	{:else if $alertsStore.error}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4 text-red-800">
			{$alertsStore.error}
		</div>
	{:else if $alertsStore.alerts.length === 0}
		<Card className="p-12 text-center">
			<p class="text-muted-foreground">Nenhum alerta encontrado</p>
		</Card>
	{:else}
		<Card className="overflow-hidden">
			<div class="overflow-x-auto">
				<table class="w-full">
					<thead class="border-b bg-muted/50">
						<tr>
							<th class="px-6 py-3 text-left text-sm font-medium">Severidade</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Título</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Dispositivo</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Data</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Status</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Ações</th>
						</tr>
					</thead>
					<tbody>
						{#each $alertsStore.alerts as alert}
							<tr class="border-b hover:bg-muted/50">
								<td class="px-6 py-4">
									<Badge variant={getSeverityBadge(alert.severity)}>
										{alert.severity}
									</Badge>
								</td>
								<td class="px-6 py-4">
									<div class="font-medium">{alert.title}</div>
									<div class="text-sm text-muted-foreground">{alert.message}</div>
								</td>
								<td class="px-6 py-4 text-sm">
									{alert.device_serial || 'N/A'}
								</td>
								<td class="px-6 py-4 text-sm">
									{new Date(alert.created_at).toLocaleString('pt-BR')}
								</td>
								<td class="px-6 py-4">
									{#if alert.resolved}
										<Badge variant="success">Resolvido</Badge>
									{:else}
										<Badge variant="warning">Pendente</Badge>
									{/if}
								</td>
								<td class="px-6 py-4">
									{#if !alert.resolved}
										<Button variant="ghost" size="sm" on:click={() => handleResolve(alert.id)}>
											Resolver
										</Button>
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</Card>
	{/if}
</div>

