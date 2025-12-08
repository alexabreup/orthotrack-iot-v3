<script lang="ts">
	import { onMount } from 'svelte';
	import { authStore } from '$lib/stores/auth.store';
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import Input from '$lib/components/ui/Input.svelte';
	import { formatDateTime } from '$lib/utils/formatters';
</script>

<div class="space-y-6">
	<div>
		<h1 class="text-3xl font-bold">Configurações</h1>
		<p class="mt-2 text-muted-foreground">Gerencie suas configurações e preferências</p>
	</div>

	<!-- Perfil do Usuário -->
	<Card>
		<CardHeader>
			<CardTitle>Perfil do Usuário</CardTitle>
		</CardHeader>
		<CardContent class="space-y-4">
			<div>
				<label for="user-name" class="mb-2 block text-sm font-medium">Nome</label>
				<Input id="user-name" value={$authStore.user?.name || ''} disabled />
			</div>
			<div>
				<label for="user-email" class="mb-2 block text-sm font-medium">Email</label>
				<Input id="user-email" value={$authStore.user?.email || ''} disabled />
			</div>
			<div>
				<label for="user-role" class="mb-2 block text-sm font-medium">Função</label>
				<Input id="user-role" value={$authStore.user?.role || ''} disabled />
			</div>
		</CardContent>
	</Card>

	<!-- Configurações de Alertas -->
	<Card>
		<CardHeader>
			<CardTitle>Configurações de Alertas</CardTitle>
		</CardHeader>
		<CardContent class="space-y-4">
			<div class="grid grid-cols-1 gap-4 md:grid-cols-2">
				<div>
					<label for="battery_low" class="mb-2 block text-sm font-medium">
						Bateria Baixa (%)
					</label>
					<Input id="battery_low" type="number" value="20" min="0" max="100" />
				</div>
				<div>
					<label for="compliance_low" class="mb-2 block text-sm font-medium">
						Compliance Baixa (%)
					</label>
					<Input id="compliance_low" type="number" value="80" min="0" max="100" />
				</div>
				<div>
					<label for="temp_high" class="mb-2 block text-sm font-medium">
						Temperatura Alta (°C)
					</label>
					<Input id="temp_high" type="number" value="40" min="0" max="100" />
				</div>
				<div>
					<label for="temp_low" class="mb-2 block text-sm font-medium">
						Temperatura Baixa (°C)
					</label>
					<Input id="temp_low" type="number" value="5" min="-50" max="50" />
				</div>
				<div>
					<label for="offline_timeout" class="mb-2 block text-sm font-medium">
						Timeout Offline (minutos)
					</label>
					<Input id="offline_timeout" type="number" value="120" min="1" />
				</div>
			</div>
			<div class="flex justify-end">
				<Button>Salvar Configurações</Button>
			</div>
		</CardContent>
	</Card>
</div>

