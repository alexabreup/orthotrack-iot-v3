# 🚀 INÍCIO RÁPIDO - ORTHOTRACK IOT V3 (CORRIGIDO)

## ✅ SISTEMA JÁ ESTÁ RODANDO!

Os containers foram iniciados com sucesso! ✅

---

## 📊 STATUS ATUAL

```bash
# Verificar containers
docker ps
```

**Containers rodando:**
- ✅ `orthotrack-postgres` - Banco de dados
- ✅ `orthotrack-backend` - API Backend
- ✅ `orthotrack-frontend` - Frontend
- ✅ `orthotrack-redis` - Cache
- ✅ `orthotrack-mqtt` - MQTT Broker

---

## 🎯 DADOS JÁ POPULADOS

✅ **5 Pacientes cadastrados**
✅ **5 Dispositivos cadastrados**

```bash
# Verificar dados
docker exec orthotrack-postgres psql -U postgres -d orthotrack -c "SELECT COUNT(*) FROM patients;"
docker exec orthotrack-postgres psql -U postgres -d orthotrack -c "SELECT COUNT(*) FROM braces;"
```

---

## 🌐 ACESSAR O SISTEMA

### **Frontend (Dashboard)**
```
URL: http://localhost:3000
```

**Credenciais:**
- Email: `admin@orthotrack.com`
- Senha: `admin123`

### **Backend (API)**
```
URL: http://localhost:8080
Health Check: http://localhost:8080/api/v1/health
```

---

## 🔍 VERIFICAR DADOS NO BANCO

```bash
# Conectar ao banco
docker exec -it orthotrack-postgres psql -U postgres -d orthotrack

# Ver tabelas
\dt

# Ver pacientes
SELECT id, name, external_id FROM patients;

# Ver dispositivos
SELECT id, device_id, serial_number, status FROM braces;

# Sair
\q
```

---

## 🧪 TESTAR API

### **1. Health Check**
```bash
curl http://localhost:8080/api/v1/health
```

### **2. Listar Pacientes**
```bash
curl http://localhost:8080/api/v1/patients
```

### **3. Dashboard Overview**
```bash
curl http://localhost:8080/api/v1/dashboard/overview
```

### **4. Enviar Telemetria de Teste**
```bash
curl -X POST http://localhost:8080/api/v1/devices/telemetry \
  -H "Content-Type: application/json" \
  -H "X-Device-API-Key: orthotrack-device-key-2024" \
  -d '{
    "device_id": "ESP32-DEMO-001",
    "timestamp": '$(date +%s)',
    "battery_level": 85,
    "sensors": {
      "temperature": {"type": "temperature", "value": 36.5, "unit": "°C"}
    },
    "is_wearing": true
  }'
```

---

## 📋 PRÓXIMOS PASSOS

### **1. Verificar Frontend (2min)**
1. Abrir navegador: http://localhost:3000
2. Fazer login: admin@orthotrack.com / admin123
3. Verificar dashboard mostra dados

### **2. Configurar ESP32 (15min)**
```bash
cd esp32-firmware

# Editar platformio.ini com seu WiFi
# -DWIFI_SSID=\"SEU_WIFI\"
# -DWIFI_PASSWORD=\"SUA_SENHA\"
# -DAPI_ENDPOINT=\"http://SEU_IP:8080\"

# Compilar e upload
pio run -t upload
pio device monitor
```

### **3. Verificar Integração (5min)**
```bash
# Ver últimas leituras de sensores
docker exec orthotrack-postgres psql -U postgres -d orthotrack -c "SELECT * FROM sensor_readings ORDER BY created_at DESC LIMIT 5;"
```

---

## 🛠️ COMANDOS ÚTEIS

### **Ver Logs**
```bash
# Backend
docker logs -f orthotrack-backend

# Frontend
docker logs -f orthotrack-frontend

# Banco
docker logs -f orthotrack-postgres
```

### **Reiniciar Serviços**
```bash
# Reiniciar tudo
docker-compose restart

# Reiniciar apenas backend
docker restart orthotrack-backend

# Reiniciar apenas frontend
docker restart orthotrack-frontend
```

### **Parar e Iniciar**
```bash
# Parar todos
docker-compose down

# Iniciar todos
docker-compose up -d

# Ver status
docker ps
```

### **Backup do Banco**
```bash
docker exec orthotrack-postgres pg_dump -U postgres orthotrack > backup_$(date +%Y%m%d_%H%M%S).sql
```

---

## ✅ CHECKLIST

- [x] Containers iniciados
- [x] Banco populado (5 pacientes, 5 dispositivos)
- [ ] Frontend acessível (http://localhost:3000)
- [ ] Login funciona
- [ ] Dashboard mostra dados
- [ ] ESP32 configurado
- [ ] ESP32 envia dados
- [ ] Dados aparecem no banco

---

## 🚨 TROUBLESHOOTING

### **Frontend não carrega**
```bash
# Ver logs
docker logs orthotrack-frontend

# Reiniciar
docker restart orthotrack-frontend

# Limpar cache do navegador (Ctrl+F5)
```

### **Backend não responde**
```bash
# Ver logs
docker logs orthotrack-backend

# Verificar se está rodando
docker ps | grep orthotrack-backend

# Reiniciar
docker restart orthotrack-backend
```

### **Banco não conecta**
```bash
# Verificar se está rodando
docker ps | grep orthotrack-postgres

# Ver logs
docker logs orthotrack-postgres

# Reiniciar
docker restart orthotrack-postgres
```

---

## 🎬 ROTEIRO DE DEMONSTRAÇÃO

### **1. Introdução (2min)**
- Problema: baixa aderência ao tratamento
- Solução: monitoramento IoT em tempo real

### **2. Dashboard (2min)**
- Abrir http://localhost:3000
- Mostrar estatísticas
- Mostrar pacientes cadastrados

### **3. Gestão de Pacientes (2min)**
- Listar pacientes (5)
- Criar novo paciente
- Mostrar compliance LGPD

### **4. Hardware ESP32 (3min)**
- Mostrar dispositivo físico
- Serial Monitor com logs
- Dados sendo enviados
- Atualização no frontend

### **5. Próximos Passos (1min)**
- Analytics com IA
- Relatórios médicos
- Gamificação

---

## 🎯 OBJETIVO ALCANÇADO

✅ **Sistema funcionando!**
✅ **Dados populados!**
✅ **Pronto para demonstração!**

---

## 📞 INFORMAÇÕES IMPORTANTES

### **Credenciais do Banco**
```
Host:     localhost
Port:     5432
Database: orthotrack
User:     postgres
Password: postgres
```

### **Credenciais do Frontend**
```
Email: admin@orthotrack.com
Senha: admin123
```

### **API Key (ESP32)**
```
orthotrack-device-key-2024
```

---

## 💡 DICAS FINAIS

1. **Teste o frontend AGORA:** http://localhost:3000
2. **Verifique os logs** se algo não funcionar
3. **Use Ctrl+F5** para limpar cache do navegador
4. **Consulte** `CORRECAO-NOMES-CONTAINERS.md` para comandos corretos

---

**SISTEMA PRONTO! AGORA É SÓ TESTAR! 🚀**

*Última atualização: 09/12/2024 - 05:25*
