@echo off
echo ========================================
echo Upload Direto - Firmware Simulacao
echo ========================================
echo.
echo ANTES DE CONTINUAR:
echo 1. Feche qualquer monitor serial aberto
echo 2. Desconecte e reconecte o cabo USB do ESP32
echo 3. Aguarde 3 segundos
echo 4. Segure o botao BOOT no ESP32
echo 5. Pressione ENTER
echo.
pause
echo.
echo Fazendo upload...
python -m esptool --chip esp32 --port COM6 --baud 460800 write_flash -z 0x1000 .pio\build\simulation\bootloader.bin 0x8000 .pio\build\simulation\partitions.bin 0x10000 .pio\build\simulation\firmware.bin
echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo Upload concluido com sucesso!
    echo ========================================
    echo.
    echo Iniciando monitor serial...
    timeout /t 2 /nobreak >nul
    pio device monitor --port COM6 --baud 115200
) else (
    echo ========================================
    echo Erro no upload!
    echo ========================================
)
pause
