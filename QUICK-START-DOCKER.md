# Quick Start - Docker

## Deploy Rápido

```bash
# 1. Configure as variáveis de ambiente
cp .env.example .env
# Edite o .env com suas configurações

# 2. Execute o deploy
./deploy-docker.sh

# Ou manualmente:
docker-compose up -d --build
```

## Acessos

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Login**: `admin` / `admin123`

## Comandos Úteis

```bash
# Ver logs
docker-compose logs -f

# Parar tudo
docker-compose down

# Reiniciar um serviço
docker-compose restart frontend

# Rebuild e restart
docker-compose up -d --build frontend
```

## Estrutura

```
orthotrack-iot-v3/
├── docker-compose.yml      # Orquestração de todos os serviços
├── backend/
│   ├── Dockerfile         # Build do backend Go
│   └── ...
├── frontend/
│   ├── Dockerfile         # Build do frontend SvelteKit
│   └── ...
└── .env                    # Variáveis de ambiente
```

## Troubleshooting

### Frontend não conecta ao backend

Verifique se o backend está rodando:
```bash
docker-compose ps
curl http://localhost:8080/health
```

### Rebuild necessário

Se você alterou código, faça rebuild:
```bash
docker-compose build --no-cache frontend
docker-compose up -d frontend
```







