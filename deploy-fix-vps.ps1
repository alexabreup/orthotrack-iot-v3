# Script para corrigir deployment no VPS via PowerShell
# Execute: .\deploy-fix-vps.ps1

Write-Host "🔧 Corrigindo deployment OrthoTrack no VPS..." -ForegroundColor Green

# Conectar ao VPS via SSH
$VPS_HOST = "72.60.50.248"
$VPS_USER = "root"

Write-Host "📡 Conectando ao VPS $VPS_HOST..." -ForegroundColor Yellow

# Script para executar no VPS
$REMOTE_SCRIPT = @"
#!/bin/bash
set -e

echo "🔧 Iniciando correção do deployment..."

# Ir para diretório do projeto
cd /opt/orthotrack

# Parar containers
echo "⏹️ Parando containers..."
docker-compose -f docker-compose.prod.yml down || true

# Limpar containers órfãos
docker container prune -f

# Criar .env.production correto
echo "📝 Criando .env.production..."
cat > .env.production << 'EOF'
DB_PASSWORD=orthotrack_secure_2024
REDIS_PASSWORD=redis_secure_2024
MQTT_PASSWORD=mqtt_secure_2024
JWT_SECRET=orthotrack_jwt_super_secret_key_2024_production_secure
EOF

# Criar mosquitto.conf
echo "📝 Criando mosquitto.conf..."
cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwd

listener 9001
protocol websockets
allow_anonymous false

log_dest stdout
log_type error
log_type warning
log_type notice
log_type information
connection_messages true
log_timestamp true

persistence true
persistence_location /mosquitto/data/
autosave_interval 1800
EOF

# Criar arquivo de senhas MQTT
echo "🔐 Configurando MQTT..."
docker run --rm -v \$(pwd):/mosquitto/config eclipse-mosquitto:2.0-openssl mosquitto_passwd -c -b /mosquitto/config/mosquitto_passwd orthotrack mqtt_secure_2024

# Fazer login no GitHub Container Registry
echo "🔐 Login no GitHub Container Registry..."
echo "ghp_SEU_TOKEN_AQUI" | docker login ghcr.io -u alexabreup --password-stdin

# Puxar imagens
echo "📥 Puxando imagens..."
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest

# Iniciar serviços
echo "🚀 Iniciando serviços..."
docker-compose -f docker-compose.prod.yml up -d

# Aguardar
echo "⏳ Aguardando 60 segundos..."
sleep 60

# Verificar status
echo "🏥 Status dos serviços:"
docker-compose -f docker-compose.prod.yml ps

# Testar
echo "🧪 Testando endpoints..."
curl -f http://localhost:8080/health || echo "Backend não respondeu"
curl -f http://localhost/ || echo "Frontend não respondeu"

echo "✅ Deploy concluído!"
"@

# Salvar script temporário
$TEMP_SCRIPT = "deploy-temp.sh"
$REMOTE_SCRIPT | Out-File -FilePath $TEMP_SCRIPT -Encoding UTF8

Write-Host "📤 Enviando script para o VPS..." -ForegroundColor Yellow

# Copiar script para VPS
scp $TEMP_SCRIPT "${VPS_USER}@${VPS_HOST}:/opt/orthotrack/"

# Executar script no VPS
Write-Host "🚀 Executando correção no VPS..." -ForegroundColor Green
ssh "${VPS_USER}@${VPS_HOST}" "cd /opt/orthotrack && chmod +x $TEMP_SCRIPT && ./$TEMP_SCRIPT"

# Limpar arquivo temporário
Remove-Item $TEMP_SCRIPT

Write-Host "✅ Correção concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Próximos passos:" -ForegroundColor Cyan
Write-Host "1. Acesse http://72.60.50.248 para ver o frontend"
Write-Host "2. Teste login com: admin@aacd.org.br / password"
Write-Host "3. Verifique logs: ssh root@72.60.50.248 'cd /opt/orthotrack && docker-compose -f docker-compose.prod.yml logs -f'"