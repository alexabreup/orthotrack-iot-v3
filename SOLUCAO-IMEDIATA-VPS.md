# 🚨 Solução Imediata - VPS OrthoTrack

## ❌ Problema Atual
```
Error response from daemon: pull access denied for alexabreup/orthotrack-backend, repository does not exist or may require 'docker login'
```

**Causa**: VPS está tentando puxar imagem do Docker Hub em vez do GitHub Container Registry.

## ✅ Solução Rápida (2 minutos)

### Execute no VPS:

```bash
# 1. Conectar ao VPS
ssh root@72.60.50.248

# 2. Ir para diretório
cd /opt/orthotrack

# 3. Parar containers
docker-compose -f docker-compose.prod.yml down

# 4. Login no GitHub Container Registry
# Você precisa de um Personal Access Token: https://github.com/settings/tokens
# Permissões: read:packages
echo "SEU_GITHUB_TOKEN_AQUI" | docker login ghcr.io -u alexabreup --password-stdin

# 5. Puxar imagens corretas
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest
docker pull ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest

# 6. Verificar se docker-compose está correto
grep "ghcr.io" docker-compose.prod.yml

# 7. Se não estiver correto, corrigir:
sed -i 's|alexabreup/orthotrack-backend:latest|ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest|g' docker-compose.prod.yml
sed -i 's|alexabreup/orthotrack-frontend:latest|ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest|g' docker-compose.prod.yml

# 8. Iniciar tudo
docker-compose -f docker-compose.prod.yml up -d

# 9. Aguardar 2 minutos
sleep 120

# 10. Testar
curl http://localhost:8080/health
```

## 🔐 Como Obter GitHub Token

1. Vá para: https://github.com/settings/tokens
2. Clique em "Generate new token (classic)"
3. Marque a permissão: `read:packages`
4. Copie o token gerado
5. Use no comando de login

## 📋 Ou Execute o Script Completo

```bash
cd /opt/orthotrack
bash fix-complete-vps.sh
```

## 🧪 Teste Final

Após executar, teste:

```bash
# Status dos containers
docker-compose -f docker-compose.prod.yml ps

# Backend
curl http://localhost:8080/health
# Deve retornar: {"status":"healthy"}

# Acesso externo
curl http://72.60.50.248:8080/health
```

## 📊 Status Esperado

```
NAME                  IMAGE                                                    STATUS
orthotrack-postgres   postgres:15-alpine                                       Up (healthy)
orthotrack-redis      redis:7-alpine                                          Up (healthy)
orthotrack-mqtt       eclipse-mosquitto:2.0-openssl                          Up (healthy)
orthotrack-backend    ghcr.io/alexabreup/orthotrack-iot-v3/backend:latest    Up (healthy)
orthotrack-frontend   ghcr.io/alexabreup/orthotrack-iot-v3/frontend:latest   Up (healthy)
```

## 🎯 Acesso Final

- **URL**: http://72.60.50.248
- **Login**: admin@aacd.org.br
- **Senha**: password

## 🆘 Se Ainda Não Funcionar

```bash
# Ver logs detalhados
docker-compose -f docker-compose.prod.yml logs backend

# Verificar imagens disponíveis
docker images | grep orthotrack

# Reiniciar tudo
docker-compose -f docker-compose.prod.yml restart
```