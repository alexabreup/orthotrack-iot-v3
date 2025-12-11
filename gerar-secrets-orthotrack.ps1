# Script para gerar todos os secrets necessários para OrthoTrack

Write-Host "🔐 Gerando secrets para OrthoTrack Deploy..." -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Yellow

# Função para gerar senha base64 segura
function New-SecurePassword {
    param([int]$Length = 32)
    $bytes = New-Object byte[] $Length
    [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($bytes)
    return [Convert]::ToBase64String($bytes)
}

Write-Host "`n📋 SECRETS PARA GITHUB:" -ForegroundColor Green
Write-Host "https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor Blue
Write-Host ""

# Gerar senhas
$dbPassword = New-SecurePassword 32
$redisPassword = New-SecurePassword 32
$mqttPassword = New-SecurePassword 32
$jwtSecret = New-SecurePassword 64

Write-Host "🔑 Database:" -ForegroundColor Yellow
Write-Host "DB_PASSWORD = $dbPassword" -ForegroundColor White

Write-Host "`n🔴 Redis:" -ForegroundColor Yellow
Write-Host "REDIS_PASSWORD = $redisPassword" -ForegroundColor White

Write-Host "`n📡 MQTT:" -ForegroundColor Yellow
Write-Host "MQTT_PASSWORD = $mqttPassword" -ForegroundColor White

Write-Host "`n🔐 JWT:" -ForegroundColor Yellow
Write-Host "JWT_SECRET = $jwtSecret" -ForegroundColor White

Write-Host "`n🐳 Docker Hub (já configurado?):" -ForegroundColor Yellow
Write-Host "DOCKER_USERNAME = alexabreup" -ForegroundColor White
Write-Host "DOCKER_PASSWORD = #,d^Ta&KPp6!jfk" -ForegroundColor White

Write-Host "`n🔑 SSH (execute obter-chave-github.ps1):" -ForegroundColor Yellow
Write-Host "VPS_SSH_PRIVATE_KEY = [conteúdo da chave privada]" -ForegroundColor White

Write-Host "`n📝 RESUMO DOS SECRETS NECESSÁRIOS:" -ForegroundColor Magenta
Write-Host "✅ VPS_SSH_PRIVATE_KEY (chave SSH)" -ForegroundColor Green
Write-Host "✅ DB_PASSWORD (gerada acima)" -ForegroundColor Green
Write-Host "✅ REDIS_PASSWORD (gerada acima)" -ForegroundColor Green
Write-Host "✅ MQTT_PASSWORD (gerada acima)" -ForegroundColor Green
Write-Host "✅ JWT_SECRET (gerada acima)" -ForegroundColor Green
Write-Host "✅ DOCKER_USERNAME (alexabreup)" -ForegroundColor Green
Write-Host "✅ DOCKER_PASSWORD (#,d^Ta&KPp6!jfk)" -ForegroundColor Green

Write-Host "`n🚀 APÓS CONFIGURAR TODOS OS SECRETS:" -ForegroundColor Cyan
Write-Host "git commit --allow-empty -m 'Trigger deploy after all secrets configuration'" -ForegroundColor White
Write-Host "git push origin main" -ForegroundColor White

# Salvar em arquivo para referência
$secretsFile = "secrets-gerados-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
@"
# Secrets gerados para OrthoTrack - $(Get-Date)

DB_PASSWORD=$dbPassword
REDIS_PASSWORD=$redisPassword
MQTT_PASSWORD=$mqttPassword
JWT_SECRET=$jwtSecret

# Docker Hub
DOCKER_USERNAME=alexabreup
DOCKER_PASSWORD=#,d^Ta&KPp6!jfk

# SSH Key
VPS_SSH_PRIVATE_KEY=[execute obter-chave-github.ps1]

# GitHub Secrets URL
https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
"@ | Out-File -FilePath $secretsFile -Encoding UTF8

Write-Host "`n💾 Secrets salvos em: $secretsFile" -ForegroundColor Green