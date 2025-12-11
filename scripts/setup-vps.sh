#!/bin/bash
# setup-vps.sh - Script de configuração inicial do VPS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    error "Este script deve ser executado como root"
fi

log "🚀 Iniciando configuração do VPS para OrthoTrack IoT v3..."

# 1. Atualizar sistema
log "📦 Atualizando sistema..."
apt update && apt upgrade -y

# 2. Instalar dependências essenciais
log "🔧 Instalando dependências essenciais..."
apt install -y \
    curl \
    wget \
    git \
    unzip \
    htop \
    tree \
    vim \
    nano \
    ufw \
    fail2ban \
    certbot \
    python3-certbot-nginx \
    nginx \
    jq \
    bc \
    rsync \
    cron

# 3. Configurar timezone
log "🕐 Configurando timezone..."
timedatectl set-timezone America/Sao_Paulo

# 4. Instalar Docker
log "🐳 Instalando Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    
    # Instalar Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Criar link simbólico
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
else
    log "Docker já está instalado"
fi

# 5. Configurar firewall
log "🔥 Configurando firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH
ufw allow 22/tcp

# Permitir HTTP e HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Permitir MQTT
ufw allow 1883/tcp
ufw allow 9001/tcp

# Permitir monitoramento (apenas localhost)
ufw allow from 127.0.0.1 to any port 9090  # Prometheus
ufw allow from 127.0.0.1 to any port 3001  # Grafana
ufw allow from 127.0.0.1 to any port 9093  # AlertManager

# Ativar firewall
ufw --force enable

# 6. Configurar Fail2Ban
log "🛡️ Configurando Fail2Ban..."
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 3
EOF

systemctl restart fail2ban
systemctl enable fail2ban

# 7. Criar estrutura de diretórios
log "📁 Criando estrutura de diretórios..."
mkdir -p /opt/orthotrack/{scripts,monitoring,backups,logs}
mkdir -p /var/log/orthotrack
mkdir -p /opt/backups/orthotrack

# 8. Configurar usuário para deploy (se não existir)
if ! id "deploy" &>/dev/null; then
    log "👤 Criando usuário deploy..."
    useradd -m -s /bin/bash deploy
    usermod -aG docker deploy
    
    # Configurar SSH para usuário deploy
    mkdir -p /home/deploy/.ssh
    chmod 700 /home/deploy/.ssh
    chown deploy:deploy /home/deploy/.ssh
fi

# 9. Configurar logrotate
log "📋 Configurando rotação de logs..."
cat > /etc/logrotate.d/orthotrack << 'EOF'
/var/log/orthotrack/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}

/opt/orthotrack/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 deploy deploy
}
EOF

# 10. Configurar swap (se não existir)
if [ ! -f /swapfile ]; then
    log "💾 Configurando swap..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 11. Otimizações do sistema
log "⚡ Aplicando otimizações do sistema..."
cat >> /etc/sysctl.conf << 'EOF'

# OrthoTrack optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 65536 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.core.netdev_max_backlog=5000
net.ipv4.tcp_congestion_control=bbr
EOF

sysctl -p

# 12. Configurar Docker daemon
log "🐳 Configurando Docker daemon..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "experimental": false,
  "metrics-addr": "127.0.0.1:9323",
  "experimental": true
}
EOF

systemctl restart docker
systemctl enable docker

# 13. Instalar ferramentas de monitoramento
log "📊 Instalando ferramentas de monitoramento..."
# Node Exporter
if [ ! -f /usr/local/bin/node_exporter ]; then
    cd /tmp
    wget https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xvfz node_exporter-1.6.1.linux-amd64.tar.gz
    cp node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
    
    # Criar usuário para node_exporter
    useradd --no-create-home --shell /bin/false node_exporter
    
    # Criar serviço systemd
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
fi

# 14. Configurar backup automático
log "💾 Configurando backup automático..."
cat > /opt/orthotrack/scripts/backup.sh << 'EOF'
#!/bin/bash
# Backup automático do OrthoTrack

BACKUP_DIR="/opt/backups/orthotrack"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p $BACKUP_DIR

# Backup do banco de dados
if docker ps --filter "name=orthotrack-postgres" --filter "status=running" | grep -q orthotrack-postgres; then
    docker exec orthotrack-postgres pg_dump -U orthotrack orthotrack_prod | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz
fi

# Backup dos volumes Docker
if docker volume ls | grep -q orthotrack; then
    docker run --rm -v orthotrack_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres_volume_$DATE.tar.gz -C /data .
    docker run --rm -v orthotrack_redis_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/redis_volume_$DATE.tar.gz -C /data .
fi

# Backup da configuração
tar czf $BACKUP_DIR/config_backup_$DATE.tar.gz -C /opt/orthotrack \
    docker-compose.prod.yml \
    nginx.conf \
    mosquitto.conf \
    backend/.env.production 2>/dev/null || true

# Remover backups antigos
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

echo "$(date): Backup completed successfully" >> /var/log/orthotrack/backup.log
EOF

chmod +x /opt/orthotrack/scripts/backup.sh

# 15. Configurar health check
log "🏥 Configurando health check..."
cat > /opt/orthotrack/scripts/health-check.sh << 'EOF'
#!/bin/bash
# Health check do OrthoTrack

LOG_FILE="/var/log/orthotrack/health.log"
WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

check_service() {
    local service_name=$1
    local container_name=$2
    
    if docker ps --filter "name=$container_name" --filter "status=running" | grep -q $container_name; then
        log_message "✅ $service_name is running"
        return 0
    else
        log_message "❌ $service_name is down"
        return 1
    fi
}

check_url() {
    local service_name=$1
    local url=$2
    local expected_status=${3:-200}
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 $url 2>/dev/null || echo "000")
    if [ "$status_code" = "$expected_status" ]; then
        log_message "✅ $service_name is responding (HTTP $status_code)"
        return 0
    else
        log_message "❌ $service_name is not responding (HTTP $status_code)"
        return 1
    fi
}

main() {
    log_message "Starting health check..."
    
    failed_services=()
    
    # Verificar containers
    check_service "PostgreSQL" "orthotrack-postgres" || failed_services+=("PostgreSQL")
    check_service "Redis" "orthotrack-redis" || failed_services+=("Redis")
    check_service "MQTT" "orthotrack-mqtt" || failed_services+=("MQTT")
    check_service "Backend" "orthotrack-backend" || failed_services+=("Backend")
    check_service "Frontend" "orthotrack-frontend" || failed_services+=("Frontend")
    check_service "Nginx" "orthotrack-nginx" || failed_services+=("Nginx")
    
    # Verificar URLs
    check_url "Frontend" "https://orthotrack.alexptech.com/health" || failed_services+=("Frontend URL")
    check_url "Backend API" "https://api.orthotrack.alexptech.com/health" || failed_services+=("Backend API")
    
    # Verificar recursos do sistema
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $disk_usage -gt 85 ]; then
        log_message "⚠️ Disk usage is high: ${disk_usage}%"
        failed_services+=("Disk Space")
    fi
    
    mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ $mem_usage -gt 90 ]; then
        log_message "⚠️ Memory usage is high: ${mem_usage}%"
        failed_services+=("Memory")
    fi
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        alert_message="Services down: $(IFS=', '; echo "${failed_services[*]}")"
        log_message "Alert: $alert_message"
        
        # Enviar notificação se webhook configurado
        if [ -n "$WEBHOOK_URL" ]; then
            curl -X POST -H 'Content-type: application/json' \
                 --data "{\"text\":\"🚨 OrthoTrack Alert: $alert_message\"}" \
                 "$WEBHOOK_URL" 2>/dev/null || true
        fi
    else
        log_message "✅ All services are healthy"
    fi
    
    log_message "Health check completed"
}

main "$@"
EOF

chmod +x /opt/orthotrack/scripts/health-check.sh

# 16. Configurar crontab para tarefas automáticas
log "⏰ Configurando tarefas automáticas..."
cat > /tmp/orthotrack-cron << 'EOF'
# Backup diário às 2h
0 2 * * * /opt/orthotrack/scripts/backup.sh

# Health check a cada 5 minutos
*/5 * * * * /opt/orthotrack/scripts/health-check.sh

# Limpeza de logs Docker semanalmente
0 3 * * 0 docker system prune -f

# Renovação SSL mensal
0 4 1 * * /usr/bin/certbot renew --quiet && docker-compose -f /opt/orthotrack/docker-compose.prod.yml restart nginx
EOF

crontab /tmp/orthotrack-cron
rm /tmp/orthotrack-cron

# 17. Configurar SSL inicial (placeholder)
log "🔒 Preparando configuração SSL..."
mkdir -p /etc/letsencrypt/live/orthotrack.alexptech.com

# Criar certificados temporários para teste
if [ ! -f /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem ]; then
    warn "Certificados SSL não encontrados. Execute o comando abaixo após configurar o DNS:"
    warn "certbot certonly --standalone -d orthotrack.alexptech.com -d www.orthotrack.alexptech.com -d api.orthotrack.alexptech.com"
fi

# 18. Configurar permissões
log "🔐 Configurando permissões..."
chown -R deploy:deploy /opt/orthotrack
chmod -R 755 /opt/orthotrack/scripts
chmod 600 /opt/orthotrack/backend/.env.production 2>/dev/null || true

# 19. Criar arquivo de variáveis de ambiente para GitHub Actions
log "📝 Criando template de variáveis de ambiente..."
cat > /opt/orthotrack/.env.template << 'EOF'
# Variáveis que devem ser configuradas no GitHub Secrets:
# DB_PASSWORD=<senha_segura_do_banco>
# REDIS_PASSWORD=<senha_segura_do_redis>
# MQTT_PASSWORD=<senha_segura_do_mqtt>
# JWT_SECRET=<chave_jwt_secreta>
# DOCKER_USERNAME=<seu_usuario_docker_hub>
# DOCKER_PASSWORD=<sua_senha_docker_hub>
# VPS_SSH_PRIVATE_KEY=<chave_privada_ssh>
# SLACK_WEBHOOK_URL=<url_webhook_slack_opcional>
EOF

# 20. Finalizar
log "✅ Configuração do VPS concluída!"
log ""
log "📋 Próximos passos:"
log "1. Configure o DNS para apontar para este servidor (72.60.50.248)"
log "2. Execute: certbot certonly --standalone -d orthotrack.alexptech.com -d www.orthotrack.alexptech.com -d api.orthotrack.alexptech.com"
log "3. Configure os secrets no GitHub:"
log "   - DB_PASSWORD, REDIS_PASSWORD, MQTT_PASSWORD, JWT_SECRET"
log "   - DOCKER_USERNAME, DOCKER_PASSWORD"
log "   - VPS_SSH_PRIVATE_KEY (chave privada SSH)"
log "4. Faça push para o branch main para iniciar o deploy automático"
log ""
log "🔧 Comandos úteis:"
log "- Ver logs: docker-compose -f /opt/orthotrack/docker-compose.prod.yml logs -f"
log "- Status: docker-compose -f /opt/orthotrack/docker-compose.prod.yml ps"
log "- Health check: /opt/orthotrack/scripts/health-check.sh"
log "- Backup manual: /opt/orthotrack/scripts/backup.sh"
log ""
log "🌐 URLs após deploy:"
log "- Frontend: https://orthotrack.alexptech.com"
log "- API: https://api.orthotrack.alexptech.com"
log "- Health: https://orthotrack.alexptech.com/health"