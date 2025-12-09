# Exemplos de Uso do Sistema OTA

## 📝 Cenários Práticos

### Cenário 1: Primeira Release (v1.0.0)

```bash
# 1. Compilar firmware inicial
cd esp32-firmware
pio run

# 2. Copiar para diretório de releases
mkdir releases
cp .pio/build/esp32dev/firmware.bin releases/firmware_v1.0.0.bin

# 3. Fazer upload para dispositivos via USB
pio run --target upload

# 4. Verificar no serial monitor
pio device monitor
```

**Saída esperada:**
```
=== OrthoTrack ESP32 Firmware v3.0 ===
🔄 OTA Updater inicializado
📦 Versão atual do firmware: 1.0.0
🗂️  Partição em execução: app0
...
```

### Cenário 2: Atualização para v1.1.0 (Bug Fix)

```bash
# 1. Fazer mudanças no código
# 2. Atualizar versão em src/ota_update.h
#    #define FIRMWARE_VERSION "1.1.0"

# 3. Executar script de release
cd esp32-firmware
python tools/release.ps1 1.0.0 1.1.0

# Ou manualmente:
# 3a. Compilar
pio run

# 3b. Criar patch
python tools/create_delta_patch.py \
  --chip esp32 \
  --base releases/firmware_v1.0.0.bin \
  --new .pio/build/esp32dev/firmware.bin \
  --output releases/patch_v1.0.0_to_v1.1.0.bin

# 4. Upload para backend
curl -X POST http://localhost:8080/api/v1/firmware/upload \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "file=@releases/patch_v1.0.0_to_v1.1.0.bin" \
  -F "version=1.1.0" \
  -F "from_version=1.0.0" \
  -F "is_delta=true" \
  -F "hardware=ESP32-WROOM-32"

# 5. Publicar atualização (10% rollout)
curl -X POST http://localhost:8080/api/v1/firmware/publish \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.1.0",
    "hardware": "ESP32-WROOM-32",
    "rollout_percentage": 10
  }'
```

**No dispositivo (após 1 hora ou comando manual):**
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

### Cenário 3: Atualização Major (v2.0.0)

```bash
# 1. Grandes mudanças no código
# 2. Atualizar versão para 2.0.0

# 3. Criar patch delta
python tools/create_delta_patch.py \
  --chip esp32 \
  --base releases/firmware_v1.1.0.bin \
  --new .pio/build/esp32dev/firmware.bin \
  --output releases/patch_v1.1.0_to_v2.0.0.bin

# 4. Também criar firmware completo (para novos dispositivos)
python tools/create_delta_patch.py \
  --chip esp32 \
  --full .pio/build/esp32dev/firmware.bin \
  --output releases/firmware_v2.0.0_packaged.bin

# 5. Upload de ambos
# Patch para dispositivos existentes
curl -X POST http://localhost:8080/api/v1/firmware/upload \
  -F "file=@releases/patch_v1.1.0_to_v2.0.0.bin" \
  -F "version=2.0.0" \
  -F "from_version=1.1.0" \
  -F "is_delta=true"

# Firmware completo para novos dispositivos
curl -X POST http://localhost:8080/api/v1/firmware/upload \
  -F "file=@releases/firmware_v2.0.0_packaged.bin" \
  -F "version=2.0.0" \
  -F "is_delta=false"
```

### Cenário 4: Rollout Gradual

```bash
# Fase 1: Canary (10%)
curl -X POST http://localhost:8080/api/v1/firmware/publish \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.1.0",
    "rollout_percentage": 10
  }'

# Aguardar 24h, monitorar métricas

# Fase 2: Expandir (50%)
curl -X PATCH http://localhost:8080/api/v1/firmware/rollout/1.1.0 \
  -H "Content-Type: application/json" \
  -d '{"rollout_percentage": 50}'

# Aguardar 24h

# Fase 3: Full rollout (100%)
curl -X PATCH http://localhost:8080/api/v1/firmware/rollout/1.1.0 \
  -H "Content-Type: application/json" \
  -d '{"rollout_percentage": 100}'
```

### Cenário 5: Forçar Atualização em Dispositivo Específico

```bash
# Via comando HTTP
curl -X POST http://localhost:8080/api/v1/braces/ESP32-001/commands \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "command_type": "check_update",
    "priority": "high"
  }'
```

**No dispositivo:**
```
📥 Comando recebido: check_update
🔍 Verificação manual de atualização solicitada
🔍 Verificando atualizações disponíveis...
```

### Cenário 6: Rollback para Versão Anterior

```bash
# 1. Marcar versão anterior como ativa
curl -X POST http://localhost:8080/api/v1/firmware/publish \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.0.0",
    "rollout_percentage": 100,
    "force": true
  }'

# 2. Dispositivos receberão "downgrade" na próxima verificação
# 3. Criar patch reverso se necessário
python tools/create_delta_patch.py \
  --chip esp32 \
  --base releases/firmware_v1.1.0.bin \
  --new releases/firmware_v1.0.0.bin \
  --output releases/patch_v1.1.0_to_v1.0.0.bin
```

### Cenário 7: Atualização de Emergência

```bash
# 1. Criar patch de emergência
python tools/create_delta_patch.py \
  --chip esp32 \
  --base releases/firmware_v1.1.0.bin \
  --new releases/firmware_v1.1.1_hotfix.bin \
  --output releases/patch_v1.1.0_to_v1.1.1.bin

# 2. Upload com prioridade alta
curl -X POST http://localhost:8080/api/v1/firmware/upload \
  -F "file=@releases/patch_v1.1.0_to_v1.1.1.bin" \
  -F "version=1.1.1" \
  -F "from_version=1.1.0" \
  -F "is_delta=true" \
  -F "priority=critical"

# 3. Publicar imediatamente para todos
curl -X POST http://localhost:8080/api/v1/firmware/publish \
  -H "Content-Type: application/json" \
  -d '{
    "version": "1.1.1",
    "rollout_percentage": 100,
    "force_immediate": true
  }'

# 4. Forçar verificação em todos os dispositivos
curl -X POST http://localhost:8080/api/v1/firmware/force-check-all \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Cenário 8: Monitoramento de Atualização

```bash
# Ver status de atualização de um dispositivo
curl http://localhost:8080/api/v1/braces/ESP32-001/firmware-status \
  -H "Authorization: Bearer $TOKEN"
```

**Response:**
```json
{
  "device_id": "ESP32-001",
  "current_version": "1.0.0",
  "target_version": "1.1.0",
  "update_status": "downloading",
  "progress": 45,
  "last_check": "2024-12-07T10:30:00Z",
  "last_update": "2024-12-01T08:00:00Z"
}
```

```bash
# Ver estatísticas de rollout
curl http://localhost:8080/api/v1/firmware/rollout-stats/1.1.0 \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

**Response:**
```json
{
  "version": "1.1.0",
  "total_devices": 100,
  "updated_devices": 45,
  "pending_devices": 55,
  "failed_devices": 0,
  "success_rate": 100.0,
  "average_download_time": "12.5s",
  "average_install_time": "8.2s"
}
```

### Cenário 9: Teste Local (Sem Backend)

```bash
# 1. Criar servidor HTTP simples
cd esp32-firmware/releases
python -m http.server 8080

# 2. Criar arquivo JSON de resposta
cat > check-update.json << EOF
{
  "update_available": true,
  "version": "1.1.0",
  "url": "http://192.168.1.100:8080/firmware_v1.1.0.bin",
  "size": 980234,
  "checksum": "1a2b3c4d5e6f7g8h9i0j",
  "is_delta": false
}
EOF

# 3. Modificar firmware para apontar para servidor local
# Em platformio.ini:
# -DAPI_ENDPOINT=\"http://192.168.1.100:8080\"

# 4. Compilar e fazer upload
pio run --target upload

# 5. Monitorar
pio device monitor
```

### Cenário 10: Debugging de Atualização Falhada

```bash
# 1. Verificar logs do dispositivo
pio device monitor

# Procurar por:
# ❌ Erro ao baixar firmware: HTTP 404
# ❌ Checksum inválido
# ❌ Não há espaço suficiente para OTA

# 2. Verificar logs do backend
curl http://localhost:8080/api/v1/logs/firmware-updates \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  | grep "ESP32-001"

# 3. Verificar integridade do arquivo
md5sum releases/patch_v1.0.0_to_v1.1.0.bin

# 4. Re-gerar patch se necessário
python tools/create_delta_patch.py \
  --chip esp32 \
  --base releases/firmware_v1.0.0.bin \
  --new releases/firmware_v1.1.0.bin \
  --output releases/patch_v1.0.0_to_v1.1.0_new.bin

# 5. Comparar checksums
md5sum releases/patch_v1.0.0_to_v1.1.0*.bin
```

## 🔧 Comandos Úteis

### Verificar Versão Atual do Dispositivo

```bash
# Via API
curl http://localhost:8080/api/v1/braces/ESP32-001 \
  -H "Authorization: Bearer $TOKEN" \
  | jq '.firmware_version'
```

### Listar Todas as Versões Disponíveis

```bash
curl http://localhost:8080/api/v1/firmware/versions \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### Calcular Estatísticas de Patch

```bash
# Tamanho dos arquivos
ls -lh releases/

# Economia percentual
python -c "
base = $(stat -c%s releases/firmware_v1.0.0.bin)
patch = $(stat -c%s releases/patch_v1.0.0_to_v1.1.0.bin)
print(f'Economia: {100 - (patch * 100 / base):.1f}%')
"
```

### Validar Patch Antes de Upload

```bash
# Verificar magic number
xxd -l 4 releases/patch_v1.0.0_to_v1.1.0.bin
# Deve mostrar: 10 de cd fc (ESP_DELTA_OTA_MAGIC em little-endian)

# Verificar hash de validação
xxd -s 4 -l 32 releases/patch_v1.0.0_to_v1.1.0.bin
```

## 📊 Métricas e Monitoramento

### Dashboard de Atualizações

```sql
-- Dispositivos por versão
SELECT firmware_version, COUNT(*) as count
FROM braces
GROUP BY firmware_version
ORDER BY firmware_version DESC;

-- Taxa de sucesso nas últimas 24h
SELECT 
  COUNT(CASE WHEN status = 'success' THEN 1 END) * 100.0 / COUNT(*) as success_rate,
  COUNT(*) as total_updates
FROM firmware_update_logs
WHERE created_at > NOW() - INTERVAL '24 hours';

-- Tempo médio de atualização
SELECT 
  AVG(EXTRACT(EPOCH FROM (completed_at - started_at))) as avg_seconds
FROM firmware_update_logs
WHERE status = 'success'
  AND created_at > NOW() - INTERVAL '7 days';
```

## 🎯 Melhores Práticas

1. **Sempre testar em dispositivo de desenvolvimento primeiro**
2. **Usar rollout gradual para atualizações importantes**
3. **Manter histórico de firmwares para rollback**
4. **Documentar mudanças no CHANGELOG.md**
5. **Validar checksums antes de publicar**
6. **Monitorar métricas de sucesso/falha**
7. **Ter plano de rollback preparado**
8. **Notificar usuários sobre atualizações críticas**
9. **Fazer backup antes de atualizações major**
10. **Testar conectividade antes de iniciar rollout**
