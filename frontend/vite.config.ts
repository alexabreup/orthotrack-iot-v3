import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		host: '0.0.0.0',
		port: 5173
	},
	build: {
		outDir: 'build'
	},
	ssr: {
		noExternal: ['@tanstack/svelte-table']
	},
	test: {
		environment: 'node',
		globals: true,
		setupFiles: []
	}
});

