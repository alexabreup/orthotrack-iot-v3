<script lang="ts">
	import Input from '$lib/components/ui/Input.svelte';
	import { Search } from 'lucide-svelte';
	import { debounce } from '$lib/utils/helpers';

	export let placeholder: string = 'Buscar...';
	export let value: string = '';
	export let onSearch: (query: string) => void;

	let searchValue = value;

	const debouncedSearch = debounce((query: string) => {
		onSearch(query);
	}, 300);

	function handleInput(e: Event) {
		const target = e.target as HTMLInputElement;
		searchValue = target.value;
		debouncedSearch(searchValue);
	}
</script>

<div class="relative">
	<Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
	<Input
		type="text"
		placeholder={placeholder}
		value={searchValue}
		on:input={handleInput}
		className="pl-10"
	/>
</div>

