# Configurar Docker Hub Secrets - AGORA

## 🎯 Informações Prontas

### Secrets para adicionar no GitHub:
```
DOCKER_USERNAME = alexabreup
DOCKER_PASSWORD = #,d^Ta&KPp6!jfk
```

## 📋 Passos Detalhados

### 1. **Abrir GitHub Secrets**
Clique neste link:
👉 https://github.com/alexabreup/orthotrack-iot-v3/settings/secrets/actions

### 2. **Adicionar DOCKER_USERNAME**
1. Clique **"New repository secret"**
2. **Name**: `DOCKER_USERNAME`
3. **Secret**: `alexabreup`
4. Clique **"Add secret"**

### 3. **Adicionar DOCKER_PASSWORD**
1. Clique **"New repository secret"** novamente
2. **Name**: `DOCKER_PASSWORD`
3. **Secret**: `#,d^Ta&KPp6!jfk`
4. Clique **"Add secret"**

## ✅ Verificação

Após adicionar, você deve ver na página:
```
✅ DOCKER_USERNAME (created X seconds ago)
✅ DOCKER_PASSWORD (created X seconds ago)
```

## 🚀 Próximo Passo

Após configurar os secrets, rode o workflow novamente:

```bash
git commit --allow-empty -m "Trigger workflow after Docker Hub secrets configuration"
git push origin main
```

## 🎯 Resultado Esperado

Com os secrets configurados, o workflow deve:
1. ✅ **Fazer login no Docker Hub** com sucesso
2. ✅ **Buildar as imagens** backend e frontend
3. ✅ **Fazer push** para Docker Hub
4. ✅ **Fazer deploy** no VPS

## 🔍 Se Houver Problemas

Se ainda der erro de login:
1. Verifique se copiou a senha exatamente: `#,d^Ta&KPp6!jfk`
2. Verifique se o username está correto: `alexabreup`
3. Teste login local: `docker login -u alexabreup`

## 💡 Dica de Segurança

Após o deploy funcionar, considere:
1. Criar um **Access Token** no Docker Hub
2. Usar o token ao invés da senha
3. Tokens são mais seguros e podem ser revogados

**Link para tokens**: https://hub.docker.com/settings/security

---

**🎉 Vamos fazer esse deploy funcionar!**