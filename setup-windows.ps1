# Setup PowerShell para OrthoTrack IoT v3
# Configuração específica para alexabreup

Write-Host "🚀 OrthoTrack IoT v3 - Setup Windows" -ForegroundColor Green
Write-Host "Repositório: https://github.com/alexabreup/orthotrack-iot-v3" -ForegroundColor Cyan
Write-Host "Servidor: 72.60.50.248" -ForegroundColor Cyan
Write-Host ""

# Função para gerar senhas seguras
function Generate-SecurePassword {
    param([int]$Length = 32)
    Add-Type -AssemblyName System.Web
    return [System.Web.Security.Membership]::GeneratePassword($Length, 8)
}

# Verificar se a chave SSH existe
$sshKeyPath = "C:\Users\alxab\.ssh\hostinger_key"
$sshKeyPubPath = "C:\Users\alxab\.ssh\hostinger_key.pub"

if (Test-Path $sshKeyPath) {
    Write-Host "✅ Chave SSH encontrada: $sshKeyPath" -ForegroundColor Green
} else {
    Write-Host "❌ Chave SSH não encontrada: $sshKeyPath" -ForegroundColor Red
    Write-Host "Por favor, verifique o caminho da chave SSH." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🔑 Gerando senhas seguras para GitHub Secrets:" -ForegroundColor Yellow
Write-Host ""

# Gerar senhas
$dbPassword = Generate-SecurePassword
$redisPassword = Generate-SecurePassword
$mqttPassword = Generate-SecurePassword
$jwtSecret = Generate-SecurePassword -Length 64

Write-Host "DB_PASSWORD: $dbPassword" -ForegroundColor White
Write-Host "REDIS_PASSWORD: $redisPassword" -ForegroundColor White
Write-Host "MQTT_PASSWORD: $mqttPassword" -ForegroundColor White
Write-Host "JWT_SECRET: $jwtSecret" -ForegroundColor White
Write-Host ""

# Ler chave SSH privada
Write-Host "🔐 Lendo chave SSH privada:" -ForegroundColor Yellow
try {
    $sshPrivateKey = Get-Content $sshKeyPath -Raw
    Write-Host "✅ Chave SSH privada lida com sucesso" -ForegroundColor Green
    Write-Host "Primeiras linhas da chave:" -ForegroundColor Gray
    Write-Host ($sshPrivateKey.Split("`n")[0..2] -join "`n") -ForegroundColor Gray
} catch {
    Write-Host "❌ Erro ao ler chave SSH privada: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📋 RESUMO DOS GITHUB SECRETS:" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""
Write-Host "1. DB_PASSWORD" -ForegroundColor Cyan
Write-Host "   Valor: $dbPassword" -ForegroundColor White
Write-Host ""
Write-Host "2. REDIS_PASSWORD" -ForegroundColor Cyan
Write-Host "   Valor: $redisPassword" -ForegroundColor White
Write-Host ""
Write-Host "3. MQTT_PASSWORD" -ForegroundColor Cyan
Write-Host "   Valor: $mqttPassword" -ForegroundColor White
Write-Host ""
Write-Host "4. JWT_SECRET" -ForegroundColor Cyan
Write-Host "   Valor: $jwtSecret" -ForegroundColor White
Write-Host ""
Write-Host "5. DOCKER_USERNAME" -ForegroundColor Cyan
Write-Host "   Valor: [SEU_USUARIO_DOCKER_HUB]" -ForegroundColor Yellow
Write-Host ""
Write-Host "6. DOCKER_PASSWORD" -ForegroundColor Cyan
Write-Host "   Valor: [SUA_SENHA_DOCKER_HUB]" -ForegroundColor Yellow
Write-Host ""
Write-Host "7. VPS_SSH_PRIVATE_KEY" -ForegroundColor Cyan
Write-Host "   Valor: [CONTEÚDO DA CHAVE PRIVADA - veja abaixo]" -ForegroundColor Yellow
Write-Host ""

Write-Host "🔐 CHAVE SSH PRIVADA COMPLETA:" -ForegroundColor Green
Write-Host "==============================" -ForegroundColor Green
Write-Host $sshPrivateKey -ForegroundColor White
Write-Host ""

Write-Host "📝 PRÓXIMOS PASSOS:" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""
Write-Host "1. Copie os valores acima" -ForegroundColor White
Write-Host "2. Vá para: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor White
Write-Host "3. Adicione cada secret com seu respectivo valor" -ForegroundColor White
Write-Host "4. Configure sua conta Docker Hub" -ForegroundColor White
Write-Host "5. Execute: ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248" -ForegroundColor White
Write-Host "6. Faça push para o repositório para iniciar o deploy" -ForegroundColor White
Write-Host ""

# Salvar informações em arquivo
$outputFile = "github-secrets.txt"
$content = @"
OrthoTrack IoT v3 - GitHub Secrets
==================================
Gerado em: $(Get-Date)

DB_PASSWORD=$dbPassword
REDIS_PASSWORD=$redisPassword
MQTT_PASSWORD=$mqttPassword
JWT_SECRET=$jwtSecret
DOCKER_USERNAME=[SEU_USUARIO_DOCKER_HUB]
DOCKER_PASSWORD=[SUA_SENHA_DOCKER_HUB]

VPS_SSH_PRIVATE_KEY:
$sshPrivateKey

Próximos passos:
1. Configure os secrets no GitHub
2. Configure Docker Hub
3. Execute: ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248
4. Faça push para deploy automático
"@

$content | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "💾 Informações salvas em: $outputFile" -ForegroundColor Green
Write-Host ""

# Testar conexão SSH
Write-Host "🔍 Testando conexão SSH..." -ForegroundColor Yellow
try {
    $testResult = ssh -i $sshKeyPath -o ConnectTimeout=10 -o BatchMode=yes root@72.60.50.248 "echo 'Conexão SSH OK'"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Conexão SSH funcionando!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Conexão SSH precisa ser configurada" -ForegroundColor Yellow
        Write-Host "Execute: ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248" -ForegroundColor White
    }
} catch {
    Write-Host "⚠️ Teste de SSH falhou - configure a chave pública no servidor" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Setup concluído! Verifique o arquivo $outputFile para os detalhes." -ForegroundColor Green