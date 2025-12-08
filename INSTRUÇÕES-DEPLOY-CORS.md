# Instruções para Deploy com Configurações CORS

## Para aplicar as correções CORS no servidor:

### 1. Backend
```bash
# No servidor, navegue até a pasta do backend
cd /path/to/orthotrack-iot-v3/backend

# Copie o arquivo de produção para .env
cp .env.production .env

# Edite e ajuste as variáveis conforme seu ambiente
nano .env
# Especialmente: ALLOWED_ORIGINS com o IP do seu servidor

# Reinicie os containers
docker-compose down
docker-compose up -d
```

### 2. Frontend
```bash
# No servidor, navegue até a pasta do frontend
cd /path/to/orthotrack-iot-v3/frontend

# Copie o arquivo de produção para .env
cp .env.production .env

# Edite e ajuste as URLs conforme seu servidor
nano .env
# Ajuste VITE_API_BASE_URL e VITE_WS_URL com o IP do seu servidor

# Rebuild o frontend
npm run build

# Se usando Docker, rebuild o container
docker-compose build frontend
docker-compose up -d frontend
```

### 3. Verificação
```bash
# Teste CORS
curl -H "Origin: http://SEU_IP:3000" -X OPTIONS -v "http://localhost:8080/api/v1/dashboard/overview"

# Deve retornar headers Access-Control-Allow-Origin
```

## Arquivos alterados nesta correção:

1. **backend/docker-compose.yml**
   - Adicionada linha: `ALLOWED_ORIGINS: ${ALLOWED_ORIGINS:-http://localhost:3000,http://localhost:5173}`

2. **backend/.env.production** (novo arquivo)
   - Configurações de produção incluindo ALLOWED_ORIGINS

3. **frontend/.env.production** (novo arquivo) 
   - URLs configuradas para acessar backend em IP específico

4. **CORREÇÃO-CORS-2025-12-08.md**
   - Documentação completa da correção aplicada

## Variáveis importantes:

- `ALLOWED_ORIGINS`: Lista de origens permitidas para CORS (separadas por vírgula)
- `VITE_API_BASE_URL`: URL base da API que o frontend irá acessar
- `VITE_WS_URL`: URL do WebSocket para conexões em tempo real