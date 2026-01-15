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
            <li v-for="item in formasPagamento" :key="item.forma" class="report-item-pagamento">
              <span class="badge badge-pagamento" :class="getBadgeClassFormaPagamento(item.forma)">
                <component :is="getIconeFormaPagamento(item.forma)" class="badge-icon" />
                {{ formatarFormaPagamento(item.forma) }}
              </span>
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
  ChartBarIcon,
  BanknotesIcon,
  CreditCardIcon,
  DevicePhoneMobileIcon,
  TicketIcon
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

function formatarFormaPagamento(forma) {
  const formas = {
    dinheiro: 'Dinheiro',
    debito: 'Débito',
    credito: 'Crédito',
    pix: 'PIX',
    vale: 'Vale'
  }
  return formas[forma] || forma
}

function getIconeFormaPagamento(forma) {
  const icones = {
    dinheiro: BanknotesIcon,
    debito: CreditCardIcon,
    credito: CreditCardIcon,
    pix: DevicePhoneMobileIcon,
    vale: TicketIcon
  }
  return icones[forma] || CurrencyDollarIcon
}

function getBadgeClassFormaPagamento(forma) {
  const classes = {
    dinheiro: 'badge-dinheiro',
    debito: 'badge-debito',
    credito: 'badge-credito',
    pix: 'badge-pix',
    vale: 'badge-vale'
  }
  return classes[forma] || 'badge-default'
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
/* Item de Pagamento com Badge */
.report-item-pagamento {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.875rem 1rem;
  border-bottom: 1px solid #e5e7eb;
  transition: background 0.2s ease;
}

.report-item-pagamento:last-child {
  border-bottom: none;
}

.report-item-pagamento:hover {
  background: #f9fafb;
}

/* Badges Temáticos */
.badge-pagamento {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.875rem;
  border-radius: 0.5rem;
  font-size: 0.8125rem;
  font-weight: 600;
  transition: all 0.2s ease;
}

.badge-pagamento:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.badge-icon {
  width: 1rem;
  height: 1rem;
  flex-shrink: 0;
}

/* Badges por Forma de Pagamento */
.badge-dinheiro {
  background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
  color: #065f46;
  border: 1px solid #10b981;
}

.badge-debito {
  background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
  color: #1e40af;
  border: 1px solid #3b82f6;
}

.badge-credito {
  background: linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%);
  color: #3730a3;
  border: 1px solid #6366f1;
}

.badge-pix {
  background: linear-gradient(135deg, #ccfbf1 0%, #99f6e4 100%);
  color: #134e4a;
  border: 1px solid #14b8a6;
}

.badge-vale {
  background: linear-gradient(135deg, #fce7f3 0%, #fbcfe8 100%);
  color: #831843;
  border: 1px solid #ec4899;
}

.badge-default {
  background: linear-gradient(135deg, #f3f4f6 0%, #e5e7eb 100%);
  color: #374151;
  border: 1px solid #d1d5db;
}
</style>
