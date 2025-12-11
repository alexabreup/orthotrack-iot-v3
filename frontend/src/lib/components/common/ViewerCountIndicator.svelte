<!--
  ViewerCountIndicator Component
  Shows viewer count with tooltip for viewer names
  Requirements: 8.4, 8.5
-->
<script lang="ts">
	import { Eye } from 'lucide-svelte';
	import { viewerCounts } from '$lib/stores/viewer-counts.store';

	export let channel: string;
	export let currentUserName = 'Você';

	$: viewerCount = $viewerCounts.get(channel) || 0;
	$: showIndicator = viewerCount > 1;

	// Mock viewer names for now - in real implementation this would come from the WebSocket event
	$: viewerNames = generateViewerNames(viewerCount);

	function generateViewerNames(count: number): string[] {
		if (count <= 1) return [];
		
		const names = ['Dr. Silva', 'Enf. Maria', 'Dr. Santos', 'Fisio. João', 'Coord. Ana'];
		return names.slice(0, count - 1); // Exclude current user
	}

	function formatViewerTooltip(names: string[]): string {
		if (names.length === 0) return '';
		if (names.length === 1) return `${names[0]} também está visualizando`;
		if (names.length === 2) return `${names[0]} e ${names[1]} também estão visualizando`;
		
		const others = names.slice(0, -1).join(', ');
		const last = names[names.length - 1];
		return `${others} e ${last} também estão visualizando`;
	}
</script>

{#if showIndicator}
	<div 
		class="flex items-center gap-1 text-sm text-muted-foreground cursor-help"
		title={formatViewerTooltip(viewerNames)}
	>
		<Eye class="h-4 w-4" />
		<span>{viewerCount}</span>
	</div>
{/if}