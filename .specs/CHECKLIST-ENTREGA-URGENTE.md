# 🚨 CHECKLIST ENTREGA URGENTE - ORTHOTRACK IOT V3
## Prazo: 2 dias (Hoje + Amanhã)

---

## 🎯 **OBJETIVO**
Ter o sistema **funcionando end-to-end** para demonstração:
- ESP32 enviando dados reais
- Backend processando e armazenando
- Frontend exibindo dados em tempo real
- Demonstração de compliance funcionando

---

## ✅ **DIA 1 - HOJE (Prioridade Máxima)**

### 🔴 **CRÍTICO - Fazer AGORA**

#### 1. **Backend: Endpoints Essenciais Funcionando** (2h)
- [ ] **GET /api/v1/dashboard/overview** - Dashboard principal
  - Retornar: total de pacientes, dispositivos online, alertas ativos
  - Dados mockados se necessário
  
- [ ] **GET /api/v1/patients** - Listar pacientes
  - Já funciona ✅
  
- [ ] **POST /api/v1/patients** - Criar paciente
  - Já funciona ✅
  
- [ ] **GET /api/v1/braces** - Listar dispositivos
  - Verificar se retorna dados
  
- [ ] **POST /api/v1/devices/telemetry** - Receber dados ESP32
  - **TESTAR COM CURL AGORA**
  - Verificar se salva no banco

**Teste Rápido:**
```bash
# Testar telemetria
curl -X POST http://72.60.50.248:8080/api/v1/devices/telemetry \
  -H "Content-Type: application/json" \
  -H "X-Device-API-Key: orthotrack-device-key-2024" \
  -d '{
    "device_id": "ESP32-TEST-001",
    "timestamp": 1733702400,
    "battery_level": 85,
    "sensors": {
      "accelerometer": {"type": "accelerometer", "value": {"x": 0.1, "y": 0.2, "z": 9.8}, "unit": "m/s²"},
      "temperature": {"type": "temperature", "value": 36.5, "unit": "°C"}
    },
    "is_wearing": true
  }'
```

#### 2. **Frontend: Dashboard Básico** (2h)
- [ ] **Página Home** - Mostrar cards com estatísticas
  - Total de pacientes
  - Dispositivos online
  - Alertas ativos
  - Gráfico simples de compliance (pode ser mockado)

- [ ] **Página Pacientes** - Já funciona ✅
  
- [ ] **Página Dispositivos** - Listar dispositivos com status
  - Online/Offline
  - Bateria
  - Último contato

**Arquivo a criar/editar:**
```typescript
// frontend/src/routes/+page.svelte
// Dashboard principal com cards de estatísticas
```

#### 3. **ESP32: Firmware Testado** (1h)
- [ ] **Compilar e fazer upload** no ESP32 físico
- [ ] **Verificar no Serial Monitor**:
  - WiFi conectado ✅
  - Sensores inicializados ✅
  - Telemetria sendo enviada
  - Resposta 200 do backend

- [ ] **Ajustar configuração** se necessário:
```cpp
// platformio.ini
-DAPI_ENDPOINT=\"http://72.60.50.248:8080\"
-DDEVICE_ID=\"ESP32-DEMO-001\"
-DAPI_KEY=\"orthotrack-device-key-2024\"
```

#### 4. **Banco de Dados: Verificar Dados** (30min)
- [ ] **Conectar ao PostgreSQL**
```bash
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db
```

- [ ] **Verificar tabelas existem**
```sql
\dt
SELECT * FROM patients LIMIT 5;
SELECT * FROM braces LIMIT 5;
SELECT * FROM sensor_readings ORDER BY created_at DESC LIMIT 10;
```

- [ ] **Se não existir dados de teste, inserir**
```sql
-- Inserir paciente de teste
INSERT INTO patients (external_id, name, institution_id, prescription_hours, status)
VALUES ('PAT-DEMO-001', 'Paciente Demonstração', 1, 16, 'active');

-- Inserir dispositivo de teste
INSERT INTO braces (device_id, serial_number, mac_address, patient_id, status)
VALUES ('ESP32-DEMO-001', 'SN-001', '00:00:00:00:00:01', 1, 'online');
```

---

### 🟡 **IMPORTANTE - Fazer Hoje se Sobrar Tempo**

#### 5. **Alertas Básicos** (1h)
- [ ] **Backend: Criar alerta quando bateria < 20%**
```go
// internal/services/iot_service.go
if telemetry.BatteryLevel < 20 {
    alert := &models.Alert{
        Type: "battery_low",
        Severity: "high",
        Message: fmt.Sprintf("Bateria baixa: %d%%", telemetry.BatteryLevel),
    }
    s.alertService.CreateAlert(alert)
}
```

- [ ] **Frontend: Mostrar alertas no dashboard**
```svelte
<!-- Badge vermelho com número de alertas -->
{#if alertCount > 0}
  <div class="badge badge-error">{alertCount}</div>
{/if}
```

#### 6. **Gráfico de Compliance Simples** (1h)
- [ ] **Backend: Endpoint de compliance**
```go
GET /api/v1/patients/:id/compliance?period=7d
// Retornar: [{date: "2024-12-08", hours: 14, target: 16, percentage: 87.5}]
```

- [ ] **Frontend: Gráfico com Chart.js**
```svelte
<script>
  import { Line } from 'svelte-chartjs';
  // Gráfico de linha mostrando horas de uso vs target
</script>
```

---

## ✅ **DIA 2 - AMANHÃ (Finalização)**

### 🔴 **CRÍTICO - Fazer AMANHÃ**

#### 7. **Testes End-to-End** (2h)
- [ ] **Cenário 1: Cadastrar Paciente**
  1. Abrir frontend
  2. Ir em Pacientes > Novo
  3. Preencher formulário
  4. Salvar
  5. Verificar aparece na lista

- [ ] **Cenário 2: ESP32 Enviando Dados**
  1. Ligar ESP32
  2. Ver no Serial Monitor: "Telemetria enviada"
  3. Verificar no banco: `SELECT * FROM sensor_readings ORDER BY created_at DESC LIMIT 1;`
  4. Ver no frontend: dispositivo aparece como "online"

- [ ] **Cenário 3: Dashboard Atualizado**
  1. Abrir dashboard
  2. Ver estatísticas corretas
  3. Ver dispositivos online
  4. Ver alertas (se houver)

#### 8. **Documentação Mínima** (1h)
- [ ] **README.md atualizado** com:
  - Como rodar o projeto
  - Credenciais de acesso
  - Endpoints principais
  - Como testar

- [ ] **Slides/Apresentação** (se necessário)
  - Arquitetura do sistema
  - Demonstração funcionando
  - Próximos passos

#### 9. **Deploy Final e Verificação** (2h)
- [ ] **Rebuild completo**
```bash
cd /opt/orthotrack
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

- [ ] **Verificar todos os serviços**
```bash
docker-compose ps
# Todos devem estar "Up" e "healthy"
```

- [ ] **Teste de fumaça completo**
  - [ ] Frontend carrega: http://72.60.50.248:3000
  - [ ] Backend responde: http://72.60.50.248:8080/api/v1/health
  - [ ] Login funciona
  - [ ] Dashboard mostra dados
  - [ ] Pacientes listam
  - [ ] ESP32 envia dados

#### 10. **Backup e Contingência** (30min)
- [ ] **Backup do banco de dados**
```bash
docker exec orthotrack-db pg_dump -U orthotrack orthotrack_db > backup_final.sql
```

- [ ] **Commit e push final**
```bash
git add .
git commit -m "feat: versão final para demonstração"
git push origin main
```

- [ ] **Documentar problemas conhecidos**
  - Listar o que não foi implementado
  - Listar o que é mockado
  - Listar próximos passos

---

## 🎬 **ROTEIRO DE DEMONSTRAÇÃO**

### **Preparação (5min antes)**
1. Verificar todos os serviços rodando
2. Ter ESP32 ligado e conectado
3. Ter navegador aberto no dashboard
4. Ter terminal com logs aberto

### **Demonstração (10-15min)**

**1. Introdução (2min)**
- "Sistema IoT para monitoramento de órteses ortopédicas"
- "Arquitetura: ESP32 → Backend Go → Frontend Svelte"

**2. Dashboard (3min)**
- Mostrar estatísticas gerais
- Mostrar dispositivos online
- Mostrar alertas (se houver)

**3. Gestão de Pacientes (3min)**
- Listar pacientes existentes
- Criar novo paciente
- Mostrar formulário completo (LGPD compliance)

**4. Dispositivo ESP32 (5min)**
- Mostrar hardware físico
- Mostrar Serial Monitor com logs
- Mostrar dados chegando no backend
- Mostrar atualização no frontend

**5. Compliance (2min)**
- Mostrar cálculo de horas de uso
- Mostrar gráfico (se implementado)
- Explicar como funciona a detecção

**6. Próximos Passos (1min)**
- Analytics com IA
- Relatórios médicos
- Gamificação
- Integração com sistemas hospitalares

---

## 🚨 **PLANO B - Se Algo Falhar**

### **Se ESP32 não conectar:**
- Usar dados mockados no backend
- Simular telemetria com curl
- Mostrar código do firmware

### **Se frontend não carregar:**
- Usar Postman/curl para demonstrar API
- Mostrar banco de dados diretamente
- Mostrar código

### **Se banco falhar:**
- Usar dados em memória (mock)
- Mostrar estrutura de dados
- Explicar arquitetura

---

## 📋 **CHECKLIST FINAL PRÉ-APRESENTAÇÃO**

- [ ] Todos os containers rodando
- [ ] Frontend acessível
- [ ] Backend respondendo
- [ ] ESP32 enviando dados
- [ ] Pelo menos 1 paciente cadastrado
- [ ] Pelo menos 1 dispositivo registrado
- [ ] Dados de telemetria no banco
- [ ] README.md atualizado
- [ ] Backup do banco feito
- [ ] Código commitado no Git
- [ ] Slides/apresentação pronta (se necessário)

---

## 🎯 **FOCO ABSOLUTO**

**NÃO FAZER:**
- ❌ Testes automatizados (não há tempo)
- ❌ Refatoração de código
- ❌ Otimizações de performance
- ❌ Features avançadas (IA, ML, gamificação)
- ❌ Documentação extensa

**FAZER:**
- ✅ Sistema funcionando end-to-end
- ✅ Demonstração fluida
- ✅ Dados reais sendo processados
- ✅ Interface apresentável
- ✅ Código commitado e backup feito

---

## 💡 **DICAS IMPORTANTES**

1. **Teste TUDO antes da apresentação**
2. **Tenha um Plano B para cada componente**
3. **Documente problemas conhecidos**
4. **Seja honesto sobre o que não foi implementado**
5. **Foque na demonstração, não na perfeição**

---

**BOA SORTE! 🚀**

*Última atualização: 08/12/2024*
