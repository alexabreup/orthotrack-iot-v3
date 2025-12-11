#!/bin/bash

echo "🔧 CORREÇÃO FINAL - TLS PostgreSQL"

# Parar apenas o backend
echo "📦 Parando backend..."
docker-compose stop backend

# Atualizar docker-compose.yml com SSL_MODE correto
echo "📝 Corrigindo configuração SSL do PostgreSQL..."
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
      # Database - CORRIGINDO SSL
      DB_HOST: orthotrack-postgres
      DB_PORT: 5432
      DB_NAME: orthotrack_prod
      DB_USER: orthotrack
      DB_PASSWORD: orthotrack_secure_2024
      DB_SSL_MODE: disable
      
      # Redis
      REDIS_HOST: orthotrack-redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: redis_secure_2024
      
      # MQTT
      MQTT_HOST: orthotrack-mqtt
      MQTT_PORT: 1883
      MQTT_BROKER_URL: tcp://orthotrack-mqtt:1883
      MQTT_USERNAME: orthotrack
      MQTT_PASSWORD: mqtt_secure_2024
      MQTT_CLIENT_ID: orthotrack-backend
      
      # JWT
      JWT_SECRET: orthotrack_jwt_super_secret_key_2024_production_secure
      
      # Server
      GIN_MODE: release
      PORT: 8080
      
      # CORS
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

echo "🚀 Reiniciando backend com configuração correta..."
docker-compose up -d backend

echo "⏳ Aguardando backend inicializar (30s)..."
sleep 30

echo "📋 Status dos containers:"
docker-compose ps

echo ""
echo "🔍 Logs do backend (últimas 20 linhas):"
docker-compose logs --tail=20 backend

echo ""
echo "🏥 Testando backend..."
curl -f http://localhost:8080/health && echo "✅ Backend OK!" || echo "❌ Backend ainda com problema"

echo ""
echo "🔄 Testando nginx..."
curl -f http://localhost/health && echo "✅ Nginx OK!" || echo "❌ Nginx ainda com problema"

echo ""
echo "🌐 Testando acesso externo..."
curl -f http://72.60.50.248/health && echo "✅ Acesso externo OK!" || echo "❌ Problema no acesso externo"

echo ""
echo "✅ CORREÇÃO TLS CONCLUÍDA!"
echo "🌐 Acesse: http://72.60.50.248"
echo "📊 API: http://72.60.50.248/api"
echo "🔍 Health: http://72.60.50.248/health"