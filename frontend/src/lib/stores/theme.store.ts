import { writable } from 'svelte/store';
import { browser } from '$app/environment';

type Theme = 'light' | 'dark' | 'system';

function createThemeStore() {
	const { subscribe, set, update } = writable<Theme>('system');

	return {
		subscribe,
		set,
		toggle: () => {
			update((current) => {
				if (current === 'light') return 'dark';
				if (current === 'dark') return 'system';
				return 'light';
			});
		},
		init: () => {
			if (!browser) return;
			
			// Check localStorage
			const stored = localStorage.getItem('theme') as Theme | null;
			if (stored && ['light', 'dark', 'system'].includes(stored)) {
				set(stored);
			}

			// Apply theme
			subscribe((theme) => {
				if (!browser) return;
				
				const root = document.documentElement;
				const isDark = theme === 'dark' || (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
				
				if (isDark) {
					root.classList.add('dark');
				} else {
					root.classList.remove('dark');
				}
				
				localStorage.setItem('theme', theme);
			})();
		}
	};
}

export const themeStore = createThemeStore();



