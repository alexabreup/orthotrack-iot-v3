<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import type { ComponentType } from 'svelte';

	export let title: string;
	export let value: string | number;
	export let icon: ComponentType;
	export let trend: 'up' | 'down' | 'neutral' = 'neutral';
	export let trendValue: string = '';
	export let description: string = '';
</script>

<Card>
	<CardHeader class="flex flex-row items-center justify-between space-y-0 pb-2">
		<CardTitle class="text-sm font-medium text-muted-foreground">{title}</CardTitle>
		<svelte:component this={icon} class="h-4 w-4 text-muted-foreground" />
	</CardHeader>
	<CardContent>
		<div class="text-2xl font-bold">{value}</div>
		{#if trendValue}
			<p class="text-xs text-muted-foreground">
				{trend === 'up' ? '↑' : trend === 'down' ? '↓' : ''} {trendValue}
			</p>
		{/if}
		{#if description}
			<p class="text-xs text-muted-foreground mt-1">{description}</p>
		{/if}
	</CardContent>
</Card>

