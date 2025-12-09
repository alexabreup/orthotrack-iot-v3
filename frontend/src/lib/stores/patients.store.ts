/**
 * Store de pacientes
 */

import { writable } from 'svelte/store';
import { patientsService, type Patient } from '$lib/services/patients.service';

interface PatientsState {
	patients: Patient[];
	loading: boolean;
	error: string | null;
	selectedPatient: Patient | null;
}

const initialState: PatientsState = {
	patients: [],
	loading: false,
	error: null,
	selectedPatient: null,
};

function createPatientsStore() {
	const { subscribe, set, update } = writable<PatientsState>(initialState);

	return {
		subscribe,
		fetchPatients: async () => {
			update((state) => ({ ...state, loading: true, error: null }));
			
			try {
				const patients = await patientsService.getPatients();
				set({
					patients,
					loading: false,
					error: null,
					selectedPatient: null,
				});
			} catch (error) {
				const errorMessage = error instanceof Error ? error.message : 'Erro ao carregar pacientes';
				update((state) => ({
					...state,
					loading: false,
					error: errorMessage,
				}));
			}
		},
		createPatient: async (data: Parameters<typeof patientsService.createPatient>[0]) => {
			try {
				const patient = await patientsService.createPatient(data);
				update((state) => ({
					...state,
					patients: [...state.patients, patient],
				}));
				return patient;
			} catch (error) {
				throw error;
			}
		},
		updatePatient: async (id: number, data: Parameters<typeof patientsService.updatePatient>[1]) => {
			try {
				const patient = await patientsService.updatePatient(id, data);
				update((state) => ({
					...state,
					patients: state.patients.map((p) => (p.id === id ? patient : p)),
					selectedPatient: state.selectedPatient?.id === id ? patient : state.selectedPatient,
				}));
				return patient;
			} catch (error) {
				throw error;
			}
		},
		deletePatient: async (id: number) => {
			try {
				await patientsService.deletePatient(id);
				update((state) => ({
					...state,
					patients: state.patients.filter((p) => p.id !== id),
					selectedPatient: state.selectedPatient?.id === id ? null : state.selectedPatient,
				}));
			} catch (error) {
				throw error;
			}
		},
		setSelectedPatient: (patient: Patient | null) => {
			update((state) => ({ ...state, selectedPatient: patient }));
		},
	};
}

export const patientsStore = createPatientsStore();











