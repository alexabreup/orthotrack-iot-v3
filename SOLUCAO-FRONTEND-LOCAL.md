# 🔧 SOLUÇÃO - FRONTEND LOCAL

## ⚠️ PROBLEMA IDENTIFICADO

O frontend foi construído para acessar o backend no IP do VPS (`72.60.50.248:8080`), mas você está rodando localmente.

**Erro:**
```
Failed to load resource: net::ERR_CONNECTION_TIMED_OUT
http://72.60.50.248:8080/api/v1/auth/login
```

---

## ✅ SOLUÇÃO RÁPIDA (2 opções)

### **OPÇÃO 1: Usar Backend Local (RECOMENDADO)**

O backend já está rodando localmente em `localhost:8080`. Vamos configurar o frontend para usar localhost.

#### **Passo 1: Parar containers**
```bash
docker-compose down
```

#### **Passo 2: Editar docker-compose.yml**

Encontre a seção `frontend` e altere as variáveis de ambiente:

```yaml
frontend:
  build:
    context: ./frontend
    dockerfile: Dockerfile
    args:
      VITE_API_BASE_URL: http://localhost:8080  # ✅ MUDAR AQUI
      VITE_WS_URL: ws://localhost:8080/ws       # ✅ MUDAR AQUI
```

#### **Passo 3: Rebuild e reiniciar**
```bash
docker-compose build --no-cache frontend
docker-compose up -d
```

#### **Passo 4: Testar**
```
Abrir: http://localhost:3000
Login: admin@orthotrack.com / admin123
```

---

### **OPÇÃO 2: Rodar Frontend em Modo Desenvolvimento (MAIS RÁPIDO)**

Ao invés de usar Docker, rode o frontend diretamente com npm:

#### **Passo 1: Instalar dependências**
```bash
cd frontend
npm install
```

#### **Passo 2: Criar arquivo .env**
```bash
# frontend/.env
VITE_API_BASE_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080/ws
```

#### **Passo 3: Rodar em modo dev**
```bash
npm run dev
```

#### **Passo 4: Acessar**
```
URL: http://localhost:5173
Login: admin@orthotrack.com / admin123
```

**Vantagens:**
- ✅ Mais rápido (sem rebuild)
- ✅ Hot reload (mudanças instantâneas)
- ✅ Melhor para desenvolvimento

---

## 🎯 OPÇÃO RECOMENDADA

**Use a OPÇÃO 2 (modo desenvolvimento)** porque:
1. Mais rápido para testar
2. Não precisa rebuild do Docker
3. Melhor experiência de desenvolvimento
4. Hot reload automático

---

## 📋 COMANDOS COMPLETOS (OPÇÃO 2)

```bash
# 1. Parar frontend Docker (manter backend rodando)
docker stop orthotrack-frontend

# 2. Ir para pasta frontend
cd frontend

# 3. Instalar dependências (se ainda não instalou)
npm install

# 4. Criar arquivo .env
echo "VITE_API_BASE_URL=http://localhost:8080" > .env
echo "VITE_WS_URL=ws://localhost:8080/ws" >> .env

# 5. Rodar em modo dev
npm run dev

# 6. Abrir navegador
# http://localhost:5173
```

---

## ✅ VERIFICAR SE FUNCIONOU

### **1. Backend está respondendo?**
```bash
curl http://localhost:8080/api/v1/health
```

**Esperado:**
```json
{"status":"healthy","timestamp":"...","version":"3.0.0"}
```

### **2. Frontend carrega?**
```
Abrir: http://localhost:5173 (modo dev) ou http://localhost:3000 (Docker)
```

### **3. Login funciona?**
```
Email: admin@orthotrack.com
Senha: admin123
```

### **4. Dashboard mostra dados?**
- Ver total de pacientes (5)
- Ver dispositivos (5)
- Ver estatísticas

---

## 🚨 TROUBLESHOOTING

### **Erro: "npm: command not found"**
```bash
# Instalar Node.js
# Windows: https://nodejs.org/
# Linux: sudo apt install nodejs npm
```

### **Erro: "Cannot find module"**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

### **Erro: "Port 5173 already in use"**
```bash
# Matar processo na porta 5173
# Windows: netstat -ano | findstr :5173
# Linux: lsof -ti:5173 | xargs kill -9
```

### **Erro: "CORS policy"**
```bash
# Verificar se backend permite localhost
docker logs orthotrack-backend | grep CORS

# Se necessário, adicionar no .env do backend
echo "ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000" >> .env
docker-compose restart backend
```

---

## 📊 COMPARAÇÃO DAS OPÇÕES

| Aspecto | Opção 1 (Docker) | Opção 2 (Dev Mode) |
|---------|------------------|-------------------|
| Velocidade | ❌ Lento (rebuild) | ✅ Rápido |
| Hot Reload | ❌ Não | ✅ Sim |
| Produção | ✅ Sim | ❌ Não |
| Desenvolvimento | ❌ Não ideal | ✅ Ideal |
| Setup | ❌ Complexo | ✅ Simples |

**Recomendação:** Use Opção 2 para desenvolvimento/teste, Opção 1 para produção.

---

## 🎯 PRÓXIMOS PASSOS

Depois que o frontend estiver funcionando:

1. **Testar Login** (2min)
2. **Verificar Dashboard** (2min)
3. **Listar Pacientes** (1min)
4. **Configurar ESP32** (15min)
5. **Testar Integração** (5min)

---

## 💡 DICA IMPORTANTE

**Para demonstração:**
- Use modo desenvolvimento (Opção 2) para testes rápidos
- Use Docker (Opção 1) apenas se precisar simular produção

**Para produção no VPS:**
- Use Docker com IP correto do VPS (72.60.50.248)
- Configure CORS corretamente
- Use HTTPS

---

**ESCOLHA A OPÇÃO 2 E CONTINUE! 🚀**

*Última atualização: 09/12/2024 - 06:15*
