#!/bin/bash
# 🚀 Script para criar usuário admin no OrthoTrack IoT V3
# Email: admin
# Senha: admin2025

set -e

echo "🔧 Criando usuário admin..."

# Navegar para o diretório do backend
cd "$(dirname "$0")"

# Compilar o script
echo "📦 Compilando script..."
go build -o /tmp/create-admin ./cmd/create-admin/main.go

# Executar o script
echo "▶️  Executando criação do usuário..."
/tmp/create-admin

# Limpar arquivo temporário
rm -f /tmp/create-admin

echo "✅ Concluído!"


