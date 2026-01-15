# PDV SALVA

Sistema completo de gestão empresarial para controle de estoque, caixa, clientes e finanças.

## Sobre o Projeto

O AIShop é uma aplicação web moderna desenvolvida em Vue 3 para gerenciamento empresarial completo, oferecendo soluções integradas para pequenas e médias empresas que necessitam de controle eficiente de suas operações comerciais.

## Características Principais

- Interface moderna e responsiva com design profissional
- Sistema de autenticação seguro baseado em usuários
- Dashboard com métricas e estatísticas em tempo real
- Controle completo de estoque com histórico de movimentações
- Sistema de caixa com controle de abertura e fechamento
- Gestão de clientes com histórico de compras
- Módulo financeiro para controle de contas a pagar e receber
- Relatórios detalhados de vendas e movimentações
- Sistema de categorias inteligente para produtos
- Numeração sequencial automática de vendas
- Integração com banco de dados PostgreSQL via Supabase
- Design responsivo que funciona em desktop e mobile

## Tecnologias Utilizadas

### Frontend
- Vue 3 (Framework principal)
- Vite (Build tool e servidor de desenvolvimento)
- Tailwind CSS (Framework CSS utilitário)
- Pinia (Gerenciamento de estado)
- Vue Router (Roteamento da aplicação)

### Backend e Banco de Dados
- Supabase (Backend como serviço - PostgreSQL)
- Row Level Security (Controle de acesso por usuário)
- Funções PostgreSQL personalizadas

### Bibliotecas Principais
- @supabase/supabase-js (Cliente Supabase)
- axios (Requisições HTTP)
- date-fns (Manipulação de datas)
- @headlessui/vue (Componentes UI acessíveis)
- @heroicons/vue (Ícones SVG)

## Estrutura do Projeto

```
AIShop/
├── src/                          # Código fonte principal
│   ├── componentes/              # Componentes Vue reutilizáveis
│   │   ├── Dashboard.vue         # Dashboard principal
│   │   ├── LayoutDashboard.vue   # Layout base do sistema
│   │   ├── Login.vue             # Tela de autenticação
│   │   ├── ModalConfirmacao.vue  # Componente de confirmação
│   │   └── Toast.vue             # Notificações toast
│   ├── estilos/                  # Arquivos de estilo
│   │   └── principal.css         # Estilos globais
│   ├── modulos/                  # Módulos funcionais
│   │   ├── caixa/                # Módulo de caixa
│   │   ├── clientes/             # Módulo de clientes
│   │   ├── estoque/              # Módulo de estoque
│   │   ├── financeiro/           # Módulo financeiro
│   │   ├── movimentacoes/        # Módulo de movimentações
│   │   └── relatorios/           # Módulo de relatórios
│   ├── rotas/                    # Configuração de rotas
│   │   └── index.js              # Definição das rotas
│   ├── servicos/                 # Serviços externos
│   │   └── supabase.js           # Configuração Supabase
│   ├── stores/                   # Stores Pinia
│   │   └── autenticacao.js       # Store de autenticação
│   ├── utils/                    # Funções utilitárias
│   │   └── formatadores.js       # Formatadores de dados
│   ├── App.vue                   # Componente raiz
│   └── main.js                   # Ponto de entrada da aplicação
├── database/                     # Scripts de banco de dados
│   └── escopo.sql                # Schema e migrações
├── docs/                         # Documentação
│   └── README.md                 # Este arquivo
├── public/                       # Arquivos públicos
├── index.html                    # HTML principal
├── package.json                  # Dependências e scripts
├── vite.config.js               # Configuração Vite
├── tailwind.config.js           # Configuração Tailwind
└── netlify.toml                 # Configuração de deploy
```

## Instalação

### Pré-requisitos
- Node.js 16+
- npm ou yarn
- Conta no Supabase (para backend)

### Para Desenvolvimento
1. Clone o repositório
2. Instale as dependências:
   ```bash
   npm install
   ```
3. Configure as variáveis de ambiente:
   - Crie um arquivo `.env` na raiz do projeto
   - Adicione as credenciais do Supabase
4. Execute o servidor de desenvolvimento:
   ```bash
   npm run dev
   ```

### Build para Produção
```bash
npm run build
```

### Deploy
O projeto pode ser facilmente implantado em:
- Netlify (configurado via netlify.toml)
- Vercel
- Qualquer plataforma que suporte SPA (Single Page Application)

## Funcionalidades

### Dashboard
- Visão geral das métricas principais
- Gráficos de vendas e movimentações
- Indicadores de performance em tempo real
- Acesso rápido aos módulos principais

### Módulo de Estoque
- Cadastro completo de produtos
- Controle de estoque mínimo
- Histórico de movimentações
- Sistema de categorias inteligente
- Código de barras e código interno
- Preço de custo e preço de venda
- Margem de lucro automática

### Módulo de Caixa
- Abertura e fechamento de caixa
- Controle de valores iniciais e finais
- Histórico de movimentações
- Vendas diárias com numeração sequencial
- Relatório de fechamento detalhado
- Controle de diferentes formas de pagamento

### Sistema de Vendas
- Registro completo de vendas
- Adição de produtos via pesquisa
- Cálculo automático de totais e descontos
- Suporte a múltiplas formas de pagamento
- Geração de cupom fiscal
- Histórico de vendas por cliente

### Módulo de Clientes
- Cadastro completo de clientes
- Histórico de compras
- Controle de limite de crédito
- Programa de fidelidade (pontos)
- Tipos de clientes (PF/PJ)
- Data de nascimento e informações adicionais

### Módulo Financeiro
- Controle de contas a pagar e receber
- Classificação por categorias
- Controle de datas de vencimento
- Status de pagamento
- Relatórios financeiros

### Relatórios
- Relatórios de vendas por período
- Relatórios de movimentações de caixa
- Relatórios de estoque
- Relatórios financeiros
- Exportação para diversos formatos

### Segurança
- Autenticação por usuário
- Controle de acesso baseado em perfil
- Criptografia de dados sensíveis
- Backup automático no Supabase

## Documentação

Documentação completa disponível na pasta `docs/`:
- **Este arquivo**: Visão geral do projeto
- **API Documentation**: Integração com Supabase
- **Development Guide**: Guia para desenvolvedores
- **Deployment Guide**: Instruções de implantação

## Suporte

Para suporte técnico ou dúvidas sobre o sistema:
- Email: contato@salvasolucoes.com.br
- Telefone: (61) 99196-3651
- Documentação: Consulte os arquivos em `docs/`

## Desenvolvido por

**Salva Soluções Ltda** - Soluções em tecnologia para negócios

---

*AIShop - Transformando a gestão empresarial através da tecnologia*
