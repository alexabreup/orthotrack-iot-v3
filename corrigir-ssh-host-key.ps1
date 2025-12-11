# Script para corrigir problema de host key SSH

Write-Host "🔧 Corrigindo problema de SSH Host Key..." -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Yellow

$vpsIP = "72.60.50.248"
$knownHostsFile = "$env:USERPROFILE\.ssh\known_hosts"

Write-Host "📋 Problema: Host key do VPS mudou" -ForegroundColor Yellow
Write-Host "VPS: $vpsIP" -ForegroundColor White
Write-Host "Arquivo: $knownHostsFile" -ForegroundColor White

# Verificar se arquivo known_hosts existe
if (Test-Path $knownHostsFile) {
    Write-Host "`n🔍 Arquivo known_hosts encontrado" -ForegroundColor Green
    
    # Fazer backup
    $backupFile = "$knownHostsFile.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $knownHostsFile $backupFile
    Write-Host "💾 Backup criado: $backupFile" -ForegroundColor Green
    
    # Remover entrada antiga do VPS
    Write-Host "`n🗑️ Removendo entrada antiga do VPS..." -ForegroundColor Yellow
    
    $content = Get-Content $knownHostsFile
    $newContent = $content | Where-Object { $_ -notmatch "^$vpsIP " -and $_ -notmatch "^$vpsIP," }
    
    if ($content.Count -ne $newContent.Count) {
        $newContent | Set-Content $knownHostsFile
        Write-Host "✅ Entrada antiga removida!" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Nenhuma entrada encontrada para $vpsIP" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n📁 Arquivo known_hosts não existe - será criado automaticamente" -ForegroundColor Yellow
}

Write-Host "`n🔑 Conectando para aceitar nova host key..." -ForegroundColor Magenta
Write-Host "Quando aparecer a pergunta, digite 'yes' para aceitar" -ForegroundColor Yellow

# Tentar conectar para aceitar nova host key
Write-Host "`nExecutando: ssh -i C:\Users\alxab\.ssh\orthotrack root@$vpsIP" -ForegroundColor Gray
Write-Host "Digite 'yes' quando perguntado sobre a host key" -ForegroundColor Yellow

# Comando para conectar e aceitar host key
$sshCommand = "ssh -i C:\Users\alxab\.ssh\orthotrack -o StrictHostKeyChecking=ask root@$vpsIP 'echo `"✅ SSH funcionando!`" && exit'"

Write-Host "`n🚀 Executando conexão SSH..." -ForegroundColor Green
Write-Host "Comando: $sshCommand" -ForegroundColor Gray

try {
    Invoke-Expression $sshCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n🎉 SSH configurado com sucesso!" -ForegroundColor Green
        Write-Host "`n📋 Próximos passos:" -ForegroundColor Yellow
        Write-Host "1. Execute: .\copiar-chave-orthotrack.ps1" -ForegroundColor White
        Write-Host "2. Execute: .\obter-chave-github.ps1" -ForegroundColor White
        Write-Host "3. Configure os secrets no GitHub" -ForegroundColor White
    } else {
        Write-Host "`n⚠️ Ainda há problemas. Tente manualmente:" -ForegroundColor Yellow
        Write-Host "ssh -i C:\Users\alxab\.ssh\orthotrack root@$vpsIP" -ForegroundColor White
    }
} catch {
    Write-Host "`n❌ Erro: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`n🔧 Solução manual:" -ForegroundColor Yellow
    Write-Host "1. ssh -i C:\Users\alxab\.ssh\orthotrack root@$vpsIP" -ForegroundColor White
    Write-Host "2. Digite 'yes' quando perguntado" -ForegroundColor White
}

Write-Host "`n💡 Dica: Se ainda der problema, delete todo o arquivo known_hosts:" -ForegroundColor Cyan
Write-Host "Remove-Item '$knownHostsFile' -Force" -ForegroundColor Gray