#!/bin/bash

# Script para buildar imagens localmente no VPS
echo "🏗️ Buildando imagens localmente no VPS..."

# Parar containers existentes
echo "⏹️ Parando containers..."
docker-compose -f docker-compose.prod.yml down || true

# Limpar containers órfãos
docker container prune -f

# Verificar se temos os arquivos de código fonte
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "❌ Código fonte não encontrado!"
    echo "Clonando repositório..."
    
    # Fazer backup do que temos
    cp docker-compose.prod.yml docker-compose.prod.yml.backup
    cp .env.production .env.production.backup 2>/dev/null || true
    cp mosquitto.conf mosquitto.conf.backup 2>/dev/null || true
    
    # Clonar repositório
    cd /opt
    git clone https://github.com/alexabreup/orthotrack-iot-v3.git orthotrack-new
    
    # Mover arquivos de configuração
    cp orthotrack/docker-compose.prod.yml.backup orthotrack-new/docker-compose.prod.yml
    cp orthotrack/.env.production.backup orthotrack-new/.env.production 2>/dev/null || true
    cp orthotrack/mosquitto.conf.backup orthotrack-new/mosquitto.conf 2>/dev/null || true
    
    # Substituir diretório
    rm -rf orthotrack-old 2>/dev/null || true
    mv orthotrack orthotrack-old
    mv orthotrack-new orthotrack
    
    cd /opt/orthotrack
fi

# Criar .env.production se não existir
if [ ! -f .env.production ]; then
    echo "📝 Criando .env.production..."
    cat > .env.production << 'EOF'
DB_PASSWORD=orthotrack_secure_2024
REDIS_PASSWORD=redis_secure_2024
MQTT_PASSWORD=mqtt_secure_2024
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
EOF
fi

# Criar mosquitto.conf se não existir
if [ ! -f mosquitto.conf ]; then
    echo "📝 Criando mosquitto.conf..."
    cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd

listener 9001
protocol websockets
allow_anonymous false

log_dest stdout
log_type error
log_type warning
log_type notice
log_type information
connection_messages true
log_timestamp true

persistence true
persistence_location /mosquitto/data/
autosave_interval 1800
EOF
fi

# Criar arquivo de senhas MQTT
echo "🔐 Configurando MQTT..."
docker run --rm -v $(pwd):/mosquitto/config eclipse-mosquitto:2.0-openssl mosquitto_passwd -c -b /mosquitto/config/mosquitto_passwd orthotrack mqtt_secure_2024

# Modificar docker-compose para build local
echo "📝 Configurando docker-compose para build local..."
cat > docker-compose.local-build.yml << 'EOF'
services:
  postgres:
    image: postgres:15-alpine
    container_name: orthotrack-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: orthotrack_prod
      POSTGRES_USER: orthotrack
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_HOST_AUTH_METHOD: md5
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/migrations:/docker-entrypoint-initdb.d:ro
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U orthotrack -d orthotrack_prod"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  redis:
    image: redis:7-alpine
    container_name: orthotrack-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "redis_secure_2024", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  mqtt:
    image: eclipse-mosquitto:2.0-openssl
    container_name: orthotrack-mqtt
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - ./mosquitto_passwd:/mosquitto/config/passwd:ro
      - mqtt_data:/mosquitto/data
      - mqtt_logs:/mosquitto/log
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m 'health check' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: orthotrack-backend
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=orthotrack-postgres
      - DB_PORT=5432
      - DB_NAME=orthotrack_prod
      - DB_USER=orthotrack
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=orthotrack-redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_DB=0
      - MQTT_HOST=orthotrack-mqtt
      - MQTT_PORT=1883
      - MQTT_BROKER_URL=tcp://orthotrack-mqtt:1883
      - MQTT_USERNAME=orthotrack
      - MQTT_PASSWORD=${MQTT_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - PORT=8080
      - GIN_MODE=release
      - ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      mqtt:
        condition: service_healthy
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - VITE_API_BASE_URL=https://api.orthotrack.alexptech.com
        - VITE_WS_URL=wss://api.orthotrack.alexptech.com/ws
    container_name: orthotrack-frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  mqtt_data:
    driver: local
  mqtt_logs:
    driver: local

networks:
  orthotrack-network:
    driver: bridge
EOF

# Buildar e iniciar serviços
echo "🏗️ Buildando e iniciando serviços..."

# Iniciar infraestrutura primeiro
echo "📊 Iniciando infraestrutura..."
docker-compose -f docker-compose.local-build.yml up -d postgres redis mqtt

# Aguardar infraestrutura ficar pronta
echo "⏳ Aguardando infraestrutura..."
sleep 60

# Buildar e iniciar aplicação
echo "🚀 Buildando e iniciando aplicação..."
docker-compose -f docker-compose.local-build.yml up -d --build backend frontend

# Aguardar aplicação
echo "⏳ Aguardando aplicação..."
sleep 120

# Verificar status
echo "📊 Status dos serviços:"
docker-compose -f docker-compose.local-build.yml ps

# Testar endpoints
echo "🧪 Testando endpoints..."
echo ""
echo "Backend health:"
curl -f http://localhost:8080/health && echo " ✅ Backend OK" || echo " ❌ Backend falhou"

echo "Frontend:"
curl -f -s -o /dev/null http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend falhou"

echo ""
echo "✅ Build local concluído!"
echo ""
echo "📋 Informações de acesso:"
echo "🌐 URL Principal: https://orthotrack.alexptech.com"
echo "🔗 API: https://api.orthotrack.alexptech.com"
echo "🔑 Login: admin@aacd.org.br"
echo "🔒 Senha: password"
echo "📱 Desenvolvimento: http://72.60.50.248:3000"
echo ""
echo "📊 Para monitorar logs:"
echo "docker-compose -f docker-compose.local-build.yml logs -f"