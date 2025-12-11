# Script Automático para Gerar GitHub Secrets
# OrthoTrack IoT v3 - alexabreup

Write-Host "🚀 Gerando GitHub Secrets Automaticamente..." -ForegroundColor Green
Write-Host "Repositório: https://github.com/alexabreup/orthotrack-iot-v3" -ForegroundColor Cyan
Write-Host ""

# Função para gerar senhas seguras
function New-SecurePassword {
    param([int]$Length = 32)
    Add-Type -AssemblyName System.Web
    return [System.Web.Security.Membership]::GeneratePassword($Length, 8)
}

# Gerar todas as senhas
Write-Host "🔑 Gerando senhas seguras..." -ForegroundColor Yellow
$secrets = @{
    "DB_PASSWORD" = New-SecurePassword -Length 32
    "REDIS_PASSWORD" = New-SecurePassword -Length 32
    "MQTT_PASSWORD" = New-SecurePassword -Length 32
    "JWT_SECRET" = New-SecurePassword -Length 64
}

# Exibir senhas geradas
Write-Host ""
Write-Host "✅ SENHAS GERADAS COM SUCESSO!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

foreach ($secret in $secrets.GetEnumerator()) {
    Write-Host "$($secret.Key): $($secret.Value)" -ForegroundColor White
}

Write-Host ""

# Tentar ler a chave SSH
$sshKeyPath = "C:\Users\alxab\.ssh\hostinger_key"
Write-Host "🔐 Tentando ler chave SSH..." -ForegroundColor Yellow

$sshPrivateKey = $null
try {
    if (Test-Path $sshKeyPath) {
        $sshPrivateKey = Get-Content $sshKeyPath -Raw -ErrorAction Stop
        Write-Host "✅ Chave SSH lida com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "❌ Arquivo de chave SSH não encontrado: $sshKeyPath" -ForegroundColor Red
    }
} catch {
    Write-Host "⚠️ Erro ao ler chave SSH: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Execute este script como Administrador ou use o comando manual" -ForegroundColor Yellow
}

# Criar arquivo com todos os secrets
$outputFile = "github-secrets-completos.txt"
$content = @"
=======================================================
GITHUB SECRETS - ORTHOTRACK IOT V3
=======================================================
Gerado em: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Repositório: https://github.com/alexabreup/orthotrack-iot-v3

INSTRUÇÕES:
1. Vá para: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
2. Clique em "New repository secret"
3. Adicione cada secret abaixo (Nome e Valor)

=======================================================
SECRETS PARA ADICIONAR:
=======================================================

1. DB_PASSWORD
   Valor: $($secrets["DB_PASSWORD"])

2. REDIS_PASSWORD
   Valor: $($secrets["REDIS_PASSWORD"])

3. MQTT_PASSWORD
   Valor: $($secrets["MQTT_PASSWORD"])

4. JWT_SECRET
   Valor: $($secrets["JWT_SECRET"])

5. DOCKER_USERNAME
   Valor: [SEU_USUARIO_DOCKER_HUB]
   ⚠️ SUBSTITUA pelo seu usuário do Docker Hub

6. DOCKER_PASSWORD
   Valor: [SUA_SENHA_DOCKER_HUB]
   ⚠️ SUBSTITUA pela sua senha do Docker Hub

7. VPS_SSH_PRIVATE_KEY
"@

if ($sshPrivateKey) {
    $content += @"
   Valor: $sshPrivateKey
"@
} else {
    $content += @"
   Valor: [EXECUTE O COMANDO ABAIXO PARA OBTER]
   
   COMANDO PARA OBTER A CHAVE SSH:
   Get-Content C:\Users\alxab\.ssh\hostinger_key -Raw
   
   OU execute como Administrador:
   Start-Process PowerShell -Verb RunAs -ArgumentList "-Command", "Get-Content C:\Users\alxab\.ssh\hostinger_key -Raw"
"@
}

$content += @"

=======================================================
PRÓXIMOS PASSOS APÓS CONFIGURAR SECRETS:
=======================================================

1. Configurar SSH sem senha:
   ssh-copy-id -i C:\Users\alxab\.ssh\hostinger_key.pub root@72.60.50.248

2. Configurar servidor VPS:
   ssh -i C:\Users\alxab\.ssh\hostinger_key root@72.60.50.248
   wget https://raw.githubusercontent.com/alexabreup/orthotrack-iot-v3/main/scripts/setup-vps.sh
   chmod +x setup-vps.sh
   ./setup-vps.sh

3. Fazer deploy:
   git add .
   git commit -m "feat: configuração produção completa"
   git push origin main

4. Verificar sistema:
   - Frontend: https://orthotrack.alexptech.com
   - API: https://api.orthotrack.alexptech.com/health
   - Grafana: http://72.60.50.248:3001 (admin/admin123)

=======================================================
"@

# Salvar arquivo
$content | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host ""
Write-Host "💾 ARQUIVO CRIADO: $outputFile" -ForegroundColor Green
Write-Host ""
Write-Host "📋 RESUMO DOS SECRETS:" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
foreach ($secret in $secrets.GetEnumerator()) {
    Write-Host "✅ $($secret.Key)" -ForegroundColor Green
}
Write-Host "⚠️ DOCKER_USERNAME (configure manualmente)" -ForegroundColor Yellow
Write-Host "⚠️ DOCKER_PASSWORD (configure manualmente)" -ForegroundColor Yellow

if ($sshPrivateKey) {
    Write-Host "✅ VPS_SSH_PRIVATE_KEY (incluído no arquivo)" -ForegroundColor Green
} else {
    Write-Host "⚠️ VPS_SSH_PRIVATE_KEY (obtenha manualmente)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 PRÓXIMO PASSO:" -ForegroundColor Yellow
Write-Host "Abra o arquivo '$outputFile' e copie os valores para o GitHub!" -ForegroundColor White
Write-Host ""
Write-Host "🌐 GitHub Secrets: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor Cyan

# Tentar abrir o arquivo automaticamente
try {
    Start-Process notepad.exe -ArgumentList $outputFile
    Write-Host "📝 Arquivo aberto no Notepad!" -ForegroundColor Green
} catch {
    Write-Host "📝 Abra manualmente o arquivo: $outputFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Script concluído com sucesso!" -ForegroundColor Green