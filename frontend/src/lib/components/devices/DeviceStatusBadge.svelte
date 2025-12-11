<!--
  DeviceStatusBadge Component
  Real-time device status badge with color coding and timestamp
  Requirements: 1.3, 1.4, 1.5
-->
<script lang="ts">
	import Badge from '$lib/components/ui/Badge.svelte';
	import { formatRelativeTime } from '$lib/utils/formatters';
	import type { DeviceStatus } from '$lib/types/websocket';

	export let deviceStatus: DeviceStatus;
	export let showTimestamp = true;
	export let size: 'sm' | 'md' | 'lg' = 'md';

	// Map device status to badge variants and text
	$: statusConfig = getStatusConfig(deviceStatus.status);
	
	function getStatusConfig(status: 'online' | 'offline' | 'maintenance') {
		switch (status) {
			case 'online':
				return {
					variant: 'success' as const,
					text: 'Online',
					color: 'text-green-600'
				};
			case 'offline':
				return {
					variant: 'danger' as const,
					text: 'Offline',
					color: 'text-red-600'
				};
			case 'maintenance':
				return {
					variant: 'warning' as const,
					text: 'Manutenção',
					color: 'text-yellow-600'
				};
			default:
				return {
					variant: 'default' as const,
					text: 'Desconhecido',
					color: 'text-gray-600'
				};
		}
	}

	$: sizeClasses = {
		sm: 'text-xs px-2 py-0.5',
		md: 'text-sm px-2.5 py-0.5',
		lg: 'text-base px-3 py-1'
	};
</script>

<div class="flex items-center gap-2">
	<Badge 
		variant={statusConfig.variant}
		className={sizeClasses[size]}
	>
		<span class="flex items-center gap-1">
			<!-- Status indicator dot -->
			<span 
				class="w-2 h-2 rounded-full {statusConfig.color === 'text-green-600' ? 'bg-green-500' : 
					statusConfig.color === 'text-red-600' ? 'bg-red-500' : 
					statusConfig.color === 'text-yellow-600' ? 'bg-yellow-500' : 'bg-gray-500'}"
			></span>
			{statusConfig.text}
		</span>
	</Badge>
	
	{#if showTimestamp && deviceStatus.timestamp}
		<span class="text-xs text-muted-foreground">
			{formatRelativeTime(new Date(deviceStatus.timestamp).toISOString())}
		</span>
	{/if}
</div>