#!/bin/bash

# Deploy Manual sem dependências do sistema
# Use este script se não conseguir instalar sshpass

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configurações do servidor
VPS_IP="72.60.50.248"
VPS_USER="root"
DEPLOY_DIR="/opt/orthotrack"

echo "🚀 Deploy Manual OrthoTrack IoT para VPS $VPS_IP"
echo
print_warning "IMPORTANTE: Este script irá solicitar a senha do VPS várias vezes"
print_warning "Senha do VPS: 6f'GJ.giU2GKNf8CZ5AX"
echo
read -p "Pressione Enter para continuar..."

# Verificar conexão
print_info "Verificando conexão com VPS..."
if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" exit; then
    print_error "Falha na conexão SSH com $VPS_IP"
    print_info "Execute: ssh $VPS_USER@$VPS_IP"
    print_info "E use a senha: 6f'GJ.giU2GKNf8CZ5AX"
    exit 1
fi
print_success "Conexão estabelecida"

# Encontrar portas livres
print_info "Verificando portas disponíveis..."
BACKEND_PORT=$(ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" 'for port in {8080..8099}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')
POSTGRES_PORT=$(ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" 'for port in {5432..5439}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')
REDIS_PORT=$(ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" 'for port in {6379..6385}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')
MQTT_PORT=$(ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" 'for port in {1883..1890}; do ! netstat -tuln | grep -q ":$port" && echo $port && break; done')

if [ -z "$BACKEND_PORT" ]; then BACKEND_PORT=8080; fi
if [ -z "$POSTGRES_PORT" ]; then POSTGRES_PORT=5432; fi
if [ -z "$REDIS_PORT" ]; then REDIS_PORT=6379; fi
if [ -z "$MQTT_PORT" ]; then MQTT_PORT=1883; fi

print_success "Portas definidas:"
print_info "  Backend: $BACKEND_PORT"
print_info "  PostgreSQL: $POSTGRES_PORT"  
print_info "  Redis: $REDIS_PORT"
print_info "  MQTT: $MQTT_PORT"

# Preparar arquivos
print_info "Preparando arquivos..."
TEMP_DIR=$(mktemp -d)
cp -r . "$TEMP_DIR/"
cd "$TEMP_DIR"

# Remover arquivos desnecessários
rm -rf .git .env tests/ pkg/validators/*_test.go

# Atualizar docker-compose com portas corretas
sed -i "s/\"8080:8080\"/\"$BACKEND_PORT:8080\"/" docker-compose.yml
sed -i "s/\"5432:5432\"/\"$POSTGRES_PORT:5432\"/" docker-compose.yml
sed -i "s/\"6379:6379\"/\"$REDIS_PORT:6379\"/" docker-compose.yml
sed -i "s/\"1883:1883\"/\"$MQTT_PORT:1883\"/" docker-compose.yml

# Criar .env local
cat > .env << 'ENVEOF'
# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_DATABASE=orthotrack
DB_USERNAME=postgres
DB_PASSWORD=postgres_secure_2024

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=redis_secure_2024

# MQTT Configuration
MQTT_HOST=mqtt
MQTT_PORT=1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=mqtt_secure_2024

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key-production-2024

# Server Configuration
PORT=8080
GIN_MODE=release

# IoT Alert Thresholds
IOT_ALERT_BATTERY_LOW=20
IOT_ALERT_TEMP_HIGH=45.0
IOT_ALERT_TEMP_LOW=5.0

# AI Configuration
AI_PROVIDER=openai
AI_API_KEY=your-openai-api-key-here
AI_MODEL=gpt-4

# Environment
APP_ENV=production
ENVEOF

print_success "Arquivos preparados"

# Criar estrutura no servidor
print_info "Criando estrutura no servidor..."
ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "mkdir -p $DEPLOY_DIR && chown $VPS_USER:$VPS_USER $DEPLOY_DIR"

# Enviar arquivos
print_info "Enviando arquivos (digite a senha quando solicitado)..."
rsync -avz --delete \
    --exclude='.git' \
    --exclude='tests/' \
    . "$VPS_USER@$VPS_IP:$DEPLOY_DIR/"

# Configurar e iniciar no servidor
print_info "Configurando e iniciando no servidor..."
ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" << 'EOF'
cd /opt/orthotrack

# Instalar Docker se necessário
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
fi

# Instalar Docker Compose se necessário
if ! command -v docker-compose &> /dev/null; then
    echo "Instalando Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# Parar containers existentes
docker-compose down 2>/dev/null || true

# Fazer backup se existir
if docker volume ls | grep -q orthotrack 2>/dev/null; then
    echo "Fazendo backup..."
    docker run --rm -v orthotrack_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data . 2>/dev/null || true
fi

# Iniciar serviços
echo "Iniciando serviços..."
docker-compose up -d --build

# Aguardar inicialização
echo "Aguardando inicialização..."
sleep 30

# Verificar status
echo "Status dos containers:"
docker-compose ps
EOF

print_success "Deploy concluído!"

# Verificar aplicação
print_info "Verificando aplicação..."
sleep 5
if curl -f "http://$VPS_IP:$BACKEND_PORT/health" >/dev/null 2>&1; then
    print_success "✅ Aplicação respondendo"
else
    print_warning "⚠️  Verificando se a aplicação está respondendo..."
    print_info "Testando conexão em: http://$VPS_IP:$BACKEND_PORT"
fi

# Informações finais
print_success "🎉 Deploy completo!"
echo
print_info "📋 Informações do Deploy:"
echo -e "   🖥️  Servidor: $VPS_IP"
echo -e "   👤 Usuário: $VPS_USER"
echo -e "   📁 Diretório: $DEPLOY_DIR"
echo
print_info "🔗 URLs de Acesso:"
echo -e "   API: http://$VPS_IP:$BACKEND_PORT"
echo -e "   Swagger: http://$VPS_IP:$BACKEND_PORT/swagger/index.html"
echo -e "   Health: http://$VPS_IP:$BACKEND_PORT/health"
echo
print_info "🔌 Portas dos Serviços:"
echo -e "   📡 Backend: $BACKEND_PORT"
echo -e "   🗄️  PostgreSQL: $POSTGRES_PORT"
echo -e "   🔄 Redis: $REDIS_PORT"
echo -e "   📡 MQTT: $MQTT_PORT"
echo
print_info "📝 Comandos úteis:"
echo -e "   Logs: ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose logs -f'"
echo -e "   Status: ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose ps'"
echo -e "   Restart: ssh $VPS_USER@$VPS_IP 'cd $DEPLOY_DIR && docker-compose restart'"

# Limpeza
cd - > /dev/null
rm -rf "$TEMP_DIR"

print_success "Deploy finalizado! 🚀"