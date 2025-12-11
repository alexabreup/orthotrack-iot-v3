#!/bin/bash

# Script para corrigir Redis imediatamente no VPS
echo "🔧 Corrigindo Redis no VPS..."

# Parar Redis que está com problema
echo "⏹️ Parando Redis problemático..."
docker stop orthotrack-redis
docker rm orthotrack-redis

# Corrigir health check do Redis no docker-compose
echo "📝 Corrigindo health check do Redis..."
sed -i 's/test: \["CMD", "redis-cli", "--raw", "incr", "ping"\]/test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]/' docker-compose.prod.yml

# Recriar Redis com configuração correta
echo "🚀 Recriando Redis..."
docker-compose -f docker-compose.prod.yml up -d redis

# Aguardar Redis ficar pronto
echo "⏳ Aguardando Redis ficar pronto..."
sleep 30

# Verificar status
echo "🏥 Verificando status do Redis..."
docker-compose -f docker-compose.prod.yml ps redis

# Testar Redis manualmente
echo "🧪 Testando Redis..."
docker exec orthotrack-redis redis-cli -a redis_secure_2024 ping

# Iniciar backend agora que Redis está funcionando
echo "🚀 Iniciando backend..."
docker-compose -f docker-compose.prod.yml up -d backend

# Aguardar backend
echo "⏳ Aguardando backend..."
sleep 60

# Verificar tudo
echo "📊 Status final:"
docker-compose -f docker-compose.prod.yml ps

echo "✅ Correção concluída!"
echo "🧪 Teste: curl http://localhost:8080/health"