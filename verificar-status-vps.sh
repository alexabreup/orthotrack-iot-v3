#!/bin/bash

# Script para verificar status atual do VPS
echo "🔍 Verificando status atual do VPS..."

echo ""
echo "📊 Status dos containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🧪 Testando endpoints locais:"
echo "Backend health:"
curl -f -s http://localhost:8080/health && echo " ✅ Backend OK" || echo " ❌ Backend falhou"

echo "Frontend:"
curl -f -s -I http://localhost:3000/ && echo "✅ Frontend OK" || echo "❌ Frontend falhou"

echo "Nginx:"
curl -f -s -I http://localhost/ && echo "✅ Nginx OK" || echo "❌ Nginx falhou"

echo ""
echo "🌐 Testando domínios SSL:"
echo "Frontend SSL:"
curl -f -s -I https://orthotrack.alexptech.com/health && echo "✅ SSL Frontend OK" || echo "❌ SSL Frontend falhou"

echo "API SSL:"
curl -f -s -I https://api.orthotrack.alexptech.com/health && echo "✅ SSL API OK" || echo "❌ SSL API falhou"

echo ""
echo "🔐 Verificando certificados SSL:"
if [ -f "/etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem" ]; then
    echo "✅ Certificados SSL existem"
    openssl x509 -in /etc/letsencrypt/live/orthotrack.alexptech.com/fullchain.pem -noout -dates
else
    echo "❌ Certificados SSL não encontrados"
fi

echo ""
echo "📋 Arquivos de configuração:"
ls -la | grep -E "(docker-compose|nginx|mosquitto|\.env)"

echo ""
echo "💾 Uso de disco:"
df -h /

echo ""
echo "🔍 Logs recentes (últimas 10 linhas):"
docker-compose logs --tail=10 backend 2>/dev/null || echo "Logs do backend não disponíveis"