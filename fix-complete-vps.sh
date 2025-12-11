#!/bin/bash

# Script completo para corrigir VPS
echo "🔧 Correção completa do VPS OrthoTrack..."

# Parar todos os containers
echo "⏹️ Parando todos os containers..."
docker-compose -f docker-compose.prod.yml down || true
docker stop $(docker ps -aq) 2>/dev/null || true

# Limpar containers órfãos
echo "🧹 Limpando containers..."
docker container prune -f
docker image prune -f

# Fazer login no GitHub Container Registry
echo "🔐 Login no GitHub Container Registry..."
echo "Você precisa de um Personal Access Token do GitHub"
echo "Gere em: https://github.com/settings/tokens"
echo "Permissões necessárias: read:packages"
echo ""
read -p "GitHub username: " GITHUB_USER
read -s -p "GitHub Personal Access Token: " GITHUB_TOKEN
echo ""

echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USER" --password-stdin

# Puxar imagens corretas do GitHub Container Registry
echo "📥 Puxando imagens do GitHub Container Registry..."
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest

# Verificar se as imagens foram baixadas
echo "🔍 Verificando imagens baixadas..."
docker images | grep ghcr.io/alexabreup/orthotrack-iot-v3

# Criar arquivo .env.production correto
echo "📝 Criando .env.production..."
cat > .env.production << 'EOF'
DB_PASSWORD=orthotrack_secure_2024
REDIS_PASSWORD=redis_secure_2024
MQTT_PASSWORD=mqtt_secure_2024
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
EOF

# Criar mosquitto.conf se não existir
if [ ! -f mosquitto.conf ]; then
    echo "📝 Criando mosquitto.conf..."
    cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd

listener 9001
protocol websockets
allow_anonymous false

log_dest stdout
log_type error
log_type warning
log_type notice
log_type information
connection_messages true
log_timestamp true

persistence true
persistence_location /mosquitto/data/
autosave_interval 1800
EOF
fi

# Criar arquivo de senhas MQTT
echo "🔐 Configurando MQTT..."
docker run --rm -v $(pwd):/mosquitto/config eclipse-mosquitto:2.0-openssl mosquitto_passwd -c -b /mosquitto/config/mosquitto_passwd orthotrack mqtt_secure_2024

# Verificar docker-compose.prod.yml
echo "🔍 Verificando docker-compose.prod.yml..."
if grep -q "ghcr.io/alexabreup/orthotrack-iot-v3" docker-compose.prod.yml; then
    echo "✅ Docker-compose está correto (usando GitHub Container Registry)"
else
    echo "❌ Docker-compose precisa ser corrigido"
    echo "Atualizando referências das imagens..."
    sed -i 's|image: alexabreup/orthotrack-backend:latest|image: ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest|g' docker-compose.prod.yml
    sed -i 's|image: alexabreup/orthotrack-frontend:latest|image: ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest|g' docker-compose.prod.yml
fi

# Iniciar serviços em ordem
echo "🚀 Iniciando serviços..."

# 1. Banco de dados primeiro
echo "📊 Iniciando PostgreSQL..."
docker-compose -f docker-compose.prod.yml up -d postgres
sleep 20

# 2. Redis
echo "🔴 Iniciando Redis..."
docker-compose -f docker-compose.prod.yml up -d redis
sleep 20

# 3. MQTT
echo "📡 Iniciando MQTT..."
docker-compose -f docker-compose.prod.yml up -d mqtt
sleep 20

# 4. Backend
echo "⚙️ Iniciando Backend..."
docker-compose -f docker-compose.prod.yml up -d backend
sleep 60

# 5. Frontend
echo "🎨 Iniciando Frontend..."
docker-compose -f docker-compose.prod.yml up -d frontend
sleep 30

# 6. Nginx (se configurado)
if [ -f nginx.conf ]; then
    echo "🌐 Iniciando Nginx..."
    docker-compose -f docker-compose.prod.yml up -d nginx
    sleep 20
fi

# Verificar status final
echo "📊 Status final dos serviços:"
docker-compose -f docker-compose.prod.yml ps

# Testar endpoints
echo "🧪 Testando endpoints..."
echo ""
echo "Backend health:"
curl -f http://localhost:8080/health && echo " ✅ Backend OK" || echo " ❌ Backend falhou"

echo "Frontend:"
curl -f -s -o /dev/null http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend falhou"

if [ -f nginx.conf ]; then
    echo "Nginx:"
    curl -f -s -o /dev/null http://localhost/ && echo "✅ Nginx OK" || echo "❌ Nginx falhou"
fi

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📋 Informações de acesso:"
echo "🌐 URL: http://72.60.50.248"
echo "🔑 Login: admin@aacd.org.br"
echo "🔒 Senha: password"
echo ""
echo "📊 Para monitorar logs:"
echo "docker-compose -f docker-compose.prod.yml logs -f"