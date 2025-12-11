# ⚡ Instruções Rápidas - Deploy OrthoTrack IoT v3

## 🎯 Para alexabreup - Repositório: https://github.com/alexabreup/orthotrack-iot-v3

---

## 1️⃣ **EXECUTAR SCRIPT POWERSHELL (5 min)**

```powershell
# No PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup-windows.ps1
```

**O script vai:**
- ✅ Gerar todas as senhas seguras
- ✅ Ler sua chave SSH
- ✅ Salvar tudo em `github-secrets.txt`
- ✅ Testar conexão SSH

---

## 2️⃣ **CONFIGURAR GITHUB SECRETS (5 min)**

1. **Abrir:** https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions

2. **Adicionar 7 secrets** (valores no arquivo `github-secrets.txt`):
   - `DB_PASSWORD`
   - `REDIS_PASSWORD` 
   - `MQTT_PASSWORD`
   - `JWT_SECRET`
   - `DOCKER_USERNAME` (seu usuário Docker Hub)
   - `DOCKER_PASSWORD` (sua senha Docker Hub)
   - `VPS_SSH_PRIVATE_KEY` (chave SSH completa)

---

## 3️⃣ **CONFIGURAR SSH SEM SENHA (2 min)**

```bash
# Copiar chave pública para servidor
ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248

# Testar (não deve pedir senha)
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248
```

---

## 4️⃣ **CONFIGURAR SERVIDOR VPS (10 min)**

```bash
# No servidor VPS
wget https://raw.githubusercontent.com/alexabreup/orthotrack-iot-v3/main/scripts/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

---

## 5️⃣ **FAZER PRIMEIRO DEPLOY (5 min)**

```bash
# No seu computador
git add .
git commit -m "feat: configuração produção completa"
git push origin main
```

**Acompanhar em:** https://github.com/alexabreup/orthotrack-iot-v3/actions

---

## ✅ **VERIFICAR SISTEMA FUNCIONANDO**

### URLs para Testar:
- **Frontend:** https://orthotrack.alexptech.com
- **API:** https://api.orthotrack.alexptech.com/health
- **Grafana:** http://72.60.50.248:3001 (admin/admin123)

### Comandos de Verificação:
```bash
# No servidor
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248

# Ver containers
docker ps

# Ver logs
docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs -f
```

---

## 🚨 **SE ALGO DER ERRADO**

### Deploy Falha?
1. Verificar logs: https://github.com/alexabreup/orthotrack-iot-v3/actions
2. Verificar se todos os 7 secrets estão configurados
3. Testar SSH: `ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248`

### Containers Não Iniciam?
```bash
# No servidor
cd /opt/orthotrack
docker-compose -f docker-compose.prod.yml logs
docker system prune -f
```

---

## 📊 **TEMPO TOTAL: ~30 MINUTOS**

1. Script PowerShell: 5 min
2. GitHub Secrets: 5 min  
3. SSH Setup: 2 min
4. VPS Setup: 10 min
5. Deploy: 5 min
6. Verificação: 3 min

---

## 🎉 **RESULTADO FINAL**

✅ **Sistema completo em produção com:**
- Deploy automático via GitHub Actions
- Monitoramento com Grafana/Prometheus
- Backup automático
- SSL/HTTPS (opcional)
- Health checks
- Logs centralizados

**Acesse:** https://orthotrack.alexptech.com

---

*Última atualização: 10/12/2024*