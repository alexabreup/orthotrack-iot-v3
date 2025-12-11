<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { devicesService } from '$lib/services/devices.service';
	import { LoadingSpinner, ErrorMessage } from '$lib/components/common';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import { formatDate } from '$lib/utils/formatters';
	import type { Brace } from '$lib/types/device';

	let device: Brace | null = null;
	let loading = true;
	let error: string | null = null;

	$: deviceId = parseInt($page.params.id);

	onMount(async () => {
		await loadDevice();
	});

	async function loadDevice() {
		loading = true;
		error = null;
		try {
			device = await devicesService.get(deviceId);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar dispositivo';
		} finally {
			loading = false;
		}
	}

	function getStatusColor(status: string) {
		const colors: Record<string, string> = {
			online: 'success',
			offline: 'secondary',
			maintenance: 'warning',
			error: 'destructive'
		};
		return colors[status] || 'default';
	}

	function getStatusLabel(status: string) {
		const labels: Record<string, string> = {
			online: 'Online',
			offline: 'Offline',
			maintenance: 'Manutenção',
			error: 'Erro'
		};
		return labels[status] || status;
	}
</script>

{#if loading}
	<div class="flex items-center justify-center py-12">
		<LoadingSpinner size="lg" />
	</div>
{:else if error}
	<ErrorMessage message={error} onRetry={loadDevice} />
{:else if device}
	<div class="space-y-6">
		<div class="flex items-center justify-between">
			<div>
				<h1 class="text-3xl font-bold">{device.device_id}</h1>
				<p class="mt-2 text-muted-foreground">Detalhes do dispositivo</p>
			</div>
			<div class="flex gap-2">
				<Button href="/devices/{device.id}/edit" variant="outline">Editar</Button>
				<Button href="/devices">Voltar</Button>
			</div>
		</div>

		<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
			<!-- Informações Básicas -->
			<Card>
				<CardHeader>
					<CardTitle>Informações Básicas</CardTitle>
				</CardHeader>
				<CardContent class="space-y-4">
					<div>
						<label class="text-sm text-muted-foreground">Device ID</label>
						<p class="font-medium">{device.device_id}</p>
					</div>
					<div>
						<label class="text-sm text-muted-foreground">UUID</label>
						<p class="font-mono text-sm">{device.uuid}</p>
					</div>
					<div>
						<label class="text-sm text-muted-foreground">Número de Série</label>
						<p class="font-medium">{device.serial_number}</p>
					</div>
					<div>
						<label class="text-sm text-muted-foreground">Endereço MAC</label>
						<p class="font-mono text-sm">{device.mac_address}</p>
					</div>
					{#if device.model}
						<div>
							<label class="text-sm text-muted-foreground">Modelo</label>
							<p class="font-medium">{device.model}</p>
						</div>
					{/if}
					<div>
						<label class="text-sm text-muted-foreground">Status</label>
						<div class="mt-1">
							<Badge variant={getStatusColor(device.status)}>
								{getStatusLabel(device.status)}
							</Badge>
						</div>
					</div>
				</CardContent>
			</Card>

			<!-- Status do Sistema -->
			<Card>
				<CardHeader>
					<CardTitle>Status do Sistema</CardTitle>
				</CardHeader>
				<CardContent class="space-y-4">
					{#if device.battery_level !== undefined}
						<div>
							<label class="text-sm text-muted-foreground">Nível de Bateria</label>
							<p class="font-medium">{device.battery_level}%</p>
						</div>
					{/if}
					{#if device.battery_voltage !== undefined}
						<div>
							<label class="text-sm text-muted-foreground">Voltagem da Bateria</label>
							<p class="font-medium">{device.battery_voltage}V</p>
						</div>
					{/if}
					{#if device.signal_strength !== undefined}
						<div>
							<label class="text-sm text-muted-foreground">Força do Sinal</label>
							<p class="font-medium">{device.signal_strength} dBm</p>
						</div>
					{/if}
					{#if device.firmware_version}
						<div>
							<label class="text-sm text-muted-foreground">Versão do Firmware</label>
							<p class="font-medium">{device.firmware_version}</p>
						</div>
					{/if}
					{#if device.hardware_version}
						<div>
							<label class="text-sm text-muted-foreground">Versão do Hardware</label>
							<p class="font-medium">{device.hardware_version}</p>
						</div>
					{/if}
					{#if device.last_heartbeat}
						<div>
							<label class="text-sm text-muted-foreground">Último Heartbeat</label>
							<p class="font-medium">{formatDate(device.last_heartbeat)}</p>
						</div>
					{/if}
					{#if device.last_seen}
						<div>
							<label class="text-sm text-muted-foreground">Última Conexão</label>
							<p class="font-medium">{formatDate(device.last_seen)}</p>
						</div>
					{/if}
				</CardContent>
			</Card>

			<!-- Uso e Histórico -->
			<Card>
				<CardHeader>
					<CardTitle>Uso e Histórico</CardTitle>
				</CardHeader>
				<CardContent class="space-y-4">
					{#if device.total_usage_hours !== undefined}
						<div>
							<label class="text-sm text-muted-foreground">Total de Horas de Uso</label>
							<p class="font-medium">{device.total_usage_hours}h</p>
						</div>
					{/if}
					{#if device.last_usage_start}
						<div>
							<label class="text-sm text-muted-foreground">Último Início de Uso</label>
							<p class="font-medium">{formatDate(device.last_usage_start)}</p>
						</div>
					{/if}
					{#if device.last_usage_end}
						<div>
							<label class="text-sm text-muted-foreground">Último Fim de Uso</label>
							<p class="font-medium">{formatDate(device.last_usage_end)}</p>
						</div>
					{/if}
					{#if device.patient_id}
						<div>
							<label class="text-sm text-muted-foreground">Paciente Associado</label>
							<p class="font-medium">
								<a href="/patients/{device.patient_id}" class="text-primary hover:underline">
									Ver Paciente #{device.patient_id}
								</a>
							</p>
						</div>
					{/if}
					<div>
						<label class="text-sm text-muted-foreground">Criado em</label>
						<p class="font-medium">{formatDate(device.created_at)}</p>
					</div>
					<div>
						<label class="text-sm text-muted-foreground">Atualizado em</label>
						<p class="font-medium">{formatDate(device.updated_at)}</p>
					</div>
				</CardContent>
			</Card>
		</div>
	</div>
{/if}
