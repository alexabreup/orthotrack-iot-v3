# 🚨 Correção Imediata do Redis - VPS

## ❌ Problema Atual
```
orthotrack-redis | Restarting (1) 12 seconds ago
```

**Causa**: Health check do Redis está incorreto no docker-compose.

## ✅ Solução Rápida

### Execute no VPS (ssh root@72.60.50.248):

```bash
# 1. Parar Redis problemático
docker stop orthotrack-redis
docker rm orthotrack-redis

# 2. Corrigir health check
sed -i 's/--raw", "incr", "ping"/-a", "redis_secure_2024", "ping"/' docker-compose.prod.yml

# 3. Recriar Redis
docker-compose -f docker-compose.prod.yml up -d redis

# 4. Aguardar 30 segundos
sleep 30

# 5. Verificar Redis
docker exec orthotrack-redis redis-cli -a redis_secure_2024 ping

# 6. Iniciar backend
docker-compose -f docker-compose.prod.yml up -d backend

# 7. Aguardar 60 segundos
sleep 60

# 8. Testar sistema
curl http://localhost:8080/health
curl http://localhost/
```

### Ou execute o script:
```bash
cd /opt/orthotrack
bash fix-redis-now.sh
```

## 🔍 Verificação

Após executar, você deve ver:
```bash
docker-compose -f docker-compose.prod.yml ps
```

**Resultado esperado**:
- ✅ orthotrack-redis: Up (healthy)
- ✅ orthotrack-backend: Up (healthy)  
- ✅ orthotrack-frontend: Up (healthy)
- ✅ orthotrack-postgres: Up (healthy)
- ✅ orthotrack-mqtt: Up (healthy)

## 🧪 Teste Final

```bash
# Backend
curl http://localhost:8080/health
# Deve retornar: {"status":"healthy"}

# Frontend via nginx
curl http://localhost/
# Deve retornar HTML da aplicação

# Acesso externo
curl http://72.60.50.248/
# Deve funcionar no navegador
```

## 📋 Status Atual

- ✅ Frontend: Funcionando
- ✅ PostgreSQL: Funcionando  
- ✅ MQTT: Funcionando
- ❌ Redis: Reiniciando (health check incorreto)
- ❌ Backend: Não pode iniciar (depende do Redis)
- ❌ Nginx: Não configurado ainda

## ⚡ Após Correção

O sistema estará 100% funcional:
- Login: admin@aacd.org.br / password
- URL: http://72.60.50.248
- API: http://72.60.50.248:8080