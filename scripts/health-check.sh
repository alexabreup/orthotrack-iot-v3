#!/bin/bash
# health-check.sh - Sistema de monitoramento de saúde do OrthoTrack IoT v3

set -e

# Configurações
LOG_FILE="/var/log/orthotrack/health.log"
WEBHOOK_URL="${HEALTH_WEBHOOK_URL:-}"
COMPOSE_FILE="/opt/orthotrack/docker-compose.prod.yml"
MAX_RESPONSE_TIME=5

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função de logging
log_message() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn_message() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error_message() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
}

info_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Criar diretório de log se não existir
mkdir -p "$(dirname "$LOG_FILE")"

# Função para verificar containers
check_container() {
    local service_name=$1
    local container_name=$2
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q "$container_name"; then
        log_message "✅ $service_name está rodando"
        return 0
    else
        error_message "❌ $service_name está parado"
        return 1
    fi
}

# Função para verificar URLs
check_url() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    local timeout=${4:-$MAX_RESPONSE_TIME}
    
    local response=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" --max-time "$timeout" "$url" 2>/dev/null || echo "000:999")
    local status_code=$(echo "$response" | cut -d':' -f1)
    local response_time=$(echo "$response" | cut -d':' -f2)
    
    if [ "$status_code" = "$expected_status" ]; then
        if (( $(echo "$response_time < $timeout" | bc -l) )); then
            log_message "✅ $service_name respondendo (HTTP $status_code, ${response_time}s)"
            return 0
        else
            warn_message "⚠️ $service_name lento (HTTP $status_code, ${response_time}s)"
            return 1
        fi
    else
        error_message "❌ $service_name não está respondendo (HTTP $status_code)"
        return 1
    fi
}

# Função para verificar porta
check_port() {
    local service_name=$1
    local host=$2
    local port=$3
    
    if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        log_message "✅ $service_name porta $port acessível"
        return 0
    else
        error_message "❌ $service_name porta $port inacessível"
        return 1
    fi
}

# Função para verificar recursos do sistema
check_system_resources() {
    info_message "🔍 Verificando recursos do sistema..."
    
    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' | sed 's/,//')
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        warn_message "⚠️ CPU usage alto: ${cpu_usage}%"
        return 1
    else
        log_message "✅ CPU usage normal: ${cpu_usage}%"
    fi
    
    # Memória
    local mem_total=$(free -m | awk 'NR==2{print $2}')
    local mem_used=$(free -m | awk 'NR==2{print $3}')
    local mem_percent=$(echo "scale=1; $mem_used*100/$mem_total" | bc)
    
    if (( $(echo "$mem_percent > 90" | bc -l) )); then
        warn_message "⚠️ Memória alta: ${mem_percent}%"
        return 1
    else
        log_message "✅ Memória normal: ${mem_percent}%"
    fi
    
    # Disco
    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 85 ]; then
        warn_message "⚠️ Espaço em disco baixo: ${disk_usage}%"
        return 1
    else
        log_message "✅ Espaço em disco OK: ${disk_usage}%"
    fi
    
    # Load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_cores=$(nproc)
    local load_percent=$(echo "scale=1; $load_avg*100/$cpu_cores" | bc)
    
    if (( $(echo "$load_percent > 80" | bc -l) )); then
        warn_message "⚠️ Load average alto: ${load_avg} (${load_percent}%)"
        return 1
    else
        log_message "✅ Load average normal: ${load_avg} (${load_percent}%)"
    fi
    
    return 0
}

# Função para verificar conectividade de rede
check_network() {
    info_message "🌐 Verificando conectividade de rede..."
    
    # DNS
    if nslookup google.com >/dev/null 2>&1; then
        log_message "✅ DNS funcionando"
    else
        error_message "❌ DNS não está funcionando"
        return 1
    fi
    
    # Internet
    if curl -s --max-time 5 http://google.com >/dev/null; then
        log_message "✅ Conectividade com internet OK"
    else
        warn_message "⚠️ Problemas de conectividade com internet"
        return 1
    fi
    
    return 0
}

# Função para verificar logs de erro
check_error_logs() {
    info_message "📋 Verificando logs de erro..."
    
    local error_count=0
    
    # Verificar logs do Docker
    if docker-compose -f "$COMPOSE_FILE" logs --tail=100 2>/dev/null | grep -i "error\|fatal\|panic" | grep -v "test" | tail -5 | while read -r line; do
        warn_message "Log error: $line"
        ((error_count++))
    done
    
    # Verificar logs do sistema
    if journalctl --since "5 minutes ago" --priority=err --no-pager -q | tail -5 | while read -r line; do
        warn_message "System error: $line"
        ((error_count++))
    done
    
    if [ "$error_count" -eq 0 ]; then
        log_message "✅ Nenhum erro crítico encontrado nos logs"
        return 0
    else
        warn_message "⚠️ Encontrados $error_count erros nos logs"
        return 1
    fi
}

# Função para verificar certificados SSL
check_ssl_certificates() {
    info_message "🔒 Verificando certificados SSL..."
    
    local domains=("orthotrack.alexptech.com" "www.orthotrack.alexptech.com" "api.orthotrack.alexptech.com")
    
    for domain in "${domains[@]}"; do
        if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            local expiry_date=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" | cut -d= -f2)
            local expiry_epoch=$(date -d "$expiry_date" +%s)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [ "$days_until_expiry" -lt 30 ]; then
                warn_message "⚠️ Certificado SSL para $domain expira em $days_until_expiry dias"
            else
                log_message "✅ Certificado SSL para $domain válido ($days_until_expiry dias restantes)"
            fi
        else
            error_message "❌ Certificado SSL para $domain não encontrado"
        fi
    done
}

# Função para enviar notificação
send_notification() {
    local status=$1
    local message=$2
    local failed_services=$3
    
    if [ -n "$WEBHOOK_URL" ]; then
        local color="good"
        local emoji="✅"
        
        if [ "$status" != "success" ]; then
            color="danger"
            emoji="❌"
        fi
        
        curl -X POST -H 'Content-type: application/json' \
             --data "{
               \"text\": \"$emoji OrthoTrack Health Check\",
               \"attachments\": [{
                 \"color\": \"$color\",
                 \"fields\": [
                   {\"title\": \"Status\", \"value\": \"$status\", \"short\": true},
                   {\"title\": \"Time\", \"value\": \"$(date)\", \"short\": true},
                   {\"title\": \"Server\", \"value\": \"$(hostname)\", \"short\": true},
                   {\"title\": \"Failed Services\", \"value\": \"$failed_services\", \"short\": false},
                   {\"title\": \"Message\", \"value\": \"$message\", \"short\": false}
                 ]
               }]
             }" \
             "$WEBHOOK_URL" 2>/dev/null || warn_message "Falha ao enviar notificação"
    fi
}

# Função principal
main() {
    log_message "🚀 Iniciando verificação de saúde do OrthoTrack IoT v3..."
    
    failed_services=()
    warnings=0
    
    # Verificar containers
    info_message "🐳 Verificando containers Docker..."
    check_container "PostgreSQL" "orthotrack-postgres" || failed_services+=("PostgreSQL")
    check_container "Redis" "orthotrack-redis" || failed_services+=("Redis")
    check_container "MQTT" "orthotrack-mqtt" || failed_services+=("MQTT")
    check_container "Backend" "orthotrack-backend" || failed_services+=("Backend")
    check_container "Frontend" "orthotrack-frontend" || failed_services+=("Frontend")
    check_container "Nginx" "orthotrack-nginx" || failed_services+=("Nginx")
    
    # Verificar URLs
    info_message "🌐 Verificando endpoints HTTP..."
    check_url "Frontend" "https://orthotrack.alexptech.com/health" || failed_services+=("Frontend URL")
    check_url "API Health" "https://api.orthotrack.alexptech.com/health" || failed_services+=("API Health")
    check_url "API Metrics" "https://api.orthotrack.alexptech.com/metrics" || failed_services+=("API Metrics")
    
    # Verificar portas
    info_message "🔌 Verificando portas de serviço..."
    check_port "MQTT" "localhost" "1883" || failed_services+=("MQTT Port")
    check_port "WebSocket" "localhost" "9001" || failed_services+=("WebSocket Port")
    
    # Verificar recursos do sistema
    check_system_resources || ((warnings++))
    
    # Verificar rede
    check_network || ((warnings++))
    
    # Verificar logs de erro
    check_error_logs || ((warnings++))
    
    # Verificar certificados SSL
    check_ssl_certificates || ((warnings++))
    
    # Verificar espaço em disco dos volumes Docker
    info_message "💾 Verificando volumes Docker..."
    docker system df | while read -r line; do
        if echo "$line" | grep -q "Local Volumes"; then
            local volume_usage=$(echo "$line" | awk '{print $4}' | sed 's/[^0-9.]//g')
            if (( $(echo "$volume_usage > 10" | bc -l) )); then
                warn_message "⚠️ Volumes Docker usando ${volume_usage}GB"
            else
                log_message "✅ Uso de volumes Docker normal: ${volume_usage}GB"
            fi
        fi
    done
    
    # Resumo final
    log_message "📊 Resumo da verificação de saúde:"
    log_message "   - Serviços com falha: ${#failed_services[@]}"
    log_message "   - Warnings: $warnings"
    log_message "   - Timestamp: $(date)"
    
    # Determinar status geral e enviar notificação
    if [ ${#failed_services[@]} -eq 0 ] && [ $warnings -eq 0 ]; then
        log_message "✅ Todos os serviços estão saudáveis!"
        send_notification "success" "All services healthy" "None"
    elif [ ${#failed_services[@]} -eq 0 ]; then
        log_message "⚠️ Todos os serviços estão rodando, mas há $warnings warnings"
        send_notification "warning" "$warnings warnings detected" "None (warnings only)"
    else
        local failed_list=$(IFS=', '; echo "${failed_services[*]}")
        error_message "❌ Serviços com falha: $failed_list"
        send_notification "failure" "Services are down or unhealthy" "$failed_list"
    fi
    
    log_message "🏁 Verificação de saúde concluída"
}

# Executar verificação principal
main "$@"