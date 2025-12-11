<!--
  TelemetryDashboard Component
  Complete telemetry dashboard with multiple real-time charts
  Requirements: 3.2, 3.3, 3.4, 3.5, 3.6
-->
<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import TelemetryChart from './TelemetryChart.svelte';
	import { telemetryData } from '$lib/stores/telemetry-data.store';
	import { formatTemperature, formatBatteryLevel } from '$lib/utils/formatters';
	import { Thermometer, Battery, Activity } from 'lucide-svelte';

	export let deviceId: string;

	// Get latest telemetry values for display
	$: latestTelemetry = $telemetryData.get(deviceId)?.slice(-1)[0];
	$: dataPointCount = $telemetryData.get(deviceId)?.length || 0;
</script>

<div class="space-y-6">
	<!-- Current Values Summary -->
	<div class="grid grid-cols-1 md:grid-cols-3 gap-4">
		<Card>
			<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
				<CardTitle class="text-sm font-medium">Temperatura Atual</CardTitle>
				<Thermometer class="h-4 w-4 text-muted-foreground" />
			</CardHeader>
			<CardContent>
				<div class="text-2xl font-bold">
					{#if latestTelemetry?.sensors.temperature !== undefined}
						{formatTemperature(latestTelemetry.sensors.temperature)}
					{:else}
						--
					{/if}
				</div>
				<p class="text-xs text-muted-foreground">
					{dataPointCount} pontos de dados
				</p>
			</CardContent>
		</Card>

		<Card>
			<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
				<CardTitle class="text-sm font-medium">Nível da Bateria</CardTitle>
				<Battery class="h-4 w-4 text-muted-foreground" />
			</CardHeader>
			<CardContent>
				<div class="text-2xl font-bold">
					{#if latestTelemetry?.sensors.battery_level !== undefined}
						{formatBatteryLevel(latestTelemetry.sensors.battery_level)}
					{:else}
						--
					{/if}
				</div>
				<p class="text-xs text-muted-foreground">
					Última atualização: {latestTelemetry ? new Date(latestTelemetry.timestamp).toLocaleTimeString() : '--'}
				</p>
			</CardContent>
		</Card>

		<Card>
			<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
				<CardTitle class="text-sm font-medium">Movimento</CardTitle>
				<Activity class="h-4 w-4 text-muted-foreground" />
			</CardHeader>
			<CardContent>
				<div class="text-2xl font-bold">
					{#if latestTelemetry?.sensors.accelerometer}
						{Math.sqrt(
							Math.pow(latestTelemetry.sensors.accelerometer.x, 2) +
							Math.pow(latestTelemetry.sensors.accelerometer.y, 2) +
							Math.pow(latestTelemetry.sensors.accelerometer.z, 2)
						).toFixed(2)} m/s²
					{:else}
						--
					{/if}
				</div>
				<p class="text-xs text-muted-foreground">
					Magnitude total
				</p>
			</CardContent>
		</Card>
	</div>

	<!-- Temperature Chart -->
	<Card>
		<CardHeader>
			<CardTitle>Temperatura em Tempo Real</CardTitle>
		</CardHeader>
		<CardContent>
			<TelemetryChart 
				{deviceId} 
				sensorType="temperature" 
				title="Temperatura (°C)"
				height={250}
			/>
		</CardContent>
	</Card>

	<!-- Battery Level Chart -->
	<Card>
		<CardHeader>
			<CardTitle>Nível da Bateria em Tempo Real</CardTitle>
		</CardHeader>
		<CardContent>
			<TelemetryChart 
				{deviceId} 
				sensorType="battery_level" 
				title="Nível da Bateria (%)"
				height={250}
			/>
		</CardContent>
	</Card>

	<!-- Accelerometer Chart -->
	<Card>
		<CardHeader>
			<CardTitle>Acelerômetro em Tempo Real</CardTitle>
		</CardHeader>
		<CardContent>
			<TelemetryChart 
				{deviceId} 
				sensorType="accelerometer" 
				title="Dados do Acelerômetro (m/s²)"
				height={300}
			/>
		</CardContent>
	</Card>
</div>