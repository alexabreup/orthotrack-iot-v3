# 📋 CHEAT SHEET - ORTHOTRACK IOT V3

## ⚡ 5 COMANDOS ESSENCIAIS

```bash
# 1. Testar (5min)
./scripts/test-sistema-completo.sh

# 2. Popular (3min)
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql

# 3. Frontend (1min)
# http://72.60.50.248:3000
# admin@orthotrack.com / admin123

# 4. ESP32 (15min)
cd esp32-firmware
pio run -t upload
pio device monitor

# 5. Verificar (5min)
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db
SELECT * FROM sensor_readings ORDER BY created_at DESC LIMIT 5;
```

---

## 🔑 ACESSO

```
Frontend:  http://72.60.50.248:3000
Backend:   http://72.60.50.248:8080
Email:     admin@orthotrack.com
Senha:     admin123
API Key:   orthotrack-device-key-2024
```

---

## 🛠️ COMANDOS ÚTEIS

```bash
# Ver logs
docker logs -f orthotrack-api
docker logs -f orthotrack-web

# Reiniciar
docker-compose restart

# Backup
docker exec orthotrack-db pg_dump -U orthotrack orthotrack_db > backup.sql

# Testar API
curl http://72.60.50.248:8080/api/v1/health

# Ver containers
docker ps

# Simular telemetria
curl -X POST http://72.60.50.248:8080/api/v1/devices/telemetry \
  -H "Content-Type: application/json" \
  -H "X-Device-API-Key: orthotrack-device-key-2024" \
  -d '{"device_id":"ESP32-TEST-001","timestamp":'$(date +%s)',"battery_level":85,"sensors":{"temperature":{"type":"temperature","value":36.5,"unit":"°C"}},"is_wearing":true}'
```

---

## 🚨 TROUBLESHOOTING RÁPIDO

### Backend não responde
```bash
docker ps | grep orthotrack-api
docker logs orthotrack-api --tail 50
docker restart orthotrack-api
```

### Frontend não carrega
```bash
docker ps | grep orthotrack-web
docker logs orthotrack-web --tail 50
docker restart orthotrack-web
# Ctrl+F5 no navegador
```

### ESP32 não conecta WiFi
```
- Verificar se é 2.4GHz (não 5GHz)
- Verificar SSID e senha em platformio.ini
- Aproximar do roteador
```

### ESP32 não envia dados
```
- Verificar IP do servidor em platformio.ini
- Verificar API Key
- Ver logs do backend: docker logs orthotrack-api
```

### Dashboard mostra zeros
```bash
# Popular banco novamente
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql
```

---

## ✅ CHECKLIST PRÉ-DEMO

- [ ] Containers rodando (`docker ps`)
- [ ] Frontend acessível
- [ ] Backend respondendo
- [ ] Banco com dados (5 pacientes)
- [ ] ESP32 funcionando
- [ ] Serial Monitor aberto
- [ ] Dashboard com números
- [ ] Backup feito
- [ ] Código commitado

---

## 🎬 ROTEIRO DEMO (10min)

1. **Introdução (2min)** - Problema e solução IoT
2. **Dashboard (2min)** - 5 pacientes, 3 online, alertas
3. **Pacientes (2min)** - CRUD e LGPD
4. **ESP32 (3min)** - Hardware enviando dados
5. **Próximos Passos (1min)** - IA, relatórios, gamificação

---

## 📊 DADOS DEMO

```
Pacientes: 5
├── João Silva (ESP32-001) ✅ Online
├── Maria Oliveira (ESP32-002) ✅ Online
├── Pedro Santos (ESP32-003) ❌ Offline
├── Ana Costa (ESP32-004) ✅ Online
└── Lucas Ferreira (ESP32-005) 🔧 Manutenção

Leituras: 864 (24h)
Sessões: 5
Alertas: 4 (1 crítico)
```

---

## 🚨 PLANO B

**ESP32 não funciona:**
- Simular com curl (comando acima)
- Mostrar código do firmware

**Frontend não carrega:**
- Usar Postman/curl
- Mostrar banco diretamente

**Banco falha:**
- Dados mockados
- Explicar arquitetura

---

## 💡 REGRAS DE OURO

✅ **FAZER:**
- Testar 30min antes
- Ter Plano B pronto
- Focar no que funciona

❌ **NÃO FAZER:**
- Testes automatizados
- Refatoração
- Features extras

---

## 📚 DOCUMENTAÇÃO

1. `COMECE-AQUI-AGORA.md` - Início rápido
2. `README-ENTREGA-URGENTE.md` - Overview
3. `.specs/GUIA-EXECUCAO-RAPIDA.md` - Passo a passo
4. `.specs/TROUBLESHOOTING-RAPIDO.md` - Problemas
5. `.specs/RESUMO-EXECUTIVO-ENTREGA.md` - Status completo

---

## 🎯 OBJETIVO

**Sistema funcionando end-to-end em 30 minutos!**

---

*Imprima este arquivo para referência rápida durante a demo!*
