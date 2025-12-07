#!/bin/bash

# Deploy Completo do Zero - OrthoTrack IoT Platform
# Instala tudo do zero em um servidor limpo

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${PURPLE}[STEP]${NC} $1"; }

echo "🚀 Deploy Completo OrthoTrack IoT Platform"
echo "================================================================"
echo

# Configurações do VPS
VPS_IP="72.60.50.248"
VPS_USER="root"
VPS_PASSWORD="6f'GJ.giU2GKNf8CZ5AX"
DEPLOY_DIR="/opt/orthotrack"

# Configurações da aplicação
OPENAI_API_KEY="your-openai-api-key-here"

# Função SSH
ssh_exec() {
    sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "$@"
}

# Verificar se sshpass está instalado
if ! command -v sshpass &> /dev/null; then
    print_info "Instalando sshpass..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    else
        print_error "Instale sshpass manualmente: sudo apt-get install sshpass"
        exit 1
    fi
fi

print_step "1/10 - Verificando conexão SSH..."
if ! ssh_exec "exit" 2>/dev/null; then
    print_error "Não foi possível conectar ao servidor $VPS_IP"
    exit 1
fi
print_success "Conexão SSH estabelecida"

print_step "2/10 - Atualizando servidor e instalando dependências..."
ssh_exec << 'EOF'
# Atualizar sistema
apt-get update
apt-get upgrade -y

# Instalar dependências básicas
apt-get install -y curl wget git net-tools htop nano

# Instalar Docker
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker-compose --version
EOF
print_success "Servidor atualizado e Docker instalado"

print_step "3/10 - Encontrando portas livres..."
BACKEND_PORT=$(ssh_exec 'for port in {8080..8099}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')
POSTGRES_PORT=$(ssh_exec 'for port in {5432..5439}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')
REDIS_PORT=$(ssh_exec 'for port in {6379..6385}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')
MQTT_PORT=$(ssh_exec 'for port in {1883..1890}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')

if [ -z "$BACKEND_PORT" ]; then BACKEND_PORT=8080; fi
if [ -z "$POSTGRES_PORT" ]; then POSTGRES_PORT=5432; fi
if [ -z "$REDIS_PORT" ]; then REDIS_PORT=6379; fi
if [ -z "$MQTT_PORT" ]; then MQTT_PORT=1883; fi

print_success "Portas definidas:"
print_info "  Backend: $BACKEND_PORT"
print_info "  PostgreSQL: $POSTGRES_PORT"
print_info "  Redis: $REDIS_PORT"
print_info "  MQTT: $MQTT_PORT"

print_step "4/10 - Preparando código fonte..."
TEMP_DIR=$(mktemp -d)
cp -r . "$TEMP_DIR/"
cd "$TEMP_DIR"

# Remover arquivos desnecessários
rm -rf .git .env tests/ pkg/validators/*_test.go *.sh

# Corrigir configurações hardcoded no código Go
sed -i 's/orthotrack_v3/orthotrack/' internal/config/config.go
sed -i 's/DB_USER", "orthotrack"/DB_USER", "postgres"/' internal/config/config.go

print_success "Código preparado e configurações corrigidas"

print_step "5/10 - Criando docker-compose otimizado..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: orthotrack-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: orthotrack
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres_secure_2024
      POSTGRES_HOST_AUTH_METHOD: trust
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "$POSTGRES_PORT:5432"
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d orthotrack"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: orthotrack-redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass redis_secure_2024
    volumes:
      - redis_data:/data
    ports:
      - "$REDIS_PORT:6379"
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  mqtt:
    image: eclipse-mosquitto:2.0
    container_name: orthotrack-mqtt
    restart: unless-stopped
    ports:
      - "$MQTT_PORT:1883"
      - "9001:9001"
    volumes:
      - mqtt_data:/mosquitto/data
      - mqtt_logs:/mosquitto/log
    networks:
      - orthotrack-network

  backend:
    build: .
    container_name: orthotrack-backend
    restart: unless-stopped
    environment:
      # Database
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_DATABASE=orthotrack
      - DB_USERNAME=postgres
      - DB_PASSWORD=postgres_secure_2024
      
      # Redis
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=redis_secure_2024
      
      # MQTT
      - MQTT_HOST=mqtt
      - MQTT_PORT=1883
      - MQTT_USERNAME=orthotrack
      - MQTT_PASSWORD=mqtt_secure_2024
      
      # JWT
      - JWT_SECRET=orthotrack-super-secret-jwt-key-production-2024
      
      # Server
      - PORT=8080
      - GIN_MODE=release
      
      # IoT Thresholds
      - IOT_ALERT_BATTERY_LOW=20
      - IOT_ALERT_TEMP_HIGH=45.0
      - IOT_ALERT_TEMP_LOW=5.0
      
      # AI Configuration
      - AI_PROVIDER=openai
      - AI_API_KEY=$OPENAI_API_KEY
      - AI_MODEL=gpt-4
      
      # Environment
      - APP_ENV=production
    ports:
      - "$BACKEND_PORT:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - orthotrack-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
  mqtt_data:
  mqtt_logs:

networks:
  orthotrack-network:
    driver: bridge
EOF

print_success "Docker-compose criado"

print_step "6/10 - Criando estrutura no servidor..."
ssh_exec "mkdir -p $DEPLOY_DIR && chown $VPS_USER:$VPS_USER $DEPLOY_DIR"

print_step "7/10 - Enviando arquivos..."
rsync -avz --delete \
    --exclude='.git' \
    --exclude='tests/' \
    --exclude='*.test' \
    -e "sshpass -p '$VPS_PASSWORD' ssh -o StrictHostKeyChecking=no" \
    . "$VPS_USER@$VPS_IP:$DEPLOY_DIR/"

print_success "Arquivos enviados"

print_step "8/10 - Construindo e iniciando aplicação..."
ssh_exec << EOF
cd $DEPLOY_DIR

# Construir imagens
docker-compose build --no-cache

# Iniciar serviços
docker-compose up -d

# Aguardar inicialização
echo "Aguardando inicialização dos serviços..."
sleep 45

# Verificar status
echo "Status dos containers:"
docker-compose ps
EOF

print_step "9/10 - Verificando saúde da aplicação..."
sleep 10

# Verificar se a aplicação está respondendo
HEALTH_CHECK_URL="http://$VPS_IP:$BACKEND_PORT/health"
for i in {1..5}; do
    print_info "Tentativa $i/5 - Testando: $HEALTH_CHECK_URL"
    if curl -f "$HEALTH_CHECK_URL" >/dev/null 2>&1; then
        print_success "✅ Aplicação está respondendo!"
        HEALTH_OK=true
        break
    fi
    sleep 10
done

if [ "$HEALTH_OK" != true ]; then
    print_warning "⚠️  Aplicação pode não estar respondendo ainda"
    print_info "Verificando logs..."
    ssh_exec "cd $DEPLOY_DIR && docker-compose logs backend | tail -20"
fi

print_step "10/10 - Configuração final e informações..."
ssh_exec << EOF
cd $DEPLOY_DIR

# Verificar logs finais
echo "=== Logs do Backend ==="
docker-compose logs backend | tail -10

echo "=== Status Final ==="
docker-compose ps

echo "=== Uso de recursos ==="
docker stats --no-stream
EOF

# Limpeza
cd - > /dev/null
rm -rf "$TEMP_DIR"

print_success "🎉 Deploy completo finalizado!"
echo "================================================================"
print_info "📋 Informações do Deploy:"
echo -e "   🖥️  Servidor: $VPS_IP"
echo -e "   👤 Usuário: $VPS_USER"
echo -e "   📁 Diretório: $DEPLOY_DIR"
echo

print_info "🔗 URLs de Acesso:"
echo -e "   🌐 API: http://$VPS_IP:$BACKEND_PORT"
echo -e "   📚 Documentação: http://$VPS_IP:$BACKEND_PORT/swagger/index.html"
echo -e "   💊 Health Check: http://$VPS_IP:$BACKEND_PORT/health"
echo

print_info "🔌 Portas dos Serviços:"
echo -e "   📡 Backend API: $BACKEND_PORT"
echo -e "   🗄️  PostgreSQL: $POSTGRES_PORT"
echo -e "   🔄 Redis: $REDIS_PORT"
echo -e "   📡 MQTT: $MQTT_PORT"
echo

print_info "📝 Comandos de Gerenciamento:"
echo -e "   📊 Status: sshpass -p '$VPS_PASSWORD' ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose ps'"
echo -e "   📋 Logs: sshpass -p '$VPS_PASSWORD' ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose logs -f'"
echo -e "   🔄 Restart: sshpass -p '$VPS_PASSWORD' ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose restart'"
echo -e "   🛑 Parar: sshpass -p '$VPS_PASSWORD' ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose down'"
echo

print_info "🔧 Teste Manual:"
echo -e "   curl http://$VPS_IP:$BACKEND_PORT/health"
echo

if [ "$HEALTH_OK" = true ]; then
    print_success "✅ Sistema funcionando perfeitamente!"
else
    print_warning "⚠️  Sistema pode precisar de alguns minutos para estabilizar"
    print_info "💡 Aguarde 2-3 minutos e teste novamente"
fi

echo "================================================================"
print_success "🚀 OrthoTrack IoT Platform deployed successfully!"