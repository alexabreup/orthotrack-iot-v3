# OrthoTrack IoT v3 - Correção de Erros Críticos

## 📋 Resumo dos Problemas Identificados

Foram identificados **3 erros críticos** que impedem a inicialização dos containers:

1. **Redis**: Configuração de senha inválida (`requirepass` sem valor)
2. **MQTT/Mosquitto**: Configuração de bridge inválida na linha 38
3. **Frontend**: Conflito de variável de ambiente `PUBLIC_WS_URL`

## 🚀 Solução Rápida

### Para Windows (PowerShell)
```powershell
# Executar como Administrador
.\fix-orthotrack-completo.ps1
```

### Para Linux/Mac (Bash)
```bash
# Dar permissão de execução
chmod +x fix-orthotrack-completo.sh

# Executar
./fix-orthotrack-completo.sh
```

## 🔍 Diagnóstico Antes da Correção

Para verificar os problemas antes de aplicar a correção:

### Windows
```powershell
# Verificar status atual
docker compose ps

# Ver logs dos serviços com problema
docker compose logs redis --tail=20
docker compose logs mqtt --tail=20
docker compose logs frontend --tail=20
```

### Linux/Mac
```bash
# Executar diagnóstico completo
./diagnostico-rapido.sh
```

## 📁 Arquivos Criados

- `fix-orthotrack-completo.sh` - Script de correção para Linux/Mac
- `fix-orthotrack-completo.ps1` - Script de correção para Windows
- `diagnostico-rapido.sh` - Script de diagnóstico para Linux/Mac

## 🔧 O que os Scripts Fazem

### 1. Backup Automático
- Cria backup das configurações atuais em `backups/config-YYYYMMDD-HHMMSS/`

### 2. Correção Redis
- Remove configuração `requirepass` problemática
- Cria configuração limpa para desenvolvimento (sem autenticação)
- Para produção, você pode adicionar senha depois

### 3. Correção MQTT/Mosquitto
- Remove configurações de bridge que causam erro na linha 38
- Cria configuração limpa e funcional
- Mantém funcionalidades essenciais (persistência, logs, performance)

### 4. Correção Frontend
- Remove variável `PUBLIC_WS_URL` conflitante do ambiente do sistema
- Cria arquivo `frontend.env` com variáveis corretas
- Resolve conflito do SvelteKit com prefixo `PUBLIC_`

### 5. Reinicialização Sequencial
- Para todos os containers
- Limpa volumes antigos
- Inicia serviços na ordem correta:
  1. PostgreSQL
  2. Redis
  3. MQTT
  4. Backend
  5. Frontend
  6. Nginx (se existir)

### 6. Verificação Automática
- Testa conectividade de cada serviço
- Mostra logs relevantes
- Confirma que os problemas foram resolvidos

## ✅ Verificação Pós-Correção

Após executar o script, verifique:

```bash
# Status dos containers
docker compose ps

# Teste Redis
docker exec orthotrack-redis redis-cli ping
# Deve retornar: PONG

# Teste MQTT
docker exec orthotrack-mqtt mosquitto_pub -h localhost -t test -m "hello"

# Teste Frontend
curl -I http://localhost:3000
# Ou acesse no navegador: http://localhost:3000
```

## 🔄 Se os Problemas Persistirem

1. **Verifique os logs detalhados:**
```bash
docker compose logs redis
docker compose logs mqtt  
docker compose logs frontend
```

2. **Reinicie containers específicos:**
```bash
docker compose restart redis
docker compose restart mqtt
docker compose restart frontend
```

3. **Limpeza completa (último recurso):**
```bash
docker compose down -v
docker system prune -f
docker volume prune -f
# Depois execute o script de correção novamente
```

## 📚 Configurações Criadas

### Redis (`config/redis/redis.conf`)
- Configuração sem autenticação para desenvolvimento
- Bind em todas as interfaces (0.0.0.0)
- Persistência habilitada
- Logs configurados

### MQTT (`config/mosquitto/mosquitto.conf`)
- Listener na porta 1883
- Acesso anônimo habilitado (desenvolvimento)
- Persistência habilitada
- Logs detalhados
- **SEM configurações de bridge** (que causavam o erro)

### Frontend (`frontend.env`)
- `PUBLIC_WS_URL=ws://localhost:8080/ws`
- `PUBLIC_API_URL=http://localhost:8080/api`
- `NODE_ENV=production`
- Outras variáveis necessárias

## 🔒 Configuração para Produção

Após resolver os problemas em desenvolvimento, para produção:

### Redis com Senha
```bash
# Editar config/redis/redis.conf
echo "requirepass SuaSenhaSegura123" >> config/redis/redis.conf

# Atualizar variáveis de ambiente
echo "REDIS_PASSWORD=SuaSenhaSegura123" >> .env
```

### MQTT com Autenticação
```bash
# Criar arquivo de senhas
docker exec orthotrack-mqtt mosquitto_passwd -c /mosquitto/config/passwd usuario

# Editar config/mosquitto/mosquitto.conf
# Trocar: allow_anonymous true
# Para: allow_anonymous false
```

## 📞 Suporte

Se precisar de ajuda adicional:

1. Execute o diagnóstico: `./diagnostico-rapido.sh`
2. Colete logs: `docker compose logs > all-logs.txt`
3. Verifique configuração: `docker compose config`
4. Compartilhe os resultados para análise

## 🎯 Resultado Esperado

Após a correção bem-sucedida:
- ✅ Todos os containers rodando sem erros
- ✅ Redis acessível e respondendo
- ✅ MQTT broker funcionando
- ✅ Frontend carregando em http://localhost:3000
- ✅ Sistema OrthoTrack IoT v3 totalmente operacional

---

**Data**: 11 de Dezembro de 2025  
**Versão**: 1.0  
**Compatibilidade**: Windows, Linux, macOS