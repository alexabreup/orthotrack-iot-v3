#!/bin/bash

# Fix Deploy - Corrigir problemas do deploy anterior

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

VPS_IP="72.60.50.248"
VPS_USER="root"
VPS_PASSWORD="6f'GJ.giU2GKNf8CZ5AX"

echo "🔧 Corrigindo deploy anterior..."

# Verificar se sshpass está disponível
if ! command -v sshpass &> /dev/null; then
    print_error "sshpass não instalado. Execute: sudo apt install sshpass"
    exit 1
fi

# Função SSH
ssh_exec() {
    sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "$@"
}

print_info "Conectando ao servidor para correções..."

# Corrigir docker-compose.yml removendo bind mount problemático
ssh_exec << 'EOF'
cd /opt/orthotrack

# Corrigir docker-compose.yml - remover volume de migrações problemático
sed -i '/migrations:/d' docker-compose.yml
sed -i '/docker-entrypoint-initdb.d/d' docker-compose.yml

# Verificar se arquivo existe
echo "Arquivo docker-compose.yml corrigido:"
grep -A5 -B5 volumes docker-compose.yml || true

# Parar todos os containers
docker-compose down

# Remover containers e volumes antigos se necessário
docker system prune -f

# Iniciar novamente
echo "Iniciando containers corrigidos..."
docker-compose up -d

# Aguardar inicialização
sleep 30

# Verificar status
echo "Status final:"
docker-compose ps

# Verificar logs do backend
echo "Logs do backend:"
docker-compose logs backend | tail -20

# Testar endpoints básicos
echo "Testando conectividade interna..."
docker-compose exec backend wget -q --spider http://localhost:8080/health && echo "Backend health OK" || echo "Backend health FAIL"

EOF

print_info "Verificando aplicação externamente..."
sleep 5

# Encontrar a porta do backend
BACKEND_PORT=$(ssh_exec 'docker-compose ps --format "table {{.Service}}\t{{.Ports}}" | grep backend | grep -o "[0-9]*:8080" | cut -d: -f1')

if [ -z "$BACKEND_PORT" ]; then
    # Buscar na configuração
    BACKEND_PORT=$(ssh_exec 'grep -o "\"[0-9]*:8080\"" docker-compose.yml | cut -d\" -f2 | cut -d: -f1')
fi

if [ -z "$BACKEND_PORT" ]; then
    BACKEND_PORT=8082  # fallback para porta que vimos no log
fi

print_info "Testando aplicação na porta: $BACKEND_PORT"

if curl -f "http://$VPS_IP:$BACKEND_PORT/health" >/dev/null 2>&1; then
    print_success "✅ Aplicação funcionando!"
else
    print_info "Testando outras portas possíveis..."
    for port in 8080 8081 8082 8083; do
        print_info "Testando porta $port..."
        if curl -f "http://$VPS_IP:$port/health" >/dev/null 2>&1; then
            print_success "✅ Aplicação funcionando na porta $port!"
            BACKEND_PORT=$port
            break
        fi
    done
fi

print_success "🎉 Correção concluída!"
echo
print_info "🔗 URLs de Acesso:"
echo -e "   API: http://$VPS_IP:$BACKEND_PORT"
echo -e "   Swagger: http://$VPS_IP:$BACKEND_PORT/swagger/index.html"
echo -e "   Health: http://$VPS_IP:$BACKEND_PORT/health"
echo
print_info "📝 Verificar logs:"
echo -e "   sshpass -p '$VPS_PASSWORD' ssh $VPS_USER@$VPS_IP 'cd /opt/orthotrack && docker-compose logs -f'"