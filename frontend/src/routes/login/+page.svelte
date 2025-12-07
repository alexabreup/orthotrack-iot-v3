<script lang="ts">
	import { onMount } from 'svelte';
	import { authStore } from '$lib/stores/auth.store';
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/Button.svelte';
	import Input from '$lib/components/ui/Input.svelte';
	import Card from '$lib/components/ui/Card.svelte';
	
	let email = '';
	let password = '';
	let loading = false;
	let error = '';
	
	onMount(() => {
		// Se já estiver autenticado, redirecionar
		if ($authStore.isAuthenticated) {
			goto('/');
		}
	});
	
	async function handleLogin() {
		if (!email || !password) {
			error = 'Por favor, preencha todos os campos';
			return;
		}
		
		loading = true;
		error = '';
		
		try {
			await authStore.login(email, password);
		} catch (err) {
			error = err instanceof Error ? err.message : 'Erro ao fazer login';
		} finally {
			loading = false;
		}
	}
</script>

<div class="flex min-h-screen items-center justify-center bg-gradient-to-br from-primary/10 to-primary/5 p-4">
	<Card className="w-full max-w-md p-8">
		<div class="mb-6 text-center">
			<h1 class="text-3xl font-bold text-foreground">OrthoTrack</h1>
			<p class="mt-2 text-sm text-muted-foreground">Dashboard Administrativo</p>
		</div>
		
		<form on:submit|preventDefault={handleLogin} class="space-y-4">
			{#if error}
				<div class="rounded-md bg-red-50 border border-red-200 p-3 text-sm text-red-800">
					{error}
				</div>
			{/if}
			
			<div>
				<label for="email" class="mb-2 block text-sm font-medium">Email ou Usuário</label>
				<Input
					id="email"
					type="text"
					bind:value={email}
					placeholder="admin ou seu@email.com"
					required
				/>
			</div>
			
			<div>
				<label for="password" class="mb-2 block text-sm font-medium">Senha</label>
				<Input
					id="password"
					type="password"
					bind:value={password}
					placeholder="••••••••"
					required
				/>
			</div>
			
			<Button type="submit" {loading} className="w-full">
				{loading ? 'Entrando...' : 'Entrar'}
			</Button>
		</form>
	</Card>
</div>

