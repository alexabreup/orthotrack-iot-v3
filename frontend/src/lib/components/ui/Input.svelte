<script lang="ts">
	import { cn } from '$lib/utils';
	import { createEventDispatcher } from 'svelte';

	export let type: string = 'text';
	export let placeholder = '';
	export let value: string | number = '';
	export let disabled = false;
	export let required = false;
	export let className = '';
	export let id: string | undefined = undefined;
	
	// HTML input attributes
	export let min: string | number | undefined = undefined;
	export let max: string | number | undefined = undefined;
	export let step: string | number | undefined = undefined;
	export let pattern: string | undefined = undefined;
	export let autocomplete: string | undefined = undefined;
	export let readonly: boolean = false;

	const dispatch = createEventDispatcher();

	// Internal value for two-way binding
	let internalValue = String(value);
	
	// Sync external value to internal when it changes (for bind:value to work)
	$: {
		const stringValue = String(value);
		if (stringValue !== internalValue) {
			internalValue = stringValue;
		}
	}

	function handleInput(e: Event) {
		const target = e.target as HTMLInputElement;
		internalValue = target.value;
		// Update the exported value to make bind:value work
		value = internalValue;
		dispatch('input', e);
	}

	function handleChange(e: Event) {
		dispatch('change', e);
	}
</script>

<input
	type={type}
	{placeholder}
	value={internalValue}
	on:input={handleInput}
	on:change={handleChange}
	{disabled}
	{required}
	{readonly}
	{min}
	{max}
	{step}
	{pattern}
	{autocomplete}
	{id}
	class={cn(
		'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm',
		'ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium',
		'placeholder:text-muted-foreground',
		'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
		'disabled:cursor-not-allowed disabled:opacity-50',
		className
	)}
/>

