/**
 * Store para dados em tempo real
 */

import { writable } from 'svelte/store';
import { dashboardService } from '$lib/services/dashboard.service';
import type { RealtimeData } from '$lib/services/dashboard.service';

interface RealtimeState {
	telemetry: Map<string, any>;
	alerts: any[];
	isConnected: boolean;
	isLoading: boolean;
	error: string | null;
}

const initialState: RealtimeState = {
	telemetry: new Map(),
	alerts: [],
	isConnected: false,
	isLoading: false,
	error: null,
};

function createRealtimeStore() {
	const { subscribe, set, update } = writable<RealtimeState>(initialState);

	let pollInterval: NodeJS.Timeout | null = null;

	return {
		subscribe,

		startPolling: (deviceId?: string) => {
			if (pollInterval) {
				clearInterval(pollInterval);
			}

			// Poll imediatamente
			update((state) => ({ ...state, isLoading: true }));

			const poll = async () => {
				try {
					const data = await dashboardService.getRealtime(deviceId);
					update((state) => ({
						...state,
						telemetry: new Map(Object.entries(data.telemetry || {})),
						alerts: data.alerts || [],
						isConnected: true,
						isLoading: false,
						error: null,
					}));
				} catch (error) {
					update((state) => ({
						...state,
						isConnected: false,
						isLoading: false,
						error: error instanceof Error ? error.message : 'Erro ao buscar dados',
					}));
				}
			};

			poll();

			// Poll a cada 30 segundos
			pollInterval = setInterval(poll, 30000);
		},

		stopPolling: () => {
			if (pollInterval) {
				clearInterval(pollInterval);
				pollInterval = null;
			}
			update((state) => ({
				...state,
				isConnected: false,
			}));
		},
	};
}

export const realtimeStore = createRealtimeStore();

