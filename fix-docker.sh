#!/bin/bash

# Script para diagnosticar e corrigir problemas do Docker

set -e

VPS_HOST="72.60.50.248"
VPS_USER="root"
VPS_PATH="/root/orthotrack-iot-v3"

echo "🔍 Diagnosticando problemas do Docker no VPS..."

# Executar diagnóstico e limpeza no servidor
ssh ${VPS_USER}@${VPS_HOST} << 'ENDSSH'
echo "📊 Status do Docker..."
docker ps -a
echo ""

echo "💾 Uso de recursos..."
docker stats --no-stream
echo ""

echo "🧹 Limpando containers parados..."
docker container prune -f

echo "🧹 Limpando imagens não utilizadas..."
docker image prune -f

echo "🧹 Limpando volumes não utilizados..."
docker volume prune -f

echo "🧹 Limpando networks não utilizadas..."
docker network prune -f

echo "🛑 Parando todos os containers orthotrack..."
docker ps -a | grep orthotrack | awk '{print $1}' | xargs -r docker stop 2>/dev/null || true
docker ps -a | grep orthotrack | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

echo "🔄 Reiniciando Docker (se necessário)..."
systemctl status docker | head -5

echo "📋 Containers restantes:"
docker ps -a

echo "💾 Espaço em disco:"
df -h | grep -E "(Filesystem|/dev/)"

echo "🧠 Memória:"
free -h

ENDSSH

echo ""
echo "✅ Diagnóstico concluído!"
echo ""
echo "Agora você pode tentar o deploy novamente:"
echo "  ./deploy-vps-complete.sh"
echo ""



