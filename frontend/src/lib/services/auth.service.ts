/**
 * Serviço de autenticação
 */

import { apiClient } from './api';

export interface LoginRequest {
	email: string;
	password: string;
}

export interface LoginResponse {
	token: string;
	expires_at: string;
	user: User;
}

export interface User {
	id: number;
	uuid: string;
	name: string;
	email: string;
	role: string;
	institution_id: number;
}

export class AuthService {
	async login(email: string, password: string): Promise<LoginResponse> {
		// O backend aceita "email" como campo, mas pode ser username também
		const response = await apiClient.post<LoginResponse>('/api/v1/auth/login', {
			email: email, // Pode ser "admin" ou email
			password,
		});

		// Armazenar token e usuário
		if (typeof window !== 'undefined') {
			localStorage.setItem('auth_token', response.token);
			localStorage.setItem('auth_user', JSON.stringify(response.user));
		}

		return response;
	}

	logout(): void {
		if (typeof window !== 'undefined') {
			localStorage.removeItem('auth_token');
			localStorage.removeItem('auth_user');
		}
	}

	getUser(): User | null {
		if (typeof window === 'undefined') return null;
		const userStr = localStorage.getItem('auth_user');
		if (!userStr) return null;
		try {
			return JSON.parse(userStr);
		} catch {
			return null;
		}
	}

	getToken(): string | null {
		if (typeof window === 'undefined') return null;
		return localStorage.getItem('auth_token');
	}

	isAuthenticated(): boolean {
		return this.getToken() !== null;
	}
}

export const authService = new AuthService();




