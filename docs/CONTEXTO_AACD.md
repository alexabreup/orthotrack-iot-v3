# OrthoTrack IoT Platform v3 - Contexto AACD

## 🏥 Sobre o Projeto

O **OrthoTrack IoT Platform v3** é uma plataforma completa para monitoramento de uso de **coletes ortopédicos** para pacientes com **escoliose** atendidos pela **AACD** (Associação de Assistência à Criança Deficiente).

## 🎯 Objetivo Principal

Monitorar e garantir a **aderência ao tratamento** com coletes ortopédicos, fornecendo:

- **Dados precisos** sobre tempo de uso diário
- **Alertas automáticos** para baixa aderência
- **Relatórios médicos** para acompanhamento clínico
- **Gamificação** para motivar os pacientes
- **Dashboard** para equipe médica da AACD

## 👥 Usuários do Sistema

### Pacientes AACD
- **Crianças e adolescentes** com escoliose
- **Idade típica**: 8 a 18 anos
- **Prescrição médica**: Uso do colete por 16-23 horas/dia
- **Acompanhamento**: Retornos regulares na AACD

### Equipe Médica AACD
- **Ortopedistas especializados** em coluna
- **Fisioterapeutas**
- **Técnicos em órteses**
- **Enfermeiros**

### Cuidadores
- **Pais e responsáveis**
- **Cuidadores domiciliares**
- **Professores** (em casos especiais)

## 🦴 Contexto Médico - Escoliose

### O que é Escoliose?
- **Deformidade tridimensional** da coluna vertebral
- **Curvatura lateral** anormal da coluna
- **Progressiva** durante o crescimento
- **Mais comum** em meninas adolescentes

### Tratamento com Colete
- **Colete Milwaukee** ou **Boston Brace**
- **Uso prolongado**: 16-23 horas por dia
- **Período de tratamento**: 2-4 anos
- **Objetivo**: Impedir progressão da curvatura

### Desafios do Tratamento
- **Baixa aderência** dos pacientes
- **Dificuldade de monitoramento** real
- **Impacto psicológico** do uso do colete
- **Necessidade de ajustes** frequentes

## 📊 Métricas Importantes

### Aderência ao Tratamento
- **Meta mínima**: 16 horas/dia
- **Meta ideal**: 20-23 horas/dia
- **Tolerância**: Remoção para banho, exercícios
- **Monitoramento**: 7 dias por semana

### Indicadores de Sucesso
- **Compliance > 80%** do tempo prescrito
- **Uso consistente** ao longo do dia
- **Redução de alertas** de não uso
- **Melhora na qualidade de vida**

## 🔧 Especificações Técnicas do Colete

### Sensores Integrados
1. **Sensor de Pressão (FSR)**
   - Detecta contato corpo-colete
   - Posicionado em pontos estratégicos
   - Threshold ajustável por paciente

2. **Sensor Hall/Magnético**
   - Detecta fechamento completo
   - Imãs nos fechos do colete
   - Redundância para segurança

3. **Acelerômetro/Giroscópio (MPU6050)**
   - Detecta movimento e posição
   - Valida se paciente está ativo
   - Identifica padrões de uso

4. **Sensor de Temperatura**
   - Monitora temperatura corporal
   - Detecta superaquecimento
   - Alerta para ajustes necessários

### ESP32 - Especificações
- **Comunicação**: Bluetooth LE com app Android
- **Bateria**: Autonomia de 7 dias
- **Resistência**: IP54 (resistente a suor)
- **Tamanho**: Discreto, integrado ao colete

## 📱 Aplicativo Android - Node Edge

### Funcionalidades Principais
- **Gateway BLE**: Coleta dados do colete via Bluetooth
- **Armazenamento offline**: Funciona sem internet
- **Sincronização automática**: Upload quando conectado
- **Notificações**: Lembretes e alertas para pacientes
- **Dashboard familiar**: Visualização para pais

### Requisitos do Dispositivo
- **Android 8.0+** (API level 26)
- **Bluetooth LE** obrigatório
- **4G/WiFi** para sincronização
- **Memória**: 2GB RAM mínimo
- **Armazenamento**: 500MB livres

## 🏥 Integração com AACD

### Workflow Clínico
1. **Consulta inicial**: Prescrição do colete + sistema
2. **Configuração**: Setup do dispositivo na AACD
3. **Treinamento**: Paciente e família aprendem uso
4. **Monitoramento**: Equipe acompanha dados
5. **Retornos**: Análise de relatórios nas consultas

### Relatórios Médicos
- **Relatório semanal**: Aderência e padrões de uso
- **Relatório mensal**: Tendências e progressão
- **Relatório de consulta**: Dados para decisão clínica
- **Alertas críticos**: Notificação imediata da equipe

## 🎮 Gamificação para Pacientes

### Sistema de Pontuação
- **Pontos por hora** de uso do colete
- **Bonificações** por consistência
- **Conquistas** semanais e mensais
- **Ranking** entre pacientes (opcional)

### Recompensas
- **Badges virtuais** para metas atingidas
- **Certificados** para impressão
- **Conteúdo desbloqueável** no app
- **Reconhecimento** da equipe médica

## 🔐 Segurança e Privacidade

### Proteção de Dados (LGPD)
- **Criptografia** de dados pessoais e médicos
- **Acesso restrito** por perfil de usuário
- **Logs de auditoria** de acessos
- **Consentimento** explícito dos responsáveis

### Segurança Técnica
- **Autenticação** multifator
- **Comunicação TLS** obrigatória
- **Backup automático** criptografado
- **Conformidade** com CFM e ANVISA

## 📈 Métricas de Sucesso

### Indicadores Clínicos
- **Melhora na aderência**: +30% vs métodos tradicionais
- **Redução de progressão**: Curvas estáveis
- **Satisfação do paciente**: Score > 8/10
- **Eficiência médica**: -50% tempo análise dados

### Indicadores Técnicos
- **Uptime do sistema**: > 99.5%
- **Precisão dos sensores**: > 95%
- **Latência de alertas**: < 5 minutos
- **Autonomia bateria**: 7 dias real

## 🌟 Benefícios Esperados

### Para Pacientes
- **Tratamento mais efetivo**
- **Maior motivação** para aderir
- **Feedback imediato** sobre progresso
- **Empoderamento** no próprio tratamento

### Para Famílias
- **Tranquilidade** sobre aderência
- **Dados objetivos** para acompanhamento
- **Comunicação** direta com equipe médica
- **Suporte 24/7** via aplicativo

### Para Equipe AACD
- **Dados precisos** para tomada de decisão
- **Identificação precoce** de problemas
- **Otimização** do tempo de consulta
- **Melhores resultados** clínicos

---

**Este projeto representa um avanço significativo no tratamento de escoliose na AACD, combinando tecnologia IoT de ponta com cuidado médico especializado para melhorar a qualidade de vida dos pacientes.**