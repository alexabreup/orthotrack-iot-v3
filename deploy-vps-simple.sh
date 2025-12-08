#!/bin/bash

# Script de deploy simplificado - passo a passo com verificações

set -e

VPS_HOST="72.60.50.248"
VPS_USER="root"
VPS_PATH="/root/orthotrack-iot-v3"

echo "🚀 Deploy simplificado para VPS ($VPS_HOST)"
echo ""

# Passo 1: Sincronizar arquivos
echo "📤 Passo 1/4: Sincronizando arquivos..."
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
    ./ ${VPS_USER}@${VPS_HOST}:${VPS_PATH}/ || {
    echo "❌ Erro ao sincronizar arquivos"
    exit 1
}

echo "✅ Arquivos sincronizados"
echo ""

# Passo 2: Configurar ambiente
echo "📝 Passo 2/4: Configurando ambiente no servidor..."
ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
cd /root/orthotrack-iot-v3

# Criar .env se não existir
if [ ! -f .env ]; then
    echo "Criando arquivo .env..."
    cat > .env << 'EOF'
DB_DATABASE=orthotrack
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=orthotrack
DB_USER=postgres
REDIS_PASSWORD=redis123
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt123
JWT_SECRET=change-this-in-production-$(date +%s)
GIN_MODE=release
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_WS_URL=ws://72.60.50.248:8080/ws
ALLOWED_ORIGINS=http://72.60.50.248:3000,http://72.60.50.248:8080,http://localhost:3000,http://localhost:5173,http://localhost:5174
EOF
fi

# Garantir que ALLOWED_ORIGINS está configurado
if ! grep -q "ALLOWED_ORIGINS=" .env; then
    echo "ALLOWED_ORIGINS=http://72.60.50.248:3000,http://72.60.50.248:8080,http://localhost:3000,http://localhost:5173,http://localhost:5174" >> .env
fi

echo "✅ Ambiente configurado"
ENDSSH

echo ""

# Passo 3: Parar containers
echo "🛑 Passo 3/4: Parando containers existentes..."
ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
cd /root/orthotrack-iot-v3

# Parar containers graciosamente
docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true

# Forçar parada se necessário
docker ps -a | grep orthotrack | awk '{print $1}' | xargs -r docker stop 2>/dev/null || true
docker ps -a | grep orthotrack | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

echo "✅ Containers parados"
ENDSSH

echo ""

# Passo 4: Build e start
echo "🔨 Passo 4/4: Construindo e iniciando containers..."
ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
cd /root/orthotrack-iot-v3

echo "Construindo imagens (isso pode levar alguns minutos)..."
docker-compose build --no-cache || docker compose build --no-cache

echo "Iniciando containers..."
docker-compose up -d || docker compose up -d

echo "Aguardando serviços iniciarem..."
sleep 15

echo ""
echo "📊 Status dos containers:"
docker-compose ps || docker compose ps

echo ""
echo "📋 Últimas linhas de log do backend:"
docker-compose logs --tail=5 backend || docker compose logs --tail=5 backend

echo ""
echo "📋 Últimas linhas de log do frontend:"
docker-compose logs --tail=5 frontend || docker compose logs --tail=5 frontend
ENDSSH

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📝 Acessos:"
echo "   Frontend: http://${VPS_HOST}:3000"
echo "   Backend:  http://${VPS_HOST}:8080"
echo ""
echo "📋 Para ver logs completos:"
echo "   ssh ${VPS_USER}@${VPS_HOST} 'cd ${VPS_PATH} && docker-compose logs -f'"
echo ""



