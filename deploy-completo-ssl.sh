#!/bin/bash

# Script completo: Build local + SSL para orthotrack.alexptech.com
echo "🚀 Deploy completo com SSL para orthotrack.alexptech.com..."

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.prod.yml" ]; then
    echo "❌ Execute este script no diretório /opt/orthotrack"
    exit 1
fi

# Parar todos os containers
echo "⏹️ Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down || true
docker-compose -f docker-compose.build.yml down 2>/dev/null || true

# Verificar código fonte
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo "📥 Clonando código fonte..."
    cd /opt
    git clone https://github.com/alexabreup/orthotrack-iot-v3.git orthotrack-temp
    
    # Fazer backup das configurações
    cp orthotrack/docker-compose.prod.yml orthotrack-temp/ 2>/dev/null || true
    cp orthotrack/.env.production orthotrack-temp/ 2>/dev/null || true
    cp orthotrack/nginx.conf orthotrack-temp/ 2>/dev/null || true
    cp orthotrack/mosquitto.conf orthotrack-temp/ 2>/dev/null || true
    
    # Substituir diretório
    mv orthotrack orthotrack-old
    mv orthotrack-temp orthotrack
    cd orthotrack
fi

# Criar .env.production com SSL
echo "📝 Criando .env.production com SSL..."
cat > .env.production << 'EOF'
# Database Configuration
DB_PASSWORD=orthotrack_secure_2024
DB_HOST=orthotrack-postgres
DB_PORT=5432
DB_NAME=orthotrack_prod
DB_USER=orthotrack

# Redis Configuration  
REDIS_PASSWORD=redis_secure_2024

# MQTT Configuration
MQTT_PASSWORD=mqtt_secure_2024

# JWT Secret
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure

# Server Configuration
GIN_MODE=release
PORT=8080

# Frontend URLs (build-time) - SSL Domain
VITE_API_BASE_URL=https://api.orthotrack.alexptech.com
VITE_WS_URL=wss://api.orthotrack.alexptech.com/ws

# CORS Origins - SSL Domain
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
EOF

# Criar mosquitto.conf
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

# Criar senha MQTT
echo "🔐 Configurando MQTT..."
docker run --rm -v $(pwd):/mosquitto/config eclipse-mosquitto:2.0-openssl mosquitto_passwd -c -b /mosquitto/config/mosquitto_passwd orthotrack mqtt_secure_2024

# Criar docker-compose para build com SSL
echo "📝 Criando docker-compose para build com SSL..."
cat > docker-compose.ssl.yml << 'EOF'
services:
  postgres:
    image: postgres:15-alpine
    container_name: orthotrack-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: orthotrack_prod
      POSTGRES_USER: orthotrack
      POSTGRES_PASSWORD: orthotrack_secure_2024
      POSTGRES_HOST_AUTH_METHOD: md5
    volumes:
      - postgres_data:/var/lib/postgresql/data
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
    command: redis-server --appendonly yes --requirepass redis_secure_2024
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
      - DB_PASSWORD=orthotrack_secure_2024
      - REDIS_HOST=orthotrack-redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=redis_secure_2024
      - REDIS_DB=0
      - MQTT_HOST=orthotrack-mqtt
      - MQTT_PORT=1883
      - MQTT_BROKER_URL=tcp://orthotrack-mqtt:1883
      - MQTT_USERNAME=orthotrack
      - MQTT_PASSWORD=mqtt_secure_2024
      - JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
      - PORT=8080
      - GIN_MODE=release
      - ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
    depends_on:
      - postgres
      - redis
      - mqtt
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
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  nginx:
    image: nginx:alpine
    container_name: orthotrack-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - backend
      - frontend
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
  redis_data:
  mqtt_data:
  mqtt_logs:

networks:
  orthotrack-network:
    driver: bridge
EOF

# Configurar SSL se não existir
if [ ! -f "/etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem" ]; then
    echo "🔐 Configurando SSL..."
    
    # Instalar certbot se necessário
    if ! command -v certbot &> /dev/null; then
        echo "📦 Instalando Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Obter certificados
    echo "🔐 Obtendo certificados SSL..."
    certbot certonly --standalone \
        --email admin@alexptech.com \
        --agree-tos \
        --no-eff-email \
        -d orthotrack.alexptech.com \
        -d www.orthotrack.alexptech.com \
        -d api.orthotrack.alexptech.com
    
    # Configurar renovação automática
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker restart orthotrack-nginx") | crontab -
else
    echo "✅ Certificados SSL já existem"
fi

# Buildar e iniciar serviços
echo "🏗️ Buildando e iniciando serviços..."

# Infraestrutura primeiro
echo "📊 Iniciando infraestrutura..."
docker-compose -f docker-compose.ssl.yml up -d postgres redis mqtt
sleep 60

# Aplicação
echo "🚀 Buildando aplicação..."
docker-compose -f docker-compose.ssl.yml up -d --build backend frontend
sleep 120

# Nginx por último
echo "🌐 Iniciando nginx..."
docker-compose -f docker-compose.ssl.yml up -d nginx
sleep 30

# Verificar status
echo "📊 Status dos serviços:"
docker-compose -f docker-compose.ssl.yml ps

# Testar endpoints
echo "🧪 Testando endpoints..."
echo ""
echo "Backend (local):"
curl -f http://localhost:8080/health && echo " ✅ Backend local OK" || echo " ❌ Backend local falhou"

echo "Frontend (local):"
curl -f -s -o /dev/null http://localhost:3000/ && echo "✅ Frontend local OK" || echo "❌ Frontend local falhou"

echo "SSL Frontend:"
curl -f -s -o /dev/null https://orthotrack.alexptech.com/health && echo "✅ SSL Frontend OK" || echo "❌ SSL Frontend falhou"

echo "SSL API:"
curl -f -s -o /dev/null https://api.orthotrack.alexptech.com/health && echo "✅ SSL API OK" || echo "❌ SSL API falhou"

echo ""
echo "✅ Deploy completo com SSL concluído!"
echo ""
echo "📋 URLs de acesso:"
echo "🌐 Frontend: https://orthotrack.alexptech.com"
echo "🔗 API: https://api.orthotrack.alexptech.com"
echo "🔒 WebSocket: wss://api.orthotrack.alexptech.com/ws"
echo "🔑 Login: admin@aacd.org.br"
echo "🔒 Senha: password"
echo ""
echo "📊 Para monitorar:"
echo "docker-compose -f docker-compose.ssl.yml logs -f"