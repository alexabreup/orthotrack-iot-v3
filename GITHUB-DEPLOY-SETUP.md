# 🚀 Configuração de Deploy Automático via GitHub Actions

## 📋 Visão Geral

Este guia configura um sistema de deploy automático que:
- ✅ Executa testes automaticamente
- ✅ Faz build das imagens Docker
- ✅ Deploy automático no VPS via SSH
- ✅ Monitoramento e rollback automático
- ✅ Notificações de status

---

## 🔧 1. Preparação do VPS

### Executar no VPS (root@72.60.50.248):

```bash
# 1. Fazer upload do script de setup
scp scripts/setup-vps.sh root@72.60.50.248:/tmp/

# 2. Conectar no VPS e executar setup
ssh root@72.60.50.248
chmod +x /tmp/setup-vps.sh
/tmp/setup-vps.sh
```

### Configurar SSL após setup:
```bash
# No VPS, após configurar DNS
certbot certonly --standalone -d orthotrack.alexptech.com -d www.orthotrack.alexptech.com -d api.orthotrack.alexptech.com
```

---

## 🔑 2. Configurar Secrets no GitHub

### Acesse: `Settings > Secrets and variables > Actions`

#### Secrets Obrigatórios:

```bash
# Banco de dados
DB_PASSWORD=<gerar_senha_segura_32_chars>

# Redis
REDIS_PASSWORD=<gerar_senha_segura_32_chars>

# MQTT
MQTT_PASSWORD=<gerar_senha_segura_32_chars>

# JWT
JWT_SECRET=<gerar_chave_jwt_64_chars>

# Docker Hub
DOCKER_USERNAME=<seu_usuario_docker_hub>
DOCKER_PASSWORD=<sua_senha_docker_hub>

# SSH do VPS
VPS_SSH_PRIVATE_KEY=<chave_privada_ssh_completa>
```

#### Secrets Opcionais:
```bash
# Notificações Slack (opcional)
SLACK_WEBHOOK_URL=<webhook_url_slack>
```

### 🔐 Gerar Senhas Seguras:

```bash
# Gerar senhas
openssl rand -base64 32  # Para DB_PASSWORD
openssl rand -base64 32  # Para REDIS_PASSWORD  
openssl rand -base64 32  # Para MQTT_PASSWORD
openssl rand -base64 64  # Para JWT_SECRET
```

### 🔑 Configurar Chave SSH:

```bash
# Usar sua chave SSH existente
# Copiar chave pública para o VPS
ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248

# Testar conexão
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248

# Copiar chave PRIVADA para GitHub Secret VPS_SSH_PRIVATE_KEY
# No Windows PowerShell:
Get-Content C:\Users\alxab\.ssh\hostinger_key
```

---

## 🐳 3. Configurar Docker Hub

### Criar repositórios no Docker Hub:
1. `orthotrack-backend`
2. `orthotrack-frontend`

### Configurar credenciais:
- **DOCKER_USERNAME**: Seu usuário do Docker Hub
- **DOCKER_PASSWORD**: Token de acesso ou senha

---

## 🌐 4. Configurar DNS

### Configurar registros DNS:

```
Tipo    Nome                         Valor           TTL
A       orthotrack.alexptech.com     72.60.50.248    300
A       www.orthotrack.alexptech.com 72.60.50.248    300  
A       api.orthotrack.alexptech.com 72.60.50.248    300
```

**Domínio:** https://orthotrack.alexptech.com

---

## 🚀 5. Estrutura do Deploy Automático

### Workflow Triggers:
- ✅ Push para `main` ou `production`
- ✅ Tags `v*` (releases)
- ✅ Manual via GitHub UI

### Etapas do Deploy:
1. **🧪 Testes**: Frontend (Vitest) + Backend (Go test)
2. **🏗️ Build**: Imagens Docker no Docker Hub
3. **🚀 Deploy**: SSH no VPS + Docker Compose
4. **🏥 Verificação**: Health checks automáticos
5. **📢 Notificação**: Status via Slack/webhook

---

## 📁 6. Estrutura de Arquivos

```
.github/
└── workflows/
    └── deploy-production.yml     # Workflow principal

scripts/
├── setup-vps.sh                 # Setup inicial do VPS
├── backup.sh                    # Backup automático
└── health-check.sh              # Verificação de saúde

docker-compose.prod.yml           # Configuração produção
nginx.conf                       # Configuração Nginx
mosquitto.conf                   # Configuração MQTT
```

---

## 🔄 7. Processo de Deploy

### Deploy Automático:
```bash
# 1. Fazer alterações no código
git add .
git commit -m "feat: nova funcionalidade"
git push origin main

# 2. GitHub Actions executa automaticamente:
# - Testes
# - Build das imagens
# - Deploy no VPS
# - Verificações
```

### Deploy Manual:
1. Acesse `Actions` no GitHub
2. Selecione `Deploy to Production VPS`
3. Clique `Run workflow`
4. Escolha o ambiente e execute

### Rollback:
```bash
# Automático em caso de falha
# Manual via GitHub Actions se necessário
```

---

## 📊 8. Monitoramento

### URLs de Monitoramento:
- **Frontend**: https://orthotrack.alexptech.com
- **API**: https://api.orthotrack.alexptech.com/health
- **Grafana**: http://72.60.50.248:3001
- **Prometheus**: http://72.60.50.248:9090

### Logs:
```bash
# No VPS
docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs -f

# Health check
/opt/orthotrack/scripts/health-check.sh

# Backup manual
/opt/orthotrack/scripts/backup.sh
```

---

## 🛠️ 9. Comandos Úteis

### No VPS:
```bash
# Ver status dos serviços
cd /opt/orthotrack
docker-compose -f docker-compose.prod.yml ps

# Ver logs
docker-compose -f docker-compose.prod.yml logs -f [serviço]

# Reiniciar serviço específico
docker-compose -f docker-compose.prod.yml restart [serviço]

# Atualizar manualmente
git pull origin main
docker-compose -f docker-compose.prod.yml up -d --build

# Backup manual
./scripts/backup.sh

# Health check
./scripts/health-check.sh
```

### Localmente:
```bash
# Testar conexão SSH
ssh -i ~/.ssh/orthotrack_deploy root@72.60.50.248

# Fazer deploy de tag específica
git tag v1.0.0
git push origin v1.0.0

# Verificar status do deploy
curl -I https://orthotrack.alexptech.com/health
curl -I https://api.orthotrack.alexptech.com/health
```

---

## 🚨 10. Troubleshooting

### Deploy falha:
1. Verificar logs no GitHub Actions
2. Verificar conexão SSH
3. Verificar secrets configurados
4. Verificar espaço em disco no VPS

### Serviços não iniciam:
```bash
# No VPS
docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs
docker system df  # Verificar espaço
docker system prune -f  # Limpar
```

### SSL não funciona:
```bash
# No VPS
certbot certificates
certbot renew --dry-run
nginx -t  # Testar configuração
```

### Banco de dados:
```bash
# Backup
docker exec orthotrack-postgres pg_dump -U orthotrack orthotrack_prod > backup.sql

# Restaurar
cat backup.sql | docker exec -i orthotrack-postgres psql -U orthotrack -d orthotrack_prod
```

---

## ✅ 11. Checklist de Deploy

### Antes do primeiro deploy:
- [ ] VPS configurado com `setup-vps.sh`
- [ ] DNS configurado
- [ ] SSL configurado
- [ ] Secrets do GitHub configurados
- [ ] Docker Hub configurado
- [ ] Chave SSH configurada

### Para cada deploy:
- [ ] Testes passando localmente
- [ ] Commit com mensagem descritiva
- [ ] Push para branch main
- [ ] Verificar GitHub Actions
- [ ] Testar URLs após deploy
- [ ] Verificar logs se necessário

---

## 🎯 12. Próximos Passos

1. **Execute o setup do VPS**:
   ```bash
   scp scripts/setup-vps.sh root@72.60.50.248:/tmp/
   ssh root@72.60.50.248 "/tmp/setup-vps.sh"
   ```

2. **Configure os secrets no GitHub**

3. **Configure o DNS**

4. **Configure o SSL**:
   ```bash
   ssh root@72.60.50.248
   certbot certonly --standalone -d orthotrack.alexptech.com -d www.orthotrack.alexptech.com -d api.orthotrack.alexptech.com
   ```

5. **Faça o primeiro deploy**:
   ```bash
   git add .
   git commit -m "feat: setup deploy automático"
   git push origin main
   ```

6. **Verifique se tudo está funcionando**:
   - https://orthotrack.alexptech.com
   - https://api.orthotrack.alexptech.com/health

🚀 **Pronto! Seu sistema estará rodando com deploy automático e monitoramento completo!**