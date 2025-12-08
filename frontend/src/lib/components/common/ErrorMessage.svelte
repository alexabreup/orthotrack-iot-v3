<script lang="ts">
	export let message: string;
	export let onRetry: (() => void) | null = null;
</script>

<div class="rounded-lg border border-destructive bg-destructive/10 p-4 text-destructive">
	<div class="flex items-center gap-2">
		<span class="text-lg">⚠️</span>
		<p class="flex-1">{message}</p>
		{#if onRetry}
			<button
				on:click={onRetry}
				class="rounded-md bg-destructive px-3 py-1.5 text-sm text-destructive-foreground hover:bg-destructive/90"
			>
				Tentar novamente
			</button>
		{/if}
	</div>
</div>




