/**
 * Store de autenticação
 */

import { writable, derived } from 'svelte/store';
import { authService, type User } from '$lib/services/auth.service';
import { goto } from '$app/navigation';

interface AuthState {
	isAuthenticated: boolean;
	user: User | null;
	loading: boolean;
	error: string | null;
}

const initialState: AuthState = {
	isAuthenticated: false,
	user: null,
	loading: false,
	error: null,
};

function createAuthStore() {
	const { subscribe, set, update } = writable<AuthState>(initialState);

	// Verificar autenticação ao inicializar
	if (typeof window !== 'undefined') {
		const user = authService.getUser();
		const isAuthenticated = authService.isAuthenticated();
		
		if (isAuthenticated && user) {
			set({
				isAuthenticated: true,
				user,
				loading: false,
				error: null,
			});
		}
	}

	return {
		subscribe,
		login: async (email: string, password: string) => {
			update((state) => ({ ...state, loading: true, error: null }));
			
			try {
				const response = await authService.login(email, password);
				console.log('Auth service login response:', response);
				
				set({
					isAuthenticated: true,
					user: response.user,
					loading: false,
					error: null,
				});
				
				console.log('Auth store updated, attempting redirect...');
				goto('/');
			} catch (error) {
				console.error('Login error:', error);
				const errorMessage = error instanceof Error ? error.message : 'Erro ao fazer login';
				set({
					isAuthenticated: false,
					user: null,
					loading: false,
					error: errorMessage,
				});
				throw error;
			}
		},
		logout: () => {
			authService.logout();
			set(initialState);
			goto('/login');
		},
		checkAuth: () => {
			const isAuthenticated = authService.isAuthenticated();
			const user = authService.getUser();
			
			set({
				isAuthenticated,
				user,
				loading: false,
				error: null,
			});
			
			return isAuthenticated;
		},
	};
}

export const authStore = createAuthStore();

export const isAuthenticated = derived(authStore, ($auth) => $auth.isAuthenticated);
export const currentUser = derived(authStore, ($auth) => $auth.user);











