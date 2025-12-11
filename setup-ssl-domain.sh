#!/bin/bash

# Script para configurar SSL com Let's Encrypt para orthotrack.alexptech.com
echo "🔐 Configurando SSL para orthotrack.alexptech.com..."

# Verificar se certbot está instalado
if ! command -v certbot &> /dev/null; then
    echo "📦 Instalando Certbot..."
    apt update
    apt install -y certbot python3-certbot-nginx
fi

# Parar nginx se estiver rodando
echo "⏹️ Parando nginx temporariamente..."
docker stop orthotrack-nginx 2>/dev/null || true

# Obter certificados SSL
echo "🔐 Obtendo certificados SSL..."
certbot certonly --standalone \
    --email admin@alexptech.com \
    --agree-tos \
    --no-eff-email \
    -d orthotrack.alexptech.com \
    -d www.orthotrack.alexptech.com \
    -d api.orthotrack.alexptech.com

# Verificar se certificados foram criados
if [ ! -f "/etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem" ]; then
    echo "❌ Falha ao obter certificados SSL!"
    echo "Verifique se:"
    echo "1. Os domínios apontam para este servidor (72.60.50.248)"
    echo "2. As portas 80 e 443 estão abertas"
    echo "3. Não há outros serviços usando essas portas"
    exit 1
fi

echo "✅ Certificados SSL obtidos com sucesso!"

# Criar configuração nginx com SSL
echo "📝 Criando configuração nginx com SSL..."
cat > nginx-ssl.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream servers
    upstream backend {
        server orthotrack-backend:8080;
    }

    upstream frontend {
        server orthotrack-frontend:3000;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name orthotrack.alexptech.com www.orthotrack.alexptech.com api.orthotrack.alexptech.com;
        return 301 https://$server_name$request_uri;
    }

    # Main application (Frontend) - HTTPS
    server {
        listen 443 ssl http2;
        server_name orthotrack.alexptech.com www.orthotrack.alexptech.com;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/orthotrack.alexptech.com/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # API Backend - HTTPS
    server {
        listen 443 ssl http2;
        server_name api.orthotrack.alexptech.com;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/orthotrack.alexptech.com/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # API routes
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # WebSocket
        location /ws {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
        }

        # Auth endpoints (more restrictive)
        location /api/v1/auth/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            access_log off;
            proxy_pass http://backend/health;
        }
    }
}
EOF

# Substituir configuração nginx
cp nginx.conf nginx.conf.backup
cp nginx-ssl.conf nginx.conf

# Configurar renovação automática
echo "🔄 Configurando renovação automática..."
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker restart orthotrack-nginx") | crontab -

# Iniciar nginx com SSL
echo "🚀 Iniciando nginx com SSL..."
docker-compose -f docker-compose.prod.yml up -d nginx

# Aguardar nginx iniciar
sleep 10

# Testar SSL
echo "🧪 Testando SSL..."
curl -I https://orthotrack.alexptech.com/health && echo "✅ Frontend SSL OK" || echo "❌ Frontend SSL falhou"
curl -I https://api.orthotrack.alexptech.com/health && echo "✅ API SSL OK" || echo "❌ API SSL falhou"

echo ""
echo "✅ SSL configurado com sucesso!"
echo ""
echo "📋 URLs com SSL:"
echo "🌐 Frontend: https://orthotrack.alexptech.com"
echo "🔗 API: https://api.orthotrack.alexptech.com"
echo "🔒 WebSocket: wss://api.orthotrack.alexptech.com/ws"
echo ""
echo "📋 Informações importantes:"
echo "• Certificados renovam automaticamente"
echo "• Redirecionamento HTTP → HTTPS ativo"
echo "• Headers de segurança configurados"
echo "• Rate limiting ativo"