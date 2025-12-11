#!/bin/bash
# OrthoTrack IoT v3 - Diagnóstico Rápido
# Verifica os 3 erros críticos identificados

echo "=== OrthoTrack IoT v3 - Diagnóstico Rápido ==="
echo "Verificando os 3 erros críticos..."
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===== VERIFICAÇÃO 1: REDIS =====
echo -e "${BLUE}=== 1. VERIFICAÇÃO REDIS ===${NC}"

if [ -f "config/redis/redis.conf" ]; then
    echo "📁 Arquivo config/redis/redis.conf encontrado"
    
    # Verificar se há linha requirepass problemática
    if grep -q "^requirepass" config/redis/redis.conf; then
        requirepass_line=$(grep "^requirepass" config/redis/redis.conf)
        echo -e "${RED}❌ PROBLEMA: Linha requirepass encontrada: $requirepass_line${NC}"
        
        # Verificar se tem valor
        if echo "$requirepass_line" | grep -q "requirepass$\|requirepass \s*$"; then
            echo -e "${RED}❌ CRÍTICO: requirepass sem valor (causa do erro)${NC}"
        fi
    else
        echo -e "${GREEN}✅ OK: Nenhuma linha requirepass problemática${NC}"
    fi
    
    # Mostrar conteúdo do arquivo
    echo "📄 Conteúdo atual:"
    cat config/redis/redis.conf | head -10
else
    echo -e "${YELLOW}⚠️  Arquivo config/redis/redis.conf não encontrado${NC}"
fi

# Verificar container Redis
echo ""
echo "🐳 Status do container Redis:"
if docker ps | grep -q "orthotrack-redis"; then
    echo -e "${GREEN}✅ Container Redis rodando${NC}"
    
    # Testar conexão
    if docker exec orthotrack-redis redis-cli ping 2>/dev/null | grep -q "PONG"; then
        echo -e "${GREEN}✅ Redis respondendo corretamente${NC}"
    else
        echo -e "${RED}❌ Redis não responde ao ping${NC}"
    fi
else
    echo -e "${RED}❌ Container Redis não está rodando${NC}"
    
    # Verificar logs do Redis
    echo "📋 Últimos logs do Redis:"
    docker compose logs redis --tail=5 2>/dev/null || echo "Não foi possível obter logs"
fi

# ===== VERIFICAÇÃO 2: MQTT/MOSQUITTO =====
echo ""
echo -e "${BLUE}=== 2. VERIFICAÇÃO MQTT/MOSQUITTO ===${NC}"

if [ -f "config/mosquitto/mosquitto.conf" ]; then
    echo "📁 Arquivo config/mosquitto/mosquitto.conf encontrado"
    
    # Contar linhas
    line_count=$(wc -l < config/mosquitto/mosquitto.conf)
    echo "📊 Total de linhas: $line_count"
    
    if [ "$line_count" -gt 20 ]; then
        echo -e "${YELLOW}⚠️  Arquivo tem muitas linhas ($line_count), pode conter configuração de bridge${NC}"
        
        # Verificar linha 38 especificamente
        if [ "$line_count" -ge 38 ]; then
            line_38=$(sed -n '38p' config/mosquitto/mosquitto.conf)
            echo "📍 Linha 38: $line_38"
            
            # Verificar se contém configuração de bridge
            if echo "$line_38" | grep -q -E "connection|bridge|address"; then
                echo -e "${RED}❌ PROBLEMA: Linha 38 contém configuração de bridge${NC}"
            fi
        fi
        
        # Procurar por configurações de bridge em todo o arquivo
        if grep -q -E "^connection|^bridge|^address.*:" config/mosquitto/mosquitto.conf; then
            echo -e "${RED}❌ PROBLEMA: Configurações de bridge encontradas${NC}"
            echo "🔍 Linhas com bridge:"
            grep -n -E "^connection|^bridge|^address.*:" config/mosquitto/mosquitto.conf
        fi
    else
        echo -e "${GREEN}✅ OK: Arquivo tem poucas linhas ($line_count), provavelmente configuração limpa${NC}"
    fi
    
    # Mostrar conteúdo
    echo "📄 Conteúdo atual:"
    cat config/mosquitto/mosquitto.conf
else
    echo -e "${YELLOW}⚠️  Arquivo config/mosquitto/mosquitto.conf não encontrado${NC}"
fi

# Verificar container MQTT
echo ""
echo "🐳 Status do container MQTT:"
if docker ps | grep -q "orthotrack-mqtt"; then
    echo -e "${GREEN}✅ Container MQTT rodando${NC}"
    
    # Testar conexão MQTT
    if timeout 3s docker exec orthotrack-mqtt mosquitto_pub -h localhost -t test -m "test" 2>/dev/null; then
        echo -e "${GREEN}✅ MQTT respondendo corretamente${NC}"
    else
        echo -e "${RED}❌ MQTT não responde${NC}"
    fi
else
    echo -e "${RED}❌ Container MQTT não está rodando${NC}"
    
    # Verificar logs do MQTT
    echo "📋 Últimos logs do MQTT:"
    docker compose logs mqtt --tail=5 2>/dev/null || echo "Não foi possível obter logs"
fi

# ===== VERIFICAÇÃO 3: FRONTEND =====
echo ""
echo -e "${BLUE}=== 3. VERIFICAÇÃO FRONTEND ===${NC}"

# Verificar variável de ambiente no sistema
echo "🔍 Verificando variáveis PUBLIC_* no ambiente:"
env_vars=$(env | grep "^PUBLIC_" || true)
if [ -n "$env_vars" ]; then
    echo -e "${RED}❌ PROBLEMA: Variáveis PUBLIC_* encontradas no ambiente:${NC}"
    echo "$env_vars"
else
    echo -e "${GREEN}✅ OK: Nenhuma variável PUBLIC_* no ambiente do sistema${NC}"
fi

# Verificar arquivo frontend.env
if [ -f "frontend.env" ]; then
    echo "📁 Arquivo frontend.env encontrado"
    echo "📄 Conteúdo:"
    cat frontend.env
else
    echo -e "${YELLOW}⚠️  Arquivo frontend.env não encontrado${NC}"
fi

# Verificar container Frontend
echo ""
echo "🐳 Status do container Frontend:"
if docker ps | grep -q "orthotrack-frontend"; then
    echo -e "${GREEN}✅ Container Frontend rodando${NC}"
    
    # Testar acesso HTTP
    if curl -s -I http://localhost:3000 2>/dev/null | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✅ Frontend acessível em http://localhost:3000${NC}"
    elif curl -s -I http://localhost:80 2>/dev/null | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✅ Frontend acessível em http://localhost:80 (via Nginx)${NC}"
    else
        echo -e "${RED}❌ Frontend não acessível${NC}"
    fi
else
    echo -e "${RED}❌ Container Frontend não está rodando${NC}"
    
    # Verificar logs do Frontend
    echo "📋 Últimos logs do Frontend:"
    docker compose logs frontend --tail=5 2>/dev/null || echo "Não foi possível obter logs"
fi

# ===== RESUMO GERAL =====
echo ""
echo -e "${BLUE}=== RESUMO GERAL ===${NC}"
echo "🐳 Status de todos os containers:"
docker compose ps 2>/dev/null || docker-compose ps 2>/dev/null || echo "Erro ao verificar containers"

echo ""
echo -e "${YELLOW}=== PRÓXIMOS PASSOS ===${NC}"
echo "Se encontrou problemas:"
echo "1. Execute: ./fix-orthotrack-completo.sh (Linux/Mac)"
echo "2. Ou execute: ./fix-orthotrack-completo.ps1 (Windows)"
echo ""
echo "Para logs detalhados:"
echo "- Redis: docker compose logs redis"
echo "- MQTT: docker compose logs mqtt" 
echo "- Frontend: docker compose logs frontend"