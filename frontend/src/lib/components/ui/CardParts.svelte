<!-- CardHeader -->
<script lang="ts" context="module">
	export let className = '';
</script>

<div class="flex flex-col space-y-1.5 p-6 {className}">
	<slot />
</div>

<!-- CardTitle -->
<script lang="ts" context="module">
	export let className = '';
</script>

<h3 class="text-2xl font-semibold leading-none tracking-tight {className}">
	<slot />
</h3>

<!-- CardDescription -->
<script lang="ts" context="module">
	export let className = '';
</script>

<p class="text-sm text-muted-foreground {className}">
	<slot />
</p>

<!-- CardContent -->
<script lang="ts" context="module">
	export let className = '';
</script>

<div class="p-6 pt-0 {className}">
	<slot />
</div>

<!-- CardFooter -->
<script lang="ts" context="module">
	export let className = '';
</script>

<div class="flex items-center p-6 pt-0 {className}">
	<slot />
</div>








