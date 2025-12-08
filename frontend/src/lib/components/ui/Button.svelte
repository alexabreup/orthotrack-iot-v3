<script lang="ts">
	import { goto } from '$app/navigation';
	import { cn } from '$lib/utils';

	type Variant = 'default' | 'primary' | 'secondary' | 'danger' | 'ghost' | 'outline';
	type Size = 'sm' | 'md' | 'lg';
	type ButtonType = 'button' | 'submit' | 'reset';

	export let variant: Variant = 'default';
	export let size: Size = 'md';
	export let disabled = false;
	export let loading = false;
	export let type: ButtonType = 'button';
	export let className = '';
	export let href: string | undefined = undefined;
	export let title: string | undefined = undefined;
	export let ariaLabel: string | undefined = undefined;
	
	// Support both 'class' and 'className' props
	let klass = '';
	export { klass as class };
	
	let computedClassName = '';
	
	$: {
		const variants: Record<Variant, string> = {
			default: 'bg-primary text-primary-foreground hover:bg-primary/90',
			primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
			secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
			danger: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
			ghost: 'hover:bg-accent hover:text-accent-foreground',
			outline: 'border border-input bg-transparent hover:bg-accent hover:text-accent-foreground',
		};
		
		const sizes: Record<Size, string> = {
			sm: 'h-8 px-3 text-sm',
			md: 'h-10 px-4',
			lg: 'h-12 px-6 text-lg',
		};
		
		computedClassName = cn(
			'inline-flex items-center justify-center rounded-md font-medium transition-colors',
			'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
			'disabled:pointer-events-none disabled:opacity-50',
			variants[variant],
			sizes[size],
			className,
			klass
		);
	}

	function handleClick(e: MouseEvent) {
		if (href && !disabled && !loading) {
			e.preventDefault();
			goto(href);
		}
	}
</script>

{#if href}
	<a
		{href}
		class={computedClassName}
		class:opacity-50={loading || disabled}
		on:click={handleClick}
		role="button"
		tabindex={disabled ? -1 : 0}
		{title}
		aria-label={ariaLabel}
	>
		{#if loading}
			<svg class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
				<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
				<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
			</svg>
		{/if}
		<slot />
	</a>
{:else}
	<button {type} {disabled} class={computedClassName} class:opacity-50={loading || disabled} {title} aria-label={ariaLabel}>
		{#if loading}
			<svg class="animate-spin -ml-1 mr-2 h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
				<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
				<path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
			</svg>
		{/if}
		<slot />
	</button>
{/if}

