# Guia de Testes - ESP32 OrthoTrack Firmware

## 📋 Visão Geral

Este guia descreve todos os testes necessários para validar o firmware ESP32 antes do deployment em produção.

## 🔧 Pré-requisitos

- [ ] Hardware montado conforme HARDWARE_SETUP.md
- [ ] Firmware compilado com sucesso
- [ ] ESP32 conectado ao computador via USB
- [ ] Rede WiFi "orthotrack" disponível
- [ ] Backend acessível (ou mock para testes)

## 📝 Checklist de Testes

### Fase 1: Testes de Hardware ✅

#### 1.1 Teste de Conexão I2C

**Objetivo**: Verificar se sensores estão conectados corretamente

**Procedimento**:
```bash
# 1. Compilar I2C scanner
cd esp32-firmware
pio run -e i2c_scanner

# 2. Fazer upload
pio run -e i2c_scanner --target upload

# 3. Monitorar saída
pio device monitor
```

**Resultado esperado**:
```
✅ Dispositivo I2C encontrado no endereço 0x68 → MPU6050
✅ Dispositivo I2C encontrado no endereço 0x76 → BMP280
✅ Total de dispositivos encontrados: 2
🎉 Todos os sensores estão conectados!
```

**Critérios de Sucesso**:
- [ ] MPU6050 detectado em 0x68 ou 0x69
- [ ] BMP280 detectado em 0x76 ou 0x77
- [ ] Sem erros de comunicação I2C

---

#### 1.2 Teste do Sensor de Toque TTP223

**Objetivo**: Verificar se o sensor de toque está funcionando corretamente

**Procedimento**:
```bash
# 1. Compilar teste do TTP223
cd esp32-firmware
pio run -e ttp223_test

# 2. Fazer upload
pio run -e ttp223_test --target upload

# 3. Monitorar saída
pio device monitor
```

**Resultado esperado**:
```
=== TTP223 Touch Sensor Test ===
Touch the sensor to test...

✓ Setup complete
Monitoring touch sensor on GPIO4...

○ ○ ○ ○ ○ ○ ○ ○ ○ ○ 
✓ TOUCH DETECTED
● ● ● ● ● ● ● ● ● ● 
○ Touch released
○ ○ ○ ○ ○ ○ ○ ○ ○ ○ 
```

**Teste Manual**:
1. Toque no sensor TTP223 (ou no pad de toque conectado)
2. Observe o LED interno do ESP32 acender
3. Observe a mensagem "✓ TOUCH DETECTED" no Serial Monitor
4. Solte o toque
5. Observe o LED apagar
6. Observe a mensagem "○ Touch released"

**Critérios de Sucesso**:
- [ ] LED acende quando sensor é tocado
- [ ] LED apaga quando sensor é solto
- [ ] Serial Monitor mostra mensagens corretas
- [ ] Resposta rápida (< 220ms)
- [ ] Sem falsos positivos (LED não acende sem toque)
- [ ] Sem falsos negativos (LED sempre acende com toque)

**Troubleshooting**:
- Se sempre HIGH: Verificar conexões, sensor pode estar em modo toggle
- Se sempre LOW: Verificar alimentação 3.3V, verificar GPIO4
- Se intermitente: Adicionar capacitor 100nF entre VCC e GND

---

#### 1.2 Teste de Inicialização de Sensores

**Objetivo**: Verificar se sensores inicializam corretamente

**Procedimento**:
```bash
# 1. Upload do firmware principal
pio run --target upload

# 2. Monitorar serial
pio device monitor
```

**Resultado esperado**:
```
=== OrthoTrack ESP32 Firmware v3.0 ===
Inicializando MPU6050... ✅ OK
Inicializando BMP280... ✅ OK
```

**Critérios de Sucesso**:
- [ ] MPU6050 inicializa sem erros
- [ ] BMP280 inicializa sem erros
- [ ] Configurações aplicadas corretamente

---

### Fase 2: Testes de Conectividade 📡

#### 2.1 Teste de Conexão WiFi

**Objetivo**: Verificar conexão com rede WiFi

**Resultado esperado**:
```
Conectando WiFi........... ✅ Conectado!
IP: 192.168.1.100
```

**Critérios de Sucesso**:
- [ ] Conecta à rede "orthotrack"
- [ ] Obtém endereço IP
- [ ] Conexão estável (sem desconexões)

**Troubleshooting**:
- Se falhar: Verificar SSID e senha
- Se timeout: Verificar alcance do sinal
- Se não conecta: Verificar rede é 2.4GHz

---

#### 2.2 Teste de Sincronização NTP

**Objetivo**: Verificar sincronização de tempo

**Resultado esperado**:
```
🕐 Sincronizando tempo via NTP...
✅ Tempo sincronizado: 2024-12-07 10:30:00
```

**Critérios de Sucesso**:
- [ ] Conecta ao servidor NTP
- [ ] Obtém timestamp correto
- [ ] Timezone UTC-3 aplicado

---

### Fase 3: Testes de Leitura de Sensores 📊

#### 3.1 Teste de Leitura do MPU6050

**Objetivo**: Verificar leituras do acelerômetro e giroscópio

**Procedimento**:
1. Deixar ESP32 parado sobre mesa
2. Observar leituras no serial
3. Mover ESP32 em diferentes direções
4. Observar mudanças nas leituras

**Resultado esperado (parado)**:
```
📊 Aceleração: X=0.0 Y=0.0 Z=9.8 m/s²
🔄 Giroscópio: X=0.0 Y=0.0 Z=0.0 rad/s
```

**Resultado esperado (movimento)**:
```
📊 Aceleração: X=2.5 Y=-1.2 Z=8.5 m/s²
🔄 Giroscópio: X=0.5 Y=-0.3 Z=0.1 rad/s
✅ Movimento detectado!
```

**Critérios de Sucesso**:
- [ ] Aceleração Z ≈ 9.8 m/s² quando parado
- [ ] Valores mudam ao mover dispositivo
- [ ] Sem leituras NaN ou infinitas
- [ ] Movimento detectado corretamente

---

#### 3.2 Teste de Leitura do BMP280

**Objetivo**: Verificar leituras de temperatura e pressão

**Resultado esperado**:
```
🌡️  Temperatura: 25.5°C
📈 Pressão: 1013.25 hPa
```

**Critérios de Sucesso**:
- [ ] Temperatura entre 15-35°C (ambiente)
- [ ] Pressão entre 950-1050 hPa (normal)
- [ ] Valores estáveis (variação < 1°C/min)
- [ ] Sem leituras inválidas

**Teste adicional**:
- Soprar ar quente no sensor → temperatura deve subir
- Pressionar levemente o sensor → pressão pode variar

---

#### 3.3 Teste de Monitoramento de Bateria

**Objetivo**: Verificar leitura do nível de bateria

**Resultado esperado**:
```
🔋 Bateria: 85%
⚡ Tensão: 3.9V
```

**Critérios de Sucesso**:
- [ ] Percentual entre 0-100%
- [ ] Tensão entre 3.0-4.2V
- [ ] Valor coerente com estado da bateria

**Nota**: Se não houver bateria conectada, valor pode ser aleatório.

---

### Fase 4: Testes de Detecção de Uso 👤

#### 4.1 Teste de Detecção de Uso (Temperatura + Movimento)

**Objetivo**: Verificar algoritmo de detecção de uso do colete

**Procedimento**:
1. **Teste 1 - Não usando (frio e parado)**:
   - Deixar ESP32 parado em temperatura ambiente
   - Observar: `isWearing = false`

2. **Teste 2 - Não usando (frio com movimento)**:
   - Mover ESP32 em temperatura ambiente
   - Observar: `isWearing = false`

3. **Teste 3 - Simulando uso (quente com movimento)**:
   - Segurar ESP32 na mão (temperatura corporal)
   - Mover levemente
   - Aguardar 5 leituras consecutivas
   - Observar: `isWearing = true`

**Resultado esperado**:
```
Teste 1:
🌡️  Temperatura: 22°C
📊 Movimento: Não detectado
👤 Estado de uso: NÃO USADO

Teste 2:
🌡️  Temperatura: 22°C
📊 Movimento: Detectado
👤 Estado de uso: NÃO USADO

Teste 3:
🌡️  Temperatura: 34°C
📊 Movimento: Detectado
👤 Estado de uso: EM USO
🚨 Alerta de mudança de estado enviado
```

**Critérios de Sucesso**:
- [ ] Não detecta uso em temperatura ambiente
- [ ] Não detecta uso apenas com movimento
- [ ] Detecta uso com temperatura + movimento
- [ ] Requer 5 leituras consecutivas
- [ ] Envia alerta ao mudar estado

---

### Fase 5: Testes de Comunicação com Backend 🌐

#### 5.1 Teste de Heartbeat

**Objetivo**: Verificar envio periódico de heartbeat

**Resultado esperado** (a cada 30 segundos):
```
💓 Heartbeat enviado
HTTP 200 OK
```

**Critérios de Sucesso**:
- [ ] Heartbeat enviado a cada 30 segundos
- [ ] Backend retorna HTTP 200
- [ ] Payload JSON válido
- [ ] Inclui device_id, status, battery, signal

**Verificar no backend**:
```bash
curl http://localhost:8080/api/v1/braces/ESP32-WROOM32-001 \
  -H "Authorization: Bearer $TOKEN"
```

Deve mostrar `last_heartbeat` atualizado.

---

#### 5.2 Teste de Telemetria

**Objetivo**: Verificar envio periódico de telemetria

**Resultado esperado** (a cada 5 segundos):
```
📡 Telemetria enviada
HTTP 200 OK
```

**Critérios de Sucesso**:
- [ ] Telemetria enviada a cada 5 segundos
- [ ] Backend retorna HTTP 200
- [ ] Payload JSON válido
- [ ] Inclui todos os dados dos sensores

**Verificar no backend**:
```bash
curl http://localhost:8080/api/v1/sensor-readings?device_id=ESP32-WROOM32-001 \
  -H "Authorization: Bearer $TOKEN"
```

Deve mostrar leituras recentes.

---

#### 5.3 Teste de Alertas

**Objetivo**: Verificar envio de alertas de mudança de estado

**Procedimento**:
1. Simular mudança de estado (segurar ESP32)
2. Aguardar detecção de uso
3. Verificar envio de alerta

**Resultado esperado**:
```
👤 Estado de uso: EM USO
🚨 Alerta de mudança de estado enviado
HTTP 200 OK
```

**Critérios de Sucesso**:
- [ ] Alerta enviado ao mudar estado
- [ ] Backend retorna HTTP 200
- [ ] Tipo de alerta correto (usage_started/stopped)

**Verificar no backend**:
```bash
curl http://localhost:8080/api/v1/alerts?device_id=ESP32-WROOM32-001 \
  -H "Authorization: Bearer $TOKEN"
```

---

### Fase 6: Testes de OTA 🔄

#### 6.1 Teste de Verificação de Atualização

**Objetivo**: Verificar se dispositivo consulta atualizações

**Resultado esperado** (a cada 1 hora ou forçado):
```
🔍 Verificando atualizações disponíveis...
📥 Resposta do servidor: {"update_available":false}
✅ Firmware já está atualizado
```

**Critérios de Sucesso**:
- [ ] Consulta endpoint correto
- [ ] Envia versão atual
- [ ] Processa resposta corretamente

---

#### 6.2 Teste de Atualização OTA (Simulado)

**Objetivo**: Testar fluxo completo de atualização

**Pré-requisitos**:
- Backend com endpoint OTA implementado
- Firmware v1.1.0 disponível

**Procedimento**:
1. Publicar atualização no backend
2. Forçar verificação no dispositivo
3. Observar download e instalação
4. Verificar reinício e nova versão

**Resultado esperado**:
```
🔍 Verificando atualizações disponíveis...
🆕 Atualização disponível!
📦 Nova versão: 1.1.0
📏 Tamanho: 45,187 bytes
🔄 Tipo: Delta Patch

📥 Baixando firmware: 45187 bytes
📦 Instalando atualização...
📊 Progresso: 10%
📊 Progresso: 20%
...
📊 Progresso: 100%
✅ Atualização instalada com sucesso!
🔄 Reiniciando em 5 segundos...

[Após reinício]
=== OrthoTrack ESP32 Firmware v3.0 ===
📦 Versão atual do firmware: 1.1.0
```

**Critérios de Sucesso**:
- [ ] Download completo sem erros
- [ ] Instalação bem-sucedida
- [ ] Reinício automático
- [ ] Nova versão ativa após reinício

---

### Fase 7: Testes de Estresse 💪

#### 7.1 Teste de Estabilidade (24h)

**Objetivo**: Verificar estabilidade de longo prazo

**Procedimento**:
1. Deixar ESP32 rodando por 24 horas
2. Monitorar logs periodicamente
3. Verificar memória e uptime

**Critérios de Sucesso**:
- [ ] Sem crashes ou resets
- [ ] Sem memory leaks
- [ ] WiFi mantém conexão
- [ ] Telemetria contínua

---

#### 7.2 Teste de Reconexão WiFi

**Objetivo**: Verificar reconexão automática

**Procedimento**:
1. Desligar roteador WiFi
2. Aguardar 1 minuto
3. Ligar roteador
4. Verificar reconexão

**Resultado esperado**:
```
❌ WiFi desconectado
Conectando WiFi...........
✅ Conectado!
IP: 192.168.1.100
```

**Critérios de Sucesso**:
- [ ] Detecta desconexão
- [ ] Tenta reconectar automaticamente
- [ ] Reconecta com sucesso
- [ ] Retoma operação normal

---

#### 7.3 Teste de Bateria Baixa

**Objetivo**: Verificar alerta de bateria baixa

**Procedimento**:
1. Descarregar bateria até <20%
2. Verificar envio de alerta

**Resultado esperado**:
```
🔋 Bateria: 18%
⚠️  Bateria baixa detectada
🚨 Alerta de bateria baixa enviado
```

**Critérios de Sucesso**:
- [ ] Detecta bateria baixa (<20%)
- [ ] Envia alerta ao backend
- [ ] Alerta enviado apenas uma vez

---

## 📊 Relatório de Testes

### Template de Relatório

```markdown
# Relatório de Testes - ESP32 OrthoTrack Firmware

**Data**: 2024-12-07
**Versão do Firmware**: 1.0.0
**Testador**: [Nome]
**Hardware**: ESP32-WROOM-32 + MPU6050 + BMP280

## Resultados

### Fase 1: Hardware
- [x] 1.1 Teste I2C: ✅ PASSOU
- [x] 1.2 Inicialização: ✅ PASSOU

### Fase 2: Conectividade
- [x] 2.1 WiFi: ✅ PASSOU
- [x] 2.2 NTP: ✅ PASSOU

### Fase 3: Sensores
- [x] 3.1 MPU6050: ✅ PASSOU
- [x] 3.2 BMP280: ✅ PASSOU
- [x] 3.3 Bateria: ⚠️  PARCIAL (sem bateria)

### Fase 4: Detecção de Uso
- [x] 4.1 Algoritmo: ✅ PASSOU

### Fase 5: Backend
- [x] 5.1 Heartbeat: ✅ PASSOU
- [x] 5.2 Telemetria: ✅ PASSOU
- [x] 5.3 Alertas: ✅ PASSOU

### Fase 6: OTA
- [ ] 6.1 Verificação: ⏸️  PENDENTE (backend)
- [ ] 6.2 Atualização: ⏸️  PENDENTE (backend)

### Fase 7: Estresse
- [ ] 7.1 Estabilidade 24h: ⏸️  EM ANDAMENTO
- [x] 7.2 Reconexão: ✅ PASSOU
- [ ] 7.3 Bateria baixa: ⏸️  PENDENTE

## Observações

- Todos os testes básicos passaram
- OTA aguardando implementação do backend
- Teste de bateria requer hardware adicional

## Conclusão

✅ Firmware pronto para deployment em ambiente de desenvolvimento
⏸️  Aguardando backend para testes completos de OTA
```

---

## 🎯 Critérios de Aceitação

### Para Desenvolvimento
- [x] Todos os testes de Fase 1-5 passam
- [x] Sem erros críticos
- [x] Documentação completa

### Para Produção
- [ ] Todos os testes passam (incluindo OTA)
- [ ] Teste de estabilidade 24h completo
- [ ] Teste de bateria completo
- [ ] Backend totalmente funcional
- [ ] Testes em múltiplos dispositivos

---

## 📝 Próximos Passos

Após completar todos os testes:

1. ✅ Documentar resultados
2. ✅ Corrigir bugs encontrados
3. ✅ Implementar melhorias identificadas
4. ⏸️  Aguardar implementação do backend OTA
5. ⏸️  Realizar testes de integração completos
6. ⏸️  Preparar para deployment em produção

---

**Última atualização**: 2024-12-07
