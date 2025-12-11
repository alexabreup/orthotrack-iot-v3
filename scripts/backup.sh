#!/bin/bash
# backup.sh - Sistema de backup completo do OrthoTrack IoT v3

set -e

# Configurações
BACKUP_DIR="/opt/backups/orthotrack"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30
LOG_FILE="/var/log/orthotrack/backup.log"
COMPOSE_FILE="/opt/orthotrack/docker-compose.prod.yml"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função de logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# Criar diretório de backup
mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log "🚀 Iniciando backup do OrthoTrack IoT v3..."

# 1. Backup do banco de dados PostgreSQL
log "💾 Fazendo backup do PostgreSQL..."
if docker ps --filter "name=orthotrack-postgres" --filter "status=running" | grep -q orthotrack-postgres; then
    docker exec orthotrack-postgres pg_dump -U orthotrack orthotrack_prod | gzip > "$BACKUP_DIR/db_backup_$DATE.sql.gz"
    if [ $? -eq 0 ]; then
        log "✅ Backup do PostgreSQL concluído"
    else
        error "❌ Falha no backup do PostgreSQL"
    fi
else
    warn "PostgreSQL container não está rodando"
fi

# 2. Backup dos volumes Docker
log "📦 Fazendo backup dos volumes Docker..."

# PostgreSQL data
if docker volume ls | grep -q orthotrack_postgres_data; then
    docker run --rm \
        -v orthotrack_postgres_data:/data \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/postgres_volume_$DATE.tar.gz -C /data .
    log "✅ Backup do volume PostgreSQL concluído"
fi

# Redis data
if docker volume ls | grep -q orthotrack_redis_data; then
    docker run --rm \
        -v orthotrack_redis_data:/data \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/redis_volume_$DATE.tar.gz -C /data .
    log "✅ Backup do volume Redis concluído"
fi

# MQTT data
if docker volume ls | grep -q orthotrack_mqtt_data; then
    docker run --rm \
        -v orthotrack_mqtt_data:/data \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf /backup/mqtt_volume_$DATE.tar.gz -C /data .
    log "✅ Backup do volume MQTT concluído"
fi

# 3. Backup da configuração
log "⚙️ Fazendo backup das configurações..."
cd /opt/orthotrack
tar czf "$BACKUP_DIR/config_backup_$DATE.tar.gz" \
    docker-compose.prod.yml \
    nginx.conf \
    mosquitto.conf \
    mosquitto_passwd \
    backend/.env.production \
    frontend/.env.production \
    monitoring/ \
    scripts/ \
    2>/dev/null || warn "Alguns arquivos de configuração não foram encontrados"

log "✅ Backup das configurações concluído"

# 4. Backup dos logs
log "📋 Fazendo backup dos logs..."
if [ -d "/var/log/orthotrack" ]; then
    tar czf "$BACKUP_DIR/logs_backup_$DATE.tar.gz" -C /var/log orthotrack/
    log "✅ Backup dos logs concluído"
fi

# 5. Backup do código fonte (se existir)
if [ -d "/opt/orthotrack/.git" ]; then
    log "📝 Fazendo backup do repositório Git..."
    tar czf "$BACKUP_DIR/source_backup_$DATE.tar.gz" \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='build' \
        --exclude='dist' \
        -C /opt orthotrack/
    log "✅ Backup do código fonte concluído"
fi

# 6. Criar manifesto do backup
log "📄 Criando manifesto do backup..."
cat > "$BACKUP_DIR/backup_manifest_$DATE.txt" << EOF
OrthoTrack IoT v3 - Backup Manifest
===================================
Date: $(date)
Backup ID: $DATE
Server: $(hostname)
IP: $(hostname -I | awk '{print $1}')

Files included:
$(ls -la "$BACKUP_DIR"/*_$DATE.* 2>/dev/null || echo "No backup files found")

Docker containers status:
$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}")

Docker volumes:
$(docker volume ls | grep orthotrack)

System info:
- Disk usage: $(df -h / | awk 'NR==2 {print $5}')
- Memory usage: $(free -h | awk 'NR==2{printf "%.1f%%", $3*100/$2}')
- Load average: $(uptime | awk -F'load average:' '{print $2}')

Backup completed at: $(date)
EOF

# 7. Calcular checksums
log "🔐 Calculando checksums..."
cd "$BACKUP_DIR"
find . -name "*_$DATE.*" -type f -exec sha256sum {} \; > "checksums_$DATE.txt"

# 8. Remover backups antigos
log "🧹 Removendo backups antigos (>$RETENTION_DAYS dias)..."
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.txt" -mtime +$RETENTION_DAYS -delete

# 9. Verificar espaço em disco
DISK_USAGE=$(df "$BACKUP_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    warn "Espaço em disco baixo: ${DISK_USAGE}%"
fi

# 10. Upload para cloud (se configurado)
if [ -n "$AWS_S3_BUCKET" ]; then
    log "☁️ Fazendo upload para S3..."
    aws s3 sync "$BACKUP_DIR" "s3://$AWS_S3_BUCKET/orthotrack-backups/" \
        --exclude "*" \
        --include "*_$DATE.*" \
        --storage-class STANDARD_IA
    log "✅ Upload para S3 concluído"
fi

# 11. Notificar conclusão
BACKUP_SIZE=$(du -sh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
log "✅ Backup concluído com sucesso!"
log "📊 Estatísticas do backup:"
log "   - Data: $DATE"
log "   - Arquivos: $(ls -1 "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | wc -l)"
log "   - Tamanho total: $(du -sh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | awk '{sum+=$1} END {print sum "B"}' || echo "0B")"
log "   - Localização: $BACKUP_DIR"

# 12. Enviar notificação (se webhook configurado)
if [ -n "$BACKUP_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
         --data "{
           \"text\": \"✅ OrthoTrack Backup Completed\",
           \"attachments\": [{
             \"color\": \"good\",
             \"fields\": [
               {\"title\": \"Date\", \"value\": \"$DATE\", \"short\": true},
               {\"title\": \"Files\", \"value\": \"$(ls -1 "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | wc -l)\", \"short\": true},
               {\"title\": \"Size\", \"value\": \"$(du -sh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null | awk '{sum+=$1} END {print sum "B"}' || echo "0B")\", \"short\": true},
               {\"title\": \"Status\", \"value\": \"Success\", \"short\": true}
             ]
           }]
         }" \
         "$BACKUP_WEBHOOK_URL" 2>/dev/null || warn "Falha ao enviar notificação"
fi

log "🎉 Processo de backup finalizado!"