# OrthoTrack Edge Node - Capacitor Setup

## 📱 Sobre o Projeto

Este é o aplicativo Android Edge Node desenvolvido com **Capacitor**, que funciona como um gateway entre dispositivos ESP32 (via BLE) e o backend OrthoTrack.

## 🚀 Quick Start

### 1. Instalar Dependências

```bash
cd android-edge-node
npm install
```

### 2. Configurar Variáveis de Ambiente

Crie um arquivo `.env`:

```env
# Para Emulador Android
VITE_API_BASE_URL=http://10.0.2.2:8080
VITE_MQTT_BROKER_URL=tcp://10.0.2.2:1883

# Para Dispositivo Físico (use o IP da sua máquina)
# VITE_API_BASE_URL=http://192.168.15.10:8080
```

### 3. Build do Projeto Web

```bash
npm run build
```

### 4. Sincronizar com Capacitor

```bash
npm run cap:sync
```

### 5. Abrir no Android Studio

```bash
npm run cap:open:android
```

Ou use o script completo:

```bash
npm run android:dev
```

## 📂 Estrutura do Projeto

```
android-edge-node/
├── src/
│   ├── main.ts              # Entry point
│   ├── services/
│   │   ├── api.service.ts   # Comunicação com backend
│   │   ├── ble.service.ts   # Comunicação BLE com ESP32
│   │   └── edge-node.service.ts  # Orquestração
│   ├── types/
│   │   └── device.ts        # Tipos TypeScript
│   └── utils/
│       └── logger.ts        # Logger
├── public/                  # Arquivos estáticos
├── dist/                    # Build output (gerado)
├── android/                 # Projeto Android nativo (gerado)
├── capacitor.config.ts      # Configuração Capacitor
├── vite.config.js           # Configuração Vite
└── package.json
```

## 🔧 Scripts Disponíveis

- `npm run dev` - Desenvolvimento local (http://localhost:3001)
- `npm run build` - Build para produção
- `npm run preview` - Preview do build
- `npm run cap:sync` - Sincronizar com plataformas nativas
- `npm run cap:copy` - Copiar assets web
- `npm run cap:open:android` - Abrir Android Studio
- `npm run android:dev` - Build + Sync + Open Android Studio

## 📱 Funcionalidades

### Comunicação BLE
- Escaneamento de dispositivos ESP32
- Conexão e desconexão
- Leitura de telemetria em tempo real
- Envio de comandos

### Sincronização com Backend
- Envio automático de telemetria
- Atualização de status de dispositivos
- Envio de alertas
- Resposta a comandos

### Interface
- Dashboard em tempo real
- Lista de dispositivos conectados
- Logs do sistema
- Status de conectividade

## 🔌 Configuração de Localhost

### Emulador Android
O projeto está configurado para usar `10.0.2.2` que mapeia para `localhost` da máquina host.

### Dispositivo Físico
1. Certifique-se que o dispositivo está na mesma rede WiFi
2. Atualize o `.env` com o IP da sua máquina:
   ```env
   VITE_API_BASE_URL=http://192.168.15.10:8080
   ```
3. Rebuild: `npm run build && npm run cap:sync`

### ADB Port Forwarding (Alternativa)
```bash
adb reverse tcp:8080 tcp:8080
adb reverse tcp:1883 tcp:1883
```

Depois use `127.0.0.1` no `.env`.

## 🛠️ Desenvolvimento

### Modo Desenvolvimento Web

```bash
npm run dev
```

Acesse `http://localhost:3001` no navegador para testar a interface web.

### Modo Nativo Android

```bash
npm run build
npm run cap:sync
npm run cap:open:android
```

No Android Studio, clique em Run (▶️) para executar no emulador/dispositivo.

### Hot Reload

Para desenvolvimento com hot reload:

1. Terminal 1: `npm run dev` (web server)
2. Terminal 2: `npm run cap:sync` (após mudanças)
3. No Android Studio: Run novamente

Ou use o Live Reload do Capacitor (configurar no `capacitor.config.ts`).

## 📦 Plugins Capacitor Utilizados

- **@capacitor/app** - App lifecycle events
- **@capacitor/network** - Network status
- **@capacitor/preferences** - Key-value storage
- **@capacitor/status-bar** - Status bar customization
- **@capacitor/splash-screen** - Splash screen
- **@capacitor/toast** - Toast notifications

## 🔵 Bluetooth LE

O app usa a **Web Bluetooth API** que funciona no Capacitor Android. Para funcionalidades mais avançadas, você pode criar um plugin Capacitor customizado.

### Plugin BLE Customizado (Futuro)

Para funcionalidades BLE mais robustas, considere criar um plugin:

```bash
npx @capacitor/cli plugin:generate
```

## 🐛 Troubleshooting

### Build falha
```bash
npm run build
# Verifique erros no console
```

### Capacitor sync falha
```bash
rm -rf android/
npm run cap:sync
```

### App não conecta ao backend
- Verifique se o backend está rodando
- Verifique o IP no `.env`
- Para emulador: use `10.0.2.2`
- Para dispositivo: use IP da máquina na rede

### Bluetooth não funciona
- Verifique permissões no AndroidManifest.xml
- Web Bluetooth requer HTTPS (ou localhost)
- Alguns recursos podem precisar de plugin customizado

## 📚 Documentação

- [Capacitor Docs](https://capacitorjs.com/docs)
- [Web Bluetooth API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Bluetooth_API)
- [Vite Docs](https://vitejs.dev/)

## 🎯 Próximos Passos

1. Implementar plugin BLE customizado (se necessário)
2. Adicionar armazenamento offline (Room/SQLite via plugin)
3. Implementar sincronização em background
4. Adicionar notificações push
5. Melhorar UI/UX

---

**Desenvolvido com Capacitor** ⚡






