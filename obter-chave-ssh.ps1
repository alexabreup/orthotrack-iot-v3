# Script para obter a chave SSH privada
# OrthoTrack IoT v3

Write-Host "🔐 Obtendo Chave SSH Privada..." -ForegroundColor Green
Write-Host ""

$sshKeyPath = "C:\Users\alxab\.ssh\hostinger_key"

try {
    if (Test-Path $sshKeyPath) {
        Write-Host "✅ Arquivo encontrado: $sshKeyPath" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔑 CHAVE SSH PRIVADA (copie tudo abaixo):" -ForegroundColor Yellow
        Write-Host "===========================================" -ForegroundColor Yellow
        
        $sshKey = Get-Content $sshKeyPath -Raw
        Write-Host $sshKey -ForegroundColor White
        
        Write-Host "===========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "✅ Copie TODA a chave acima (incluindo BEGIN e END)" -ForegroundColor Green
        Write-Host "📋 Cole no GitHub Secret: VPS_SSH_PRIVATE_KEY" -ForegroundColor Cyan
        
        # Salvar em arquivo também
        $sshKey | Out-File -FilePath "chave-ssh-privada.txt" -Encoding UTF8
        Write-Host "💾 Chave salva também em: chave-ssh-privada.txt" -ForegroundColor Green
        
    } else {
        Write-Host "❌ Arquivo não encontrado: $sshKeyPath" -ForegroundColor Red
        Write-Host "Verifique se o caminho está correto" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Erro ao ler arquivo: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 SOLUÇÕES:" -ForegroundColor Yellow
    Write-Host "1. Execute este script como Administrador" -ForegroundColor White
    Write-Host "2. Ou execute manualmente:" -ForegroundColor White
    Write-Host "   Get-Content C:\Users\alxab\.ssh\hostinger_key" -ForegroundColor Cyan
    Write-Host "3. Ou abra o arquivo no Notepad:" -ForegroundColor White
    Write-Host "   notepad C:\Users\alxab\.ssh\hostinger_key" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "🎯 Próximo passo: Cole a chave no GitHub Secret VPS_SSH_PRIVATE_KEY" -ForegroundColor Yellow