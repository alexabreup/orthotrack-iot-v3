#!/bin/bash

# Script para verificar status dos serviços

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📊 Status dos Serviços OrthoTrack IoT v3${NC}"
echo "=========================================="
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker não encontrado!${NC}"
    exit 1
fi

# PostgreSQL
echo -n "PostgreSQL: "
if docker ps | grep -q orthotrack-postgres; then
    if docker exec orthotrack-postgres pg_isready -U orthotrack > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Rodando${NC}"
    else
        echo -e "${YELLOW}⚠ Container rodando mas não responde${NC}"
    fi
else
    echo -e "${RED}✗ Parado${NC}"
fi

# Redis
echo -n "Redis:      "
if docker ps | grep -q orthotrack-redis; then
    if docker exec orthotrack-redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Rodando${NC}"
    else
        echo -e "${YELLOW}⚠ Container rodando mas não responde${NC}"
    fi
else
    echo -e "${RED}✗ Parado${NC}"
fi

# MQTT
echo -n "MQTT:       "
if docker ps | grep -q orthotrack-mqtt; then
    echo -e "${GREEN}✓ Rodando${NC}"
else
    echo -e "${RED}✗ Parado${NC}"
fi

# Backend
echo -n "Backend:    "
if curl -s http://localhost:8080/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Rodando${NC}"
else
    echo -e "${RED}✗ Parado${NC}"
fi

echo ""
echo "Containers Docker:"
docker-compose -f docker-compose.services.yml ps 2>/dev/null || echo "Nenhum container encontrado"
echo ""














