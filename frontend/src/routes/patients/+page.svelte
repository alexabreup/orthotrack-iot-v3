<script lang="ts">
	import { onMount } from 'svelte';
	import { patientsStore } from '$lib/stores/patients.store';
	import Button from '$lib/components/ui/Button.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import Badge from '$lib/components/ui/Badge.svelte';
	
	onMount(() => {
		patientsStore.fetchPatients();
	});
	
	function formatDate(dateString: string) {
		return new Date(dateString).toLocaleDateString('pt-BR');
	}
</script>

<div class="p-8">
	<div class="mb-8 flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">Pacientes</h1>
			<p class="mt-2 text-muted-foreground">Gerenciamento de pacientes</p>
		</div>
		<Button>+ Novo Paciente</Button>
	</div>
	
	{#if $patientsStore.loading}
		<div class="flex items-center justify-center py-12">
			<div class="loading-spinner h-8 w-8"></div>
		</div>
	{:else if $patientsStore.error}
		<div class="rounded-lg border border-red-200 bg-red-50 p-4 text-red-800">
			{$patientsStore.error}
		</div>
	{:else if $patientsStore.patients.length === 0}
		<Card className="p-12 text-center">
			<p class="text-muted-foreground">Nenhum paciente cadastrado</p>
			<Button className="mt-4">Criar Primeiro Paciente</Button>
		</Card>
	{:else}
		<Card className="overflow-hidden">
			<div class="overflow-x-auto">
				<table class="w-full">
					<thead class="border-b bg-muted/50">
						<tr>
							<th class="px-6 py-3 text-left text-sm font-medium">Nome</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Data de Nascimento</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Gênero</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Horas Prescritas</th>
							<th class="px-6 py-3 text-left text-sm font-medium">Ações</th>
						</tr>
					</thead>
					<tbody>
						{#each $patientsStore.patients as patient}
							<tr class="border-b hover:bg-muted/50">
								<td class="px-6 py-4">
									<div class="font-medium">{patient.name}</div>
									{#if patient.diagnosis}
										<div class="text-sm text-muted-foreground">{patient.diagnosis}</div>
									{/if}
								</td>
								<td class="px-6 py-4 text-sm">{formatDate(patient.date_of_birth)}</td>
								<td class="px-6 py-4">
									<Badge variant="default">{patient.gender}</Badge>
								</td>
								<td class="px-6 py-4 text-sm">
									{patient.prescribed_hours_per_day || 'N/A'}h/dia
								</td>
								<td class="px-6 py-4">
									<div class="flex gap-2">
										<Button variant="ghost" size="sm">Editar</Button>
										<Button variant="ghost" size="sm">Ver Detalhes</Button>
									</div>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		</Card>
	{/if}
</div>

