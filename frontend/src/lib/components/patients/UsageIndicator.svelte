<!--
  UsageIndicator Component
  Real-time usage indicator for patient sessions
  Requirements: 11.3, 11.4, 11.5
-->
<script lang="ts">
	import Badge from '$lib/components/ui/Badge.svelte';
	import { Clock, Activity } from 'lucide-svelte';
	import { formatDuration } from '$lib/utils/formatters';

	export let isInUse = false;
	export let dailyUsageMinutes = 0;
	export let targetMinutes = 0;
	export let sessionStartTime: number | null = null;

	$: compliance = targetMinutes > 0 ? (dailyUsageMinutes / targetMinutes) * 100 : 0;
	$: complianceColor = compliance >= 80 ? 'success' as const : compliance >= 60 ? 'warning' as const : 'danger' as const;
	
	// Calculate current session duration if in use
	$: currentSessionDuration = isInUse && sessionStartTime 
		? Math.floor((Date.now() - sessionStartTime) / 1000 / 60) 
		: 0;
</script>

<div class="space-y-4">
	<!-- Usage Status -->
	<div class="flex items-center gap-2">
		{#if isInUse}
			<Badge variant="success" className="flex items-center gap-1">
				<Activity class="h-3 w-3" />
				Em Uso
			</Badge>
			{#if currentSessionDuration > 0}
				<span class="text-sm text-muted-foreground">
					Sessão atual: {currentSessionDuration}min
				</span>
			{/if}
		{:else}
			<Badge variant="default" className="flex items-center gap-1">
				<Clock class="h-3 w-3" />
				Inativo
			</Badge>
		{/if}
	</div>

	<!-- Daily Usage Progress -->
	<div class="space-y-2">
		<div class="flex items-center justify-between">
			<span class="text-sm font-medium">Uso Diário</span>
			<Badge variant={complianceColor}>
				{compliance.toFixed(1)}%
			</Badge>
		</div>
		
		<div class="w-full bg-secondary rounded-full h-2">
			<div 
				class="h-2 rounded-full transition-all duration-300 {
					complianceColor === 'success' ? 'bg-green-500' :
					complianceColor === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
				}"
				style="width: {Math.min(compliance, 100)}%"
			></div>
		</div>
		
		<div class="flex items-center justify-between text-xs text-muted-foreground">
			<span>{formatDuration(dailyUsageMinutes * 60)}</span>
			<span>{formatDuration(targetMinutes * 60)} meta</span>
		</div>
	</div>
</div>