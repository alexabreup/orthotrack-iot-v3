# Configuração do GitHub Actions - OrthoTrack IoT v3

## Problemas Corrigidos

### 1. Frontend Dockerfile
- ✅ Corrigido: `npm ci` agora instala todas as dependências (incluindo devDependencies)
- ✅ Corrigido: CMD usa `node build` para executar o servidor SvelteKit

### 2. Backend Dockerfile
- ✅ Está correto e funcionando

---

## Secrets Necessários no GitHub

Para o workflow funcionar, você precisa configurar **7 secrets** no GitHub:

### Como adicionar secrets:
1. Acesse: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
2. Clique em "New repository secret"
3. Adicione cada um dos secrets abaixo:

### Lista de Secrets:

#### 1. `DOCKER_USERNAME`
- **Descrição**: Seu username do Docker Hub
- **Exemplo**: `alexabreup`
- **Onde obter**: https://hub.docker.com

#### 2. `DOCKER_PASSWORD`
- **Descrição**: Seu password do Docker Hub ou Access Token
- **Recomendação**: Use um Access Token ao invés da senha
- **Como criar token**:
  1. Docker Hub → Account Settings → Security → New Access Token
  2. Nome: `github-actions-orthotrack`
  3. Permissions: Read & Write

#### 3. `VPS_SSH_PRIVATE_KEY`
- **Descrição**: Chave SSH privada para acessar o VPS
- **Como gerar**:
  ```bash
  # No seu computador local:
  ssh-keygen -t ed25519 -C "github-actions@orthotrack" -f ~/.ssh/orthotrack_deploy

  # Copiar chave pública para o VPS:
  ssh-copy-id -i ~/.ssh/orthotrack_deploy.pub root@72.60.50.248

  # Copiar conteúdo da chave PRIVADA para o secret:
  cat ~/.ssh/orthotrack_deploy
  ```
- **IMPORTANTE**: Cole TODO o conteúdo, incluindo as linhas `-----BEGIN` e `-----END`

#### 4. `DB_PASSWORD`
- **Descrição**: Senha do PostgreSQL
- **Recomendação**: Use uma senha forte, gerada aleatoriamente
- **Exemplo de geração**:
  ```bash
  openssl rand -base64 32
  ```

#### 5. `REDIS_PASSWORD`
- **Descrição**: Senha do Redis
- **Recomendação**: Use uma senha forte, gerada aleatoriamente
- **Exemplo de geração**:
  ```bash
  openssl rand -base64 32
  ```

#### 6. `MQTT_PASSWORD`
- **Descrição**: Senha do MQTT Broker (Mosquitto)
- **Recomendação**: Use uma senha forte, gerada aleatoriamente
- **Exemplo de geração**:
  ```bash
  openssl rand -base64 32
  ```

#### 7. `JWT_SECRET`
- **Descrição**: Chave secreta para assinar tokens JWT
- **Recomendação**: Use uma string longa e aleatória
- **Exemplo de geração**:
  ```bash
  openssl rand -base64 64
  ```

---

## Verificação dos Secrets

Depois de adicionar todos os secrets, verifique se estão corretos:

1. Vá para: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
2. Você deve ver 7 secrets listados:
   - ✓ DB_PASSWORD
   - ✓ DOCKER_PASSWORD
   - ✓ DOCKER_USERNAME
   - ✓ JWT_SECRET
   - ✓ MQTT_PASSWORD
   - ✓ REDIS_PASSWORD
   - ✓ VPS_SSH_PRIVATE_KEY

---

## Testando o Workflow

### Método 1: Push para main
```bash
git add .
git commit -m "fix: corrigir Dockerfile e configurar CI/CD"
git push origin main
```

### Método 2: Executar manualmente
1. Acesse: https://github.com/alexabreup/orthotrack-iot-v3/actions
2. Clique em "Deploy to Production VPS"
3. Clique em "Run workflow"
4. Selecione a branch "main"
5. Clique em "Run workflow"

---

## Monitoramento

### Acompanhar execução:
- https://github.com/alexabreup/orthotrack-iot-v3/actions

### Verificar logs:
1. Clique na execução do workflow
2. Clique em cada job (test, build, deploy)
3. Veja os logs detalhados

---

## Troubleshooting

### Se o workflow falhar:

#### 1. Erro "Invalid credentials" no Docker
- Verifique `DOCKER_USERNAME` e `DOCKER_PASSWORD`
- Certifique-se de que o token do Docker Hub tem permissão de escrita

#### 2. Erro "Permission denied" no VPS
- Verifique `VPS_SSH_PRIVATE_KEY`
- Certifique-se de que a chave pública está em `~/.ssh/authorized_keys` no VPS

#### 3. Erro nos testes
- Execute localmente: `cd frontend && npm test`
- Execute localmente: `cd backend && go test -v ./...`

#### 4. Erro no build do Docker
- Verifique se os Dockerfiles estão corretos
- Teste localmente: `docker build -t test-frontend ./frontend`

---

## Comandos Úteis

### Verificar status local:
```powershell
.\verificar-github-actions.ps1
```

### Ver logs do GitHub Actions (com gh CLI):
```bash
gh run list
gh run view <run-id>
gh run watch
```

### Instalar GitHub CLI:
```powershell
winget install --id GitHub.cli
```

---

## Próximos Passos

1. ✅ Dockerfiles corrigidos
2. ⏳ Configurar os 7 secrets no GitHub
3. ⏳ Fazer commit e push
4. ⏳ Verificar se o workflow executa com sucesso
5. ⏳ Monitorar deploy no VPS

---

## Links Importantes

- **Repositório**: https://github.com/alexabreup/orthotrack-iot-v3
- **GitHub Actions**: https://github.com/alexabreup/orthotrack-iot-v3/actions
- **Secrets**: https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions
- **Docker Hub**: https://hub.docker.com/u/alexabreup
- **VPS**: ssh root@72.60.50.248

---

## Notas de Segurança

- ⚠️ NUNCA compartilhe seus secrets
- ⚠️ NUNCA faça commit de secrets no código
- ⚠️ Use Access Tokens ao invés de senhas quando possível
- ⚠️ Rotacione as senhas periodicamente
- ⚠️ Use senhas fortes geradas aleatoriamente
