<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import DeviceStatus from '$lib/components/dashboard/DeviceStatus.svelte';
	import { Smartphone, Battery } from 'lucide-svelte';
	import { formatRelativeTime } from '$lib/utils/formatters';
	import { DEVICE_STATUS_COLORS } from '$lib/utils/constants';
	import type { Brace } from '$lib/types/device';

	export let device: Brace;
</script>

<Card class="p-4">
	<div class="flex items-start justify-between">
		<div class="flex-1">
			<div class="flex items-center gap-2 mb-2">
				<Smartphone class="h-5 w-5 text-muted-foreground" />
				<h3 class="text-lg font-semibold">{device.device_id}</h3>
				<Badge variant={DEVICE_STATUS_COLORS[device.status] || 'default'}>
					{device.status}
				</Badge>
			</div>
			<div class="space-y-1 text-sm text-muted-foreground">
				{#if device.serial_number}
					<p>Serial: {device.serial_number}</p>
				{/if}
				{#if device.mac_address}
					<p>MAC: {device.mac_address}</p>
				{/if}
				{#if device.last_seen}
					<p>Última vez visto: {formatRelativeTime(device.last_seen)}</p>
				{/if}
			</div>
			<div class="mt-3">
				<DeviceStatus
					status={device.status}
					batteryLevel={device.battery_level}
					lastSeen={device.last_seen}
				/>
			</div>
		</div>
		<div class="flex flex-col gap-2">
			<Button variant="outline" size="sm" href="/devices/{device.id}">
				Ver detalhes
			</Button>
		</div>
	</div>
</Card>

