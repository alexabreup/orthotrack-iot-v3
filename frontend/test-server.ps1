# Script para testar o servidor de produção
Write-Host "🚀 Starting production server test..." -ForegroundColor Green

# Parar processos Node.js existentes
Write-Host "🛑 Stopping existing Node.js processes..." -ForegroundColor Yellow
Stop-Process -Name node -Force -ErrorAction SilentlyContinue

# Aguardar um pouco
Start-Sleep -Seconds 2

# Definir apenas variáveis de runtime (não PUBLIC_*)
$env:PORT = 3000
$env:HOST = "0.0.0.0"
$env:NODE_ENV = "production"

Write-Host "Runtime environment variables set:" -ForegroundColor Cyan
Write-Host "  PORT: $env:PORT" -ForegroundColor Cyan
Write-Host "  HOST: $env:HOST" -ForegroundColor Cyan
Write-Host "  NODE_ENV: $env:NODE_ENV" -ForegroundColor Cyan
Write-Host ""
Write-Host "API URLs are embedded in the build from build-time variables" -ForegroundColor Green

# Verificar se o build existe
if (-not (Test-Path "build")) {
    Write-Host "❌ Build directory not found! Run 'npm run build' first." -ForegroundColor Red
    exit 1
}

Write-Host "🌐 Starting server on http://localhost:$env:PORT" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Iniciar o servidor
try {
    node build
} catch {
    Write-Host "❌ Server failed to start: $_" -ForegroundColor Red
    exit 1
}