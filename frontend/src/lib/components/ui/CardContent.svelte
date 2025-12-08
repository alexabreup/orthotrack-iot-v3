<script lang="ts">
	import { cn } from '$lib/utils';

	export let className = '';
	
	// Support both 'class' and 'className' props
	let klass = '';
	export { klass as class };
</script>

<div class={cn('p-6 pt-0', className, klass)}>
	<slot />
</div>


