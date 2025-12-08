#!/bin/bash

# Script de deploy completo para VPS
# Servidor: 72.60.50.248

set -e

VPS_HOST="72.60.50.248"
VPS_USER="root"
VPS_PATH="/root/orthotrack-iot-v3"

echo "🚀 Iniciando deploy para VPS ($VPS_HOST)..."

# Verificar se está no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Erro: docker-compose.yml não encontrado. Execute este script na raiz do projeto."
    exit 1
fi

# 1. Criar arquivo .env para produção se não existir
if [ ! -f ".env.production" ]; then
    echo "📝 Criando arquivo .env.production..."
    cat > .env.production << EOF
# Configuração para Produção VPS
DB_DATABASE=orthotrack
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=orthotrack
DB_USER=postgres

REDIS_PASSWORD=redis123

MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt123

# JWT Secret - ALTERE EM PRODUÇÃO!
JWT_SECRET=$(openssl rand -base64 32)

GIN_MODE=release

# URLs do Frontend (build-time)
VITE_API_BASE_URL=http://${VPS_HOST}:8080
VITE_WS_URL=ws://${VPS_HOST}:8080/ws

# CORS - Origens permitidas
ALLOWED_ORIGINS=http://${VPS_HOST}:3000,http://localhost:3000,http://localhost:5173,http://localhost:5174
EOF
    echo "✅ Arquivo .env.production criado. Por favor, edite-o com suas configurações de produção."
    echo "   Pressione Enter para continuar ou Ctrl+C para cancelar..."
    read
fi

# 2. Sincronizar arquivos para o VPS
echo "📤 Sincronizando arquivos para o VPS..."
rsync -avz --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '*.log' \
    --exclude '.env' \
    --exclude '.env.local' \
    --exclude 'build' \
    --exclude 'dist' \
    --exclude '.svelte-kit' \
    ./ ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/

# 3. Copiar arquivo .env.production
echo "📤 Copiando configurações de produção..."
scp .env.production ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/.env

# 4. Executar deploy no VPS
echo "🔨 Executando deploy no VPS..."
ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
cd /root/orthotrack-iot-v3

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null

# Construir e iniciar containers
echo "🔨 Construindo e iniciando containers..."
docker-compose build --no-cache || docker compose build --no-cache
docker-compose up -d || docker compose up -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 15

# Verificar status
echo "📊 Status dos containers:"
docker-compose ps || docker compose ps

# Verificar saúde dos serviços
echo ""
echo "🏥 Verificando saúde dos serviços..."
echo ""

# Backend
if curl -f http://localhost:8080/api/v1/health &> /dev/null; then
    echo "✅ Backend está respondendo"
else
    echo "⚠️  Backend ainda não está respondendo (pode levar alguns segundos)"
fi

# Frontend
if curl -f http://localhost:3000 &> /dev/null; then
    echo "✅ Frontend está respondendo"
else
    echo "⚠️  Frontend ainda não está respondendo (pode levar alguns segundos)"
fi

echo ""
echo "✅ Deploy concluído no VPS!"
echo ""
echo "📝 Acessos:"
echo "   Frontend: http://${VPS_HOST}:3000"
echo "   Backend:  http://${VPS_HOST}:8080"
echo ""
ENDSSH

echo ""
echo "✅ Deploy concluído com sucesso!"
echo ""
echo "📝 Acessos:"
echo "   Frontend: http://${VPS_HOST}:3000"
echo "   Backend:  http://${VPS_HOST}:8080"
echo ""
echo "📋 Para ver logs:"
echo "   ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_PATH} && docker-compose logs -f'"
echo ""



