# Build script para produção no Windows
Write-Host "🏗️ Building frontend for production..." -ForegroundColor Green

# Definir variáveis de ambiente
$env:PUBLIC_API_URL = "https://orthotrack.alexptech.com/api"
$env:PUBLIC_WS_URL = "wss://orthotrack.alexptech.com/ws"
$env:NODE_ENV = "production"

Write-Host "Environment variables set:" -ForegroundColor Yellow
Write-Host "  PUBLIC_API_URL: $env:PUBLIC_API_URL" -ForegroundColor Cyan
Write-Host "  PUBLIC_WS_URL: $env:PUBLIC_WS_URL" -ForegroundColor Cyan
Write-Host "  NODE_ENV: $env:NODE_ENV" -ForegroundColor Cyan

# Limpar build anterior
if (Test-Path "build") {
    Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force build
}

if (Test-Path ".svelte-kit") {
    Write-Host "🧹 Cleaning .svelte-kit..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force .svelte-kit
}

# Executar build
Write-Host "🔨 Running build..." -ForegroundColor Green
npm run build

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "📦 Build output available in ./build/" -ForegroundColor Cyan
} else {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}