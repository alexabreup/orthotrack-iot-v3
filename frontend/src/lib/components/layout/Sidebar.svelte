<script lang="ts">
	import { page } from '$app/stores';
	import { authStore } from '$lib/stores/auth.store';
	import {
		Home,
		Users,
		Smartphone,
		AlertCircle,
		BarChart3,
		Settings,
		LogOut,
	} from 'lucide-svelte';
	import { goto } from '$app/navigation';

	const navItems = [
		{ href: '/', label: 'Dashboard', icon: Home },
		{ href: '/patients', label: 'Pacientes', icon: Users },
		{ href: '/devices', label: 'Dispositivos', icon: Smartphone },
		{ href: '/alerts', label: 'Alertas', icon: AlertCircle },
		{ href: '/reports', label: 'Relatórios', icon: BarChart3 },
		{ href: '/settings', label: 'Configurações', icon: Settings },
	];

	function handleLogout() {
		authStore.logout();
	}
</script>

<aside class="fixed left-0 top-0 z-40 h-screen w-64 border-r border-border bg-card">
	<div class="flex h-full flex-col">
		<!-- Logo -->
		<div class="flex h-16 items-center border-b border-border px-6">
			<h1 class="text-xl font-bold text-foreground">OrthoTrack</h1>
		</div>

		<!-- Navigation -->
		<nav class="flex-1 space-y-1 overflow-y-auto px-3 py-4">
			{#each navItems as item}
				{@const Icon = item.icon}
				{@const isActive = $page.url.pathname === item.href || ($page.url.pathname.startsWith(item.href) && item.href !== '/')}
				<a
					href={item.href}
					class="flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors {isActive
						? 'bg-primary text-primary-foreground'
						: 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'}"
				>
					<Icon class="h-5 w-5" />
					{item.label}
				</a>
			{/each}
		</nav>

		<!-- User Info -->
		<div class="border-t border-border p-4">
			<div class="mb-3">
				<p class="text-sm font-medium text-foreground">{$authStore.user?.name || 'Usuário'}</p>
				<p class="text-xs text-muted-foreground">{$authStore.user?.email}</p>
			</div>
			<button
				on:click={handleLogout}
				class="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
			>
				<LogOut class="h-5 w-5" />
				Sair
			</button>
		</div>
	</div>
</aside>








