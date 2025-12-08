<script lang="ts">
	import { cn } from '$lib/utils';

	export let className = '';
	
	// Support both 'class' and 'className' props
	let klass = '';
	export { klass as class };
</script>

<h3 class={cn('text-2xl font-semibold leading-none tracking-tight', className, klass)}>
	<slot />
</h3>


