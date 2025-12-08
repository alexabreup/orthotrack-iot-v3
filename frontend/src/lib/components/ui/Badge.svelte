<script lang="ts">
	import { cn } from '$lib/utils';

	type Variant = 'default' | 'success' | 'warning' | 'danger' | 'info';
	
	export let variant: Variant = 'default';
	export let className = '';
	
	$: {
		const variants: Record<Variant, string> = {
			default: 'bg-secondary text-secondary-foreground',
			success: 'bg-success/10 text-success',
			warning: 'bg-warning/10 text-warning',
			danger: 'bg-destructive/10 text-destructive',
			info: 'bg-info/10 text-info',
		};
		
		className = cn(
			'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors',
			variants[variant],
			className
		);
	}
</script>

<span class={className}>
	<slot />
</span>

