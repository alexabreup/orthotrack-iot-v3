<script lang="ts">
	export let title: string;
	export let value: string | number;
	export let subtitle: string | undefined = undefined;
	export let icon: string | undefined = undefined;
	export let trend: {
		value: number;
		direction: 'up' | 'down';
	} | undefined = undefined;
</script>

<div class="rounded-lg border bg-card p-6">
	<div class="flex items-center justify-between">
		<div class="flex-1">
			<p class="text-sm font-medium text-muted-foreground">{title}</p>
			<p class="mt-2 text-3xl font-bold">{value}</p>
			{#if subtitle}
				<p class="mt-1 text-xs text-muted-foreground">{subtitle}</p>
			{/if}
			{#if trend}
				<div class="mt-2 flex items-center text-xs">
					<span class={trend.direction === 'up' ? 'text-green-600' : 'text-red-600'}>
						{trend.direction === 'up' ? '↑' : '↓'} {Math.abs(trend.value)}%
					</span>
					<span class="ml-1 text-muted-foreground">vs período anterior</span>
				</div>
			{/if}
		</div>
		{#if icon}
			<div class="rounded-full bg-primary/10 p-3">
				<span class="text-2xl">{icon}</span>
			</div>
		{/if}
	</div>
</div>

