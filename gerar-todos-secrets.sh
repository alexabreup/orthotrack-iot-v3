#!/bin/bash

echo "🔐 Gerando todos os secrets necessários para deploy..."
echo "=================================================="
echo ""

echo "📋 Secrets para adicionar no GitHub:"
echo "https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions"
echo ""

echo "🔑 Passwords geradas:"
echo "DB_PASSWORD=$(openssl rand -base64 32)"
echo "REDIS_PASSWORD=$(openssl rand -base64 32)"
echo "MQTT_PASSWORD=$(openssl rand -base64 32)"
echo "JWT_SECRET=$(openssl rand -base64 64)"
echo ""

echo "🔐 SSH Key (execute separadamente):"
echo "VPS_SSH_PRIVATE_KEY = conteúdo de: cat ~/.ssh/id_rsa"
echo ""

echo "🐳 Docker Hub (já configurado?):"
echo "DOCKER_USERNAME = alexabreup"
echo "DOCKER_PASSWORD = #,d^Ta&KPp6!jfk"
echo ""

echo "📝 Passos para SSH:"
echo "1. ssh-keygen -t rsa -b 4096 -C 'deploy@orthotrack'"
echo "2. ssh-copy-id root@72.60.50.248"
echo "3. cat ~/.ssh/id_rsa (copiar para VPS_SSH_PRIVATE_KEY)"
echo ""

echo "✅ Após configurar todos os secrets, rode:"
echo "git commit --allow-empty -m 'Trigger deploy after secrets configuration'"
echo "git push origin main"