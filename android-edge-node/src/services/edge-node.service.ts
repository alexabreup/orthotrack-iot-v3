import { APIService } from './api.service';
import { BLEService } from './ble.service';
import { Logger } from '../utils/logger';
import { ESP32Device, TelemetryData } from '../types/device';

export class EdgeNodeService {
    private apiService: APIService;
    private bleService: BLEService;
    private logger: Logger;
    private syncInterval: number | null = null;
    private telemetryQueue: TelemetryData[] = [];

    constructor(apiService: APIService, bleService: BLEService, logger: Logger) {
        this.apiService = apiService;
        this.bleService = bleService;
        this.logger = logger;

        // Escutar eventos de telemetria
        window.addEventListener('telemetry', this.handleTelemetry.bind(this) as EventListener);
    }

    async scanDevices(): Promise<ESP32Device[]> {
        return await this.bleService.scanDevices();
    }

    async connectDevice(deviceId: string): Promise<boolean> {
        const connected = await this.bleService.connectDevice(deviceId);
        if (connected) {
            this.startSync();
        }
        return connected;
    }

    async disconnectDevice(deviceId: string): Promise<boolean> {
        const disconnected = await this.bleService.disconnectDevice(deviceId);
        if (this.bleService.getDevices().filter(d => d.connected).length === 0) {
            this.stopSync();
        }
        return disconnected;
    }

    getDevices(): ESP32Device[] {
        return this.bleService.getDevices();
    }

    getDevice(deviceId: string): ESP32Device | undefined {
        return this.bleService.getDevice(deviceId);
    }

    private handleTelemetry(event: CustomEvent) {
        const { deviceId, data } = event.detail;

        // Criar objeto TelemetryData
        const telemetry: TelemetryData = {
            device_id: deviceId,
            timestamp: new Date().toISOString(),
            sensors: data.sensors || {},
            battery_level: data.battery_level,
            status: data.status || 'online',
        };

        // Adicionar à fila
        this.telemetryQueue.push(telemetry);

        // Tentar enviar imediatamente
        this.syncTelemetry();
    }

    private async syncTelemetry() {
        if (this.telemetryQueue.length === 0) {
            return;
        }

        const telemetry = this.telemetryQueue.shift();
        if (!telemetry) return;

        try {
            const sent = await this.apiService.sendTelemetry(telemetry);
            if (!sent) {
                // Re-adicionar à fila se falhar
                this.telemetryQueue.unshift(telemetry);
                this.logger.warning('Falha ao enviar telemetria, reenfileirando...');
            } else {
                this.logger.debug(`Telemetria sincronizada: ${telemetry.device_id}`);
            }
        } catch (error) {
            this.logger.error(`Erro ao sincronizar telemetria: ${error}`);
            this.telemetryQueue.unshift(telemetry);
        }
    }

    private startSync() {
        if (this.syncInterval) {
            return; // Já está sincronizando
        }

        this.logger.info('Iniciando sincronização automática...');

        // Sincronizar a cada 60 segundos
        this.syncInterval = window.setInterval(() => {
            this.syncAllTelemetry();
        }, 60000);

        // Sincronizar imediatamente
        this.syncAllTelemetry();
    }

    private stopSync() {
        if (this.syncInterval) {
            clearInterval(this.syncInterval);
            this.syncInterval = null;
            this.logger.info('Sincronização automática parada');
        }
    }

    private async syncAllTelemetry() {
        while (this.telemetryQueue.length > 0) {
            await this.syncTelemetry();
        }
    }
}






