# Troubleshooting - Docker e Deploy

## Problema: Docker travado ou não responde

### Solução 1: Limpeza e diagnóstico

Execute o script de diagnóstico:

```bash
./fix-docker.sh
```

Este script irá:
- Verificar status dos containers
- Limpar recursos não utilizados
- Parar containers travados
- Verificar uso de recursos

### Solução 2: Reiniciar Docker no servidor

```bash
ssh root@72.60.50.248 'systemctl restart docker'
```

### Solução 3: Limpeza manual completa

```bash
ssh root@72.60.50.248 << 'EOF'
# Parar todos os containers
docker stop $(docker ps -aq) 2>/dev/null || true

# Remover todos os containers
docker rm $(docker ps -aq) 2>/dev/null || true

# Limpar tudo
docker system prune -a --volumes -f

# Verificar espaço
df -h
docker system df
EOF
```

## Problema: Deploy falha ou trava

### Use o script simplificado

```bash
./deploy-vps-simple.sh
```

Este script faz o deploy em passos menores e com mais verificações.

### Deploy manual passo a passo

1. **Sincronizar arquivos:**
```bash
rsync -avz --progress \
    --exclude 'node_modules' \
    --exclude '.git' \
    ./ root@72.60.50.248:/root/orthotrack-iot-v3/
```

2. **SSH no servidor:**
```bash
ssh root@72.60.50.248
cd /root/orthotrack-iot-v3
```

3. **Parar tudo:**
```bash
docker-compose down
docker ps -a | grep orthotrack | awk '{print $1}' | xargs docker rm -f
```

4. **Build apenas backend primeiro:**
```bash
docker-compose build backend
docker-compose up -d postgres redis mqtt
sleep 10
docker-compose up -d backend
sleep 10
```

5. **Build frontend depois:**
```bash
docker-compose build frontend
docker-compose up -d frontend
```

## Verificar logs

### Ver todos os logs
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose logs'
```

### Ver logs de um serviço específico
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose logs backend'
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose logs frontend'
```

### Ver logs em tempo real
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose logs -f'
```

## Verificar recursos do servidor

```bash
ssh root@72.60.50.248 << 'EOF'
echo "=== Memória ==="
free -h

echo ""
echo "=== Disco ==="
df -h

echo ""
echo "=== CPU ==="
top -bn1 | head -5

echo ""
echo "=== Docker ==="
docker system df
EOF
```

## Reiniciar um serviço específico

```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose restart backend'
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && docker-compose restart frontend'
```

## Rebuild apenas um serviço

```bash
ssh root@72.60.50.248 << 'EOF'
cd /root/orthotrack-iot-v3
docker-compose stop frontend
docker-compose build --no-cache frontend
docker-compose up -d frontend
EOF
```

## Verificar conectividade

### Testar backend
```bash
curl http://72.60.50.248:8080/api/v1/health
```

### Testar frontend
```bash
curl http://72.60.50.248:3000
```

### Testar dentro do container
```bash
ssh root@72.60.50.248 'docker exec orthotrack-frontend wget -qO- http://backend:8080/api/v1/health'
```

## Problemas comuns

### 1. Porta já em uso
```bash
ssh root@72.60.50.248 'netstat -tulpn | grep -E "(3000|8080)"'
# Matar processo se necessário
```

### 2. Sem espaço em disco
```bash
ssh root@72.60.50.248 'docker system prune -a --volumes -f'
```

### 3. Memória insuficiente
```bash
# Verificar memória
ssh root@72.60.50.248 'free -h'

# Se necessário, aumentar swap ou reduzir containers
```

### 4. CORS não funciona
```bash
ssh root@72.60.50.248 'cd /root/orthotrack-iot-v3 && grep ALLOWED_ORIGINS .env'
# Deve incluir: http://72.60.50.248:3000
```

## Reset completo (⚠️ apaga tudo)

```bash
ssh root@72.60.50.248 << 'EOF'
cd /root/orthotrack-iot-v3
docker-compose down -v
docker system prune -a --volumes -f
rm -rf /root/orthotrack-iot-v3
EOF

# Depois execute o deploy novamente
./deploy-vps-simple.sh
```



