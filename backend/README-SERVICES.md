# 🚀 Guia de Serviços - OrthoTrack IoT v3

## 📋 Visão Geral

Este guia explica como iniciar e gerenciar os serviços de infraestrutura (PostgreSQL, Redis, MQTT) necessários para o backend e android-edge-node.

## 🏠 Desenvolvimento Local

### Iniciar Serviços

```bash
cd backend
./start-services.sh
```

Este script irá:
- ✅ Verificar Docker e Docker Compose
- ✅ Criar arquivo `.env` se não existir
- ✅ Criar `mosquitto.conf` se não existir
- ✅ Iniciar containers (PostgreSQL, Redis, MQTT)
- ✅ Configurar banco de dados
- ✅ Verificar saúde dos serviços

### Parar Serviços

```bash
./stop-services.sh
```

### Verificar Status

```bash
./status-services.sh
```

### Iniciar Backend

Após os serviços estarem rodando:

```bash
# Criar .env se necessário
cp .env.example .env

# Iniciar backend
go run cmd/api/main.go
```

## 🌐 Servidor Remoto

### Deploy Inicial

```bash
# Do seu computador local
cd backend
./deploy-services-remote.sh
```

Este script irá:
- ✅ Conectar ao servidor via SSH
- ✅ Criar estrutura de diretórios
- ✅ Enviar arquivos necessários
- ✅ Configurar permissões
- ✅ Opcionalmente iniciar serviços

### Conectar ao Servidor

```bash
ssh root@72.60.50.248
```

### No Servidor Remoto

```bash
cd /root/orthotrack-iot-v3/backend

# Iniciar serviços
./start-services.sh

# Verificar status
./status-services.sh

# Parar serviços
./stop-services.sh
```

## 📦 Serviços

### PostgreSQL
- **Porta**: 5432
- **Banco**: `orthotrack_v3`
- **Usuário**: `orthotrack`
- **Senha**: `password` (padrão)

### Redis
- **Porta**: 6379
- **Senha**: (nenhuma por padrão em desenvolvimento)

### MQTT (Mosquitto)
- **Porta MQTT**: 1883
- **Porta WebSocket**: 9001
- **Autenticação**: Anônima (desenvolvimento)

## 🔧 Configuração

### Arquivo .env

Crie um arquivo `.env` na pasta `backend/`:

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=orthotrack_v3
DB_USER=orthotrack
DB_PASSWORD=password
DB_SSL_MODE=disable

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT
JWT_SECRET=orthotrack-secret-key-change-in-production
JWT_EXPIRE_HOURS=24

# MQTT
MQTT_BROKER_URL=tcp://localhost:1883
MQTT_CLIENT_ID=orthotrack-backend

# Server
PORT=8080
```

### Para Servidor Remoto

No servidor, ajuste o `.env` com:
- IP do servidor ao invés de `localhost` (se necessário)
- Senhas mais seguras
- Configurações de produção

## 🐛 Troubleshooting

### Docker não encontrado

```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
apt-get install docker-compose-plugin
```

### Porta já em uso

```bash
# Verificar o que está usando a porta
sudo lsof -i :5432  # PostgreSQL
sudo lsof -i :6379  # Redis
sudo lsof -i :1883  # MQTT

# Parar serviços conflitantes
sudo systemctl stop postgresql  # Se houver PostgreSQL nativo
```

### Containers não iniciam

```bash
# Ver logs
docker-compose -f docker-compose.services.yml logs

# Ver logs de um serviço específico
docker logs orthotrack-postgres
docker logs orthotrack-redis
docker logs orthotrack-mqtt
```

### Banco de dados não conecta

```bash
# Verificar se o container está rodando
docker ps | grep postgres

# Testar conexão
docker exec -it orthotrack-postgres psql -U orthotrack -d orthotrack_v3

# Recriar banco
docker-compose -f docker-compose.services.yml down -v
./start-services.sh
```

## 📱 Testando com Android Edge Node

### 1. Iniciar Serviços

```bash
cd backend
./start-services.sh
```

### 2. Iniciar Backend

```bash
go run cmd/api/main.go
```

### 3. Configurar Android Edge Node

No arquivo `.env` do `android-edge-node`:

```env
# Para emulador
VITE_API_BASE_URL=http://10.0.2.2:8080

# Para dispositivo físico (mesma rede)
VITE_API_BASE_URL=http://192.168.1.X:8080

# Para servidor remoto
VITE_API_BASE_URL=http://72.60.50.248:8080
```

### 4. Build e Testar

```bash
cd android-edge-node
npm run build
npm run cap:sync
npm run cap:open:android
```

## 🔒 Segurança (Produção)

⚠️ **IMPORTANTE**: As configurações padrão são para desenvolvimento!

Para produção, ajuste:

1. **Senhas fortes** no `.env`
2. **Autenticação MQTT** no `mosquitto.conf`
3. **SSL/TLS** para PostgreSQL e Redis
4. **Firewall** para limitar acesso às portas
5. **JWT Secret** forte e único

## 📚 Comandos Úteis

```bash
# Ver containers rodando
docker ps

# Ver logs em tempo real
docker-compose -f docker-compose.services.yml logs -f

# Parar tudo
docker-compose -f docker-compose.services.yml down

# Parar e remover volumes (⚠️ apaga dados)
docker-compose -f docker-compose.services.yml down -v

# Reiniciar um serviço específico
docker-compose -f docker-compose.services.yml restart postgres

# Executar comandos dentro do container
docker exec -it orthotrack-postgres psql -U orthotrack
docker exec -it orthotrack-redis redis-cli
```

---

**Desenvolvido para OrthoTrack IoT Platform v3** 🚀





