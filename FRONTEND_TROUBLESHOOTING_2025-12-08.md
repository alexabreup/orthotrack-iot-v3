# Troubleshooting Frontend - 08/12/2025

**Data:** 08 de Dezembro de 2025  
**Horário:** 22:30 - 23:00 (GMT-3)  
**Responsável:** Sistema de Diagnóstico Automático  

## Problema Reportado

Frontend inacessível via `http://72.60.50.248:3000/` com erro de timeout de conexão.

## Cronologia da Investigação

### 22:30 - Verificação Inicial
- **Status:** Frontend completamente offline
- **Erro:** `connect ETIMEDOUT 72.60.50.248:3000`
- **Causa Identificada:** Serviço frontend não estava rodando

### 22:32 - Análise da Infraestrutura
- Verificação de containers Docker ativos
- **Resultado:** Container `orthotrack-frontend` não encontrado
- **Containers Ativos:**
  - `orthotrack-backend` (porta 8080) - UP
  - `orthotrack-postgres` (porta 5432) - UP
  - `orthotrack-redis` (porta 6379) - UP
  - `orthotrack-mqtt` (porta 1883/9001) - UP

### 22:35 - Análise do Docker Compose
- Verificado `docker-compose.yml`
- **Configuração Frontend:**
  - Porta: 3000
  - Build context: `./frontend`
  - Dockerfile: `Dockerfile`
  - Network: `orthotrack-network`
  - Dependência: backend

### 22:38 - Tentativa de Build
- Executado `docker-compose build frontend`
- **Status:** Build iniciado com sucesso
- **Tempo:** ~2 minutos (timeout do comando)
- **Resultado:** Build aparentemente concluído

### 22:40 - Primeira Tentativa de Start
- Executado container com variáveis VITE_
- **Resultado:** Container iniciado mas saiu com erro (Exit Code 1)

### 22:42 - Diagnóstico do Erro
- Analisados logs do container
- **Erro Identificado:**
```
Error: You should change envPrefix (VITE_) to avoid conflicts with existing environment variables — unexpectedly saw VITE_API_BASE_URL
```

### 22:44 - Análise do Dockerfile
- Verificado `frontend/Dockerfile`
- **Problema:** Variáveis VITE_ definidas em build-time, conflito em runtime
- **Configuração Atual:**
  - ARG VITE_API_BASE_URL=http://72.60.50.248:8080
  - ARG VITE_WS_URL=ws://72.60.50.248:8080/ws

### 22:46 - Correção Aplicada
- Removido container problemático
- Criado novo container sem variáveis VITE_ em runtime
- **Comando:**
```bash
docker run -d --name orthotrack-frontend \
  --network orthotrack-iot-v3_orthotrack-network \
  -p 3000:3000 \
  -e NODE_ENV=production \
  -e PORT=3000 \
  -e HOST=0.0.0.0 \
  orthotrack-iot-v3_frontend
```

### 22:48 - Verificação Local
- **Status:** Container rodando com sucesso
- **Teste Local:** `curl -I http://localhost:3000/`
- **Resultado:** HTTP/1.1 200 OK
- **Confirmação:** Frontend funcionando localmente

### 22:50 - Teste de Acesso Externo
- **Teste:** `http://72.60.50.248:3000/`
- **Resultado:** Ainda com timeout
- **Verificação de Porta:** `netstat -tlnp | grep :3000`
- **Status:** Porta 3000 ouvindo em 0.0.0.0:3000

### 22:52 - Diagnóstico de Rede
- **Problema Identificado:** Firewall/Network blocking
- **Tentativa de Verificação:** Comandos de firewall requerem sudo
- **Status:** Sem acesso root para diagnóstico completo

## Status Final

### ✅ Problemas Resolvidos
1. **Container Frontend:** Agora rodando corretamente
2. **Erro de Variáveis VITE_:** Corrigido
3. **Serviço Local:** Funcionando na porta 3000

### ⚠️ Problemas Pendentes
1. **Acesso Externo:** Timeout em `72.60.50.248:3000`
2. **Firewall:** Possível bloqueio da porta 3000
3. **Configuração VPS:** Requer acesso administrativo

## Configuração Atual

### Container Frontend
- **Nome:** orthotrack-frontend
- **Imagem:** orthotrack-iot-v3_frontend
- **Porta:** 3000:3000
- **Network:** orthotrack-iot-v3_orthotrack-network
- **Status:** Running

### Variáveis de Ambiente
```bash
NODE_ENV=production
PORT=3000
HOST=0.0.0.0
```

### URLs Configuradas (Build-time)
- **API Base:** http://72.60.50.248:8080
- **WebSocket:** ws://72.60.50.248:8080/ws

## Próximos Passos Recomendados

1. **Verificar Firewall VPS:**
   - Liberar porta 3000 no firewall do servidor
   - Verificar regras iptables
   - Consultar painel de controle do provedor VPS

2. **Teste de Conectividade:**
   - Verificar se outras portas estão acessíveis externamente
   - Testar conectividade de outras máquinas na mesma rede

3. **Configuração Docker:**
   - Verificar se o Docker está expondo corretamente
   - Considerar usar docker-compose para gerenciar todos os serviços

4. **Monitoramento:**
   - Implementar healthcheck para o frontend
   - Adicionar logs de acesso

## Logs Relevantes

### Container Status
```bash
CONTAINER ID   IMAGE                       COMMAND                  STATUS
24b5b99cec35   orthotrack-iot-v3_frontend  "docker-entrypoint.s…"   Up (5 seconds)
```

### Network Listening
```bash
tcp        0      0 0.0.0.0:3000            0.0.0.0:*               LISTEN
tcp6       0      0 :::3000                 :::*                    LISTEN
```

### HTTP Response (Local)
```bash
HTTP/1.1 200 OK
content-length: 3119
content-type: text/html
x-sveltekit-page: true
```

---

**Conclusão:** O frontend foi restaurado com sucesso localmente. O problema de acesso externo requer configuração de firewall/rede no VPS que está fora do escopo desta sessão de troubleshooting.