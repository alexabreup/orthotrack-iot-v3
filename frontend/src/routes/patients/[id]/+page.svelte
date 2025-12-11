<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { patientsService } from '$lib/services/patients.service';
	import { LoadingSpinner, ErrorMessage } from '$lib/components/common';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import UsageIndicator from '$lib/components/patients/UsageIndicator.svelte';
	import ViewerCountIndicator from '$lib/components/common/ViewerCountIndicator.svelte';
	import TelemetryDashboard from '$lib/components/devices/TelemetryDashboard.svelte';
	import { formatDate, formatCPF, formatPhone } from '$lib/utils/formatters';
	import { PATIENT_STATUS_COLORS } from '$lib/utils/constants';
	import { getWebSocketClient } from '$lib/services/websocket.service';
	import { activeAlerts } from '$lib/stores/active-alerts.store';
	import type { Patient } from '$lib/types/patient';
	import type { UsageSessionEvent, AlertEvent } from '$lib/types/websocket';

	let patient: Patient | null = null;
	let loading = true;
	let error: string | null = null;
	let isInUse = false;
	let dailyUsageMinutes = 0;
	let sessionStartTime: number | null = null;

	$: patientId = parseInt($page.params.id);
	$: patientChannel = `patient:${patientId}`;
	$: deviceId = ''; // TODO: Get device ID from patient-device relationship

	onMount(async () => {
		await loadPatient();
		initializeRealTimeUpdates();
	});

	onDestroy(() => {
		cleanupRealTimeUpdates();
	});

	function initializeRealTimeUpdates() {
		const wsClient = getWebSocketClient();
		
		// Subscribe to patient channel for alerts and usage sessions
		wsClient.subscribe(patientChannel);
		
		// Handle usage session events
		wsClient.on('usage_session_start', (event: UsageSessionEvent) => {
			if (event.data.patient_id === patientId.toString()) {
				isInUse = true;
				sessionStartTime = event.data.timestamp;
			}
		});

		wsClient.on('usage_session_end', (event: UsageSessionEvent) => {
			if (event.data.patient_id === patientId.toString()) {
				isInUse = false;
				sessionStartTime = null;
				// Update daily usage with session duration
				if (event.data.duration) {
					dailyUsageMinutes += Math.floor(event.data.duration / 60);
				}
			}
		});

		// Handle alert events
		wsClient.on('alert_created', (event: AlertEvent) => {
			if (event.data.patient_id === patientId.toString()) {
				// Alert will be handled by the activeAlerts store
				console.log('New alert for patient:', event.data);
			}
		});
	}

	function cleanupRealTimeUpdates() {
		const wsClient = getWebSocketClient();
		wsClient.unsubscribe(patientChannel);
	}

	async function loadPatient() {
		loading = true;
		error = null;
		try {
			patient = await patientsService.get(patientId);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar paciente';
		} finally {
			loading = false;
		}
	}
</script>

{#if loading}
	<div class="flex items-center justify-center py-12">
		<LoadingSpinner size="lg" />
	</div>
{:else if error}
	<ErrorMessage message={error} onRetry={loadPatient} />
{:else if patient}
	<div class="space-y-6">
		<div class="flex items-center justify-between">
			<div class="flex items-center gap-4">
				<div>
					<h1 class="text-3xl font-bold">{patient.name}</h1>
					<p class="mt-2 text-muted-foreground">Detalhes do paciente</p>
				</div>
				<ViewerCountIndicator channel={patientChannel} />
			</div>
			<Button href="/patients/{patient.id}/edit">Editar</Button>
		</div>

		<div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
			<!-- Informações Pessoais -->
			<Card>
				<CardHeader>
					<CardTitle>Informações Pessoais</CardTitle>
				</CardHeader>
				<CardContent class="space-y-4">
					<div>
						<label class="text-sm text-muted-foreground">Nome</label>
						<p class="font-medium">{patient.name}</p>
					</div>
					{#if patient.external_id}
						<div>
							<label class="text-sm text-muted-foreground">ID Externo</label>
							<p class="font-medium">{patient.external_id}</p>
						</div>
					{/if}
					{#if patient.date_of_birth}
						<div>
							<label class="text-sm text-muted-foreground">Data de Nascimento</label>
							<p class="font-medium">{formatDate(patient.date_of_birth)}</p>
						</div>
					{/if}
					{#if patient.gender}
						<div>
							<label class="text-sm text-muted-foreground">Gênero</label>
							<p class="font-medium">{patient.gender === 'M' ? 'Masculino' : 'Feminino'}</p>
						</div>
					{/if}
					{#if patient.cpf}
						<div>
							<label class="text-sm text-muted-foreground">CPF</label>
							<p class="font-medium">{formatCPF(patient.cpf)}</p>
						</div>
					{/if}
					{#if patient.email}
						<div>
							<label class="text-sm text-muted-foreground">Email</label>
							<p class="font-medium">{patient.email}</p>
						</div>
					{/if}
					{#if patient.phone}
						<div>
							<label class="text-sm text-muted-foreground">Telefone</label>
							<p class="font-medium">{formatPhone(patient.phone)}</p>
						</div>
					{/if}
				</CardContent>
			</Card>

			<!-- Dados Médicos -->
			<Card>
				<CardHeader>
					<CardTitle>Dados Médicos</CardTitle>
				</CardHeader>
				<CardContent class="space-y-4">
					{#if patient.medical_record}
						<div>
							<label class="text-sm text-muted-foreground">Prontuário Médico</label>
							<p class="font-medium">{patient.medical_record}</p>
						</div>
					{/if}
					{#if patient.diagnosis_code}
						<div>
							<label class="text-sm text-muted-foreground">Código de Diagnóstico</label>
							<p class="font-medium">{patient.diagnosis_code}</p>
						</div>
					{/if}
					{#if patient.severity_level}
						<div>
							<label class="text-sm text-muted-foreground">Nível de Severidade</label>
							<p class="font-medium">{patient.severity_level}/5</p>
						</div>
					{/if}
					{#if patient.scoliosis_type}
						<div>
							<label class="text-sm text-muted-foreground">Tipo de Escoliose</label>
							<p class="font-medium">{patient.scoliosis_type}</p>
						</div>
					{/if}
					<div>
						<label class="text-sm text-muted-foreground">Status</label>
						<div class="mt-1">
							<Badge variant={PATIENT_STATUS_COLORS[patient.status] || 'default'}>
								{patient.status}
							</Badge>
						</div>
					</div>
				</CardContent>
			</Card>

			<!-- Prescrição e Uso Atual -->
			<Card>
				<CardHeader>
					<CardTitle>Prescrição e Uso Atual</CardTitle>
				</CardHeader>
				<CardContent class="space-y-4">
					{#if patient.prescription_hours}
						<div>
							<label class="text-sm text-muted-foreground">Horas Prescritas por Dia</label>
							<p class="font-medium">{patient.prescription_hours}h</p>
						</div>
					{/if}
					{#if patient.daily_usage_target_minutes}
						<div>
							<label class="text-sm text-muted-foreground">Minutos Alvo Diários</label>
							<p class="font-medium">{patient.daily_usage_target_minutes}min</p>
						</div>
					{/if}
					{#if patient.treatment_start}
						<div>
							<label class="text-sm text-muted-foreground">Data de Início</label>
							<p class="font-medium">{formatDate(patient.treatment_start)}</p>
						</div>
					{/if}
					{#if patient.treatment_end}
						<div>
							<label class="text-sm text-muted-foreground">Data de Término</label>
							<p class="font-medium">{formatDate(patient.treatment_end)}</p>
						</div>
					{/if}
					{#if patient.prescription_notes}
						<div>
							<label class="text-sm text-muted-foreground">Notas</label>
							<p class="font-medium">{patient.prescription_notes}</p>
						</div>
					{/if}
					
					<!-- Real-time Usage Indicator -->
					<div class="pt-4 border-t">
						<label class="text-sm text-muted-foreground">Status de Uso em Tempo Real</label>
						<div class="mt-2">
							<UsageIndicator 
								{isInUse}
								{dailyUsageMinutes}
								targetMinutes={patient.daily_usage_target_minutes || 0}
								{sessionStartTime}
							/>
						</div>
					</div>
				</CardContent>
			</Card>
		</div>

		<!-- Telemetry Dashboard -->
		{#if deviceId}
			<div class="mt-8">
				<h2 class="text-2xl font-bold mb-4">Telemetria em Tempo Real</h2>
				<TelemetryDashboard {deviceId} />
			</div>
		{/if}

		<!-- Recent Alerts -->
		{#if $activeAlerts.length > 0}
			<Card class="mt-6">
				<CardHeader>
					<CardTitle>Alertas Recentes</CardTitle>
				</CardHeader>
				<CardContent>
					<div class="space-y-2">
						{#each $activeAlerts.filter(alert => alert.patient_id === patientId).slice(0, 5) as alert}
							<div class="flex items-center justify-between p-3 bg-secondary rounded-lg">
								<div class="flex items-center gap-2">
									<Badge variant={alert.severity === 'critical' ? 'danger' : alert.severity === 'high' ? 'warning' : 'info'}>
										{alert.severity}
									</Badge>
									<span class="text-sm">{alert.message}</span>
								</div>
								<span class="text-xs text-muted-foreground">
									{new Date(alert.created_at).toLocaleTimeString()}
								</span>
							</div>
						{/each}
					</div>
				</CardContent>
			</Card>
		{/if}
	</div>
{/if}

