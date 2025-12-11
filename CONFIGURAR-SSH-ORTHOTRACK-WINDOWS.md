# Configurar SSH OrthoTrack - Windows

## 🎯 Sua Situação
- **Chave SSH**: `C:\Users\alxab\.ssh\orthotrack`
- **VPS**: `root@72.60.50.248`
- **Sistema**: Windows

## 📋 Passos Específicos para sua Chave

### **Passo 1: Verificar Arquivos SSH**
```powershell
# Abrir PowerShell e verificar arquivos
dir C:\Users\alxab\.ssh\

# Você deve ter:
# orthotrack (chave privada)
# orthotrack.pub (chave pública)
```

### **Passo 2: Copiar Chave Pública para o VPS**

#### Método A: Usando PowerShell
```powershell
# Ver conteúdo da chave pública
type C:\Users\alxab\.ssh\orthotrack.pub

# Copiar para o VPS (digite a senha do root quando solicitado)
type C:\Users\alxab\.ssh\orthotrack.pub | ssh root@72.60.50.248 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

#### Método B: Manual
```powershell
# 1. Ver chave pública
type C:\Users\alxab\.ssh\orthotrack.pub

# 2. Copiar o conteúdo (começa com ssh-rsa...)

# 3. Conectar no VPS
ssh root@72.60.50.248

# 4. No VPS Ubuntu, adicionar a chave
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# Colar sua chave pública
# Salvar: Ctrl+X, Y, Enter

# 5. Definir permissões
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### **Passo 3: Testar Conexão SSH**
```powershell
# Testar com sua chave específica
ssh -i C:\Users\alxab\.ssh\orthotrack root@72.60.50.248

# Se funcionar sem pedir senha, está correto!
```

### **Passo 4: Obter Chave Privada para GitHub**
```powershell
# Mostrar chave privada completa
type C:\Users\alxab\.ssh\orthotrack

# Copiar TODO o conteúdo (incluindo -----BEGIN e -----END)
```

### **Passo 5: Configurar Secret no GitHub**

1. **Vá para**: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions

2. **Clique**: "New repository secret"

3. **Adicione**:
   - **Name**: `VPS_SSH_PRIVATE_KEY`
   - **Secret**: Cole o conteúdo completo de `C:\Users\alxab\.ssh\orthotrack`

## 🔧 Scripts PowerShell para Facilitar

### **Script 1: Copiar Chave para VPS**
```powershell
# copiar-chave-vps.ps1
Write-Host "🔑 Copiando chave SSH para VPS..." -ForegroundColor Cyan

$chavePublica = Get-Content "C:\Users\alxab\.ssh\orthotrack.pub"
Write-Host "Chave pública:" -ForegroundColor Yellow
Write-Host $chavePublica

Write-Host "`n📤 Copiando para VPS (digite a senha do root)..." -ForegroundColor Green
type C:\Users\alxab\.ssh\orthotrack.pub | ssh root@72.60.50.248 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"

Write-Host "`n🧪 Testando conexão..." -ForegroundColor Magenta
ssh -i C:\Users\alxab\.ssh\orthotrack root@72.60.50.248 "echo 'SSH funcionando!' && exit"
```

### **Script 2: Obter Chave Privada**
```powershell
# obter-chave-privada.ps1
Write-Host "🔐 Chave privada para GitHub Secret:" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Yellow

$chavePrivada = Get-Content "C:\Users\alxab\.ssh\orthotrack" -Raw
Write-Host $chavePrivada

Write-Host "`n📋 Copie todo o conteúdo acima para:" -ForegroundColor Green
Write-Host "GitHub Secret: VPS_SSH_PRIVATE_KEY" -ForegroundColor White
Write-Host "Link: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor Blue
```

### **Script 3: Gerar Outros Secrets**
```powershell
# gerar-secrets.ps1
Write-Host "🔐 Gerando secrets para deploy..." -ForegroundColor Cyan

# Função para gerar senha aleatória
function New-RandomPassword {
    param([int]$Length = 32)
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

Write-Host "`n📋 Secrets para GitHub:" -ForegroundColor Yellow
Write-Host "DB_PASSWORD = $(New-RandomPassword 32)"
Write-Host "REDIS_PASSWORD = $(New-RandomPassword 32)"
Write-Host "MQTT_PASSWORD = $(New-RandomPassword 32)"
Write-Host "JWT_SECRET = $(New-RandomPassword 64)"
```

## 🚀 Execução Rápida

### **1. Copiar chave para VPS**
```powershell
type C:\Users\alxab\.ssh\orthotrack.pub | ssh root@72.60.50.248 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys"
```

### **2. Testar conexão**
```powershell
ssh -i C:\Users\alxab\.ssh\orthotrack root@72.60.50.248
```

### **3. Obter chave privada**
```powershell
type C:\Users\alxab\.ssh\orthotrack
```

### **4. Configurar no GitHub**
- Copiar saída do comando acima
- Adicionar como `VPS_SSH_PRIVATE_KEY` no GitHub

## 💡 Dicas Importantes

### **Formato da Chave**:
A chave deve começar e terminar com:
```
-----BEGIN OPENSSH PRIVATE KEY-----
[conteúdo]
-----END OPENSSH PRIVATE KEY-----
```

### **Teste Local**:
Se conseguir conectar com `ssh -i C:\Users\alxab\.ssh\orthotrack root@72.60.50.248` sem senha, está funcionando!

### **Troubleshooting**:
```powershell
# Se der erro de permissões no Windows
icacls C:\Users\alxab\.ssh\orthotrack /inheritance:r /grant:r "%USERNAME%:F"
```

---

**🎯 Após configurar, o deploy deve funcionar!**