<script lang="ts">
	import { themeStore } from '$lib/stores/theme.store';
	import { onMount } from 'svelte';
	import { Sun, Moon, Monitor } from 'lucide-svelte';
	import Button from './Button.svelte';

	let currentTheme: 'light' | 'dark' | 'system' = 'system';

	onMount(() => {
		themeStore.init();
		const unsubscribe = themeStore.subscribe((theme) => {
			currentTheme = theme as 'light' | 'dark' | 'system';
		});
		return unsubscribe;
	});

	function toggleTheme() {
		themeStore.toggle();
	}

	function getIcon() {
		if (currentTheme === 'light') {
			return Sun;
		} else if (currentTheme === 'dark') {
			return Moon;
		} else {
			return Monitor;
		}
	}

	function getLabel() {
		if (currentTheme === 'light') {
			return 'Tema Claro';
		} else if (currentTheme === 'dark') {
			return 'Tema Escuro';
		} else {
			return 'Tema do Sistema';
		}
	}
</script>

	<Button
		variant="ghost"
		size="sm"
		on:click={toggleTheme}
		class="gap-2"
		title={getLabel()}
		ariaLabel={getLabel()}
	>
	<svelte:component this={getIcon()} class="h-4 w-4" />
	<span class="hidden sm:inline">{getLabel()}</span>
</Button>

