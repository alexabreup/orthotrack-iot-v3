# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [Unreleased]

### Added
- **Sensor de Toque TTP223**: Integração do sensor de toque capacitivo TTP223-HA6 para detecção precisa de uso do colete
  - Conexão no GPIO4 do ESP32
  - Detecção de contato com a pele do paciente
  - Debouncing de 500ms para evitar falsos positivos
  - Algoritmo de detecção de uso aprimorado com toque como indicador primário
- Documentação completa do TTP223 em `TTP223_SETUP.md`
- Teste dedicado para o sensor de toque em `test/ttp223_test.cpp`
- Ambiente de teste `ttp223_test` no platformio.ini

### Changed
- Algoritmo de detecção de uso agora usa sensor de toque como indicador primário
- Estrutura `SensorData` agora inclui campo `touchDetected`
- Telemetria JSON agora inclui estado do sensor de toque
- Requisito 5 atualizado para incluir detecção baseada em toque
- Requisito 6 atualizado para incluir `touch_detected` na telemetria

### Improved
- Detecção de uso mais confiável com sensor de toque capacitivo
- Redução de falsos positivos na detecção de uso
- Melhor diferenciação entre colete em uso e colete guardado

### Planejado
- Suporte completo a ESP Delta OTA no ESP-IDF
- Assinatura digital de firmwares
- Rollback automático em caso de falha
- Compressão adicional com LZMA

## [1.0.0] - 2024-12-07

### Adicionado
- ✨ Sistema OTA (Over-The-Air) completo
  - Verificação automática de atualizações a cada 1 hora
  - Suporte a Delta Patches (economia de ~95% de banda)
  - Suporte a firmware completo (fallback)
  - Validação de checksum MD5
  - Script Python para criação de patches
  - Documentação completa (OTA_GUIDE.md)
- ✅ Leitura de sensores MPU6050 (acelerômetro + giroscópio)
- ✅ Leitura de sensor BMP280 (temperatura + pressão)
- ✅ Detecção inteligente de uso do colete
  - Algoritmo baseado em temperatura corporal (30-40°C)
  - Detecção de movimento (threshold: 1.0 m/s²)
  - Filtro de 5 leituras consecutivas
- ✅ Envio de telemetria a cada 5 segundos
  - Dados de acelerômetro e giroscópio
  - Temperatura e pressão
  - Nível de bateria
  - Estado de uso (isWearing)
- ✅ Heartbeat a cada 30 segundos
  - Status online/offline
  - Força do sinal WiFi (RSSI)
  - Nível de bateria
- ✅ Monitoramento de bateria
  - Leitura via ADC (GPIO35)
  - Cálculo de percentual (3.0V-4.2V)
  - Alerta de bateria baixa (<20%)
- ✅ Alertas de mudança de estado
  - Notificação quando paciente começa a usar
  - Notificação quando paciente para de usar
- ✅ Sincronização de tempo via NTP
  - Servidor: pool.ntp.org
  - Timezone: UTC-3 (Brasil)
- ✅ Conexão WiFi automática com reconexão
  - Retry automático em caso de falha
  - Reconexão automática se perder conexão
- ✅ Configuração via build flags
  - WiFi SSID e password
  - API endpoint e credenciais
  - Device ID único
- ✅ Documentação completa
  - README.md com guia de uso
  - CONFIG.md com detalhes de configuração
  - OTA_GUIDE.md com guia de atualizações
  - DEPLOYMENT_STATUS.md com checklist

### Técnico
- Framework: Arduino para ESP32
- Plataforma: ESP32-WROOM-32
- Bibliotecas:
  - Adafruit MPU6050 @ 2.2.6
  - Adafruit BMP280 Library @ 2.6.8
  - PubSubClient @ 2.8.0
  - ArduinoJson @ 6.21.5
  - NTPClient @ 3.2.1
- Partição: huge_app.csv (suporte a OTA)
- Uso de RAM: 14.6% (47,984 bytes)
- Uso de Flash: 31.0% (975,509 bytes)

### Segurança
- Autenticação via API Key (X-Device-API-Key header)
- Validação de checksum em atualizações OTA
- Credenciais configuráveis via build flags

### Conhecido
- Delta OTA não funciona no Arduino Framework (usa fallback para firmware completo)
- Para suporte completo a Delta OTA, migrar para ESP-IDF
- Credenciais hardcoded no firmware (adequado para desenvolvimento)

## Formato de Versão

- **MAJOR**: Mudanças incompatíveis na API
- **MINOR**: Novas funcionalidades compatíveis
- **PATCH**: Correções de bugs compatíveis

## Tipos de Mudanças

- `Adicionado` para novas funcionalidades
- `Modificado` para mudanças em funcionalidades existentes
- `Descontinuado` para funcionalidades que serão removidas
- `Removido` para funcionalidades removidas
- `Corrigido` para correções de bugs
- `Segurança` para vulnerabilidades corrigidas
- `Técnico` para mudanças técnicas internas
- `Conhecido` para problemas conhecidos

[Unreleased]: https://github.com/orthotrack/firmware/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/orthotrack/firmware/releases/tag/v1.0.0
