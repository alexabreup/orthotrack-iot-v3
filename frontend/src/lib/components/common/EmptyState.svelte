<script lang="ts">
	export let title: string;
	export let description: string = '';
	export let icon: string = '📭';
	export let actionLabel: string | null = null;
	export let onAction: (() => void) | null = null;
</script>

<div class="flex flex-col items-center justify-center py-12 text-center">
	<div class="mb-4 text-6xl">{icon}</div>
	<h3 class="mb-2 text-lg font-semibold">{title}</h3>
	{#if description}
		<p class="mb-4 max-w-sm text-sm text-muted-foreground">{description}</p>
	{/if}
	{#if actionLabel && onAction}
		<button
			on:click={onAction}
			class="rounded-md bg-primary px-4 py-2 text-sm text-primary-foreground hover:bg-primary/90"
		>
			{actionLabel}
		</button>
	{/if}
</div>




