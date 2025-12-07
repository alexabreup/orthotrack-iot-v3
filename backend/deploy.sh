#!/bin/bash

# Script de Deploy para Servidor VPS Ubuntu
# OrthoTrack IoT Platform - Backend Go

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
APP_NAME="orthotrack-backend"
DEPLOY_USER="root"
DEPLOY_HOST=""
DEPLOY_DIR="/opt/orthotrack"
DOCKER_COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
DEFAULT_PORT=8080
DEFAULT_MQTT_PORT=1883
DEFAULT_POSTGRES_PORT=5432
DEFAULT_REDIS_PORT=6379

# Funções
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se uma porta está em uso
check_port() {
    local host=$1
    local port=$2
    if ssh_with_password "$DEPLOY_USER@$host" "netstat -tuln | grep -q :$port"; then
        return 0  # Porta em uso
    else
        return 1  # Porta livre
    fi
}

# Função para encontrar uma porta livre
find_free_port() {
    local host=$1
    local base_port=$2
    local port=$base_port
    
    while check_port "$host" "$port"; do
        port=$((port + 1))
        if [ $port -gt $((base_port + 100)) ]; then
            print_error "Não foi possível encontrar uma porta livre a partir de $base_port"
            exit 1
        fi
    done
    
    echo $port
}

# Verificar argumentos
if [ $# -lt 1 ]; then
    print_error "Uso: $0 <server-ip> [--production] [--port=XXXX]"
    print_info "Exemplo: $0 192.168.1.100 --production"
    print_info "Exemplo: $0 192.168.1.100 --port=8081"
    exit 1
fi

DEPLOY_HOST=$1
IS_PRODUCTION=""
CUSTOM_PORT=""

# Processar argumentos
for arg in "${@:2}"; do
    case $arg in
        --production)
            IS_PRODUCTION="--production"
            ;;
        --port=*)
            CUSTOM_PORT="${arg#*=}"
            ;;
        *)
            print_warning "Argumento desconhecido: $arg"
            ;;
    esac
done

# Verificar se é produção
if [[ "$IS_PRODUCTION" == "--production" ]]; then
    print_warning "⚠️  DEPLOY DE PRODUÇÃO DETECTADO ⚠️"
    read -p "Tem certeza que deseja fazer deploy em produção? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deploy cancelado."
        exit 1
    fi
    ENV_MODE="production"
else
    ENV_MODE="development"
fi

print_info "🚀 Iniciando deploy do $APP_NAME para $DEPLOY_HOST"
print_info "Modo: $ENV_MODE"

# 1. Verificar conexão SSH
print_info "Verificando conexão SSH..."

# Função para SSH com password
ssh_with_password() {
    sshpass -p '6f'\''GJ.giU2GKNf8CZ5AX' ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$@"
}

# Instalar sshpass se não estiver disponível
if ! command -v sshpass &> /dev/null; then
    print_info "Instalando sshpass..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    elif command -v yum &> /dev/null; then
        sudo yum install -y sshpass
    elif command -v brew &> /dev/null; then
        brew install hudochenkov/sshpass/sshpass
    else
        print_error "sshpass não está instalado e não foi possível instalar automaticamente"
        print_info "Instale manualmente: sudo apt-get install sshpass"
        exit 1
    fi
fi

if ! ssh_with_password "$DEPLOY_USER@$DEPLOY_HOST" exit 2>/dev/null; then
    print_error "Não foi possível conectar ao servidor via SSH"
    print_info "Verifique:"
    print_info "- Se o IP está correto: $DEPLOY_HOST"
    print_info "- Se o password está correto"
    print_info "- Se o servidor está acessível"
    exit 1
fi
print_success "Conexão SSH estabelecida"

# 1.1. Verificar e definir portas livres
print_info "Verificando portas disponíveis no servidor..."

# Determinar porta principal
if [ -n "$CUSTOM_PORT" ]; then
    FINAL_PORT=$CUSTOM_PORT
    if check_port "$DEPLOY_HOST" "$FINAL_PORT"; then
        print_error "Porta $FINAL_PORT já está em uso!"
        exit 1
    fi
else
    FINAL_PORT=$(find_free_port "$DEPLOY_HOST" "$DEFAULT_PORT")
fi

# Encontrar portas livres para outros serviços
FINAL_POSTGRES_PORT=$(find_free_port "$DEPLOY_HOST" "$DEFAULT_POSTGRES_PORT")
FINAL_REDIS_PORT=$(find_free_port "$DEPLOY_HOST" "$DEFAULT_REDIS_PORT")
FINAL_MQTT_PORT=$(find_free_port "$DEPLOY_HOST" "$DEFAULT_MQTT_PORT")
FINAL_MQTT_WS_PORT=$(find_free_port "$DEPLOY_HOST" 9001)

print_success "Portas definidas:"
print_info "  - API Backend: $FINAL_PORT"
print_info "  - PostgreSQL: $FINAL_POSTGRES_PORT"
print_info "  - Redis: $FINAL_REDIS_PORT"
print_info "  - MQTT: $FINAL_MQTT_PORT"
print_info "  - MQTT WebSocket: $FINAL_MQTT_WS_PORT"

# 2. Preparar arquivos localmente
print_info "Preparando arquivos para deploy..."

# Verificar se os arquivos necessários existem
REQUIRED_FILES=("Dockerfile" "docker-compose.yml" ".env.example")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Arquivo obrigatório não encontrado: $file"
        exit 1
    fi
done

# Criar arquivo temporário com configurações
TEMP_DIR=$(mktemp -d)
print_info "Diretório temporário: $TEMP_DIR"

# Copiar arquivos necessários
cp -r . "$TEMP_DIR/"
cd "$TEMP_DIR"

# Remover arquivos não necessários para o servidor
rm -rf .git .env tests/ pkg/validators/*_test.go

# Atualizar docker-compose.yml com as portas corretas
sed -i "s/\"8080:8080\"/\"$FINAL_PORT:8080\"/" docker-compose.yml
sed -i "s/\"5432:5432\"/\"$FINAL_POSTGRES_PORT:5432\"/" docker-compose.yml
sed -i "s/\"6379:6379\"/\"$FINAL_REDIS_PORT:6379\"/" docker-compose.yml
sed -i "s/\"1883:1883\"/\"$FINAL_MQTT_PORT:1883\"/" docker-compose.yml
sed -i "s/\"9001:9001\"/\"$FINAL_MQTT_WS_PORT:9001\"/" docker-compose.yml

print_success "Arquivos preparados com portas customizadas"

# 3. Enviar arquivos para o servidor
print_info "Enviando arquivos para o servidor..."

# Criar estrutura de diretórios no servidor
ssh_with_password "$DEPLOY_USER@$DEPLOY_HOST" "
    mkdir -p $DEPLOY_DIR
    chown $DEPLOY_USER:$DEPLOY_USER $DEPLOY_DIR
"

# Enviar arquivos via rsync com sshpass
rsync -avz --delete \
    --exclude='.git' \
    --exclude='tests/' \
    --exclude='*.test' \
    --exclude='.env' \
    -e "sshpass -p '6f'\"'\"'GJ.giU2GKNf8CZ5AX' ssh -o StrictHostKeyChecking=no" \
    . "$DEPLOY_USER@$DEPLOY_HOST:$DEPLOY_DIR/"

print_success "Arquivos enviados"

# 4. Configurar ambiente no servidor
print_info "Configurando ambiente no servidor..."

ssh_with_password "$DEPLOY_USER@$DEPLOY_HOST" << EOF
    cd $DEPLOY_DIR
    
    # Criar arquivo .env se não existir
    if [ ! -f .env ]; then
        cp .env.example .env
        echo "GIN_MODE=release" >> .env
        echo "APP_ENV=$ENV_MODE" >> .env
        
        # Gerar JWT secret seguro
        JWT_SECRET=\$(openssl rand -base64 32)
        sed -i "s/your-super-secret-jwt-key-change-in-production/\$JWT_SECRET/" .env
        
        # Gerar senhas aleatórias se for produção
        if [ "$ENV_MODE" = "production" ]; then
            DB_PASSWORD=\$(openssl rand -base64 16)
            REDIS_PASSWORD=\$(openssl rand -base64 16)
            MQTT_PASSWORD=\$(openssl rand -base64 16)
            
            sed -i "s/DB_PASSWORD=postgres/DB_PASSWORD=\$DB_PASSWORD/" .env
            sed -i "s/REDIS_PASSWORD=redis123/REDIS_PASSWORD=\$REDIS_PASSWORD/" .env
            sed -i "s/MQTT_PASSWORD=mqtt123/MQTT_PASSWORD=\$MQTT_PASSWORD/" .env
        fi
    fi
    
    # Ajustar permissões
    chmod 600 .env
    
    # Instalar Docker se não estiver instalado
    if ! command -v docker &> /dev/null; then
        echo "Instalando Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $DEPLOY_USER
        rm get-docker.sh
    fi
    
    # Instalar Docker Compose se não estiver instalado
    if ! command -v docker-compose &> /dev/null; then
        echo "Instalando Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi
EOF

print_success "Ambiente configurado"

# 5. Deploy da aplicação
print_info "Fazendo deploy da aplicação..."

ssh_with_password "$DEPLOY_USER@$DEPLOY_HOST" << EOF
    cd $DEPLOY_DIR
    
    # Parar containers existentes
    if [ -f docker-compose.yml ]; then
        docker-compose down || true
    fi
    
    # Fazer backup do banco se existir
    if [ "$ENV_MODE" = "production" ] && docker volume ls | grep -q orthotrack; then
        echo "Fazendo backup do banco de dados..."
        docker run --rm -v orthotrack_postgres_data:/data -v \$(pwd):/backup alpine tar czf /backup/postgres_backup_\$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
    fi
    
    # Construir e iniciar containers
    docker-compose build --no-cache
    docker-compose up -d
    
    # Aguardar serviços iniciarem
    echo "Aguardando serviços iniciarem..."
    sleep 30
    
    # Verificar se os containers estão rodando
    docker-compose ps
EOF

print_success "Deploy concluído"

# 6. Verificações pós-deploy
print_info "Executando verificações pós-deploy..."

# Verificar se a aplicação está respondendo
print_info "Verificando se a aplicação está respondendo..."
sleep 5

# Test health endpoint
if curl -f "http://$DEPLOY_HOST:$FINAL_PORT/health" >/dev/null 2>&1; then
    print_success "✅ Aplicação está respondendo corretamente"
else
    print_warning "⚠️  Aplicação pode não estar respondendo ainda"
    print_info "Verifique os logs: ssh $DEPLOY_USER@$DEPLOY_HOST 'cd $DEPLOY_DIR && docker-compose logs -f'"
fi

# 7. Informações finais
print_success "🎉 Deploy concluído com sucesso!"
echo
print_info "📋 Informações do Deploy:"
echo -e "   🖥️  Servidor: $DEPLOY_HOST"
echo -e "   📁 Diretório: $DEPLOY_DIR"
echo -e "   🌍 Ambiente: $ENV_MODE"
echo -e "   🔗 API URL: http://$DEPLOY_HOST:$FINAL_PORT"
echo -e "   📚 Swagger: http://$DEPLOY_HOST:$FINAL_PORT/swagger/index.html"
echo
print_info "🔌 Portas dos Serviços:"
echo -e "   📡 Backend API: $FINAL_PORT"
echo -e "   🗄️  PostgreSQL: $FINAL_POSTGRES_PORT"
echo -e "   🔄 Redis: $FINAL_REDIS_PORT"
echo -e "   📡 MQTT: $FINAL_MQTT_PORT"
echo -e "   🌐 MQTT WebSocket: $FINAL_MQTT_WS_PORT"
echo
print_info "📝 Comandos úteis:"
echo -e "   Logs: ssh $DEPLOY_USER@$DEPLOY_HOST 'cd $DEPLOY_DIR && docker-compose logs -f'"
echo -e "   Status: ssh $DEPLOY_USER@$DEPLOY_HOST 'cd $DEPLOY_DIR && docker-compose ps'"
echo -e "   Restart: ssh $DEPLOY_USER@$DEPLOY_HOST 'cd $DEPLOY_DIR && docker-compose restart'"
echo
print_info "🔗 URLs de Acesso:"
echo -e "   API: http://$DEPLOY_HOST:$FINAL_PORT"
echo -e "   Documentação: http://$DEPLOY_HOST:$FINAL_PORT/swagger/index.html"
echo -e "   Health Check: http://$DEPLOY_HOST:$FINAL_PORT/health"
echo

# Limpeza
cd - > /dev/null
rm -rf "$TEMP_DIR"

print_success "Deploy finalizado! 🚀"