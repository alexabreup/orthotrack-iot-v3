<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import { AlertCircle } from 'lucide-svelte';
	import { formatRelativeTime } from '$lib/utils/formatters';
	import { ALERT_ICONS, ALERT_SEVERITY_COLORS } from '$lib/utils/constants';
	import type { Alert } from '$lib/types/alert';

	export let alerts: Alert[] = [];
	export let maxItems: number = 5;
	export let showViewAll: boolean = true;

	const displayedAlerts = alerts.slice(0, maxItems);
</script>

<Card>
	<CardHeader class="flex flex-row items-center justify-between">
		<CardTitle>Alertas Recentes</CardTitle>
		{#if showViewAll}
			<Button variant="ghost" size="sm" href="/alerts">Ver todos</Button>
		{/if}
	</CardHeader>
	<CardContent>
		{#if displayedAlerts.length === 0}
			<div class="py-8 text-center text-sm text-muted-foreground">
				Nenhum alerta recente
			</div>
		{:else}
			<div class="space-y-2">
				{#each displayedAlerts as alert}
					<div
						class="flex items-start gap-3 rounded-lg border border-border p-3 {ALERT_SEVERITY_COLORS[alert.severity]}"
					>
						<div class="mt-0.5 text-lg">{ALERT_ICONS[alert.type]}</div>
						<div class="flex-1">
							<div class="flex items-center gap-2">
								<h4 class="text-sm font-medium">{alert.title}</h4>
								<span class="text-xs text-muted-foreground">
									{formatRelativeTime(alert.created_at)}
								</span>
							</div>
							<p class="mt-1 text-xs text-muted-foreground">{alert.message}</p>
						</div>
					</div>
				{/each}
			</div>
		{/if}
	</CardContent>
</Card>

