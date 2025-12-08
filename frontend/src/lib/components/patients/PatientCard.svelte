<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import { Users, Activity, TrendingUp } from 'lucide-svelte';
	import { formatDate, formatPercentage } from '$lib/utils/formatters';
	import { PATIENT_STATUS_COLORS } from '$lib/utils/constants';
	import type { Patient } from '$lib/types/patient';

	export let patient: Patient;
	export let compliance: number | undefined = undefined;
</script>

<Card class="p-4">
	<div class="flex items-start justify-between">
		<div class="flex-1">
			<div class="flex items-center gap-2 mb-2">
				<h3 class="text-lg font-semibold">{patient.name}</h3>
				<Badge variant={PATIENT_STATUS_COLORS[patient.status] || 'default'}>
					{patient.status}
				</Badge>
			</div>
			<div class="space-y-1 text-sm text-muted-foreground">
				{#if patient.external_id}
					<p>ID: {patient.external_id}</p>
				{/if}
				{#if patient.medical_record}
					<p>Prontuário: {patient.medical_record}</p>
				{/if}
				{#if patient.date_of_birth}
					<p>Nascimento: {formatDate(patient.date_of_birth)}</p>
				{/if}
			</div>
			{#if compliance !== undefined}
				<div class="mt-3">
					<div class="flex items-center gap-2 mb-1">
						<TrendingUp class="h-4 w-4 text-muted-foreground" />
						<span class="text-sm font-medium">Compliance: {formatPercentage(compliance)}</span>
					</div>
					<div class="h-2 w-full rounded-full bg-secondary">
						<div
							class="h-2 rounded-full bg-success transition-all"
							style="width: {compliance}%"
						></div>
					</div>
				</div>
			{/if}
		</div>
		<div class="flex flex-col gap-2">
			<Button variant="outline" size="sm" href="/patients/{patient.id}">
				Ver detalhes
			</Button>
		</div>
	</div>
</Card>

