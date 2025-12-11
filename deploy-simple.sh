#!/bin/bash

# Deploy simples - apenas pull e start
echo "🚀 Iniciando deploy simples..."

# Definir variáveis de ambiente
export DB_PASSWORD=postgres
export REDIS_PASSWORD=redis123
export MQTT_USERNAME=orthotrack
export MQTT_PASSWORD=mqtt123
export JWT_SECRET=YourSecretJWTKeyHere123456789

# Parar containers existentes
echo "⏹️  Parando containers existentes..."
docker-compose -f docker-compose.prod.yml down

# Login no GitHub Container Registry (você precisa de um token)
echo "🔐 Fazendo login no GitHub Container Registry..."
# Você precisará criar um Personal Access Token no GitHub com permissão read:packages
# echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u alexabreup --password-stdin

# Fazer pull das imagens mais recentes
echo "📥 Fazendo pull das imagens..."
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest

# Iniciar os serviços
echo "🚀 Iniciando serviços..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar um pouco
echo "⏳ Aguardando serviços iniciarem..."
sleep 30

# Verificar status
echo "📊 Status dos containers:"
docker-compose -f docker-compose.prod.yml ps

# Testar endpoints
echo "🧪 Testando endpoints..."
echo "Backend: http://localhost:8080/health"
curl -f http://localhost:8080/health || echo "❌ Backend não respondeu"

echo "Frontend via nginx: http://localhost/health"  
curl -f http://localhost/health || echo "❌ Nginx não respondeu"

echo "✅ Deploy concluído!"