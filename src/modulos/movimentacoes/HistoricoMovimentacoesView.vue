<template>
  <div class="historico-movimentacoes-view">
    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <!-- Histórico de Movimentações -->
    <div class="movimentacao-history-section">
      <div class="section-header-modern">
        <div class="section-header-content">
          <div class="section-icon-wrapper section-icon-history">
            <ClockIcon class="section-icon" />
          </div>
          <div>
            <h3 class="section-title-modern">Histórico de Movimentações</h3>
            <p class="section-subtitle">Visualize todas as movimentações registradas</p>
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
          <p class="empty-hint">As movimentações registradas aparecerão aqui</p>
        </div>
        <div v-else class="table-container-modern">
          <table class="tabela tabela-movimentacoes">
            <thead>
              <tr>
                <th>Data e Hora</th>
                <th>Tipo</th>
                <th>Descrição</th>
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
                  <span :class="mov.tipo === 'entrada' ? 'badge badge-entrada' : 'badge badge-saida'">
                    <component :is="mov.tipo === 'entrada' ? ArrowUpIcon : ArrowDownIcon" class="badge-icon" />
                    <span class="badge-text">{{ mov.tipo === 'entrada' ? 'Entrada' : 'Saída' }}</span>
                  </span>
                </td>
                <td>
                  <div class="table-cell-descricao-wrapper">
                    <div class="table-cell-descricao" :title="mov.descricao">{{ mov.descricao }}</div>
                    <span v-if="mov.categoria" class="table-cell-categoria-badge">{{ mov.categoria }}</span>
                  </div>
                </td>
                <td>
                  <div :class="mov.tipo === 'entrada' ? 'valor-cell valor-entrada' : 'valor-cell valor-saida'">
                    <span class="valor-symbol">{{ mov.tipo === 'entrada' ? '+' : '-' }}</span>
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
import { ref, onMounted, onUnmounted } from 'vue'
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

async function carregarMovimentacoes() {
  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('movimentacoes_caixa')
      .select('*')
      .eq('usuario_id', user.id)
      .order('created_at', { ascending: false })

    if (error) throw error
    movimentacoes.value = data || []
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
.historico-movimentacoes-view {
  width: 100%;
}

.movimentacao-history-section {
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
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
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
  border-color: #8b5cf6;
  box-shadow: 0 0 0 3px rgba(139, 92, 246, 0.1);
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
  border-top-color: #8b5cf6;
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

.tabela-movimentacoes th:first-child {
  padding-left: 1.5rem;
}

.tabela-movimentacoes th:last-child {
  text-align: right;
  padding-right: 1.5rem;
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

.table-cell-descricao-wrapper {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-width: 400px;
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
  width: fit-content;
}

.valor-cell {
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

  .tabela-movimentacoes {
    font-size: 0.8125rem;
  }

  .tabela-movimentacoes th,
  .tabela-movimentacoes td {
    padding: 0.875rem 1rem;
  }

  .table-cell-descricao-wrapper {
    max-width: 200px;
  }

  .valor-cell {
    font-size: 0.9375rem;
  }
}
</style>
