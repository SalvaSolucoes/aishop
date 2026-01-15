<template>
  <div class="movimentacoes-view">
    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <!-- Toast de Sucesso -->
    <Toast
      :mostrar="mostrarToast"
      :mensagem="mensagemToast"
      tipo="success"
      :duracao="3000"
      @fechar="mostrarToast = false"
    />

    <!-- Cards de Resumo -->
    <div v-if="caixaAtual" class="summary-cards">
      <div class="summary-card summary-card-entrada">
        <div class="summary-card-icon summary-icon-entrada">
          <ArrowUpIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Total de Entradas</div>
          <div class="summary-card-value summary-value-entrada">
            {{ formatarMoeda(totalEntradas) }}
          </div>
        </div>
      </div>
      <div class="summary-card summary-card-saida">
        <div class="summary-card-icon summary-icon-saida">
          <ArrowDownIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Total de Saídas</div>
          <div class="summary-card-value summary-value-saida">
            {{ formatarMoeda(totalSaidas) }}
          </div>
        </div>
      </div>
      <div class="summary-card summary-card-saldo">
        <div class="summary-card-icon summary-icon-saldo">
          <ArrowsRightLeftIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Saldo Líquido</div>
          <div class="summary-card-value summary-value-saldo">
            {{ formatarMoeda(totalEntradas - totalSaidas) }}
          </div>
        </div>
      </div>
    </div>

    <div v-else class="caixa-fechado-alert">
      <div class="alert-content">
        <ArrowsRightLeftIcon class="alert-icon" />
        <div>
          <h4 class="alert-title">Caixa Fechado</h4>
          <p class="alert-message">Abra um caixa no Carrinho para visualizar o histórico de movimentações</p>
        </div>
      </div>
    </div>

    <!-- Histórico de Movimentações -->
    <div v-if="caixaAtual" class="movimentacao-history-section">
      <div class="section-header-modern">
        <div class="section-header-content">
          <div class="section-icon-wrapper section-icon-history">
            <DocumentTextIcon class="section-icon" />
          </div>
          <div>
            <h3 class="section-title-modern">Histórico de Movimentações</h3>
            <p class="section-subtitle">Entradas e saídas registradas no caixa</p>
          </div>
        </div>
        <div class="filter-group">
          <label class="filter-label">
            <ClockIcon class="filter-icon" />
            Filtrar por data
          </label>
          <input
            v-model="filtroData"
            type="date"
            class="form-input form-input-filter-modern"
            @change="carregarMovimentacoes"
          />
        </div>
      </div>
      <div class="card card-table-modern">
        <div v-if="carregando" class="table-loading">
          <div class="loading-spinner"></div>
          <p>Carregando movimentações...</p>
        </div>
        <div v-else-if="movimentacoes.length === 0" class="table-empty">
          <ArrowsRightLeftIcon class="empty-icon" />
          <p class="empty-text">Nenhuma movimentação encontrada</p>
          <p class="empty-hint">Registre uma nova movimentação para começar</p>
        </div>
        <div v-else class="overflow-x-auto -mx-3 sm:mx-0">
          <table class="tabela tabela-movimentacoes">
            <thead>
              <tr>
                <th class="text-center">Data e Hora</th>
                <th class="text-center">Tipo</th>
                <th class="text-center">Descrição</th>
                <th class="text-center">Categoria</th>
                <th class="text-center">Valor</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="mov in movimentacoes" 
                :key="mov.id"
                class="table-row-modern"
              >
                <td class="table-cell-date text-center">
                  {{ formatarDataHora(mov.created_at) }}
                </td>
                <td class="text-center">
                  <span 
                    class="badge badge-modern"
                    :class="{
                      'badge-entrada': mov.tipo === 'entrada',
                      'badge-saida': mov.tipo === 'saida'
                    }"
                  >
                    <ArrowUpIcon v-if="mov.tipo === 'entrada'" class="badge-icon" />
                    <ArrowDownIcon v-else class="badge-icon" />
                    {{ mov.tipo === 'entrada' ? 'Entrada' : 'Saída' }}
                  </span>
                </td>
                <td class="table-cell-description text-center">
                  {{ mov.descricao }}
                </td>
                <td class="text-center">
                  <span v-if="mov.categoria" class="categoria-badge">
                    {{ mov.categoria }}
                  </span>
                  <span v-else class="text-gray-400">-</span>
                </td>
                <td class="text-center">
                  <span 
                    class="table-cell-valor"
                    :class="{
                      'valor-entrada': mov.tipo === 'entrada',
                      'valor-saida': mov.tipo === 'saida'
                    }"
                  >
                    {{ mov.tipo === 'entrada' ? '+' : '-' }} {{ formatarMoeda(mov.valor) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import Toast from '@/componentes/Toast.vue'
import {
  ArrowUpIcon,
  ArrowDownIcon,
  ArrowsRightLeftIcon,
  DocumentTextIcon,
  ClockIcon,
} from '@heroicons/vue/24/outline'
import { 
  caixaAtual as caixaAtualStore,
  refreshCaixaState
} from '@/stores/caixa.js'

// Use store's reactive ref
const caixaAtual = caixaAtualStore
const movimentacoes = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroData = ref('')
const mostrarToast = ref(false)
const mensagemToast = ref('')

const totalEntradas = computed(() => {
  return movimentacoes.value
    .filter(m => m.tipo === 'entrada')
    .reduce((sum, m) => sum + parseFloat(m.valor || 0), 0)
})

const totalSaidas = computed(() => {
  return movimentacoes.value
    .filter(m => m.tipo === 'saida')
    .reduce((sum, m) => sum + parseFloat(m.valor || 0), 0)
})

onMounted(async () => {
  await refreshCaixaState()
  if (caixaAtual.value) {
    await carregarMovimentacoes()
  }
})

// Removed unused function
// async function carregarCaixaAtual() { ... }

async function carregarMovimentacoes() {
  if (!caixaAtual.value) return

  try {
    carregando.value = true
    let query = supabase
      .from('movimentacoes_caixa')
      .select('*')
      .eq('caixa_id', caixaAtual.value.id)
      .neq('categoria', 'Vendas')
      .order('created_at', { ascending: false })

    if (filtroData.value) {
      const dataInicio = new Date(filtroData.value)
      dataInicio.setHours(0, 0, 0, 0)
      const dataFim = new Date(filtroData.value)
      dataFim.setHours(23, 59, 59, 999)

      query = query
        .gte('created_at', dataInicio.toISOString())
        .lte('created_at', dataFim.toISOString())
    }

    const { data, error } = await query

    if (error) throw error
    movimentacoes.value = data || []
  } catch (err) {
    console.error('Erro ao carregar movimentações:', err)
    erro.value = 'Erro ao carregar movimentações'
  } finally {
    carregando.value = false
  }
}

function formatarDataHora(data) {
  return new Date(data).toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}
</script>

<style scoped>
.movimentacoes-view {
  width: 100%;
}

/* Cards de Resumo */
.summary-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2.5rem;
}

.summary-card {
  background: white;
  border-radius: 1rem;
  padding: 1.5rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  border: 1px solid #e5e7eb;
  transition: all 0.3s ease;
}

.summary-card:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  transform: translateY(-2px);
}

.summary-card-icon {
  width: 3.5rem;
  height: 3.5rem;
  border-radius: 0.875rem;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.summary-icon-entrada {
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
}

.summary-icon-saida {
  background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%);
}

.summary-icon-saldo {
  background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
}

.summary-icon {
  width: 1.75rem;
  height: 1.75rem;
  color: white;
}

.summary-card-content {
  flex: 1;
  min-width: 0;
}

.summary-card-label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.5rem;
}

.summary-card-value {
  font-size: 1.5rem;
  font-weight: 700;
  letter-spacing: -0.02em;
}

.summary-value-entrada {
  color: #10b981;
}

.summary-value-saida {
  color: #ef4444;
}

.summary-value-saldo {
  color: #0ea5e9;
}

/* Alerta de Caixa Fechado */
.caixa-fechado-alert {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  border: 1px solid #fbbf24;
  border-radius: 1rem;
  padding: 1.5rem;
  margin-bottom: 2rem;
}

.alert-content {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
}

.alert-icon {
  width: 2rem;
  height: 2rem;
  color: #d97706;
  flex-shrink: 0;
  margin-top: 0.125rem;
}

.alert-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: #92400e;
  margin: 0 0 0.25rem 0;
}

.alert-message {
  font-size: 0.9375rem;
  color: #78350f;
  margin: 0;
}

/* Section Headers */
.section-header-modern {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  flex-wrap: wrap;
  margin-bottom: 1.25rem;
}

.section-header-content {
  display: flex;
  align-items: flex-start;
  gap: 1rem;
}

.section-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 3rem;
  height: 3rem;
  background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
  border-radius: 0.75rem;
  flex-shrink: 0;
}

.section-icon-history {
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
}

.section-icon {
  width: 1.5rem;
  height: 1.5rem;
  color: white;
}

.section-title-modern {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.25rem 0;
  line-height: 1.2;
}

.section-subtitle {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
  line-height: 1.5;
}

/* Filter Group */
.filter-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.filter-label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8125rem;
  font-weight: 500;
  color: #6b7280;
}

.filter-icon {
  width: 1rem;
  height: 1rem;
  color: #9ca3af;
}

.form-input-filter-modern {
  max-width: 200px;
  padding: 0.625rem 0.875rem;
  font-size: 0.875rem;
  border: 1.5px solid #e5e7eb;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
  background: white;
}

.form-input-filter-modern:focus {
  outline: none;
  border-color: #8b5cf6;
  box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1);
}

/* Cards */
.card {
  background: white;
  border-radius: 1rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  border: 1px solid #e5e7eb;
  overflow: hidden;
  transition: all 0.3s ease;
}

.card:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

/* Tables */
.table-loading,
.table-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 2rem;
  text-align: center;
}

.loading-spinner {
  width: 2.5rem;
  height: 2.5rem;
  border: 3px solid #e5e7eb;
  border-top-color: #0ea5e9;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.empty-icon {
  width: 4rem;
  height: 4rem;
  color: #d1d5db;
  margin-bottom: 1rem;
}

.empty-text {
  font-size: 1.125rem;
  font-weight: 600;
  color: #374151;
  margin: 0 0 0.5rem 0;
}

.empty-hint {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

.table-row-modern {
  transition: all 0.2s ease;
  background: white;
}

.table-row-modern:hover {
  background: #f9fafb;
}

.table-cell-date {
  font-weight: 600;
  color: #111827;
  font-size: 0.875rem;
}

.table-cell-description {
  font-weight: 500;
  color: #111827;
  max-width: 400px;
}

.text-center {
  text-align: center;
}

.table-cell-valor {
  display: flex;
  align-items: baseline;
  gap: 0.25rem;
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: -0.02em;
}

.valor-entrada {
  color: #10b981;
}

.valor-saida {
  color: #ef4444;
}

/* Badges */
.badge-modern {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.875rem;
  border-radius: 0.5rem;
  font-size: 0.8125rem;
  font-weight: 600;
}

.badge-icon {
  width: 1rem;
  height: 1rem;
  flex-shrink: 0;
}

.badge-entrada {
  background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
  color: #065f46;
  border-color: #10b981;
}

.badge-saida {
  background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
  color: #991b1b;
  border-color: #ef4444;
}

.categoria-badge {
  display: inline-block;
  padding: 0.25rem 0.625rem;
  background: #f3f4f6;
  color: #6b7280;
  border-radius: 0.375rem;
  font-size: 0.75rem;
  font-weight: 500;
  width: fit-content;
}

/* Responsividade */
@media (max-width: 768px) {
  .summary-cards {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .summary-card {
    padding: 1.25rem;
  }

  .summary-card-value {
    font-size: 1.25rem;
  }

  .section-header-modern {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
  }

  .filter-group {
    width: 100%;
  }

  .form-input-filter-modern {
    max-width: 100%;
    width: 100%;
  }
}
</style>
