# ⚡ Quick Start - Serviços

## 🏠 Local

```bash
cd backend
./start-services.sh
go run cmd/api/main.go
```

## 🌐 Servidor Remoto (72.60.50.248)

### Opção 1: Deploy Automático (do seu PC)

```bash
cd backend
./deploy-services-remote.sh
```

### Opção 2: Manual (via SSH)

```bash
# 1. Conectar
ssh root@72.60.50.248

# 2. No servidor
cd /root/orthotrack-iot-v3/backend
./start-services.sh

# 3. Verificar
./status-services.sh
```

## ✅ Verificar

```bash
# Local
curl http://localhost:8080/api/v1/health

# Remoto
curl http://72.60.50.248:8080/api/v1/health
```

## 🛑 Parar

```bash
# Local
./stop-services.sh

# Remoto (via SSH)
ssh root@72.60.50.248 "cd /root/orthotrack-iot-v3/backend && ./stop-services.sh"
```

---

**Pronto para testar android-edge-node!** 📱










