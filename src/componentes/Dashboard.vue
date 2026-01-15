<template>
  <div class="dashboard">
    <!-- Cards de Métricas Principais -->
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Produtos em estoque</span>
            <span class="metric-value">{{ totalProdutos }}</span>
          </div>
          <div class="metric-icon metric-icon-orange">
            <CubeIcon class="icon" />
          </div>
        </div>
      </div>

      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Caixa {{ caixaAberto ? 'Operacional' : 'Indisponível' }}</span>
            <span class="metric-value metric-value-status" :class="caixaAberto ? 'status-open' : 'status-closed'">
              {{ caixaAberto ? 'Aberto' : 'Fechado' }}
            </span>
          </div>
          <div class="metric-icon" :class="caixaAberto ? 'metric-icon-green' : 'metric-icon-red'">
            <CurrencyDollarIcon class="icon" />
          </div>
        </div>
      </div>

      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Clientes cadastrados</span>
            <span class="metric-value">{{ totalClientes }}</span>
          </div>
          <div class="metric-icon metric-icon-blue">
            <UserGroupIcon class="icon" />
          </div>
        </div>
      </div>

      <div class="metric-card">
        <div class="metric-content">
          <div class="metric-info">
            <span class="metric-label">Saldo Financeiro</span>
            <span class="metric-value" :class="saldoFinanceiro >= 0 ? 'text-positive' : 'text-negative'">
              {{ formatarMoeda(saldoFinanceiro) }}
            </span>
          </div>
          <div class="metric-icon" :class="saldoFinanceiro >= 0 ? 'metric-icon-green' : 'metric-icon-red'">
            <CreditCardIcon class="icon" />
          </div>
        </div>
      </div>
    </div>

    <!-- Seção de Atividades e Ações Rápidas -->
    <div class="dashboard-grid">
      <!-- Vendas Recentes -->
      <div class="dashboard-section">
        <div class="section-header">
          <h2 class="section-title">Vendas Recentes</h2>
          <router-link to="/relatorios" class="section-link">
            Ver todas
            <ArrowRightIcon class="link-icon" />
          </router-link>
        </div>
        <div class="section-content">
          <div v-if="carregandoVendas" class="loading-state">
            <div class="loading-spinner"></div>
            <span>Carregando...</span>
          </div>
          <div v-else-if="vendasRecentes.length === 0" class="empty-state">
            <DocumentTextIcon class="empty-icon" />
            <p>Nenhuma venda recente</p>
          </div>
          <div v-else class="vendas-list">
            <div
              v-for="venda in vendasRecentes"
              :key="venda.id"
              class="venda-item"
            >
              <div class="venda-info">
                <span class="venda-numero">{{ venda.numero_venda }}</span>
                <span class="venda-data">{{ formatarDataHora(venda.created_at) }}</span>
              </div>
              <span class="venda-valor">{{ formatarMoeda(venda.total) }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Produtos com Estoque Baixo -->
      <div class="dashboard-section">
        <div class="section-header">
          <h2 class="section-title">Estoque Baixo</h2>
          <router-link to="/estoque" class="section-link">
            Gerenciar
            <ArrowRightIcon class="link-icon" />
          </router-link>
        </div>
        <div class="section-content">
          <div v-if="carregandoEstoque" class="loading-state">
            <div class="loading-spinner"></div>
            <span>Carregando...</span>
          </div>
          <div v-else-if="produtosEstoqueBaixo.length === 0" class="empty-state">
            <CheckCircleIcon class="empty-icon text-positive" />
            <p>Estoque em dia</p>
          </div>
          <div v-else class="produtos-list">
            <div
              v-for="produto in produtosEstoqueBaixo"
              :key="produto.id"
              class="produto-item"
            >
              <div class="produto-info">
                <span class="produto-nome">{{ produto.nome }}</span>
                <span class="produto-estoque">
                  <span class="badge badge-warning">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Acesso Rápido aos Módulos -->
    <div class="dashboard-section">
      <div class="section-header">
        <h2 class="section-title">Acesso Rápido</h2>
        <p class="section-description">Navegue rapidamente pelos módulos do sistema</p>
      </div>
      <div class="modules-grid">
        <router-link to="/estoque" class="module-card">
          <div class="module-icon module-icon-orange">
            <CubeIcon class="icon" />
          </div>
          <div class="module-content">
            <h3 class="module-title">Estoque</h3>
            <p class="module-description">Produtos e movimentações</p>
          </div>
          <ArrowRightIcon class="module-arrow" />
        </router-link>

        <router-link to="/caixa/carrinho" class="module-card">
          <div class="module-icon module-icon-green">
            <CurrencyDollarIcon class="icon" />
          </div>
          <div class="module-content">
            <h3 class="module-title">Caixa</h3>
            <p class="module-description">Vendas e movimentações</p>
          </div>
          <ArrowRightIcon class="module-arrow" />
        </router-link>

        <router-link to="/clientes" class="module-card">
          <div class="module-icon module-icon-blue">
            <UserGroupIcon class="icon" />
          </div>
          <div class="module-content">
            <h3 class="module-title">Clientes</h3>
            <p class="module-description">Cadastro e histórico</p>
          </div>
          <ArrowRightIcon class="module-arrow" />
        </router-link>

        <router-link to="/financeiro" class="module-card">
          <div class="module-icon module-icon-purple">
            <CreditCardIcon class="icon" />
          </div>
          <div class="module-content">
            <h3 class="module-title">Financeiro</h3>
            <p class="module-description">Contas e pagamentos</p>
          </div>
          <ArrowRightIcon class="module-arrow" />
        </router-link>

        <router-link to="/relatorios" class="module-card">
          <div class="module-icon module-icon-indigo">
            <ChartBarIcon class="icon" />
          </div>
          <div class="module-content">
            <h3 class="module-title">Relatórios</h3>
            <p class="module-description">Análises e estatísticas</p>
          </div>
          <ArrowRightIcon class="module-arrow" />
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda, formatarDataHora } from '@/utils/formatadores'
import { 
  caixaAberto as caixaAbertoStore,
  refreshCaixaState
} from '@/stores/caixa.js'
import {
  CubeIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  CreditCardIcon,
  ArrowRightIcon,
  DocumentTextIcon,
  CheckCircleIcon,
  ChartBarIcon
} from '@heroicons/vue/24/outline'

const totalProdutos = ref(0)
// Use the store's reactive ref
const caixaAberto = caixaAbertoStore
const totalClientes = ref(0)
const saldoFinanceiro = ref(0)
const vendasRecentes = ref([])
const produtosEstoqueBaixo = ref([])
const carregandoVendas = ref(false)
const carregandoEstoque = ref(false)

async function carregarEstatisticas() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Carregar total de produtos
    const { count: countProdutos } = await supabase
      .from('produtos')
      .select('*', { count: 'exact', head: true })
      .eq('usuario_id', user.id)

    totalProdutos.value = countProdutos || 0

    // Refresh cash register state from store
    await refreshCaixaState()

    // Carregar total de clientes
    const { count: countClientes } = await supabase
      .from('clientes')
      .select('*', { count: 'exact', head: true })
      .eq('usuario_id', user.id)

    totalClientes.value = countClientes || 0

    // Calcular saldo financeiro
    const { data: contas } = await supabase
      .from('contas_financeiras')
      .select('valor, tipo')
      .eq('usuario_id', user.id)
      .eq('status', 'pendente')

    if (contas) {
      saldoFinanceiro.value = contas.reduce((acc, conta) => {
        return acc + (conta.tipo === 'receber' ? conta.valor : -conta.valor)
      }, 0)
    }
  } catch (error) {
    console.error('Erro ao carregar estatísticas:', error)
  }
}

async function carregarVendasRecentes() {
  carregandoVendas.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('vendas')
      .select('id, numero_venda, total, created_at')
      .eq('usuario_id', user.id)
      .order('created_at', { ascending: false })
      .limit(4)

    if (error) throw error
    vendasRecentes.value = data || []
  } catch (error) {
    console.error('Erro ao carregar vendas recentes:', error)
  } finally {
    carregandoVendas.value = false
  }
}

async function carregarProdutosEstoqueBaixo() {
  carregandoEstoque.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('produtos')
      .select('id, nome, quantidade, estoque_minimo, unidade')
      .eq('usuario_id', user.id)
      .not('estoque_minimo', 'is', null)

    if (error) throw error
    
    // Filtrar produtos onde quantidade <= estoque_minimo
    if (data) {
      produtosEstoqueBaixo.value = data
        .filter(p => p.quantidade <= (p.estoque_minimo || 0))
        .sort((a, b) => a.quantidade - b.quantidade)
        .slice(0, 4)
    } else {
      produtosEstoqueBaixo.value = []
    }
  } catch (error) {
    console.error('Erro ao carregar produtos com estoque baixo:', error)
    produtosEstoqueBaixo.value = []
  } finally {
    carregandoEstoque.value = false
  }
}

function onVendaFinalizada() {
  carregarEstatisticas()
  carregarVendasRecentes()
  carregarProdutosEstoqueBaixo()
}

function onMovimentacaoRegistrada() {
  carregarEstatisticas()
}

function onMovimentacaoEstoqueRegistrada() {
  carregarEstatisticas()
  carregarProdutosEstoqueBaixo()
}

function onContaFinanceiraRegistrada() {
  carregarEstatisticas()
}

onMounted(async () => {
  await carregarEstatisticas()
  carregarVendasRecentes()
  carregarProdutosEstoqueBaixo()
  window.addEventListener('venda-finalizada', onVendaFinalizada)
  window.addEventListener('movimentacao-registrada', onMovimentacaoRegistrada)
  window.addEventListener('movimentacao-estoque-registrada', onMovimentacaoEstoqueRegistrada)
  window.addEventListener('conta-financeira-registrada', onContaFinanceiraRegistrada)
})

onUnmounted(() => {
  window.removeEventListener('venda-finalizada', onVendaFinalizada)
  window.removeEventListener('movimentacao-registrada', onMovimentacaoRegistrada)
  window.removeEventListener('movimentacao-estoque-registrada', onMovimentacaoEstoqueRegistrada)
  window.removeEventListener('conta-financeira-registrada', onContaFinanceiraRegistrada)
})
</script>

<style scoped>
.dashboard {
  max-width: 1400px;
  margin: 0 auto;
}

/* Header */
.dashboard-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1.5rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #e5e7eb;
}

.dashboard-title {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.25rem 0;
}

.dashboard-subtitle {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

.dashboard-date {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

/* Métricas */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.metric-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1rem;
  transition: all 0.2s ease;
}

.metric-card:hover {
  border-color: #d1d5db;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.metric-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.metric-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.metric-label {
  font-size: 0.75rem;
  font-weight: 500;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.metric-value {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  line-height: 1.2;
}

.metric-value-status {
  font-size: 1.25rem;
}

.status-open {
  color: #059669;
}

.status-closed {
  color: #dc2626;
}

.metric-hint {
  font-size: 0.75rem;
  color: #9ca3af;
}

.metric-icon {
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.metric-icon .icon {
  width: 1.25rem;
  height: 1.25rem;
}

.metric-icon-orange {
  background: #fef3c7;
  color: #d97706;
}

.metric-icon-green {
  background: #d1fae5;
  color: #059669;
}

.metric-icon-blue {
  background: #dbeafe;
  color: #2563eb;
}

.metric-icon-red {
  background: #fee2e2;
  color: #dc2626;
}

.metric-icon-purple {
  background: #f3e8ff;
  color: #7c3aed;
}

.metric-icon-indigo {
  background: #e0e7ff;
  color: #4f46e5;
}

.metric-icon-cyan {
  background: #cffafe;
  color: #0891b2;
}

.module-icon-orange {
  background: #f3f4f6;
  color: #111827;
}

.module-icon-green {
  background: #f3f4f6;
  color: #111827;
}

.module-icon-cyan {
  background: #f3f4f6;
  color: #111827;
}

.module-icon-blue {
  background: #f3f4f6;
  color: #111827;
}

.module-icon-purple {
  background: #f3f4f6;
  color: #111827;
}

.module-icon-indigo {
  background: #f3f4f6;
  color: #111827;
}

.text-positive {
  color: #059669;
}

.text-negative {
  color: #dc2626;
}

/* Grid Principal */
.dashboard-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

/* Seções */
.dashboard-section {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1.25rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #f3f4f6;
}

.section-title {
  font-size: 1rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.section-description {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0.25rem 0 0 0;
}

.section-link {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #ea580c;
  text-decoration: none;
  transition: color 0.2s ease;
}

.section-link:hover {
  color: #c2410c;
}

.link-icon {
  width: 0.875rem;
  height: 0.875rem;
}

.section-content {
  min-height: 100px;
}

/* Listas */
.vendas-list,
.produtos-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.venda-item,
.produto-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.625rem;
  background: #f9fafb;
  border-radius: 0.375rem;
  transition: background-color 0.2s ease;
}

.venda-item:hover,
.produto-item:hover {
  background: #f3f4f6;
}

.venda-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.venda-numero {
  font-size: 0.875rem;
  font-weight: 600;
  color: #111827;
}

.venda-data {
  font-size: 0.75rem;
  color: #6b7280;
}

.venda-valor {
  font-size: 0.875rem;
  font-weight: 600;
  color: #059669;
}

.produto-info {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
  flex: 1;
}

.produto-nome {
  font-size: 0.875rem;
  font-weight: 500;
  color: #111827;
}

.produto-estoque {
  display: flex;
  align-items: center;
}

.badge {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.625rem;
  border-radius: 0.375rem;
  font-size: 0.75rem;
  font-weight: 500;
}

.badge-warning {
  background: #fef3c7;
  color: #d97706;
}

/* Estados Vazios */
.empty-state,
.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
  text-align: center;
  color: #6b7280;
}

.empty-icon {
  width: 3rem;
  height: 3rem;
  margin-bottom: 0.75rem;
  opacity: 0.5;
}

.empty-state p {
  font-size: 0.875rem;
  margin: 0;
}

.loading-spinner {
  width: 2rem;
  height: 2rem;
  border: 2px solid #e5e7eb;
  border-top-color: #2563eb;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
  margin-bottom: 0.75rem;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* Módulos */
.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 0.75rem;
}

.module-card {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  text-decoration: none;
  transition: all 0.2s ease;
  cursor: pointer;
}

.module-card:hover {
  background: white;
  border-color: #d1d5db;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.module-icon {
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 0.375rem;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.module-icon .icon {
  width: 1.125rem;
  height: 1.125rem;
}

.module-content {
  flex: 1;
  min-width: 0;
}

.module-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.125rem 0;
}

.module-description {
  font-size: 0.75rem;
  color: #6b7280;
  margin: 0;
  line-height: 1.3;
}

.module-arrow {
  width: 0.875rem;
  height: 0.875rem;
  color: #9ca3af;
  flex-shrink: 0;
  transition: transform 0.2s ease;
}

.module-card:hover .module-arrow {
  transform: translateX(2px);
  color: #6b7280;
}

/* Responsividade */
@media (max-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .modules-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .dashboard-header {
    flex-direction: column;
    gap: 0.5rem;
  }

  .metrics-grid {
    grid-template-columns: 1fr;
    gap: 0.75rem;
  }

  .metric-card {
    padding: 0.875rem;
  }

  .metric-value {
    font-size: 1.5rem;
  }

  .dashboard-grid {
    grid-template-columns: 1fr;
  }

  .modules-grid {
    grid-template-columns: 1fr;
  }

  .module-card {
    padding: 0.75rem;
  }

  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }

  .section-title {
    font-size: 0.95rem;
  }

  .venda-item,
  .produto-item {
    padding: 0.5rem;
  }
}

@media (max-width: 480px) {
  .metric-icon {
    width: 2rem;
    height: 2rem;
  }

  .metric-icon .icon {
    width: 1rem;
    height: 1rem;
  }

  .metric-label {
    font-size: 0.75rem;
  }

  .metric-value {
    font-size: 1.25rem;
  }

  .module-title {
    font-size: 0.8125rem;
  }

  .module-description {
    font-size: 0.7rem;
  }
}
</style>
