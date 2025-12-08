#!/bin/bash

# Script de deploy completo da plataforma OrthoTrack IoT v3
# Este script constrói e inicia todos os containers Docker

set -e

echo "🚀 Iniciando deploy da plataforma OrthoTrack IoT v3..."

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não está instalado. Por favor, instale o Docker primeiro."
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose não está instalado. Por favor, instale o Docker Compose primeiro."
    exit 1
fi

# Verificar se o arquivo .env existe
if [ ! -f .env ]; then
    echo "⚠️  Arquivo .env não encontrado. Criando a partir do .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "✅ Arquivo .env criado. Por favor, edite-o com suas configurações antes de continuar."
        echo "   Pressione Enter para continuar ou Ctrl+C para cancelar..."
        read
    else
        echo "❌ Arquivo .env.example não encontrado. Criando .env básico..."
        cat > .env << EOF
# Configuração básica
DB_DATABASE=orthotrack
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=orthotrack
DB_USER=postgres
REDIS_PASSWORD=redis123
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt123
JWT_SECRET=$(openssl rand -base64 32)
GIN_MODE=release
VITE_API_BASE_URL=http://backend:8080
VITE_WS_URL=ws://backend:8080/ws
EOF
        echo "✅ Arquivo .env criado com valores padrão."
    fi
fi

# Parar containers existentes
echo "🛑 Parando containers existentes..."
docker-compose down 2>/dev/null || docker compose down 2>/dev/null

# Construir imagens
echo "🔨 Construindo imagens Docker..."
docker-compose build --no-cache || docker compose build --no-cache

# Iniciar serviços
echo "▶️  Iniciando serviços..."
docker-compose up -d || docker compose up -d

# Aguardar serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 10

# Verificar status
echo "📊 Verificando status dos containers..."
docker-compose ps || docker compose ps

# Verificar saúde dos serviços
echo ""
echo "🏥 Verificando saúde dos serviços..."
echo ""

# Backend
if curl -f http://localhost:8080/health &> /dev/null; then
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
echo "✅ Deploy concluído!"
echo ""
echo "📝 Acessos:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8080"
echo ""
echo "📋 Comandos úteis:"
echo "   Ver logs:        docker-compose logs -f"
echo "   Parar serviços:  docker-compose down"
echo "   Reiniciar:       docker-compose restart"
echo ""



