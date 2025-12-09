/**
 * Store de dispositivos
 */

import { writable } from 'svelte/store';
import { devicesService, type Device } from '$lib/services/devices.service';

interface DevicesState {
	devices: Device[];
	loading: boolean;
	error: string | null;
	selectedDevice: Device | null;
}

const initialState: DevicesState = {
	devices: [],
	loading: false,
	error: null,
	selectedDevice: null,
};

function createDevicesStore() {
	const { subscribe, set, update } = writable<DevicesState>(initialState);

	return {
		subscribe,
		fetchDevices: async () => {
			update((state) => ({ ...state, loading: true, error: null }));
			
			try {
				const devices = await devicesService.getDevices();
				set({
					devices,
					loading: false,
					error: null,
					selectedDevice: null,
				});
			} catch (error) {
				const errorMessage = error instanceof Error ? error.message : 'Erro ao carregar dispositivos';
				update((state) => ({
					...state,
					loading: false,
					error: errorMessage,
				}));
			}
		},
		createDevice: async (data: Parameters<typeof devicesService.createDevice>[0]) => {
			try {
				const device = await devicesService.createDevice(data);
				update((state) => ({
					...state,
					devices: [...state.devices, device],
				}));
				return device;
			} catch (error) {
				throw error;
			}
		},
		updateDevice: async (id: number, data: Parameters<typeof devicesService.updateDevice>[1]) => {
			try {
				const device = await devicesService.updateDevice(id, data);
				update((state) => ({
					...state,
					devices: state.devices.map((d) => (d.id === id ? device : d)),
					selectedDevice: state.selectedDevice?.id === id ? device : state.selectedDevice,
				}));
				return device;
			} catch (error) {
				throw error;
			}
		},
		deleteDevice: async (id: number) => {
			try {
				await devicesService.deleteDevice(id);
				update((state) => ({
					...state,
					devices: state.devices.filter((d) => d.id !== id),
					selectedDevice: state.selectedDevice?.id === id ? null : state.selectedDevice,
				}));
			} catch (error) {
				throw error;
			}
		},
		setSelectedDevice: (device: Device | null) => {
			update((state) => ({ ...state, selectedDevice: device }));
		},
	};
}

export const devicesStore = createDevicesStore();











