#!/bin/bash

echo "🔧 CRIANDO USUÁRIO E BANCO POSTGRESQL"

# Parar backend
echo "📦 Parando backend..."
docker-compose stop backend

echo "🗄️ Criando usuário e banco no PostgreSQL..."

# Conectar ao PostgreSQL e criar usuário/banco
docker exec -i orthotrack-postgres psql -U postgres << 'EOF'
-- Criar usuário orthotrack se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'orthotrack') THEN
        CREATE USER orthotrack WITH PASSWORD 'orthotrack_secure_2024';
    END IF;
END
$$;

-- Criar banco se não existir
SELECT 'CREATE DATABASE orthotrack_prod OWNER orthotrack'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'orthotrack_prod')\gexec

-- Dar permissões
GRANT ALL PRIVILEGES ON DATABASE orthotrack_prod TO orthotrack;
ALTER USER orthotrack CREATEDB;

-- Verificar
\du
\l
EOF

echo "✅ Usuário e banco criados!"

echo "🔍 Testando conexão direta..."
docker exec -i orthotrack-postgres psql -U orthotrack -d orthotrack_prod -c "SELECT version();"

echo "🚀 Reiniciando backend..."
docker-compose up -d backend

echo "⏳ Aguardando backend (30s)..."
sleep 30

echo "📋 Status dos containers:"
docker-compose ps

echo ""
echo "🔍 Logs do backend (últimas 15 linhas):"
docker-compose logs --tail=15 backend

echo ""
echo "🏥 Testando backend..."
curl -f http://localhost:8080/health && echo "✅ Backend OK!" || echo "❌ Backend ainda com problema"

echo ""
echo "🔄 Testando nginx..."
curl -f http://localhost/health && echo "✅ Nginx OK!" || echo "❌ Nginx ainda com problema"

echo ""
echo "🌐 Testando acesso externo..."
curl -f http://72.60.50.248/health && echo "✅ Acesso externo OK!" || echo "❌ Problema no acesso externo"

echo ""
echo "✅ USUÁRIO POSTGRESQL CRIADO!"
echo "🌐 Acesse: http://72.60.50.248"