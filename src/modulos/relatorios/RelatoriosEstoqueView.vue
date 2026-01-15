<template>
  <div class="relatorios-estoque-view">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header-content">
        <div class="page-icon-wrapper page-icon-estoque">
          <CubeIcon class="page-icon" />
        </div>
        <div>
          <h2 class="page-title">Relatórios de Estoque</h2>
          <p class="page-subtitle">Análises e indicadores do estoque</p>
        </div>
      </div>
    </div>

    <!-- Filtros de Período -->
    <div class="card">
      <div class="card-body">
        <div class="filters-row">
          <div class="filter-field">
            <label class="filter-label">Data Inicial</label>
            <input
              v-model="dataInicial"
              type="date"
              class="form-input"
              @change="carregarRelatorios"
            />
          </div>
          <div class="filter-field">
            <label class="filter-label">Data Final</label>
            <input
              v-model="dataFinal"
              type="date"
              class="form-input"
              @change="carregarRelatorios"
            />
          </div>
          <button
            @click="resetarFiltros"
            class="btn btn-secondary"
          >
            Limpar Filtros
          </button>
        </div>
      </div>
    </div>

    <!-- Cards de Resumo -->
    <div class="summary-grid">
      <div class="summary-card">
        <div class="summary-card-icon summary-icon-blue">
          <CubeIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Produtos em Estoque</div>
          <div class="summary-card-value">{{ resumo.totalProdutos }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-green">
          <CurrencyDollarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Valor Total do Estoque</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.valorTotal) }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-yellow">
          <ExclamationTriangleIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Produtos com Estoque Baixo</div>
          <div class="summary-card-value">{{ resumo.produtosEstoqueBaixo }}</div>
        </div>
      </div>
    </div>

    <!-- Seções de Relatórios -->
    <div class="reports-grid">
      <!-- Produtos Mais Vendidos -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Produtos Mais Vendidos</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="produtosMaisVendidos.length === 0" class="empty-state">
            <p>Nenhuma venda registrada no período</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="(item, index) in produtosMaisVendidos" :key="item.produto_id" class="report-item">
              <span class="report-position">{{ index + 1 }}º</span>
              <span class="report-name">{{ item.nome }}</span>
              <span class="report-value">{{ item.quantidade }} un</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Produtos com Estoque Baixo -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Estoque Baixo</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="produtosEstoqueBaixo.length === 0" class="empty-state">
            <p>Nenhum produto com estoque baixo</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="produto in produtosEstoqueBaixo" :key="produto.id" class="report-item report-item-alert">
              <span class="report-name">{{ produto.nome }}</span>
              <span class="report-value">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Produtos Parados -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Produtos Parados</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="produtosParados.length === 0" class="empty-state">
            <p>Todos os produtos tiveram movimentação</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="produto in produtosParados" :key="produto.id" class="report-item">
              <span class="report-name">{{ produto.nome }}</span>
              <span class="report-value">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import {
  CubeIcon,
  CurrencyDollarIcon,
  ExclamationTriangleIcon
} from '@heroicons/vue/24/outline'

const carregando = ref(false)
const dataInicial = ref('')
const dataFinal = ref('')

const resumo = ref({
  totalProdutos: 0,
  valorTotal: 0,
  produtosEstoqueBaixo: 0
})

const produtosMaisVendidos = ref([])
const produtosEstoqueBaixo = ref([])
const produtosParados = ref([])

async function carregarRelatorios() {
  carregando.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Carregar produtos
    const { data: produtos } = await supabase
      .from('produtos')
      .select('*')
      .eq('usuario_id', user.id)

    if (produtos) {
      resumo.value.totalProdutos = produtos.length
      resumo.value.valorTotal = produtos.reduce((sum, p) => {
        const preco = parseFloat(p.preco_unitario) || 0
        const quantidade = parseFloat(p.quantidade) || 0
        return sum + (preco * quantidade)
      }, 0)
      resumo.value.produtosEstoqueBaixo = produtos.filter(p => p.quantidade <= (p.estoque_minimo || 5)).length
      
      produtosEstoqueBaixo.value = produtos
        .filter(p => p.quantidade <= (p.estoque_minimo || 5))
        .slice(0, 10)
    }

    // Carregar produtos mais vendidos
    let query = supabase
      .from('itens_venda')
      .select(`
        produto_id,
        quantidade,
        produtos (nome)
      `)
      .eq('produtos.usuario_id', user.id)

    if (dataInicial.value) {
      query = query.gte('created_at', dataInicial.value)
    }
    if (dataFinal.value) {
      query = query.lte('created_at', dataFinal.value + 'T23:59:59')
    }

    const { data: itensVenda } = await query

    if (itensVenda) {
      const vendidosPorProduto = {}
      itensVenda.forEach(item => {
        if (!vendidosPorProduto[item.produto_id]) {
          vendidosPorProduto[item.produto_id] = {
            produto_id: item.produto_id,
            nome: item.produtos?.nome || 'Produto',
            quantidade: 0
          }
        }
        vendidosPorProduto[item.produto_id].quantidade += item.quantidade
      })

      produtosMaisVendidos.value = Object.values(vendidosPorProduto)
        .sort((a, b) => b.quantidade - a.quantidade)
        .slice(0, 10)
    }

    // Produtos parados (sem vendas no período)
    if (produtos && itensVenda) {
      const produtosVendidos = new Set(itensVenda.map(i => i.produto_id))
      produtosParados.value = produtos
        .filter(p => !produtosVendidos.has(p.id) && p.quantidade > 0)
        .slice(0, 10)
    }

  } catch (err) {
    console.error('Erro ao carregar relatórios:', err)
  } finally {
    carregando.value = false
  }
}

function resetarFiltros() {
  const hoje = new Date()
  dataInicial.value = new Date(hoje.getFullYear(), hoje.getMonth(), 1).toISOString().split('T')[0]
  dataFinal.value = hoje.toISOString().split('T')[0]
  carregarRelatorios()
}

onMounted(() => {
  resetarFiltros()
})
</script>

<style scoped>
@import '@/estilos/relatorios-comum.css';
</style>
