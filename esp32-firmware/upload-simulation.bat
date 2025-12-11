@echo off
echo ========================================
echo Upload Firmware Simulacao ESP32
echo ========================================
echo.
echo INSTRUCOES:
echo 1. Feche qualquer monitor serial aberto
echo 2. Segure o botao BOOT no ESP32
echo 3. Pressione ENTER para iniciar upload
echo 4. Solte o BOOT quando aparecer "Writing at..."
echo.
pause
echo.
echo Iniciando upload...
pio run -e simulation --target upload
echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo Upload concluido com sucesso!
    echo ========================================
    echo.
    echo Aguarde 3 segundos para iniciar monitor...
    timeout /t 3 /nobreak >nul
    echo.
    echo Iniciando monitor serial...
    pio device monitor --port COM6 --baud 115200
) else (
    echo ========================================
    echo Erro no upload!
    echo ========================================
)
pause
