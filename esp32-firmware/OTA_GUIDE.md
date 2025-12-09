# Guia de Atualização OTA (Over-The-Air)

## 📋 Visão Geral

O sistema OTA do OrthoTrack permite atualizar o firmware dos dispositivos ESP32 remotamente, sem necessidade de conexão física. Suporta dois modos:

1. **Delta OTA**: Envia apenas as diferenças entre versões (patch menor, mais rápido)
2. **Full OTA**: Envia o firmware completo (mais confiável, maior tamanho)

### Metodologia

Baseado no [DeltaOtaPatchCreatorELT](https://github.com/alexabreup/DeltaOtaPacthCreatorELT) e [ESP Delta OTA da Espressif](https://github.com/espressif/idf-extra-components/tree/master/esp_delta_ota).

## 🔧 Pré-requisitos

### Software

- Python 3.7+
- PlatformIO
- Dependências Python (instalar com `pip install -r tools/requirements.txt`):
  - esptool >= 4.5.1
  - detools >= 0.54.0
  - pyserial >= 3.5

### Hardware

- ESP32-WROOM-32 com partição OTA configurada
- Conexão WiFi estável
- Backend OrthoTrack acessível

## 🚀 Workflow de Atualização

### 1. Preparação

```bash
# Instalar dependências Python
cd esp32-firmware/tools
pip install -r requirements.txt
```

### 2. Compilar Nova Versão

```bash
# Atualizar versão em src/ota_update.h
# Alterar: #define FIRMWARE_VERSION "1.0.0" para "1.1.0"

# Compilar
cd esp32-firmware
pio run

# O binário estará em: .pio/build/esp32dev/firmware.bin
```

### 3. Criar Patch Delta

```bash
# Criar patch entre versão antiga e nova
python tools/create_delta_patch.py \
  --chip esp32 \
  --base firmware_v1.0.0.bin \
  --new .pio/build/esp32dev/firmware.bin \
  --output patch_v1.0.0_to_v1.1.0.bin
```

**Saída esperada:**
```
🔍 Verificando dependências...
✅ esptool: 4.5.1
✅ detools: 0.54.0

============================================================
🔄 Criando Delta OTA Patch
============================================================

📝 Extraindo hash do firmware base...
✅ Hash de validação: a1b2c3d4e5f6...

📦 Gerando patch delta...

📊 Estatísticas:
   Firmware base:  975,509 bytes
   Firmware novo:  980,234 bytes
   Patch delta:    45,123 bytes
   Economia:       95.4%

📝 Adicionando header Delta OTA...

✅ Patch criado com sucesso!
📁 Arquivo: patch_v1.0.0_to_v1.1.0.bin
📏 Tamanho: 45,187 bytes
🔐 MD5: 1a2b3c4d5e6f7g8h9i0j...
```

### 4. Criar Firmware Completo (Alternativa)

```bash
# Para dispositivos que não suportam delta ou como fallback
python tools/create_delta_patch.py \
  --chip esp32 \
  --full .pio/build/esp32dev/firmware.bin \
  --output firmware_v1.1.0_packaged.bin
```

### 5. Upload para Backend

```bash
# Upload do patch delta
curl -X POST http://localhost:8080/api/v1/firmware/upload \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@patch_v1.0.0_to_v1.1.0.bin" \
  -F "version=1.1.0" \
  -F "from_version=1.0.0" \
  -F "is_delta=true" \
  -F "hardware=ESP32-WROOM-32"

# Upload do firmware completo (fallback)
curl -X POST http://localhost:8080/api/v1/firmware/upload \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -F "file=@firmware_v1.1.0_packaged.bin" \
  -F "version=1.1.0" \
  -F "is_delta=false" \
  -F "hardware=ESP32-WROOM-32"
```

### 6. Publicar Atualização

```bash
# Marcar versão como disponível para dispositivos
curl -X POST http://localhost:8080/api/v1/firmware/publish \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.1.0",
    "hardware": "ESP32-WROOM-32",
    "rollout_percentage": 10
  }'
```

## 📡 Processo no Dispositivo

### Verificação Automática

O ESP32 verifica atualizações automaticamente a cada 1 hora:

```cpp
#define OTA_CHECK_INTERVAL 3600000  // 1 hora em ms
```

### Verificação Manual

Você pode forçar uma verificação via comando MQTT ou HTTP:

```bash
# Via HTTP
curl -X POST http://localhost:8080/api/v1/braces/ESP32-001/commands \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "command_type": "check_update",
    "priority": "high"
  }'
```

### Fluxo de Atualização

1. **Verificação**: ESP32 consulta `/api/v1/firmware/check-update`
2. **Download**: Se disponível, baixa o patch/firmware
3. **Instalação**: Aplica a atualização na partição OTA
4. **Verificação**: Valida checksum e integridade
5. **Reinício**: Reinicia com novo firmware
6. **Confirmação**: Envia status ao backend

### Logs no Serial Monitor

```
🔍 Verificando atualizações disponíveis...
📥 Resposta do servidor: {"update_available":true,...}
🆕 Atualização disponível!
📦 Nova versão: 1.1.0
📏 Tamanho: 45,187 bytes
🔐 Checksum: 1a2b3c4d5e6f...
🔄 Tipo: Delta Patch

📦 Iniciando atualização de firmware completo...
📥 Baixando firmware: 45187 bytes
📦 Instalando atualização...
📊 Progresso: 10%
📊 Progresso: 20%
...
📊 Progresso: 100%
✅ Atualização instalada com sucesso!
📦 Versão instalada: 1.1.0
🔄 Reiniciando em 5 segundos...
```

## 🔐 Segurança

### Validação de Firmware

- **Checksum MD5**: Verificado antes da instalação
- **Validation Hash**: Hash do firmware base no header do patch
- **Assinatura Digital**: (Recomendado para produção)

### Rollback Automático

O ESP32 possui sistema de rollback automático:
- Se o novo firmware falhar ao iniciar 3 vezes
- Automaticamente volta para a versão anterior
- Requer configuração de `esp_ota_mark_app_valid_cancel_rollback()`

### Autenticação

- API Key obrigatória para verificar/baixar atualizações
- Backend valida permissões do dispositivo
- HTTPS recomendado para produção

## 📊 Monitoramento

### Status no Backend

O backend rastreia:
- Versão atual de cada dispositivo
- Status de atualização (pending, downloading, installing, success, failed)
- Histórico de atualizações
- Taxa de sucesso/falha

### Métricas

```sql
-- Dispositivos por versão
SELECT firmware_version, COUNT(*) 
FROM braces 
GROUP BY firmware_version;

-- Taxa de sucesso de atualizações
SELECT 
  COUNT(CASE WHEN status = 'success' THEN 1 END) * 100.0 / COUNT(*) as success_rate
FROM firmware_updates
WHERE created_at > NOW() - INTERVAL '7 days';
```

## 🐛 Troubleshooting

### Atualização Falha

**Problema**: "Não há espaço suficiente para OTA"
- **Solução**: Verificar partição OTA no `platformio.ini`
- Usar `board_build.partitions = huge_app.csv`

**Problema**: "Erro ao escrever firmware"
- **Solução**: Verificar conexão WiFi estável
- Aumentar timeout de download
- Tentar novamente

**Problema**: "Checksum inválido"
- **Solução**: Re-gerar patch
- Verificar integridade do arquivo no servidor
- Limpar cache do backend

### Delta Patch Não Funciona

**Problema**: "Delta OTA não implementado no Arduino Framework"
- **Causa**: Arduino não suporta nativamente esp_delta_ota
- **Solução**: Sistema faz fallback automático para firmware completo
- **Alternativa**: Migrar para ESP-IDF para suporte completo a delta

### Dispositivo Não Verifica Atualizações

**Problema**: Dispositivo não consulta servidor
- **Solução**: 
  - Verificar conectividade WiFi
  - Verificar endpoint da API está correto
  - Verificar API Key é válida
  - Forçar verificação manual

## 🔄 Rollout Gradual

### Estratégia de Implantação

1. **Canary (10%)**: Liberar para 10% dos dispositivos
2. **Monitorar**: Aguardar 24h, verificar métricas
3. **Expandir (50%)**: Se estável, liberar para 50%
4. **Monitorar**: Aguardar 24h
5. **Full (100%)**: Liberar para todos

### Configuração no Backend

```json
{
  "version": "1.1.0",
  "rollout_percentage": 10,
  "target_devices": ["ESP32-001", "ESP32-002"],
  "exclude_devices": [],
  "auto_rollback": true
}
```

## 📚 Referências

- [ESP Delta OTA - Espressif](https://github.com/espressif/idf-extra-components/tree/master/esp_delta_ota)
- [DeltaOtaPatchCreatorELT](https://github.com/alexabreup/DeltaOtaPacthCreatorELT)
- [ESP32 OTA Updates - ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/system/ota.html)
- [detools - Binary Delta Encoding](https://github.com/eerimoq/detools)

## 🎯 Melhores Práticas

1. **Sempre testar** atualizações em dispositivo de desenvolvimento primeiro
2. **Manter histórico** de firmwares para rollback
3. **Monitorar métricas** de sucesso/falha
4. **Usar rollout gradual** para atualizações críticas
5. **Documentar mudanças** em cada versão (changelog)
6. **Validar checksums** antes de publicar
7. **Ter plano de rollback** para emergências
8. **Testar conectividade** antes de iniciar atualização
9. **Notificar usuários** sobre atualizações importantes
10. **Manter logs** detalhados de todas as atualizações

## 📝 Changelog

### v1.1.0 (Exemplo)
- ✨ Adicionado suporte a OTA Delta
- 🐛 Corrigido bug de reconexão WiFi
- ⚡ Melhorado desempenho de leitura de sensores
- 📝 Atualizada documentação

### v1.0.0
- 🎉 Versão inicial
- ✅ Suporte a MPU6050 e BMP280
- ✅ Telemetria e heartbeat
- ✅ Detecção de uso do colete
