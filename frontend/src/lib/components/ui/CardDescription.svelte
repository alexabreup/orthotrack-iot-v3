<script lang="ts">
	import { cn } from '$lib/utils';

	export let className = '';
	
	// Support both 'class' and 'className' props
	let klass = '';
	export { klass as class };
</script>

<p class={cn('text-sm text-muted-foreground', className, klass)}>
	<slot />
</p>


