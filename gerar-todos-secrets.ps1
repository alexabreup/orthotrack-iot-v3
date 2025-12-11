# Script para gerar todos os secrets necessários para deploy

Write-Host "🔐 Gerando todos os secrets para deploy VPS..." -ForegroundColor Cyan
Write-Host ""

# Função para gerar senha aleatória
function Generate-Password {
    param([int]$Length = 32)
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

Write-Host "📋 Secrets para configurar no GitHub:" -ForegroundColor Yellow
Write-Host "https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor Blue
Write-Host ""

# Docker Hub (já configurados)
Write-Host "✅ Docker Hub (já devem estar configurados):" -ForegroundColor Green
Write-Host "DOCKER_USERNAME = alexabreup"
Write-Host "DOCKER_PASSWORD = #,d^Ta&KPp6!jfk"
Write-Host ""

# VPS SSH
Write-Host "🔑 SSH para VPS:" -ForegroundColor Yellow
Write-Host "VPS_SSH_PRIVATE_KEY = [sua_chave_ssh_privada]"
Write-Host ""
Write-Host "💡 Para gerar chave SSH:" -ForegroundColor Magenta
Write-Host "  ssh-keygen -t rsa -b 4096 -C 'deploy@orthotrack'"
Write-Host "  ssh-copy-id root@72.60.50.248"
Write-Host "  cat ~/.ssh/id_rsa  # Copie este conteúdo para o secret"
Write-Host ""

# Database
$dbPassword = Generate-Password -Length 32
Write-Host "🗄️ Database:" -ForegroundColor Yellow
Write-Host "DB_PASSWORD = $dbPassword"
Write-Host ""

# Redis
$redisPassword = Generate-Password -Length 32
Write-Host "🔴 Redis:" -ForegroundColor Yellow
Write-Host "REDIS_PASSWORD = $redisPassword"
Write-Host ""

# MQTT
$mqttPassword = Generate-Password -Length 32
Write-Host "📡 MQTT:" -ForegroundColor Yellow
Write-Host "MQTT_PASSWORD = $mqttPassword"
Write-Host ""

# JWT
$jwtSecret = Generate-Password -Length 64
Write-Host "🎫 JWT:" -ForegroundColor Yellow
Write-Host "JWT_SECRET = $jwtSecret"
Write-Host ""

# Slack (opcional)
Write-Host "💬 Slack (opcional):" -ForegroundColor Gray
Write-Host "SLACK_WEBHOOK_URL = [seu_webhook_do_slack]"
Write-Host ""

Write-Host "📝 Resumo dos secrets necessários:" -ForegroundColor White
Write-Host "=================================="
Write-Host "1. VPS_SSH_PRIVATE_KEY (chave SSH)"
Write-Host "2. DB_PASSWORD (gerado acima)"
Write-Host "3. REDIS_PASSWORD (gerado acima)"
Write-Host "4. MQTT_PASSWORD (gerado acima)"
Write-Host "5. JWT_SECRET (gerado acima)"
Write-Host "6. SLACK_WEBHOOK_URL (opcional)"
Write-Host ""

Write-Host "🚀 Após configurar todos os secrets:" -ForegroundColor Green
Write-Host "git commit --allow-empty -m 'Trigger deploy after configuring all secrets'"
Write-Host "git push origin main"
Write-Host ""

Write-Host "🔍 Para testar SSH local:" -ForegroundColor Cyan
Write-Host "ssh root@72.60.50.248"