# 🚀 Comandos Diretos para VPS - OrthoTrack

## ❌ Problema
Os scripts `.sh` não estão no VPS porque o GitHub Actions só copia arquivos específicos.

## ✅ Solução: Comandos Diretos

### 1. 📊 Verificar Status Atual

```bash
# Conectar ao VPS
ssh root@72.60.50.248

# Ir para diretório
cd /opt/orthotrack

# Verificar containers
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Testar backend
curl -f http://localhost:8080/health

# Testar frontend  
curl -f -I http://localhost:3000/

# Ver logs se necessário
docker-compose logs backend --tail=20
```

### 2. 🔐 Configurar SSL (Método Rápido)

```bash
# No VPS, execute linha por linha:

# Instalar certbot
apt update && apt install -y certbot python3-certbot-nginx

# Parar nginx temporariamente
docker stop orthotrack-nginx 2>/dev/null || true

# Obter certificados SSL
certbot certonly --standalone \
    --email admin@alexptech.com \
    --agree-tos \
    --no-eff-email \
    -d orthotrack.alexptech.com \
    -d www.orthotrack.alexptech.com \
    -d api.orthotrack.alexptech.com

# Configurar renovação automática
(crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker restart orthotrack-nginx") | crontab -

# Atualizar .env.production
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
ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
EOF

# Reiniciar backend
docker-compose restart backend

# Aguardar 30 segundos
sleep 30

# Iniciar nginx
docker-compose up -d nginx

# Testar SSL
curl -I https://orthotrack.alexptech.com/health
curl -I https://api.orthotrack.alexptech.com/health
```

### 3. 📝 Criar Scripts no VPS (Alternativa)

```bash
# Criar script de verificação
cat > verificar-status.sh << 'EOF'
#!/bin/bash
echo "📊 Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}"
echo ""
echo "🧪 Testando endpoints:"
curl -f http://localhost:8080/health && echo "✅ Backend OK" || echo "❌ Backend falhou"
curl -f -I http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend falhou"
curl -f -I https://orthotrack.alexptech.com/health && echo "✅ SSL OK" || echo "❌ SSL falhou"
EOF

chmod +x verificar-status.sh

# Usar o script
./verificar-status.sh
```

### 4. 🆘 Corrigir Problemas Comuns

```bash
# Se containers não estão funcionando:
docker-compose down
docker container prune -f
docker-compose up -d

# Se backend não responde:
docker-compose restart backend
sleep 30
curl http://localhost:8080/health

# Se nginx não funciona:
docker-compose restart nginx
sleep 10
curl -I http://localhost/

# Ver logs detalhados:
docker-compose logs backend
docker-compose logs frontend
docker-compose logs nginx
```

## 🎯 Sequência Recomendada

### Passo 1: Verificar Status
```bash
ssh root@72.60.50.248
cd /opt/orthotrack
docker ps
curl http://localhost:8080/health
```

### Passo 2: Configurar SSL (se necessário)
```bash
# Execute os comandos da seção 2 acima
```

### Passo 3: Testar Tudo
```bash
curl https://orthotrack.alexptech.com/health
curl https://api.orthotrack.alexptech.com/health
```

## 📋 URLs Finais

Após configurar SSL:
- **Frontend**: https://orthotrack.alexptech.com
- **API**: https://api.orthotrack.alexptech.com  
- **WebSocket**: wss://api.orthotrack.alexptech.com/ws
- **Login**: admin@aacd.org.br / password

## 🔍 Verificação Rápida

```bash
# Status containers
docker ps

# Teste backend
curl http://localhost:8080/health

# Teste SSL (após configurar)
curl https://orthotrack.alexptech.com/health

# Ver logs se necessário
docker-compose logs --tail=20
```

## 📝 Nota Importante

Os scripts `.sh` que criamos estão no repositório GitHub, mas o workflow do GitHub Actions não os copia automaticamente para o VPS. Por isso, use os comandos diretos acima ou crie os scripts manualmente no VPS.