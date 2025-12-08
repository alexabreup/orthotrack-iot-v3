<script lang="ts">
	import Button from '$lib/components/ui/Button.svelte';
	import Input from '$lib/components/ui/Input.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import { patientsService } from '$lib/services/patients.service';
	import { validateCPF, validateEmail, validatePhone, validateRequired } from '$lib/utils/validators';
	import { formatCPF, formatPhone } from '$lib/utils/formatters';
	import { goto } from '$app/navigation';
	import type { Patient, CreatePatientData } from '$lib/types/patient';

	export let patient: Patient | null = null;
	export let onSuccess: ((patient: Patient) => void) | null = null;

	let loading = false;
	let error: string | null = null;

	// Form data
	let formData: CreatePatientData = {
		external_id: patient?.external_id || '',
		name: patient?.name || '',
		date_of_birth: patient?.date_of_birth || '',
		gender: (patient?.gender as 'M' | 'F') || 'M',
		cpf: patient?.cpf || '',
		email: patient?.email || '',
		phone: patient?.phone || '',
		guardian_name: patient?.guardian_name || '',
		guardian_phone: patient?.guardian_phone || '',
		medical_record: patient?.medical_record || '',
		diagnosis_code: patient?.diagnosis_code || '',
		severity_level: patient?.severity_level || 1,
		scoliosis_type: patient?.scoliosis_type || '',
		prescription_hours: patient?.prescription_hours || 16,
		daily_usage_target_minutes: patient?.daily_usage_target_minutes || 960,
		treatment_start: patient?.treatment_start || new Date().toISOString().split('T')[0],
		treatment_end: patient?.treatment_end || '',
		prescription_notes: patient?.prescription_notes || '',
		status: patient?.status || 'active',
	};

	// Calcular minutos alvo automaticamente
	$: {
		if (formData.prescription_hours) {
			formData.daily_usage_target_minutes = formData.prescription_hours * 60;
		}
	}

	// Validation errors
	let errors: Record<string, string> = {};

	function validateForm(): boolean {
		errors = {};

		if (!validateRequired(formData.external_id)) {
			errors.external_id = 'ID externo é obrigatório';
		}
		if (!validateRequired(formData.name)) {
			errors.name = 'Nome é obrigatório';
		}
		if (formData.cpf && !validateCPF(formData.cpf)) {
			errors.cpf = 'CPF inválido';
		}
		if (formData.email && !validateEmail(formData.email)) {
			errors.email = 'Email inválido';
		}
		if (formData.phone && !validatePhone(formData.phone)) {
			errors.phone = 'Telefone inválido';
		}
		if (formData.guardian_phone && !validatePhone(formData.guardian_phone)) {
			errors.guardian_phone = 'Telefone do responsável inválido';
		}

		return Object.keys(errors).length === 0;
	}

	async function handleSubmit() {
		if (!validateForm()) {
			error = 'Por favor, corrija os erros no formulário';
			return;
		}

		loading = true;
		error = null;

		try {
			let result: Patient;
			if (patient) {
				result = await patientsService.update(patient.id, formData);
			} else {
				result = await patientsService.create(formData);
			}

			if (onSuccess) {
				onSuccess(result);
			} else {
				goto(`/patients/${result.id}`);
			}
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao salvar paciente';
		} finally {
			loading = false;
		}
	}

	function handleCPFInput(e: Event) {
		const target = e.target as HTMLInputElement;
		if (!target || target.value === null) return;
		const cleaned = target.value.replace(/\D/g, '');
		formData.cpf = cleaned;
		target.value = formatCPF(cleaned);
	}

	function handlePhoneInput(e: Event) {
		const target = e.target as HTMLInputElement;
		if (!target || target.value === null) return;
		const cleaned = target.value.replace(/\D/g, '');
		formData.phone = cleaned;
		target.value = formatPhone(cleaned);
	}

	function handleGuardianPhoneInput(e: Event) {
		const target = e.target as HTMLInputElement;
		if (!target || target.value === null) return;
		const cleaned = target.value.replace(/\D/g, '');
		formData.guardian_phone = cleaned;
		target.value = formatPhone(cleaned);
	}
</script>

<Card>
	<CardHeader>
		<CardTitle>{patient ? 'Editar Paciente' : 'Novo Paciente'}</CardTitle>
	</CardHeader>
	<CardContent>
		<form on:submit|preventDefault={handleSubmit} class="space-y-6">
			{#if error}
				<div class="rounded-lg border border-destructive bg-destructive/10 p-4 text-destructive">
					{error}
				</div>
			{/if}

			<!-- Informações Básicas -->
			<div class="space-y-4">
				<h3 class="text-lg font-semibold">Informações Básicas</h3>
				<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
					<div>
						<label for="external_id" class="mb-2 block text-sm font-medium">
							ID Externo <span class="text-destructive">*</span>
						</label>
						<Input
							id="external_id"
							type="text"
							bind:value={formData.external_id}
							required
							class={errors.external_id ? 'border-destructive' : ''}
						/>
						{#if errors.external_id}
							<p class="mt-1 text-sm text-destructive">{errors.external_id}</p>
						{/if}
					</div>

					<div>
						<label for="name" class="mb-2 block text-sm font-medium">
							Nome Completo <span class="text-destructive">*</span>
						</label>
						<Input
							id="name"
							type="text"
							bind:value={formData.name}
							required
							class={errors.name ? 'border-destructive' : ''}
						/>
						{#if errors.name}
							<p class="mt-1 text-sm text-destructive">{errors.name}</p>
						{/if}
					</div>

					<div>
						<label for="date_of_birth" class="mb-2 block text-sm font-medium">
							Data de Nascimento
						</label>
						<Input id="date_of_birth" type="date" bind:value={formData.date_of_birth} />
					</div>

					<div>
						<label for="gender" class="mb-2 block text-sm font-medium">Gênero</label>
						<select
							id="gender"
							bind:value={formData.gender}
							class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
						>
							<option value="M">Masculino</option>
							<option value="F">Feminino</option>
						</select>
					</div>

					<div>
						<label for="cpf" class="mb-2 block text-sm font-medium">CPF</label>
						<Input
							id="cpf"
							type="text"
							on:input={handleCPFInput}
							placeholder="000.000.000-00"
							class={errors.cpf ? 'border-destructive' : ''}
						/>
						{#if errors.cpf}
							<p class="mt-1 text-sm text-destructive">{errors.cpf}</p>
						{/if}
					</div>

					<div>
						<label for="email" class="mb-2 block text-sm font-medium">Email</label>
						<Input
							id="email"
							type="email"
							bind:value={formData.email}
							class={errors.email ? 'border-destructive' : ''}
						/>
						{#if errors.email}
							<p class="mt-1 text-sm text-destructive">{errors.email}</p>
						{/if}
					</div>

					<div>
						<label for="phone" class="mb-2 block text-sm font-medium">Telefone</label>
						<Input
							id="phone"
							type="text"
							on:input={handlePhoneInput}
							placeholder="(00) 00000-0000"
							class={errors.phone ? 'border-destructive' : ''}
						/>
						{#if errors.phone}
							<p class="mt-1 text-sm text-destructive">{errors.phone}</p>
						{/if}
					</div>
				</div>
			</div>

			<!-- Responsável -->
			<div class="space-y-4">
				<h3 class="text-lg font-semibold">Responsável</h3>
				<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
					<div>
						<label for="guardian_name" class="mb-2 block text-sm font-medium">
							Nome do Responsável
						</label>
						<Input id="guardian_name" type="text" bind:value={formData.guardian_name} />
					</div>

					<div>
						<label for="guardian_phone" class="mb-2 block text-sm font-medium">
							Telefone do Responsável
						</label>
						<Input
							id="guardian_phone"
							type="text"
							on:input={handleGuardianPhoneInput}
							placeholder="(00) 00000-0000"
							class={errors.guardian_phone ? 'border-destructive' : ''}
						/>
						{#if errors.guardian_phone}
							<p class="mt-1 text-sm text-destructive">{errors.guardian_phone}</p>
						{/if}
					</div>
				</div>
			</div>

			<!-- Dados Médicos -->
			<div class="space-y-4">
				<h3 class="text-lg font-semibold">Dados Médicos</h3>
				<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
					<div>
						<label for="medical_record" class="mb-2 block text-sm font-medium">
							Prontuário Médico
						</label>
						<Input id="medical_record" type="text" bind:value={formData.medical_record} />
					</div>

					<div>
						<label for="diagnosis_code" class="mb-2 block text-sm font-medium">
							Código de Diagnóstico (CID)
						</label>
						<Input id="diagnosis_code" type="text" bind:value={formData.diagnosis_code} />
					</div>

					<div>
						<label for="severity_level" class="mb-2 block text-sm font-medium">
							Nível de Severidade (1-5)
						</label>
						<Input
							id="severity_level"
							type="number"
							min="1"
							max="5"
							bind:value={formData.severity_level}
						/>
					</div>

					<div>
						<label for="scoliosis_type" class="mb-2 block text-sm font-medium">
							Tipo de Escoliose
						</label>
						<Input id="scoliosis_type" type="text" bind:value={formData.scoliosis_type} />
					</div>
				</div>
			</div>

			<!-- Prescrição -->
			<div class="space-y-4">
				<h3 class="text-lg font-semibold">Prescrição</h3>
				<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
					<div>
						<label for="prescription_hours" class="mb-2 block text-sm font-medium">
							Horas Prescritas por Dia
						</label>
						<Input
							id="prescription_hours"
							type="number"
							min="1"
							max="24"
							bind:value={formData.prescription_hours}
						/>
					</div>

					<div>
						<label for="daily_usage_target_minutes" class="mb-2 block text-sm font-medium">
							Minutos Alvo Diários
						</label>
						<Input
							id="daily_usage_target_minutes"
							type="number"
							value={formData.daily_usage_target_minutes}
							readonly
							disabled
						/>
					</div>

					<div>
						<label for="treatment_start" class="mb-2 block text-sm font-medium">
							Data de Início do Tratamento
						</label>
						<Input id="treatment_start" type="date" bind:value={formData.treatment_start} />
					</div>

					<div>
						<label for="treatment_end" class="mb-2 block text-sm font-medium">
							Data de Término (opcional)
						</label>
						<Input id="treatment_end" type="date" bind:value={formData.treatment_end} />
					</div>

					<div class="md:col-span-2">
						<label for="prescription_notes" class="mb-2 block text-sm font-medium">
							Notas de Prescrição
						</label>
						<textarea
							id="prescription_notes"
							bind:value={formData.prescription_notes}
							rows="3"
							class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
						></textarea>
					</div>

					<div>
						<label for="status" class="mb-2 block text-sm font-medium">Status</label>
						<select
							id="status"
							bind:value={formData.status}
							class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
						>
							<option value="active">Ativo</option>
							<option value="inactive">Inativo</option>
							<option value="completed">Concluído</option>
							<option value="suspended">Suspenso</option>
						</select>
					</div>
				</div>
			</div>

			<div class="flex justify-end gap-4">
				<Button type="button" variant="outline" on:click={() => goto('/patients')}>
					Cancelar
				</Button>
				<Button type="submit" loading={loading}>
					{patient ? 'Salvar Alterações' : 'Criar Paciente'}
				</Button>
			</div>
		</form>
	</CardContent>
</Card>

