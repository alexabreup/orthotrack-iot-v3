# Docker Setup - OrthoTrack IoT Platform v3

Este documento descreve como executar toda a plataforma OrthoTrack usando Docker Compose.

## Estrutura

A plataforma consiste em 5 serviços Docker:

1. **PostgreSQL** - Banco de dados principal
2. **Redis** - Cache e pub/sub
3. **MQTT (Mosquitto)** - Broker MQTT para comunicação com ESP32
4. **Backend** - API Go/Gin
5. **Frontend** - Dashboard SvelteKit

## Pré-requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- Pelo menos 2GB de RAM disponível
- Portas disponíveis: 3000, 5432, 6379, 8080, 1883, 9001

## Configuração Inicial

1. **Copie o arquivo de exemplo de variáveis de ambiente:**

```bash
cp .env.example .env
```

2. **Edite o arquivo `.env` e configure:**

- Senhas do banco de dados
- JWT Secret (use um valor seguro em produção!)
- Credenciais MQTT
- URLs da API (se necessário)

## Executando a Plataforma

### Iniciar todos os serviços

```bash
docker-compose up -d
```

### Ver logs

```bash
# Todos os serviços
docker-compose logs -f

# Apenas backend
docker-compose logs -f backend

# Apenas frontend
docker-compose logs -f frontend
```

### Parar todos os serviços

```bash
docker-compose down
```

### Parar e remover volumes (⚠️ apaga dados!)

```bash
docker-compose down -v
```

## Acessos

Após iniciar os serviços:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **MQTT**: localhost:1883

## Credenciais Padrão

- **Login Frontend**: `admin` / `admin123`
- **PostgreSQL**: `postgres` / `postgres`
- **Redis**: senha definida em `REDIS_PASSWORD`
- **MQTT**: usuário/senha definidos em `.env`

## Build e Rebuild

### Rebuild apenas o frontend

```bash
docker-compose build frontend
docker-compose up -d frontend
```

### Rebuild apenas o backend

```bash
docker-compose build backend
docker-compose up -d backend
```

### Rebuild tudo

```bash
docker-compose build --no-cache
docker-compose up -d
```

## Variáveis de Ambiente do Frontend

O frontend precisa das URLs da API no momento do build. Por padrão, usa URLs internas da rede Docker:

- `VITE_API_BASE_URL=http://backend:8080` (interno)
- `VITE_WS_URL=ws://backend:8080/ws` (interno)

Se você precisar que o frontend acesse o backend via URL externa (por exemplo, se o frontend for servido por um proxy reverso), você pode definir essas variáveis no `.env` antes de fazer o build.

## Troubleshooting

### Frontend não consegue conectar ao backend

1. Verifique se o backend está rodando: `docker-compose ps`
2. Verifique os logs: `docker-compose logs backend`
3. Teste a conexão: `curl http://localhost:8080/health`
4. Verifique se as variáveis `VITE_API_BASE_URL` estão corretas

### Erro de permissão no banco de dados

1. Verifique as credenciais no `.env`
2. Verifique os logs do PostgreSQL: `docker-compose logs postgres`

### Porta já em uso

Se alguma porta estiver em uso, você pode alterar no `docker-compose.yml`:

```yaml
ports:
  - "3001:3000"  # Mude 3000 para 3001
```

## Deploy em Produção

Para deploy em produção:

1. Altere todas as senhas padrão no `.env`
2. Use um JWT_SECRET forte e único
3. Configure um proxy reverso (nginx/traefik) para HTTPS
4. Configure firewall para expor apenas as portas necessárias
5. Configure backups regulares do PostgreSQL
6. Monitore os logs e saúde dos containers

## Estrutura de Rede

Todos os containers estão na mesma rede Docker (`orthotrack-network`), permitindo comunicação interna usando os nomes dos serviços:

- `postgres` - Banco de dados
- `redis` - Cache
- `mqtt` - Broker MQTT
- `backend` - API
- `frontend` - Dashboard

## Health Checks

Todos os serviços têm health checks configurados. Você pode verificar o status com:

```bash
docker-compose ps
```

Os containers devem mostrar "healthy" quando estiverem funcionando corretamente.



