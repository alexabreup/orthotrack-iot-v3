<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { page } from '$app/stores';
	import { authStore } from '$lib/stores/auth.store';
	import { themeStore } from '$lib/stores/theme.store';
	import { websocketManager } from '$lib/services/websocket-manager.service';
	import { subscriptionManager } from '$lib/services/subscription-manager.service';
	import { goto } from '$app/navigation';
	import Sidebar from '$lib/components/layout/Sidebar.svelte';
	import Header from '$lib/components/layout/Header.svelte';
	import Footer from '$lib/components/layout/Footer.svelte';
	import ReconnectionIndicator from '$lib/components/common/ReconnectionIndicator.svelte';
	import '../app.css';
	
	let isAuthenticated = false;
	let currentPath = '';
	
	$: {
		isAuthenticated = $authStore.isAuthenticated;
		currentPath = $page.url.pathname;
	}
	
	// Handle route changes for subscription management
	$: {
		if (typeof window !== 'undefined') {
			subscriptionManager.handleRouteChange(currentPath);
		}
	}
	
	onMount(() => {
		// Inicializar tema
		themeStore.init();
		
		// Verificar autenticação apenas se não estiver na página de login
		if (currentPath !== '/login') {
			const isAuth = authStore.checkAuth();
			if (!isAuth) {
				goto('/login');
			} else {
				// Initialize WebSocket connection when authenticated
				initializeWebSocket();
			}
		}
	});

	onDestroy(() => {
		// Clean up subscriptions and WebSocket connection on app destroy
		subscriptionManager.unsubscribeAll();
		websocketManager.disconnect();
	});

	async function initializeWebSocket() {
		try {
			await websocketManager.initialize();
			console.log('WebSocket manager initialized');
			
			// Handle initial route subscriptions after WebSocket is connected
			subscriptionManager.handleRouteChange(currentPath);
		} catch (error) {
			console.error('Failed to initialize WebSocket manager:', error);
		}
	}
	
	// Reactive statement para verificar mudanças de autenticação
	$: {
		if (typeof window !== 'undefined' && currentPath !== '/login') {
			if (!$authStore.isAuthenticated) {
				// Clean up subscriptions and disconnect WebSocket when user logs out
				subscriptionManager.unsubscribeAll();
				websocketManager.disconnect();
				goto('/login');
			} else if ($authStore.isAuthenticated && websocketManager.getConnectionStatus() === 'disconnected') {
				// Initialize WebSocket when user logs in
				initializeWebSocket();
			}
		}
	}
</script>

<div class="flex min-h-screen flex-col bg-background">
	<!-- Reconnection indicator - always visible when needed -->
	<ReconnectionIndicator />
	
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




