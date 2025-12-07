<script lang="ts">
	import { onMount } from 'svelte';
	import { devicesStore } from '$lib/stores/devices.store';
	import Button from '$lib/components/ui/Button.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	
	onMount(() => {
		devicesStore.fetchDevices();
	});
	
	function getStatusBadge(status: string) {
		const variants = {
			online: 'success',
			offline: 'danger',
			maintenance: 'warning',
		} as const;
		return variants[status as keyof typeof variants] || 'default';
	}
	
	function formatDate(dateString?: string) {
		if (!dateString) return 'Nunca';
		return new Date(dateString).toLocaleString('pt-BR');
	}
</script>

<div class="p-8">
	<div class="mb-8 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">Dispositivos</h1>
			<p class="mt-2 text-muted-foreground">Gerenciamento de dispositivos (braces)</p>
		</div>
		<Button>+ Novo Dispositivo</Button>
	</div>
	
	{#if $devicesStore.loading}
		<div class="flex items-center justify-center py-12">
			<div class="loading-spinner h-8 w-8"></div>
		</div>
	{:else if $devicesStore.error}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4 text-red-800">
			{$devicesStore.error}
		</div>
	{:else if $devicesStore.devices.length === 0}
		<Card className="p-12 text-center">
			<p class="text-muted-foreground">Nenhum dispositivo cadastrado</p>
			<Button className="mt-4">Adicionar Primeiro Dispositivo</Button>
		</Card>
	{:else}
		<div class="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
			{#each $devicesStore.devices as device}
				<Card className="p-6">
					<div class="mb-4 flex items-start justify-between">
						<div>
							<h3 class="text-lg font-semibold">{device.serial_number}</h3>
							{#if device.patient_name}
								<p class="text-sm text-muted-foreground">{device.patient_name}</p>
							{/if}
						</div>
						<Badge variant={getStatusBadge(device.status)}>
							{device.status}
						</Badge>
					</div>
					
					<div class="space-y-2 text-sm">
						{#if device.battery_level !== undefined}
							<div class="flex justify-between">
								<span class="text-muted-foreground">Bateria:</span>
								<span>{device.battery_level}%</span>
							</div>
						{/if}
						{#if device.signal_strength !== undefined}
							<div class="flex justify-between">
								<span class="text-muted-foreground">Sinal:</span>
								<span>{device.signal_strength}%</span>
							</div>
						{/if}
						<div class="flex justify-between">
							<span class="text-muted-foreground">Última conexão:</span>
							<span>{formatDate(device.last_seen)}</span>
						</div>
						{#if device.firmware_version}
							<div class="flex justify-between">
								<span class="text-muted-foreground">Firmware:</span>
								<span>{device.firmware_version}</span>
							</div>
						{/if}
					</div>
					
					<div class="mt-4 flex gap-2">
						<Button variant="ghost" size="sm" className="flex-1">Detalhes</Button>
						<Button variant="ghost" size="sm" className="flex-1">Comandos</Button>
					</div>
				</Card>
			{/each}
		</div>
	{/if}
</div>

