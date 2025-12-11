@echo off
echo ========================================
echo   ORTHOTRACK IOT V3 - Frontend Dev
echo ========================================
echo.
echo Parando frontend Docker...
docker stop orthotrack-frontend 2>nul

echo.
echo Iniciando frontend em modo desenvolvimento...
echo.
echo URL: http://localhost:5173
echo Login: admin@orthotrack.com / admin123
echo.
echo Pressione Ctrl+C para parar
echo.

cd frontend
npm run dev
