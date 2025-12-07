<script lang="ts">
	type Variant = 'default' | 'success' | 'warning' | 'danger' | 'info';
	
	export let variant: Variant = 'default';
	
	let className = '';
	
	$: {
		const variants: Record<Variant, string> = {
			default: 'bg-secondary text-secondary-foreground',
			success: 'bg-green-100 text-green-800 dark:bg-green-800 dark:text-green-100',
			warning: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-800 dark:text-yellow-100',
			danger: 'bg-red-100 text-red-800 dark:bg-red-800 dark:text-red-100',
			info: 'bg-blue-100 text-blue-800 dark:bg-blue-800 dark:text-blue-100',
		};
		
		className = `inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors ${variants[variant]}`;
	}
</script>

<span class={className}>
	<slot />
</span>

