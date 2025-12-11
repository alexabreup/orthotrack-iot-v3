#!/bin/bash
# deploy.sh - Script de deploy manual do OrthoTrack IoT v3

set -e

# Configurações
COMPOSE_FILE="/opt/orthotrack/docker-compose.prod.yml"
BACKUP_SCRIPT="/opt/orthotrack/scripts/backup.sh"
HEALTH_SCRIPT="/opt/orthotrack/scripts/health-check.sh"
LOG_FILE="/var/log/orthotrack/deploy.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}" | tee -a "$LOG_FILE"
}

# Verificar se está rodando como root ou com sudo
if [ "$EUID" -ne 0 ]; then
    error "Este script deve ser executado como root ou com sudo"
fi

# Função de ajuda
show_help() {
    echo "OrthoTrack IoT v3 - Deploy Script"
    echo ""
    echo "Uso: $0 [OPÇÕES]"
    echo ""
    echo "Opções:"
    echo "  -h, --help              Mostrar esta ajuda"
    echo "  -b, --backup            Fazer backup antes do deploy"
    echo "  -f, --force             Forçar deploy sem confirmação"
    echo "  -t, --tag TAG           Usar tag específica das imagens"
    echo "  -r, --rollback          Fazer rollback para versão anterior"
    echo "  --no-health-check       Pular verificação de saúde"
    echo "  --pull-only             Apenas fazer pull das imagens"
    echo ""
    echo "Exemplos:"
    echo "  $0 -b                   Deploy com backup"
    echo "  $0 -t v1.2.3           Deploy da versão v1.2.3"
    echo "  $0 -r                   Rollback para versão anterior"
}

# Variáveis padrão
DO_BACKUP=false
FORCE_DEPLOY=false
IMAGE_TAG="latest"
DO_ROLLBACK=false
SKIP_HEALTH_CHECK=false
PULL_ONLY=false

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--backup)
            DO_BACKUP=true
            shift
            ;;
        -f|--force)
            FORCE_DEPLOY=true
            shift
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -r|--rollback)
            DO_ROLLBACK=true
            shift
            ;;
        --no-health-check)
            SKIP_HEALTH_CHECK=true
            shift
            ;;
        --pull-only)
            PULL_ONLY=true
            shift
            ;;
        *)
            error "Opção desconhecida: $1"
            ;;
    esac
done

# Criar diretório de log
mkdir -p "$(dirname "$LOG_FILE")"

log "🚀 Iniciando deploy do OrthoTrack IoT v3..."

# Verificar se o Docker está rodando
if ! docker info >/dev/null 2>&1; then
    error "Docker não está rodando"
fi

# Verificar se o arquivo docker-compose existe
if [ ! -f "$COMPOSE_FILE" ]; then
    error "Arquivo docker-compose não encontrado: $COMPOSE_FILE"
fi

# Mudar para o diretório do projeto
cd /opt/orthotrack

# Função de rollback
do_rollback() {
    log "🔄 Iniciando processo de rollback..."
    
    # Obter a tag anterior
    local previous_tag=$(docker images --format 'table {{.Repository}}:{{.Tag}}' | grep orthotrack-backend | grep -v latest | head -2 | tail -1 | cut -d':' -f2)
    
    if [ -n "$previous_tag" ]; then
        log "📦 Fazendo rollback para tag: $previous_tag"
        
        # Atualizar docker-compose com a tag anterior
        sed -i "s|image: .*/orthotrack-backend:.*|image: orthotrack/orthotrack-backend:$previous_tag|g" "$COMPOSE_FILE"
        sed -i "s|image: .*/orthotrack-frontend:.*|image: orthotrack/orthotrack-frontend:$previous_tag|g" "$COMPOSE_FILE"
        
        # Deploy da versão anterior
        docker-compose -f "$COMPOSE_FILE" up -d --remove-orphans
        
        log "✅ Rollback concluído para versão: $previous_tag"
    else
        error "❌ Nenhuma versão anterior encontrada para rollback"
    fi
}

# Função de backup
do_backup_if_requested() {
    if [ "$DO_BACKUP" = true ]; then
        log "💾 Fazendo backup antes do deploy..."
        if [ -f "$BACKUP_SCRIPT" ]; then
            bash "$BACKUP_SCRIPT"
        else
            warn "Script de backup não encontrado: $BACKUP_SCRIPT"
        fi
    fi
}

# Função para verificar saúde dos serviços
check_health() {
    if [ "$SKIP_HEALTH_CHECK" = false ]; then
        log "🏥 Verificando saúde dos serviços..."
        sleep 30  # Aguardar serviços iniciarem
        
        if [ -f "$HEALTH_SCRIPT" ]; then
            bash "$HEALTH_SCRIPT"
        else
            warn "Script de health check não encontrado: $HEALTH_SCRIPT"
            
            # Health check básico
            local failed_services=()
            
            # Verificar se containers estão rodando
            for service in postgres redis mqtt backend frontend nginx; do
                if ! docker-compose -f "$COMPOSE_FILE" ps "$service" | grep -q "Up"; then
                    failed_services+=("$service")
                fi
            done
            
            if [ ${#failed_services[@]} -eq 0 ]; then
                log "✅ Todos os serviços estão rodando"
            else
                error "❌ Serviços com falha: ${failed_services[*]}"
            fi
        fi
    fi
}

# Função principal de deploy
do_deploy() {
    log "📦 Iniciando processo de deploy..."
    
    # Fazer backup se solicitado
    do_backup_if_requested
    
    # Atualizar imagens Docker
    log "📥 Fazendo pull das imagens Docker..."
    if [ "$IMAGE_TAG" != "latest" ]; then
        # Usar tag específica
        docker pull "orthotrack/orthotrack-backend:$IMAGE_TAG"
        docker pull "orthotrack/orthotrack-frontend:$IMAGE_TAG"
        
        # Atualizar docker-compose
        sed -i "s|image: .*/orthotrack-backend:.*|image: orthotrack/orthotrack-backend:$IMAGE_TAG|g" "$COMPOSE_FILE"
        sed -i "s|image: .*/orthotrack-frontend:.*|image: orthotrack/orthotrack-frontend:$IMAGE_TAG|g" "$COMPOSE_FILE"
    else
        docker-compose -f "$COMPOSE_FILE" pull
    fi
    
    if [ "$PULL_ONLY" = true ]; then
        log "✅ Pull das imagens concluído. Saindo (--pull-only especificado)."
        return 0
    fi
    
    # Deploy com zero downtime
    log "🚀 Fazendo deploy dos serviços..."
    docker-compose -f "$COMPOSE_FILE" up -d --remove-orphans
    
    # Aguardar serviços ficarem prontos
    log "⏳ Aguardando serviços ficarem prontos..."
    sleep 10
    
    # Verificar saúde
    check_health
    
    # Limpeza de imagens antigas
    log "🧹 Limpando imagens Docker antigas..."
    docker image prune -f
    
    log "✅ Deploy concluído com sucesso!"
}

# Confirmação antes do deploy (se não forçado)
if [ "$FORCE_DEPLOY" = false ] && [ "$DO_ROLLBACK" = false ]; then
    echo ""
    echo "🚀 OrthoTrack IoT v3 Deploy"
    echo "=========================="
    echo "Tag das imagens: $IMAGE_TAG"
    echo "Fazer backup: $DO_BACKUP"
    echo "Arquivo compose: $COMPOSE_FILE"
    echo ""
    read -p "Continuar com o deploy? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "❌ Deploy cancelado pelo usuário"
        exit 0
    fi
fi

# Executar ação solicitada
if [ "$DO_ROLLBACK" = true ]; then
    do_rollback
else
    do_deploy
fi

# Mostrar status final
log "📊 Status final dos serviços:"
docker-compose -f "$COMPOSE_FILE" ps

# Mostrar URLs importantes
log "🌐 URLs do sistema:"
log "   - Frontend: https://orthotrack.alexptech.com"
log "   - API: https://api.orthotrack.alexptech.com"
log "   - Health Check: https://orthotrack.alexptech.com/health"

log "🎉 Processo concluído!"