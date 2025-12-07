<script lang="ts">
	export let type = 'text';
	export let placeholder = '';
	export let value = '';
	export let disabled = false;
	export let required = false;
	export let className = '';
	export let id: string | undefined = undefined;
	
	let inputId = id || `input-${Math.random().toString(36).substr(2, 9)}`;
</script>

<input
	{type}
	{placeholder}
	{value}
	{disabled}
	{required}
	{id}={inputId}
	class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 {className}"
	on:input={(e) => value = e.currentTarget.value}
	on:change
/>

