#!/bin/bash

echo "🔧 Correção imediata do Backend - VPS"

# Parar todos os containers
echo "📦 Parando todos os containers..."
docker-compose down

# Remover containers antigos
echo "🧹 Limpando containers antigos..."
docker container prune -f

# Criar .env.production correto
echo "📝 Criando .env.production correto..."
cat > .env.production << 'EOF'
# Database Configuration
DB_HOST=orthotrack-postgres
DB_PORT=5432
DB_NAME=orthotrack_prod
DB_USER=orthotrack
DB_PASSWORD=orthotrack_secure_2024

# Redis Configuration  
REDIS_HOST=orthotrack-redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_2024

# MQTT Configuration
MQTT_HOST=orthotrack-mqtt
MQTT_PORT=1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt_secure_2024

# JWT Secret
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure

# Server Configuration
GIN_MODE=release
PORT=8080

# CORS Origins
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000,http://72.60.50.248:3000,http://72.60.50.248:8080,http://72.60.50.248

# Frontend URLs (build-time)
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_WS_URL=ws://72.60.50.248:8080/ws
EOF

# Criar docker-compose.yml simplificado
echo "📝 Criando docker-compose.yml simplificado..."
cat > docker-compose.yml << 'EOF'
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
      interval: 10s
      timeout: 5s
      retries: 5

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
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  mqtt:
    image: eclipse-mosquitto:2.0-openssl
    container_name: orthotrack-mqtt
    restart: unless-stopped
    ports:
      - "1883:1883"
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
    environment:
      DB_HOST: orthotrack-postgres
      DB_PORT: 5432
      DB_NAME: orthotrack_prod
      DB_USER: orthotrack
      DB_PASSWORD: orthotrack_secure_2024
      REDIS_HOST: orthotrack-redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: redis_secure_2024
      MQTT_HOST: orthotrack-mqtt
      MQTT_PORT: 1883
      MQTT_USERNAME: orthotrack
      MQTT_PASSWORD: mqtt_secure_2024
      JWT_SECRET: orthotrack_jwt_super_secret_key_2024_production_secure
      GIN_MODE: release
      PORT: 8080
      ALLOWED_ORIGINS: "http://72.60.50.248:3000,http://72.60.50.248:8080,http://72.60.50.248,http://localhost:3000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - orthotrack-network

  frontend:
    image: ghcr.io/alexabreup/orthotrack-iot-v3/frontend:51d9b127e809143ca7c0fb0a8a0407897e45b95f
    container_name: orthotrack-frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      PORT: 3000
      HOST: 0.0.0.0
    depends_on:
      - backend
    networks:
      - orthotrack-network

  nginx:
    image: nginx:alpine
    container_name: orthotrack-nginx
    restart: unless-stopped
    ports:
      - "80:80"
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

# Criar mosquitto.conf simples
echo "🦟 Criando mosquitto.conf simples..."
cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest stdout
EOF

# Criar nginx.conf simples
echo "🌐 Criando nginx.conf simples..."
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name _;

        location /health {
            proxy_pass http://orthotrack-backend:8080/health;
            proxy_set_header Host $host;
        }

        location /api/ {
            proxy_pass http://orthotrack-backend:8080/;
            proxy_set_header Host $host;
        }

        location /ws {
            proxy_pass http://orthotrack-backend:8080/ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }

        location / {
            proxy_pass http://orthotrack-frontend:3000/;
            proxy_set_header Host $host;
        }
    }
}
EOF

echo "🚀 Iniciando deploy sequencial..."

# 1. Banco e Redis
echo "📊 Iniciando PostgreSQL e Redis..."
docker-compose up -d postgres redis

echo "⏳ Aguardando PostgreSQL e Redis (60s)..."
sleep 60

# Verificar se estão saudáveis
echo "🔍 Verificando saúde dos serviços..."
docker-compose ps

# 2. MQTT
echo "🦟 Iniciando MQTT..."
docker-compose up -d mqtt
sleep 20

# 3. Backend
echo "🔧 Iniciando Backend..."
docker-compose up -d backend
sleep 30

# 4. Frontend
echo "🌐 Iniciando Frontend..."
docker-compose up -d frontend
sleep 20

# 5. Nginx
echo "🔄 Iniciando Nginx..."
docker-compose up -d nginx
sleep 10

echo "📋 Status final:"
docker-compose ps

echo ""
echo "🔍 Testando serviços..."
sleep 10

curl -f http://localhost:8080/health && echo "✅ Backend OK" || echo "❌ Backend falhou"
curl -f http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend falhou"  
curl -f http://localhost/health && echo "✅ Nginx OK" || echo "❌ Nginx falhou"

echo ""
echo "✅ Correção concluída!"
echo "🌐 Acesse: http://72.60.50.248"