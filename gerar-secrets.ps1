# Script para gerar secrets para GitHub Actions
# OrthoTrack IoT v3

Write-Host "🔐 Gerador de Secrets para GitHub Actions" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Função para gerar senha aleatória
function Generate-RandomPassword {
    param([int]$Length = 32)
    $bytes = New-Object byte[] $Length
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

Write-Host "📋 SECRETS GERADOS:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow
Write-Host ""

# Gerar senhas
$dbPassword = Generate-RandomPassword -Length 32
$redisPassword = Generate-RandomPassword -Length 32
$mqttPassword = Generate-RandomPassword -Length 32
$jwtSecret = Generate-RandomPassword -Length 64

Write-Host "1️⃣ DB_PASSWORD:" -ForegroundColor Cyan
Write-Host $dbPassword -ForegroundColor White
Write-Host ""

Write-Host "2️⃣ REDIS_PASSWORD:" -ForegroundColor Cyan
Write-Host $redisPassword -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ MQTT_PASSWORD:" -ForegroundColor Cyan
Write-Host $mqttPassword -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ JWT_SECRET:" -ForegroundColor Cyan
Write-Host $jwtSecret -ForegroundColor White
Write-Host ""

Write-Host "📝 SECRETS QUE VOCÊ PRECISA FORNECER:" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "5️⃣ DOCKER_USERNAME:" -ForegroundColor Cyan
Write-Host "   Valor: alexabreup" -ForegroundColor White
Write-Host "   (Seu username do Docker Hub)" -ForegroundColor Gray
Write-Host ""

Write-Host "6️⃣ DOCKER_PASSWORD:" -ForegroundColor Cyan
Write-Host "   Crie um Access Token no Docker Hub:" -ForegroundColor White
Write-Host "   1. Acesse: https://hub.docker.com/settings/security" -ForegroundColor Gray
Write-Host "   2. Clique em 'New Access Token'" -ForegroundColor Gray
Write-Host "   3. Nome: github-actions-orthotrack" -ForegroundColor Gray
Write-Host "   4. Permissions: Read and Write" -ForegroundColor Gray
Write-Host "   5. Copie o token gerado" -ForegroundColor Gray
Write-Host ""

Write-Host "7️⃣ VPS_SSH_PRIVATE_KEY:" -ForegroundColor Cyan
Write-Host "   Você tem duas opções:" -ForegroundColor White
Write-Host ""
Write-Host "   OPÇÃO A - Usar chave SSH existente:" -ForegroundColor Yellow
Write-Host "   1. Encontre sua chave privada (geralmente em ~/.ssh/id_rsa ou ~/.ssh/id_ed25519)" -ForegroundColor Gray
Write-Host "   2. Copie TODO o conteúdo do arquivo (incluindo BEGIN e END)" -ForegroundColor Gray
Write-Host ""
Write-Host "   OPÇÃO B - Criar nova chave SSH:" -ForegroundColor Yellow
Write-Host "   Execute os comandos abaixo:" -ForegroundColor Gray
Write-Host ""
Write-Host '   ssh-keygen -t ed25519 -C "github-actions@orthotrack" -f ~/.ssh/orthotrack_deploy' -ForegroundColor Magenta
Write-Host '   ssh-copy-id -i ~/.ssh/orthotrack_deploy.pub root@72.60.50.248' -ForegroundColor Magenta
Write-Host '   cat ~/.ssh/orthotrack_deploy' -ForegroundColor Magenta
Write-Host ""
Write-Host "   Depois copie TODO o conteúdo da chave privada" -ForegroundColor Gray
Write-Host ""

Write-Host "🔗 PRÓXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "===================" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Abra: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor White
Write-Host "2. Para cada secret, clique em 'New repository secret'" -ForegroundColor White
Write-Host "3. Cole o valor correspondente" -ForegroundColor White
Write-Host "4. Clique em 'Add secret'" -ForegroundColor White
Write-Host ""

Write-Host "⚠️ IMPORTANTE:" -ForegroundColor Red
Write-Host "===============" -ForegroundColor Red
Write-Host "- Copie esses valores em um local seguro (gerenciador de senhas)" -ForegroundColor Yellow
Write-Host "- NUNCA compartilhe esses secrets" -ForegroundColor Yellow
Write-Host "- NUNCA faça commit desses valores no Git" -ForegroundColor Yellow
Write-Host ""

# Salvar em arquivo temporário para facilitar cópia
$secretsFile = "secrets-temp.txt"
@"
DB_PASSWORD=$dbPassword
REDIS_PASSWORD=$redisPassword
MQTT_PASSWORD=$mqttPassword
JWT_SECRET=$jwtSecret
DOCKER_USERNAME=alexabreup
DOCKER_PASSWORD=<CRIAR_NO_DOCKER_HUB>
VPS_SSH_PRIVATE_KEY=<COPIAR_CHAVE_SSH>
"@ | Out-File -FilePath $secretsFile -Encoding UTF8

Write-Host "💾 Secrets salvos temporariamente em: $secretsFile" -ForegroundColor Green
Write-Host "   Lembre-se de DELETAR este arquivo após configurar os secrets!" -ForegroundColor Yellow
Write-Host ""

Write-Host "🌐 Abrindo página de secrets do GitHub..." -ForegroundColor Green
Start-Process "https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions"

Write-Host ""
Write-Host "✅ Geração de secrets concluída!" -ForegroundColor Green
Write-Host ""
Write-Host "Pressione qualquer tecla para sair..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
