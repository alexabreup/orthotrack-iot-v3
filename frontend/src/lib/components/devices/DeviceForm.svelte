<script lang="ts">
	import { onMount } from 'svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import Input from '$lib/components/ui/Input.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import { devicesService } from '$lib/services/devices.service';
	import { patientsService } from '$lib/services/patients.service';
	import { validateMacAddress, validateRequired } from '$lib/utils/validators';
	import { goto } from '$app/navigation';
	import type { Brace, CreateBraceData, DeviceStatus } from '$lib/types/device';
	import type { Patient } from '$lib/types/patient';

	export let device: Brace | null = null;
	export let onSuccess: ((device: Brace) => void) | null = null;

	let loading = false;
	let error: string | null = null;
	let patients: Patient[] = [];
	let loadingPatients = false;

	onMount(async () => {
		await loadPatients();
	});

	// Form data
	let formData: CreateBraceData = {
		device_id: device?.device_id || '',
		serial_number: device?.serial_number || '',
		mac_address: device?.mac_address || '',
		model: device?.model || '',
		version: device?.version || '',
		patient_id: device?.patient_id,
		status: device?.status || 'offline',
		firmware_version: device?.firmware_version || '',
		hardware_version: device?.hardware_version || '',
	};

	// Validation errors
	let errors: Record<string, string> = {};

	async function loadPatients() {
		loadingPatients = true;
		try {
			const response = await patientsService.list({ limit: 100 });
			patients = response.data;
		} catch (err) {
			console.error('Erro ao carregar pacientes:', err);
		} finally {
			loadingPatients = false;
		}
	}

	function validateForm(): boolean {
		errors = {};

		if (!validateRequired(formData.device_id)) {
			errors.device_id = 'Device ID é obrigatório';
		}
		if (!validateRequired(formData.serial_number)) {
			errors.serial_number = 'Serial Number é obrigatório';
		}
		if (!validateRequired(formData.mac_address)) {
			errors.mac_address = 'MAC Address é obrigatório';
		} else if (!validateMacAddress(formData.mac_address)) {
			errors.mac_address = 'MAC Address inválido (formato: XX:XX:XX:XX:XX:XX)';
		}

		return Object.keys(errors).length === 0;
	}

	async function handleSubmit() {
		if (!validateForm()) {
			error = 'Por favor, corrija os erros no formulário';
			return;
		}

		loading = true;
		error = null;

		try {
			let result: Brace;
			if (device) {
				result = await devicesService.update(device.id, formData);
			} else {
				result = await devicesService.create(formData);
			}

			if (onSuccess) {
				onSuccess(result);
			} else {
				goto(`/devices/${result.id}`);
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao salvar dispositivo';
		} finally {
			loading = false;
		}
	}
</script>

<Card>
	<CardHeader>
		<CardTitle>{device ? 'Editar Dispositivo' : 'Novo Dispositivo'}</CardTitle>
	</CardHeader>
	<CardContent>
		{#if loadingPatients}
			<div class="flex items-center justify-center py-8">
				<p class="text-sm text-muted-foreground">Carregando pacientes...</p>
			</div>
		{:else}
			<form on:submit|preventDefault={handleSubmit} class="space-y-6">
					{#if error}
						<div class="rounded-lg border border-destructive bg-destructive/10 p-4 text-destructive">
							{error}
						</div>
					{/if}

					<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
						<div>
							<label for="device_id" class="mb-2 block text-sm font-medium">
								Device ID <span class="text-destructive">*</span>
							</label>
							<Input
								id="device_id"
								type="text"
								bind:value={formData.device_id}
								required
								class={errors.device_id ? 'border-destructive' : ''}
							/>
							{#if errors.device_id}
								<p class="mt-1 text-sm text-destructive">{errors.device_id}</p>
							{/if}
						</div>

						<div>
							<label for="serial_number" class="mb-2 block text-sm font-medium">
								Serial Number <span class="text-destructive">*</span>
							</label>
							<Input
								id="serial_number"
								type="text"
								bind:value={formData.serial_number}
								required
								class={errors.serial_number ? 'border-destructive' : ''}
							/>
							{#if errors.serial_number}
								<p class="mt-1 text-sm text-destructive">{errors.serial_number}</p>
							{/if}
						</div>

						<div>
							<label for="mac_address" class="mb-2 block text-sm font-medium">
								MAC Address <span class="text-destructive">*</span>
							</label>
							<Input
								id="mac_address"
								type="text"
								bind:value={formData.mac_address}
								placeholder="AA:BB:CC:DD:EE:FF"
								required
								class={errors.mac_address ? 'border-destructive' : ''}
							/>
							{#if errors.mac_address}
								<p class="mt-1 text-sm text-destructive">{errors.mac_address}</p>
							{/if}
						</div>

						<div>
							<label for="patient_id" class="mb-2 block text-sm font-medium">Paciente</label>
							<select
								id="patient_id"
								bind:value={formData.patient_id}
								class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
							>
								<option value={undefined}>Nenhum</option>
								{#each patients as patient}
									<option value={patient.id}>{patient.name}</option>
								{/each}
							</select>
						</div>

						<div>
							<label for="model" class="mb-2 block text-sm font-medium">Modelo</label>
							<Input id="model" type="text" bind:value={formData.model} />
						</div>

						<div>
							<label for="version" class="mb-2 block text-sm font-medium">Versão</label>
							<Input id="version" type="text" bind:value={formData.version} />
						</div>

						<div>
							<label for="status" class="mb-2 block text-sm font-medium">Status</label>
							<select
								id="status"
								bind:value={formData.status}
								class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
							>
								<option value="online">Online</option>
								<option value="offline">Offline</option>
								<option value="maintenance">Manutenção</option>
								<option value="error">Erro</option>
							</select>
						</div>

						<div>
							<label for="firmware_version" class="mb-2 block text-sm font-medium">
								Firmware Version
							</label>
							<Input id="firmware_version" type="text" bind:value={formData.firmware_version} />
						</div>

						<div>
							<label for="hardware_version" class="mb-2 block text-sm font-medium">
								Hardware Version
							</label>
							<Input id="hardware_version" type="text" bind:value={formData.hardware_version} />
						</div>
					</div>

					<div class="flex justify-end gap-4">
						<Button type="button" variant="outline" on:click={() => goto('/devices')}>
							Cancelar
						</Button>
						<Button type="submit" loading={loading}>
							{device ? 'Salvar Alterações' : 'Criar Dispositivo'}
						</Button>
					</div>
				</form>
		{/if}
	</CardContent>
</Card>

