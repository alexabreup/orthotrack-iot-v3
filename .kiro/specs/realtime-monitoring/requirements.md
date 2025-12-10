# Requirements Document - Sistema de Monitoramento em Tempo Real

## Introduction

O Sistema de Monitoramento em Tempo Real do OrthoTrack IoT v3 permite que profissionais de saúde e gestores visualizem atualizações instantâneas sobre o status dos dispositivos, telemetria dos sensores e alertas críticos sem necessidade de recarregar a página. Utilizando WebSocket para comunicação bidirecional, o sistema garante que todas as mudanças de estado sejam propagadas imediatamente para todos os clientes conectados, melhorando significativamente a experiência do usuário e permitindo resposta rápida a situações críticas.

## Glossary

- **Sistema**: OrthoTrack IoT Platform v3
- **WebSocket**: Protocolo de comunicação bidirecional em tempo real sobre TCP
- **Cliente**: Navegador web conectado ao dashboard via WebSocket
- **Servidor WebSocket**: Componente backend que gerencia conexões WebSocket
- **Evento**: Mensagem enviada do servidor para clientes sobre mudanças de estado
- **Subscrição**: Registro de interesse de um cliente em receber eventos específicos
- **Canal**: Tópico lógico para agrupar eventos relacionados (ex: patient:123, device:456)
- **Heartbeat**: Mensagem periódica para manter conexão ativa
- **Reconexão**: Processo de restabelecer conexão WebSocket após desconexão
- **Broadcast**: Envio de mensagem para múltiplos clientes simultaneamente
- **Dispositivo**: Hardware ESP32 acoplado ao colete ortopédico
- **Telemetria**: Dados coletados dos sensores do dispositivo
- **Alerta**: Notificação sobre condição que requer atenção
- **Status do Dispositivo**: Estado atual do dispositivo (online, offline, manutenção)
- **Dashboard**: Interface web que exibe dados em tempo real

## Requirements

### Requirement 1

**User Story:** Como profissional de saúde, quero ver atualizações em tempo real do status dos dispositivos, para que eu possa saber imediatamente quando um dispositivo fica online ou offline.

#### Acceptance Criteria

1. WHEN um dispositivo muda de status THEN o Sistema SHALL enviar evento WebSocket para todos os clientes subscritos àquele dispositivo
2. WHEN um cliente recebe evento de mudança de status THEN o Sistema SHALL atualizar o indicador visual do dispositivo sem recarregar a página
3. WHEN um dispositivo fica online THEN o Sistema SHALL exibir badge verde com texto "Online" e timestamp da última conexão
4. WHEN um dispositivo fica offline THEN o Sistema SHALL exibir badge vermelho com texto "Offline" e timestamp da última conexão
5. WHEN um dispositivo entra em manutenção THEN o Sistema SHALL exibir badge amarelo com texto "Manutenção"


### Requirement 2

**User Story:** Como profissional de saúde, quero receber notificações em tempo real de novos alertas críticos, para que eu possa responder rapidamente a situações que requerem atenção imediata.

#### Acceptance Criteria

1. WHEN um alerta crítico é criado THEN o Sistema SHALL enviar evento WebSocket para todos os clientes subscritos ao paciente relacionado
2. WHEN um cliente recebe evento de novo alerta THEN o Sistema SHALL exibir notificação toast no canto superior direito da tela
3. WHEN a notificação toast é exibida THEN o Sistema SHALL incluir nível de severidade, mensagem do alerta e nome do paciente
4. WHEN a notificação toast é exibida THEN o Sistema SHALL reproduzir som de notificação se o usuário tiver habilitado áudio
5. WHEN o usuário clica na notificação toast THEN o Sistema SHALL navegar para a página de detalhes do paciente
6. WHEN a notificação toast permanece por 10 segundos sem interação THEN o Sistema SHALL removê-la automaticamente da tela

### Requirement 3

**User Story:** Como profissional de saúde, quero ver dados de telemetria atualizando em tempo real nos gráficos, para que eu possa monitorar continuamente as condições do paciente.

#### Acceptance Criteria

1. WHEN novos dados de telemetria são recebidos pelo backend THEN o Sistema SHALL enviar evento WebSocket para clientes subscritos àquele dispositivo
2. WHEN um cliente recebe evento de telemetria THEN o Sistema SHALL adicionar o novo ponto de dados ao gráfico sem recarregar
3. WHEN o gráfico atinge 100 pontos de dados THEN o Sistema SHALL remover o ponto mais antigo antes de adicionar o novo
4. WHEN dados de telemetria incluem temperatura THEN o Sistema SHALL atualizar o gráfico de temperatura em tempo real
5. WHEN dados de telemetria incluem nível de bateria THEN o Sistema SHALL atualizar o indicador de bateria em tempo real
6. WHEN dados de telemetria incluem acelerômetro THEN o Sistema SHALL atualizar o gráfico de movimento em tempo real

### Requirement 4

**User Story:** Como desenvolvedor do sistema, quero que as conexões WebSocket sejam resilientes e se reconectem automaticamente, para que os usuários não percam atualizações em tempo real devido a problemas temporários de rede.

#### Acceptance Criteria

1. WHEN a conexão WebSocket é perdida THEN o Sistema SHALL tentar reconectar automaticamente após 1 segundo
2. WHEN a primeira tentativa de reconexão falha THEN o Sistema SHALL tentar novamente após 2 segundos
3. WHEN tentativas subsequentes falham THEN o Sistema SHALL dobrar o intervalo de espera até um máximo de 30 segundos
4. WHEN a reconexão é bem-sucedida THEN o Sistema SHALL resubscrever automaticamente a todos os canais anteriores
5. WHEN o Sistema está tentando reconectar THEN o Sistema SHALL exibir indicador visual de "Reconectando..." no topo da página
6. WHEN a reconexão é bem-sucedida THEN o Sistema SHALL remover o indicador e exibir mensagem de sucesso por 3 segundos

### Requirement 5

**User Story:** Como profissional de saúde, quero subscrever apenas aos pacientes e dispositivos que estou visualizando, para que eu não receba notificações irrelevantes de outros pacientes.

#### Acceptance Criteria

1. WHEN o usuário acessa a página de detalhes de um paciente THEN o Sistema SHALL subscrever ao canal daquele paciente
2. WHEN o usuário sai da página de detalhes THEN o Sistema SHALL cancelar a subscrição ao canal do paciente
3. WHEN o usuário acessa o dashboard geral THEN o Sistema SHALL subscrever ao canal de alertas globais
4. WHEN o usuário acessa a lista de dispositivos THEN o Sistema SHALL subscrever ao canal de status de dispositivos
5. WHEN o usuário navega entre páginas THEN o Sistema SHALL gerenciar subscrições automaticamente sem intervenção manual


### Requirement 6

**User Story:** Como gestor da instituição, quero ver estatísticas do dashboard atualizando em tempo real, para que eu possa monitorar o estado geral do sistema sem recarregar a página.

#### Acceptance Criteria

1. WHEN o número de pacientes ativos muda THEN o Sistema SHALL enviar evento WebSocket para clientes subscritos ao dashboard institucional
2. WHEN o número de dispositivos online muda THEN o Sistema SHALL atualizar o contador em tempo real
3. WHEN um novo alerta é criado THEN o Sistema SHALL incrementar o contador de alertas ativos em tempo real
4. WHEN um alerta é resolvido THEN o Sistema SHALL decrementar o contador de alertas ativos em tempo real
5. WHEN o compliance médio é recalculado THEN o Sistema SHALL atualizar o valor exibido em tempo real

### Requirement 7

**User Story:** Como desenvolvedor do sistema, quero que o servidor WebSocket envie heartbeats periódicos, para que conexões inativas não sejam fechadas por proxies ou firewalls.

#### Acceptance Criteria

1. WHEN uma conexão WebSocket está ativa THEN o Sistema SHALL enviar mensagem de heartbeat a cada 30 segundos
2. WHEN o cliente recebe heartbeat THEN o Sistema SHALL responder com mensagem de pong
3. WHEN o servidor não recebe pong após 3 heartbeats consecutivos THEN o Sistema SHALL considerar a conexão morta e fechá-la
4. WHEN o cliente não recebe heartbeat por 60 segundos THEN o Sistema SHALL iniciar processo de reconexão
5. WHEN heartbeats são enviados THEN o Sistema SHALL incluir timestamp para sincronização de relógio

### Requirement 8

**User Story:** Como profissional de saúde, quero ver indicador de quantos usuários estão visualizando o mesmo paciente, para que eu possa coordenar com outros profissionais.

#### Acceptance Criteria

1. WHEN um usuário subscreve ao canal de um paciente THEN o Sistema SHALL incrementar o contador de visualizadores
2. WHEN um usuário cancela subscrição THEN o Sistema SHALL decrementar o contador de visualizadores
3. WHEN o contador de visualizadores muda THEN o Sistema SHALL enviar evento para todos os clientes subscritos
4. WHEN há mais de 1 visualizador THEN o Sistema SHALL exibir ícone de olho com número de visualizadores
5. WHEN o usuário passa o mouse sobre o ícone THEN o Sistema SHALL exibir tooltip com nomes dos outros usuários visualizando

### Requirement 9

**User Story:** Como desenvolvedor do sistema, quero que eventos WebSocket sejam autenticados e autorizados, para que apenas usuários com permissão recebam dados sensíveis.

#### Acceptance Criteria

1. WHEN um cliente tenta conectar via WebSocket THEN o Sistema SHALL validar o token JWT fornecido
2. WHEN o token JWT é inválido ou expirado THEN o Sistema SHALL rejeitar a conexão com código de erro apropriado
3. WHEN um cliente tenta subscrever a um canal THEN o Sistema SHALL verificar se o usuário tem permissão para acessar aquele recurso
4. WHEN o usuário não tem permissão THEN o Sistema SHALL rejeitar a subscrição e enviar mensagem de erro
5. WHEN o token JWT expira durante uma conexão ativa THEN o Sistema SHALL fechar a conexão e solicitar reautenticação

### Requirement 10

**User Story:** Como desenvolvedor do sistema, quero que o servidor WebSocket seja escalável horizontalmente, para que possamos adicionar mais instâncias conforme o número de usuários cresce.

#### Acceptance Criteria

1. WHEN múltiplas instâncias do servidor estão rodando THEN o Sistema SHALL usar Redis Pub/Sub para sincronizar eventos entre instâncias
2. WHEN um evento é publicado em uma instância THEN o Sistema SHALL propagar o evento para clientes conectados em outras instâncias
3. WHEN um cliente se conecta THEN o Sistema SHALL poder conectar a qualquer instância disponível
4. WHEN uma instância falha THEN o Sistema SHALL permitir que clientes se reconectem a outra instância sem perda de funcionalidade
5. WHEN eventos são publicados via Redis THEN o Sistema SHALL incluir metadados para evitar loops de propagação

### Requirement 11

**User Story:** Como profissional de saúde, quero receber notificação quando uma sessão de uso do colete é iniciada ou finalizada, para que eu possa acompanhar a aderência em tempo real.

#### Acceptance Criteria

1. WHEN uma sessão de uso é iniciada THEN o Sistema SHALL enviar evento WebSocket para clientes subscritos ao paciente
2. WHEN uma sessão de uso é finalizada THEN o Sistema SHALL enviar evento com duração total da sessão
3. WHEN o evento de início de sessão é recebido THEN o Sistema SHALL exibir indicador "Em Uso" no card do paciente
4. WHEN o evento de fim de sessão é recebido THEN o Sistema SHALL atualizar o contador de horas de uso do dia
5. WHEN o evento de fim de sessão é recebido THEN o Sistema SHALL recalcular e atualizar o compliance do dia em tempo real

### Requirement 12

**User Story:** Como desenvolvedor do sistema, quero logs detalhados de eventos WebSocket, para que eu possa debugar problemas e monitorar a saúde do sistema.

#### Acceptance Criteria

1. WHEN uma conexão WebSocket é estabelecida THEN o Sistema SHALL registrar log com ID do usuário, IP e timestamp
2. WHEN uma conexão é fechada THEN o Sistema SHALL registrar log com motivo do fechamento e duração da conexão
3. WHEN um evento é enviado THEN o Sistema SHALL registrar log com tipo de evento, canal e número de destinatários
4. WHEN ocorre erro na conexão THEN o Sistema SHALL registrar log com detalhes do erro e stack trace
5. WHEN métricas são coletadas THEN o Sistema SHALL incluir número de conexões ativas, eventos por segundo e latência média
