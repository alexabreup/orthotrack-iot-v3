# 🚀 Setup Completo VPS - Instalação Imediata

## 🔧 Instalar Docker e Docker Compose

Execute no VPS (como root):

```bash
# 1. Atualizar sistema
apt update && apt upgrade -y

# 2. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. Instalar Docker Compose (versão mais recente)
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 4. Verificar instalação
docker --version
docker-compose --version

# 5. Iniciar Docker
systemctl start docker
systemctl enable docker
```

## 🚀 Deploy Imediato Após Instalação

```bash
# 1. Ir para diretório
cd /opt/orthotrack

# 2. Parar qualquer container rodando
docker ps -q | xargs -r docker stop
docker ps -aq | xargs -r docker rm

# 3. Usar configuração com build local
cp docker-compose.local-build.yml docker-compose.yml

# 4. Criar .env com valores funcionais
cat > .env << 'EOF'
DB_PASSWORD=postgres123
REDIS_PASSWORD=
JWT_SECRET=jwt_secret_for_testing_change_in_production
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=
EOF

# 5. Build e deploy
docker-compose up -d --build

# 6. Verificar status
docker-compose ps
docker-compose logs -f
```

## ⚡ Comando Único (Copie e Cole)

```bash
# Setup completo em um comando
apt update && apt upgrade -y && \
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && \
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
chmod +x /usr/local/bin/docker-compose && \
systemctl start docker && systemctl enable docker && \
cd /opt/orthotrack && \
cp docker-compose.local-build.yml docker-compose.yml && \
cat > .env << 'EOF'
DB_PASSWORD=postgres123
REDIS_PASSWORD=
JWT_SECRET=jwt_secret_for_testing_change_in_production
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=
EOF
docker-compose up -d --build
```

## 🔍 Verificação Final

```bash
# Ver status dos containers
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f

# Testar endpoints
curl http://localhost:8080/health
curl http://localhost:3000

# Ver uso de recursos
docker stats
```

## 🌐 Acesso Externo

Após o deploy:
- **Frontend**: http://72.60.50.248:3000
- **Backend**: http://72.60.50.248:8080
- **API Health**: http://72.60.50.248:8080/health

## 🚨 Troubleshooting

### Se der erro de permissão:
```bash
usermod -aG docker $USER
newgrp docker
```

### Se der erro de porta ocupada:
```bash
netstat -tulpn | grep :8080
netstat -tulpn | grep :3000
# Matar processos se necessário
```

### Se der erro de memória:
```bash
free -h
docker system prune -f
```

## 📋 Status Esperado

Após executar, você deve ver:

```
NAME                    COMMAND                  SERVICE             STATUS              PORTS
orthotrack-backend      "/app/main"              backend             running (healthy)   0.0.0.0:8080->8080/tcp
orthotrack-frontend     "docker-entrypoint.s…"   frontend            running (healthy)   0.0.0.0:3000->3000/tcp
orthotrack-mqtt         "/docker-entrypoint.…"   mqtt                running (healthy)   0.0.0.0:1883->1883/tcp, 0.0.0.0:9001->9001/tcp
orthotrack-nginx        "/docker-entrypoint.…"   nginx               running (healthy)   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp
orthotrack-postgres     "docker-entrypoint.s…"   postgres            running (healthy)   5432/tcp
orthotrack-redis        "docker-entrypoint.s…"   redis               running (healthy)   6379/tcp
```

Execute o **comando único** acima para resolver tudo de uma vez! 🚀