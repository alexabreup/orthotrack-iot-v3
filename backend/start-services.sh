#!/bin/bash

# Script para iniciar serviços de infraestrutura (PostgreSQL, Redis, MQTT)
# Para desenvolvimento local do backend e android-edge-node

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 OrthoTrack IoT v3 - Iniciando Serviços${NC}"
echo "=========================================="
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não encontrado!${NC}"
    echo "   Instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose não encontrado!${NC}"
    exit 1
fi

# Verificar se já está rodando
if docker ps | grep -q "orthotrack-postgres\|orthotrack-redis\|orthotrack-mqtt"; then
    echo -e "${YELLOW}⚠ Alguns serviços já estão rodando${NC}"
    echo ""
    read -p "Deseja parar e reiniciar? (s/N): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Parando serviços existentes...${NC}"
        docker-compose -f docker-compose.services.yml down 2>/dev/null || true
    else
        echo -e "${GREEN}Continuando com serviços existentes...${NC}"
    fi
fi

# Criar arquivo .env se não existir
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Criando arquivo .env...${NC}"
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Arquivo .env criado a partir de .env.example${NC}"
    else
        cat > .env << EOF
# Configurações do Backend
PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_NAME=orthotrack_v3
DB_USER=orthotrack
DB_PASSWORD=password
DB_SSL_MODE=disable
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0
JWT_SECRET=orthotrack-secret-key-change-in-production
JWT_EXPIRE_HOURS=24
MQTT_BROKER_URL=tcp://localhost:1883
MQTT_CLIENT_ID=orthotrack-backend
EOF
        echo -e "${GREEN}✓ Arquivo .env criado com valores padrão${NC}"
    fi
fi

# Criar mosquitto.conf se não existir
if [ ! -f mosquitto.conf ]; then
    echo -e "${YELLOW}📝 Criando mosquitto.conf...${NC}"
    cat > mosquitto.conf << EOF
listener 1883
protocol mqtt
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_type all
listener 9001
protocol websockets
EOF
    echo -e "${GREEN}✓ mosquitto.conf criado${NC}"
fi

# Iniciar serviços
echo ""
echo -e "${BLUE}🐳 Iniciando containers Docker...${NC}"
docker-compose -f docker-compose.services.yml up -d

# Aguardar serviços ficarem prontos
echo ""
echo -e "${YELLOW}⏳ Aguardando serviços ficarem prontos...${NC}"

# PostgreSQL
echo -n "PostgreSQL: "
for i in {1..30}; do
    if docker exec orthotrack-postgres pg_isready -U orthotrack > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}✗ Timeout${NC}"
    else
        sleep 1
    fi
done

# Redis
echo -n "Redis: "
for i in {1..30}; do
    if docker exec orthotrack-redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}✗ Timeout${NC}"
    else
        sleep 1
    fi
done

# MQTT
echo -n "MQTT: "
sleep 2
if docker ps | grep -q orthotrack-mqtt; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
fi

# Criar banco de dados e usuário se necessário
echo ""
echo -e "${BLUE}🗄️  Configurando banco de dados...${NC}"

# Tentar criar usuário e banco (pode falhar se já existir, mas não é problema)
docker exec -i orthotrack-postgres psql -U postgres << EOF 2>/dev/null || true
CREATE USER orthotrack WITH PASSWORD 'password';
CREATE DATABASE orthotrack_v3 OWNER orthotrack;
GRANT ALL PRIVILEGES ON DATABASE orthotrack_v3 TO orthotrack;
EOF

echo -e "${GREEN}✓ Banco de dados configurado${NC}"

# Mostrar status
echo ""
echo -e "${GREEN}✅ Serviços iniciados com sucesso!${NC}"
echo ""
echo "📊 Status dos serviços:"
docker-compose -f docker-compose.services.yml ps
echo ""
echo "🔗 Endpoints:"
echo "   PostgreSQL: localhost:5432"
echo "   Redis:      localhost:6379"
echo "   MQTT:       localhost:1883"
echo ""
echo "📝 Próximos passos:"
echo "   1. Inicie o backend: go run cmd/api/main.go"
echo "   2. Teste o android-edge-node"
echo ""
echo "🛑 Para parar os serviços:"
echo "   ./stop-services.sh"
echo ""





