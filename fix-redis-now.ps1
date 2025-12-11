# 🔧 Fix Imediato do Redis - OrthoTrack (PowerShell)
# Este script corrige o problema do Redis no docker-compose.yml

Write-Host "🔧 Iniciando correção do Redis..." -ForegroundColor Green

# Parar todos os containers
Write-Host "⏹️ Parando containers..." -ForegroundColor Yellow
docker compose down

# Backup do arquivo atual
Write-Host "💾 Fazendo backup do docker-compose.yml..." -ForegroundColor Blue
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item "docker-compose.yml" "docker-compose.yml.backup.$timestamp"

# Corrigir a configuração do Redis
Write-Host "🔄 Corrigindo configuração do Redis..." -ForegroundColor Yellow

# Ler o conteúdo do arquivo
$content = Get-Content "docker-compose.yml" -Raw

# Substituir a linha problemática
$content = $content -replace 'command: redis-server --appendonly yes --requirepass \$\{REDIS_PASSWORD:-redis123\}', 'command: redis-server --appendonly yes --requirepass redis123'

# Salvar o arquivo corrigido
Set-Content "docker-compose.yml" $content

Write-Host "✅ Configuração do Redis corrigida!" -ForegroundColor Green

# Verificar se a correção foi aplicada
Write-Host "🔍 Verificando correção..." -ForegroundColor Blue
Select-String -Path "docker-compose.yml" -Pattern "command: redis-server"

# Reiniciar os serviços
Write-Host "🚀 Reiniciando serviços..." -ForegroundColor Green
docker compose up -d

# Aguardar um pouco para os serviços subirem
Write-Host "⏳ Aguardando serviços iniciarem..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Verificar status
Write-Host "📊 Verificando status dos containers..." -ForegroundColor Blue
docker compose ps

# Testar conexão com Redis
Write-Host "🧪 Testando conexão com Redis..." -ForegroundColor Yellow
docker exec orthotrack-redis redis-cli -a redis123 ping

Write-Host "✅ Fix do Redis concluído!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Resumo das alterações:" -ForegroundColor Cyan
Write-Host "- Removida dependência da variável REDIS_PASSWORD" -ForegroundColor White
Write-Host "- Definida senha fixa 'redis123' para o Redis" -ForegroundColor White
Write-Host "- Backup criado: docker-compose.yml.backup.$timestamp" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Para testar a conexão:" -ForegroundColor Cyan
Write-Host "docker exec orthotrack-redis redis-cli -a redis123 ping" -ForegroundColor White