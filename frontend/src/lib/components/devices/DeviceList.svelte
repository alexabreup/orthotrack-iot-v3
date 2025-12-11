<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import DeviceCard from './DeviceCard.svelte';
	import { LoadingSpinner, ErrorMessage, EmptyState, Pagination, SearchBar } from '$lib/components/common';
	import Button from '$lib/components/ui/Button.svelte';
	import { devicesService } from '$lib/services/devices.service';
	import { getWebSocketClient } from '$lib/services/websocket.service';
	import { deviceStatuses, initializeDeviceStatusesStore } from '$lib/stores/device-statuses.store';
	import type { Brace, DevicesListParams } from '$lib/types/device';

	export let filters: DevicesListParams = {};

	let devices: Brace[] = [];
	let loading = true;
	let error: string | null = null;
	let currentPage = 1;
	let totalPages = 1;
	let searchQuery = '';

	onMount(() => {
		loadDevices();
		initializeRealTimeUpdates();
	});

	onDestroy(() => {
		cleanupRealTimeUpdates();
	});

	function initializeRealTimeUpdates() {
		// Initialize device statuses store
		initializeDeviceStatusesStore();
		
		// Subscribe to device status channels for all devices
		const wsClient = getWebSocketClient();
		devices.forEach(device => {
			wsClient.subscribe(`device:${device.device_id}`);
		});
	}

	function cleanupRealTimeUpdates() {
		// Unsubscribe from device status channels
		const wsClient = getWebSocketClient();
		devices.forEach(device => {
			wsClient.unsubscribe(`device:${device.device_id}`);
		});
	}

	async function loadDevices() {
		loading = true;
		error = null;
		try {
			const params = {
				...filters,
				page: currentPage,
				search: searchQuery || undefined,
			};
			const response = await devicesService.list(params);
			
			// Cleanup previous subscriptions
			if (devices.length > 0) {
				cleanupRealTimeUpdates();
			}
			
			devices = response.data;
			totalPages = response.total_pages;
			
			// Setup new subscriptions for loaded devices
			if (devices.length > 0) {
				initializeRealTimeUpdates();
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar dispositivos';
		} finally {
			loading = false;
		}
	}

	function handleSearch(query: string) {
		searchQuery = query;
		currentPage = 1;
		loadDevices();
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadDevices();
	}
</script>

<div class="space-y-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">Dispositivos</h1>
			<p class="mt-2 text-muted-foreground">Gerencie os dispositivos do sistema</p>
		</div>
		<Button href="/devices/new">Novo Dispositivo</Button>
	</div>

	<div class="flex gap-4">
		<div class="flex-1">
			<SearchBar placeholder="Buscar dispositivos..." onSearch={handleSearch} />
		</div>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<LoadingSpinner size="lg" />
		</div>
	{:else if error}
		<ErrorMessage message={error} onRetry={loadDevices} />
	{:else if devices.length === 0}
		<EmptyState
			title="Nenhum dispositivo encontrado"
			description="Comece adicionando um novo dispositivo ao sistema"
			actionLabel="Novo Dispositivo"
			onAction={() => (window.location.href = '/devices/new')}
		/>
	{:else}
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
			{#each devices as device}
				<DeviceCard {device} />
			{/each}
		</div>

		{#if totalPages > 1}
			<div class="mt-6">
				<Pagination
					currentPage={currentPage}
					totalPages={totalPages}
					onPageChange={handlePageChange}
				/>
			</div>
		{/if}
	{/if}
</div>

