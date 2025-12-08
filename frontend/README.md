# 📊 Frontend Dashboard - OrthoTrack IoT Platform v3

## 📋 Visão Geral

Dashboard administrativo web para gerenciamento e monitoramento da plataforma OrthoTrack IoT. Desenvolvido com SvelteKit, oferece interface moderna e responsiva para visualização de dados, gerenciamento de pacientes, dispositivos e alertas.

## 🛠️ Stack Tecnológico

- **Framework**: SvelteKit 1.27+
- **Linguagem**: TypeScript
- **Estilização**: Tailwind CSS 3.3+
- **Gráficos**: Chart.js 4.4+
- **Ícones**: Lucide Svelte
- **Notificações**: Svelte Sonner
- **Tabelas**: TanStack Svelte Table
- **Build**: Vite 4.5+

## 📁 Estrutura do Projeto

```
frontend/
├── src/
│   ├── lib/
│   │   ├── components/          # Componentes reutilizáveis
│   │   │   ├── ui/              # Componentes base (Button, Card, etc)
│   │   │   ├── charts/          # Componentes de gráficos
│   │   │   ├── tables/          # Componentes de tabelas
│   │   │   └── layout/          # Componentes de layout
│   │   ├── services/            # Serviços de API
│   │   │   ├── api.ts           # Cliente HTTP base
│   │   │   ├── auth.service.ts  # Autenticação
│   │   │   ├── patients.service.ts
│   │   │   ├── devices.service.ts
│   │   │   └── alerts.service.ts
│   │   └── stores/              # Stores Svelte
│   │       ├── auth.store.ts     # Estado de autenticação
│   │       ├── patients.store.ts
│   │       └── devices.store.ts
│   ├── routes/                  # Rotas SvelteKit
│   │   ├── +layout.svelte        # Layout principal
│   │   ├── +page.svelte          # Dashboard principal
│   │   ├── login/                # Página de login
│   │   ├── patients/             # Gerenciamento de pacientes
│   │   ├── devices/              # Gerenciamento de dispositivos
│   │   └── alerts/               # Gerenciamento de alertas
│   ├── app.css                   # Estilos globais
│   └── app.html                  # Template HTML
├── static/                       # Arquivos estáticos
├── package.json
└── vite.config.ts
```

## 🚀 Início Rápido

### Instalação

```bash
cd frontend
npm install
```

### Desenvolvimento

```bash
# Iniciar servidor de desenvolvimento
npm run dev

# O frontend estará disponível em http://localhost:5173
```

### Build para Produção

```bash
npm run build
npm run preview
```

## 🔧 Configuração

### Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
VITE_API_BASE_URL=http://72.60.50.248:8080
VITE_WS_URL=ws://72.60.50.248:8080/ws
```

### Para Desenvolvimento Local

```env
VITE_API_BASE_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080/ws
```

## 📊 Funcionalidades

### Dashboard Principal

- **Visão Geral**: Estatísticas gerais do sistema
- **Gráficos de Compliance**: Visualização de aderência ao tratamento
- **Alertas Recentes**: Lista de alertas críticos
- **Dispositivos Online**: Status em tempo real dos dispositivos
- **Métricas de Uso**: Estatísticas de uso dos dispositivos

### Gerenciamento de Pacientes

- Listagem de pacientes
- Criação e edição de pacientes
- Visualização de histórico de uso
- Relatórios de compliance
- Exportação de dados

### Gerenciamento de Dispositivos

- Listagem de dispositivos (braces)
- Status em tempo real
- Envio de comandos
- Histórico de telemetria
- Configurações de alertas

### Sistema de Alertas

- Listagem de alertas
- Filtros por severidade e tipo
- Resolução de alertas
- Estatísticas de alertas
- Notificações em tempo real

## 🔐 Autenticação

O frontend usa JWT (JSON Web Tokens) para autenticação. O token é armazenado no localStorage e enviado em todas as requisições via header `Authorization: Bearer <token>`.

### Fluxo de Autenticação

1. Usuário faz login em `/login`
2. Backend retorna token JWT
3. Token é armazenado no localStorage
4. Todas as requisições subsequentes incluem o token
5. Token expira após 24 horas (configurável)

## 📡 Integração com Backend

### Endpoints Utilizados

#### Autenticação
- `POST /api/v1/auth/login` - Login

#### Pacientes
- `GET /api/v1/patients` - Listar pacientes
- `POST /api/v1/patients` - Criar paciente
- `GET /api/v1/patients/:id` - Obter paciente
- `PUT /api/v1/patients/:id` - Atualizar paciente
- `DELETE /api/v1/patients/:id` - Deletar paciente

#### Dispositivos
- `GET /api/v1/braces` - Listar dispositivos
- `POST /api/v1/braces` - Criar dispositivo
- `GET /api/v1/braces/:id` - Obter dispositivo
- `PUT /api/v1/braces/:id` - Atualizar dispositivo
- `DELETE /api/v1/braces/:id` - Deletar dispositivo
- `POST /api/v1/braces/:id/commands` - Enviar comando

#### Alertas
- `GET /api/v1/alerts` - Listar alertas
- `PUT /api/v1/alerts/:id/resolve` - Resolver alerta
- `GET /api/v1/alerts/statistics` - Estatísticas

#### Dashboard
- `GET /api/v1/dashboard/overview` - Visão geral
- `GET /api/v1/dashboard/realtime` - Dados em tempo real
- `GET /api/v1/reports/compliance` - Relatório de compliance
- `GET /api/v1/reports/usage` - Relatório de uso

#### WebSocket
- `ws://<host>:8080/ws` - Conexão WebSocket para dados em tempo real

## 🎨 Componentes

### Componentes Base (UI)

- `Button` - Botões estilizados
- `Card` - Cards de conteúdo
- `Input` - Campos de entrada
- `Select` - Seletores
- `Modal` - Modais
- `Toast` - Notificações toast
- `Badge` - Badges de status
- `Table` - Tabelas

### Componentes de Gráficos

- `LineChart` - Gráficos de linha
- `BarChart` - Gráficos de barras
- `PieChart` - Gráficos de pizza
- `ComplianceChart` - Gráfico de compliance
- `UsageChart` - Gráfico de uso

### Componentes de Layout

- `Sidebar` - Barra lateral de navegação
- `Header` - Cabeçalho
- `Footer` - Rodapé
- `PageLayout` - Layout de página

## 🔄 Estado Global (Stores)

### Auth Store

Gerencia estado de autenticação:

```typescript
import { authStore } from '$lib/stores/auth.store';

// Verificar se está autenticado
$authStore.isAuthenticated

// Obter usuário atual
$authStore.user

// Fazer login
authStore.login(email, password)

// Fazer logout
authStore.logout()
```

### Patients Store

Gerencia estado de pacientes:

```typescript
import { patientsStore } from '$lib/stores/patients.store';

// Listar pacientes
await patientsStore.fetchPatients()

// Criar paciente
await patientsStore.createPatient(data)

// Atualizar paciente
await patientsStore.updatePatient(id, data)
```

## 📱 Responsividade

O dashboard é totalmente responsivo e funciona em:
- Desktop (1920px+)
- Laptop (1366px+)
- Tablet (768px+)
- Mobile (320px+)

## 🌙 Modo Escuro

O dashboard suporta modo escuro/claro com toggle automático baseado nas preferências do sistema.

## 🧪 Testes

```bash
# Executar testes
npm run test

# Testes com cobertura
npm run test:coverage
```

## 📦 Deploy

### Build de Produção

```bash
npm run build
```

Os arquivos gerados estarão em `build/`.

### Deploy no Servidor

```bash
# Copiar arquivos para servidor
rsync -avz build/ root@72.60.50.248:/var/www/orthotrack-frontend/

# Ou usar Nginx como proxy reverso
```

### Configuração Nginx

```nginx
server {
    listen 80;
    server_name orthotrack.example.com;

    root /var/www/orthotrack-frontend;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🐛 Troubleshooting

### Erro de CORS

Se encontrar erros de CORS, verifique se o backend está configurado para aceitar requisições do frontend.

### Token Expirado

O token JWT expira após 24 horas. O usuário será redirecionado para a página de login automaticamente.

### WebSocket não conecta

Verifique se o backend está rodando e se a URL do WebSocket está correta nas variáveis de ambiente.

## 📚 Documentação Adicional

- [SvelteKit Docs](https://kit.svelte.dev/docs)
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [Chart.js Docs](https://www.chartjs.org/docs)

## 🔗 Links Úteis

- **Backend API**: http://72.60.50.248:8080
- **Swagger Docs**: http://72.60.50.248:8080/swagger/index.html
- **Health Check**: http://72.60.50.248:8080/api/v1/health







