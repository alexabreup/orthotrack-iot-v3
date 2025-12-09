#!/bin/bash
# OrthoTrack Firmware Release Script
# Automatiza o processo de build, criação de patch e upload

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de log
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar argumentos
if [ "$#" -lt 2 ]; then
    echo "Uso: $0 <versao_atual> <nova_versao> [backend_url]"
    echo ""
    echo "Exemplo:"
    echo "  $0 1.0.0 1.1.0"
    echo "  $0 1.0.0 1.1.0 http://localhost:8080"
    exit 1
fi

CURRENT_VERSION=$1
NEW_VERSION=$2
BACKEND_URL=${3:-"http://localhost:8080"}

log_info "🚀 Iniciando release do firmware"
log_info "   Versão atual: $CURRENT_VERSION"
log_info "   Nova versão:  $NEW_VERSION"
log_info "   Backend:      $BACKEND_URL"
echo ""

# Diretórios
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FIRMWARE_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$FIRMWARE_DIR/.pio/build/esp32dev"
RELEASES_DIR="$FIRMWARE_DIR/releases"

# Criar diretório de releases se não existir
mkdir -p "$RELEASES_DIR"

# Arquivos
CURRENT_FIRMWARE="$RELEASES_DIR/firmware_v${CURRENT_VERSION}.bin"
NEW_FIRMWARE="$BUILD_DIR/firmware.bin"
NEW_FIRMWARE_RELEASE="$RELEASES_DIR/firmware_v${NEW_VERSION}.bin"
DELTA_PATCH="$RELEASES_DIR/patch_v${CURRENT_VERSION}_to_v${NEW_VERSION}.bin"

# 1. Verificar se firmware atual existe
if [ ! -f "$CURRENT_FIRMWARE" ]; then
    log_error "Firmware v$CURRENT_VERSION não encontrado em $CURRENT_FIRMWARE"
    log_info "Para primeira release, copie o firmware manualmente:"
    log_info "  cp .pio/build/esp32dev/firmware.bin releases/firmware_v${CURRENT_VERSION}.bin"
    exit 1
fi

log_success "Firmware v$CURRENT_VERSION encontrado"

# 2. Atualizar versão no código
log_info "Atualizando versão no código..."
sed -i "s/#define FIRMWARE_VERSION \".*\"/#define FIRMWARE_VERSION \"$NEW_VERSION\"/" "$FIRMWARE_DIR/src/ota_update.h"
log_success "Versão atualizada para $NEW_VERSION"

# 3. Compilar novo firmware
log_info "Compilando firmware v$NEW_VERSION..."
cd "$FIRMWARE_DIR"
pio run
log_success "Firmware compilado"

# 4. Copiar firmware compilado para releases
cp "$NEW_FIRMWARE" "$NEW_FIRMWARE_RELEASE"
log_success "Firmware copiado para releases/"

# 5. Criar patch delta
log_info "Criando patch delta..."
python "$SCRIPT_DIR/create_delta_patch.py" \
    --chip esp32 \
    --base "$CURRENT_FIRMWARE" \
    --new "$NEW_FIRMWARE_RELEASE" \
    --output "$DELTA_PATCH"

log_success "Patch delta criado"

# 6. Calcular estatísticas
CURRENT_SIZE=$(stat -f%z "$CURRENT_FIRMWARE" 2>/dev/null || stat -c%s "$CURRENT_FIRMWARE")
NEW_SIZE=$(stat -f%z "$NEW_FIRMWARE_RELEASE" 2>/dev/null || stat -c%s "$NEW_FIRMWARE_RELEASE")
PATCH_SIZE=$(stat -f%z "$DELTA_PATCH" 2>/dev/null || stat -c%s "$DELTA_PATCH")

SAVINGS=$(echo "scale=1; 100 - ($PATCH_SIZE * 100 / $NEW_SIZE)" | bc)

echo ""
log_info "📊 Estatísticas:"
echo "   Firmware v$CURRENT_VERSION: $(numfmt --to=iec-i --suffix=B $CURRENT_SIZE)"
echo "   Firmware v$NEW_VERSION:     $(numfmt --to=iec-i --suffix=B $NEW_SIZE)"
echo "   Patch delta:                $(numfmt --to=iec-i --suffix=B $PATCH_SIZE)"
echo "   Economia:                   ${SAVINGS}%"
echo ""

# 7. Gerar checksums
log_info "Gerando checksums..."
NEW_MD5=$(md5sum "$NEW_FIRMWARE_RELEASE" | awk '{print $1}')
PATCH_MD5=$(md5sum "$DELTA_PATCH" | awk '{print $1}')

echo "   Firmware MD5: $NEW_MD5"
echo "   Patch MD5:    $PATCH_MD5"
echo ""

# 8. Criar arquivo de metadados
METADATA_FILE="$RELEASES_DIR/release_v${NEW_VERSION}.json"
cat > "$METADATA_FILE" << EOF
{
  "version": "$NEW_VERSION",
  "from_version": "$CURRENT_VERSION",
  "release_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "hardware": "ESP32-WROOM-32",
  "firmware": {
    "file": "firmware_v${NEW_VERSION}.bin",
    "size": $NEW_SIZE,
    "md5": "$NEW_MD5"
  },
  "delta_patch": {
    "file": "patch_v${CURRENT_VERSION}_to_v${NEW_VERSION}.bin",
    "size": $PATCH_SIZE,
    "md5": "$PATCH_MD5",
    "compression_ratio": $SAVINGS
  }
}
EOF

log_success "Metadados salvos em $METADATA_FILE"

# 9. Upload para backend (opcional)
read -p "Fazer upload para backend? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Fazendo upload para $BACKEND_URL..."
    
    # Upload firmware completo
    log_info "Uploading firmware completo..."
    curl -X POST "$BACKEND_URL/api/v1/firmware/upload" \
        -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
        -F "file=@$NEW_FIRMWARE_RELEASE" \
        -F "version=$NEW_VERSION" \
        -F "is_delta=false" \
        -F "hardware=ESP32-WROOM-32" \
        -F "md5=$NEW_MD5"
    
    # Upload patch delta
    log_info "Uploading patch delta..."
    curl -X POST "$BACKEND_URL/api/v1/firmware/upload" \
        -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
        -F "file=@$DELTA_PATCH" \
        -F "version=$NEW_VERSION" \
        -F "from_version=$CURRENT_VERSION" \
        -F "is_delta=true" \
        -F "hardware=ESP32-WROOM-32" \
        -F "md5=$PATCH_MD5"
    
    log_success "Upload concluído"
fi

# 10. Resumo
echo ""
echo "═══════════════════════════════════════════════════════════"
log_success "Release v$NEW_VERSION concluído!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📁 Arquivos gerados:"
echo "   • $NEW_FIRMWARE_RELEASE"
echo "   • $DELTA_PATCH"
echo "   • $METADATA_FILE"
echo ""
echo "📝 Próximos passos:"
echo "   1. Testar firmware em dispositivo de desenvolvimento"
echo "   2. Publicar atualização no backend"
echo "   3. Monitorar rollout gradual"
echo "   4. Atualizar changelog"
echo ""
