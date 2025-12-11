# 🚀 Deploy Rápido VPS - OrthoTrack
# Este script faz deploy direto no VPS com build local

$VPS_HOST = "72.60.50.248"
$VPS_USER = "root"
$DEPLOY_PATH = "/opt/orthotrack"

Write-Host "🚀 Iniciando deploy rápido no VPS..." -ForegroundColor Green

# 1. Parar serviços existentes
Write-Host "⏹️  Parando serviços existentes..." -ForegroundColor Yellow
ssh "$VPS_USER@$VPS_HOST" "cd $DEPLOY_PATH && docker-compose down || true"

# 2. Copiar arquivos atualizados
Write-Host "📦 Copiando arquivos..." -ForegroundColor Yellow
scp docker-compose.local-build.yml "$VPS_USER@$VPS_HOST`:$DEPLOY_PATH/docker-compose.yml"
scp -r backend/ "$VPS_USER@$VPS_HOST`:$DEPLOY_PATH/"
scp -r frontend/ "$VPS_USER@$VPS_HOST`:$DEPLOY_PATH/"

# 3. Criar arquivo .env com valores padrão
Write-Host "🔧 Criando arquivo .env..." -ForegroundColor Yellow
$envContent = @"
# Valores padrão para teste rápido
DB_PASSWORD=postgres123
REDIS_PASSWORD=
JWT_SECRET=jwt_secret_for_testing_change_in_production
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=
"@

ssh "$VPS_USER@$VPS_HOST" "cat > $DEPLOY_PATH/.env << 'EOF'
$envContent
EOF"

# 4. Build e deploy
Write-Host "🏗️  Fazendo build e deploy..." -ForegroundColor Yellow
ssh "$VPS_USER@$VPS_HOST" "cd $DEPLOY_PATH && docker-compose up -d --build"

# 5. Aguardar serviços
Write-Host "⏳ Aguardando serviços ficarem prontos..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# 6. Verificar status
Write-Host "✅ Verificando status dos serviços..." -ForegroundColor Yellow
ssh "$VPS_USER@$VPS_HOST" "cd $DEPLOY_PATH && docker-compose ps"

# 7. Teste básico
Write-Host "🧪 Testando endpoints..." -ForegroundColor Yellow
Write-Host "Frontend: http://$VPS_HOST`:3000" -ForegroundColor Cyan
Write-Host "Backend: http://$VPS_HOST`:8080" -ForegroundColor Cyan
Write-Host "API Health: http://$VPS_HOST`:8080/health" -ForegroundColor Cyan

# Teste de conectividade
try {
    Invoke-WebRequest -Uri "http://$VPS_HOST`:3000" -Method Head -TimeoutSec 10 | Out-Null
    Write-Host "✅ Frontend OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend falhou" -ForegroundColor Red
}

try {
    Invoke-WebRequest -Uri "http://$VPS_HOST`:8080/health" -Method Head -TimeoutSec 10 | Out-Null
    Write-Host "✅ Backend OK" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend falhou" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎉 Deploy concluído!" -ForegroundColor Green
Write-Host "🌐 Acesse: http://$VPS_HOST`:3000" -ForegroundColor Cyan
Write-Host "📊 API: http://$VPS_HOST`:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Para ver logs:" -ForegroundColor Yellow
Write-Host "ssh $VPS_USER@$VPS_HOST 'cd $DEPLOY_PATH && docker-compose logs -f'" -ForegroundColor Gray