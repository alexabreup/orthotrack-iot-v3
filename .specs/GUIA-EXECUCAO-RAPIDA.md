# 🚀 GUIA DE EXECUÇÃO RÁPIDA - 30 MINUTOS

## ⏰ **COMEÇAR AGORA**

### **PASSO 1: Testar Sistema (5min)**

```bash
# Dar permissão ao script
chmod +x scripts/test-sistema-completo.sh

# Executar teste completo
./scripts/test-sistema-completo.sh
```

**Resultado esperado:** 
- ✅ 8/8 testes passando
- ✅ "Sistema pronto para demonstração"

**Se falhar:**
- Verificar containers: `docker ps`
- Ver logs: `docker logs orthotrack-api`
- Reiniciar: `docker-compose restart`

---

### **PASSO 2: Popular Banco com Dados Demo (3min)**

```bash
# Copiar script SQL para container
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/

# Executar script
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql
```

**Resultado esperado:**
```
Instituições     | 2
Profissionais    | 3
Pacientes        | 5
Dispositivos     | 5
Leituras Sensores| 864
Sessões de Uso   | 5
Compliance Diário| 35
Alertas          | 4
✓ Dados de demonstração inseridos com sucesso!
```

---

### **PASSO 3: Verificar Frontend (2min)**

1. **Abrir navegador:** http://72.60.50.248:3000

2. **Fazer login:**
   - Email: `admin@orthotrack.com`
   - Senha: `admin123`

3. **Verificar Dashboard:**
   - [ ] Total de Pacientes: 5
   - [ ] Dispositivos Online: 3
   - [ ] Alertas Ativos: 3
   - [ ] Compliance Médio: ~85%

4. **Verificar Pacientes:**
   - [ ] Lista mostra 5 pacientes
   - [ ] Consegue abrir detalhes
   - [ ] Consegue criar novo

---

### **PASSO 4: Testar ESP32 (15min)**

#### A. Preparar Hardware
1. Conectar ESP32 ao computador via USB
2. Verificar porta COM (Windows) ou /dev/ttyUSB0 (Linux)

#### B. Configurar WiFi
```ini
# Editar: esp32-firmware/platformio.ini

build_flags = 
    -DWIFI_SSID=\"SEU_WIFI_AQUI\"
    -DWIFI_PASSWORD=\"SUA_SENHA_AQUI\"
    -DAPI_ENDPOINT=\"http://72.60.50.248:8080\"
    -DDEVICE_ID=\"ESP32-DEMO-001\"
    -DAPI_KEY=\"orthotrack-device-key-2024\"
```

#### C. Compilar e Upload
```bash
cd esp32-firmware
pio run -t upload
pio device monitor
```

#### D. Verificar Serial Monitor
```
=== OrthoTrack ESP32 Firmware v3.0 ===
Inicializando TTP223... ✅ OK
Inicializando MPU6050... ✅ OK
Inicializando BMP280... ✅ OK
Conectando WiFi..... ✅ Conectado!
IP: 192.168.x.x
✅ Sistema inicializado com sucesso!
💓 Heartbeat enviado
📡 Telemetria enviada
```

**Se não conectar WiFi:**
- Verificar se é 2.4GHz (ESP32 não suporta 5GHz)
- Verificar SSID e senha
- Tentar hotspot do celular

---

### **PASSO 5: Verificar Integração (5min)**

#### A. Verificar dados chegando no banco
```bash
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db
```

```sql
-- Ver últimas leituras
SELECT 
  b.device_id,
  sr.temperature,
  sr.is_wearing,
  sr.created_at
FROM sensor_readings sr
JOIN braces b ON b.id = sr.brace_id
ORDER BY sr.created_at DESC
LIMIT 5;

-- Sair
\q
```

#### B. Verificar no Frontend
1. Ir em **Dispositivos**
2. Verificar **ESP32-DEMO-001** está **Online**
3. Ver **Última atualização** recente
4. Ver **Bateria** atualizada

---

## ✅ **CHECKLIST FINAL**

Antes de considerar pronto:

- [ ] **Backend responde:** `curl http://72.60.50.248:8080/api/v1/health`
- [ ] **Frontend carrega:** Navegador abre dashboard
- [ ] **Login funciona:** Consegue entrar no sistema
- [ ] **Dashboard mostra dados:** Números corretos aparecem
- [ ] **5 pacientes cadastrados:** Lista completa
- [ ] **5 dispositivos cadastrados:** 3 online, 1 offline, 1 manutenção
- [ ] **ESP32 conecta:** Serial Monitor mostra "WiFi conectado"
- [ ] **ESP32 envia dados:** Serial Monitor mostra "Telemetria enviada"
- [ ] **Dados no banco:** Query retorna leituras recentes
- [ ] **Frontend atualiza:** Dispositivo aparece como online

---

## 🎬 **ROTEIRO DE DEMONSTRAÇÃO (10min)**

### **1. Introdução (1min)**
> "Sistema IoT para monitoramento de compliance de órteses ortopédicas desenvolvido para a AACD"

**Mostrar:**
- Arquitetura: ESP32 → Backend Go → Frontend Svelte
- Tecnologias: Go, SvelteKit, PostgreSQL, ESP32

### **2. Dashboard (2min)**
> "Dashboard em tempo real com estatísticas gerais"

**Mostrar:**
- Total de pacientes: 5
- Dispositivos online: 3 de 5
- Alertas ativos: 3 (1 crítico)
- Compliance médio: ~85%

### **3. Gestão de Pacientes (2min)**
> "Sistema completo de gestão de pacientes com compliance LGPD"

**Mostrar:**
- Lista de pacientes
- Criar novo paciente (formulário completo)
- Campos LGPD: consentimento, retenção de dados

### **4. Monitoramento de Dispositivos (2min)**
> "Monitoramento em tempo real dos dispositivos ESP32"

**Mostrar:**
- Lista de dispositivos com status
- Dispositivo online (verde)
- Dispositivo offline (vermelho)
- Bateria e sinal

### **5. Hardware ESP32 (2min)**
> "Dispositivo físico com sensores integrados"

**Mostrar:**
- Hardware ESP32 físico
- Serial Monitor com logs
- Dados sendo enviados
- Atualização no frontend

### **6. Alertas e Compliance (1min)**
> "Sistema de alertas automáticos e cálculo de compliance"

**Mostrar:**
- Alertas ativos (bateria baixa, baixo compliance)
- Gráfico de compliance (se implementado)
- Histórico de uso

---

## 🚨 **PLANO B - Se Algo Falhar**

### **ESP32 não conecta:**
```bash
# Simular telemetria com curl
curl -X POST http://72.60.50.248:8080/api/v1/devices/telemetry \
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

### **Frontend não carrega:**
- Usar Postman para demonstrar API
- Mostrar banco de dados diretamente
- Mostrar código

### **Banco falha:**
- Usar dados mockados
- Mostrar estrutura de dados
- Explicar arquitetura

---

## 📞 **COMANDOS ÚTEIS**

### Ver logs em tempo real
```bash
# Backend
docker logs -f orthotrack-api

# Frontend
docker logs -f orthotrack-web

# Banco
docker logs -f orthotrack-db
```

### Reiniciar serviços
```bash
# Reiniciar tudo
docker-compose restart

# Reiniciar apenas backend
docker restart orthotrack-api

# Rebuild completo
docker-compose down
docker-compose up -d --build
```

### Verificar saúde
```bash
# Backend
curl http://72.60.50.248:8080/api/v1/health

# Dashboard
curl http://72.60.50.248:8080/api/v1/dashboard/overview

# Containers
docker ps
```

---

## 💡 **DICAS FINAIS**

1. **Teste TUDO 30min antes da apresentação**
2. **Tenha o Serial Monitor aberto durante demo**
3. **Tenha um terminal com logs aberto**
4. **Prepare-se para perguntas sobre:**
   - Escalabilidade
   - Segurança (LGPD)
   - Próximos passos
   - Tecnologias escolhidas

5. **Seja honesto sobre:**
   - O que não foi implementado (IA, ML, gamificação)
   - Limitações atuais
   - Próximas melhorias

---

**BOA SORTE! 🚀**

*Você tem um sistema funcional end-to-end. Foque na demonstração!*
