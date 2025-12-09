# Correções de Localhost para VPS - 08/12/2025

## ✅ Arquivos Corrigidos

### 1. **backend/cmd/api/main.go**
- **Antes**: CORS com localhost hardcoded como fallback
- **Depois**: CORS usa IP do VPS (72.60.50.248) como fallback padrão
- **Mudança**: Servidor agora escuta em `0.0.0.0:8080` (todas as interfaces) em vez de apenas localhost

```go
// ANTES
corsConfig.AllowOrigins = []string{
    "http://localhost:3000",
    "http://localhost:5173",
    ...
}

// DEPOIS
corsConfig.AllowOrigins = []string{
    "http://72.60.50.248:3000",
    "http://72.60.50.248:8080",
    ...
}
```

### 2. **backend/cmd/api/docs/docs.go**
- **Antes**: Swagger configurado para `localhost:8080`
- **Depois**: Swagger configurado para `72.60.50.248:8080`
- **Impacto**: Documentação Swagger agora aponta para o servidor correto

### 3. **frontend/src/routes/login/+page.svelte**
- **Antes**: Placeholders com valores "admin" e "admin123"
- **Depois**: Placeholders genéricos "Digite seu email" e "Digite sua senha"
- **Segurança**: Remove credenciais visíveis no formulário

### 4. **docker-compose.yml**
- **Status**: ✅ Já configurado corretamente
- **Nota**: Healthchecks usam `localhost` mas isso é correto (dentro do container)

## 📋 Arquivos que NÃO precisam correção

### **frontend/src/lib/services/api.ts**
- **Status**: ✅ OK
- **Razão**: O `localhost:8080` é apenas um fallback para desenvolvimento
- **Produção**: Usa `VITE_API_BASE_URL` da variável de ambiente (já configurado para VPS)

### **backend/internal/config/config.go**
- **Status**: ✅ OK
- **Razão**: Os defaults `localhost` são sobrescritos pelo `docker-compose.yml` que usa nomes de serviços Docker

## 🔧 Configurações Importantes

### Variáveis de Ambiente no VPS

Certifique-se de que o arquivo `.env` no servidor contém:

```bash
# Backend
ALLOWED_ORIGINS=http://72.60.50.248:3000,http://72.60.50.248:8080

# Frontend
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_WS_URL=ws://72.60.50.248:8080/ws
```

### Docker Compose

O `docker-compose.yml` já está configurado corretamente:
- Backend escuta em `0.0.0.0:8080` (todas as interfaces)
- Frontend recebe `VITE_API_BASE_URL` como build arg
- CORS configurado via `ALLOWED_ORIGINS`

## 🚀 Próximos Passos

1. **Rebuild do Backend**:
   ```bash
   docker-compose build backend
   docker-compose up -d backend
   ```

2. **Rebuild do Frontend**:
   ```bash
   docker-compose build frontend
   docker-compose up -d frontend
   ```

3. **Verificar Logs**:
   ```bash
   docker-compose logs backend | grep -i "server starting"
   docker-compose logs frontend
   ```

4. **Testar Conectividade**:
   ```bash
   curl http://72.60.50.248:8080/api/v1/health
   curl http://72.60.50.248:3000
   ```

## ⚠️ Notas Importantes

- O servidor backend agora escuta em **todas as interfaces** (`0.0.0.0`), não apenas localhost
- CORS está configurado para aceitar requisições do IP do VPS
- Swagger documentation aponta para o servidor correto
- Formulário de login não exibe mais credenciais padrão

## 🔍 Verificação Final

Execute para verificar se não há mais referências problemáticas:

```bash
# Buscar localhost em arquivos críticos (excluindo docs e scripts de dev)
grep -r "localhost" --include="*.go" --include="*.ts" --include="*.svelte" \
  backend/cmd backend/internal frontend/src | grep -v "node_modules" | grep -v ".svelte-kit"
```

Todas as referências encontradas devem ser:
- ✅ Fallbacks para desenvolvimento (OK)
- ✅ Comentários ou documentação (OK)
- ✅ Healthchecks dentro de containers (OK)





