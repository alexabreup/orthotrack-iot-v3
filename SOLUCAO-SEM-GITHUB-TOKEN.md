# 🚀 Solução Sem GitHub Token - Build Local

## ❌ Problema
```
Error response from daemon: Get "https://ghcr.io/v2/": denied: denied
```

**Causa**: Não conseguimos acessar o GitHub Container Registry sem token válido.

## ✅ Solução: Build Local no VPS

### Opção 1: Script Automático (Recomendado)

```bash
# No VPS, execute:
cd /opt/orthotrack
bash build-local-vps.sh
```

### Opção 2: Comandos Manuais

```bash
# 1. Conectar ao VPS
ssh root@72.60.50.248

# 2. Ir para diretório
cd /opt/orthotrack

# 3. Parar containers
docker-compose -f docker-compose.prod.yml down

# 4. Verificar se temos código fonte
ls -la backend frontend

# 5. Se não tiver código, clonar repositório público
if [ ! -d "backend" ]; then
    cd /opt
    git clone https://github.com/alexabreup/orthotrack-iot-v3.git orthotrack-new
    cp orthotrack/docker-compose.prod.yml orthotrack-new/
    cp orthotrack/.env.production orthotrack-new/ 2>/dev/null || true
    mv orthotrack orthotrack-old
    mv orthotrack-new orthotrack
    cd orthotrack
fi

# 6. Criar docker-compose para build local
cat > docker-compose.build.yml << 'EOF'
services:
  postgres:
    image: postgres:15-alpine
    container_name: orthotrack-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: orthotrack_prod
      POSTGRES_USER: orthotrack
      POSTGRES_PASSWORD: orthotrack_secure_2024
      POSTGRES_HOST_AUTH_METHOD: md5
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U orthotrack -d orthotrack_prod"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  redis:
    image: redis:7-alpine
    container_name: orthotrack-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass redis_secure_2024
    volumes:
      - redis_data:/data
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "redis_secure_2024", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

  mqtt:
    image: eclipse-mosquitto:2.0-openssl
    container_name: orthotrack-mqtt
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - ./mosquitto_passwd:/mosquitto/config/passwd:ro
      - mqtt_data:/mosquitto/data
      - mqtt_logs:/mosquitto/log
    networks:
      - orthotrack-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: orthotrack-backend
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - DB_HOST=orthotrack-postgres
      - DB_PORT=5432
      - DB_NAME=orthotrack_prod
      - DB_USER=orthotrack
      - DB_PASSWORD=orthotrack_secure_2024
      - REDIS_HOST=orthotrack-redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=redis_secure_2024
      - REDIS_DB=0
      - MQTT_HOST=orthotrack-mqtt
      - MQTT_PORT=1883
      - MQTT_BROKER_URL=tcp://orthotrack-mqtt:1883
      - MQTT_USERNAME=orthotrack
      - MQTT_PASSWORD=mqtt_secure_2024
      - JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
      - PORT=8080
      - GIN_MODE=release
      - ALLOWED_ORIGINS=https://orthotrack.alexptech.com,https://www.orthotrack.alexptech.com,https://api.orthotrack.alexptech.com,http://localhost:3000
    depends_on:
      - postgres
      - redis
      - mqtt
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - VITE_API_BASE_URL=https://api.orthotrack.alexptech.com
        - VITE_WS_URL=wss://api.orthotrack.alexptech.com/ws
    container_name: orthotrack-frontend
    restart: unless-stopped
    ports:
      - "3000:3000"
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s

volumes:
  postgres_data:
  redis_data:
  mqtt_data:
  mqtt_logs:

networks:
  orthotrack-network:
    driver: bridge
EOF

# 7. Criar mosquitto.conf
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

# 8. Criar senha MQTT
docker run --rm -v $(pwd):/mosquitto/config eclipse-mosquitto:2.0-openssl mosquitto_passwd -c -b /mosquitto/config/mosquitto_passwd orthotrack mqtt_secure_2024

# 9. Buildar e iniciar
docker-compose -f docker-compose.build.yml up -d --build

# 10. Aguardar 3 minutos
sleep 180

# 11. Testar
curl http://localhost:8080/health
curl http://localhost:3000/
```

## 🧪 Teste Final

```bash
# Status dos containers
docker-compose -f docker-compose.build.yml ps

# Todos devem estar "Up (healthy)"

# Testar endpoints
curl http://localhost:8080/health
# Deve retornar: {"status":"healthy"}

curl -I http://localhost:3000/
# Deve retornar: HTTP/1.1 200 OK
```

## 🎯 Acesso Final

- **URL Principal**: https://orthotrack.alexptech.com
- **API**: https://api.orthotrack.alexptech.com
- **Login**: admin@aacd.org.br  
- **Senha**: password
- **Desenvolvimento**: http://72.60.50.248:3000

## 📊 Vantagens do Build Local

✅ **Não precisa de GitHub token**
✅ **Usa código fonte mais recente**
✅ **Build otimizado para o VPS**
✅ **Controle total sobre o processo**

## 🆘 Se Ainda Não Funcionar

```bash
# Ver logs detalhados
docker-compose -f docker-compose.build.yml logs backend
docker-compose -f docker-compose.build.yml logs frontend

# Verificar espaço em disco
df -h

# Limpar cache Docker se necessário
docker system prune -f
```

## 📋 Próximos Passos

1. Execute o script ou comandos manuais
2. Aguarde 3-5 minutos para build completo
3. Teste em http://72.60.50.248:3000
4. Configure nginx se necessário para porta 80