# Script para obter chave privada para GitHub Secret

Write-Host "🔐 Obtendo chave privada para GitHub..." -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Yellow

$chavePrivada = "C:\Users\alxab\.ssh\orthotrack"

if (!(Test-Path $chavePrivada)) {
    Write-Host "❌ Chave privada não encontrada: $chavePrivada" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Chave privada encontrada!" -ForegroundColor Green

Write-Host "`n📋 CHAVE PRIVADA PARA GITHUB SECRET:" -ForegroundColor Yellow
Write-Host "====================================" -ForegroundColor Yellow

# Ler e mostrar chave privada
$conteudoChave = Get-Content $chavePrivada -Raw
Write-Host $conteudoChave -ForegroundColor White

Write-Host "`n📝 INSTRUÇÕES:" -ForegroundColor Green
Write-Host "1. Copie TODO o conteúdo acima (incluindo -----BEGIN e -----END)" -ForegroundColor White
Write-Host "2. Vá para: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions" -ForegroundColor Blue
Write-Host "3. Clique 'New repository secret'" -ForegroundColor White
Write-Host "4. Name: VPS_SSH_PRIVATE_KEY" -ForegroundColor Yellow
Write-Host "5. Secret: Cole o conteúdo da chave" -ForegroundColor White
Write-Host "6. Clique 'Add secret'" -ForegroundColor White

Write-Host "`n🔐 Outros secrets necessários:" -ForegroundColor Magenta
Write-Host "Execute: .\gerar-secrets-orthotrack.ps1" -ForegroundColor White

# Verificar se chave está no formato correto
if ($conteudoChave -match "-----BEGIN.*PRIVATE KEY-----" -and $conteudoChave -match "-----END.*PRIVATE KEY-----") {
    Write-Host "`n✅ Formato da chave está correto!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Verifique o formato da chave - deve ter BEGIN e END" -ForegroundColor Yellow
}