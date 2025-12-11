#!/bin/bash

echo "🔧 Corrigindo deploy VPS - Configuração imediata"

# Parar todos os containers
echo "📦 Parando containers..."
docker-compose down

# Criar docker-compose.yml correto para VPS
echo "📝 Criando docker-compose.yml correto..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

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
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  mqtt:
    image: eclipse-mosquitto:2.0-openssl
    container_name: orthotrack-mqtt
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf
      - mqtt_data:/mosquitto/data
      - mqtt_logs:/mosquitto/log
    networks:
      - orthotrack-network

  backend:
    image: ghcr.io/alexabreup/orthotrack-iot-v3/backend:51d9b127e809143ca7c0fb0a8a0407897e45b95f
    container_name: orthotrack-backend
    restart: unless-stopped
    ports:
      - "8080:8080"
    env_file:
      - .env.production
    environment:
      - DB_HOST=orthotrack-postgres
      - DB_PORT=5432
      - DB_NAME=orthotrack_prod
      - DB_USER=orthotrack
      - DB_PASSWORD=orthotrack_secure_2024
      - REDIS_HOST=orthotrack-redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=redis_secure_2024
      - MQTT_HOST=orthotrack-mqtt
      - MQTT_PORT=1883
      - MQTT_PASSWORD=mqtt_secure_2024
      - JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
      - GIN_MODE=release
      - PORT=8080
      - ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000,http://72.60.50.248:3000,http://72.60.50.248:8080
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    image: ghcr.io/alexabreup/orthotrack-iot-v3/frontend:51d9b127e809143ca7c0fb0a8a0407897e45b95f
    container_name: orthotrack-frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - HOST=0.0.0.0
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: orthotrack-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - backend
      - frontend
    networks:
      - orthotrack-network

volumes:
  postgres_data:
  redis_data:
  mqtt_data:
  mqtt_logs:

networks:
  orthotrack-network:
    driver: bridge
EOF

# Criar nginx.conf correto
echo "🌐 Criando nginx.conf..."
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream backend {
        server orthotrack-backend:8080;
    }

    upstream frontend {
        server orthotrack-frontend:3000;
    }

    server {
        listen 80;
        server_name _;

        # Health check endpoint
        location /health {
            proxy_pass http://backend/health;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # API routes
        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # WebSocket
        location /ws {
            proxy_pass http://backend/ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Frontend
        location / {
            proxy_pass http://frontend/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# Criar mosquitto.conf se não existir
if [ ! -f mosquitto.conf ]; then
    echo "🦟 Criando mosquitto.conf..."
    cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF
fi

# Limpar volumes antigos se necessário
echo "🧹 Limpando volumes antigos..."
docker volume prune -f

# Iniciar serviços em ordem
echo "🚀 Iniciando serviços..."

# 1. Banco e Redis primeiro
echo "📊 Iniciando PostgreSQL e Redis..."
docker-compose up -d postgres redis

# Aguardar serviços ficarem saudáveis
echo "⏳ Aguardando PostgreSQL e Redis ficarem prontos..."
sleep 30

# 2. MQTT
echo "🦟 Iniciando MQTT..."
docker-compose up -d mqtt
sleep 10

# 3. Backend
echo "🔧 Iniciando Backend..."
docker-compose up -d backend
sleep 30

# 4. Frontend e Nginx
echo "🌐 Iniciando Frontend e Nginx..."
docker-compose up -d frontend nginx

# Verificar status
echo "📋 Status dos containers:"
docker-compose ps

echo ""
echo "🔍 Testando conectividade..."
sleep 10

# Testar serviços
echo "🏥 Testando health do backend..."
curl -f http://localhost:8080/health || echo "❌ Backend não respondeu"

echo "🌐 Testando frontend..."
curl -f http://localhost:3000/ || echo "❌ Frontend não respondeu"

echo "🔄 Testando nginx..."
curl -f http://localhost/health || echo "❌ Nginx não respondeu"

echo ""
echo "✅ Deploy concluído!"
echo "🌐 Acesse: http://72.60.50.248"
echo "📊 API: http://72.60.50.248/api"
echo "🔍 Health: http://72.60.50.248/health"