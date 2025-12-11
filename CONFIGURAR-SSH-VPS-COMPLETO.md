# Configurar SSH do Laptop no VPS Ubuntu

## 🎯 Objetivo
Copiar a chave SSH do seu laptop para o VPS Ubuntu (72.60.50.248) e configurar no GitHub Actions.

## 📋 Passo a Passo Completo

### **Passo 1: Verificar/Gerar Chave SSH no Laptop**

#### No seu laptop (Windows/Linux):
```bash
# Verificar se já tem chave SSH
ls -la ~/.ssh/

# Se não existir, gerar nova chave
ssh-keygen -t rsa -b 4096 -C "deploy@orthotrack"

# Pressione Enter para aceitar o local padrão
# Pressione Enter para senha vazia (ou digite uma senha)
```

### **Passo 2: Copiar Chave Pública para o VPS**

#### Método A: Usando ssh-copy-id (Mais fácil)
```bash
# Copiar chave automaticamente
ssh-copy-id root@72.60.50.248

# Digite a senha do root quando solicitado
```

#### Método B: Manual (se ssh-copy-id não funcionar)
```bash
# 1. Ver sua chave pública
cat ~/.ssh/id_rsa.pub

# 2. Copiar o conteúdo (começa com ssh-rsa...)

# 3. Conectar no VPS
ssh root@72.60.50.248

# 4. No VPS, criar/editar authorized_keys
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys

# 5. Colar sua chave pública no arquivo
# 6. Salvar e sair (Ctrl+X, Y, Enter)

# 7. Definir permissões corretas
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### **Passo 3: Testar Conexão SSH**
```bash
# Testar se consegue conectar sem senha
ssh root@72.60.50.248

# Se funcionar sem pedir senha, está correto!
```

### **Passo 4: Obter Chave Privada para GitHub**
```bash
# Mostrar chave privada
cat ~/.ssh/id_rsa

# Copiar TODO o conteúdo (incluindo -----BEGIN e -----END)
```

### **Passo 5: Configurar Secret no GitHub**

1. **Vá para**: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions

2. **Clique**: "New repository secret"

3. **Adicione**:
   - **Name**: `VPS_SSH_PRIVATE_KEY`
   - **Secret**: Cole toda a chave privada (incluindo as linhas BEGIN/END)

### **Passo 6: Gerar Outros Secrets Necessários**

Execute no seu laptop:
```bash
# Gerar senhas seguras
echo "DB_PASSWORD=$(openssl rand -base64 32)"
echo "REDIS_PASSWORD=$(openssl rand -base64 32)"
echo "MQTT_PASSWORD=$(openssl rand -base64 32)"
echo "JWT_SECRET=$(openssl rand -base64 64)"
```

Adicione cada um como secret no GitHub.

## 🔧 Troubleshooting

### **Se ssh-copy-id não funcionar**:
```bash
# Alternativa no Windows
type %USERPROFILE%\.ssh\id_rsa.pub | ssh root@72.60.50.248 "cat >> ~/.ssh/authorized_keys"
```

### **Se não conseguir conectar**:
```bash
# Testar com verbose
ssh -v root@72.60.50.248

# Verificar se VPS está acessível
ping 72.60.50.248
```

### **Permissões SSH no VPS**:
```bash
# No VPS, verificar/corrigir permissões
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chown root:root ~/.ssh/authorized_keys
```

## 📝 Lista de Secrets Necessários

Após configurar SSH, adicione estes secrets no GitHub:

```
✅ VPS_SSH_PRIVATE_KEY = [sua_chave_privada_completa]
✅ DB_PASSWORD = [senha_gerada]
✅ REDIS_PASSWORD = [senha_gerada]
✅ MQTT_PASSWORD = [senha_gerada]
✅ JWT_SECRET = [chave_gerada]
```

## 🚀 Testar Deploy

Após configurar todos os secrets:
```bash
git commit --allow-empty -m "Trigger deploy after SSH configuration"
git push origin main
```

## 💡 Dicas Importantes

### **Formato da Chave Privada**:
Deve incluir as linhas completas:
```
-----BEGIN OPENSSH PRIVATE KEY-----
[conteúdo da chave]
-----END OPENSSH PRIVATE KEY-----
```

### **Segurança**:
- Use chaves SSH ao invés de senhas
- Mantenha a chave privada segura
- Não compartilhe a chave privada

### **VPS Ubuntu**:
- Certifique-se que SSH está habilitado
- Verifique firewall (porta 22)
- User root deve ter acesso SSH

---

**🎯 Após seguir estes passos, o deploy deve funcionar!**