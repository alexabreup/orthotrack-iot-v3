# 🚀 Quick Start - Capacitor Android Edge Node

## Passos Rápidos para Rodar em Localhost

### 1. Iniciar o Backend

```bash
cd ../backend
go run cmd/api/main.go
```

O backend deve estar rodando em `http://localhost:8080`

### 2. Configurar Ambiente

```bash
cd android-edge-node

# Criar arquivo .env (se não existir)
cat > .env << EOF
VITE_API_BASE_URL=http://10.0.2.2:8080
VITE_MQTT_BROKER_URL=tcp://10.0.2.2:1883
EOF
```

### 3. Build e Sincronizar

```bash
npm run build
npm run cap:sync
```

### 4. Abrir no Android Studio

```bash
npm run cap:open:android
```

Ou use o script completo:

```bash
npm run android:dev
```

### 5. Executar no Emulador/Dispositivo

No Android Studio:
1. Selecione um emulador ou dispositivo
2. Clique em **Run** (▶️) ou `Shift + F10`
3. Aguarde o build e instalação

## 📱 Configurações

### Emulador (Padrão)
✅ Já configurado com `10.0.2.2` - funciona automaticamente!

### Dispositivo Físico
1. Certifique-se que está na mesma rede WiFi
2. Atualize `.env`:
   ```env
   VITE_API_BASE_URL=http://192.168.15.10:8080
   ```
3. Rebuild:
   ```bash
   npm run build && npm run cap:sync
   ```

## 🔍 Verificar Funcionamento

### Testar no Navegador (Desenvolvimento)

```bash
npm run dev
```

Acesse `http://localhost:3001` para testar a interface web.

### Ver Logs do App

```bash
# Logs do Android
adb logcat | grep -i "orthotrack\|capacitor\|jsconsole"

# Ou filtrar por tag
adb logcat -s CapacitorConsole:V
```

### Testar Backend

```bash
curl http://localhost:8080/api/v1/health
```

## 🛠️ Comandos Úteis

```bash
# Desenvolvimento web
npm run dev

# Build produção
npm run build

# Sincronizar Capacitor
npm run cap:sync

# Copiar apenas assets
npm run cap:copy

# Abrir Android Studio
npm run cap:open:android

# Tudo de uma vez
npm run android:dev
```

## 📚 Documentação Completa

Veja `README_CAPACITOR.md` para documentação detalhada.

---

**Status**: ✅ Projeto configurado e pronto para desenvolvimento!






