# Requirements Document - Sistema de Analytics e Relatórios

## Introduction

O Sistema de Analytics e Relatórios do OrthoTrack IoT v3 tem como objetivo fornecer visualizações avançadas, análises de dados históricos e relatórios médicos exportáveis para profissionais de saúde e gestores. Este sistema permitirá o acompanhamento detalhado da aderência ao tratamento, identificação de padrões de uso e geração de insights acionáveis para melhorar os resultados clínicos dos pacientes.

## Glossary

- **Sistema**: OrthoTrack IoT Platform v3
- **Dashboard**: Interface web que exibe visualizações e métricas em tempo real
- **Relatório Médico**: Documento estruturado contendo dados clínicos do paciente
- **Compliance**: Taxa de aderência do paciente ao tratamento prescrito
- **Telemetria**: Dados coletados dos sensores do dispositivo ESP32
- **Sessão de Uso**: Período contínuo em que o paciente utiliza o colete ortopédico
- **Dispositivo**: Hardware ESP32 acoplado ao colete ortopédico
- **Paciente**: Usuário final que utiliza o colete com monitoramento IoT
- **Profissional de Saúde**: Médico, fisioterapeuta ou terapeuta ocupacional
- **Período de Análise**: Intervalo de tempo selecionado para análise de dados
- **Métrica**: Valor quantitativo calculado a partir dos dados de telemetria
- **Gráfico de Tendência**: Visualização que mostra evolução de métricas ao longo do tempo
- **Exportação**: Processo de gerar arquivo em formato PDF ou Excel

## Requirements

### Requirement 1

**User Story:** Como profissional de saúde, quero visualizar gráficos de compliance do paciente ao longo do tempo, para que eu possa avaliar a aderência ao tratamento e fazer ajustes quando necessário.

#### Acceptance Criteria

1. WHEN o profissional acessa a página de detalhes do paciente THEN o Sistema SHALL exibir um gráfico de linha mostrando o compliance diário dos últimos 30 dias
2. WHEN o gráfico de compliance é renderizado THEN o Sistema SHALL calcular o compliance como a razão entre horas de uso real e horas prescritas multiplicado por 100
3. WHEN o usuário passa o mouse sobre um ponto do gráfico THEN o Sistema SHALL exibir tooltip com data, horas de uso e percentual de compliance
4. WHEN o compliance de um dia é inferior a 70% THEN o Sistema SHALL destacar o ponto no gráfico com cor vermelha
5. WHEN o compliance de um dia está entre 70% e 90% THEN o Sistema SHALL destacar o ponto no gráfico com cor amarela
6. WHEN o compliance de um dia é superior a 90% THEN o Sistema SHALL destacar o ponto no gráfico com cor verde

### Requirement 2

**User Story:** Como profissional de saúde, quero filtrar os dados de analytics por período customizado, para que eu possa analisar intervalos específicos do tratamento.

#### Acceptance Criteria

1. WHEN o usuário acessa qualquer dashboard de analytics THEN o Sistema SHALL exibir um seletor de período com opções predefinidas (7 dias, 30 dias, 90 dias, 6 meses, 1 ano)
2. WHEN o usuário seleciona um período predefinido THEN o Sistema SHALL atualizar todos os gráficos e métricas para refletir o período selecionado
3. WHEN o usuário seleciona a opção "Período Customizado" THEN o Sistema SHALL exibir dois campos de data (início e fim)
4. WHEN o usuário define um período customizado válido THEN o Sistema SHALL aplicar o filtro e atualizar as visualizações
5. WHEN o usuário define uma data de início posterior à data de fim THEN o Sistema SHALL exibir mensagem de erro e prevenir a aplicação do filtro
6. WHEN o período selecionado não contém dados THEN o Sistema SHALL exibir mensagem informativa indicando ausência de dados

### Requirement 3

**User Story:** Como profissional de saúde, quero visualizar estatísticas agregadas de uso do dispositivo, para que eu possa entender os padrões de comportamento do paciente.

#### Acceptance Criteria

1. WHEN o profissional acessa a página de analytics do paciente THEN o Sistema SHALL calcular e exibir a média de horas de uso diário no período selecionado
2. WHEN as estatísticas são calculadas THEN o Sistema SHALL exibir o total de sessões de uso registradas no período
3. WHEN as estatísticas são calculadas THEN o Sistema SHALL exibir a duração média das sessões de uso
4. WHEN as estatísticas são calculadas THEN o Sistema SHALL exibir o compliance médio do período
5. WHEN as estatísticas são calculadas THEN o Sistema SHALL exibir a sequência atual de dias consecutivos com compliance acima de 90%
6. WHEN não há dados suficientes para calcular uma métrica THEN o Sistema SHALL exibir "N/A" ou mensagem apropriada

### Requirement 4

**User Story:** Como profissional de saúde, quero visualizar um gráfico de distribuição de uso por hora do dia, para que eu possa identificar os horários em que o paciente mais utiliza o dispositivo.

#### Acceptance Criteria

1. WHEN o profissional acessa a seção de padrões de uso THEN o Sistema SHALL exibir um gráfico de barras com 24 colunas representando cada hora do dia
2. WHEN o gráfico de distribuição horária é renderizado THEN o Sistema SHALL calcular o total de minutos de uso para cada hora do dia no período selecionado
3. WHEN o usuário passa o mouse sobre uma barra THEN o Sistema SHALL exibir tooltip com a hora e o total de minutos de uso
4. WHEN o gráfico é exibido THEN o Sistema SHALL destacar as 3 horas com maior uso em cor diferenciada
5. WHEN não há dados de uso para uma hora específica THEN o Sistema SHALL exibir barra com altura zero

### Requirement 5

**User Story:** Como profissional de saúde, quero visualizar um gráfico de distribuição de uso por dia da semana, para que eu possa identificar padrões semanais de aderência.

#### Acceptance Criteria

1. WHEN o profissional acessa a seção de padrões de uso THEN o Sistema SHALL exibir um gráfico de barras com 7 colunas representando cada dia da semana
2. WHEN o gráfico de distribuição semanal é renderizado THEN o Sistema SHALL calcular a média de horas de uso para cada dia da semana no período selecionado
3. WHEN o usuário passa o mouse sobre uma barra THEN o Sistema SHALL exibir tooltip com o dia da semana e a média de horas de uso
4. WHEN o gráfico é exibido THEN o Sistema SHALL ordenar os dias de segunda a domingo
5. WHEN não há dados suficientes para um dia da semana THEN o Sistema SHALL exibir barra com altura zero

### Requirement 6

**User Story:** Como profissional de saúde, quero exportar relatórios médicos em formato PDF, para que eu possa compartilhar com outros profissionais ou incluir no prontuário do paciente.

#### Acceptance Criteria

1. WHEN o profissional clica no botão "Exportar Relatório PDF" THEN o Sistema SHALL gerar um arquivo PDF contendo os dados do paciente e métricas do período selecionado
2. WHEN o PDF é gerado THEN o Sistema SHALL incluir cabeçalho com logo, nome da instituição e data de geração
3. WHEN o PDF é gerado THEN o Sistema SHALL incluir seção com dados demográficos do paciente (nome, idade, ID, prescrição)
4. WHEN o PDF é gerado THEN o Sistema SHALL incluir seção com resumo executivo contendo compliance médio, total de horas de uso e número de sessões
5. WHEN o PDF é gerado THEN o Sistema SHALL incluir gráfico de compliance ao longo do tempo
6. WHEN o PDF é gerado THEN o Sistema SHALL incluir tabela com dados diários de uso
7. WHEN o PDF é gerado THEN o Sistema SHALL incluir rodapé com número de página e data/hora de geração
8. WHEN o PDF é gerado com sucesso THEN o Sistema SHALL iniciar o download automático do arquivo

### Requirement 7

**User Story:** Como profissional de saúde, quero exportar dados de telemetria em formato Excel, para que eu possa realizar análises customizadas em ferramentas externas.

#### Acceptance Criteria

1. WHEN o profissional clica no botão "Exportar Excel" THEN o Sistema SHALL gerar um arquivo XLSX contendo os dados de telemetria do período selecionado
2. WHEN o Excel é gerado THEN o Sistema SHALL criar uma aba "Resumo" com estatísticas agregadas
3. WHEN o Excel é gerado THEN o Sistema SHALL criar uma aba "Uso Diário" com dados de compliance por dia
4. WHEN o Excel é gerado THEN o Sistema SHALL criar uma aba "Sessões" com detalhes de cada sessão de uso
5. WHEN o Excel é gerado THEN o Sistema SHALL criar uma aba "Telemetria" com leituras de sensores
6. WHEN o Excel é gerado THEN o Sistema SHALL formatar datas no padrão DD/MM/YYYY HH:MM:SS
7. WHEN o Excel é gerado THEN o Sistema SHALL aplicar formatação condicional nas células de compliance (verde >90%, amarelo 70-90%, vermelho <70%)
8. WHEN o Excel é gerado com sucesso THEN o Sistema SHALL iniciar o download automático do arquivo

### Requirement 8

**User Story:** Como gestor da instituição, quero visualizar um dashboard consolidado com métricas de todos os pacientes, para que eu possa monitorar a efetividade geral do programa de tratamento.

#### Acceptance Criteria

1. WHEN o gestor acessa o dashboard institucional THEN o Sistema SHALL exibir o número total de pacientes ativos
2. WHEN o dashboard institucional é carregado THEN o Sistema SHALL calcular e exibir o compliance médio de todos os pacientes ativos
3. WHEN o dashboard institucional é carregado THEN o Sistema SHALL exibir o número de dispositivos online, offline e em manutenção
4. WHEN o dashboard institucional é carregado THEN o Sistema SHALL exibir lista dos 10 pacientes com menor compliance no período
5. WHEN o dashboard institucional é carregado THEN o Sistema SHALL exibir lista dos 10 pacientes com maior compliance no período
6. WHEN o dashboard institucional é carregado THEN o Sistema SHALL exibir gráfico de distribuição de compliance (faixas: <50%, 50-70%, 70-90%, >90%)
7. WHEN o usuário clica em um paciente na lista THEN o Sistema SHALL navegar para a página de detalhes daquele paciente

### Requirement 9

**User Story:** Como profissional de saúde, quero visualizar alertas e eventos importantes na timeline do paciente, para que eu possa correlacionar mudanças no comportamento com eventos específicos.

#### Acceptance Criteria

1. WHEN o profissional acessa a página de analytics do paciente THEN o Sistema SHALL exibir uma timeline com eventos importantes
2. WHEN a timeline é renderizada THEN o Sistema SHALL incluir marcadores para alertas críticos gerados no período
3. WHEN a timeline é renderizada THEN o Sistema SHALL incluir marcadores para mudanças na prescrição
4. WHEN a timeline é renderizada THEN o Sistema SHALL incluir marcadores para períodos de inatividade superiores a 48 horas
5. WHEN o usuário clica em um marcador da timeline THEN o Sistema SHALL exibir detalhes do evento em um popover
6. WHEN a timeline é exibida THEN o Sistema SHALL ordenar os eventos cronologicamente do mais recente para o mais antigo

### Requirement 10

**User Story:** Como profissional de saúde, quero visualizar dados de sensores em gráficos de tendência, para que eu possa identificar anomalias ou padrões nos dados biomecânicos.

#### Acceptance Criteria

1. WHEN o profissional acessa a seção de dados de sensores THEN o Sistema SHALL exibir gráfico de linha para temperatura corporal ao longo do tempo
2. WHEN o profissional acessa a seção de dados de sensores THEN o Sistema SHALL exibir gráfico de linha para nível de bateria do dispositivo ao longo do tempo
3. WHEN o profissional acessa a seção de dados de sensores THEN o Sistema SHALL exibir gráfico de linha para dados do acelerômetro (magnitude) ao longo do tempo
4. WHEN um gráfico de sensor é renderizado THEN o Sistema SHALL permitir zoom e pan para análise detalhada
5. WHEN valores de sensor estão fora da faixa normal THEN o Sistema SHALL destacar os pontos anômalos no gráfico
6. WHEN o usuário passa o mouse sobre um ponto THEN o Sistema SHALL exibir tooltip com timestamp e valor exato do sensor

### Requirement 11

**User Story:** Como desenvolvedor do sistema, quero que os cálculos de analytics sejam otimizados e cacheados, para que o dashboard carregue rapidamente mesmo com grandes volumes de dados.

#### Acceptance Criteria

1. WHEN métricas agregadas são solicitadas THEN o Sistema SHALL utilizar queries otimizadas com índices apropriados no banco de dados
2. WHEN métricas agregadas são calculadas THEN o Sistema SHALL armazenar os resultados em cache Redis com TTL de 5 minutos
3. WHEN uma requisição de métricas é recebida THEN o Sistema SHALL verificar o cache antes de executar queries no banco
4. WHEN dados de telemetria são inseridos THEN o Sistema SHALL invalidar o cache relacionado àquele paciente
5. WHEN o dashboard é carregado THEN o Sistema SHALL responder em menos de 2 segundos para períodos de até 1 ano
6. WHEN queries de analytics são executadas THEN o Sistema SHALL utilizar agregações no banco de dados ao invés de processar dados na aplicação

### Requirement 12

**User Story:** Como profissional de saúde, quero comparar o desempenho de um paciente com a média da instituição, para que eu possa contextualizar os resultados individuais.

#### Acceptance Criteria

1. WHEN o profissional visualiza o compliance de um paciente THEN o Sistema SHALL exibir uma linha de referência indicando o compliance médio da instituição
2. WHEN a comparação é exibida THEN o Sistema SHALL calcular a média apenas de pacientes com prescrição similar (±2 horas)
3. WHEN a comparação é exibida THEN o Sistema SHALL indicar se o paciente está acima ou abaixo da média
4. WHEN não há pacientes suficientes para comparação (menos de 5) THEN o Sistema SHALL exibir mensagem indicando dados insuficientes
5. WHEN o usuário passa o mouse sobre a linha de referência THEN o Sistema SHALL exibir tooltip com o valor exato da média e número de pacientes incluídos na comparação
