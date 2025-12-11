#!/bin/bash

# 🚀 Deploy Rápido VPS - OrthoTrack
# Este script faz deploy direto no VPS com build local

set -e

VPS_HOST="72.60.50.248"
VPS_USER="root"
DEPLOY_PATH="/opt/orthotrack"

echo "🚀 Iniciando deploy rápido no VPS..."

# 1. Parar serviços existentes
echo "⏹️  Parando serviços existentes..."
ssh $VPS_USER@$VPS_HOST "cd $DEPLOY_PATH && docker-compose down || true"

# 2. Copiar arquivos atualizados
echo "📦 Copiando arquivos..."
scp docker-compose.local-build.yml $VPS_USER@$VPS_HOST:$DEPLOY_PATH/docker-compose.yml
scp -r backend/ $VPS_USER@$VPS_HOST:$DEPLOY_PATH/
scp -r frontend/ $VPS_USER@$VPS_HOST:$DEPLOY_PATH/

# 3. Criar arquivo .env com valores padrão
echo "🔧 Criando arquivo .env..."
ssh $VPS_USER@$VPS_HOST "cat > $DEPLOY_PATH/.env << 'EOF'
# Valores padrão para teste rápido
DB_PASSWORD=postgres123
REDIS_PASSWORD=
JWT_SECRET=jwt_secret_for_testing_change_in_production
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=
EOF"

# 4. Build e deploy
echo "🏗️  Fazendo build e deploy..."
ssh $VPS_USER@$VPS_HOST "cd $DEPLOY_PATH && docker-compose up -d --build"

# 5. Aguardar serviços
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 60

# 6. Verificar status
echo "✅ Verificando status dos serviços..."
ssh $VPS_USER@$VPS_HOST "cd $DEPLOY_PATH && docker-compose ps"

# 7. Teste básico
echo "🧪 Testando endpoints..."
echo "Frontend: http://$VPS_HOST:3000"
echo "Backend: http://$VPS_HOST:8080"
echo "API Health: http://$VPS_HOST:8080/health"

# Teste de conectividade
curl -f -s -o /dev/null http://$VPS_HOST:3000 && echo "✅ Frontend OK" || echo "❌ Frontend falhou"
curl -f -s -o /dev/null http://$VPS_HOST:8080/health && echo "✅ Backend OK" || echo "❌ Backend falhou"

echo ""
echo "🎉 Deploy concluído!"
echo "🌐 Acesse: http://$VPS_HOST:3000"
echo "📊 API: http://$VPS_HOST:8080"
echo ""
echo "📋 Para ver logs:"
echo "ssh $VPS_USER@$VPS_HOST 'cd $DEPLOY_PATH && docker-compose logs -f'"