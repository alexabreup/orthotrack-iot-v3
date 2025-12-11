<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import DeviceStatusBadge from './DeviceStatusBadge.svelte';
	import { Smartphone, Battery } from 'lucide-svelte';
	import { formatRelativeTime, formatBatteryLevel } from '$lib/utils/formatters';
	import { deviceStatuses } from '$lib/stores/device-statuses.store';
	import type { Brace } from '$lib/types/device';
	import type { DeviceStatus } from '$lib/types/websocket';

	export let device: Brace;

	// Get real-time device status from store, fallback to device data
	$: realtimeStatus = $deviceStatuses.get(device.device_id);
	$: currentStatus = realtimeStatus || {
		device_id: device.device_id,
		status: device.status as 'online' | 'offline' | 'maintenance',
		timestamp: device.last_seen ? new Date(device.last_seen).getTime() : Date.now(),
		battery_level: device.battery_level
	};
</script>

<Card class="p-4">
	<div class="flex items-start justify-between">
		<div class="flex-1">
			<div class="flex items-center gap-2 mb-2">
				<Smartphone class="h-5 w-5 text-muted-foreground" />
				<h3 class="text-lg font-semibold">{device.device_id}</h3>
				<DeviceStatusBadge deviceStatus={currentStatus} />
			</div>
			<div class="space-y-1 text-sm text-muted-foreground">
				{#if device.serial_number}
					<p>Serial: {device.serial_number}</p>
				{/if}
				{#if device.mac_address}
					<p>MAC: {device.mac_address}</p>
				{/if}
				{#if currentStatus.battery_level !== undefined}
					<div class="flex items-center gap-1">
						<Battery class="h-4 w-4" />
						<span>{formatBatteryLevel(currentStatus.battery_level)}</span>
					</div>
				{/if}
			</div>
		</div>
		<div class="flex flex-col gap-2">
			<Button variant="outline" size="sm" href="/devices/{device.id}">
				Ver detalhes
			</Button>
		</div>
	</div>
</Card>

