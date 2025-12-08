<script lang="ts">
	import { cn } from '$lib/utils';

	export let className = '';
	
	// Support both 'class' and 'className' props
	let klass = '';
	export { klass as class };
</script>

<div class={cn('rounded-lg border border-border bg-card text-card-foreground shadow-sm', className, klass)}>
	<slot />
</div>


