# 🚀 OrthoTrack IoT v3 - Guia de Início Rápido

## 📋 Pré-requisitos

- **VPS Ubuntu Server** (mínimo 4GB RAM, 2 CPU cores)
- **Domínio configurado** apontando para o VPS
- **GitHub Account** com repositório
- **Docker Hub Account**

## ⚡ Setup Rápido (5 minutos)

### 1. 🔧 Configurar VPS

```bash
# Conectar no VPS
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248

# Fazer upload e executar script de setup
wget https://raw.githubusercontent.com/alexabreup/orthotrack-iot-v3/main/scripts/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

### 2. 🌐 Configurar DNS

Configure os seguintes registros DNS:

```
A    orthotrack.alexptech.com      72.60.50.248
A    www.orthotrack.alexptech.com  72.60.50.248  
A    api.orthotrack.alexptech.com  72.60.50.248
```

### 3. 🔒 Configurar SSL

```bash
# No VPS, após DNS propagado
certbot certonly --standalone \
  -d orthotrack.alexptech.com \
  -d www.orthotrack.alexptech.com \
  -d api.orthotrack.alexptech.com
```

### 4. 🔑 Configurar GitHub Secrets

No GitHub, vá em `Settings > Secrets and variables > Actions` e adicione:

```bash
# Gerar senhas seguras
DB_PASSWORD=$(openssl rand -base64 32)
REDIS_PASSWORD=$(openssl rand -base64 32)
MQTT_PASSWORD=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 64)

# Adicionar no GitHub Secrets:
DB_PASSWORD=<senha_gerada>
REDIS_PASSWORD=<senha_gerada>
MQTT_PASSWORD=<senha_gerada>
JWT_SECRET=<chave_gerada>
DOCKER_USERNAME=<seu_usuario_docker_hub>
DOCKER_PASSWORD=<sua_senha_docker_hub>
VPS_SSH_PRIVATE_KEY=<chave_privada_ssh>
```

### 5. 🔑 Configurar SSH Key

```bash
# Usar chave SSH existente
# Copiar chave pública para VPS
ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248

# Copiar chave PRIVADA para GitHub Secret VPS_SSH_PRIVATE_KEY
# No PowerShell:
Get-Content C:\Users\alxab\.ssh\hostinger_key
```

### 6. 🚀 Primeiro Deploy

```bash
# Fazer push para main - deploy automático!
git add .
git commit -m "feat: setup inicial produção"
git push origin main
```

## ✅ Verificação

Após o deploy, verifique:

- ✅ **Frontend**: https://orthotrack.alexptech.com
- ✅ **API**: https://api.orthotrack.alexptech.com/health
- ✅ **Grafana**: http://72.60.50.248:3001 (admin/admin123)
- ✅ **Prometheus**: http://72.60.50.248:9090

## 🔧 Comandos Úteis

```bash
# No VPS - Ver logs
docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs -f

# Status dos serviços
docker-compose -f /opt/orthotrack/docker-compose.prod.yml ps

# Health check manual
/opt/orthotrack/scripts/health-check.sh

# Backup manual
/opt/orthotrack/scripts/backup.sh

# Deploy manual
/opt/orthotrack/scripts/deploy.sh -b
```

## 🆘 Troubleshooting

### Deploy falha?
1. Verificar logs no GitHub Actions
2. Verificar secrets configurados
3. Testar conexão SSH: `ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248`

### Serviços não iniciam?
```bash
# No VPS
cd /opt/orthotrack
docker-compose -f docker-compose.prod.yml logs
docker system prune -f  # Limpar espaço
```

### SSL não funciona?
```bash
# Verificar certificados
certbot certificates
nginx -t  # Testar configuração
```

## 📞 Suporte

- **GitHub Issues**: Para bugs e features
- **Documentação**: [README.md](README.md)
- **Deploy Completo**: [GITHUB-DEPLOY-SETUP.md](GITHUB-DEPLOY-SETUP.md)

---

🎉 **Pronto! Seu OrthoTrack IoT v3 está rodando em produção!**