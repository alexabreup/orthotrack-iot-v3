#!/bin/bash

# Quick Deploy Script para OrthoTrack IoT Platform
# Script simplificado para deploy rápido

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Verificar argumentos
if [ $# -eq 0 ]; then
    print_error "Uso: $0 <server-ip>"
    echo "Exemplo: $0 192.168.1.100"
    echo "Exemplo com porta customizada: $0 192.168.1.100 --port=8081"
    exit 1
fi

SERVER_IP=$1
CUSTOM_PORT=""

# Processar argumento da porta
if [ $# -eq 2 ] && [[ $2 == --port=* ]]; then
    CUSTOM_PORT="$2"
fi

echo "🚀 Quick Deploy para OrthoTrack IoT Backend"
echo "Servidor: $SERVER_IP"

# Verificar se o script principal de deploy existe
if [ ! -f "./deploy.sh" ]; then
    print_error "Script deploy.sh não encontrado!"
    print_error "Execute este script do diretório backend/"
    exit 1
fi

# Executar deploy principal
print_success "Iniciando deploy..."
if [ -n "$CUSTOM_PORT" ]; then
    ./deploy.sh "$SERVER_IP" "$CUSTOM_PORT"
else
    ./deploy.sh "$SERVER_IP"
fi

print_success "Quick deploy concluído! ✅"