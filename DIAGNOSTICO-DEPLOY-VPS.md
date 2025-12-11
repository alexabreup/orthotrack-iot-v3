# Diagnóstico Deploy VPS - Falha em 6s

## 🎯 Status Atual
✅ **Testes passaram** (core functionality)  
✅ **Build chegou ao deploy** (Docker funcionou ou foi pulado)  
❌ **Deploy VPS falhou** em 6 segundos  

## 🔍 Possíveis Causas

### 1. **SSH Key não configurada** (Mais provável)
**Secret necessário**: `VPS_SSH_PRIVATE_KEY`

### 2. **Outros secrets faltando**
Secrets que podem estar faltando:
- `DB_PASSWORD`
- `REDIS_PASSWORD` 
- `MQTT_PASSWORD`
- `JWT_SECRET`
- `SLACK_WEBHOOK_URL` (opcional)

### 3. **VPS não acessível**
- IP `72.60.50.248` não responde
- Porta SSH (22) bloqueada
- Firewall bloqueando conexão

### 4. **Permissões SSH**
- User `root` não tem acesso
- Chave SSH incorreta
- Formato da chave inválido

## 📋 Secrets Necessários para Deploy

### **Obrigatórios**:
```
VPS_SSH_PRIVATE_KEY = [sua_chave_ssh_privada]
DB_PASSWORD = [senha_do_postgres]
REDIS_PASSWORD = [senha_do_redis]
MQTT_PASSWORD = [senha_do_mqtt]
JWT_SECRET = [chave_jwt_secreta]
```

### **Opcionais**:
```
SLACK_WEBHOOK_URL = [webhook_do_slack]
```

## 🔧 Como Verificar e Corrigir

### **Passo 1: Verificar Secrets**
Vá para: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions

Verifique se existem todos os secrets listados acima.

### **Passo 2: Testar SSH Local**
```bash
# Teste se consegue acessar o VPS
ssh root@72.60.50.248

# Se funcionar, o problema são os secrets
# Se não funcionar, o problema é o VPS/rede
```

### **Passo 3: Gerar SSH Key (se necessário)**
```bash
# Gerar nova chave SSH
ssh-keygen -t rsa -b 4096 -C "deploy@orthotrack"

# Copiar chave pública para o VPS
ssh-copy-id root@72.60.50.248

# Copiar chave privada para GitHub secrets
cat ~/.ssh/id_rsa
```

### **Passo 4: Gerar Passwords (se necessário)**
```bash
# Gerar senhas seguras
openssl rand -base64 32  # Para DB_PASSWORD
openssl rand -base64 32  # Para REDIS_PASSWORD  
openssl rand -base64 32  # Para MQTT_PASSWORD
openssl rand -base64 64  # Para JWT_SECRET
```

## 🚀 Solução Rápida

### **Se você tem acesso SSH ao VPS**:
1. **Configure os secrets** no GitHub
2. **Rode o workflow** novamente

### **Se não tem acesso SSH**:
1. **Verifique se VPS está ligado**
2. **Teste conexão**: `ping 72.60.50.248`
3. **Verifique firewall** do VPS
4. **Configure SSH** no VPS

## 📝 Script para Gerar Todos os Secrets

Vou criar um script para gerar todos os secrets necessários:

```bash
#!/bin/bash
echo "🔐 Gerando secrets para deploy..."
echo ""
echo "DB_PASSWORD=$(openssl rand -base64 32)"
echo "REDIS_PASSWORD=$(openssl rand -base64 32)"
echo "MQTT_PASSWORD=$(openssl rand -base64 32)"
echo "JWT_SECRET=$(openssl rand -base64 64)"
echo ""
echo "📋 Copie estes valores para os GitHub Secrets"
```

## 🎯 Próximos Passos

1. **Identifique** qual secret está faltando
2. **Configure** todos os secrets necessários
3. **Teste SSH** local para o VPS
4. **Rode workflow** novamente

## 💡 Dica

O fato de ter falhado em apenas 6 segundos indica que provavelmente é um problema de **autenticação SSH** ou **secrets faltando**, não um problema de deploy em si.

---

**🔍 Preciso ver os logs detalhados do deploy para identificar o problema exato!**