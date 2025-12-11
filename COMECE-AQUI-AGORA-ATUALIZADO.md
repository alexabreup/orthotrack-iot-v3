# 🚀 COMECE AQUI AGORA! (ATUALIZADO)

## ✅ SISTEMA PRONTO - ÚLTIMA ETAPA!

**Status:** Backend rodando ✅ | Banco populado ✅ | Frontend: configurar ⏳

---

## ⚡ AÇÃO IMEDIATA (5 minutos)

### **OPÇÃO A: Modo Rápido (RECOMENDADO)**

Execute este comando no terminal:

```bash
cd frontend
npm install
npm run dev
```

**Depois abra:**
```
URL: http://localhost:5173
Login: admin@orthotrack.com / admin123
```

---

### **OPÇÃO B: Usar Script Automático**

Execute o arquivo criado:

```bash
./iniciar-frontend-dev.bat
```

Ou no PowerShell:
```powershell
.\iniciar-frontend-dev.bat
```

---

## 📊 O QUE VOCÊ TEM AGORA

```
✅ Backend rodando em http://localhost:8080
✅ Banco de dados com 5 pacientes e 5 dispositivos
✅ Redis e MQTT rodando
⏳ Frontend: precisa rodar em modo dev
```

---

## 🎯 SEQUÊNCIA COMPLETA

### **1. Backend está OK** ✅
```bash
curl http://localhost:8080/api/v1/health
```

**Resposta esperada:**
```json
{"status":"healthy","timestamp":"...","version":"3.0.0"}
```

### **2. Iniciar Frontend** ⏳
```bash
cd frontend
npm install  # Só precisa fazer uma vez
npm run dev
```

**Aguarde ver:**
```
VITE v... ready in ... ms

➜  Local:   http://localhost:5173/
➜  Network: use --host to expose
```

### **3. Acessar Sistema** 🌐
```
Abrir: http://localhost:5173
Login: admin@orthotrack.com / admin123
```

### **4. Verificar Dashboard** ✅
- Ver 5 pacientes
- Ver 5 dispositivos
- Ver estatísticas

---

## 🚨 SE DER ERRO

### **Erro: "npm: command not found"**
```bash
# Você precisa instalar Node.js
# Download: https://nodejs.org/
# Escolha a versão LTS (Long Term Support)
```

### **Erro: "Cannot find module"**
```bash
cd frontend
rm -rf node_modules
npm install
npm run dev
```

### **Erro: "Port 5173 already in use"**
```bash
# Matar processo na porta 5173
# Windows PowerShell:
Get-Process -Id (Get-NetTCPConnection -LocalPort 5173).OwningProcess | Stop-Process

# Ou simplesmente use outra porta:
npm run dev -- --port 5174
```

### **Erro: "CORS policy"**
```bash
# Adicionar localhost nas origens permitidas
docker exec orthotrack-backend env | grep ALLOWED_ORIGINS

# Se necessário, reiniciar backend
docker restart orthotrack-backend
```

---

## 📋 CHECKLIST FINAL

- [x] Backend rodando (localhost:8080)
- [x] Banco populado (5 pacientes, 5 dispositivos)
- [ ] Node.js instalado
- [ ] Frontend dependencies instaladas (`npm install`)
- [ ] Frontend rodando (`npm run dev`)
- [ ] Navegador aberto (localhost:5173)
- [ ] Login funcionando
- [ ] Dashboard mostrando dados

---

## 🎯 DEPOIS QUE FUNCIONAR

### **Próximos Passos:**

1. **Explorar Dashboard** (5min)
   - Ver pacientes
   - Ver dispositivos
   - Ver estatísticas

2. **Configurar ESP32** (15min)
   ```bash
   cd esp32-firmware
   # Editar platformio.ini
   pio run -t upload
   pio device monitor
   ```

3. **Testar Integração** (5min)
   - ESP32 envia dados
   - Backend processa
   - Frontend atualiza

---

## 💡 POR QUE MODO DEV?

**Vantagens:**
- ✅ Mais rápido (sem Docker rebuild)
- ✅ Hot reload (mudanças instantâneas)
- ✅ Melhor para desenvolvimento
- ✅ Fácil de debugar

**Quando usar Docker:**
- Para produção no VPS
- Para simular ambiente de produção
- Para deploy final

---

## 🔑 INFORMAÇÕES IMPORTANTES

### **URLs**
```
Frontend Dev:  http://localhost:5173
Backend:       http://localhost:8080
Health Check:  http://localhost:8080/api/v1/health
```

### **Credenciais**
```
Email: admin@orthotrack.com
Senha: admin123
```

### **Containers Rodando**
```bash
docker ps
```

Você deve ver:
- orthotrack-backend
- orthotrack-postgres
- orthotrack-redis
- orthotrack-mqtt

---

## 🚀 COMANDO ÚNICO

Se você tem Node.js instalado, execute:

```bash
cd frontend && npm install && npm run dev
```

Depois abra: http://localhost:5173

---

## 📞 AJUDA RÁPIDA

**Backend não responde:**
```bash
docker logs orthotrack-backend
docker restart orthotrack-backend
```

**Frontend não inicia:**
```bash
cd frontend
rm -rf node_modules .svelte-kit
npm install
npm run dev
```

**Banco não conecta:**
```bash
docker logs orthotrack-postgres
docker restart orthotrack-postgres
```

---

## 🎉 VOCÊ ESTÁ QUASE LÁ!

```
┌─────────────────────────────────────────┐
│  ✅ Backend: FUNCIONANDO                │
│  ✅ Banco: POPULADO                     │
│  ✅ Dados: 5 pacientes, 5 dispositivos  │
│  ⏳ Frontend: INICIAR AGORA             │
│                                         │
│  🚀 FALTA SÓ 1 COMANDO!                │
└─────────────────────────────────────────┘
```

---

**EXECUTE AGORA:**

```bash
cd frontend
npm install
npm run dev
```

**Depois abra:** http://localhost:5173

---

**BOA SORTE! VOCÊ CONSEGUE! 💪🚀**

*Última atualização: 09/12/2024 - 06:20*
