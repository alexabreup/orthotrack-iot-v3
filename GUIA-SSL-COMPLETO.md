# 🔐 Guia Completo SSL - orthotrack.alexptech.com

## 🎯 Objetivo
Configurar SSL/HTTPS para o domínio `orthotrack.alexptech.com` com certificados Let's Encrypt.

## 📋 Pré-requisitos

### 1. DNS Configurado
Certifique-se que os domínios apontam para o VPS (72.60.50.248):

```bash
# Verificar DNS
nslookup orthotrack.alexptech.com
nslookup www.orthotrack.alexptech.com  
nslookup api.orthotrack.alexptech.com
```

**Resultado esperado**: Todos devem retornar `72.60.50.248`

### 2. Portas Abertas
```bash
# Verificar portas
netstat -tlnp | grep :80
netstat -tlnp | grep :443
```

## 🚀 Opção 1: Script Automático (Recomendado)

```bash
# No VPS, execute:
cd /opt/orthotrack
bash deploy-completo-ssl.sh
```

Este script faz tudo:
- ✅ Clona código fonte se necessário
- ✅ Configura variáveis de ambiente para SSL
- ✅ Obtém certificados Let's Encrypt
- ✅ Configura nginx com SSL
- ✅ Builda e inicia todos os serviços
- ✅ Configura renovação automática

## 🔧 Opção 2: Passo a Passo Manual

### Passo 1: Preparar Ambiente
```bash
cd /opt/orthotrack

# Parar containers
docker-compose -f docker-compose.prod.yml down
```

### Passo 2: Obter Certificados SSL
```bash
# Instalar certbot
apt update
apt install -y certbot python3-certbot-nginx

# Obter certificados
certbot certonly --standalone \
    --email admin@alexptech.com \
    --agree-tos \
    --no-eff-email \
    -d orthotrack.alexptech.com \
    -d www.orthotrack.alexptech.com \
    -d api.orthotrack.alexptech.com
```

### Passo 3: Configurar Variáveis de Ambiente
```bash
cat > .env.production << 'EOF'
DB_PASSWORD=orthotrack_secure_2024
REDIS_PASSWORD=redis_secure_2024
MQTT_PASSWORD=mqtt_secure_2024
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure

# URLs SSL
VITE_API_BASE_URL=https://api.orthotrack.alexptech.com
VITE_WS_URL=wss://api.orthotrack.alexptech.com/ws
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
EOF
```

### Passo 4: Iniciar Serviços
```bash
# Usar docker-compose com SSL
docker-compose -f docker-compose.ssl.yml up -d --build
```

## 🧪 Verificação

### Testar Certificados
```bash
# Verificar certificados
openssl x509 -in /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem -text -noout

# Testar SSL
curl -I https://orthotrack.alexptech.com/health
curl -I https://api.orthotrack.alexptech.com/health
```

### Testar Redirecionamento HTTP → HTTPS
```bash
curl -I http://orthotrack.alexptech.com
# Deve retornar: HTTP/1.1 301 Moved Permanently
# Location: https://orthotrack.alexptech.com/
```

### Verificar Headers de Segurança
```bash
curl -I https://orthotrack.alexptech.com
# Deve incluir:
# Strict-Transport-Security: max-age=31536000; includeSubDomains
# X-Frame-Options: DENY
# X-Content-Type-Options: nosniff
```

## 📊 URLs Finais

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **Frontend** | https://orthotrack.alexptech.com | Interface principal |
| **API** | https://api.orthotrack.alexptech.com | Backend REST API |
| **WebSocket** | wss://api.orthotrack.alexptech.com/ws | Conexão em tempo real |
| **Desenvolvimento** | http://72.60.50.248:3000 | Acesso direto (sem SSL) |

## 🔄 Renovação Automática

O script configura renovação automática via cron:
```bash
# Ver cron configurado
crontab -l

# Deve mostrar:
# 0 12 * * * /usr/bin/certbot renew --quiet && docker restart orthotrack-nginx
```

### Testar Renovação
```bash
# Teste seco (não renova de verdade)
certbot renew --dry-run
```

## 🆘 Troubleshooting

### Problema: DNS não resolve
```bash
# Verificar DNS
dig orthotrack.alexptech.com
dig api.orthotrack.alexptech.com

# Se não resolver, aguarde propagação DNS (até 24h)
```

### Problema: Certificado não obtido
```bash
# Verificar logs
journalctl -u certbot

# Verificar se portas estão livres
netstat -tlnp | grep :80
netstat -tlnp | grep :443

# Parar serviços que usam essas portas
docker stop orthotrack-nginx
```

### Problema: Nginx não inicia
```bash
# Verificar logs
docker logs orthotrack-nginx

# Verificar configuração
nginx -t -c /opt/orthotrack/nginx.conf

# Verificar se certificados existem
ls -la /etc/letsencrypt/live/orthotrack.alexptech.com/
```

### Problema: CORS
```bash
# Verificar variáveis de ambiente
docker exec orthotrack-backend env | grep ALLOWED_ORIGINS

# Deve incluir os domínios SSL
```

## 📋 Checklist Final

- [ ] DNS configurado (orthotrack.alexptech.com → 72.60.50.248)
- [ ] Certificados SSL obtidos
- [ ] Nginx configurado com SSL
- [ ] Redirecionamento HTTP → HTTPS funcionando
- [ ] Frontend acessível via https://orthotrack.alexptech.com
- [ ] API acessível via https://api.orthotrack.alexptech.com
- [ ] WebSocket funcionando via wss://
- [ ] Login funcionando (admin@aacd.org.br / password)
- [ ] Renovação automática configurada

## 🎉 Sucesso!

Após completar, você terá:
- ✅ **SSL/HTTPS ativo** com certificados válidos
- ✅ **Domínio personalizado** orthotrack.alexptech.com
- ✅ **Segurança aprimorada** com headers de segurança
- ✅ **Renovação automática** de certificados
- ✅ **Performance otimizada** com HTTP/2 e gzip