#!/bin/bash

# Script de Limpeza Completa do Servidor Ubuntu
# Remove Docker, containers, volumes e reseta o ambiente

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "🧹 Limpeza Completa do Servidor Ubuntu"
echo "⚠️  ATENÇÃO: Este script irá remover TUDO relacionado ao Docker e aplicações!"
echo

# Configurações do VPS
VPS_IP="72.60.50.248"
VPS_USER="root"
VPS_PASSWORD="6f'GJ.giU2GKNf8CZ5AX"

# Função SSH
ssh_exec() {
    sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no "$VPS_USER@$VPS_IP" "$@"
}

print_warning "Conectando ao servidor $VPS_IP..."

# Verificar conexão
if ! ssh_exec "exit" 2>/dev/null; then
    print_error "Não foi possível conectar ao servidor"
    exit 1
fi

print_success "Conectado ao servidor"

print_info "🛑 Parando todos os containers Docker..."
ssh_exec << 'EOF'
# Parar todos os containers em execução
docker stop $(docker ps -aq) 2>/dev/null || true

# Remover todos os containers
docker rm $(docker ps -aq) 2>/dev/null || true

# Remover todas as imagens
docker rmi $(docker images -aq) 2>/dev/null || true

# Remover todos os volumes
docker volume rm $(docker volume ls -q) 2>/dev/null || true

# Remover todas as redes customizadas
docker network rm $(docker network ls -q) 2>/dev/null || true

# Limpeza completa do sistema Docker
docker system prune -a -f --volumes 2>/dev/null || true

echo "Docker containers, images e volumes removidos"
EOF

print_info "🗂️ Removendo diretórios de aplicação..."
ssh_exec << 'EOF'
# Remover diretório da aplicação
rm -rf /opt/orthotrack

# Remover outros possíveis diretórios
rm -rf /home/orthotrack
rm -rf /var/lib/docker/volumes/orthotrack*

echo "Diretórios removidos"
EOF

print_info "📦 Removendo Docker completamente..."
ssh_exec << 'EOF'
# Parar serviço Docker
systemctl stop docker 2>/dev/null || true
systemctl disable docker 2>/dev/null || true

# Remover pacotes Docker
apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true

# Remover diretórios Docker
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker

# Remover Docker Compose
rm -f /usr/local/bin/docker-compose

# Limpar pacotes órfãos
apt-get autoremove -y 2>/dev/null || true
apt-get autoclean 2>/dev/null || true

echo "Docker completamente removido"
EOF

print_info "🧼 Limpeza geral do sistema..."
ssh_exec << 'EOF'
# Atualizar lista de pacotes
apt-get update 2>/dev/null || true

# Limpar logs antigos
journalctl --vacuum-time=1d 2>/dev/null || true

# Limpar cache do apt
apt-get clean 2>/dev/null || true

# Limpar arquivos temporários
rm -rf /tmp/*
rm -rf /var/tmp/*

# Limpar logs de aplicação
rm -rf /var/log/orthotrack*

echo "Limpeza geral concluída"
EOF

print_info "🔄 Liberando portas..."
ssh_exec << 'EOF'
# Parar processos que podem estar usando portas comuns
fuser -k 8080/tcp 2>/dev/null || true
fuser -k 8081/tcp 2>/dev/null || true
fuser -k 8082/tcp 2>/dev/null || true
fuser -k 5432/tcp 2>/dev/null || true
fuser -k 6379/tcp 2>/dev/null || true
fuser -k 1883/tcp 2>/dev/null || true
fuser -k 9001/tcp 2>/dev/null || true

# Verificar portas livres
echo "Portas liberadas:"
netstat -tuln | grep -E ":(8080|8081|8082|5432|6379|1883|9001)" || echo "Todas as portas estão livres"
EOF

print_info "💾 Verificando espaço em disco liberado..."
ssh_exec << 'EOF'
echo "Espaço em disco:"
df -h / | tail -1

echo "Memória disponível:"
free -h | grep Mem
EOF

print_success "🎉 Limpeza completa finalizada!"
echo
print_info "📋 Resumo da limpeza:"
echo -e "   🗑️  Todos os containers Docker removidos"
echo -e "   🖼️  Todas as imagens Docker removidas"
echo -e "   💾 Todos os volumes Docker removidos"
echo -e "   🐳 Docker completamente desinstalado"
echo -e "   📁 Diretórios da aplicação removidos"
echo -e "   🔌 Portas liberadas"
echo -e "   🧹 Sistema limpo"
echo
print_info "🚀 O servidor está pronto para uma instalação limpa!"
echo -e "   Execute: ./deploy-complete.sh"