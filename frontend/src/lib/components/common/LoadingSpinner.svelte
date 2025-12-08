<script lang="ts">
	export let size: 'sm' | 'md' | 'lg' = 'md';
	
	const sizeClasses = {
		sm: 'w-4 h-4 border-2',
		md: 'w-8 h-8 border-2',
		lg: 'w-12 h-12 border-4',
	};
</script>

<div class="flex items-center justify-center">
	<div
		class="loading-spinner {sizeClasses[size]}"
		role="status"
		aria-label="Carregando..."
	>
		<span class="sr-only">Carregando...</span>
	</div>
</div>




