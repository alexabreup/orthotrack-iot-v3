<script lang="ts">
	import { onMount } from 'svelte';
	import PatientCard from './PatientCard.svelte';
	import { LoadingSpinner, ErrorMessage, EmptyState, Pagination, SearchBar } from '$lib/components/common';
	import Button from '$lib/components/ui/Button.svelte';
	import { patientsService } from '$lib/services/patients.service';
	import type { Patient, PatientsListParams } from '$lib/types/patient';

	export let filters: PatientsListParams = {};

	let patients: Patient[] = [];
	let loading = true;
	let error: string | null = null;
	let currentPage = 1;
	let totalPages = 1;
	let searchQuery = '';

	onMount(() => {
		loadPatients();
	});

	async function loadPatients() {
		loading = true;
		error = null;
		try {
			const params = {
				...filters,
				page: currentPage,
				search: searchQuery || undefined,
			};
			const response = await patientsService.list(params);
			patients = response.data;
			totalPages = response.total_pages;
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao carregar pacientes';
		} finally {
			loading = false;
		}
	}

	function handleSearch(query: string) {
		searchQuery = query;
		currentPage = 1;
		loadPatients();
	}

	function handlePageChange(page: number) {
		currentPage = page;
		loadPatients();
	}
</script>

<div class="space-y-6">
	<div class="flex items-center justify-between">
		<div>
			<h1 class="text-3xl font-bold">Pacientes</h1>
			<p class="mt-2 text-muted-foreground">Gerencie os pacientes do sistema</p>
		</div>
		<Button href="/patients/new">Novo Paciente</Button>
	</div>

	<div class="flex gap-4">
		<div class="flex-1">
			<SearchBar placeholder="Buscar pacientes..." onSearch={handleSearch} />
		</div>
	</div>

	{#if loading}
		<div class="flex items-center justify-center py-12">
			<LoadingSpinner size="lg" />
		</div>
	{:else if error}
		<ErrorMessage message={error} onRetry={loadPatients} />
	{:else if patients.length === 0}
		<EmptyState
			title="Nenhum paciente encontrado"
			description="Comece adicionando um novo paciente ao sistema"
			actionLabel="Novo Paciente"
			onAction={() => (window.location.href = '/patients/new')}
		/>
	{:else}
		<div class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
			{#each patients as patient}
				<PatientCard {patient} />
			{/each}
		</div>

		{#if totalPages > 1}
			<div class="mt-6">
				<Pagination
					currentPage={currentPage}
					totalPages={totalPages}
					onPageChange={handlePageChange}
				/>
			</div>
		{/if}
	{/if}
</div>

