#!/bin/bash

# Script para fazer deploy dos serviços no servidor remoto
# Uso: ./deploy-services-remote.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

SERVER="root@72.60.50.248"
REMOTE_DIR="/root/orthotrack-iot-v3/backend"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 Deploy de Serviços - Servidor Remoto${NC}"
echo "=========================================="
echo ""
echo "Servidor: ${SERVER}"
echo "Diretório remoto: ${REMOTE_DIR}"
echo ""

# Verificar conexão SSH
echo -e "${YELLOW}🔌 Verificando conexão SSH...${NC}"
if ! ssh -o ConnectTimeout=5 ${SERVER} "echo 'Conexão OK'" 2>/dev/null; then
    echo -e "${RED}✗ Não foi possível conectar ao servidor${NC}"
    echo "   Verifique:"
    echo "   - Conexão com a internet"
    echo "   - IP do servidor: 72.60.50.248"
    echo "   - Acesso SSH configurado"
    exit 1
fi
echo -e "${GREEN}✓ Conexão estabelecida${NC}"
echo ""

# Criar diretório remoto se não existir
echo -e "${YELLOW}📁 Criando estrutura de diretórios...${NC}"
ssh ${SERVER} "mkdir -p ${REMOTE_DIR}"
echo -e "${GREEN}✓ Diretório criado${NC}"
echo ""

# Enviar arquivos necessários
echo -e "${YELLOW}📤 Enviando arquivos...${NC}"

# docker-compose.services.yml
echo -n "  docker-compose.services.yml... "
scp ${LOCAL_DIR}/docker-compose.services.yml ${SERVER}:${REMOTE_DIR}/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

# mosquitto.conf
echo -n "  mosquitto.conf... "
scp ${LOCAL_DIR}/mosquitto.conf ${SERVER}:${REMOTE_DIR}/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

# Scripts
echo -n "  start-services.sh... "
scp ${LOCAL_DIR}/start-services.sh ${SERVER}:${REMOTE_DIR}/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo -n "  stop-services.sh... "
scp ${LOCAL_DIR}/stop-services.sh ${SERVER}:${REMOTE_DIR}/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo -n "  status-services.sh... "
scp ${LOCAL_DIR}/status-services.sh ${SERVER}:${REMOTE_DIR}/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

# .env.example
echo -n "  .env.example... "
scp ${LOCAL_DIR}/.env.example ${SERVER}:${REMOTE_DIR}/ 2>/dev/null && echo -e "${GREEN}✓${NC}" || echo -e "${RED}✗${NC}"

echo ""

# Dar permissão de execução aos scripts
echo -e "${YELLOW}🔧 Configurando permissões...${NC}"
ssh ${SERVER} "cd ${REMOTE_DIR} && chmod +x *.sh"
echo -e "${GREEN}✓ Permissões configuradas${NC}"
echo ""

# Verificar Docker no servidor
echo -e "${YELLOW}🐳 Verificando Docker no servidor...${NC}"
if ssh ${SERVER} "command -v docker &> /dev/null"; then
    echo -e "${GREEN}✓ Docker instalado${NC}"
    ssh ${SERVER} "docker --version"
else
    echo -e "${RED}✗ Docker não encontrado no servidor${NC}"
    echo "   Instale o Docker primeiro"
    exit 1
fi

if ssh ${SERVER} "command -v docker-compose &> /dev/null || docker compose version &> /dev/null"; then
    echo -e "${GREEN}✓ Docker Compose disponível${NC}"
else
    echo -e "${RED}✗ Docker Compose não encontrado${NC}"
    exit 1
fi
echo ""

# Perguntar se deseja iniciar os serviços
echo -e "${BLUE}❓ Deseja iniciar os serviços agora?${NC}"
read -p "   (s/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}🚀 Iniciando serviços no servidor...${NC}"
    ssh ${SERVER} "cd ${REMOTE_DIR} && ./start-services.sh"
else
    echo ""
    echo -e "${GREEN}✅ Arquivos enviados com sucesso!${NC}"
    echo ""
    echo "Para iniciar os serviços, conecte-se ao servidor:"
    echo "  ssh ${SERVER}"
    echo "  cd ${REMOTE_DIR}"
    echo "  ./start-services.sh"
fi

echo ""














