/**
 * Store de autenticação
 */

import { writable, derived } from 'svelte/store';
import { goto } from '$app/navigation';
import api, { setAuthToken, getAuthToken } from '$lib/api/client';

// Types
export interface User {
  id: number;
  uuid: string;
  name: string;
  email: string;
  role: string;
  permissions?: any;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

// Initial state
const initialState: AuthState = {
  user: null,
  token: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,
};

// Create store
function createAuthStore() {
  const { subscribe, set, update } = writable<AuthState>(initialState);
  
  return {
    subscribe,
    
    // Initialize from localStorage
    init: () => {
      const token = getAuthToken();
      if (token) {
        update(state => ({ ...state, token, isAuthenticated: true, isLoading: true }));
        authStore.verifyToken();
      }
    },
    
    // Login
    login: async (email: string, password: string) => {
      update(state => ({ ...state, isLoading: true, error: null }));
      
      try {
        const response = await api.post<{ token: string; user: User }>(
          '/auth/login',
          { email, password },
          { skipAuth: true }
        );
        
        setAuthToken(response.token);
        
        update(state => ({
          ...state,
          user: response.user,
          token: response.token,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        }));
        
        goto('/dashboard');
        
        return response;
      } catch (error: any) {
        const message = error.data?.error || error.message || 'Erro ao fazer login';
        
        update(state => ({
          ...state,
          isLoading: false,
          error: message,
        }));
        
        throw new Error(message);
      }
    },
    
    // Logout
    logout: async () => {
      try {
        await api.post('/auth/logout');
      } catch (error) {
        console.error('Logout error:', error);
      } finally {
        setAuthToken(null);
        set(initialState);
        goto('/login');
      }
    },
    
    // Verify token
    verifyToken: async () => {
      try {
        const user = await api.get<User>('/auth/me');
        
        update(state => ({
          ...state,
          user,
          isAuthenticated: true,
          isLoading: false,
        }));
      } catch (error) {
        console.error('Token verification failed:', error);
        setAuthToken(null);
        set(initialState);
        goto('/login');
      }
    },
    
    // Clear error
    clearError: () => {
      update(state => ({ ...state, error: null }));
    },
  };
}

export const authStore = createAuthStore();

// Initialize on load
if (typeof window !== 'undefined') {
  authStore.init();
}

export const isAuthenticated = derived(authStore, ($auth) => $auth.isAuthenticated);
export const currentUser = derived(authStore, ($auth) => $auth.user);











