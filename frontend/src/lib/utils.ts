import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Função cn() - Merge de classes Tailwind CSS
 * Essencial para o shadcn-svelte funcionar corretamente
 * Combina classes do clsx e tailwind-merge para evitar conflitos
 */
export function cn(...inputs: ClassValue[]) {
	return twMerge(clsx(inputs));
}







