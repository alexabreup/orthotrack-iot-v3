# OrthoTrack Firmware Release Script (PowerShell)
# Automatiza o processo de build, criação de patch e upload

param(
    [Parameter(Mandatory=$true)]
    [string]$CurrentVersion,
    
    [Parameter(Mandatory=$true)]
    [string]$NewVersion,
    
    [Parameter(Mandatory=$false)]
    [string]$BackendUrl = "http://localhost:8080"
)

# Funções de log
function Log-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Log-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Log-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Início
Log-Info "🚀 Iniciando release do firmware"
Log-Info "   Versão atual: $CurrentVersion"
Log-Info "   Nova versão:  $NewVersion"
Log-Info "   Backend:      $BackendUrl"
Write-Host ""

# Diretórios
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FirmwareDir = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $FirmwareDir ".pio\build\esp32dev"
$ReleasesDir = Join-Path $FirmwareDir "releases"

# Criar diretório de releases
if (-not (Test-Path $ReleasesDir)) {
    New-Item -ItemType Directory -Path $ReleasesDir | Out-Null
}

# Arquivos
$CurrentFirmware = Join-Path $ReleasesDir "firmware_v$CurrentVersion.bin"
$NewFirmware = Join-Path $BuildDir "firmware.bin"
$NewFirmwareRelease = Join-Path $ReleasesDir "firmware_v$NewVersion.bin"
$DeltaPatch = Join-Path $ReleasesDir "patch_v${CurrentVersion}_to_v${NewVersion}.bin"

# 1. Verificar se firmware atual existe
if (-not (Test-Path $CurrentFirmware)) {
    Log-Error "Firmware v$CurrentVersion não encontrado em $CurrentFirmware"
    Log-Info "Para primeira release, copie o firmware manualmente:"
    Log-Info "  Copy-Item .pio\build\esp32dev\firmware.bin releases\firmware_v${CurrentVersion}.bin"
    exit 1
}

Log-Success "Firmware v$CurrentVersion encontrado"

# 2. Atualizar versão no código
Log-Info "Atualizando versão no código..."
$OtaHeaderPath = Join-Path $FirmwareDir "src\ota_update.h"
$content = Get-Content $OtaHeaderPath -Raw
$content = $content -replace '#define FIRMWARE_VERSION ".*"', "#define FIRMWARE_VERSION `"$NewVersion`""
Set-Content -Path $OtaHeaderPath -Value $content
Log-Success "Versão atualizada para $NewVersion"

# 3. Compilar novo firmware
Log-Info "Compilando firmware v$NewVersion..."
Push-Location $FirmwareDir
pio run
Pop-Location
Log-Success "Firmware compilado"

# 4. Copiar firmware compilado para releases
Copy-Item $NewFirmware $NewFirmwareRelease
Log-Success "Firmware copiado para releases\"

# 5. Criar patch delta
Log-Info "Criando patch delta..."
$PythonScript = Join-Path $ScriptDir "create_delta_patch.py"
python $PythonScript `
    --chip esp32 `
    --base $CurrentFirmware `
    --new $NewFirmwareRelease `
    --output $DeltaPatch

Log-Success "Patch delta criado"

# 6. Calcular estatísticas
$CurrentSize = (Get-Item $CurrentFirmware).Length
$NewSize = (Get-Item $NewFirmwareRelease).Length
$PatchSize = (Get-Item $DeltaPatch).Length

$Savings = [math]::Round(100 - ($PatchSize * 100 / $NewSize), 1)

Write-Host ""
Log-Info "📊 Estatísticas:"
Write-Host "   Firmware v$CurrentVersion: $([math]::Round($CurrentSize/1KB, 2)) KB"
Write-Host "   Firmware v$NewVersion:     $([math]::Round($NewSize/1KB, 2)) KB"
Write-Host "   Patch delta:                $([math]::Round($PatchSize/1KB, 2)) KB"
Write-Host "   Economia:                   $Savings%"
Write-Host ""

# 7. Gerar checksums
Log-Info "Gerando checksums..."
$NewMD5 = (Get-FileHash -Path $NewFirmwareRelease -Algorithm MD5).Hash.ToLower()
$PatchMD5 = (Get-FileHash -Path $DeltaPatch -Algorithm MD5).Hash.ToLower()

Write-Host "   Firmware MD5: $NewMD5"
Write-Host "   Patch MD5:    $PatchMD5"
Write-Host ""

# 8. Criar arquivo de metadados
$MetadataFile = Join-Path $ReleasesDir "release_v${NewVersion}.json"
$Metadata = @{
    version = $NewVersion
    from_version = $CurrentVersion
    release_date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    hardware = "ESP32-WROOM-32"
    firmware = @{
        file = "firmware_v${NewVersion}.bin"
        size = $NewSize
        md5 = $NewMD5
    }
    delta_patch = @{
        file = "patch_v${CurrentVersion}_to_v${NewVersion}.bin"
        size = $PatchSize
        md5 = $PatchMD5
        compression_ratio = $Savings
    }
} | ConvertTo-Json -Depth 10

Set-Content -Path $MetadataFile -Value $Metadata
Log-Success "Metadados salvos em $MetadataFile"

# 9. Upload para backend (opcional)
$Upload = Read-Host "Fazer upload para backend? (y/n)"
if ($Upload -eq 'y' -or $Upload -eq 'Y') {
    Log-Info "Fazendo upload para $BackendUrl..."
    
    # Upload firmware completo
    Log-Info "Uploading firmware completo..."
    $FormData = @{
        file = Get-Item $NewFirmwareRelease
        version = $NewVersion
        is_delta = "false"
        hardware = "ESP32-WROOM-32"
        md5 = $NewMD5
    }
    
    try {
        Invoke-RestMethod -Uri "$BackendUrl/api/v1/firmware/upload" `
            -Method Post `
            -Headers @{"Authorization" = "Bearer YOUR_ADMIN_TOKEN"} `
            -Form $FormData
    } catch {
        Log-Warning "Erro no upload do firmware: $_"
    }
    
    # Upload patch delta
    Log-Info "Uploading patch delta..."
    $FormData = @{
        file = Get-Item $DeltaPatch
        version = $NewVersion
        from_version = $CurrentVersion
        is_delta = "true"
        hardware = "ESP32-WROOM-32"
        md5 = $PatchMD5
    }
    
    try {
        Invoke-RestMethod -Uri "$BackendUrl/api/v1/firmware/upload" `
            -Method Post `
            -Headers @{"Authorization" = "Bearer YOUR_ADMIN_TOKEN"} `
            -Form $FormData
    } catch {
        Log-Warning "Erro no upload do patch: $_"
    }
    
    Log-Success "Upload concluído"
}

# 10. Resumo
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════"
Log-Success "Release v$NewVersion concluído!"
Write-Host "═══════════════════════════════════════════════════════════"
Write-Host ""
Write-Host "📁 Arquivos gerados:"
Write-Host "   • $NewFirmwareRelease"
Write-Host "   • $DeltaPatch"
Write-Host "   • $MetadataFile"
Write-Host ""
Write-Host "📝 Próximos passos:"
Write-Host "   1. Testar firmware em dispositivo de desenvolvimento"
Write-Host "   2. Publicar atualização no backend"
Write-Host "   3. Monitorar rollout gradual"
Write-Host "   4. Atualizar changelog"
Write-Host ""
