<script lang="ts">
	import { onMount, onDestroy } from 'svelte';
	import { websocketManager } from '$lib/services/websocket-manager.service';
	
	let isReconnecting = false;
	let reconnectAttempt = 0;
	let showSuccessMessage = false;
	let showErrorMessage = false;
	let errorMessage = '';
	let successTimeout: number | null = null;
	let errorTimeout: number | null = null;
	
	// Subscribe to WebSocket manager state
	let wsState = { status: 'disconnected' };
	
	function handleReconnecting(data: { attempt: number; delay: number }) {
		isReconnecting = true;
		reconnectAttempt = data.attempt;
		showSuccessMessage = false;
		showErrorMessage = false;
		
		// Clear any existing timeouts
		if (successTimeout) {
			clearTimeout(successTimeout);
			successTimeout = null;
		}
		if (errorTimeout) {
			clearTimeout(errorTimeout);
			errorTimeout = null;
		}
	}
	
	function handleConnected() {
		if (isReconnecting) {
			// Show success message for 3 seconds
			isReconnecting = false;
			showSuccessMessage = true;
			showErrorMessage = false;
			
			successTimeout = window.setTimeout(() => {
				showSuccessMessage = false;
				successTimeout = null;
			}, 3000);
		}
	}
	
	function handleDisconnected() {
		showSuccessMessage = false;
		if (successTimeout) {
			clearTimeout(successTimeout);
			successTimeout = null;
		}
	}
	
	function handleError(data: { error: string }) {
		showErrorMessage = true;
		errorMessage = data.error;
		isReconnecting = false;
		showSuccessMessage = false;
		
		// Auto-hide error message after 5 seconds
		errorTimeout = window.setTimeout(() => {
			showErrorMessage = false;
			errorTimeout = null;
		}, 5000);
	}
	
	onMount(() => {
		// Subscribe to WebSocket manager state
		const unsubscribe = websocketManager.state.subscribe(state => {
			wsState = state;
			
			if (state.status === 'reconnecting') {
				handleReconnecting({ attempt: state.reconnectAttempt || 0, delay: 0 });
			} else if (state.status === 'connected') {
				handleConnected();
			} else if (state.status === 'disconnected') {
				handleDisconnected();
			} else if (state.status === 'error' && state.error) {
				handleError({ error: state.error });
			}
		});
		
		// Also listen to direct events from the WebSocket client
		websocketManager.on('reconnecting', handleReconnecting);
		websocketManager.on('connected', handleConnected);
		websocketManager.on('disconnected', handleDisconnected);
		
		return unsubscribe;
	});
	
	onDestroy(() => {
		websocketManager.off('reconnecting', handleReconnecting);
		websocketManager.off('connected', handleConnected);
		websocketManager.off('disconnected', handleDisconnected);
		
		if (successTimeout) {
			clearTimeout(successTimeout);
		}
		if (errorTimeout) {
			clearTimeout(errorTimeout);
		}
	});
</script>

{#if isReconnecting}
	<div class="fixed top-0 left-0 right-0 z-50 bg-yellow-500 text-white px-4 py-2 text-center text-sm font-medium shadow-md">
		<div class="flex items-center justify-center gap-2">
			<div class="animate-spin rounded-full h-4 w-4 border-2 border-white border-t-transparent"></div>
			<span>Reconnecting... (Attempt {reconnectAttempt})</span>
		</div>
	</div>
{/if}

{#if showSuccessMessage}
	<div class="fixed top-0 left-0 right-0 z-50 bg-green-500 text-white px-4 py-2 text-center text-sm font-medium shadow-md">
		<div class="flex items-center justify-center gap-2">
			<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
			</svg>
			<span>Connection restored successfully</span>
		</div>
	</div>
{/if}

{#if showErrorMessage}
	<div class="fixed top-0 left-0 right-0 z-50 bg-red-500 text-white px-4 py-2 text-center text-sm font-medium shadow-md">
		<div class="flex items-center justify-center gap-2">
			<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"></path>
			</svg>
			<span>{errorMessage}</span>
		</div>
	</div>
{/if}