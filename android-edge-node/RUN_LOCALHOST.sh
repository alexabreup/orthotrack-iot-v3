#!/bin/bash

# Script para facilitar a execução do Android Edge Node em localhost

echo "🚀 OrthoTrack Android Edge Node - Setup Localhost"
echo "=================================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se o backend está rodando
echo -e "${YELLOW}1. Verificando se o backend está rodando...${NC}"
if curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Backend está rodando em http://localhost:8080${NC}"
else
    echo -e "${RED}✗ Backend não está rodando!${NC}"
    echo "   Inicie o backend primeiro:"
    echo "   cd ../backend && go run cmd/api/main.go"
    exit 1
fi

# Verificar se adb está disponível
echo -e "${YELLOW}2. Verificando ADB...${NC}"
if command -v adb &> /dev/null; then
    echo -e "${GREEN}✓ ADB encontrado${NC}"
    
    # Verificar dispositivos conectados
    DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
    if [ $DEVICES -eq 0 ]; then
        echo -e "${YELLOW}⚠ Nenhum dispositivo/emulador conectado${NC}"
        echo "   Conecte um dispositivo ou inicie um emulador"
    else
        echo -e "${GREEN}✓ $DEVICES dispositivo(s) conectado(s)${NC}"
        
        # Configurar port forwarding
        echo -e "${YELLOW}3. Configurando port forwarding...${NC}"
        adb reverse tcp:8080 tcp:8080
        adb reverse tcp:1883 tcp:1883
        echo -e "${GREEN}✓ Port forwarding configurado${NC}"
    fi
else
    echo -e "${YELLOW}⚠ ADB não encontrado (opcional)${NC}"
fi

# Obter IP da máquina
echo -e "${YELLOW}4. Obtendo IP da máquina...${NC}"
MACHINE_IP=$(hostname -I | awk '{print $1}')
if [ -z "$MACHINE_IP" ]; then
    MACHINE_IP=$(ip addr show | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}' | cut -d/ -f1)
fi

if [ -n "$MACHINE_IP" ]; then
    echo -e "${GREEN}✓ IP da máquina: $MACHINE_IP${NC}"
    echo ""
    echo "📱 Configurações para o app:"
    echo "   - Emulador: use 10.0.2.2 (já configurado no build.gradle)"
    echo "   - Dispositivo físico: use $MACHINE_IP"
    echo ""
    echo "   Para atualizar o build.gradle com seu IP:"
    echo "   buildConfigField \"String\", \"API_BASE_URL\", \"\\\"http://$MACHINE_IP:8080\\\"\""
else
    echo -e "${YELLOW}⚠ Não foi possível obter o IP${NC}"
fi

echo ""
echo -e "${GREEN}✅ Setup concluído!${NC}"
echo ""
echo "Próximos passos:"
echo "1. Abra o projeto no Android Studio"
echo "2. Build e Run o app (Shift+F10)"
echo "3. Verifique os logs: adb logcat | grep -i orthotrack"
echo ""






