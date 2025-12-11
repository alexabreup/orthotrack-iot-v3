# Script para verificar e configurar Docker Hub secrets

Write-Host "🔍 Verificando configuração do Docker Hub..." -ForegroundColor Cyan

# Informações necessárias
Write-Host ""
Write-Host "📋 Secrets necessários no GitHub:" -ForegroundColor Yellow
Write-Host "  DOCKER_USERNAME = alexabreup"
Write-Host "  DOCKER_PASSWORD = [sua_senha_ou_token]"
Write-Host ""

# Links úteis
Write-Host "🔗 Links para configurar:" -ForegroundColor Green
Write-Host "  1. GitHub Secrets: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions"
Write-Host "  2. Docker Hub Tokens: https://hub.docker.com/settings/security"
Write-Host ""

# Instruções
Write-Host "📝 Passos para configurar:" -ForegroundColor White
Write-Host "  1. Vá no link do GitHub Secrets acima"
Write-Host "  2. Clique 'New repository secret'"
Write-Host "  3. Adicione DOCKER_USERNAME = alexabreup"
Write-Host "  4. Adicione DOCKER_PASSWORD = [sua_senha]"
Write-Host ""

# Verificação local (opcional)
Write-Host "🧪 Teste local do Docker Hub:" -ForegroundColor Magenta
Write-Host "  docker login -u alexabreup"
Write-Host "  [Digite sua senha quando solicitado]"
Write-Host ""

Write-Host "✅ Após configurar os secrets, rode novamente:" -ForegroundColor Green
Write-Host "  git commit --allow-empty -m 'Trigger workflow after Docker secrets'"
Write-Host "  git push origin main"