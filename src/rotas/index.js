import { createRouter, createWebHistory } from 'vue-router'
import { useAutenticacaoStore } from '@/stores/autenticacao.js'

const rotas = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/componentes/Login.vue'),
    meta: { requerAutenticacao: false }
  },
  {
    path: '/',
    component: () => import('@/componentes/LayoutDashboard.vue'),
    meta: { requerAutenticacao: true },
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('@/componentes/Dashboard.vue')
      },
      {
        path: 'estoque',
        name: 'Estoque',
        component: () => import('@/modulos/estoque/EstoqueView.vue')
      },
      {
        path: 'caixa',
        name: 'Caixa',
        redirect: '/caixa/carrinho',
        children: [
          {
            path: 'carrinho',
            name: 'CaixaCarrinho',
            component: () => import('@/modulos/caixa/CaixaView.vue')
          },
          {
            path: 'movimentacoes',
            name: 'CaixaMovimentacoes',
            component: () => import('@/modulos/caixa/MovimentacoesView.vue')
          },
          {
            path: 'historico-vendas',
            name: 'CaixaHistoricoVendas',
            component: () => import('@/modulos/caixa/HistoricoView.vue')
          },
          {
            path: 'historico-movimentacoes',
            name: 'CaixaHistoricoMovimentacoes',
            component: () => import('@/modulos/caixa/HistoricoMovimentacoesView.vue')
          }
        ]
      },
      {
        path: 'clientes',
        name: 'Clientes',
        component: () => import('@/modulos/clientes/ClientesView.vue')
      },
      {
        path: 'financeiro',
        name: 'Financeiro',
        component: () => import('@/modulos/financeiro/FinanceiroView.vue')
      },
      {
        path: 'relatorios',
        name: 'Relatorios',
        component: () => import('@/modulos/relatorios/RelatoriosView.vue')
      }
    ]
  }
]

const roteador = createRouter({
  history: createWebHistory(),
  routes: rotas
})

// Guard de navegação para proteger rotas
roteador.beforeEach(async (to, _from, next) => {
  if (to.meta.requerAutenticacao) {
    const autenticacaoStore = useAutenticacaoStore()
    
    // Se não está autenticado, verificar sessão
    if (!autenticacaoStore.estaAutenticado) {
      const { supabase } = await import('@/servicos/supabase')
      const { data: { session } } = await supabase.auth.getSession()
      
      if (!session) {
        next('/login')
        return
      }
    }
  }

  next()
})

export default roteador
