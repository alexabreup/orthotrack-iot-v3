import { Preferences } from '@capacitor/preferences';
import { Logger } from '../utils/logger';
import { TelemetryData, DeviceCommand } from '../types/device';

export class APIService {
    private baseURL: string;
    private apiKey: string | null = null;
    private logger: Logger;

    constructor(baseURL: string, logger: Logger) {
        this.baseURL = baseURL.replace(/\/$/, '');
        this.logger = logger;
    }

    async setApiKey(apiKey: string) {
        this.apiKey = apiKey;
        await Preferences.set({ key: 'device_api_key', value: apiKey });
    }

    private async getApiKey(): Promise<string | null> {
        if (this.apiKey) return this.apiKey;
        
        const { value } = await Preferences.get({ key: 'device_api_key' });
        this.apiKey = value || null;
        return this.apiKey;
    }

    private async getHeaders(): Promise<Record<string, string>> {
        const headers: Record<string, string> = {
            'Content-Type': 'application/json',
        };

        const apiKey = await this.getApiKey();
        if (apiKey) {
            headers['X-Device-API-Key'] = apiKey;
        }

        return headers;
    }

    async checkHealth(): Promise<boolean> {
        try {
            const response = await fetch(`${this.baseURL}/api/v1/health`, {
                method: 'GET',
                headers: await this.getHeaders(),
            });

            return response.ok;
        } catch (error) {
            this.logger.error(`Health check failed: ${error}`);
            return false;
        }
    }

    async sendTelemetry(data: TelemetryData): Promise<boolean> {
        try {
            const response = await fetch(`${this.baseURL}/api/v1/devices/telemetry`, {
                method: 'POST',
                headers: await this.getHeaders(),
                body: JSON.stringify(data),
            });

            if (response.ok) {
                this.logger.info(`Telemetria enviada: ${data.device_id}`);
                return true;
            }

            return false;
        } catch (error) {
            this.logger.error(`Erro ao enviar telemetria: ${error}`);
            return false;
        }
    }

    async updateDeviceStatus(deviceId: string, status: string, batteryLevel?: number, signalStrength?: number): Promise<boolean> {
        try {
            const response = await fetch(`${this.baseURL}/api/v1/devices/status`, {
                method: 'POST',
                headers: await this.getHeaders(),
                body: JSON.stringify({
                    device_id: deviceId,
                    status,
                    battery_level: batteryLevel,
                    signal_strength: signalStrength,
                }),
            });

            return response.ok;
        } catch (error) {
            this.logger.error(`Erro ao atualizar status: ${error}`);
            return false;
        }
    }

    async sendDeviceAlert(deviceId: string, alertType: string, severity: string, message: string, value?: number): Promise<boolean> {
        try {
            const response = await fetch(`${this.baseURL}/api/v1/devices/alerts`, {
                method: 'POST',
                headers: await this.getHeaders(),
                body: JSON.stringify({
                    brace_id: deviceId,
                    type: alertType,
                    severity,
                    title: `Alerta do Dispositivo ${deviceId}`,
                    message,
                    value,
                }),
            });

            return response.ok;
        } catch (error) {
            this.logger.error(`Erro ao enviar alerta: ${error}`);
            return false;
        }
    }

    async sendCommandResponse(commandId: number, status: string, response?: any, error?: string): Promise<boolean> {
        try {
            const httpResponse = await fetch(`${this.baseURL}/api/v1/devices/commands/response`, {
                method: 'POST',
                headers: await this.getHeaders(),
                body: JSON.stringify({
                    command_id: commandId,
                    status,
                    response,
                    error,
                }),
            });

            return httpResponse.ok;
        } catch (error) {
            this.logger.error(`Erro ao enviar resposta de comando: ${error}`);
            return false;
        }
    }
}

