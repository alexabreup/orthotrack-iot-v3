#!/bin/bash

# Script para corrigir deployment no VPS
# Execute no VPS: bash deploy-fix-vps.sh

set -e

echo "🔧 Corrigindo deployment OrthoTrack no VPS..."

# Parar containers existentes
echo "⏹️ Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down || true

# Limpar containers órfãos
echo "🧹 Limpando containers órfãos..."
docker container prune -f

# Fazer login no GitHub Container Registry
echo "🔐 Fazendo login no GitHub Container Registry..."
echo "Você precisa ter um Personal Access Token do GitHub com permissão 'read:packages'"
echo "Gere em: https://github.com/settings/tokens"
read -p "Digite seu GitHub username: " GITHUB_USER
read -s -p "Digite seu GitHub Personal Access Token: " GITHUB_TOKEN
echo

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

# Puxar imagens mais recentes
echo "📥 Puxando imagens mais recentes..."
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest

# Criar arquivo .env.production com valores corretos
echo "📝 Criando arquivo .env.production..."
cat > .env.production << 'EOF'
# Database
DB_PASSWORD=orthotrack_secure_2024

# Redis  
REDIS_PASSWORD=redis_secure_2024

# MQTT
MQTT_PASSWORD=mqtt_secure_2024

# JWT
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
EOF

# Criar arquivo mosquitto.conf se não existir
if [ ! -f mosquitto.conf ]; then
    echo "📝 Criando configuração do MQTT..."
    cat > mosquitto.conf << 'EOF'
# Mosquitto Configuration for OrthoTrack
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd

# WebSocket support
listener 9001
protocol websockets
allow_anonymous false

# Logging
log_dest stdout
log_type error
log_type warning
log_type notice
log_type information
connection_messages true
log_timestamp true

# Persistence
persistence true
persistence_location /mosquitto/data/
autosave_interval 1800
EOF
fi

# Criar arquivo de senhas do MQTT
echo "🔐 Configurando senhas do MQTT..."
docker run --rm -v $(pwd):/mosquitto/config eclipse-mosquitto:2.0-openssl mosquitto_passwd -c -b /mosquitto/config/mosquitto_passwd orthotrack mqtt_secure_2024

# Iniciar serviços
echo "🚀 Iniciando serviços..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 60

# Verificar status
echo "🏥 Verificando status dos serviços..."
docker-compose -f docker-compose.prod.yml ps

# Testar endpoints
echo "🧪 Testando endpoints..."
echo "Backend health:"
curl -f http://localhost:8080/health || echo "❌ Backend não está respondendo"

echo "Frontend:"
curl -f http://localhost/ || echo "❌ Frontend não está respondendo"

echo "✅ Deploy concluído!"
echo ""
echo "📋 Próximos passos:"
echo "1. Acesse http://72.60.50.248 para ver o frontend"
echo "2. Teste login com: admin@aacd.org.br / password"
echo "3. Verifique logs com: docker-compose -f docker-compose.prod.yml logs -f"