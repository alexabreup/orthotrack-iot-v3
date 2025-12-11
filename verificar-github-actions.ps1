# Script para verificar GitHub Actions
# OrthoTrack IoT v3

Write-Host "🔍 Verificando GitHub Actions..." -ForegroundColor Green
Write-Host "Repositório: https://github.com/alexabreup/orthotrack-iot-v3" -ForegroundColor Cyan
Write-Host ""

# URLs importantes
$repoUrl = "https://github.com/alexabreup/orthotrack-iot-v3"
$actionsUrl = "$repoUrl/actions"
$secretsUrl = "$repoUrl/settings/secrets/actions"
$workflowUrl = "$repoUrl/blob/main/.github/workflows/deploy-production.yml"

Write-Host "📋 STATUS DO SISTEMA:" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host ""

# Verificar se o arquivo de workflow existe
if (Test-Path ".github/workflows/deploy-production.yml") {
    Write-Host "✅ Workflow do GitHub Actions configurado" -ForegroundColor Green
} else {
    Write-Host "❌ Workflow do GitHub Actions não encontrado" -ForegroundColor Red
}

# Verificar conectividade com GitHub
try {
    $response = Invoke-WebRequest -Uri $repoUrl -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ Repositório GitHub acessível" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao acessar repositório GitHub" -ForegroundColor Red
}

# Verificar último commit
try {
    $lastCommit = git log -1 --oneline
    Write-Host "✅ Último commit: $lastCommit" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao verificar último commit" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔗 LINKS IMPORTANTES:" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host "📦 Repositório: $repoUrl" -ForegroundColor Cyan
Write-Host "⚙️ GitHub Actions: $actionsUrl" -ForegroundColor Cyan
Write-Host "🔑 Secrets: $secretsUrl" -ForegroundColor Cyan
Write-Host "📄 Workflow: $workflowUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 CHECKLIST GITHUB SECRETS:" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow
Write-Host "Verifique se todos os 7 secrets estão configurados:" -ForegroundColor White
Write-Host "□ DB_PASSWORD" -ForegroundColor White
Write-Host "□ REDIS_PASSWORD" -ForegroundColor White
Write-Host "□ MQTT_PASSWORD" -ForegroundColor White
Write-Host "□ JWT_SECRET" -ForegroundColor White
Write-Host "□ DOCKER_USERNAME" -ForegroundColor White
Write-Host "□ DOCKER_PASSWORD" -ForegroundColor White
Write-Host "□ VPS_SSH_PRIVATE_KEY" -ForegroundColor White
Write-Host ""

Write-Host "🎯 COMO VERIFICAR O GITHUB ACTIONS:" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow
Write-Host "1. Abra: $actionsUrl" -ForegroundColor White
Write-Host "2. Procure pelo workflow 'Deploy to Production VPS'" -ForegroundColor White
Write-Host "3. Se não aparecer, configure os secrets primeiro" -ForegroundColor White
Write-Host "4. O workflow será executado automaticamente após push" -ForegroundColor White
Write-Host ""

Write-Host "⚠️ IMPORTANTE:" -ForegroundColor Red
Write-Host "O GitHub Actions só será executado após configurar TODOS os 7 secrets!" -ForegroundColor Yellow
Write-Host ""

# Tentar abrir o GitHub Actions no navegador
Write-Host "🌐 Abrindo GitHub Actions no navegador..." -ForegroundColor Green
try {
    Start-Process $actionsUrl
    Write-Host "✅ GitHub Actions aberto no navegador!" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Não foi possível abrir automaticamente. Acesse manualmente:" -ForegroundColor Yellow
    Write-Host "$actionsUrl" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎉 Verificação concluída!" -ForegroundColor Green