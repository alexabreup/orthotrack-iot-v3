<script lang="ts">
	import { cn } from '$lib/utils';

	export let className = '';
	
	// Support both 'class' and 'className' props
	let klass = '';
	export { klass as class };
</script>

<div class={cn('flex flex-col space-y-1.5 p-6', className, klass)}>
	<slot />
</div>


