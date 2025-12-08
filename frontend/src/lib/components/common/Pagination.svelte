<script lang="ts">
	import Button from '$lib/components/ui/Button.svelte';
	import { ChevronLeft, ChevronRight } from 'lucide-svelte';

	export let currentPage: number;
	export let totalPages: number;
	export let onPageChange: (page: number) => void;

	function handlePrevious() {
		if (currentPage > 1) {
			onPageChange(currentPage - 1);
		}
	}

	function handleNext() {
		if (currentPage < totalPages) {
			onPageChange(currentPage + 1);
		}
	}
</script>

<div class="flex items-center justify-between">
	<div class="text-sm text-muted-foreground">
		Página {currentPage} de {totalPages}
	</div>
	<div class="flex items-center gap-2">
		<Button
			on:click={handlePrevious}
			disabled={currentPage === 1}
			className="h-8 w-8 p-0"
		>
			<ChevronLeft class="h-4 w-4" />
		</Button>
		<div class="flex items-center gap-1">
			{#each Array(Math.min(5, totalPages)) as _, i}
				{@const page = currentPage <= 3 ? i + 1 : currentPage >= totalPages - 2 ? totalPages - 4 + i : currentPage - 2 + i}
				{#if page >= 1 && page <= totalPages}
					<Button
						on:click={() => onPageChange(page)}
						variant={page === currentPage ? 'default' : 'outline'}
						className="h-8 w-8 p-0"
					>
						{page}
					</Button>
				{/if}
			{/each}
		</div>
		<Button
			on:click={handleNext}
			disabled={currentPage === totalPages}
			className="h-8 w-8 p-0"
		>
			<ChevronRight class="h-4 w-4" />
		</Button>
	</div>
</div>

