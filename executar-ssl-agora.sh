#!/bin/bash

# Script para executar SSL imediatamente após deploy do GitHub Actions
echo "🚀 Configurando SSL após deploy do GitHub Actions..."

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script no diretório /opt/orthotrack"
    exit 1
fi

# Verificar status atual
echo "📊 Status atual dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}"

# Verificar se backend está funcionando
echo ""
echo "🧪 Testando backend atual:"
curl -f http://localhost:8080/health && echo " ✅ Backend funcionando" || echo " ❌ Backend com problema"

# Configurar SSL se não existir
if [ ! -f "/etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem" ]; then
    echo ""
    echo "🔐 Configurando SSL pela primeira vez..."
    
    # Instalar certbot se necessário
    if ! command -v certbot &> /dev/null; then
        echo "📦 Instalando Certbot..."
        apt update
        apt install -y certbot python3-certbot-nginx
    fi
    
    # Parar nginx temporariamente para obter certificados
    echo "⏹️ Parando nginx temporariamente..."
    docker stop orthotrack-nginx 2>/dev/null || true
    
    # Obter certificados
    echo "🔐 Obtendo certificados SSL..."
    certbot certonly --standalone \
        --email admin@alexptech.com \
        --agree-tos \
        --no-eff-email \
        -d orthotrack.alexptech.com \
        -d www.orthotrack.alexptech.com \
        -d api.orthotrack.alexptech.com
    
    if [ $? -eq 0 ]; then
        echo "✅ Certificados SSL obtidos com sucesso!"
        
        # Configurar renovação automática
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker restart orthotrack-nginx") | crontab -
        echo "✅ Renovação automática configurada"
    else
        echo "❌ Falha ao obter certificados SSL"
        echo "Verifique se os domínios apontam para este servidor"
        exit 1
    fi
else
    echo "✅ Certificados SSL já existem"
fi

# Atualizar .env.production para SSL
echo ""
echo "📝 Atualizando .env.production para SSL..."
cat > .env.production << 'EOF'
# Database
DB_HOST=orthotrack-postgres
DB_PORT=5432
DB_NAME=orthotrack_prod
DB_USER=orthotrack
DB_PASSWORD=orthotrack_secure_2024
DB_SSL_MODE=require

# Redis
REDIS_HOST=orthotrack-redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_2024
REDIS_DB=0
REDIS_POOL_SIZE=20
REDIS_MIN_IDLE_CONNS=10
REDIS_MAX_RETRIES=5

# MQTT
MQTT_HOST=orthotrack-mqtt
MQTT_PORT=1883
MQTT_BROKER_URL=tcp://orthotrack-mqtt:1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt_secure_2024
MQTT_CLIENT_ID=orthotrack-backend-prod

# JWT
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
JWT_EXPIRE_HOURS=24

# Server
PORT=8080
GIN_MODE=release

# CORS - SSL Domains
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000

# Alertas
IOT_ALERT_BATTERY_LOW=15
IOT_ALERT_TEMP_HIGH=45.0
IOT_ALERT_TEMP_LOW=5.0
EOF

# Reiniciar backend com novas variáveis
echo ""
echo "🔄 Reiniciando backend com configurações SSL..."
docker-compose restart backend

# Aguardar backend
echo "⏳ Aguardando backend reiniciar..."
sleep 30

# Iniciar nginx com SSL
echo ""
echo "🌐 Iniciando nginx com SSL..."
docker-compose up -d nginx

# Aguardar nginx
echo "⏳ Aguardando nginx iniciar..."
sleep 20

# Verificar status final
echo ""
echo "📊 Status final dos containers:"
docker-compose ps

# Testar endpoints
echo ""
echo "🧪 Testando endpoints finais:"

echo "Backend local:"
curl -f http://localhost:8080/health && echo " ✅ Backend local OK" || echo " ❌ Backend local falhou"

echo "Frontend local:"
curl -f -s -I http://localhost:3000/ && echo "✅ Frontend local OK" || echo "❌ Frontend local falhou"

echo "Nginx local:"
curl -f -s -I http://localhost/ && echo "✅ Nginx local OK" || echo "❌ Nginx local falhou"

echo "SSL Frontend:"
curl -f -s -I https://orthotrack.alexptech.com/health && echo "✅ SSL Frontend OK" || echo "❌ SSL Frontend falhou"

echo "SSL API:"
curl -f -s -I https://api.orthotrack.alexptech.com/health && echo "✅ SSL API OK" || echo "❌ SSL API falhou"

echo ""
echo "✅ Configuração SSL concluída!"
echo ""
echo "📋 URLs de acesso:"
echo "🌐 Frontend: https://orthotrack.alexptech.com"
echo "🔗 API: https://api.orthotrack.alexptech.com"
echo "🔒 WebSocket: wss://api.orthotrack.alexptech.com/ws"
echo "🔑 Login: admin@aacd.org.br"
echo "🔒 Senha: password"
echo ""
echo "📊 Para monitorar logs:"
echo "docker-compose logs -f"