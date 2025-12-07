# 🚀 **SETUP RÁPIDO - OrthoTrack IoT v3.1**

## **⚡ SETUP EM 10 MINUTOS**

### **1. Pré-requisitos**
```bash
# Instalar dependências
sudo apt update
sudo apt install postgresql redis-server golang nodejs npm

# Ou via Docker
docker --version
docker-compose --version
```

### **2. Clonar e Configurar**
```bash
git clone https://github.com/seu-usuario/orthotrack-iot-v3.git
cd orthotrack-iot-v3/backend
```

### **3. Configurar Variáveis de Ambiente**
```bash
# Copiar template
cp .env.example .env

# Gerar JWT secret SEGURO
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET=$JWT_SECRET" >> .env

# Editar .env com suas configurações
nano .env
```

### **4. Configuração Mínima (.env)**
```env
# OBRIGATÓRIOS
JWT_SECRET=<sua-chave-gerada>
DB_NAME=orthotrack_v3
DB_USER=orthotrack  
DB_PASSWORD=<senha-segura>
MQTT_BROKER_URL=tcp://localhost:1883
MQTT_USERNAME=orthotrack
MQTT_PASSWORD=<senha-mqtt>

# Desenvolvimento
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
```

### **5. Iniciar Serviços**
```bash
# PostgreSQL e Redis
sudo systemctl start postgresql redis-server

# Criar banco
sudo -u postgres createdb orthotrack_v3
sudo -u postgres createuser orthotrack

# Iniciar backend
cd backend
go mod tidy
go run cmd/api/main.go
```

### **6. Frontend (Terminal separado)**
```bash
cd frontend
npm install
npm run dev
```

### **7. ESP32 (opcional)**
```bash
cd esp32-firmware

# Configurar environment
export WIFI_SSID="SuaWiFi"
export WIFI_PASSWORD="SuaSenha"
export API_ENDPOINT="http://localhost:8080"
export DEVICE_ID="ESP32-001"  
export API_KEY="sua-api-key"

# Compile e upload
pio run -t upload
```

---

## **🔥 DOCKER SETUP (RECOMENDADO)**

### **1. Docker Compose Completo**
```bash
# Criar .env
cp backend/.env.example backend/.env
# Editar conforme necessário

# Iniciar todos os serviços
docker-compose up -d

# Logs
docker-compose logs -f
```

### **2. Verificar Status**
```bash
# Backend
curl http://localhost:8080/api/v1/health

# Frontend  
curl http://localhost:3000

# Swagger
open http://localhost:8080/swagger/index.html
```

---

## **⚡ COMANDOS ÚTEIS**

### **Desenvolvimento**
```bash
# Backend hot reload
cd backend && air

# Frontend dev server
cd frontend && npm run dev

# ESP32 monitor serial
pio device monitor

# Logs do sistema
docker-compose logs backend postgres redis
```

### **Produção**
```bash
# Build otimizado
cd backend && go build -o orthotrack-api cmd/api/main.go
cd frontend && npm run build

# Deploy
./deploy.sh production
```

---

## **🔧 TROUBLESHOOTING**

### **Erro: JWT_SECRET required**
```bash
# Gerar nova chave
openssl rand -base64 32
# Adicionar ao .env
```

### **Erro: Database connection**
```bash
# Verificar PostgreSQL
sudo systemctl status postgresql
sudo systemctl start postgresql

# Testar conexão
psql -h localhost -U orthotrack -d orthotrack_v3
```

### **Erro: CORS**
```bash
# Verificar ALLOWED_ORIGINS no .env
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173
```

### **ESP32 não conecta**
```bash
# Verificar WiFi
# Verificar API_ENDPOINT no platformio.ini
# Monitor serial: pio device monitor
```

---

## **✅ CHECKLIST DE FUNCIONAMENTO**

- [ ] Backend rodando em http://localhost:8080
- [ ] Frontend rodando em http://localhost:3000  
- [ ] PostgreSQL conectado
- [ ] Redis conectado
- [ ] Swagger acessível em /swagger/index.html
- [ ] ESP32 enviando telemetria (opcional)
- [ ] Logs de auditoria funcionando
- [ ] Rate limiting ativo

---

## **🔐 CHECKLIST DE SEGURANÇA**

- [ ] JWT_SECRET gerado e único
- [ ] DB_PASSWORD alterado
- [ ] MQTT_PASSWORD alterado
- [ ] CORS configurado corretamente
- [ ] SSL mode = require (produção)
- [ ] Logs de auditoria ativos

**🎉 PROJETO PRONTO PARA DESENVOLVIMENTO!**