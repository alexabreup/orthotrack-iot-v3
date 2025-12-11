#!/bin/bash

echo "🔍 Diagnóstico completo dos logs - VPS"

echo "📋 Status atual dos containers:"
docker-compose ps

echo ""
echo "🔧 Logs do Backend (últimas 50 linhas):"
docker-compose logs --tail=50 backend

echo ""
echo "🦟 Logs do MQTT (últimas 30 linhas):"
docker-compose logs --tail=30 mqtt

echo ""
echo "📊 Logs do PostgreSQL (últimas 20 linhas):"
docker-compose logs --tail=20 postgres

echo ""
echo "🔴 Logs do Redis (últimas 20 linhas):"
docker-compose logs --tail=20 redis

echo ""
echo "🌐 Verificando conectividade interna:"
echo "- Testando PostgreSQL..."
docker exec orthotrack-postgres pg_isready -U orthotrack -d orthotrack_prod || echo "❌ PostgreSQL não está pronto"

echo "- Testando Redis..."
docker exec orthotrack-redis redis-cli --raw incr ping || echo "❌ Redis não está respondendo"

echo ""
echo "🔍 Verificando variáveis de ambiente do backend:"
docker exec orthotrack-backend env | grep -E "(DB_|REDIS_|MQTT_|JWT_)" | sort

echo ""
echo "📡 Testando conectividade de rede:"
docker exec orthotrack-backend ping -c 2 orthotrack-postgres || echo "❌ Backend não consegue alcançar PostgreSQL"
docker exec orthotrack-backend ping -c 2 orthotrack-redis || echo "❌ Backend não consegue alcançar Redis"
docker exec orthotrack-backend ping -c 2 orthotrack-mqtt || echo "❌ Backend não consegue alcançar MQTT"