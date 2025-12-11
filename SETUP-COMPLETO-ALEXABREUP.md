# 🚀 Setup Completo - OrthoTrack IoT v3
## Configuração Específica para alexabreup

**Repositório:** https://github.com/alexabreup/orthotrack-iot-v3  
**Servidor:** srv1167332.hstgr.cloud (72.60.50.248)  
**SSH Key:** C:\Users\alxab\.ssh\hostinger_key.pub  

---

## 📋 Passo 1: Configurar SSH sem Senha

### 1.1 Copiar Chave SSH para o Servidor
```powershell
# No PowerShell do Windows
ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248
```

### 1.2 Testar Conexão SSH
```powershell
# Testar conexão sem senha
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248
```

Se funcionar, você conseguirá acessar sem digitar a senha!

---

## 🔑 Passo 2: Configurar GitHub Secrets

### 2.1 Acessar GitHub Secrets
1. Vá para: https://github.com/alexabreup/orthotrack-iot-v3
2. Clique em `Settings` > `Secrets and variables` > `Actions`
3. Clique em `New repository secret`

### 2.2 Adicionar os Secrets Obrigatórios

#### **DB_PASSWORD**
```
Nome: DB_PASSWORD
Valor: (gerar senha segura - veja comando abaixo)
```

#### **REDIS_PASSWORD**
```
Nome: REDIS_PASSWORD
Valor: (gerar senha segura - veja comando abaixo)
```

#### **MQTT_PASSWORD**
```
Nome: MQTT_PASSWORD
Valor: (gerar senha segura - veja comando abaixo)
```

#### **JWT_SECRET**
```
Nome: JWT_SECRET
Valor: (gerar chave JWT - veja comando abaixo)
```

#### **DOCKER_USERNAME**
```
Nome: DOCKER_USERNAME
Valor: seu_usuario_docker_hub
```

#### **DOCKER_PASSWORD**
```
Nome: DOCKER_PASSWORD
Valor: sua_senha_docker_hub
```

#### **VPS_SSH_PRIVATE_KEY**
```
Nome: VPS_SSH_PRIVATE_KEY
Valor: (conteúdo da chave privada - veja comando abaixo)
```

### 2.3 Gerar Senhas Seguras

#### No PowerShell (Windows):
```powershell
# Gerar senhas aleatórias
[System.Web.Security.Membership]::GeneratePassword(32, 8)
```

#### Ou use este site: https://passwordsgenerator.net/
- Tamanho: 32 caracteres
- Incluir: letras, números, símbolos

### 2.4 Obter Chave SSH Privada
```powershell
# No PowerShell
Get-Content C:\Users\alxab\.ssh\hostinger_key
```

**Copie TODO o conteúdo** (incluindo `-----BEGIN` e `-----END`) e cole no secret `VPS_SSH_PRIVATE_KEY`.

---

## 🐳 Passo 3: Configurar Docker Hub

### 3.1 Criar Conta no Docker Hub
1. Acesse: https://hub.docker.com/
2. Crie uma conta se não tiver
3. Anote seu **username** e **password**

### 3.2 Criar Repositórios
1. No Docker Hub, clique em `Create Repository`
2. Crie dois repositórios:
   - `orthotrack-backend` (público)
   - `orthotrack-frontend` (público)

---

## 🖥️ Passo 4: Configurar o Servidor VPS

### 4.1 Executar Script de Setup
```bash
# Conectar no servidor
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248

# Fazer upload do script
wget https://raw.githubusercontent.com/alexabreup/orthotrack-iot-v3/main/scripts/setup-vps.sh
chmod +x setup-vps.sh

# Executar setup
./setup-vps.sh
```

**Tempo estimado:** 10-15 minutos

### 4.2 Verificar Instalação
```bash
# Verificar Docker
docker --version
docker-compose --version

# Verificar firewall
ufw status

# Verificar estrutura
ls -la /opt/orthotrack/
```

---

## 🚀 Passo 5: Primeiro Deploy

### 5.1 Fazer Push para GitHub
```bash
# No seu computador local
git add .
git commit -m "feat: configuração inicial produção"
git push origin main
```

### 5.2 Acompanhar Deploy
1. Vá para: https://github.com/alexabreup/orthotrack-iot-v3/actions
2. Clique na execução mais recente
3. Acompanhe o progresso

**Tempo estimado:** 5-10 minutos

---

## ✅ Passo 6: Verificar Sistema

### 6.1 URLs para Testar
- **Frontend**: https://orthotrack.alexptech.com
- **API**: https://api.orthotrack.alexptech.com/health
- **Grafana**: http://72.60.50.248:3001 (admin/admin123)

### 6.2 Comandos de Verificação
```bash
# No servidor VPS
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248

# Ver containers rodando
docker ps

# Ver logs
docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs -f

# Health check
/opt/orthotrack/scripts/health-check.sh
```

---

## 🔧 Comandos Úteis

### No Servidor VPS:
```bash
# Ver status dos serviços
cd /opt/orthotrack
docker-compose -f docker-compose.prod.yml ps

# Reiniciar serviços
docker-compose -f docker-compose.prod.yml restart

# Ver logs específicos
docker logs orthotrack-backend
docker logs orthotrack-frontend

# Backup manual
./scripts/backup.sh

# Deploy manual
./scripts/deploy.sh -b
```

### No seu Computador:
```bash
# Testar API
curl https://api.orthotrack.alexptech.com/health

# Fazer deploy de versão específica
git tag v1.0.0
git push origin v1.0.0
```

---

## 🚨 Troubleshooting

### Deploy Falha?
1. Verificar logs no GitHub Actions
2. Verificar se todos os secrets estão configurados
3. Testar conexão SSH: `ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248`

### Serviços Não Iniciam?
```bash
# No VPS
cd /opt/orthotrack
docker-compose -f docker-compose.prod.yml logs
docker system df  # Verificar espaço
docker system prune -f  # Limpar
```

### Problemas de Conexão?
```bash
# Verificar firewall
ufw status
ufw allow 3000/tcp
ufw allow 8080/tcp
```

---

## 📊 Monitoramento

### Dashboards Disponíveis:
- **Grafana**: http://72.60.50.248:3001
  - Usuário: admin
  - Senha: admin123

- **Prometheus**: http://72.60.50.248:9090

### Logs Centralizados:
```bash
# Ver todos os logs
docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs -f

# Logs específicos
docker logs -f orthotrack-backend
docker logs -f orthotrack-frontend
```

---

## 🎯 Próximos Passos

### Após Sistema Funcionando:
1. **Configurar SSL** (opcional):
   ```bash
   certbot certonly --standalone -d srv1167332.hstgr.cloud
   ```

2. **Configurar Domínio Personalizado** (opcional)

3. **Configurar ESP32**:
   - Editar `esp32-firmware/platformio.ini`
   - Definir WiFi e endpoint da API

4. **Testar Integração Completa**

---

## 📞 Suporte

- **GitHub Issues**: https://github.com/alexabreup/orthotrack-iot-v3/issues
- **Documentação**: README.md
- **Deploy Detalhado**: GITHUB-DEPLOY-SETUP.md

---

## ✅ Checklist Final

- [ ] SSH configurado sem senha
- [ ] GitHub Secrets configurados (7 secrets)
- [ ] Docker Hub configurado
- [ ] VPS configurado com setup-vps.sh
- [ ] Primeiro deploy realizado
- [ ] Frontend acessível (https://orthotrack.alexptech.com)
- [ ] API funcionando (https://api.orthotrack.alexptech.com/health)
- [ ] Monitoramento ativo (http://72.60.50.248:3001)

---

🚀 **Seu sistema estará rodando em produção com deploy automático!**

*Última atualização: 10/12/2024*