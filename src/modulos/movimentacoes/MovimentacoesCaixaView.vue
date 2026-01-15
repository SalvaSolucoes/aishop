<template>
  <div class="movimentacoes-caixa-view">
    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <!-- Cards de Resumo -->
    <div class="summary-cards">
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

    <!-- Movimentações de Caixa -->
    <div class="movimentacao-section">
      <div class="section-header-modern">
        <div class="section-header-content">
          <div class="section-icon-wrapper">
            <ArrowsRightLeftIcon class="section-icon" />
          </div>
          <div>
            <h3 class="section-title-modern">Movimentações de Caixa</h3>
            <p class="section-subtitle">Entradas e saídas (exceto vendas)</p>
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
          <p class="empty-hint">Movimentações de caixa (sangria, suprimento, etc.) aparecerão aqui</p>
        </div>
        <div v-else class="table-container-modern">
          <table class="tabela tabela-movimentacoes">
            <thead>
              <tr>
                <th>Data e Hora</th>
                <th>Tipo</th>
                <th>Descrição</th>
                <th>Categoria</th>
                <th>Valor</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="(mov, index) in movimentacoes" 
                :key="mov.id"
                class="table-row-modern"
                :style="{ animationDelay: `${index * 0.03}s` }"
              >
                <td>
                  <div class="table-cell-datetime">
                    <div class="table-cell-date">{{ new Date(mov.created_at).toLocaleDateString('pt-BR') }}</div>
                    <div class="table-cell-time">
                      <ClockIcon class="table-time-icon" />
                      {{ new Date(mov.created_at).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }) }}
                    </div>
                  </div>
                </td>
                <td>
                  <span :class="mov.tipo === 'entrada' || mov.tipo === 'suprimento' ? 'badge badge-entrada' : 'badge badge-saida'">
                    <component :is="mov.tipo === 'entrada' || mov.tipo === 'suprimento' ? ArrowUpIcon : ArrowDownIcon" class="badge-icon" />
                    <span class="badge-text">{{ formatarTipo(mov.tipo) }}</span>
                  </span>
                </td>
                <td>
                  <div class="table-cell-descricao">{{ mov.descricao }}</div>
                </td>
                <td>
                  <span v-if="mov.categoria" class="table-cell-categoria-badge">{{ mov.categoria }}</span>
                  <span v-else class="text-muted">-</span>
                </td>
                <td>
                  <div :class="mov.tipo === 'entrada' || mov.tipo === 'suprimento' ? 'valor-cell valor-entrada' : 'valor-cell valor-saida'">
                    <span class="valor-symbol">{{ mov.tipo === 'entrada' || mov.tipo === 'suprimento' ? '+' : '-' }}</span>
                    <span class="valor-amount">{{ formatarMoeda(mov.valor) }}</span>
                  </div>
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
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import {
  ArrowsRightLeftIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  ClockIcon
} from '@heroicons/vue/24/outline'

const movimentacoes = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroData = ref(new Date().toISOString().split('T')[0])

const totalEntradas = computed(() => {
  return movimentacoes.value
    .filter(m => m.tipo === 'entrada' || m.tipo === 'suprimento')
    .reduce((sum, m) => sum + m.valor, 0)
})

const totalSaidas = computed(() => {
  return movimentacoes.value
    .filter(m => m.tipo === 'saida' || m.tipo === 'sangria')
    .reduce((sum, m) => sum + m.valor, 0)
})

function formatarTipo(tipo) {
  const tipos = {
    'entrada': 'Entrada',
    'saida': 'Saída',
    'sangria': 'Sangria',
    'suprimento': 'Suprimento'
  }
  return tipos[tipo] || tipo
}

async function carregarMovimentacoes() {
  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Buscar todas as vendas do usuário em ordem cronológica
    const { data: vendasData, error: errorVendas } = await supabase
      .from('vendas')
      .select('id, numero_venda, created_at, caixa_id, total')
      .eq('usuario_id', user.id)
      .order('created_at', { ascending: true })

    if (errorVendas) throw errorVendas

    // Criar mapa de vendas com numeração sequencial
    const vendasMap = new Map()
    let numeroSequencial = 1
    
    ;(vendasData || []).forEach(venda => {
      vendasMap.set(venda.id, {
        ...venda,
        numeroSequencial: numeroSequencial++
      })
    })

    // Buscar movimentações
    const { data: movimentacoesData, error: errorMov } = await supabase
      .from('movimentacoes_caixa')
      .select('*')
      .eq('usuario_id', user.id)
      .order('created_at', { ascending: false })

    if (errorMov) throw errorMov

    // Processar movimentações e tentar identificar vendas
    const movimentacoesProcessadas = (movimentacoesData || []).map(mov => {
      // Verificar se é uma entrada que pode ser venda
      // Critérios: tipo entrada + (categoria venda OU descrição contém "Venda")
      const isVenda = mov.tipo === 'entrada' && 
                      (mov.categoria?.toLowerCase() === 'venda' || 
                       mov.descricao?.toLowerCase().includes('venda'))
      
      if (isVenda) {
        // Tentar encontrar venda correspondente pelo caixa_id e timestamp próximo
        const vendasDoCaixa = Array.from(vendasMap.values()).filter(v => v.caixa_id === mov.caixa_id)
        
        // Encontrar venda com timestamp mais próximo (dentro de 10 segundos)
        let vendaMaisProxima = null
        let menorDiferenca = Infinity
        
        vendasDoCaixa.forEach(venda => {
          const diffMs = Math.abs(new Date(venda.created_at) - new Date(mov.created_at))
          if (diffMs < 10000 && diffMs < menorDiferenca) { // Menos de 10 segundos
            menorDiferenca = diffMs
            vendaMaisProxima = venda
          }
        })
        
        if (vendaMaisProxima) {
          return {
            ...mov,
            numeroVenda: vendaMaisProxima.numeroSequencial,
            numeroVendaOriginal: vendaMaisProxima.numero_venda,
            isVenda: true
          }
        }
      }
      
      return {
        ...mov,
        isVenda: false
      }
    })

    movimentacoes.value = movimentacoesProcessadas
  } catch (err) {
    erro.value = 'Erro ao carregar movimentações: ' + err.message
    console.error(err)
  } finally {
    carregando.value = false
  }
}

function onMovimentacaoRegistrada() {
  carregarMovimentacoes()
}

onMounted(() => {
  carregarMovimentacoes()
  
  // Ouvir eventos de movimentação registrada
  window.addEventListener('movimentacao-registrada', onMovimentacaoRegistrada)
})

onUnmounted(() => {
  window.removeEventListener('movimentacao-registrada', onMovimentacaoRegistrada)
})
</script>

<style scoped>
.movimentacoes-caixa-view {
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

.movimentacao-section {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.section-header-modern {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 1rem;
  flex-wrap: wrap;
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
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
}

.card-table-modern {
  background: white;
  border-radius: 1rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  border: 1px solid #e5e7eb;
  overflow: hidden;
}

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

.table-container-modern {
  overflow-x: auto;
}

.tabela-movimentacoes {
  width: 100%;
  border-collapse: collapse;
}

.tabela-movimentacoes thead {
  background: linear-gradient(to bottom, #f9fafb 0%, #f3f4f6 100%);
  position: sticky;
  top: 0;
  z-index: 10;
}

.tabela-movimentacoes th {
  padding: 1.125rem 1.5rem;
  text-align: left;
  font-size: 0.75rem;
  font-weight: 700;
  color: #374151;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  border-bottom: 2px solid #e5e7eb;
  white-space: nowrap;
}

.tabela-movimentacoes th:last-child {
  text-align: right;
}

.tabela-movimentacoes tbody tr {
  transition: all 0.2s ease;
  border-bottom: 1px solid #f3f4f6;
  animation: slideInRight 0.4s ease-out forwards;
  opacity: 0;
  background: white;
}

.tabela-movimentacoes tbody tr:last-child {
  border-bottom: none;
}

.tabela-movimentacoes tbody tr:hover {
  background: #f9fafb;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05);
}

.tabela-movimentacoes tbody td {
  padding: 1.25rem 1.5rem;
  text-align: left;
  font-size: 0.875rem;
  color: #374151;
  vertical-align: middle;
}

.tabela-movimentacoes tbody td:last-child {
  text-align: right;
  font-weight: 600;
}

@keyframes slideInRight {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.table-cell-datetime {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.table-cell-date {
  font-weight: 600;
  color: #111827;
  font-size: 0.875rem;
}

.table-cell-time {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  font-size: 0.8125rem;
  color: #6b7280;
}

.table-time-icon {
  width: 0.875rem;
  height: 0.875rem;
  color: #9ca3af;
}

.table-cell-descricao {
  font-weight: 500;
  color: #111827;
  font-size: 0.875rem;
  line-height: 1.5;
}

.table-cell-categoria-badge {
  display: inline-block;
  padding: 0.25rem 0.625rem;
  background: #f3f4f6;
  color: #6b7280;
  border-radius: 0.375rem;
  font-size: 0.75rem;
  font-weight: 500;
}

.text-muted {
  color: #9ca3af;
  font-size: 0.875rem;
}

.valor-cell {
  display: flex;
  align-items: baseline;
  gap: 0.25rem;
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: -0.02em;
  justify-content: flex-end;
}

.valor-entrada {
  color: #10b981;
}

.valor-saida {
  color: #ef4444;
}

.valor-symbol {
  font-size: 0.875rem;
  font-weight: 600;
}

.valor-amount {
  font-size: 1rem;
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 0.875rem;
  border-radius: 0.5rem;
  font-size: 0.8125rem;
  font-weight: 600;
  transition: all 0.2s ease;
  border: 1px solid transparent;
}

.badge-icon {
  width: 1rem;
  height: 1rem;
  flex-shrink: 0;
}

.badge-text {
  white-space: nowrap;
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

@media (max-width: 768px) {
  .summary-cards {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .section-header-modern {
    flex-direction: column;
    align-items: stretch;
  }

  .filter-group {
    width: 100%;
  }

  .form-input-filter-modern {
    max-width: 100%;
  }

  .tabela-movimentacoes th,
  .tabela-movimentacoes td {
    padding: 0.875rem 1rem;
  }
}
</style>
