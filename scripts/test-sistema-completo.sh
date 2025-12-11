#!/bin/bash

# Script de Teste Completo - OrthoTrack IoT v3
# Executa todos os testes necessários para validar o sistema

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
API_URL="http://72.60.50.248:8080"
FRONTEND_URL="http://72.60.50.248:3000"
API_KEY="orthotrack-device-key-2024"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  OrthoTrack IoT - Teste Sistema Completo${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Função para testar endpoint
test_endpoint() {
    local name=$1
    local url=$2
    local expected=$3
    
    echo -n "Testando $name... "
    response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" -eq "$expected" ]; then
        echo -e "${GREEN}✓ OK ($response)${NC}"
        return 0
    else
        echo -e "${RED}✗ FALHOU (esperado: $expected, recebido: $response)${NC}"
        return 1
    fi
}

# Contador de testes
total_tests=0
passed_tests=0

# ============================================
# TESTE 1: Backend Health Check
# ============================================
echo -e "\n${YELLOW}[1/8] Testando Backend Health...${NC}"
total_tests=$((total_tests + 1))
if test_endpoint "Health Check" "$API_URL/api/v1/health" 200; then
    passed_tests=$((passed_tests + 1))
    
    # Mostrar resposta
    health_response=$(curl -s "$API_URL/api/v1/health")
    echo "  Resposta: $health_response"
fi

# ============================================
# TESTE 2: Frontend Acessível
# ============================================
echo -e "\n${YELLOW}[2/8] Testando Frontend...${NC}"
total_tests=$((total_tests + 1))
if test_endpoint "Frontend" "$FRONTEND_URL" 200; then
    passed_tests=$((passed_tests + 1))
fi

# ============================================
# TESTE 3: Dashboard Overview
# ============================================
echo -e "\n${YELLOW}[3/8] Testando Dashboard Overview...${NC}"
total_tests=$((total_tests + 1))
if test_endpoint "Dashboard" "$API_URL/api/v1/dashboard/overview" 200; then
    passed_tests=$((passed_tests + 1))
    
    # Mostrar estatísticas
    dashboard=$(curl -s "$API_URL/api/v1/dashboard/overview")
    echo "  Estatísticas:"
    echo "    $dashboard" | jq '.' 2>/dev/null || echo "    $dashboard"
fi

# ============================================
# TESTE 4: Listar Pacientes
# ============================================
echo -e "\n${YELLOW}[4/8] Testando Lista de Pacientes...${NC}"
total_tests=$((total_tests + 1))
if test_endpoint "Pacientes" "$API_URL/api/v1/patients" 200; then
    passed_tests=$((passed_tests + 1))
    
    # Contar pacientes
    patients=$(curl -s "$API_URL/api/v1/patients")
    count=$(echo "$patients" | jq '.data | length' 2>/dev/null || echo "0")
    echo "  Total de pacientes: $count"
fi

# ============================================
# TESTE 5: Listar Dispositivos
# ============================================
echo -e "\n${YELLOW}[5/8] Testando Lista de Dispositivos...${NC}"
total_tests=$((total_tests + 1))
if test_endpoint "Dispositivos" "$API_URL/api/v1/braces" 200; then
    passed_tests=$((passed_tests + 1))
    
    # Contar dispositivos
    braces=$(curl -s "$API_URL/api/v1/braces")
    count=$(echo "$braces" | jq '.data | length' 2>/dev/null || echo "0")
    echo "  Total de dispositivos: $count"
fi

# ============================================
# TESTE 6: Enviar Telemetria de Teste
# ============================================
echo -e "\n${YELLOW}[6/8] Testando Envio de Telemetria...${NC}"
total_tests=$((total_tests + 1))

telemetry_data='{
  "device_id": "ESP32-TEST-001",
  "timestamp": '$(date +%s)',
  "status": "online",
  "battery_level": 85,
  "sensors": {
    "accelerometer": {
      "type": "accelerometer",
      "value": {"x": 0.1, "y": 0.2, "z": 9.8},
      "unit": "m/s²"
    },
    "temperature": {
      "type": "temperature",
      "value": 36.5,
      "unit": "°C"
    }
  },
  "is_wearing": true,
  "movement_detected": true,
  "touch_detected": true
}'

response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/devices/telemetry" \
  -H "Content-Type: application/json" \
  -H "X-Device-API-Key: $API_KEY" \
  -d "$telemetry_data")

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
    echo -e "${GREEN}✓ Telemetria enviada com sucesso ($http_code)${NC}"
    echo "  Resposta: $body"
    passed_tests=$((passed_tests + 1))
else
    echo -e "${RED}✗ Falha ao enviar telemetria ($http_code)${NC}"
    echo "  Resposta: $body"
fi

# ============================================
# TESTE 7: Verificar Containers Docker
# ============================================
echo -e "\n${YELLOW}[7/8] Verificando Containers Docker...${NC}"
total_tests=$((total_tests + 1))

if command -v docker &> /dev/null; then
    echo "  Containers em execução:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep orthotrack || echo "  Nenhum container encontrado"
    
    # Verificar se todos os containers estão rodando
    expected_containers=("orthotrack-api" "orthotrack-web" "orthotrack-db")
    all_running=true
    
    for container in "${expected_containers[@]}"; do
        if docker ps | grep -q "$container"; then
            echo -e "  ${GREEN}✓${NC} $container está rodando"
        else
            echo -e "  ${RED}✗${NC} $container NÃO está rodando"
            all_running=false
        fi
    done
    
    if [ "$all_running" = true ]; then
        passed_tests=$((passed_tests + 1))
    fi
else
    echo -e "${YELLOW}  Docker não encontrado - pulando teste${NC}"
fi

# ============================================
# TESTE 8: Verificar Banco de Dados
# ============================================
echo -e "\n${YELLOW}[8/8] Verificando Banco de Dados...${NC}"
total_tests=$((total_tests + 1))

if command -v docker &> /dev/null; then
    # Verificar se container do banco está rodando
    if docker ps | grep -q "orthotrack-db"; then
        echo "  Testando conexão com PostgreSQL..."
        
        # Tentar conectar e contar registros
        patient_count=$(docker exec orthotrack-db psql -U orthotrack -d orthotrack_db -t -c "SELECT COUNT(*) FROM patients;" 2>/dev/null | tr -d ' ')
        brace_count=$(docker exec orthotrack-db psql -U orthotrack -d orthotrack_db -t -c "SELECT COUNT(*) FROM braces;" 2>/dev/null | tr -d ' ')
        
        if [ ! -z "$patient_count" ]; then
            echo -e "  ${GREEN}✓${NC} Banco de dados acessível"
            echo "    Pacientes: $patient_count"
            echo "    Dispositivos: $brace_count"
            passed_tests=$((passed_tests + 1))
        else
            echo -e "  ${RED}✗${NC} Não foi possível acessar o banco"
        fi
    else
        echo -e "  ${YELLOW}Container do banco não está rodando${NC}"
    fi
else
    echo -e "${YELLOW}  Docker não encontrado - pulando teste${NC}"
fi

# ============================================
# RESUMO FINAL
# ============================================
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  RESUMO DOS TESTES${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo "  Total de testes: $total_tests"
echo "  Testes passados: $passed_tests"
echo "  Testes falhados: $((total_tests - passed_tests))"
echo ""

# Calcular porcentagem
percentage=$((passed_tests * 100 / total_tests))

if [ $percentage -eq 100 ]; then
    echo -e "${GREEN}✓ TODOS OS TESTES PASSARAM! Sistema pronto para demonstração.${NC}"
    exit 0
elif [ $percentage -ge 75 ]; then
    echo -e "${YELLOW}⚠ $percentage% dos testes passaram. Sistema funcional mas com alguns problemas.${NC}"
    exit 0
else
    echo -e "${RED}✗ Apenas $percentage% dos testes passaram. Sistema precisa de correções.${NC}"
    exit 1
fi
