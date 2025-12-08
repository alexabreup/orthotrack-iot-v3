<script lang="ts">
	import Button from '$lib/components/ui/Button.svelte';
	import { Download } from 'lucide-svelte';

	export let onExport: () => void;
	export let format: 'csv' | 'pdf' = 'csv';
	export let loading = false;
</script>

<Button variant="outline" on:click={onExport} loading={loading}>
	<Download class="mr-2 h-4 w-4" />
	Exportar {format.toUpperCase()}
</Button>

