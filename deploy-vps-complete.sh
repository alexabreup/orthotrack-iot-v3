#!/bin/bash

# Script de deploy completo para VPS
# Publica frontend e backend integrados via Docker

set -e

VPS_HOST="72.60.50.248"
VPS_USER="root"
VPS_PATH="/root/orthotrack-iot-v3"

echo "🚀 Iniciando deploy completo para VPS ($VPS_HOST)..."

# Verificar se está no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Erro: docker-compose.yml não encontrado. Execute este script na raiz do projeto."
    exit 1
fi

# 1. Criar arquivo .env para produção
echo "📝 Criando arquivo .env para produção..."
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

# JWT Secret
JWT_SECRET=\$(openssl rand -base64 32)

GIN_MODE=release

# URLs do Frontend (build-time) - usar IP do VPS
VITE_API_BASE_URL=http://${VPS_HOST}:8080
VITE_WS_URL=ws://${VPS_HOST}:8080/ws

# CORS - Origens permitidas
ALLOWED_ORIGINS=http://${VPS_HOST}:3000,http://${VPS_HOST}:8080,http://localhost:3000,http://localhost:5173,http://localhost:5174
EOF

# 2. Sincronizar arquivos para o VPS
echo "📤 Sincronizando arquivos para o VPS..."
rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '*.log' \
    --exclude '.env' \
    --exclude '.env.local' \
    --exclude 'build' \
    --exclude 'dist' \
    --exclude '.svelte-kit' \
    --exclude '.vite' \
    --exclude 'coverage' \
    --exclude '.nyc_output' \
    ./ ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/

# 3. Copiar arquivo .env.production como .env no servidor
echo "📤 Configurando variáveis de ambiente no VPS..."
ssh ${VPS_USER}@${VPS_HOST} << ENDSSH
cd ${VPS_PATH}

# Gerar JWT_SECRET se não existir
if ! grep -q "JWT_SECRET=" .env.production 2>/dev/null; then
    JWT_SECRET=\$(openssl rand -base64 32)
    echo "JWT_SECRET=\${JWT_SECRET}" >> .env.production
fi

# Copiar .env.production para .env
cp .env.production .env

# Adicionar ALLOWED_ORIGINS se não existir
if ! grep -q "ALLOWED_ORIGINS=" .env; then
    echo "ALLOWED_ORIGINS=http://${VPS_HOST}:3000,http://${VPS_HOST}:8080,http://localhost:3000,http://localhost:5173,http://localhost:5174" >> .env
fi
ENDSSH

# 4. Executar deploy no VPS
echo "🔨 Executando deploy no VPS..."
ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
cd /root/orthotrack-iot-v3

echo "🛑 Parando containers existentes..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

echo "🗑️  Removendo containers antigos (se existirem)..."
docker ps -a | grep orthotrack | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

echo "🔨 Construindo imagens..."
docker-compose build --no-cache || docker compose build --no-cache

echo "▶️  Iniciando containers..."
docker-compose up -d || docker compose up -d

echo "⏳ Aguardando serviços ficarem prontos..."
sleep 20

echo "📊 Status dos containers:"
docker-compose ps || docker compose ps

echo ""
echo "🏥 Verificando saúde dos serviços..."
echo ""

# Backend
echo -n "Backend: "
if curl -f http://localhost:8080/api/v1/health &> /dev/null; then
    echo "✅ OK"
else
    echo "⚠️  Não respondeu (pode levar alguns segundos)"
fi

# Frontend
echo -n "Frontend: "
if curl -f http://localhost:3000 &> /dev/null; then
    echo "✅ OK"
else
    echo "⚠️  Não respondeu (pode levar alguns segundos)"
fi

echo ""
echo "📋 Logs recentes do backend:"
docker-compose logs --tail=10 backend || docker compose logs --tail=10 backend

echo ""
echo "📋 Logs recentes do frontend:"
docker-compose logs --tail=10 frontend || docker compose logs --tail=10 frontend

ENDSSH

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📝 Acessos:"
echo "   Frontend: http://${VPS_HOST}:3000"
echo "   Backend:  http://${VPS_HOST}:8080"
echo "   Health:   http://${VPS_HOST}:8080/api/v1/health"
echo ""
echo "📋 Comandos úteis:"
echo "   Ver logs: ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_PATH} && docker-compose logs -f'"
echo "   Status:   ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_PATH} && docker-compose ps'"
echo "   Restart:  ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_PATH} && docker-compose restart'"
echo ""



