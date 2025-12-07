📋 Plano de Instalação Completa - OrthoTrack IoT v3

  🔍 Análise do Estado Atual

  Containers existentes no servidor:
  - orthotrack-postgres (PostgreSQL 15) - ✅ Funcionando
  - orthotrack-test (Nginx) - ✅ Funcionando

  Infraestrutura disponível:
  - Docker instalado e funcional
  - Rede orthotrack_orthotrack-network configurada
  - Volume orthotrack_postgres_data com dados persistentes

  ---
  🎯 Plano de Instalação Completo

  Fase 1: Preparação do Ambiente

  1. Backup dos dados existentes
  docker exec orthotrack-postgres pg_dump -U postgres orthotrack
   > backup_orthotrack_$(date +%Y%m%d).sql
  2. Transferir código para o servidor
  # No servidor local
  rsync -avz --progress backend/
  root@72.60.50.248:~/orthotrack-iot-v3/backend/
  3. Configurar variáveis de ambiente
  # Criar arquivo .env no servidor
  cat > ~/orthotrack-iot-v3/backend/.env << 'EOF'
  DB_DATABASE=orthotrack
  DB_USERNAME=postgres
  DB_PASSWORD=postgres
  REDIS_PASSWORD=redis123
  MQTT_USERNAME=orthotrack
  MQTT_PASSWORD=mqtt123
  JWT_SECRET=your-super-secret-jwt-key-change-in-production
  GIN_MODE=release
  IOT_ALERT_BATTERY_LOW=20
  IOT_ALERT_TEMP_HIGH=45.0
  IOT_ALERT_TEMP_LOW=5.0
  EOF

  Fase 2: Parada Controlada dos Serviços

  # Parar containers de teste
  docker stop orthotrack-test
  docker rm orthotrack-test

  # Manter postgres rodando para evitar perda de dados

  Fase 3: Instalação dos Novos Serviços

  1. Build da aplicação Backend
  cd ~/orthotrack-iot-v3/backend
  docker build -t orthotrack-backend:latest .
  2. Deploy dos serviços completos
  # Usar o docker-compose.yml completo
  docker-compose -f docker-compose.yml up -d

  Fase 4: Configuração dos Novos Serviços

  1. Redis Cache & Pub/Sub
    - Container: orthotrack-redis
    - Porta: 6379
    - Configuração: Persistência habilitada + senha
  2. MQTT Broker (Mosquitto)
    - Container: orthotrack-mqtt
    - Portas: 1883 (MQTT), 9001 (WebSocket)
    - Configuração: arquivo mosquitto.conf
  3. Backend API (Go)
    - Container: orthotrack-backend
    - Porta: 8080
    - Health check configurado

  Fase 5: Configuração do Proxy Reverso (Opcional)

  # Configurar Nginx como proxy reverso
  cat > nginx.conf << 'EOF'
  upstream backend {
      server localhost:8080;
  }

  server {
      listen 80;
      server_name _;

      location /api/ {
          proxy_pass http://backend;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
      }
  }
  EOF

  Fase 6: Verificação e Testes

  # Verificar status dos containers
  docker ps

  # Testar conectividade
  curl http://localhost:8080/health
  curl http://localhost:8080/api/v1/ping

  # Verificar logs
  docker logs orthotrack-backend
  docker logs orthotrack-mqtt
  docker logs orthotrack-redis

  Fase 7: Configuração de Produção

  1. Firewall e Segurança
  # Configurar iptables para portas necessárias
  ufw allow 8080/tcp    # Backend API
  ufw allow 1883/tcp    # MQTT
  ufw allow 5432/tcp    # PostgreSQL (se necessário externo)
  2. Monitoramento
  # Script de monitoramento
  cat > monitor-services.sh << 'EOF'
  #!/bin/bash
  echo "=== Status dos Serviços OrthoTrack ==="
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  echo ""
  echo "=== Health Checks ==="
  curl -s http://localhost:8080/health || echo "Backend: 
  OFFLINE"
  EOF
  chmod +x monitor-services.sh

  Fase 8: Documentação de Migração

  # Comando para rollback se necessário
  cat > rollback.sh << 'EOF'
  #!/bin/bash
  docker-compose down
  docker run -d --name orthotrack-test -p 8080:80 nginx:alpine
  echo "Rollback concluído - teste nginx restaurado"
  EOF

  ---
  🚀 Comandos de Execução Resumidos

  # 1. Transferir arquivos
  rsync -avz backend/
  root@72.60.50.248:~/orthotrack-iot-v3/backend/

  # 2. No servidor
  cd ~/orthotrack-iot-v3/backend
  docker stop orthotrack-test && docker rm orthotrack-test

  # 3. Deploy completo
  docker-compose up -d

  # 4. Verificar
  docker ps && curl http://localhost:8080/health

  ---
  📊 Arquitetura Final

  ┌─────────────────────┐    ┌─────────────────────┐
  │   Frontend Web      │    │   Android Edge      │
  │   (Frontend)        │    │   Node (Capacitor)  │
  └─────────┬───────────┘    └─────────┬───────────┘
            │                          │
            │ HTTP/REST                │ HTTP/REST
            │                          │
  ┌─────────▼──────────────────────────▼───────────┐
  │         Backend API (Go/Gin)                   │
  │         Container: orthotrack-backend          │
  │         Porta: 8080                            │
  └─┬─────────────┬─────────────────┬─────────────┬┘
    │             │                 │             │
    │ SQL         │ Cache/PubSub    │ MQTT        │ Logs
    │             │                 │             │
  ┌─▼───────┐   ┌─▼──────────┐    ┌─▼─────────┐ ┌─▼──────────┐
  │PostgreSQL│   │   Redis    │    │ Mosquitto │ │ File/Syslog│
  │postgres  │   │   redis    │    │   mqtt    │ │  Logging   │
  │:5432     │   │   :6379    │    │   :1883   │ │            │
  └──────────┘   └────────────┘    └───────────┘ └────────────┘

● O plano está pronto! Atualmente você tem apenas PostgreSQL e
  um container de teste Nginx. Para implementação completa, será
   necessário adicionar Redis, MQTT (Mosquitto) e o backend Go.
  O plano preserva seus dados PostgreSQL existentes e oferece
  rollback seguro.

> escreva um prompt para implementar os servicos

● # 🚀 PROMPT PARA IMPLEMENTAÇÃO DOS SERVIÇOS ORTHOTRACK IOT V3

  # Execute estes comandos em sequência para implementar a 
  instalação completa:

  # 1. PREPARAÇÃO - Backup e preparação do ambiente
  ssh root@72.60.50.248 "
  # Fazer backup do banco atual
  docker exec orthotrack-postgres pg_dump -U postgres orthotrack
   > /root/backup_orthotrack_$(date +%Y%m%d_%H%M).sql

  # Verificar espaço em disco
  df -h

  # Criar diretório de trabalho
  mkdir -p /opt/orthotrack-v3
  "

  # 2. TRANSFERÊNCIA DE ARQUIVOS - Enviar código para o servidor
  rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude '.git' \
    --exclude 'dist' \

  /home/alxp/Desktop/alexp/iot-golang/orthotrack-iot-v3/backend/
   \
    root@72.60.50.248:/opt/orthotrack-v3/

  # 3. CONFIGURAÇÃO DO AMBIENTE - Criar arquivo .env no servidor
  ssh root@72.60.50.248 "
  cd /opt/orthotrack-v3

  # Criar arquivo de environment
  cat > .env << 'EOF'
  # Database Configuration
  DB_DATABASE=orthotrack
  DB_USERNAME=postgres
  DB_PASSWORD=postgres

  # Redis Configuration
  REDIS_PASSWORD=redis123

  # MQTT Configuration
  MQTT_USERNAME=orthotrack
  MQTT_PASSWORD=mqtt123

  # JWT Configuration
  JWT_SECRET=orthotrack-super-secret-jwt-key-production-v3-2024

  # Server Configuration
  GIN_MODE=release
  PORT=8080

  # IoT Alert Thresholds
  IOT_ALERT_BATTERY_LOW=20
  IOT_ALERT_TEMP_HIGH=45.0
  IOT_ALERT_TEMP_LOW=5.0
  EOF

  # Criar arquivo mosquitto.conf
  cat > mosquitto.conf << 'EOF'
  # Mosquitto Configuration for OrthoTrack IoT
  listener 1883
  allow_anonymous false
  password_file /mosquitto/config/passwd

  # WebSocket support
  listener 9001
  protocol websockets
  allow_anonymous false

  # Logging
  log_dest file /mosquitto/log/mosquitto.log
  log_type all
  connection_messages true

  # Persistence
  persistence true
  persistence_location /mosquitto/data/
  autosave_interval 60
  EOF
  "

  # 4. MIGRAÇÃO CONTROLADA - Parar serviços de teste
  ssh root@72.60.50.248 "
  # Parar e remover container de teste (manter PostgreSQL)
  docker stop orthotrack-test
  docker rm orthotrack-test

  # Verificar se PostgreSQL ainda está rodando
  docker ps | grep postgres
  "

  # 5. BUILD E DEPLOY - Construir e executar todos os serviços
  ssh root@72.60.50.248 "
  cd /opt/orthotrack-v3

  # Build da imagem do backend
  echo '🔨 Building backend image...'
  docker build -t orthotrack-backend:latest .

  # Deploy de todos os serviços
  echo '🚀 Starting all services...'
  docker-compose up -d

  # Aguardar inicialização
  echo '⏳ Waiting for services to start...'
  sleep 30
  "

  # 6. CONFIGURAÇÃO MQTT - Setup de usuários MQTT
  ssh root@72.60.50.248 "
  # Criar usuário MQTT
  docker exec orthotrack-mqtt mosquitto_passwd -c -b 
  /mosquitto/config/passwd orthotrack mqtt123

  # Reiniciar MQTT para aplicar configurações
  docker restart orthotrack-mqtt
  sleep 10
  "

  # 7. VERIFICAÇÃO E TESTES - Validar todos os serviços
  ssh root@72.60.50.248 "
  echo '🔍 Service Status Check:'
  echo '======================='
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

  echo ''
  echo '🏥 Health Checks:'
  echo '================'

  # Backend Health Check
  echo -n 'Backend API: '
  if curl -s http://localhost:8080/health > /dev/null; then
      echo '✅ ONLINE'
  else
      echo '❌ OFFLINE'
  fi

  # PostgreSQL Check
  echo -n 'PostgreSQL: '
  if docker exec orthotrack-postgres pg_isready -U postgres > 
  /dev/null 2>&1; then
      echo '✅ ONLINE'
  else
      echo '❌ OFFLINE'
  fi

  # Redis Check
  echo -n 'Redis: '
  if docker exec orthotrack-redis redis-cli ping > /dev/null 
  2>&1; then
      echo '✅ ONLINE'
  else
      echo '❌ OFFLINE'
  fi

  # MQTT Check
  echo -n 'MQTT Broker: '
  if docker exec orthotrack-mqtt mosquitto_sub -h localhost -t 
  test -C 1 -W 2 > /dev/null 2>&1; then
      echo '✅ ONLINE'
  else
      echo '❌ OFFLINE'
  fi

  echo ''
  echo '📊 Service Logs (last 10 lines each):'
  echo '====================================='
  echo '--- Backend Logs ---'
  docker logs --tail 10 orthotrack-backend

  echo '--- MQTT Logs ---'
  docker logs --tail 10 orthotrack-mqtt

  echo '--- Redis Logs ---'
  docker logs --tail 10 orthotrack-redis
  "

  # 8. CONFIGURAÇÃO DE FIREWALL (Opcional)
  ssh root@72.60.50.248 "
  echo '🔐 Configuring firewall rules...'
  ufw allow 8080/tcp comment 'OrthoTrack Backend API'
  ufw allow 1883/tcp comment 'MQTT Broker'
  ufw allow 9001/tcp comment 'MQTT WebSocket'
  # ufw allow 6379/tcp comment 'Redis (only if external access 
  needed)'
  # ufw allow 5432/tcp comment 'PostgreSQL (only if external 
  access needed)'
  ufw status
  "

  # 9. TESTE FINAL DA API
  echo "🧪 Testing API endpoints..."
  ssh root@72.60.50.248 "
  echo 'Testing API endpoints:'
  echo '- Health check:'
  curl -s http://localhost:8080/health | head -5

  echo ''
  echo '- API version:'
  curl -s http://localhost:8080/api/v1/ping | head -5
  "

  # 10. CRIAR SCRIPT DE MONITORAMENTO
  ssh root@72.60.50.248 "
  cat > /root/monitor-orthotrack.sh << 'EOF'
  #!/bin/bash
  echo '=== OrthoTrack IoT v3 - Service Monitor ==='
  echo 'Timestamp: $(date)'
  echo ''

  echo 'Container Status:'
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
   --filter 'name=orthotrack'

  echo ''
  echo 'Health Checks:'
  services=('backend:8080/health' 'postgres:5432' 'redis:6379' 
  'mqtt:1883')
  for service in \${services[@]}; do
      name=\${service%:*}
      echo -n \"  \$name: \"
      case \$name in
          backend) curl -s http://localhost:8080/health 
  >/dev/null && echo '✅' || echo '❌' ;;
          postgres) docker exec orthotrack-postgres pg_isready 
  -U postgres >/dev/null 2>&1 && echo '✅' || echo '❌' ;;
          redis) docker exec orthotrack-redis redis-cli ping 
  >/dev/null 2>&1 && echo '✅' || echo '❌' ;;
          mqtt) docker exec orthotrack-mqtt mosquitto_sub -h 
  localhost -t test -C 1 -W 2 >/dev/null 2>&1 && echo '✅' || 
  echo '❌' ;;
      esac
  done

  echo ''
  echo 'Disk Usage:'
  df -h | grep -E '(Filesystem|/dev/)'
  EOF

  chmod +x /root/monitor-orthotrack.sh
  echo '✅ Monitor script created at 
  /root/monitor-orthotrack.sh'
  "

  # 🎉 IMPLEMENTAÇÃO CONCLUÍDA!
  echo ""
  echo "🎉 IMPLEMENTAÇÃO DOS SERVIÇOS CONCLUÍDA!"
  echo ""
  echo "📋 Próximos Passos:"
  echo "1. Execute: ssh root@72.60.50.248 
  '/root/monitor-orthotrack.sh' para monitorar"
  echo "2. Acesse a API em: http://72.60.50.248:8080"
  echo "3. MQTT disponível em: 72.60.50.248:1883 (user: 
  orthotrack, pass: mqtt123)"
  echo "4. Para rollback: ssh root@72.60.50.248 'docker-compose 
  -f /opt/orthotrack-v3/docker-compose.yml down'"
  echo ""
  echo "🔗 Endpoints principais:"
  echo "  - Health: http://72.60.50.248:8080/health"
  echo "  - API: http://72.60.50.248:8080/api/v1/"
  echo "  - WebSocket MQTT: ws://72.60.50.248:9001"

╭───────────────────────────────────────────────────────────────────╮
│ >                                                                 │
╰───────────────────────────────────────────────────────────────────╯
  ? for          ✗ Auto-update failed · Try claude doctor or npm i 
  shortcuts      -g @anthropic-ai/claude-code
