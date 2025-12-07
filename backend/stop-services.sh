#!/bin/bash

# Script para parar serviços de infraestrutura

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🛑 Parando serviços OrthoTrack IoT v3${NC}"
echo "=========================================="
echo ""

docker-compose -f docker-compose.services.yml down

echo ""
echo -e "${GREEN}✅ Serviços parados${NC}"
echo ""





