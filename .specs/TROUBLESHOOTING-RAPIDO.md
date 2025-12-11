# 🔧 TROUBLESHOOTING RÁPIDO

## 🚨 **PROBLEMAS COMUNS E SOLUÇÕES**

---

### ❌ **PROBLEMA 1: Backend não responde**

**Sintomas:**
- `curl http://72.60.50.248:8080/api/v1/health` retorna erro
- Frontend mostra "Erro ao conectar"

**Diagnóstico:**
```bash
# Verificar se container está rodando
docker ps | grep orthotrack-api

# Ver logs
docker logs orthotrack-api --tail 50
```

**Soluções:**

**A. Container não está rodando**
```bash
docker-compose up -d backend
```

**B. Erro de conexão com banco**
```bash
# Verificar se PostgreSQL está rodando
docker ps | grep orthotrack-db

# Reiniciar banco
docker restart orthotrack-db

# Aguardar 10 segundos
sleep 10

# Reiniciar backend
docker restart orthotrack-api
```

**C. Erro de porta ocupada**
```bash
# Verificar o que está usando porta 8080
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/Mac

# Matar processo ou mudar porta no docker-compose.yml
```

---

### ❌ **PROBLEMA 2: Frontend não carrega**

**Sintomas:**
- Navegador mostra página em branco
- Erro 502 Bad Gateway
- Erro de CORS

**Diagnóstico:**
```bash
# Verificar container
docker ps | grep orthotrack-web

# Ver logs
docker logs orthotrack-web --tail 50
```

**Soluções:**

**A. Container não está rodando**
```bash
docker-compose up -d frontend
```

**B. Erro de build**
```bash
# Rebuild do frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend
```

**C. Erro de CORS**
```bash
# Verificar variável de ambiente
docker exec orthotrack-api env | grep ALLOWED_ORIGINS

# Se não estiver configurada, adicionar no .env
echo "ALLOWED_ORIGINS=http://72.60.50.248:3000" >> .env

# Reiniciar backend
docker restart orthotrack-api
```

**D. Cache do navegador**
```
1. Abrir DevTools (F12)
2. Clicar com botão direito no ícone de refresh
3. Selecionar "Limpar cache e recarregar"
OU
4. Abrir aba anônima (Ctrl+Shift+N)
```

---

### ❌ **PROBLEMA 3: Banco de dados não conecta**

**Sintomas:**
- Backend mostra erro "connection refused"
- Tabelas não existem

**Diagnóstico:**
```bash
# Verificar container
docker ps | grep orthotrack-db

# Tentar conectar
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db
```

**Soluções:**

**A. Container não está rodando**
```bash
docker-compose up -d postgres
```

**B. Senha incorreta**
```bash
# Verificar senha no .env
cat .env | grep POSTGRES_PASSWORD

# Verificar senha no docker-compose.yml
cat docker-compose.yml | grep POSTGRES_PASSWORD

# Devem ser iguais!
```

**C. Tabelas não existem**
```bash
# Executar migrations
docker exec orthotrack-api /app/orthotrack-iot-v3 migrate

# OU popular com dados demo
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql
```

---

### ❌ **PROBLEMA 4: ESP32 não conecta WiFi**

**Sintomas:**
- Serial Monitor mostra "Conectando WiFi....." infinitamente
- Nunca mostra "✅ Conectado!"

**Diagnóstico:**
```
Verificar no Serial Monitor:
- Qual SSID está tentando conectar
- Se há erro de autenticação
```

**Soluções:**

**A. WiFi 5GHz**
```
ESP32 só suporta 2.4GHz!
- Verificar se seu WiFi é 2.4GHz
- Ou criar hotspot 2.4GHz no celular
```

**B. SSID ou senha incorretos**
```ini
# Verificar em platformio.ini
-DWIFI_SSID=\"SEU_WIFI\"
-DWIFI_PASSWORD=\"SUA_SENHA\"

# Recompilar e fazer upload
pio run -t upload
```

**C. WiFi com caracteres especiais**
```ini
# Se WiFi tem espaços ou caracteres especiais
-DWIFI_SSID=\"Meu WiFi 2.4\"  # ✅ Correto
-DWIFI_SSID="Meu WiFi 2.4"    # ❌ Errado (aspas simples)
```

**D. Sinal fraco**
```
- Aproximar ESP32 do roteador
- Verificar antena do ESP32
- Usar outro WiFi mais próximo
```

---

### ❌ **PROBLEMA 5: ESP32 não envia telemetria**

**Sintomas:**
- WiFi conecta ✅
- Mas não mostra "📡 Telemetria enviada"
- Ou mostra "❌ Erro ao enviar telemetria"

**Diagnóstico:**
```
Ver código de erro no Serial Monitor:
- 400: Dados inválidos
- 401: Autenticação falhou
- 404: Endpoint não encontrado
- 500: Erro no servidor
```

**Soluções:**

**A. IP do servidor incorreto**
```ini
# Verificar em platformio.ini
-DAPI_ENDPOINT=\"http://72.60.50.248:8080\"

# Testar se servidor responde
curl http://72.60.50.248:8080/api/v1/health

# Se não responder, corrigir IP
```

**B. API Key incorreta**
```ini
# Verificar em platformio.ini
-DAPI_KEY=\"orthotrack-device-key-2024\"

# Verificar no backend se aceita essa key
docker logs orthotrack-api | grep "Device auth"
```

**C. Firewall bloqueando**
```bash
# Verificar firewall do VPS
sudo ufw status

# Permitir porta 8080
sudo ufw allow 8080/tcp
```

**D. Formato JSON incorreto**
```cpp
// Verificar no código se JSON está correto
// Ver logs do backend para ver o que está chegando
docker logs orthotrack-api | grep "telemetry"
```

---

### ❌ **PROBLEMA 6: Dashboard mostra zeros**

**Sintomas:**
- Dashboard carrega ✅
- Mas todos os números são 0
- Nenhum paciente ou dispositivo aparece

**Diagnóstico:**
```bash
# Verificar se há dados no banco
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db

SELECT COUNT(*) FROM patients;
SELECT COUNT(*) FROM braces;
```

**Soluções:**

**A. Banco vazio**
```bash
# Popular com dados demo
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql
```

**B. API não retorna dados**
```bash
# Testar endpoint diretamente
curl http://72.60.50.248:8080/api/v1/dashboard/overview

# Se retornar zeros, problema é no banco
# Se retornar erro, problema é no backend
```

**C. Frontend não está chamando API**
```
1. Abrir DevTools (F12)
2. Ir na aba Network
3. Recarregar página
4. Verificar se há chamadas para /api/v1/dashboard/overview
5. Ver resposta da API
```

---

### ❌ **PROBLEMA 7: Erro 401 Unauthorized**

**Sintomas:**
- Login não funciona
- API retorna 401
- "Token inválido"

**Soluções:**

**A. JWT_SECRET não configurado**
```bash
# Verificar se existe
docker exec orthotrack-api env | grep JWT_SECRET

# Se não existir, adicionar no .env
echo "JWT_SECRET=$(openssl rand -hex 32)" >> .env

# Reiniciar backend
docker restart orthotrack-api
```

**B. Token expirado**
```
- Fazer logout
- Fazer login novamente
- Token será renovado
```

**C. Credenciais incorretas**
```
Credenciais padrão:
- Email: admin@orthotrack.com
- Senha: admin123

Se não funcionar, criar novo usuário no banco
```

---

### ❌ **PROBLEMA 8: Containers param sozinhos**

**Sintomas:**
- Containers estavam rodando
- Depois de um tempo param
- `docker ps` não mostra containers

**Diagnóstico:**
```bash
# Ver containers parados
docker ps -a

# Ver logs do container que parou
docker logs orthotrack-api
```

**Soluções:**

**A. Erro de memória**
```bash
# Verificar uso de memória
docker stats

# Se estiver alto, aumentar memória do Docker
# Docker Desktop > Settings > Resources > Memory
```

**B. Erro no código**
```bash
# Ver logs completos
docker logs orthotrack-api --tail 100

# Corrigir erro e reiniciar
docker-compose up -d
```

**C. Healthcheck falhando**
```bash
# Verificar healthcheck
docker inspect orthotrack-api | grep -A 10 Health

# Desabilitar healthcheck temporariamente
# Comentar no docker-compose.yml
```

---

## 🆘 **COMANDOS DE EMERGÊNCIA**

### Reiniciar tudo do zero
```bash
# CUIDADO: Apaga todos os dados!
docker-compose down -v
docker-compose up -d
sleep 30
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql
```

### Backup antes de mexer
```bash
# Backup do banco
docker exec orthotrack-db pg_dump -U orthotrack orthotrack_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup dos containers
docker commit orthotrack-api orthotrack-api-backup
docker commit orthotrack-web orthotrack-web-backup
```

### Ver tudo que está rodando
```bash
# Containers
docker ps -a

# Portas ocupadas
netstat -ano | findstr :8080  # Windows
lsof -i :8080                 # Linux/Mac

# Uso de recursos
docker stats
```

---

## 📞 **CHECKLIST DE DIAGNÓSTICO**

Quando algo não funciona, verificar nesta ordem:

1. [ ] **Containers rodando?** `docker ps`
2. [ ] **Logs sem erros?** `docker logs <container>`
3. [ ] **Portas abertas?** `netstat -ano | findstr :8080`
4. [ ] **Variáveis de ambiente?** `docker exec <container> env`
5. [ ] **Banco acessível?** `docker exec -it orthotrack-db psql -U orthotrack`
6. [ ] **API responde?** `curl http://72.60.50.248:8080/api/v1/health`
7. [ ] **Frontend carrega?** Abrir no navegador
8. [ ] **CORS configurado?** Ver logs do backend
9. [ ] **Dados no banco?** `SELECT COUNT(*) FROM patients;`
10. [ ] **ESP32 conectado?** Ver Serial Monitor

---

**Se nada funcionar:** 

1. Fazer backup
2. Reiniciar tudo do zero
3. Popular dados demo
4. Testar passo a passo

**Última opção:**
- Usar dados mockados
- Demonstrar com Postman/curl
- Mostrar código e arquitetura

---

*Mantenha a calma e teste um componente por vez! 🧘*
