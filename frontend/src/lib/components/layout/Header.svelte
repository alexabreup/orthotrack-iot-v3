<script lang="ts">
	import { Bell } from 'lucide-svelte';
	import { authStore } from '$lib/stores/auth.store';
	import ThemeToggle from '$lib/components/ui/ThemeToggle.svelte';
</script>

<header class="sticky top-0 z-30 flex h-16 items-center border-b border-border bg-card px-6">
	<div class="flex flex-1 items-center justify-between">
		<div class="flex items-center gap-4">
			<h2 class="text-lg font-semibold">Dashboard</h2>
		</div>
		<div class="flex items-center gap-4">
			<ThemeToggle />
			<button
				class="relative rounded-lg p-2 text-muted-foreground transition-colors hover:bg-accent hover:text-accent-foreground"
				aria-label="Notificações"
			>
				<Bell class="h-5 w-5" />
				<span
					class="absolute right-1 top-1 h-2 w-2 rounded-full bg-destructive"
					aria-hidden="true"
				></span>
			</button>
			<div class="flex items-center gap-2">
				<div class="h-8 w-8 rounded-full bg-primary flex items-center justify-center text-primary-foreground text-sm font-medium">
					{($authStore.user?.name || 'U').charAt(0).toUpperCase()}
				</div>
			</div>
		</div>
	</div>
</header>


