# Gerador de Secrets para GitHub Actions - OrthoTrack IoT v3

Write-Host ""
Write-Host "SECRETS GERADOS:" -ForegroundColor Yellow
Write-Host "=================" -ForegroundColor Yellow
Write-Host ""

# Gerar senhas aleatórias
Add-Type -AssemblyName System.Web
$dbPassword = [System.Web.Security.Membership]::GeneratePassword(32, 8)
$redisPassword = [System.Web.Security.Membership]::GeneratePassword(32, 8)
$mqttPassword = [System.Web.Security.Membership]::GeneratePassword(32, 8)
$jwtSecret = [System.Web.Security.Membership]::GeneratePassword(64, 16)

Write-Host "DB_PASSWORD:" -ForegroundColor Cyan
Write-Host $dbPassword
Write-Host ""

Write-Host "REDIS_PASSWORD:" -ForegroundColor Cyan
Write-Host $redisPassword
Write-Host ""

Write-Host "MQTT_PASSWORD:" -ForegroundColor Cyan
Write-Host $mqttPassword
Write-Host ""

Write-Host "JWT_SECRET:" -ForegroundColor Cyan
Write-Host $jwtSecret
Write-Host ""

Write-Host "DOCKER_USERNAME:" -ForegroundColor Cyan
Write-Host "alexabreup"
Write-Host ""

Write-Host "INSTRUCOES:" -ForegroundColor Yellow
Write-Host "============" -ForegroundColor Yellow
Write-Host "1. Abra: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions"
Write-Host "2. Para cada secret acima, clique em 'New repository secret'"
Write-Host "3. Cole o valor e clique em 'Add secret'"
Write-Host ""
Write-Host "DOCKER_PASSWORD: Crie em https://hub.docker.com/settings/security"
Write-Host "VPS_SSH_PRIVATE_KEY: Copie sua chave SSH privada completa"
Write-Host ""

# Salvar em arquivo
$secrets = @"
DB_PASSWORD=$dbPassword
REDIS_PASSWORD=$redisPassword
MQTT_PASSWORD=$mqttPassword
JWT_SECRET=$jwtSecret
DOCKER_USERNAME=alexabreup
"@

$secrets | Out-File "secrets-gerados.txt" -Encoding UTF8
Write-Host "Secrets salvos em: secrets-gerados.txt" -ForegroundColor Green
Write-Host "LEMBRE-SE DE DELETAR ESTE ARQUIVO APOS USAR!" -ForegroundColor Red
Write-Host ""
