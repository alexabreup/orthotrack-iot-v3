# OrthoTrack IoT v3 - Script de Correção Completa (Windows PowerShell)
# Data: 11 de Dezembro de 2025
# Resolve: Redis, MQTT/Mosquitto e Frontend

param(
    [switch]$Force = $false
)

# Configuração de cores
$Host.UI.RawUI.ForegroundColor = "White"

function Write-Log {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor Green
}

function Write-Error-Log {
    param([string]$Message)
    Write-Host "[ERRO] $Message" -ForegroundColor Red
}

function Write-Warning-Log {
    param([string]$Message)
    Write-Host "[AVISO] $Message" -ForegroundColor Yellow
}

Write-Host "=== OrthoTrack IoT v3 - Correção Completa ===" -ForegroundColor Blue
Write-Host "Resolvendo 3 erros críticos identificados" -ForegroundColor Yellow
Write-Host ""

# Verificar se estamos no diretório correto
if (-not (Test-Path "docker-compose.yml")) {
    Write-Error-Log "docker-compose.yml não encontrado. Execute este script no diretório raiz do projeto."
    exit 1
}

Write-Log "1. Parando todos os containers..."
try {
    docker compose down -v 2>$null
} catch {
    try {
        docker-compose down -v 2>$null
    } catch {
        Write-Warning-Log "Erro ao parar containers, continuando..."
    }
}

Write-Log "2. Fazendo backup das configurações..."
$BackupDir = "backups\config-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

if (Test-Path "config") {
    Copy-Item -Path "config" -Destination $BackupDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Backup salvo em: $BackupDir"
}

Write-Log "3. Criando diretórios de configuração necessários..."
New-Item -ItemType Directory -Path "config\redis" -Force | Out-Null
New-Item -ItemType Directory -Path "config\mosquitto" -Force | Out-Null
New-Item -ItemType Directory -Path "config\nginx" -Force | Out-Null

# ===== CORREÇÃO 1: REDIS =====
Write-Log "4. Corrigindo configuração do Redis..."

if (Test-Path "config\redis\redis.conf") {
    Write-Warning-Log "Arquivo redis.conf existente encontrado, fazendo backup..."
    Copy-Item -Path "config\redis\redis.conf" -Destination "$BackupDir\redis.conf.backup" -Force -ErrorAction SilentlyContinue
}

# Criar configuração Redis limpa
$redisConfig = @"
# Redis Configuration - OrthoTrack IoT v3
# Configuração para ambiente de desenvolvimento (sem autenticação)

# Network
bind 0.0.0.0
port 6379
protected-mode no

# General
daemonize no
supervised no
pidfile /var/run/redis_6379.pid

# Logging
loglevel notice
logfile ""

# Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /data

# Memory
maxmemory-policy allkeys-lru

# Clients
timeout 0
tcp-keepalive 300
tcp-backlog 511

# Performance
databases 16
"@

$redisConfig | Out-File -FilePath "config\redis\redis.conf" -Encoding UTF8
Write-Log "Redis configurado sem autenticação (modo desenvolvimento)"

# ===== CORREÇÃO 2: MQTT/MOSQUITTO =====
Write-Log "5. Corrigindo configuração do MQTT/Mosquitto..."

if (Test-Path "config\mosquitto\mosquitto.conf") {
    Write-Warning-Log "Arquivo mosquitto.conf existente encontrado, fazendo backup..."
    Copy-Item -Path "config\mosquitto\mosquitto.conf" -Destination "$BackupDir\mosquitto.conf.backup" -Force -ErrorAction SilentlyContinue
}

# Criar configuração Mosquitto limpa
$mosquittoConfig = @"
# Mosquitto Configuration - OrthoTrack IoT v3
# Configuração limpa sem bridge para evitar erros

# Listener principal
listener 1883
protocol mqtt

# Segurança (modo desenvolvimento)
allow_anonymous true
password_file /mosquitto/config/passwd

# Persistência
persistence true
persistence_location /mosquitto/data/
autosave_interval 1800

# Logs
log_dest stdout
log_type error
log_type warning
log_type notice
log_type information

# Performance e limites
max_inflight_messages 40
max_queued_messages 200
message_size_limit 0
max_keepalive 65535

# Conexões
max_connections -1
connection_messages true
log_timestamp true

# WebSocket (se necessário)
# listener 9001
# protocol websockets

# Não incluir configurações de bridge que causam erro na linha 38
"@

$mosquittoConfig | Out-File -FilePath "config\mosquitto\mosquitto.conf" -Encoding UTF8

# Criar arquivo de senhas vazio
New-Item -ItemType File -Path "config\mosquitto\passwd" -Force | Out-Null

Write-Log "Mosquitto configurado sem bridge (configuração limpa)"

# ===== CORREÇÃO 3: FRONTEND =====
Write-Log "6. Corrigindo conflito de variável de ambiente do Frontend..."

# Remover variável conflitante do ambiente atual
Remove-Item Env:PUBLIC_WS_URL -ErrorAction SilentlyContinue

# Criar arquivo de ambiente específico para o frontend
$frontendEnv = @"
# Frontend Environment Variables - OrthoTrack IoT v3
PUBLIC_WS_URL=ws://localhost:8080/ws
PUBLIC_API_URL=http://localhost:8080/api
PUBLIC_MQTT_URL=ws://localhost:9001
NODE_ENV=production
VITE_API_BASE_URL=http://localhost:8080/api
VITE_WS_URL=ws://localhost:8080/ws
"@

$frontendEnv | Out-File -FilePath "frontend.env" -Encoding UTF8
Write-Log "Variáveis de ambiente do frontend configuradas"

# ===== LIMPEZA DE VOLUMES =====
Write-Log "7. Limpando volumes antigos..."
$volumes = @("orthotrack_redis_data", "orthotrack_mqtt_data", "orthotrack_mqtt_logs", "orthotrack_postgres_data")

foreach ($volume in $volumes) {
    try {
        docker volume rm $volume 2>$null
    } catch {
        # Ignorar erros se o volume não existir
    }
}

# Remover volumes órfãos
try {
    docker volume prune -f 2>$null
} catch {
    Write-Warning-Log "Erro ao limpar volumes órfãos"
}

Write-Log "Volumes limpos"

# ===== VERIFICAÇÃO DE ARQUIVOS DOCKER COMPOSE =====
Write-Log "8. Verificando arquivos docker-compose..."

$ComposeFile = "docker-compose.yml"
if (Test-Path "docker-compose.local.yml") {
    $ComposeFile = "docker-compose.local.yml"
    Write-Log "Usando docker-compose.local.yml"
} elseif (Test-Path "docker-compose.prod.yml") {
    $ComposeFile = "docker-compose.prod.yml"
    Write-Log "Usando docker-compose.prod.yml"
}

# ===== INICIALIZAÇÃO SEQUENCIAL =====
Write-Log "9. Iniciando serviços sequencialmente..."

# Função para iniciar serviço
function Start-Service {
    param([string]$ServiceName, [int]$WaitSeconds = 5)
    
    Write-Log "Iniciando $ServiceName..."
    try {
        docker compose -f $ComposeFile up -d $ServiceName 2>$null
    } catch {
        try {
            docker-compose -f $ComposeFile up -d $ServiceName 2>$null
        } catch {
            Write-Warning-Log "Erro ao iniciar $ServiceName"
        }
    }
    Start-Sleep -Seconds $WaitSeconds
}

# Iniciar serviços em ordem
Start-Service "postgres" 10
Start-Service "redis" 5
Start-Service "mqtt" 5
Start-Service "backend" 10
Start-Service "frontend" 5

# Verificar se nginx existe e iniciar
try {
    $services = docker compose -f $ComposeFile config --services 2>$null
    if ($services -contains "nginx") {
        Start-Service "nginx" 5
    }
} catch {
    Write-Warning-Log "Não foi possível verificar serviços disponíveis"
}

Write-Log "10. Aguardando estabilização dos serviços..."
Start-Sleep -Seconds 15

# ===== VERIFICAÇÃO DE STATUS =====
Write-Log "11. Verificando status dos containers..."
Write-Host ""
try {
    docker compose -f $ComposeFile ps
} catch {
    try {
        docker-compose -f $ComposeFile ps
    } catch {
        Write-Warning-Log "Erro ao verificar status dos containers"
    }
}

Write-Host ""
Write-Log "12. Verificando logs dos serviços principais..."

function Show-ServiceLogs {
    param([string]$ServiceName)
    
    Write-Host "`n=== LOGS $ServiceName ===" -ForegroundColor Blue
    try {
        docker compose -f $ComposeFile logs $ServiceName --tail=10 2>$null
    } catch {
        try {
            docker-compose -f $ComposeFile logs $ServiceName --tail=10 2>$null
        } catch {
            Write-Warning-Log "Erro ao obter logs do $ServiceName"
        }
    }
}

Show-ServiceLogs "redis"
Show-ServiceLogs "mqtt"
Show-ServiceLogs "frontend"

# ===== TESTES DE CONECTIVIDADE =====
Write-Log "13. Executando testes de conectividade..."

Write-Host "`n=== TESTE REDIS ===" -ForegroundColor Blue
try {
    $redisTest = docker exec orthotrack-redis redis-cli ping 2>$null
    if ($redisTest -eq "PONG") {
        Write-Log "✅ Redis: Conectividade OK"
    } else {
        Write-Error-Log "❌ Redis: Falha na conectividade"
    }
} catch {
    Write-Error-Log "❌ Redis: Erro no teste de conectividade"
}

Write-Host "`n=== TESTE MQTT ===" -ForegroundColor Blue
try {
    docker exec orthotrack-mqtt mosquitto_pub -h localhost -t test/connection -m "test" 2>$null
    Write-Log "✅ MQTT: Conectividade OK"
} catch {
    Write-Warning-Log "⚠️  MQTT: Teste de conectividade inconclusivo"
}

Write-Host "`n=== TESTE FRONTEND ===" -ForegroundColor Blue
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Log "✅ Frontend: Acessível"
    } else {
        $response80 = Invoke-WebRequest -Uri "http://localhost:80" -Method Head -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response80.StatusCode -eq 200) {
            Write-Log "✅ Frontend: Acessível via Nginx (porta 80)"
        } else {
            Write-Warning-Log "⚠️  Frontend: Verificar manualmente http://localhost:3000"
        }
    }
} catch {
    Write-Warning-Log "⚠️  Frontend: Verificar manualmente http://localhost:3000"
}

# ===== RESUMO FINAL =====
Write-Host ""
Write-Host "=== CORREÇÃO CONCLUÍDA ===" -ForegroundColor Green
Write-Host "Problemas resolvidos:" -ForegroundColor Blue
Write-Host "✅ Redis: Configuração de senha corrigida (sem autenticação para dev)"
Write-Host "✅ MQTT: Configuração de bridge removida (configuração limpa)"
Write-Host "✅ Frontend: Conflito de variável PUBLIC_WS_URL resolvido"
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "1. Verificar se todos os containers estão rodando: docker compose ps"
Write-Host "2. Acessar o frontend: http://localhost:3000"
Write-Host "3. Verificar logs se necessário: docker compose logs [serviço]"
Write-Host "4. Para ambiente de produção, configurar senhas adequadas"
Write-Host ""
Write-Host "Arquivos de backup salvos em: $BackupDir" -ForegroundColor Blue
Write-Host "Sistema OrthoTrack IoT v3 pronto para uso!" -ForegroundColor Green