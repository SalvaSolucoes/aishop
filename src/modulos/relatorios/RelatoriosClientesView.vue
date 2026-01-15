<template>
  <div class="relatorios-clientes-view">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header-content">
        <div class="page-icon-wrapper page-icon-clientes">
          <UserGroupIcon class="page-icon" />
        </div>
        <div>
          <h2 class="page-title">Relatórios de Clientes</h2>
          <p class="page-subtitle">Análises e indicadores de clientes</p>
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
        <div class="summary-card-icon summary-icon-purple">
          <UserGroupIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Total de Clientes</div>
          <div class="summary-card-value">{{ resumo.totalClientes }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-green">
          <CurrencyDollarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Total em Vendas</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.totalVendas) }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-blue">
          <ChartBarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Ticket Médio</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.ticketMedio) }}</div>
        </div>
      </div>
    </div>

    <!-- Seções de Relatórios -->
    <div class="reports-grid">
      <!-- Clientes que Mais Compraram -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Clientes que Mais Compraram</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="clientesTop.length === 0" class="empty-state">
            <p>Nenhuma venda registrada no período</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="(item, index) in clientesTop" :key="item.cliente_id" class="report-item">
              <span class="report-position">{{ index + 1 }}º</span>
              <span class="report-name">{{ item.nome }}</span>
              <span class="report-value">{{ formatarMoeda(item.total) }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Novos Clientes -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Novos Clientes</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="novosClientes.length === 0" class="empty-state">
            <p>Nenhum cliente novo no período</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="cliente in novosClientes" :key="cliente.id" class="report-item">
              <span class="report-name">{{ cliente.nome }}</span>
              <span class="report-value">{{ formatarData(cliente.created_at) }}</span>
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
  UserGroupIcon,
  CurrencyDollarIcon,
  ChartBarIcon
} from '@heroicons/vue/24/outline'

const carregando = ref(false)
const dataInicial = ref('')
const dataFinal = ref('')

const resumo = ref({
  totalClientes: 0,
  totalVendas: 0,
  ticketMedio: 0
})

const clientesTop = ref([])
const novosClientes = ref([])

function formatarData(data) {
  return new Date(data).toLocaleDateString('pt-BR')
}

async function carregarRelatorios() {
  carregando.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Carregar clientes
    const { data: clientes } = await supabase
      .from('clientes')
      .select('*')
      .eq('usuario_id', user.id)

    if (clientes) {
      resumo.value.totalClientes = clientes.length

      // Novos clientes no período
      if (dataInicial.value && dataFinal.value) {
        novosClientes.value = clientes
          .filter(c => {
            const dataCriacao = c.created_at.split('T')[0]
            return dataCriacao >= dataInicial.value && dataCriacao <= dataFinal.value
          })
          .slice(0, 10)
      }
    }

    // Carregar vendas por cliente
    let queryVendas = supabase
      .from('vendas')
      .select('cliente_id, total, clientes(nome)')
      .eq('usuario_id', user.id)
      .not('cliente_id', 'is', null)

    if (dataInicial.value) {
      queryVendas = queryVendas.gte('created_at', dataInicial.value)
    }
    if (dataFinal.value) {
      queryVendas = queryVendas.lte('created_at', dataFinal.value + 'T23:59:59')
    }

    const { data: vendas } = await queryVendas

    if (vendas) {
      resumo.value.totalVendas = vendas.reduce((sum, v) => sum + v.total, 0)
      resumo.value.ticketMedio = vendas.length > 0 ? resumo.value.totalVendas / vendas.length : 0

      // Agrupar por cliente
      const vendasPorCliente = {}
      vendas.forEach(v => {
        if (!vendasPorCliente[v.cliente_id]) {
          vendasPorCliente[v.cliente_id] = {
            cliente_id: v.cliente_id,
            nome: v.clientes?.nome || 'Cliente',
            total: 0
          }
        }
        vendasPorCliente[v.cliente_id].total += v.total
      })

      clientesTop.value = Object.values(vendasPorCliente)
        .sort((a, b) => b.total - a.total)
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
