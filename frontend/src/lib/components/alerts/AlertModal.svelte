<script lang="ts">
	import Card from '$lib/components/ui/Card.svelte';
	import CardHeader from '$lib/components/ui/CardHeader.svelte';
	import CardTitle from '$lib/components/ui/CardTitle.svelte';
	import CardContent from '$lib/components/ui/CardContent.svelte';
	import Button from '$lib/components/ui/Button.svelte';
	import AlertBadge from './AlertBadge.svelte';
	import { formatDateTime } from '$lib/utils/formatters';
	import { ALERT_ICONS } from '$lib/utils/constants';
	import type { Alert } from '$lib/types/alert';

	export let alert: Alert | null = null;
	export let open = false;
	export let onClose: () => void;
	export let onResolve: ((id: number, notes: string) => void) | null = null;

	let notes = '';

	function handleResolve() {
		if (alert && onResolve) {
			onResolve(alert.id, notes);
			notes = '';
			onClose();
		}
	}
</script>

{#if open && alert}
	<div
		class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
		on:click={onClose}
		role="button"
		tabindex="0"
		on:keydown={(e) => {
			if (e.key === 'Escape' || e.key === 'Enter') {
				onClose();
			}
		}}
		aria-label="Fechar modal"
	>
		<div on:click|stopPropagation>
			<Card class="w-full max-w-2xl max-h-[90vh] overflow-y-auto">
			<CardHeader>
				<div class="flex items-center gap-3">
					<span class="text-3xl">{ALERT_ICONS[alert.type]}</span>
					<div class="flex-1">
						<CardTitle>{alert.title}</CardTitle>
						<div class="mt-2">
							<AlertBadge severity={alert.severity} />
						</div>
					</div>
					<Button variant="ghost" size="sm" on:click={onClose}>✕</Button>
				</div>
			</CardHeader>
			<CardContent class="space-y-4">
				<div>
					<p class="text-sm font-medium">Mensagem</p>
					<p class="text-sm text-muted-foreground mt-1">{alert.message}</p>
				</div>

				<div class="grid grid-cols-2 gap-4">
					<div>
						<p class="text-sm font-medium">Tipo</p>
						<p class="text-sm text-muted-foreground mt-1">{alert.type}</p>
					</div>
					<div>
						<p class="text-sm font-medium">Criado em</p>
						<p class="text-sm text-muted-foreground mt-1">
							{formatDateTime(alert.created_at)}
						</p>
					</div>
					{#if alert.value !== undefined}
						<div>
							<p class="text-sm font-medium">Valor</p>
							<p class="text-sm text-muted-foreground mt-1">{alert.value}</p>
						</div>
					{/if}
					{#if alert.threshold !== undefined}
						<div>
							<p class="text-sm font-medium">Threshold</p>
							<p class="text-sm text-muted-foreground mt-1">{alert.threshold}</p>
						</div>
					{/if}
				</div>

				{#if alert.resolved}
					<div class="rounded-lg border border-success bg-success/10 p-4">
						<p class="text-sm font-medium text-success">Resolvido</p>
						{#if alert.resolved_at}
							<p class="text-sm text-muted-foreground mt-1">
								{formatDateTime(alert.resolved_at)}
							</p>
						{/if}
						{#if alert.notes}
							<p class="text-sm text-muted-foreground mt-2">{alert.notes}</p>
						{/if}
					</div>
				{:else if onResolve}
					<div>
						<label for="notes" class="mb-2 block text-sm font-medium">
							Notas de Resolução
						</label>
						<textarea
							id="notes"
							bind:value={notes}
							rows="3"
							class="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
							placeholder="Adicione notas sobre a resolução do alerta..."
						></textarea>
					</div>
				{/if}

				<div class="flex justify-end gap-4">
					<Button variant="outline" on:click={onClose}>Fechar</Button>
					{#if !alert.resolved && onResolve}
						<Button on:click={handleResolve}>Resolver Alerta</Button>
					{/if}
				</div>
			</CardContent>
		</Card>
		</div>
	</div>
{/if}

