# Script para copiar chave SSH OrthoTrack para VPS

Write-Host "🔑 Configurando SSH OrthoTrack no VPS..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Yellow

# Verificar se chave existe
$chavePrivada = "C:\Users\alxab\.ssh\orthotrack"
$chavePublica = "C:\Users\alxab\.ssh\orthotrack.pub"

if (!(Test-Path $chavePrivada) -or !(Test-Path $chavePublica)) {
    Write-Host "❌ Chaves SSH não encontradas!" -ForegroundColor Red
    Write-Host "Verifique se existem:" -ForegroundColor Yellow
    Write-Host "  - $chavePrivada"
    Write-Host "  - $chavePublica"
    exit 1
}

Write-Host "✅ Chaves SSH encontradas!" -ForegroundColor Green

# Mostrar chave pública
Write-Host "`n📋 Sua chave pública:" -ForegroundColor Yellow
$pubKey = Get-Content $chavePublica
Write-Host $pubKey -ForegroundColor White

# Copiar para VPS
Write-Host "`n📤 Copiando chave para VPS (digite a senha do root)..." -ForegroundColor Magenta
Write-Host "VPS: root@72.60.50.248" -ForegroundColor Cyan

try {
    # Comando para copiar chave
    $comando = "type `"$chavePublica`" | ssh root@72.60.50.248 `"mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys && echo 'Chave copiada com sucesso!'`""
    
    Write-Host "Executando: $comando" -ForegroundColor Gray
    Invoke-Expression $comando
    
    Write-Host "`n🧪 Testando conexão SSH..." -ForegroundColor Green
    
    # Testar conexão
    ssh -i $chavePrivada root@72.60.50.248 "echo '✅ SSH funcionando perfeitamente!' && exit"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n🎉 SSH configurado com sucesso!" -ForegroundColor Green
        Write-Host "`n📋 Próximos passos:" -ForegroundColor Yellow
        Write-Host "1. Execute: .\obter-chave-github.ps1" -ForegroundColor White
        Write-Host "2. Configure os secrets no GitHub" -ForegroundColor White
        Write-Host "3. Rode o deploy novamente" -ForegroundColor White
    } else {
        Write-Host "`n⚠️ SSH copiado, mas teste falhou. Verifique manualmente." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "`n❌ Erro ao copiar chave: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n🔧 Tente manualmente:" -ForegroundColor Yellow
    Write-Host "ssh root@72.60.50.248" -ForegroundColor White
    Write-Host "# No VPS: nano ~/.ssh/authorized_keys" -ForegroundColor Gray
    Write-Host "# Cole sua chave pública e salve" -ForegroundColor Gray
}