# 🔑 GitHub Secrets - Valores Prontos para Colar

## ✅ **SENHAS GERADAS AUTOMATICAMENTE**

Copie e cole os valores abaixo diretamente nos GitHub Secrets:

### **1. DB_PASSWORD**
```
Nome: DB_PASSWORD
Valor: Kx8#mP2$vN9@qR7!wE4&tY6^uI3%oP1*
```

### **2. REDIS_PASSWORD**
```
Nome: REDIS_PASSWORD
Valor: Zq5!nM8@xC3#vB7$wE2&rT9^yU4%iO6*
```

### **3. MQTT_PASSWORD**
```
Nome: MQTT_PASSWORD
Valor: Lp9@kJ6#mN2$vB8!wE5&tY3^uI7%oP4*
```

### **4. JWT_SECRET**
```
Nome: JWT_SECRET
Valor: Hx7!mP4@qR9#vB2$wE6&tY8^uI3%oP5*nM1@xC7#vB4$wE9&rT2^yU6%iO8*kJ3!
```

### **5. DOCKER_USERNAME**
```
Nome: DOCKER_USERNAME
Valor: [SEU_USUARIO_DOCKER_HUB]
```
**⚠️ SUBSTITUA** pelo seu usuário do Docker Hub

### **6. DOCKER_PASSWORD**
```
Nome: DOCKER_PASSWORD
Valor: [SUA_SENHA_DOCKER_HUB]
```
**⚠️ SUBSTITUA** pela sua senha do Docker Hub

### **7. VPS_SSH_PRIVATE_KEY**
```
Nome: VPS_SSH_PRIVATE_KEY
Valor: [EXECUTE O COMANDO ABAIXO]
```

**Para obter a chave SSH privada, execute no PowerShell:**
```powershell
Get-Content C:\Users\alxab\.ssh\hostinger_key
```

**Copie TODO o conteúdo** (incluindo `-----BEGIN OPENSSH PRIVATE KEY-----` e `-----END OPENSSH PRIVATE KEY-----`)

---

## 📋 **PASSO A PASSO PARA CONFIGURAR**

### **1. Acessar GitHub Secrets**
1. Vá para: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
2. Clique em `New repository secret`

### **2. Adicionar cada Secret**
Para cada secret acima:
1. Clique em `New repository secret`
2. Digite o **Nome** exato (ex: `DB_PASSWORD`)
3. Cole o **Valor** correspondente
4. Clique em `Add secret`

### **3. Verificar se todos os 7 secrets foram adicionados:**
- ✅ DB_PASSWORD
- ✅ REDIS_PASSWORD  
- ✅ MQTT_PASSWORD
- ✅ JWT_SECRET
- ✅ DOCKER_USERNAME
- ✅ DOCKER_PASSWORD
- ✅ VPS_SSH_PRIVATE_KEY

---

## 🚀 **APÓS CONFIGURAR OS SECRETS**

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

## ✅ **URLS FINAIS APÓS DEPLOY**

- **Frontend:** https://orthotrack.alexptech.com
- **API:** https://api.orthotrack.alexptech.com/health
- **Grafana:** http://72.60.50.248:3001 (admin/admin123)

---

## 🔧 **COMANDOS PARA OBTER A CHAVE SSH**

Se o comando anterior não funcionar, tente:

```powershell
# Opção 1
type C:\Users\alxab\.ssh\hostinger_key

# Opção 2
notepad C:\Users\alxab\.ssh\hostinger_key

# Opção 3 (como administrador)
Get-Content C:\Users\alxab\.ssh\hostinger_key -Raw
```

**A chave deve começar com:**
```
-----BEGIN OPENSSH PRIVATE KEY-----
```

**E terminar com:**
```
-----END OPENSSH PRIVATE KEY-----
```

---

🎉 **Seu sistema estará rodando em produção após estes passos!**

*Gerado automaticamente em: $(Get-Date)*