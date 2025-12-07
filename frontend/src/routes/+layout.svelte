<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { authStore } from '$lib/stores/auth.store';
	import { goto } from '$app/navigation';
	
	let isAuthenticated = false;
	let currentPath = '';
	
	$: {
		isAuthenticated = $authStore.isAuthenticated;
		currentPath = $page.url.pathname;
	}
	
	onMount(() => {
		// Verificar autenticação
		if (!authStore.checkAuth() && currentPath !== '/login') {
			goto('/login');
		}
	});
	
	function handleLogout() {
		authStore.logout();
	}
</script>

<div class="min-h-screen bg-background">
	{#if isAuthenticated && currentPath !== '/login'}
		<!-- Sidebar -->
		<aside class="fixed left-0 top-0 z-40 h-screen w-64 border-r bg-card">
			<div class="flex h-full flex-col">
				<!-- Logo -->
				<div class="flex h-16 items-center border-b px-6">
					<h1 class="text-xl font-bold text-primary">OrthoTrack</h1>
				</div>
				
				<!-- Navigation -->
				<nav class="flex-1 space-y-1 px-3 py-4">
					<a
						href="/"
						class="flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors {currentPath === '/' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'}"
					>
						📊 Dashboard
					</a>
					<a
						href="/patients"
						class="flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors {currentPath.startsWith('/patients') ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'}"
					>
						👥 Pacientes
					</a>
					<a
						href="/devices"
						class="flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors {currentPath.startsWith('/devices') ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'}"
					>
						📱 Dispositivos
					</a>
					<a
						href="/alerts"
						class="flex items-center rounded-lg px-3 py-2 text-sm font-medium transition-colors {currentPath.startsWith('/alerts') ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'}"
					>
						🚨 Alertas
					</a>
				</nav>
				
				<!-- User Info -->
				<div class="border-t p-4">
					<div class="flex items-center justify-between">
						<div class="flex-1">
							<p class="text-sm font-medium">{$authStore.user?.name || 'Usuário'}</p>
							<p class="text-xs text-muted-foreground">{$authStore.user?.email}</p>
						</div>
						<button
							on:click={handleLogout}
							class="rounded-md px-3 py-1.5 text-sm text-muted-foreground hover:bg-accent"
						>
							Sair
						</button>
					</div>
				</div>
			</div>
		</aside>
		
		<!-- Main Content -->
		<main class="ml-64">
			<slot />
		</main>
	{:else}
		<!-- Login or public pages -->
		<main>
			<slot />
		</main>
	{/if}
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
	}
</style>


