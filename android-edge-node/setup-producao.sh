#!/bin/bash

# Script de Configuração para Produção - Android Edge Node
# Configura o projeto para conectar ao servidor de produção

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Configurando Android Edge Node para Produção${NC}"
echo "=========================================="
echo ""

# Diretório do projeto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Servidor de produção
PROD_SERVER="72.60.50.248"
API_URL="http://${PROD_SERVER}:8080"
MQTT_URL="tcp://${PROD_SERVER}:1883"

echo -e "${YELLOW}📝 Criando arquivo .env...${NC}"
cat > .env << EOF
# Configuração de Produção - OrthoTrack Edge Node
# Servidor: ${PROD_SERVER}

VITE_API_BASE_URL=${API_URL}
VITE_MQTT_BROKER_URL=${MQTT_URL}
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

echo -e "${YELLOW}🔄 Sincronizando com Capacitor...${NC}"
npm run cap:sync
echo -e "${GREEN}✓ Sincronização concluída${NC}"
echo ""

echo -e "${GREEN}✅ Configuração concluída!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "1. Abra o projeto no Android Studio:"
echo "   npm run cap:open:android"
echo ""
echo "2. Ou manualmente:"
echo "   - Abra Android Studio"
echo "   - File > Open > Selecione a pasta android/"
echo ""
echo "3. Build e instale no dispositivo:"
echo "   - Build > Build Bundle(s) / APK(s) > Build APK(s)"
echo "   - Ou clique em Run (▶️)"
echo ""
echo "🔗 URLs configuradas:"
echo "   - API: ${API_URL}"
echo "   - MQTT: ${MQTT_URL}"
echo ""


