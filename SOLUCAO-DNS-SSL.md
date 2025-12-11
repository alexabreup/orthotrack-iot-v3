# 🔐 Solução DNS e SSL - OrthoTrack

## ❌ Problema Identificado
```
DNS problem: NXDOMAIN looking up A for api.orthotrack.alexptech.com
DNS problem: NXDOMAIN looking up A for www.orthotrack.alexptech.com
```

**Causa**: Os subdomínios não existem no DNS.

## ✅ Soluções

### Opção 1: SSL Apenas para Domínio Principal (Recomendado)

```bash
# No VPS, execute:
certbot certonly --standalone \
    --email admin@alexptech.com \
    --agree-tos \
    --no-eff-email \
    -d orthotrack.alexptech.com
```

### Opção 2: Configurar DNS Primeiro

Você precisa adicionar registros DNS:
- `www.orthotrack.alexptech.com` → `72.60.50.248`
- `api.orthotrack.alexptech.com` → `72.60.50.248`

## 🚀 Configuração Imediata (Opção 1)

### Passo 1: SSL para Domínio Principal
```bash
# Obter certificado apenas para domínio principal
certbot certonly --standalone \
    --email admin@alexptech.com \
    --agree-tos \
    --no-eff-email \
    -d orthotrack.alexptech.com
```

### Passo 2: Configurar Nginx Simples
```bash
# Criar configuração nginx simplificada
cat > nginx-simple-ssl.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

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
        server_name orthotrack.alexptech.com;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS Server
    server {
        listen 443 ssl http2;
        server_name orthotrack.alexptech.com;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/orthotrack.alexptech.com/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # Frontend (root)
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # API routes
        location /api/ {
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

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Substituir configuração nginx
cp nginx.conf nginx.conf.backup
cp nginx-simple-ssl.conf nginx.conf
```

### Passo 3: Atualizar Variáveis de Ambiente
```bash
# Atualizar .env.production para usar domínio único
cat > .env.production << 'EOF'
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
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,http://localhost:3000
EOF
```

### Passo 4: Reiniciar Serviços
```bash
# Reiniciar backend com novas configurações
docker-compose restart backend

# Aguardar backend
sleep 30

# Iniciar nginx
docker-compose up -d nginx

# Aguardar nginx
sleep 20
```

### Passo 5: Testar
```bash
# Testar SSL
curl -I https://orthotrack.alexptech.com/health

# Testar API
curl -I https://orthotrack.alexptech.com/api/v1/health

# Testar redirecionamento HTTP → HTTPS
curl -I http://orthotrack.alexptech.com
```

## 📋 URLs Finais (Configuração Simples)

- **Frontend**: https://orthotrack.alexptech.com
- **API**: https://orthotrack.alexptech.com/api/
- **WebSocket**: wss://orthotrack.alexptech.com/ws
- **Login**: admin@aacd.org.br / password

## 🔄 Configuração Automática de Renovação

```bash
# Configurar renovação automática
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker restart orthotrack-nginx") | crontab -
```

## 🧪 Verificação Final

```bash
# Status containers
docker-compose ps

# Teste HTTPS
curl https://orthotrack.alexptech.com/health

# Teste API
curl https://orthotrack.alexptech.com/api/v1/health

# Verificar certificado
openssl x509 -in /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem -noout -dates
```

## 📝 Nota sobre Frontend

O frontend precisará ser reconstruído com as novas URLs:
- `VITE_API_BASE_URL=https://orthotrack.alexptech.com`
- `VITE_WS_URL=wss://orthotrack.alexptech.com/ws`

Isso será feito no próximo deploy do GitHub Actions.