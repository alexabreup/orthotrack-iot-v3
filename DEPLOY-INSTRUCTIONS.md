# Instruções de Deploy para VPS

## Deploy Completo (Frontend + Backend)

Execute o script de deploy:

```bash
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3
./deploy-vps-complete.sh
```

## Deploy Manual (Passo a Passo)

Se preferir fazer manualmente:

### 1. Preparar arquivo .env no servidor

```bash
# No servidor VPS (root@72.60.50.248)
cd /root/orthotrack-iot-v3

# Criar .env com as configurações
cat > .env << EOF
DB_DATABASE=orthotrack
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=orthotrack
DB_USER=postgres
REDIS_PASSWORD=redis123
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt123
JWT_SECRET=$(openssl rand -base64 32)
GIN_MODE=release
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_WS_URL=ws://72.60.50.248:8080/ws
ALLOWED_ORIGINS=http://72.60.50.248:3000,http://72.60.50.248:8080,http://localhost:3000,http://localhost:5173,http://localhost:5174
EOF
```

### 2. Sincronizar arquivos

```bash
# Na sua máquina local
cd /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3

rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude '*.log' \
    --exclude '.env' \
    --exclude '.env.local' \
    --exclude 'build' \
    --exclude 'dist' \
    --exclude '.svelte-kit' \
    --exclude '.vite' \
    ./ root@72.60.50.248:/root/orthotrack-iot-v3/
```

### 3. Executar deploy no servidor

```bash
# SSH no servidor
ssh root@72.60.50.248

# No servidor
cd /root/orthotrack-iot-v3

# Parar containers existentes
docker-compose down

# Construir e iniciar
docker-compose build --no-cache
docker-compose up -d

# Verificar status
docker-compose ps
docker-compose logs -f
```

## Verificar Deploy

### Testar Backend
```bash
curl http://72.60.50.248:8080/api/v1/health
```

### Testar Frontend
```bash
curl http://72.60.50.248:3000
```

### Acessar no navegador
- Frontend: http://72.60.50.248:3000
- Backend API: http://72.60.50.248:8080
- Health Check: http://72.60.50.248:8080/api/v1/health

## Credenciais de Login

- Usuário: `admin`
- Senha: `admin123`

## Troubleshooting

### Ver logs
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose logs -f'
```

### Reiniciar serviços
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose restart'
```

### Rebuild frontend
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose build --no-cache frontend && docker-compose up -d frontend'
```

### Verificar CORS
Se o frontend não conseguir conectar ao backend, verifique se o CORS está configurado:
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && grep ALLOWED_ORIGINS .env'
```

Deve incluir: `http://72.60.50.248:3000`







