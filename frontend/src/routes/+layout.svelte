<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { authStore } from '$lib/stores/auth.store';
	import { themeStore } from '$lib/stores/theme.store';
	import { goto } from '$app/navigation';
	import Sidebar from '$lib/components/layout/Sidebar.svelte';
	import Header from '$lib/components/layout/Header.svelte';
	import Footer from '$lib/components/layout/Footer.svelte';
	import '../app.css';
	
	let isAuthenticated = false;
	let currentPath = '';
	
	$: {
		isAuthenticated = $authStore.isAuthenticated;
		currentPath = $page.url.pathname;
	}
	
	onMount(() => {
		// Inicializar tema
		themeStore.init();
		
		// Verificar autenticação apenas se não estiver na página de login
		if (currentPath !== '/login') {
			const isAuth = authStore.checkAuth();
			if (!isAuth) {
				goto('/login');
			}
		}
	});
	
	// Reactive statement para verificar mudanças de autenticação
	$: {
		if (typeof window !== 'undefined' && currentPath !== '/login') {
			if (!$authStore.isAuthenticated) {
				goto('/login');
			}
		}
	}
</script>

<div class="flex min-h-screen flex-col bg-background">
	{#if isAuthenticated && currentPath !== '/login'}
		<div class="flex flex-1 overflow-hidden">
			<Sidebar />
			<div class="flex flex-1 flex-col overflow-hidden ml-64">
				<Header />
				<main class="flex-1 overflow-y-auto p-6">
					<slot />
				</main>
				<Footer />
			</div>
		</div>
	{:else}
		<!-- Login or public pages -->
		<main class="flex-1">
			<slot />
		</main>
		<Footer />
	{/if}
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
	}
</style>




