<script lang="ts">
	import Badge from '$lib/components/ui/Badge.svelte';
	import type { Severity } from '$lib/types/alert';

	export let severity: Severity;
</script>

<Badge
	variant={severity === 'critical' || severity === 'high' ? 'danger' : severity === 'medium' ? 'warning' : 'default'}
>
	{severity}
</Badge>








