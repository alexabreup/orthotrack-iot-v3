# 🔧 CORREÇÃO - NOMES DOS CONTAINERS

## ⚠️ IMPORTANTE: Nomes Corretos dos Containers

Os nomes dos containers são **diferentes** do que está na documentação original!

### **Nomes CORRETOS:**

```bash
orthotrack-postgres   # ✅ Banco de dados (NÃO orthotrack-db)
orthotrack-backend    # ✅ API Backend
orthotrack-frontend   # ✅ Frontend
orthotrack-redis      # ✅ Redis
orthotrack-mqtt       # ✅ MQTT Broker
```

---

## 🔄 COMANDOS CORRIGIDOS

### **1. Popular Banco de Dados**

❌ **ERRADO:**
```bash
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql
```

✅ **CORRETO:**
```bash
docker cp scripts/popular-dados-demo.sql orthotrack-postgres:/tmp/
docker exec -it orthotrack-postgres psql -U postgres -d orthotrack -f /tmp/popular-dados-demo.sql
```

### **2. Acessar Banco de Dados**

❌ **ERRADO:**
```bash
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db
```

✅ **CORRETO:**
```bash
docker exec -it orthotrack-postgres psql -U postgres -d orthotrack
```

### **3. Backup do Banco**

❌ **ERRADO:**
```bash
docker exec orthotrack-db pg_dump -U orthotrack orthotrack_db > backup.sql
```

✅ **CORRETO:**
```bash
docker exec orthotrack-postgres pg_dump -U postgres orthotrack > backup.sql
```

### **4. Ver Logs**

✅ **CORRETO:**
```bash
# Backend
docker logs -f orthotrack-backend

# Frontend
docker logs -f orthotrack-frontend

# Banco
docker logs -f orthotrack-postgres

# Redis
docker logs -f orthotrack-redis
```

---

## 🚀 COMANDOS ESSENCIAIS CORRIGIDOS

### **Iniciar Containers**
```bash
docker-compose up -d
```

### **Ver Status**
```bash
docker ps
```

### **Parar Containers**
```bash
docker-compose down
```

### **Reiniciar**
```bash
docker-compose restart
```

### **Rebuild Completo**
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

---

## 📊 CREDENCIAIS CORRETAS

### **Banco de Dados:**
```
Host:     localhost (ou orthotrack-postgres dentro da rede Docker)
Port:     5432
Database: orthotrack
User:     postgres
Password: postgres
```

### **Frontend:**
```
URL:   http://72.60.50.248:3000
Email: admin@orthotrack.com
Senha: admin123
```

### **Backend:**
```
URL: http://72.60.50.248:8080
API Key: orthotrack-device-key-2024
```

---

## ✅ SEQUÊNCIA CORRETA PARA POPULAR BANCO

```bash
# 1. Verificar se containers estão rodando
docker ps

# 2. Copiar script SQL
docker cp scripts/popular-dados-demo.sql orthotrack-postgres:/tmp/

# 3. Executar script
docker exec -it orthotrack-postgres psql -U postgres -d orthotrack -f /tmp/popular-dados-demo.sql

# 4. Verificar dados
docker exec -it orthotrack-postgres psql -U postgres -d orthotrack
SELECT COUNT(*) FROM patients;
\q
```

---

## 🔍 VERIFICAR DADOS NO BANCO

```bash
# Conectar ao banco
docker exec -it orthotrack-postgres psql -U postgres -d orthotrack

# Ver tabelas
\dt

# Contar pacientes
SELECT COUNT(*) FROM patients;

# Contar dispositivos
SELECT COUNT(*) FROM braces;

# Ver últimas leituras
SELECT * FROM sensor_readings ORDER BY created_at DESC LIMIT 5;

# Sair
\q
```

---

## 🚨 TROUBLESHOOTING

### **Erro: "No such container: orthotrack-db"**
✅ **Solução:** Use `orthotrack-postgres` ao invés de `orthotrack-db`

### **Erro: "database orthotrack_db does not exist"**
✅ **Solução:** Use `orthotrack` ao invés de `orthotrack_db`

### **Erro: "role orthotrack does not exist"**
✅ **Solução:** Use `-U postgres` ao invés de `-U orthotrack`

---

## 📝 NOTA IMPORTANTE

**Todos os documentos criados anteriormente usam os nomes ERRADOS!**

Use este arquivo como referência para os comandos corretos.

Os nomes corretos são:
- Container: `orthotrack-postgres`
- Database: `orthotrack`
- User: `postgres`
- Password: `postgres`

---

*Última atualização: 09/12/2024 - 05:20*
