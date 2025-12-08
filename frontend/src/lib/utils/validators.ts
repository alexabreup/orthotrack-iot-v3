/**
 * Validadores de formulários
 */

export function validateCPF(cpf: string): boolean {
	const cleaned = cpf.replace(/\D/g, '');

	if (cleaned.length !== 11 || /^(\d)\1+$/.test(cleaned)) {
		return false;
	}

	let sum = 0;
	for (let i = 0; i < 9; i++) {
		sum += parseInt(cleaned.charAt(i)) * (10 - i);
	}
	let digit = 11 - (sum % 11);
	if (digit >= 10) digit = 0;
	if (digit !== parseInt(cleaned.charAt(9))) return false;

	sum = 0;
	for (let i = 0; i < 10; i++) {
		sum += parseInt(cleaned.charAt(i)) * (11 - i);
	}
	digit = 11 - (sum % 11);
	if (digit >= 10) digit = 0;
	if (digit !== parseInt(cleaned.charAt(10))) return false;

	return true;
}

export function validateEmail(email: string): boolean {
	const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
	return re.test(email);
}

export function validatePhone(phone: string): boolean {
	const cleaned = phone.replace(/\D/g, '');
	return cleaned.length === 10 || cleaned.length === 11;
}

export function validateMacAddress(mac: string): boolean {
	const re = /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/;
	return re.test(mac);
}

export function validateRequired(value: string | number | undefined | null): boolean {
	if (typeof value === 'string') {
		return value.trim().length > 0;
	}
	return value !== undefined && value !== null;
}




