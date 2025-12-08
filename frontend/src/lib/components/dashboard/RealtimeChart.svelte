<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import {
		Chart,
		CategoryScale,
		LinearScale,
		PointElement,
		LineElement,
		Title,
		Tooltip,
		Legend,
		Filler,
		type ChartConfiguration,
	} from 'chart.js';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import { LoadingSpinner } from '$lib/components/common';

	export let deviceId: string | undefined = undefined;
	export let dataType: 'compliance' | 'telemetry' | 'usage' = 'compliance';
	export let title: string = 'Dados em Tempo Real';

	let chartCanvas: HTMLCanvasElement;
	let chart: Chart | null = null;
	let interval: NodeJS.Timeout | null = null;
	let isLoading = true;
	let chartData: any = null;

	onMount(() => {
		Chart.register(
			CategoryScale,
			LinearScale,
			PointElement,
			LineElement,
			Title,
			Tooltip,
			Legend,
			Filler
		);

		// Inicializar gráfico
		if (chartCanvas) {
			chart = new Chart(chartCanvas, {
				type: 'line',
				data: {
					labels: [],
					datasets: [],
				},
				options: {
					responsive: true,
					maintainAspectRatio: false,
					plugins: {
						legend: {
							labels: {
								color: 'hsl(var(--foreground))',
							},
						},
					},
					scales: {
						x: {
							ticks: {
								color: 'hsl(var(--muted-foreground))',
							},
							grid: {
								color: 'hsl(var(--border))',
							},
						},
						y: {
							ticks: {
								color: 'hsl(var(--muted-foreground))',
							},
							grid: {
								color: 'hsl(var(--border))',
							},
						},
					},
				},
			});
		}

		// Polling a cada 30 segundos
		interval = setInterval(() => {
			// Atualizar dados do gráfico
			// TODO: Implementar chamada à API
		}, 30000);
	});

	onDestroy(() => {
		if (interval) clearInterval(interval);
		if (chart) chart.destroy();
	});
</script>

<Card>
	<CardHeader>
		<CardTitle>{title}</CardTitle>
	</CardHeader>
	<CardContent>
		{#if isLoading}
			<div class="flex h-64 items-center justify-center">
				<LoadingSpinner />
			</div>
		{:else}
			<div class="h-64">
				<canvas bind:this={chartCanvas}></canvas>
			</div>
		{/if}
	</CardContent>
</Card>

