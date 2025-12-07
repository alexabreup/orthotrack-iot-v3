/**
 * Cliente HTTP base para comunicação com a API
 */

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080';

export interface ApiError {
	message: string;
	status?: number;
}

export class ApiClient {
	private baseURL: string;

	constructor(baseURL: string = API_BASE_URL) {
		this.baseURL = baseURL.replace(/\/$/, '');
	}

	private getAuthToken(): string | null {
		if (typeof window === 'undefined') return null;
		return localStorage.getItem('auth_token');
	}

	private async request<T>(
		endpoint: string,
		options: RequestInit = {}
	): Promise<T> {
		const token = this.getAuthToken();
		const headers: HeadersInit = {
			'Content-Type': 'application/json',
			...options.headers,
		};

		if (token) {
			headers['Authorization'] = `Bearer ${token}`;
		}

		const url = `${this.baseURL}${endpoint}`;
		const response = await fetch(url, {
			...options,
			headers,
		});

		if (!response.ok) {
			const error: ApiError = {
				message: `HTTP error! status: ${response.status}`,
				status: response.status,
			};

			try {
				const data = await response.json();
				error.message = data.error || data.message || error.message;
			} catch {
				// Se não conseguir parsear JSON, usar mensagem padrão
			}

			// Se não autorizado, limpar token
			if (response.status === 401) {
				localStorage.removeItem('auth_token');
				localStorage.removeItem('auth_user');
				if (typeof window !== 'undefined') {
					window.location.href = '/login';
				}
			}

			throw error;
		}

		// Se resposta vazia, retornar null
		const contentType = response.headers.get('content-type');
		if (!contentType || !contentType.includes('application/json')) {
			return null as T;
		}

		return response.json();
	}

	async get<T>(endpoint: string): Promise<T> {
		return this.request<T>(endpoint, { method: 'GET' });
	}

	async post<T>(endpoint: string, data?: unknown): Promise<T> {
		return this.request<T>(endpoint, {
			method: 'POST',
			body: data ? JSON.stringify(data) : undefined,
		});
	}

	async put<T>(endpoint: string, data?: unknown): Promise<T> {
		return this.request<T>(endpoint, {
			method: 'PUT',
			body: data ? JSON.stringify(data) : undefined,
		});
	}

	async delete<T>(endpoint: string): Promise<T> {
		return this.request<T>(endpoint, { method: 'DELETE' });
	}
}

export const apiClient = new ApiClient();


