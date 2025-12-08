#!/bin/bash

# 🚀 Script de Implementação dos Serviços OrthoTrack IoT V3
# Executa backup, preparação do ambiente e transferência de arquivos

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
SERVER="root@72.60.50.248"
REMOTE_DIR="/opt/orthotrack-v3"
LOCAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${LOCAL_DIR}"

# Funções auxiliares
print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Verificar conexão SSH
check_ssh_connection() {
    print_step "Verificando conexão SSH com o servidor..."
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no ${SERVER} "echo 'Conexão OK'" 2>/dev/null; then
        print_success "Conexão SSH estabelecida"
        return 0
    else
        print_error "Não foi possível conectar ao servidor ${SERVER}"
        echo ""
        echo "Verifique:"
        echo "  - Conexão com a internet"
        echo "  - IP do servidor: 72.60.50.248"
        echo "  - Acesso SSH configurado (chave SSH ou senha)"
        echo "  - Firewall permitindo conexão SSH"
        return 1
    fi
}

# 1. PREPARAÇÃO - Backup e preparação do ambiente
prepare_environment() {
    print_header "1. PREPARAÇÃO - Backup e Preparação do Ambiente"
    
    print_step "Executando backup do banco de dados atual..."
    
    # Executar comandos de preparação no servidor remoto
    ssh ${SERVER} << 'PREPARE_EOF'
set -e

echo "📦 Fazendo backup do banco de dados atual..."

# Verificar se o container PostgreSQL existe
if docker ps -a | grep -q orthotrack-postgres; then
    BACKUP_FILE="/root/backup_orthotrack_$(date +%Y%m%d_%H%M%S).sql"
    
    # Tentar fazer backup
    if docker exec orthotrack-postgres pg_dump -U postgres orthotrack > "$BACKUP_FILE" 2>/dev/null || \
       docker exec orthotrack-postgres pg_dump -U orthotrack orthotrack > "$BACKUP_FILE" 2>/dev/null || \
       docker exec orthotrack-postgres pg_dump -U postgres orthotrack_v3 > "$BACKUP_FILE" 2>/dev/null; then
        echo "✓ Backup criado: $BACKUP_FILE"
        ls -lh "$BACKUP_FILE"
    else
        echo "⚠ Não foi possível fazer backup (banco pode não existir ou estar vazio)"
    fi
else
    echo "⚠ Container PostgreSQL não encontrado, pulando backup"
fi

echo ""
echo "💾 Verificando espaço em disco..."
df -h | grep -E '^/dev|Filesystem'

echo ""
echo "📁 Criando diretório de trabalho..."
mkdir -p /opt/orthotrack-v3
chmod 755 /opt/orthotrack-v3
echo "✓ Diretório criado: /opt/orthotrack-v3"

echo ""
echo "✅ Preparação concluída!"
PREPARE_EOF

    if [ $? -eq 0 ]; then
        print_success "Preparação do ambiente concluída"
    else
        print_error "Erro durante a preparação do ambiente"
        return 1
    fi
}

# 2. TRANSFERÊNCIA DE ARQUIVOS - Enviar código para o servidor
transfer_files() {
    print_header "2. TRANSFERÊNCIA DE ARQUIVOS - Enviar Código para o Servidor"
    
    print_step "Verificando diretório local..."
    if [ ! -d "${BACKEND_DIR}" ]; then
        print_error "Diretório backend não encontrado: ${BACKEND_DIR}"
        return 1
    fi
    print_success "Diretório local verificado: ${BACKEND_DIR}"
    
    print_step "Iniciando transferência de arquivos via rsync..."
    echo "  Origem: ${BACKEND_DIR}/"
    echo "  Destino: ${SERVER}:${REMOTE_DIR}/"
    echo ""
    
    # Verificar se rsync está disponível
    if ! command -v rsync &> /dev/null; then
        print_error "rsync não está instalado"
        echo "  Instale com: sudo apt-get install rsync"
        return 1
    fi
    
    # Executar rsync
    rsync -avz --progress \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude 'dist' \
        --exclude '*.log' \
        --exclude '.env' \
        --exclude '.env.local' \
        --exclude '*.swp' \
        --exclude '*.swo' \
        --exclude '*~' \
        --exclude '.DS_Store' \
        --exclude 'orthotrack-iot-v3' \
        "${BACKEND_DIR}/" \
        "${SERVER}:${REMOTE_DIR}/"
    
    if [ $? -eq 0 ]; then
        print_success "Transferência de arquivos concluída"
    else
        print_error "Erro durante a transferência de arquivos"
        return 1
    fi
    
    # Configurar permissões dos scripts no servidor
    print_step "Configurando permissões dos scripts..."
    ssh ${SERVER} "cd ${REMOTE_DIR} && chmod +x *.sh 2>/dev/null || true"
    print_success "Permissões configuradas"
}

# 3. VERIFICAÇÃO - Verificar arquivos transferidos
verify_transfer() {
    print_header "3. VERIFICAÇÃO - Verificar Arquivos Transferidos"
    
    print_step "Verificando arquivos essenciais no servidor..."
    
    ssh ${SERVER} << 'VERIFY_EOF'
cd /opt/orthotrack-v3

echo "Verificando arquivos essenciais..."
MISSING_FILES=0

# Lista de arquivos essenciais
ESSENTIAL_FILES=(
    "docker-compose.yml"
    "docker-compose.services.yml"
    "Dockerfile"
    "go.mod"
    "cmd/api/main.go"
)

for file in "${ESSENTIAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (NÃO ENCONTRADO)"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

echo ""
if [ $MISSING_FILES -eq 0 ]; then
    echo "✅ Todos os arquivos essenciais estão presentes"
else
    echo "⚠ $MISSING_FILES arquivo(s) essencial(is) não encontrado(s)"
fi

echo ""
echo "Estrutura de diretórios:"
ls -la | head -20
VERIFY_EOF

    if [ $? -eq 0 ]; then
        print_success "Verificação concluída"
    else
        print_warning "Alguns arquivos podem estar faltando"
    fi
}

# 4. PRÓXIMOS PASSOS - Instruções
show_next_steps() {
    print_header "4. PRÓXIMOS PASSOS"
    
    echo -e "${GREEN}✅ Implementação dos arquivos concluída!${NC}"
    echo ""
    echo "Para continuar com a instalação, execute no servidor:"
    echo ""
    echo -e "${CYAN}  ssh ${SERVER}${NC}"
    echo -e "${CYAN}  cd ${REMOTE_DIR}${NC}"
    echo ""
    echo "Opções disponíveis:"
    echo ""
    echo "1. Configurar variáveis de ambiente:"
    echo "   - Copie .env.example para .env"
    echo "   - Edite .env com suas configurações"
    echo ""
    echo "2. Iniciar serviços com Docker Compose:"
    echo "   - docker-compose up -d"
    echo "   - ou ./start-services.sh (se disponível)"
    echo ""
    echo "3. Verificar status dos serviços:"
    echo "   - docker-compose ps"
    echo "   - docker-compose logs -f"
    echo ""
    echo "4. Verificar saúde da aplicação:"
    echo "   - curl http://localhost:8080/health"
    echo ""
}

# Função principal
main() {
    clear
    print_header "🚀 IMPLEMENTAÇÃO DOS SERVIÇOS ORTHOTRACK IOT V3"
    
    echo "Servidor: ${SERVER}"
    echo "Diretório remoto: ${REMOTE_DIR}"
    echo "Diretório local: ${BACKEND_DIR}"
    echo ""
    
    # Verificar conexão SSH
    if ! check_ssh_connection; then
        exit 1
    fi
    
    echo ""
    read -p "Deseja continuar com a implementação? (s/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_warning "Implementação cancelada pelo usuário"
        exit 0
    fi
    
    # Executar etapas
    prepare_environment || exit 1
    echo ""
    
    transfer_files || exit 1
    echo ""
    
    verify_transfer || true
    echo ""
    
    show_next_steps
    
    print_header "🎉 IMPLEMENTAÇÃO CONCLUÍDA"
}

# Executar função principal
main







