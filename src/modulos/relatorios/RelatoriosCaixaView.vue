<template>
  <div class="relatorios-caixa-view">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header-content">
        <div class="page-icon-wrapper page-icon-caixa">
          <CurrencyDollarIcon class="page-icon" />
        </div>
        <div>
          <h2 class="page-title">Relatórios de Caixa</h2>
          <p class="page-subtitle">Análises de vendas e movimentações</p>
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
        <div class="summary-card-icon summary-icon-green">
          <CurrencyDollarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Total de Vendas</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.totalVendas) }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-blue">
          <ShoppingCartIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Quantidade de Vendas</div>
          <div class="summary-card-value">{{ resumo.quantidadeVendas }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-purple">
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
      <!-- Vendas por Dia -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Vendas por Dia</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="vendasPorDia.length === 0" class="empty-state">
            <p>Nenhuma venda registrada no período</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="item in vendasPorDia" :key="item.data" class="report-item">
              <span class="report-name">{{ formatarData(item.data) }}</span>
              <span class="report-value">{{ formatarMoeda(item.total) }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Formas de Pagamento -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Formas de Pagamento</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="formasPagamento.length === 0" class="empty-state">
            <p>Nenhuma venda registrada</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="item in formasPagamento" :key="item.forma" class="report-item">
              <span class="report-name">{{ item.forma }}</span>
              <span class="report-value">{{ formatarMoeda(item.total) }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Movimentações -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Movimentações</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else class="empty-state">
            <p>Total de Entradas: {{ formatarMoeda(resumo.totalEntradas) }}</p>
            <p>Total de Saídas: {{ formatarMoeda(resumo.totalSaidas) }}</p>
          </div>
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
  CurrencyDollarIcon,
  ShoppingCartIcon,
  ChartBarIcon
} from '@heroicons/vue/24/outline'

const carregando = ref(false)
const dataInicial = ref('')
const dataFinal = ref('')

const resumo = ref({
  totalVendas: 0,
  quantidadeVendas: 0,
  ticketMedio: 0,
  totalEntradas: 0,
  totalSaidas: 0
})

const vendasPorDia = ref([])
const formasPagamento = ref([])

function formatarData(data) {
  return new Date(data).toLocaleDateString('pt-BR')
}

async function carregarRelatorios() {
  carregando.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Carregar vendas
    let queryVendas = supabase
      .from('vendas')
      .select('*')
      .eq('usuario_id', user.id)

    if (dataInicial.value) {
      queryVendas = queryVendas.gte('created_at', dataInicial.value)
    }
    if (dataFinal.value) {
      queryVendas = queryVendas.lte('created_at', dataFinal.value + 'T23:59:59')
    }

    const { data: vendas } = await queryVendas

    if (vendas) {
      resumo.value.totalVendas = vendas.reduce((sum, v) => sum + v.total, 0)
      resumo.value.quantidadeVendas = vendas.length
      resumo.value.ticketMedio = vendas.length > 0 ? resumo.value.totalVendas / vendas.length : 0

      // Vendas por dia
      const vendasPorDiaMap = {}
      vendas.forEach(v => {
        const data = v.created_at.split('T')[0]
        if (!vendasPorDiaMap[data]) {
          vendasPorDiaMap[data] = { data, total: 0 }
        }
        vendasPorDiaMap[data].total += v.total
      })
      vendasPorDia.value = Object.values(vendasPorDiaMap).sort((a, b) => b.data.localeCompare(a.data))

      // Formas de pagamento
      const formasPagamentoMap = {}
      vendas.forEach(v => {
        const forma = v.forma_pagamento || 'Não informado'
        if (!formasPagamentoMap[forma]) {
          formasPagamentoMap[forma] = { forma, total: 0 }
        }
        formasPagamentoMap[forma].total += v.total
      })
      formasPagamento.value = Object.values(formasPagamentoMap).sort((a, b) => b.total - a.total)
    }

    // Carregar movimentações
    let queryMov = supabase
      .from('movimentacoes_caixa')
      .select('*')
      .eq('usuario_id', user.id)

    if (dataInicial.value) {
      queryMov = queryMov.gte('created_at', dataInicial.value)
    }
    if (dataFinal.value) {
      queryMov = queryMov.lte('created_at', dataFinal.value + 'T23:59:59')
    }

    const { data: movimentacoes } = await queryMov

    if (movimentacoes) {
      resumo.value.totalEntradas = movimentacoes
        .filter(m => m.tipo === 'entrada' || m.tipo === 'suprimento')
        .reduce((sum, m) => sum + m.valor, 0)
      
      resumo.value.totalSaidas = movimentacoes
        .filter(m => m.tipo === 'saida' || m.tipo === 'sangria')
        .reduce((sum, m) => sum + m.valor, 0)
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
