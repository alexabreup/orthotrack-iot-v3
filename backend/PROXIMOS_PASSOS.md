# 📋 Próximos Passos - OrthoTrack IoT v3

## ✅ O que já foi feito:

1. ✅ **Backup do banco de dados** - Backup criado em `/root/backup_orthotrack_*.sql`
2. ✅ **Transferência de arquivos** - Código transferido para `/opt/orthotrack-v3`
3. ✅ **Configuração do ambiente** - Arquivo `.env` criado e configurado
4. ✅ **Configuração MQTT** - Arquivo `mosquitto.conf` criado
5. ✅ **Build e deploy** - Todos os serviços Docker iniciados:
   - PostgreSQL ✅
   - Redis ✅
   - MQTT ✅
   - Backend ✅

## 🔄 Próximos Passos Necessários:

### 1. Verificação e Testes dos Serviços

```bash
ssh root@72.60.50.248
cd /opt/orthotrack-v3

# Testar endpoint de health (correto)
curl http://localhost:8080/api/v1/health

# Verificar status de todos os containers
docker-compose ps

# Verificar logs
docker-compose logs --tail=20 backend
```

### 2. Configuração MQTT (se necessário autenticação)

Se quiser habilitar autenticação MQTT (atualmente está permitindo conexões anônimas):

```bash
ssh root@72.60.50.248
cd /opt/orthotrack-v3

# Criar arquivo de senhas MQTT
docker exec orthotrack-mqtt mosquitto_passwd -c -b /mosquitto/config/passwd orthotrack mqtt123

# Atualizar mosquitto.conf para usar autenticação
# (já está configurado, mas precisa do arquivo de senhas)
```

### 3. Testes de Conectividade

```bash
ssh root@72.60.50.248

# Testar endpoints da API
curl http://localhost:8080/api/v1/health
curl http://localhost:8080/swagger/index.html

# Testar PostgreSQL
docker exec orthotrack-postgres pg_isready -U postgres

# Testar Redis
docker exec orthotrack-redis redis-cli ping

# Testar MQTT
docker exec orthotrack-mqtt mosquitto_sub -h localhost -t test -C 1 -W 2
```

### 4. Configuração de Firewall (Opcional mas Recomendado)

```bash
ssh root@72.60.50.248

# Permitir portas necessárias
ufw allow 8080/tcp comment 'OrthoTrack Backend API'
ufw allow 1883/tcp comment 'MQTT Broker'
ufw allow 9001/tcp comment 'MQTT WebSocket'

# Verificar status
ufw status
```

### 5. Criar Script de Monitoramento

```bash
ssh root@72.60.50.248
cat > /root/monitor-orthotrack.sh << 'EOF'
#!/bin/bash
echo "=== OrthoTrack IoT v3 - Service Monitor ==="
echo "Timestamp: $(date)"
echo ""

echo "Container Status:"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' --filter 'name=orthotrack'

echo ""
echo "Health Checks:"
echo -n "  Backend API: "
curl -s http://localhost:8080/api/v1/health >/dev/null && echo "✅" || echo "❌"

echo -n "  PostgreSQL: "
docker exec orthotrack-postgres pg_isready -U postgres >/dev/null 2>&1 && echo "✅" || echo "❌"

echo -n "  Redis: "
docker exec orthotrack-redis redis-cli ping >/dev/null 2>&1 && echo "✅" || echo "❌"

echo -n "  MQTT: "
docker exec orthotrack-mqtt mosquitto_sub -h localhost -t test -C 1 -W 2 >/dev/null 2>&1 && echo "✅" || echo "❌"

echo ""
echo "Disk Usage:"
df -h | grep -E '(Filesystem|/dev/)'
EOF

chmod +x /root/monitor-orthotrack.sh
```

### 6. Testar Endpoints da API

```bash
# Health check
curl http://72.60.50.248:8080/api/v1/health

# Swagger documentation
curl http://72.60.50.248:8080/swagger/index.html

# Teste de login (se tiver usuário criado)
curl -X POST http://72.60.50.248:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'
```

### 7. Configurar Proxy Reverso (Opcional)

Se quiser usar Nginx como proxy reverso na porta 80:

```bash
ssh root@72.60.50.248
cat > /etc/nginx/sites-available/orthotrack << 'EOF'
upstream backend {
    server localhost:8080;
}

server {
    listen 80;
    server_name 72.60.50.248;

    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /swagger/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
    }
}
EOF

# Habilitar site
ln -s /etc/nginx/sites-available/orthotrack /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

## 📊 Endpoints Disponíveis

### Públicos:
- `GET /api/v1/health` - Health check
- `POST /api/v1/auth/login` - Login de usuário
- `GET /swagger/*` - Documentação Swagger

### Protegidos (requerem JWT):
- `GET /api/v1/patients` - Listar pacientes
- `POST /api/v1/patients` - Criar paciente
- `GET /api/v1/braces` - Listar dispositivos
- `POST /api/v1/braces` - Criar dispositivo
- `GET /api/v1/alerts` - Listar alertas
- `GET /api/v1/dashboard/overview` - Dashboard
- E muitos outros...

### Dispositivos (requerem Device Auth):
- `POST /api/v1/devices/telemetry` - Enviar telemetria
- `POST /api/v1/devices/status` - Status do dispositivo
- `POST /api/v1/devices/alerts` - Alertas do dispositivo

### WebSocket:
- `GET /ws` - Conexão WebSocket para tempo real

## 🔗 URLs de Acesso

- **API Backend**: http://72.60.50.248:8080
- **Swagger Docs**: http://72.60.50.248:8080/swagger/index.html
- **Health Check**: http://72.60.50.248:8080/api/v1/health
- **MQTT Broker**: mqtt://72.60.50.248:1883
- **MQTT WebSocket**: ws://72.60.50.248:9001

## 📝 Comandos Úteis

```bash
# Ver logs
docker-compose logs -f backend

# Reiniciar serviços
docker-compose restart

# Parar serviços
docker-compose down

# Iniciar serviços
docker-compose up -d

# Status
docker-compose ps

# Monitoramento
/root/monitor-orthotrack.sh
```

## ⚠️ Observações Importantes

1. O endpoint de health está em `/api/v1/health`, não em `/health`
2. O MQTT está configurado para permitir conexões anônimas (desenvolvimento)
3. Para produção, considere:
   - Habilitar autenticação MQTT
   - Configurar SSL/TLS
   - Usar senhas mais seguras
   - Configurar backup automático do banco
   - Implementar monitoramento com alertas

## 🎯 Próxima Fase: Android Edge Node

Após confirmar que todos os serviços estão funcionando, você pode:
1. Configurar o Android Edge Node para conectar ao backend
2. Testar envio de telemetria
3. Verificar dados no dashboard











