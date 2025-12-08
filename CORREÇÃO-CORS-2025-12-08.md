# Correção de Problemas CORS - OrthoTrack IoT V3

**Data:** 08 de dezembro de 2025  
**Responsável:** Claude Code Assistant  
**Objetivo:** Resolver erros de CORS entre frontend e backend em produção

## Problema Identificado

O frontend em produção (`http://72.60.50.248:3000`) estava falhando ao acessar o backend (`http://72.60.50.248:8080`) com os seguintes erros:

```
Access to fetch at 'http://localhost:8080/api/v1/dashboard/overview' 
from origin 'http://72.60.50.248:3000' has been blocked by CORS policy: 
Response to preflight request doesn't pass access control check: 
No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

## Análise da Causa

1. **Frontend configurado incorretamente**: Estava tentando acessar `localhost:8080` mesmo estando em produção
2. **Backend sem configuração CORS**: Variável `ALLOWED_ORIGINS` não estava sendo passada para o container Docker
3. **Configuração de ambiente inconsistente**: Frontend e backend não estavam alinhados para produção

## Soluções Implementadas

### 1. Configuração do Frontend

**Arquivo:** `frontend/.env`
```env
# Configuração para Produção VPS
# Backend rodando no VPS
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_WS_URL=ws://72.60.50.248:8080/ws

# Para desenvolvimento local, descomente e ajuste:
# VITE_API_BASE_URL=http://localhost:8080
# VITE_WS_URL=ws://localhost:8080/ws
```

**Mudança:** Trocou de `localhost:8080` para `72.60.50.248:8080` para apontar para o servidor VPS.

### 2. Configuração do Backend - Docker Compose

**Arquivo:** `backend/docker-compose.yml`

**Adicionado na seção `environment` do serviço `backend`:**
```yaml
# CORS Configuration
ALLOWED_ORIGINS: ${ALLOWED_ORIGINS:-http://localhost:3000,http://localhost:5173}
```

### 3. Configuração do Backend - Arquivo .env

**Arquivo criado:** `backend/.env`
```env
# Configuração de Produção para VPS
DB_DATABASE=orthotrack
DB_USERNAME=postgres
DB_PASSWORD=postgres
DB_NAME=orthotrack
DB_USER=postgres

REDIS_PASSWORD=redis123

MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt123

# JWT Secret (gerar um novo em produção)
JWT_SECRET=your-super-secret-jwt-key-change-in-production

GIN_MODE=release

# CORS - Origens permitidas para o VPS
ALLOWED_ORIGINS=http://72.60.50.248:3000,http://72.60.50.248:8080,http://localhost:3000,http://localhost:5173,http://localhost:5174

# IoT Configuration
IOT_ALERT_BATTERY_LOW=20
IOT_ALERT_TEMP_HIGH=45.0
IOT_ALERT_TEMP_LOW=5.0
```

### 4. Rebuild do Frontend

Executado `npm run build` para aplicar as novas variáveis de ambiente.

### 5. Restart dos Serviços Backend

Reiniciado containers Docker para carregar as novas configurações CORS.

## Verificação da Correção

### Teste CORS Realizado
```bash
curl -H "Origin: http://72.60.50.248:3000" -X OPTIONS -v "http://localhost:8080/api/v1/dashboard/overview"
```

### Resposta Obtida (Sucesso)
```
< HTTP/1.1 204 No Content
< Access-Control-Allow-Credentials: true
< Access-Control-Allow-Headers: Origin,Content-Length,Content-Type,Authorization,X-Device-Api-Key,Accept,X-Requested-With
< Access-Control-Allow-Methods: GET,POST,PUT,DELETE,OPTIONS
< Access-Control-Allow-Origin: http://72.60.50.248:3000
< Access-Control-Max-Age: 43200
< Vary: Origin
```

✅ **Header `Access-Control-Allow-Origin: http://72.60.50.248:3000` presente e correto**

## Status Final

- ✅ **Backend configurado** com CORS para aceitar requisições de `72.60.50.248:3000`
- ✅ **Frontend reconfigurado** para usar API em `72.60.50.248:8080`
- ✅ **Containers reiniciados** com novas configurações
- ✅ **Teste CORS confirmado** funcionando

## Arquivos Modificados

1. `frontend/.env` - Atualizado URLs da API para produção
2. `backend/docker-compose.yml` - Adicionada variável ALLOWED_ORIGINS
3. `backend/.env` - Criado arquivo com configurações de produção

## Observações

- As configurações de desenvolvimento local foram mantidas comentadas para facilitar alternância
- A configuração CORS inclui múltiplas origens para flexibilidade (localhost para dev, IP do VPS para produção)
- Recomenda-se gerar um JWT_SECRET mais seguro para produção real

## Próximos Passos

1. Testar todas as funcionalidades do frontend em produção
2. Considerar usar HTTPS para maior segurança
3. Gerar JWT_SECRET mais seguro para produção
4. Implementar monitoramento de logs para detectar problemas similares