# 🚨 Diagnóstico Erro 521 - OrthoTrack

## ❌ Erro Identificado
```
curl https://orthotrack.alexptech.com/health
error code: 521
```

**Erro 521**: "Web server is down" - Cloudflare não consegue conectar ao servidor.

## 🔍 Diagnóstico Imediato

Execute no VPS para identificar o problema:

### 1. Verificar Status dos Containers
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. Verificar Nginx
```bash
# Status do nginx
docker logs orthotrack-nginx --tail=20

# Testar nginx localmente
curl -I http://localhost/
curl -I http://localhost:443/
```

### 3. Verificar Certificados SSL
```bash
# Verificar se certificados existem
ls -la /etc/letsencrypt/live/orthotrack.alexptech.com/

# Testar certificados
openssl x509 -in /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem -noout -dates
```

### 4. Verificar Portas
```bash
# Verificar se portas estão abertas
netstat -tlnp | grep :80
netstat -tlnp | grep :443
```

### 5. Testar Backend e Frontend
```bash
# Backend direto
curl http://localhost:8080/health

# Frontend direto  
curl -I http://localhost:3000/
```

## 🚀 Soluções Possíveis

### Solução 1: Nginx Não Está Rodando
```bash
# Verificar status
docker ps | grep nginx

# Se não estiver rodando, iniciar
docker-compose up -d nginx

# Ver logs
docker logs orthotrack-nginx
```

### Solução 2: Problema de Configuração Nginx
```bash
# Testar configuração nginx
docker exec orthotrack-nginx nginx -t

# Se houver erro, usar configuração simples
cat > nginx-minimal.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server orthotrack-backend:8080;
    }

    upstream frontend {
        server orthotrack-frontend:3000;
    }

    server {
        listen 80;
        server_name orthotrack.alexptech.com;
        
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }

        location /health {
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Substituir configuração
cp nginx.conf nginx.conf.ssl-backup
cp nginx-minimal.conf nginx.conf

# Reiniciar nginx
docker-compose restart nginx
```

### Solução 3: Problema com Cloudflare
```bash
# Testar diretamente pelo IP (bypass Cloudflare)
curl -H "Host: orthotrack.alexptech.com" http://72.60.50.248/health

# Se funcionar, o problema é Cloudflare
```

### Solução 4: Reiniciar Tudo
```bash
# Parar tudo
docker-compose down

# Limpar
docker container prune -f

# Iniciar em ordem
docker-compose up -d postgres redis mqtt
sleep 30
docker-compose up -d backend frontend
sleep 60
docker-compose up -d nginx

# Testar
curl http://localhost/health
```

## 🧪 Testes de Verificação

### Teste 1: Containers
```bash
docker ps
# Todos devem estar "Up"
```

### Teste 2: Nginx Local
```bash
curl http://localhost/health
# Deve retornar "healthy"
```

### Teste 3: Backend Direto
```bash
curl http://localhost:8080/health
# Deve retornar JSON
```

### Teste 4: Bypass Cloudflare
```bash
curl -H "Host: orthotrack.alexptech.com" http://72.60.50.248/health
# Se funcionar, problema é Cloudflare
```

## 📋 Checklist de Diagnóstico

Execute em ordem:

- [ ] `docker ps` - Verificar containers
- [ ] `docker logs orthotrack-nginx` - Ver logs nginx
- [ ] `curl http://localhost:8080/health` - Testar backend
- [ ] `curl http://localhost:3000/` - Testar frontend
- [ ] `curl http://localhost/health` - Testar nginx local
- [ ] `netstat -tlnp | grep :80` - Verificar porta 80
- [ ] `ls /etc/letsencrypt/live/orthotrack.alexptech.com/` - Verificar SSL

## 🎯 Próximo Passo

Execute o diagnóstico e me informe os resultados. Provavelmente o nginx não está rodando ou há problema na configuração.