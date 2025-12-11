#!/bin/bash

# Script para criar todos os scripts necessários no VPS
echo "📝 Criando scripts necessários no VPS..."

# Script 1: Verificar status
cat > verificar-status-vps.sh << 'EOF'
#!/bin/bash

# Script para verificar status atual do VPS
echo "🔍 Verificando status atual do VPS..."

echo ""
echo "📊 Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🧪 Testando endpoints locais:"
echo "Backend health:"
curl -f -s http://localhost:8080/health && echo " ✅ Backend OK" || echo " ❌ Backend falhou"

echo "Frontend:"
curl -f -s -I http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend falhou"

echo "Nginx:"
curl -f -s -I http://localhost/ && echo "✅ Nginx OK" || echo "❌ Nginx falhou"

echo ""
echo "🌐 Testando domínios SSL:"
echo "Frontend SSL:"
curl -f -s -I https://orthotrack.alexptech.com/health && echo "✅ SSL Frontend OK" || echo "❌ SSL Frontend falhou"

echo "API SSL:"
curl -f -s -I https://api.orthotrack.alexptech.com/health && echo "✅ SSL API OK" || echo "❌ SSL API falhou"

echo ""
echo "🔐 Verificando certificados SSL:"
if [ -f "/etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem" ]; then
    echo "✅ Certificados SSL existem"
    openssl x509 -in /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem -noout -dates
else
    echo "❌ Certificados SSL não encontrados"
fi

echo ""
echo "📋 Arquivos de configuração:"
ls -la | grep -E "(docker-compose|nginx|mosquitto|\.env)"

echo ""
echo "💾 Uso de disco:"
df -h /

echo ""
echo "🔍 Logs recentes (últimas 10 linhas):"
docker-compose logs --tail=10 backend 2>/dev/null || echo "Logs do backend não disponíveis"
EOF

# Script 2: Configurar SSL
cat > configurar-ssl.sh << 'EOF'
#!/bin/bash

# Script para configurar SSL
echo "🔐 Configurando SSL para orthotrack.alexptech.com..."

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Execute este script no diretório /opt/orthotrack"
    exit 1
fi

# Verificar status atual
echo "📊 Status atual dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}"

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
cat > .env.production << 'ENVEOF'
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
ENVEOF

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
EOF

# Script 3: Corrigir problemas
cat > corrigir-problemas.sh << 'EOF'
#!/bin/bash

# Script para corrigir problemas comuns
echo "🔧 Corrigindo problemas comuns..."

echo "⏹️ Parando todos os containers..."
docker-compose down

echo "🧹 Limpando containers órfãos..."
docker container prune -f

echo "📝 Verificando .env.production..."
if [ ! -f ".env.production" ]; then
    echo "Criando .env.production..."
    cat > .env.production << 'ENVEOF'
DB_HOST=orthotrack-postgres
DB_PORT=5432
DB_NAME=orthotrack_prod
DB_USER=orthotrack
DB_PASSWORD=orthotrack_secure_2024
REDIS_HOST=orthotrack-redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_2024
MQTT_HOST=orthotrack-mqtt
MQTT_PORT=1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt_secure_2024
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
PORT=8080
GIN_MODE=release
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
ENVEOF
fi

echo "🚀 Iniciando serviços em ordem..."
docker-compose up -d postgres redis mqtt
sleep 30
docker-compose up -d backend frontend
sleep 60
docker-compose up -d nginx

echo "📊 Status final:"
docker-compose ps

echo "🧪 Testando:"
curl -f http://localhost:8080/health && echo "✅ Backend OK" || echo "❌ Backend falhou"
EOF

# Tornar scripts executáveis
chmod +x verificar-status-vps.sh
chmod +x configurar-ssl.sh
chmod +x corrigir-problemas.sh

echo "✅ Scripts criados com sucesso!"
echo ""
echo "📋 Scripts disponíveis:"
echo "• verificar-status-vps.sh - Verifica status atual"
echo "• configurar-ssl.sh - Configura SSL"
echo "• corrigir-problemas.sh - Corrige problemas comuns"
echo ""
echo "🚀 Para usar:"
echo "bash verificar-status-vps.sh"
echo "bash configurar-ssl.sh"
echo "bash corrigir-problemas.sh"