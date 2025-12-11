# 🔑 GITHUB SECRETS - PRONTOS PARA COLAR

## ✅ **VALORES GERADOS AUTOMATICAMENTE**

Copie e cole exatamente como está abaixo:

---

### **1. DB_PASSWORD**
```
Nome: DB_PASSWORD
Valor: Kx8mP2vN9qR7wE4tY6uI3oP1zL5nM8xC
```

### **2. REDIS_PASSWORD**
```
Nome: REDIS_PASSWORD
Valor: Zq5nM8xC3vB7wE2rT9yU4iO6pL9kJ6mN
```

### **3. MQTT_PASSWORD**
```
Nome: MQTT_PASSWORD
Valor: Lp9kJ6mN2vB8wE5tY3uI7oP4zQ1nM5xC
```

### **4. JWT_SECRET**
```
Nome: JWT_SECRET
Valor: Hx7mP4qR9vB2wE6tY8uI3oP5nM1xC7vB4wE9rT2yU6iO8kJ3mN5xC1vB7wE4tY9uI2oP6
```

### **5. DOCKER_USERNAME**
```
Nome: DOCKER_USERNAME
Valor: alexabreup
```
**⚠️ SUBSTITUA** pelo seu usuário real do Docker Hub

### **6. DOCKER_PASSWORD**
```
Nome: DOCKER_PASSWORD
Valor: [SUA_SENHA_DOCKER_HUB]
```
**⚠️ SUBSTITUA** pela sua senha real do Docker Hub

### **7. VPS_SSH_PRIVATE_KEY**
```
Nome: VPS_SSH_PRIVATE_KEY
Valor: [EXECUTE O COMANDO ABAIXO]
```

---

## 🔐 **COMO OBTER A CHAVE SSH PRIVADA**

Execute **UM** dos comandos abaixo no PowerShell:

### **Opção 1 (Recomendada):**
```powershell
Get-Content C:\Users\alxab\.ssh\hostinger_key -Raw
```

### **Opção 2 (Se der erro de permissão):**
```powershell
# Execute o PowerShell como Administrador e rode:
Get-Content C:\Users\alxab\.ssh\hostinger_key
```

### **Opção 3 (Alternativa):**
```powershell
type C:\Users\alxab\.ssh\hostinger_key
```

### **Opção 4 (Manual):**
```powershell
notepad C:\Users\alxab\.ssh\hostinger_key
```

**A chave deve começar com:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
```

**E terminar com:**
```
-----END OPENSSH PRIVATE KEY-----
```

**⚠️ COPIE TUDO**, incluindo as linhas BEGIN e END!

---

## 📋 **PASSO A PASSO COMPLETO**

### **1. Acessar GitHub Secrets**
1. Abra: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
2. Clique em `New repository secret`

### **2. Adicionar os 7 Secrets**
Para cada secret acima:
1. Clique em `New repository secret`
2. Digite o **Nome** exato (ex: `DB_PASSWORD`)
3. Cole o **Valor** correspondente
4. Clique em `Add secret`
5. Repita para todos os 7 secrets

### **3. Checklist dos Secrets:**
- [ ] DB_PASSWORD
- [ ] REDIS_PASSWORD  
- [ ] MQTT_PASSWORD
- [ ] JWT_SECRET
- [ ] DOCKER_USERNAME
- [ ] DOCKER_PASSWORD
- [ ] VPS_SSH_PRIVATE_KEY

---

## 🚀 **APÓS CONFIGURAR TODOS OS SECRETS**

### **1. Configurar SSH sem senha:**
```bash
ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248
```

### **2. Configurar o servidor VPS:**
```bash
ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248
wget https://raw.githubusercontent.com/alexabreup/orthotrack-iot-v3/main/scripts/setup-vps.sh
chmod +x setup-vps.sh
./setup-vps.sh
```

### **3. Fazer o primeiro deploy:**
```bash
git add .
git commit -m "feat: configuração produção completa"
git push origin main
```

### **4. Acompanhar o deploy:**
- Vá para: https://github.com/alexabreup/orthotrack-iot-v3/actions
- Clique na execução mais recente
- Aguarde a conclusão (5-10 minutos)

---

## ✅ **URLS FINAIS (após deploy concluído)**

- **Frontend:** https://orthotrack.alexptech.com
- **API:** https://api.orthotrack.alexptech.com/health
- **Grafana:** http://72.60.50.248:3001 (admin/admin123)

---

## 🎯 **RESUMO RÁPIDO**

1. **Copie os 6 primeiros secrets** (DB_PASSWORD até DOCKER_PASSWORD)
2. **Execute o comando** para obter VPS_SSH_PRIVATE_KEY
3. **Cole todos no GitHub Secrets**
4. **Configure SSH** e **rode o setup do VPS**
5. **Faça push** para iniciar o deploy automático

🎉 **Seu sistema estará rodando em produção!**

---

*Gerado automaticamente - OrthoTrack IoT v3*