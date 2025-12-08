<script lang="ts">
	import Badge from '$lib/components/ui/Badge.svelte';
	import { Battery } from 'lucide-svelte';
	import { formatRelativeTime, formatBatteryLevel } from '$lib/utils/formatters';
	import type { DeviceStatus } from '$lib/types/device';

	export let status: DeviceStatus;
	export let batteryLevel: number | undefined;
	export let lastSeen: string | undefined;
</script>

<div class="flex items-center gap-2">
	<Badge
		variant={status === 'online' ? 'success' : status === 'offline' ? 'default' : 'warning'}
	>
		{status}
	</Badge>
	{#if batteryLevel !== undefined}
		<div class="flex items-center gap-1">
			<Battery class="h-4 w-4 text-muted-foreground" />
			<span class="text-sm">{formatBatteryLevel(batteryLevel)}</span>
		</div>
	{/if}
	{#if lastSeen}
		<span class="text-xs text-muted-foreground">
			Última sincronização: {formatRelativeTime(lastSeen)}
		</span>
	{/if}
</div>

