#!/bin/bash

echo "🚨 SOLUÇÃO FINAL - Corrigindo problemas identificados"

# Parar tudo
echo "📦 Parando containers..."
docker-compose down

# Corrigir mosquitto.conf
echo "🦟 Criando mosquitto.conf correto..."
cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest stdout
EOF

# Criar docker-compose.yml com TODAS as variáveis necessárias
echo "📝 Criando docker-compose.yml com variáveis corretas..."
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
      # Database
      DB_HOST: orthotrack-postgres
      DB_PORT: 5432
      DB_NAME: orthotrack_prod
      DB_USER: orthotrack
      DB_PASSWORD: orthotrack_secure_2024
      
      # Redis
      REDIS_HOST: orthotrack-redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: redis_secure_2024
      
      # MQTT - TODAS as variáveis necessárias
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

# Corrigir configuração do sistema para Redis
echo "🔧 Corrigindo configuração do sistema..."
sysctl vm.overcommit_memory=1

echo "🚀 Iniciando deploy final..."

# 1. Banco e Redis
echo "📊 Iniciando PostgreSQL e Redis..."
docker-compose up -d postgres redis

echo "⏳ Aguardando PostgreSQL e Redis (45s)..."
sleep 45

# Verificar se estão saudáveis
echo "🔍 Verificando saúde dos serviços base..."
docker-compose ps postgres redis

# 2. MQTT
echo "🦟 Iniciando MQTT..."
docker-compose up -d mqtt
sleep 15

# Verificar MQTT
echo "🔍 Verificando MQTT..."
docker-compose logs --tail=10 mqtt

# 3. Backend
echo "🔧 Iniciando Backend..."
docker-compose up -d backend
sleep 30

# Verificar backend
echo "🔍 Verificando Backend..."
docker-compose logs --tail=10 backend

# 4. Frontend
echo "🌐 Iniciando Frontend..."
docker-compose up -d frontend
sleep 20

# 5. Nginx
echo "🔄 Iniciando Nginx..."
docker-compose up -d nginx
sleep 10

echo "📋 Status final completo:"
docker-compose ps

echo ""
echo "🔍 Testando conectividade final..."
sleep 15

echo "🏥 Testando Backend..."
curl -f http://localhost:8080/health && echo "✅ Backend OK" || echo "❌ Backend ainda com problema"

echo "🌐 Testando Frontend..."
curl -f http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend ainda com problema"

echo "🔄 Testando Nginx..."
curl -f http://localhost/health && echo "✅ Nginx OK" || echo "❌ Nginx ainda com problema"

echo ""
echo "📊 Logs finais do Backend (se ainda houver problema):"
docker-compose logs --tail=20 backend

echo ""
echo "✅ SOLUÇÃO FINAL APLICADA!"
echo "🌐 Acesse: http://72.60.50.248"
echo "📊 API: http://72.60.50.248/api"
echo "🔍 Health: http://72.60.50.248/health"