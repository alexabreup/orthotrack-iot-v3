# 🚀 Deploy Completo no VPS Ubuntu Server - OrthoTrack IoT v3

## 📋 Índice
1. [Preparação do Servidor](#preparação-do-servidor)
2. [Configuração de Segurança](#configuração-de-segurança)
3. [Deploy da Aplicação](#deploy-da-aplicação)
4. [Monitoramento e Observabilidade](#monitoramento-e-observabilidade)
5. [Backup e Recuperação](#backup-e-recuperação)
6. [Manutenção e Atualizações](#manutenção-e-atualizações)

---

## 🖥️ Preparação do Servidor

### 1. Requisitos Mínimos do VPS
```bash
# Especificações recomendadas:
- CPU: 2+ cores
- RAM: 4GB+ (8GB recomendado)
- Storage: 50GB+ SSD
- Bandwidth: Ilimitado
- OS: Ubuntu Server 22.04 LTS
```

### 2. Configuração Inicial do Ubuntu Server
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências essenciais
sudo apt install -y curl wget git unzip htop tree vim nano ufw fail2ban

# Configurar timezone
sudo timedatectl set-timezone America/Sao_Paulo

# Verificar configuração
timedatectl status
```

### 3. Instalar Docker e Docker Compose
```bash
# Remover versões antigas do Docker
sudo apt remove docker docker-engine docker.io containerd runc

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker-compose --version

# Reiniciar sessão para aplicar mudanças de grupo
exit
# Reconectar via SSH
```

---

## 🔒 Configuração de Segurança

### 1. Configurar Firewall (UFW)
```bash
# Configurar UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Permitir SSH (ajuste a porta se necessário)
sudo ufw allow 22/tcp

# Permitir HTTP e HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Permitir portas da aplicação
sudo ufw allow 8080/tcp  # Backend API
sudo ufw allow 3000/tcp  # Frontend (temporário)
sudo ufw allow 1883/tcp  # MQTT
sudo ufw allow 5432/tcp  # PostgreSQL (apenas se necessário externamente)
sudo ufw allow 6379/tcp  # Redis (apenas se necessário externamente)

# Ativar firewall
sudo ufw enable

# Verificar status
sudo ufw status verbose
```

### 2. Configurar Fail2Ban
```bash
# Criar configuração personalizada
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Editar configuração
sudo nano /etc/fail2ban/jail.local
```

Adicionar no arquivo `/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

```bash
# Reiniciar fail2ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Verificar status
sudo fail2ban-client status
```

### 3. Configurar SSL/TLS com Let's Encrypt
```bash
# Instalar Certbot
sudo apt install -y certbot python3-certbot-nginx

# Instalar Nginx
sudo apt install -y nginx

# Configurar Nginx (será detalhado na seção de deploy)
```

---

## 🚀 Deploy da Aplicação

### 1. Preparar Estrutura de Diretórios
```bash
# Criar estrutura de projeto
sudo mkdir -p /opt/orthotrack
sudo chown $USER:$USER /opt/orthotrack
cd /opt/orthotrack

# Clonar repositório (ajuste a URL)
git clone <seu-repositorio> .
# OU fazer upload dos arquivos via SCP/SFTP
```

### 2. Configurar Variáveis de Ambiente para Produção
```bash
# Criar arquivo de ambiente para produção
cp backend/.env.example backend/.env.production
nano backend/.env.production
```

Configurar `backend/.env.production`:
```env
# Database
DB_HOST=orthotrack-postgres
DB_PORT=5432
DB_NAME=orthotrack_prod
DB_USER=orthotrack
DB_PASSWORD=SENHA_SUPER_SEGURA_AQUI
DB_SSL_MODE=require

# Redis
REDIS_HOST=orthotrack-redis
REDIS_PORT=6379
REDIS_PASSWORD=REDIS_SENHA_SEGURA_AQUI
REDIS_DB=0
REDIS_POOL_SIZE=20
REDIS_MIN_IDLE_CONNS=10
REDIS_MAX_RETRIES=5

# MQTT
MQTT_HOST=orthotrack-mqtt
MQTT_PORT=1883
MQTT_BROKER_URL=tcp://orthotrack-mqtt:1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=MQTT_SENHA_SEGURA_AQUI
MQTT_CLIENT_ID=orthotrack-backend-prod

# JWT
JWT_SECRET=JWT_SUPER_SECRETO_MINIMO_32_CARACTERES_AQUI
JWT_EXPIRE_HOURS=24

# Server
PORT=8080
GIN_MODE=release

# CORS - Ajustar para seu domínio
ALLOWED_ORIGINS=https://seu-dominio.com,https://www.seu-dominio.com

# Alertas
IOT_ALERT_BATTERY_LOW=15
IOT_ALERT_TEMP_HIGH=45.0
IOT_ALERT_TEMP_LOW=5.0
```

### 3. Criar Docker Compose para Produção
```bash
nano docker-compose.prod.yml
```

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: orthotrack-postgres-prod
    restart: unless-stopped
    environment:
      POSTGRES_DB: orthotrack_prod
      POSTGRES_USER: orthotrack
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_HOST_AUTH_METHOD: md5
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backend/migrations:/docker-entrypoint-initdb.d:ro
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U orthotrack -d orthotrack_prod"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  redis:
    image: redis:7-alpine
    container_name: orthotrack-redis-prod
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  mqtt:
    image: eclipse-mosquitto:2.0-openssl
    container_name: orthotrack-mqtt-prod
    restart: unless-stopped
    ports:
      - "1883:1883"
      - "9001:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf:ro
      - ./mosquitto_passwd:/mosquitto/config/passwd:ro
      - mqtt_data:/mosquitto/data
      - mqtt_logs:/mosquitto/log
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m 'health check' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    image: orthotrack-backend:prod
    container_name: orthotrack-backend-prod
    restart: unless-stopped
    env_file:
      - ./backend/.env.production
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      mqtt:
        condition: service_healthy
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "50m"
        max-file: "5"

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - NODE_ENV=production
        - VITE_API_URL=https://api.seu-dominio.com
        - VITE_WS_URL=wss://api.seu-dominio.com/ws
    image: orthotrack-frontend:prod
    container_name: orthotrack-frontend-prod
    restart: unless-stopped
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  nginx:
    image: nginx:alpine
    container_name: orthotrack-nginx-prod
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - backend
      - frontend
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  mqtt_data:
    driver: local
  mqtt_logs:
    driver: local

networks:
  orthotrack-network:
    driver: bridge
```

### 4. Configurar Nginx como Reverse Proxy
```bash
nano nginx.conf
```

```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

    # Upstream servers
    upstream backend {
        server orthotrack-backend-prod:8080;
    }

    upstream frontend {
        server orthotrack-frontend-prod:3000;
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name seu-dominio.com www.seu-dominio.com api.seu-dominio.com;
        return 301 https://$server_name$request_uri;
    }

    # Main application (Frontend)
    server {
        listen 443 ssl http2;
        server_name seu-dominio.com www.seu-dominio.com;

        # SSL Configuration
        ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        location / {
            proxy_pass http://frontend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
    }

    # API Backend
    server {
        listen 443 ssl http2;
        server_name api.seu-dominio.com;

        # SSL Configuration (same as above)
        ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # API routes
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # WebSocket
        location /ws {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 86400;
        }

        # Auth endpoints (more restrictive)
        location /api/v1/auth/ {
            limit_req zone=login burst=5 nodelay;
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Health check
        location /health {
            access_log off;
            proxy_pass http://backend/health;
        }
    }
}
```

### 5. Configurar MQTT com Autenticação
```bash
# Criar arquivo de configuração do Mosquitto
nano mosquitto.conf
```

```conf
# Mosquitto Configuration for Production

# Network
listener 1883
protocol mqtt

listener 9001
protocol websockets

# Security
allow_anonymous false
password_file /mosquitto/config/passwd

# Persistence
persistence true
persistence_location /mosquitto/data/

# Logging
log_dest file /mosquitto/log/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information
log_timestamp true

# Limits
max_connections 1000
max_inflight_messages 100
max_queued_messages 1000
```

```bash
# Criar arquivo de senhas do MQTT
touch mosquitto_passwd
docker run --rm -v $(pwd):/mosquitto eclipse-mosquitto:2.0-openssl mosquitto_passwd -c /mosquitto/mosquitto_passwd orthotrack
# Digite a senha quando solicitado
```

### 6. Deploy da Aplicação
```bash
# Gerar senhas seguras
export DB_PASSWORD=$(openssl rand -base64 32)
export REDIS_PASSWORD=$(openssl rand -base64 32)
export JWT_SECRET=$(openssl rand -base64 32)

# Salvar senhas em arquivo seguro
echo "DB_PASSWORD=$DB_PASSWORD" > .env.secrets
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env.secrets
echo "JWT_SECRET=$JWT_SECRET" >> .env.secrets
chmod 600 .env.secrets

# Atualizar arquivo .env.production com as senhas geradas
sed -i "s/SENHA_SUPER_SEGURA_AQUI/$DB_PASSWORD/g" backend/.env.production
sed -i "s/REDIS_SENHA_SEGURA_AQUI/$REDIS_PASSWORD/g" backend/.env.production
sed -i "s/JWT_SUPER_SECRETO_MINIMO_32_CARACTERES_AQUI/$JWT_SECRET/g" backend/.env.production

# Fazer build das imagens
docker-compose -f docker-compose.prod.yml build

# Iniciar serviços
docker-compose -f docker-compose.prod.yml up -d

# Verificar status
docker-compose -f docker-compose.prod.yml ps
docker-compose -f docker-compose.prod.yml logs -f
```

### 7. Configurar SSL com Let's Encrypt
```bash
# Parar nginx temporariamente
docker-compose -f docker-compose.prod.yml stop nginx

# Obter certificados SSL
sudo certbot certonly --standalone -d seu-dominio.com -d www.seu-dominio.com -d api.seu-dominio.com

# Reiniciar nginx
docker-compose -f docker-compose.prod.yml start nginx

# Configurar renovação automática
sudo crontab -e
# Adicionar linha:
# 0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f /opt/orthotrack/docker-compose.prod.yml restart nginx
```

---

## 📊 Monitoramento e Observabilidade

### 1. Instalar Prometheus + Grafana + AlertManager
```bash
# Criar diretório de monitoramento
mkdir -p monitoring/{prometheus,grafana,alertmanager}
cd monitoring
```

```yaml
# monitoring/docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin_password_segura
      - GF_USERS_ALLOW_SIGN_UP=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager_data:/alertmanager
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    restart: unless-stopped
    ports:
      - "8081:8080"
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

networks:
  monitoring:
    driver: bridge
```

### 2. Configurar Prometheus
```yaml
# monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'orthotrack-backend'
    static_configs:
      - targets: ['orthotrack-backend-prod:8080']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'nginx'
    static_configs:
      - targets: ['orthotrack-nginx-prod:80']
    metrics_path: '/nginx_status'
    scrape_interval: 30s
```

### 3. Configurar Alertas
```yaml
# monitoring/prometheus/rules/alerts.yml
groups:
  - name: orthotrack-alerts
    rules:
      # Sistema
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "CPU usage is above 80%"
          description: "CPU usage is {{ $value }}% on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Memory usage is above 85%"
          description: "Memory usage is {{ $value }}% on {{ $labels.instance }}"

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 15
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space is below 15%"
          description: "Disk space is {{ $value }}% on {{ $labels.instance }}"

      # Aplicação
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          description: "Service {{ $labels.job }} on {{ $labels.instance }} is down"

      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time detected"
          description: "95th percentile response time is {{ $value }}s"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) * 100 > 5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          description: "Error rate is {{ $value }}%"

      # Database
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL is down"
          description: "PostgreSQL database is not responding"

      - alert: RedisDown
        expr: redis_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Redis is down"
          description: "Redis server is not responding"
```

### 4. Configurar AlertManager
```yaml
# monitoring/alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@seu-dominio.com'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@seu-dominio.com'
        subject: 'OrthoTrack Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}
    
    webhook_configs:
      - url: 'http://seu-webhook-url/alerts'
        send_resolved: true

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

### 5. Scripts de Monitoramento Personalizados
```bash
# Criar script de health check
nano /opt/orthotrack/scripts/health-check.sh
```

```bash
#!/bin/bash
# health-check.sh - Verificação de saúde do sistema

LOG_FILE="/var/log/orthotrack-health.log"
WEBHOOK_URL="https://seu-webhook-discord-ou-slack"

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
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
    if [ "$status_code" = "$expected_status" ]; then
        log_message "✅ $service_name is responding (HTTP $status_code)"
        return 0
    else
        log_message "❌ $service_name is not responding (HTTP $status_code)"
        return 1
    fi
}

send_alert() {
    local message=$1
    curl -X POST -H 'Content-type: application/json' \
         --data "{\"text\":\"🚨 OrthoTrack Alert: $message\"}" \
         $WEBHOOK_URL
}

main() {
    log_message "Starting health check..."
    
    failed_services=()
    
    # Verificar containers
    check_service "PostgreSQL" "orthotrack-postgres-prod" || failed_services+=("PostgreSQL")
    check_service "Redis" "orthotrack-redis-prod" || failed_services+=("Redis")
    check_service "MQTT" "orthotrack-mqtt-prod" || failed_services+=("MQTT")
    check_service "Backend" "orthotrack-backend-prod" || failed_services+=("Backend")
    check_service "Frontend" "orthotrack-frontend-prod" || failed_services+=("Frontend")
    check_service "Nginx" "orthotrack-nginx-prod" || failed_services+=("Nginx")
    
    # Verificar URLs
    check_url "Frontend" "https://seu-dominio.com/health" || failed_services+=("Frontend URL")
    check_url "Backend API" "https://api.seu-dominio.com/health" || failed_services+=("Backend API")
    
    # Verificar espaço em disco
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $disk_usage -gt 85 ]; then
        log_message "⚠️ Disk usage is high: ${disk_usage}%"
        failed_services+=("Disk Space")
    fi
    
    # Verificar memória
    mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ $mem_usage -gt 90 ]; then
        log_message "⚠️ Memory usage is high: ${mem_usage}%"
        failed_services+=("Memory")
    fi
    
    # Enviar alertas se necessário
    if [ ${#failed_services[@]} -gt 0 ]; then
        alert_message="Services down: $(IFS=', '; echo "${failed_services[*]}")"
        send_alert "$alert_message"
        log_message "Alert sent: $alert_message"
    else
        log_message "✅ All services are healthy"
    fi
    
    log_message "Health check completed"
}

main "$@"
```

```bash
# Tornar executável
chmod +x /opt/orthotrack/scripts/health-check.sh

# Configurar cron para executar a cada 5 minutos
crontab -e
# Adicionar:
# */5 * * * * /opt/orthotrack/scripts/health-check.sh
```

### 6. Configurar Logs Centralizados
```bash
# Instalar Loki + Promtail para logs
nano monitoring/docker-compose.logging.yml
```

```yaml
version: '3.8'

services:
  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/local-config.yaml:ro
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - monitoring

  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/config.yml:ro
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    networks:
      - monitoring

volumes:
  loki_data:

networks:
  monitoring:
    external: true
```

---

## 💾 Backup e Recuperação

### 1. Script de Backup Automatizado
```bash
nano /opt/orthotrack/scripts/backup.sh
```

```bash
#!/bin/bash
# backup.sh - Backup automatizado do OrthoTrack

BACKUP_DIR="/opt/backups/orthotrack"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Criar diretório de backup
mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker exec orthotrack-postgres-prod pg_dump -U orthotrack orthotrack_prod | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Backup dos volumes Docker
docker run --rm -v orthotrack_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/postgres_volume_$DATE.tar.gz -C /data .
docker run --rm -v orthotrack_redis_data:/data -v $BACKUP_DIR:/backup alpine tar czf /backup/redis_volume_$DATE.tar.gz -C /data .

# Backup da configuração
tar czf $BACKUP_DIR/config_backup_$DATE.tar.gz -C /opt/orthotrack \
    docker-compose.prod.yml \
    nginx.conf \
    mosquitto.conf \
    backend/.env.production \
    .env.secrets

# Remover backups antigos
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete

# Log do backup
echo "$(date): Backup completed successfully" >> /var/log/orthotrack-backup.log

# Upload para cloud (opcional)
# aws s3 sync $BACKUP_DIR s3://seu-bucket-backup/orthotrack/
```

```bash
# Configurar backup diário
chmod +x /opt/orthotrack/scripts/backup.sh
crontab -e
# Adicionar:
# 0 2 * * * /opt/orthotrack/scripts/backup.sh
```

### 2. Script de Restauração
```bash
nano /opt/orthotrack/scripts/restore.sh
```

```bash
#!/bin/bash
# restore.sh - Restauração do backup

BACKUP_DIR="/opt/backups/orthotrack"
BACKUP_DATE=$1

if [ -z "$BACKUP_DATE" ]; then
    echo "Usage: $0 <backup_date> (format: YYYYMMDD_HHMMSS)"
    echo "Available backups:"
    ls -la $BACKUP_DIR/db_backup_*.sql.gz | awk '{print $9}' | sed 's/.*db_backup_\(.*\)\.sql\.gz/\1/'
    exit 1
fi

echo "Restoring backup from $BACKUP_DATE..."

# Parar serviços
docker-compose -f /opt/orthotrack/docker-compose.prod.yml stop

# Restaurar banco de dados
gunzip -c $BACKUP_DIR/db_backup_$BACKUP_DATE.sql.gz | docker exec -i orthotrack-postgres-prod psql -U orthotrack -d orthotrack_prod

# Restaurar volumes
docker run --rm -v orthotrack_postgres_data:/data -v $BACKUP_DIR:/backup alpine tar xzf /backup/postgres_volume_$BACKUP_DATE.tar.gz -C /data
docker run --rm -v orthotrack_redis_data:/data -v $BACKUP_DIR:/backup alpine tar xzf /backup/redis_volume_$BACKUP_DATE.tar.gz -C /data

# Reiniciar serviços
docker-compose -f /opt/orthotrack/docker-compose.prod.yml start

echo "Restore completed!"
```

---

## 🔄 Manutenção e Atualizações

### 1. Script de Atualização
```bash
nano /opt/orthotrack/scripts/update.sh
```

```bash
#!/bin/bash
# update.sh - Atualização do sistema

set -e

echo "Starting OrthoTrack update process..."

# Backup antes da atualização
/opt/orthotrack/scripts/backup.sh

# Baixar atualizações
cd /opt/orthotrack
git pull origin main

# Rebuild das imagens
docker-compose -f docker-compose.prod.yml build --no-cache

# Rolling update (zero downtime)
docker-compose -f docker-compose.prod.yml up -d --force-recreate --remove-orphans

# Verificar saúde após atualização
sleep 30
/opt/orthotrack/scripts/health-check.sh

echo "Update completed successfully!"
```

### 2. Monitoramento de Performance
```bash
nano /opt/orthotrack/scripts/performance-monitor.sh
```

```bash
#!/bin/bash
# performance-monitor.sh - Monitor de performance

METRICS_FILE="/var/log/orthotrack-metrics.log"

collect_metrics() {
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    # Memory
    mem_total=$(free -m | awk 'NR==2{print $2}')
    mem_used=$(free -m | awk 'NR==2{print $3}')
    mem_percent=$(echo "scale=2; $mem_used/$mem_total*100" | bc)
    
    # Disk
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # Docker stats
    container_stats=$(docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}")
    
    # Response times
    frontend_response=$(curl -o /dev/null -s -w '%{time_total}' https://seu-dominio.com/health)
    api_response=$(curl -o /dev/null -s -w '%{time_total}' https://api.seu-dominio.com/health)
    
    # Log metrics
    echo "$timestamp,CPU:$cpu_usage,MEM:$mem_percent%,DISK:$disk_usage%,FRONTEND:${frontend_response}s,API:${api_response}s" >> $METRICS_FILE
}

# Executar coleta
collect_metrics

# Manter apenas últimos 7 dias de métricas
find /var/log -name "orthotrack-metrics.log" -mtime +7 -exec truncate -s 0 {} \;
```

### 3. Configurar Rotação de Logs
```bash
sudo nano /etc/logrotate.d/orthotrack
```

```
/var/log/orthotrack-*.log {
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
```

---

## 🚀 Comandos de Deploy Final

```bash
# 1. Clonar e configurar
cd /opt
sudo git clone <seu-repositorio> orthotrack
sudo chown -R $USER:$USER orthotrack
cd orthotrack

# 2. Configurar ambiente
cp backend/.env.example backend/.env.production
# Editar backend/.env.production com suas configurações

# 3. Gerar senhas seguras
export DB_PASSWORD=$(openssl rand -base64 32)
export REDIS_PASSWORD=$(openssl rand -base64 32)
export JWT_SECRET=$(openssl rand -base64 32)

# 4. Iniciar monitoramento
cd monitoring
docker-compose -f docker-compose.monitoring.yml up -d
docker-compose -f docker-compose.logging.yml up -d

# 5. Deploy da aplicação
cd /opt/orthotrack
docker-compose -f docker-compose.prod.yml up -d

# 6. Configurar SSL
sudo certbot certonly --standalone -d seu-dominio.com -d www.seu-dominio.com -d api.seu-dominio.com

# 7. Configurar backups e monitoramento
chmod +x scripts/*.sh
crontab -e
# Adicionar:
# 0 2 * * * /opt/orthotrack/scripts/backup.sh
# */5 * * * * /opt/orthotrack/scripts/health-check.sh
# */10 * * * * /opt/orthotrack/scripts/performance-monitor.sh

# 8. Verificar status
docker-compose -f docker-compose.prod.yml ps
curl -I https://seu-dominio.com
curl -I https://api.seu-dominio.com/health
```

---

## 📊 URLs de Monitoramento

Após o deploy, você terá acesso a:

- **Aplicação Principal**: https://seu-dominio.com
- **API**: https://api.seu-dominio.com
- **Grafana**: http://seu-ip:3001 (admin/admin_password_segura)
- **Prometheus**: http://seu-ip:9090
- **AlertManager**: http://seu-ip:9093

---

## 🔧 Troubleshooting

### Comandos Úteis de Diagnóstico:
```bash
# Ver logs de todos os serviços
docker-compose -f docker-compose.prod.yml logs -f

# Ver status dos containers
docker-compose -f docker-compose.prod.yml ps

# Verificar recursos do sistema
htop
df -h
free -h

# Testar conectividade
curl -I https://seu-dominio.com
curl -I https://api.seu-dominio.com/health

# Verificar certificados SSL
openssl s_client -connect seu-dominio.com:443 -servername seu-dominio.com

# Reiniciar serviços específicos
docker-compose -f docker-compose.prod.yml restart backend
docker-compose -f docker-compose.prod.yml restart nginx
```

Este guia fornece uma implementação completa e robusta para produção com monitoramento avançado, backups automatizados e alta disponibilidade! 🚀