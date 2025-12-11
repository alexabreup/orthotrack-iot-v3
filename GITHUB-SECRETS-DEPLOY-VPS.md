# 🔐 Secrets Necessários para Deploy VPS

## Secrets do GitHub Actions

Configure estes secrets em: `Settings → Secrets and variables → Actions`

### 🔑 SSH e VPS
```
VPS_SSH_PRIVATE_KEY
```
**Valor:** Chave SSH privada para acesso ao VPS (já configurada)

### 🗄️ Database
```
DB_PASSWORD
```
**Valor:** Senha segura para PostgreSQL
**Exemplo:** `postgres_super_secure_password_123`

### 🔴 Redis
```
REDIS_PASSWORD
```
**Valor:** Senha para Redis (pode ser vazio se não quiser senha)
**Exemplo:** `redis_secure_password_456` ou deixe vazio

### 🔒 JWT
```
JWT_SECRET
```
**Valor:** Chave secreta para JWT (deve ser longa e aleatória)
**Exemplo:** `jwt_super_secret_key_that_is_very_long_and_random_789`

### 📡 MQTT
```
MQTT_PASSWORD
```
**Valor:** Senha para MQTT broker
**Exemplo:** `mqtt_secure_password_101`

### 🐳 Docker Hub (Opcional - para build de imagens)
```
DOCKER_USERNAME
DOCKER_PASSWORD
```
**Valores:**
- Username: `alexabreup`
- Password: `#,d^Ta&KPp6!jfk`

### 📢 Notificações (Opcional)
```
SLACK_WEBHOOK_URL
```
**Valor:** URL do webhook do Slack para notificações de deploy

## 🚀 Como Configurar

1. Acesse: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions

2. Clique em "New repository secret"

3. Adicione cada secret com seu respectivo valor

4. Teste o deploy fazendo um push para a branch `main`

## ✅ Verificação

Após configurar todos os secrets, o deploy deve:

1. ✅ Conectar via SSH no VPS
2. ✅ Criar estrutura de diretórios
3. ✅ Copiar arquivos de configuração
4. ✅ Criar arquivo .env.production
5. ✅ Fazer deploy com Docker Compose
6. ✅ Verificar saúde dos serviços

## 🔧 Comandos para Gerar Secrets

### Gerar JWT Secret
```bash
openssl rand -base64 64
```

### Gerar Passwords Seguros
```bash
openssl rand -base64 32
```

## 📝 Exemplo de .env.production Final

```env
# Database
DB_HOST=orthotrack-postgres
DB_PORT=5432
DB_NAME=orthotrack_prod
DB_USER=orthotrack
DB_PASSWORD=postgres_super_secure_password_123
DB_SSL_MODE=require

# Redis
REDIS_HOST=orthotrack-redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_password_456
REDIS_DB=0
REDIS_POOL_SIZE=20
REDIS_MIN_IDLE_CONNS=10
REDIS_MAX_RETRIES=5

# MQTT
MQTT_HOST=orthotrack-mqtt
MQTT_PORT=1883
MQTT_BROKER_URL=tcp://orthotrack-mqtt:1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt_secure_password_101
MQTT_CLIENT_ID=orthotrack-backend-prod

# JWT
JWT_SECRET=jwt_super_secret_key_that_is_very_long_and_random_789
JWT_EXPIRE_HOURS=24

# Server
PORT=8080
GIN_MODE=release

# CORS
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://72.60.50.248:3000,http://72.60.50.248:8080

# Alertas
IOT_ALERT_BATTERY_LOW=15
IOT_ALERT_TEMP_HIGH=45.0
IOT_ALERT_TEMP_LOW=5.0
```