/**
 * Store de alertas
 */

import { writable } from 'svelte/store';
import { alertsService, type Alert, type AlertFilters } from '$lib/services/alerts.service';

interface AlertsState {
	alerts: Alert[];
	loading: boolean;
	error: string | null;
	filters: AlertFilters;
	statistics: {
		total: number;
		by_severity: {
			critical: number;
			high: number;
			medium: number;
			low: number;
		};
		unresolved: number;
	} | null;
}

const initialState: AlertsState = {
	alerts: [],
	loading: false,
	error: null,
	filters: {},
	statistics: null,
};

function createAlertsStore() {
	const { subscribe, set, update } = writable<AlertsState>(initialState);

	return {
		subscribe,
		fetchAlerts: async (filters?: AlertFilters) => {
			update((state) => ({ ...state, loading: true, error: null, filters: filters || {} }));
			
			try {
				const alerts = await alertsService.getAlerts(filters);
				set({
					alerts,
					loading: false,
					error: null,
					filters: filters || {},
				});
			} catch (error) {
				const errorMessage = error instanceof Error ? error.message : 'Erro ao carregar alertas';
				update((state) => ({
					...state,
					loading: false,
					error: errorMessage,
				}));
			}
		},
		resolveAlert: async (id: number) => {
			try {
				const alert = await alertsService.resolveAlert(id);
				update((state) => ({
					...state,
					alerts: state.alerts.map((a) => (a.id === id ? alert : a)),
				}));
				return alert;
			} catch (error) {
				throw error;
			}
		},
		fetchStatistics: async () => {
			try {
				const stats = await alertsService.getStatistics();
				update((state) => ({
					...state,
					statistics: {
						total: stats.total,
						by_severity: stats.by_severity,
						unresolved: stats.unresolved,
					},
				}));
			} catch (error) {
				console.error('Erro ao carregar estatísticas:', error);
			}
		},
	};
}

export const alertsStore = createAlertsStore();


