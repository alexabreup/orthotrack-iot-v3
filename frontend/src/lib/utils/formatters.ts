/**
 * Formatadores de dados
 */

export function formatDate(date: string | Date): string {
	return new Date(date).toLocaleDateString('pt-BR');
}

export function formatDateTime(date: string | Date): string {
	return new Date(date).toLocaleString('pt-BR');
}

export function formatRelativeTime(date: string | Date): string {
	const now = new Date();
	const then = new Date(date);
	const diffMs = now.getTime() - then.getTime();
	const diffMins = Math.floor(diffMs / 60000);

	if (diffMins < 1) return 'agora mesmo';
	if (diffMins < 60) return `${diffMins}min atrás`;

	const diffHours = Math.floor(diffMins / 60);
	if (diffHours < 24) return `${diffHours}h atrás`;

	const diffDays = Math.floor(diffHours / 24);
	return `${diffDays}d atrás`;
}

export function formatDuration(seconds: number): string {
	const hours = Math.floor(seconds / 3600);
	const minutes = Math.floor((seconds % 3600) / 60);
	return `${hours}h ${minutes}min`;
}

export function formatPercentage(value: number | undefined | null): string {
	if (value === undefined || value === null) return '0.0%';
	return `${value.toFixed(1)}%`;
}

export function formatBatteryLevel(level: number): string {
	return `${level}%`;
}

export function formatCPF(cpf: string): string {
	const cleaned = cpf.replace(/\D/g, '');
	if (cleaned.length !== 11) return cpf;
	return cleaned.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
}

export function formatPhone(phone: string): string {
	const cleaned = phone.replace(/\D/g, '');
	if (cleaned.length === 11) {
		return cleaned.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
	}
	if (cleaned.length === 10) {
		return cleaned.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
	}
	return phone;
}




