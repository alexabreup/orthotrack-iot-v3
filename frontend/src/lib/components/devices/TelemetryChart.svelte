<!--
  TelemetryChart Component
  Real-time telemetry chart with 100-point sliding window
  Requirements: 3.2, 3.3, 3.4, 3.5, 3.6
-->
<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { Chart, registerables } from 'chart.js';
	import 'chartjs-adapter-date-fns';
	import { telemetryData, initializeTelemetryDataStore } from '$lib/stores/telemetry-data.store';
	import { getWebSocketClient } from '$lib/services/websocket.service';
	import type { TelemetryPoint } from '$lib/types/websocket';

	export let deviceId: string;
	export let sensorType: 'temperature' | 'battery_level' | 'accelerometer' = 'temperature';
	export let title = 'Telemetria';
	export let height = 300;

	let canvas: HTMLCanvasElement;
	let chart: Chart | null = null;
	let unsubscribeTelemetry: (() => void) | null = null;

	Chart.register(...registerables);

	onMount(() => {
		initializeChart();
		initializeRealTimeUpdates();
	});

	onDestroy(() => {
		cleanup();
	});

	function initializeChart() {
		if (!canvas) return;

		const ctx = canvas.getContext('2d');
		if (!ctx) return;

		chart = new Chart(ctx, {
			type: 'line',
			data: {
				datasets: getDatasets()
			},
			options: {
				responsive: true,
				maintainAspectRatio: false,
				scales: {
					x: {
						type: 'time',
						time: {
							displayFormats: {
								minute: 'HH:mm',
								hour: 'HH:mm'
							}
						},
						title: {
							display: true,
							text: 'Tempo'
						}
					},
					y: {
						title: {
							display: true,
							text: getYAxisLabel()
						},
						min: getYAxisMin(),
						max: getYAxisMax()
					}
				},
				plugins: {
					legend: {
						display: sensorType === 'accelerometer'
					},
					title: {
						display: true,
						text: title
					}
				},
				animation: {
					duration: 0 // Disable animation for real-time updates
				},
				elements: {
					point: {
						radius: 2
					},
					line: {
						tension: 0.1
					}
				}
			}
		});

		// Load initial data
		updateChartData();
	}

	function initializeRealTimeUpdates() {
		// Initialize telemetry store
		initializeTelemetryDataStore();
		
		// Subscribe to device telemetry channel
		const wsClient = getWebSocketClient();
		wsClient.subscribe(`device:${deviceId}`);

		// Subscribe to telemetry data changes
		unsubscribeTelemetry = telemetryData.subscribe(data => {
			const deviceData = data.get(deviceId);
			if (deviceData && chart) {
				updateChartData();
			}
		});
	}

	function cleanup() {
		// Unsubscribe from WebSocket channel
		const wsClient = getWebSocketClient();
		wsClient.unsubscribe(`device:${deviceId}`);

		// Unsubscribe from store
		if (unsubscribeTelemetry) {
			unsubscribeTelemetry();
		}

		// Destroy chart
		if (chart) {
			chart.destroy();
			chart = null;
		}
	}

	function updateChartData() {
		if (!chart) return;

		const deviceData = $telemetryData.get(deviceId) || [];
		
		// Enforce 100-point limit (sliding window)
		const limitedData = deviceData.slice(-100);

		chart.data.datasets = getDatasets(limitedData);
		chart.update('none'); // Update without animation for real-time feel
	}

	function getDatasets(data?: TelemetryPoint[]) {
		const deviceData = data || $telemetryData.get(deviceId) || [];

		switch (sensorType) {
			case 'temperature':
				return [{
					label: 'Temperatura (°C)',
					data: deviceData
						.filter(point => point.sensors.temperature !== undefined)
						.map(point => ({
							x: point.timestamp,
							y: point.sensors.temperature || 0
						})),
					borderColor: 'rgb(239, 68, 68)',
					backgroundColor: 'rgba(239, 68, 68, 0.1)',
					fill: false
				}];

			case 'battery_level':
				return [{
					label: 'Nível da Bateria (%)',
					data: deviceData
						.filter(point => point.sensors.battery_level !== undefined)
						.map(point => ({
							x: point.timestamp,
							y: point.sensors.battery_level || 0
						})),
					borderColor: 'rgb(34, 197, 94)',
					backgroundColor: 'rgba(34, 197, 94, 0.1)',
					fill: false
				}];

			case 'accelerometer':
				return [
					{
						label: 'Acelerômetro X',
						data: deviceData
							.filter(point => point.sensors.accelerometer?.x !== undefined)
							.map(point => ({
								x: point.timestamp,
								y: point.sensors.accelerometer?.x || 0
							})),
						borderColor: 'rgb(239, 68, 68)',
						backgroundColor: 'rgba(239, 68, 68, 0.1)',
						fill: false
					},
					{
						label: 'Acelerômetro Y',
						data: deviceData
							.filter(point => point.sensors.accelerometer?.y !== undefined)
							.map(point => ({
								x: point.timestamp,
								y: point.sensors.accelerometer?.y || 0
							})),
						borderColor: 'rgb(34, 197, 94)',
						backgroundColor: 'rgba(34, 197, 94, 0.1)',
						fill: false
					},
					{
						label: 'Acelerômetro Z',
						data: deviceData
							.filter(point => point.sensors.accelerometer?.z !== undefined)
							.map(point => ({
								x: point.timestamp,
								y: point.sensors.accelerometer?.z || 0
							})),
						borderColor: 'rgb(59, 130, 246)',
						backgroundColor: 'rgba(59, 130, 246, 0.1)',
						fill: false
					}
				];

			default:
				return [];
		}
	}

	function getYAxisLabel(): string {
		switch (sensorType) {
			case 'temperature':
				return 'Temperatura (°C)';
			case 'battery_level':
				return 'Nível da Bateria (%)';
			case 'accelerometer':
				return 'Aceleração (m/s²)';
			default:
				return 'Valor';
		}
	}

	function getYAxisMin(): number | undefined {
		switch (sensorType) {
			case 'battery_level':
				return 0;
			default:
				return undefined;
		}
	}

	function getYAxisMax(): number | undefined {
		switch (sensorType) {
			case 'battery_level':
				return 100;
			default:
				return undefined;
		}
	}
</script>

<div class="w-full" style="height: {height}px;">
	<canvas bind:this={canvas}></canvas>
</div>