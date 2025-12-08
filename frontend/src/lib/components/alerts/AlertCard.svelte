<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import AlertBadge from './AlertBadge.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import { formatRelativeTime, formatDateTime } from '$lib/utils/formatters';
	import { ALERT_ICONS, ALERT_SEVERITY_COLORS } from '$lib/utils/constants';
	import type { Alert } from '$lib/types/alert';

	export let alert: Alert;
	export let onResolve: ((id: number) => void) | null = null;
</script>

<Card
	class="p-4 transition-colors hover:bg-accent/50 {ALERT_SEVERITY_COLORS[alert.severity]}"
>
	<div class="flex items-start justify-between gap-4">
		<div class="flex items-start gap-3 flex-1">
			<div class="mt-0.5 text-2xl">{ALERT_ICONS[alert.type]}</div>
			<div class="flex-1">
				<div class="flex items-center gap-2 mb-1">
					<AlertBadge severity={alert.severity} />
					<h3 class="font-semibold">{alert.title}</h3>
				</div>
				<p class="text-sm text-muted-foreground mb-2">{alert.message}</p>
				<div class="flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
					<span>{formatRelativeTime(alert.created_at)}</span>
					{#if alert.value !== undefined && alert.threshold !== undefined}
						<span>
							Valor: {alert.value} / Threshold: {alert.threshold}
						</span>
					{/if}
				</div>
			</div>
		</div>
		{#if !alert.resolved && onResolve}
			<Button variant="outline" size="sm" on:click={() => onResolve(alert.id)}>
				Resolver
			</Button>
		{:else if alert.resolved}
			<span class="text-xs text-muted-foreground">
				Resolvido {alert.resolved_at ? formatRelativeTime(alert.resolved_at) : ''}
			</span>
		{/if}
	</div>
</Card>

