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
			// Login successful, redirect will be handled by authStore.login()
			console.log('Login successful, redirecting to dashboard...');
		} catch (err: any) {
			if (err?.status === 0) {
				error = 'Não foi possível conectar ao servidor. Verifique se o backend está rodando.';
			} else if (err?.status === 401) {
				error = 'Usuário ou senha incorretos';
			} else {
				error = err?.message || 'Erro ao fazer login. Verifique sua conexão.';
			}
		} finally {
			loading = false;
		}
	}
</script>

<div 
	class="flex min-h-screen items-center justify-center p-4"
	style="background-image: url('/bg-login.png'); background-size: cover; background-position: center; background-repeat: no-repeat;"
>
	<div class="absolute inset-0 bg-black/40"></div>
	<Card class="relative z-10 w-full max-w-md p-8 bg-card/95 backdrop-blur-sm">
		<div class="mb-6 text-center">
			<h1 class="text-3xl font-bold text-foreground">OrthoTrack</h1>
			<p class="mt-2 text-sm text-muted-foreground">Dashboard Administrativo</p>
		</div>
		
		<form on:submit|preventDefault={handleLogin} class="space-y-4">
			{#if error}
				<div class="rounded-md bg-destructive/10 border border-destructive p-3 text-sm text-destructive">
					{error}
				</div>
			{/if}
			
			<div>
				<label for="email" class="mb-2 block text-sm font-medium">Usuário</label>
				<Input
					id="email"
					type="text"
					bind:value={email}
					placeholder="Digite seu email"
					required
				/>
			</div>
			
			<div>
				<label for="password" class="mb-2 block text-sm font-medium">Senha</label>
				<Input
					id="password"
					type="password"
					bind:value={password}
					placeholder="Digite sua senha"
					required
				/>
			</div>
			
			<Button type="submit" {loading} class="w-full">
				{loading ? 'Entrando...' : 'Entrar'}
			</Button>
		</form>
	</Card>
</div>

