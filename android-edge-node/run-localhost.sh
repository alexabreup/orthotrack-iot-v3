#!/bin/bash

# Script para rodar o Android Edge Node em localhost com Capacitor

echo "🚀 OrthoTrack Edge Node - Capacitor Localhost Setup"
echo "===================================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar se o backend está rodando
echo -e "${YELLOW}1. Verificando backend...${NC}"
if curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend está rodando${NC}"
else
    echo -e "${RED}✗ Backend não está rodando!${NC}"
    echo "   Inicie o backend primeiro:"
    echo "   cd ../backend && go run cmd/api/main.go"
    exit 1
fi

# Verificar Node.js
echo -e "${YELLOW}2. Verificando Node.js...${NC}"
if command -v node &> /dev/null; then
    echo -e "${GREEN}✓ Node.js encontrado: $(node --version)${NC}"
else
    echo -e "${RED}✗ Node.js não encontrado!${NC}"
    exit 1
fi

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}3. Instalando dependências...${NC}"
    npm install
fi

# Build
echo -e "${YELLOW}4. Build do projeto web...${NC}"
npm run build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build falhou!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build concluído${NC}"

# Sync Capacitor
echo -e "${YELLOW}5. Sincronizando com Capacitor...${NC}"
npm run cap:sync

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Sync falhou!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Sync concluído${NC}"

# Verificar Android Studio
echo -e "${YELLOW}6. Verificando Android Studio...${NC}"
if command -v studio &> /dev/null || command -v android-studio &> /dev/null; then
    echo -e "${GREEN}✓ Android Studio encontrado${NC}"
    echo ""
    echo -e "${GREEN}✅ Tudo pronto!${NC}"
    echo ""
    echo "Abrindo Android Studio..."
    npm run cap:open:android
else
    echo -e "${YELLOW}⚠ Android Studio não encontrado no PATH${NC}"
    echo ""
    echo "Para abrir manualmente:"
    echo "1. Abra o Android Studio"
    echo "2. File > Open"
    echo "3. Selecione: $(pwd)/android"
    echo ""
    echo "Ou execute: npm run cap:open:android"
fi

echo ""
echo "📱 Configuração Localhost:"
echo "   - Emulador: 10.0.2.2:8080 (já configurado)"
echo "   - Dispositivo físico: use IP da máquina no .env"
echo ""






