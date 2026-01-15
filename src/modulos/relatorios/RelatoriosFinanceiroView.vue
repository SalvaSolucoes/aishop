<template>
  <div class="relatorios-financeiro-view">
    <!-- Header -->
    <div class="page-header">
      <div class="page-header-content">
        <div class="page-icon-wrapper page-icon-financeiro">
          <CreditCardIcon class="page-icon" />
        </div>
        <div>
          <h2 class="page-title">Relatórios Financeiros</h2>
          <p class="page-subtitle">Análises de contas a pagar e receber</p>
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
          <ArrowUpIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Contas a Receber</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.contasReceber) }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-red">
          <ArrowDownIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Contas a Pagar</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.contasPagar) }}</div>
        </div>
      </div>

      <div class="summary-card">
        <div class="summary-card-icon summary-icon-cyan">
          <ChartBarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Saldo</div>
          <div class="summary-card-value">{{ formatarMoeda(resumo.saldo) }}</div>
        </div>
      </div>
    </div>

    <!-- Seções de Relatórios -->
    <div class="reports-grid">
      <!-- Contas Vencidas -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Contas Vencidas</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="contasVencidas.length === 0" class="empty-state">
            <p>Nenhuma conta vencida</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="conta in contasVencidas" :key="conta.id" class="report-item report-item-alert">
              <span class="report-name">{{ conta.descricao }}</span>
              <span class="report-value">{{ formatarMoeda(conta.valor) }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Contas Pagas -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Contas Pagas no Período</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="contasPagas.length === 0" class="empty-state">
            <p>Nenhuma conta paga no período</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="conta in contasPagas" :key="conta.id" class="report-item">
              <span class="report-name">{{ conta.descricao }}</span>
              <span class="report-value">{{ formatarMoeda(conta.valor) }}</span>
            </li>
          </ul>
        </div>
      </div>

      <!-- Contas Pendentes -->
      <div class="card">
        <div class="card-header">
          <h3 class="card-title">Contas Pendentes</h3>
        </div>
        <div class="card-body">
          <div v-if="carregando" class="loading-state">
            <div class="loading-spinner"></div>
            <p>Carregando...</p>
          </div>
          <div v-else-if="contasPendentes.length === 0" class="empty-state">
            <p>Nenhuma conta pendente</p>
          </div>
          <ul v-else class="report-list">
            <li v-for="conta in contasPendentes" :key="conta.id" class="report-item">
              <span class="report-name">{{ conta.descricao }}</span>
              <span class="report-value">{{ formatarMoeda(conta.valor) }}</span>
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
  CreditCardIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  ChartBarIcon
} from '@heroicons/vue/24/outline'

const carregando = ref(false)
const dataInicial = ref('')
const dataFinal = ref('')

const resumo = ref({
  contasReceber: 0,
  contasPagar: 0,
  saldo: 0
})

const contasVencidas = ref([])
const contasPagas = ref([])
const contasPendentes = ref([])

async function carregarRelatorios() {
  carregando.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const hoje = new Date().toISOString().split('T')[0]

    // Carregar contas
    let queryContas = supabase
      .from('contas')
      .select('*')
      .eq('usuario_id', user.id)

    if (dataInicial.value) {
      queryContas = queryContas.gte('data_vencimento', dataInicial.value)
    }
    if (dataFinal.value) {
      queryContas = queryContas.lte('data_vencimento', dataFinal.value)
    }

    const { data: contas } = await queryContas

    if (contas) {
      // Resumo
      resumo.value.contasReceber = contas
        .filter(c => c.tipo === 'receber' && c.status === 'pendente')
        .reduce((sum, c) => sum + c.valor, 0)

      resumo.value.contasPagar = contas
        .filter(c => c.tipo === 'pagar' && c.status === 'pendente')
        .reduce((sum, c) => sum + c.valor, 0)

      resumo.value.saldo = resumo.value.contasReceber - resumo.value.contasPagar

      // Contas vencidas
      contasVencidas.value = contas
        .filter(c => c.status === 'pendente' && c.data_vencimento < hoje)
        .slice(0, 10)

      // Contas pagas
      contasPagas.value = contas
        .filter(c => c.status === 'paga')
        .slice(0, 10)

      // Contas pendentes
      contasPendentes.value = contas
        .filter(c => c.status === 'pendente' && c.data_vencimento >= hoje)
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
