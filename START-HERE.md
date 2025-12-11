# 🚀 START HERE - ORTHOTRACK IOT V3

## ⚡ **AÇÃO IMEDIATA - 30 SEGUNDOS**

```bash
# 1. Testar sistema
chmod +x scripts/test-sistema-completo.sh
./scripts/test-sistema-completo.sh

# 2. Popular dados
docker cp scripts/popular-dados-demo.sql orthotrack-db:/tmp/
docker exec -it orthotrack-db psql -U orthotrack -d orthotrack_db -f /tmp/popular-dados-demo.sql

# 3. Abrir frontend
# http://72.60.50.248:3000
# Login: admin@orthotrack.com / admin123
```

---

## 📚 **DOCUMENTAÇÃO - LEIA NESTA ORDEM**

### **1. AGORA (3min)**
→ `README-ENTREGA-URGENTE.md`

### **2. DEPOIS (5min)**
→ `PROXIMOS-PASSOS-IMEDIATOS.md`

### **3. EXECUTANDO (30min)**
→ `.specs/GUIA-EXECUCAO-RAPIDA.md`

### **4. SE DER PROBLEMA**
→ `.specs/TROUBLESHOOTING-RAPIDO.md`

### **5. ANTES DA DEMO**
→ `.specs/RESUMO-EXECUTIVO-ENTREGA.md`

---

## ✅ **CHECKLIST RÁPIDO**

- [ ] Script de teste passou (8/8)
- [ ] Banco tem 5 pacientes
- [ ] Frontend carrega
- [ ] ESP32 conecta
- [ ] Dados aparecem

---

## 🎯 **OBJETIVO**

**Sistema funcionando end-to-end em 30 minutos!**

---

## 📞 **ACESSO**

```
Frontend: http://72.60.50.248:3000
Backend:  http://72.60.50.248:8080
Login:    admin@orthotrack.com / admin123
```

---

## 🚨 **AJUDA**

Problemas? → `.specs/TROUBLESHOOTING-RAPIDO.md`

---

**COMECE AGORA! ⚡**
