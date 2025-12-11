@echo off
REM Script to run WebSocket property-based tests on Windows
REM Requires Go 1.21+ and Redis running on localhost:6379

echo Running WebSocket Property-Based Tests...
echo ==========================================
echo.

REM Check if Go is installed
where go >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Error: Go is not installed or not in PATH
    exit /b 1
)

echo Running Property 1: Device status event propagation...
go test -v -run TestProperty_DeviceStatusEventPropagation ./internal/services/

echo.
echo Running additional property tests...
go test -v -run TestProperty_ ./internal/services/

echo.
echo ==========================================
echo Tests complete!
