#!/bin/bash

# 🔧 Fix Imediato do Redis - OrthoTrack
# Este script corrige o problema do Redis no docker-compose.yml

echo "🔧 Iniciando correção do Redis..."

# Parar todos os containers
echo "⏹️ Parando containers..."
docker compose down

# Backup do arquivo atual
echo "💾 Fazendo backup do docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)

# Criar versão corrigida do docker-compose.yml
echo "🔄 Corrigindo configuração do Redis..."

# Usar sed para corrigir a linha do comando do Redis
sed -i 's/command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-redis123}/command: redis-server --appendonly yes --requirepass redis123/' docker-compose.yml

echo "✅ Configuração do Redis corrigida!"

# Verificar se a correção foi aplicada
echo "🔍 Verificando correção..."
grep -n "command: redis-server" docker-compose.yml

# Reiniciar os serviços
echo "🚀 Reiniciando serviços..."
docker compose up -d

# Aguardar um pouco para os serviços subirem
echo "⏳ Aguardando serviços iniciarem..."
sleep 10

# Verificar status
echo "📊 Verificando status dos containers..."
docker compose ps

# Testar conexão com Redis
echo "🧪 Testando conexão com Redis..."
docker exec orthotrack-redis redis-cli -a redis123 ping

echo "✅ Fix do Redis concluído!"
echo ""
echo "📋 Resumo das alterações:"
echo "- Removida dependência da variável REDIS_PASSWORD"
echo "- Definida senha fixa 'redis123' para o Redis"
echo "- Backup criado: docker-compose.yml.backup.*"
echo ""
echo "🔗 Para testar a conexão:"
echo "docker exec orthotrack-redis redis-cli -a redis123 ping"