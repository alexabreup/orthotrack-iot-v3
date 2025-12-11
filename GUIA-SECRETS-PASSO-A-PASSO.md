# Guia Passo-a-Passo: Configurar Docker Hub Secrets

## 🎯 Problema
O workflow ainda mostra: `Error: Username and password required`

## 📋 Solução Detalhada

### **Passo 1: Abrir GitHub Secrets**
1. Vá para: https://github.com/alexabreup/orthotrack-iot-v3
2. Clique em **"Settings"** (no menu superior)
3. No menu lateral esquerdo, clique em **"Secrets and variables"**
4. Clique em **"Actions"**

### **Passo 2: Verificar Secrets Existentes**
Na página que abrir, você deve ver uma lista de secrets.
- Se já existem `DOCKER_USERNAME` e `DOCKER_PASSWORD`, **delete-os** e recrie
- Se não existem, prossiga para o Passo 3

### **Passo 3: Adicionar DOCKER_USERNAME**
1. Clique no botão **"New repository secret"** (verde)
2. No campo **"Name"**, digite: `DOCKER_USERNAME`
3. No campo **"Secret"**, digite: `alexabreup`
4. Clique **"Add secret"**

### **Passo 4: Adicionar DOCKER_PASSWORD**
1. Clique no botão **"New repository secret"** novamente
2. No campo **"Name"**, digite: `DOCKER_PASSWORD`
3. No campo **"Secret"**, digite: `#,d^Ta&KPp6!jfk`
4. Clique **"Add secret"**

### **Passo 5: Verificar Configuração**
Após adicionar, você deve ver:
```
✅ DOCKER_USERNAME (created just now)
✅ DOCKER_PASSWORD (created just now)
```

### **Passo 6: Triggerar Workflow**
Execute estes comandos:
```bash
git add .
git commit -m "Add enhanced Docker credentials check and conditional build"
git push origin main
```

## 🔍 Verificação no Workflow

O novo workflow vai mostrar:
```
🔍 Checking Docker Hub credentials...
✅ DOCKER_USERNAME secret is configured
✅ DOCKER_PASSWORD secret is configured
✅ All Docker Hub credentials are configured
```

## ⚠️ Se Ainda Não Funcionar

### **Possíveis Problemas**:

1. **Senha incorreta**: Verifique se copiou exatamente `#,d^Ta&KPp6!jfk`
2. **Username incorreto**: Deve ser exatamente `alexabreup`
3. **Espaços extras**: Não adicione espaços antes/depois dos valores
4. **Cache**: Aguarde alguns minutos e tente novamente

### **Teste Local**:
```bash
docker login -u alexabreup
# Digite a senha: #,d^Ta&KPp6!jfk
```

Se o login local falhar, a senha está incorreta.

## 🚀 Resultado Esperado

Com os secrets corretos, o workflow deve:
1. ✅ **Login Docker Hub** com sucesso
2. ✅ **Build backend image**
3. ✅ **Build frontend image**
4. ✅ **Push para Docker Hub**
5. ✅ **Deploy no VPS**

## 📞 Se Precisar de Ajuda

Se ainda não funcionar:
1. **Screenshot** da página de secrets do GitHub
2. **Log completo** do workflow
3. **Teste** do login local do Docker

---

**🎯 O importante é configurar os secrets EXATAMENTE como mostrado acima!**