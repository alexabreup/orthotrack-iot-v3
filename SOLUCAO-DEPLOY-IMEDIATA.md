# 🚀 Solução Imediata para Deploy VPS

## 🔥 Problema Atual
- Imagens Docker não existem no Docker Hub
- Variáveis de ambiente não definidas
- Deploy falhando por falta de imagens

## ✅ Solução Rápida

### Opção 1: Deploy com Build Local (RECOMENDADO)

Execute no VPS diretamente:

```bash
# 1. Parar serviços atuais
cd /opt/orthotrack
docker-compose down

# 2. Usar o docker-compose com build local
cp docker-compose.local-build.yml docker-compose.yml

# 3. Criar .env com valores padrão
cat > .env << 'EOF'
DB_PASSWORD=postgres123
REDIS_PASSWORD=
JWT_SECRET=jwt_secret_for_testing_change_in_production
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=
EOF

# 4. Build e deploy
docker-compose up -d --build

# 5. Verificar status
docker-compose ps
docker-compose logs -f
```

### Opção 2: Usar Script Automatizado

Execute no seu Windows:

```powershell
.\deploy-vps-rapido.ps1
```

## 🔧 O que a Solução Faz

1. **Build Local**: Constrói as imagens diretamente no VPS
2. **Valores Padrão**: Define senhas temporárias para funcionar
3. **Portas Diretas**: Expõe backend:8080 e frontend:3000
4. **CORS Liberado**: Permite acesso de qualquer origem

## 🌐 Endpoints Após Deploy

- **Frontend**: http://72.60.50.248:3000
- **Backend**: http://72.60.50.248:8080
- **API Health**: http://72.60.50.248:8080/health
- **MQTT**: tcp://72.60.50.248:1883

## 📋 Verificação Rápida

```bash
# No VPS, verificar se tudo está rodando
cd /opt/orthotrack
docker-compose ps

# Ver logs em tempo real
docker-compose logs -f backend
docker-compose logs -f frontend

# Testar endpoints
curl http://localhost:8080/health
curl http://localhost:3000
```

## 🔒 Próximos Passos (Após Funcionar)

1. **Configurar Secrets Reais**:
   - DB_PASSWORD com senha forte
   - JWT_SECRET com chave aleatória
   - REDIS_PASSWORD se necessário

2. **Configurar Nginx**:
   - SSL/TLS com Let's Encrypt
   - Proxy reverso para domínio

3. **Build Pipeline**:
   - Configurar Docker Hub
   - Automatizar builds no GitHub Actions

## 🚨 Comandos de Emergência

```bash
# Parar tudo
docker-compose down

# Limpar volumes (CUIDADO: apaga dados)
docker-compose down -v

# Rebuild completo
docker-compose up -d --build --force-recreate

# Ver uso de recursos
docker stats

# Limpar imagens antigas
docker image prune -f
```

## 📞 Status Esperado

Após executar, você deve ver:

```
✅ orthotrack-postgres    healthy
✅ orthotrack-redis       healthy  
✅ orthotrack-mqtt        healthy
✅ orthotrack-backend     healthy
✅ orthotrack-frontend    healthy
✅ orthotrack-nginx       healthy
```

## 🎯 Teste Final

```bash
# Teste completo
curl -f http://72.60.50.248:8080/health && echo "Backend OK"
curl -f http://72.60.50.248:3000 && echo "Frontend OK"
```

Execute a **Opção 1** diretamente no VPS para resolver imediatamente! 🚀