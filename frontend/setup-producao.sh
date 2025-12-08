#!/bin/bash

# Script de Configuração para Produção - Frontend Dashboard
# Configura o projeto para conectar ao servidor de produção

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Configurando Frontend Dashboard para Produção${NC}"
echo "=========================================="
echo ""

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Servidor de produção
PROD_SERVER="72.60.50.248"
API_URL="http://${PROD_SERVER}:8080"
WS_URL="ws://${PROD_SERVER}:8080/ws"

echo -e "${YELLOW}📝 Criando arquivo .env...${NC}"
cat > .env << EOF
# Configuração de Produção - Frontend Dashboard
# Servidor: ${PROD_SERVER}

VITE_API_BASE_URL=${API_URL}
VITE_WS_URL=${WS_URL}
EOF
echo -e "${GREEN}✓ Arquivo .env criado${NC}"
echo ""

echo -e "${YELLOW}🔍 Verificando conectividade com o servidor...${NC}"
if curl -s --connect-timeout 5 "${API_URL}/api/v1/health" > /dev/null; then
    echo -e "${GREEN}✓ Servidor acessível${NC}"
else
    echo -e "${YELLOW}⚠ Servidor pode não estar acessível (verifique firewall)${NC}"
fi
echo ""

echo -e "${YELLOW}📦 Verificando dependências...${NC}"
if [ ! -d "node_modules" ]; then
    echo "Instalando dependências..."
    npm install
else
    echo -e "${GREEN}✓ Dependências já instaladas${NC}"
fi
echo ""

echo -e "${YELLOW}🔨 Build do projeto...${NC}"
npm run build
echo -e "${GREEN}✓ Build concluído${NC}"
echo ""

echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "1. Para desenvolvimento:"
echo "   npm run dev"
echo ""
echo "2. Para preview do build:"
echo "   npm run preview"
echo ""
echo "3. Para deploy:"
echo "   - Os arquivos estão em build/"
echo "   - Copie para seu servidor web (Nginx, Apache, etc)"
echo ""
echo "🔗 URLs configuradas:"
echo "   - API: ${API_URL}"
echo "   - WebSocket: ${WS_URL}"
echo ""







