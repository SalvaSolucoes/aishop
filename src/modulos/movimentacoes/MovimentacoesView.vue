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
          <p class="alert-message">Abra um caixa na página de Caixa para registrar movimentações</p>
        </div>
      </div>
    </div>

    <div class="movimentacoes-container">
      <!-- Formulário de Nova Movimentação -->
      <div v-if="caixaAtual" class="movimentacao-form-section">
        <div class="section-header-modern">
          <div class="section-header-content">
            <div class="section-icon-wrapper">
              <PlusIcon class="section-icon" />
            </div>
            <div>
              <h3 class="section-title-modern">Registrar Movimentação</h3>
              <p class="section-subtitle">Adicione uma nova entrada ou saída de valores</p>
            </div>
          </div>
        </div>
        
        <div class="card card-form-modern">
          <form @submit.prevent="registrarMovimentacao" class="form-movimentacao-modern">
            <div class="form-grid">
              <div class="form-group-modern">
                <label class="form-label-modern">Tipo de Movimentação</label>
                <div class="tipo-selector">
                  <button
                    type="button"
                    class="tipo-option"
                    :class="{ 'tipo-option-active': novaMovimentacao.tipo === 'entrada' }"
                    @click="novaMovimentacao.tipo = 'entrada'"
                  >
                    <ArrowUpIcon class="tipo-icon tipo-icon-entrada" />
                    <span>Entrada</span>
                  </button>
                  <button
                    type="button"
                    class="tipo-option"
                    :class="{ 'tipo-option-active': novaMovimentacao.tipo === 'saida' }"
                    @click="novaMovimentacao.tipo = 'saida'"
                  >
                    <ArrowDownIcon class="tipo-icon tipo-icon-saida" />
                    <span>Saída</span>
                  </button>
                </div>
              </div>

              <div class="form-group-modern">
                <label class="form-label-modern">Valor</label>
                <div class="input-wrapper-modern">
                  <span class="input-prefix-modern">R$</span>
                  <input
                    v-model.number="novaMovimentacao.valor"
                    type="number"
                    class="form-input-modern form-input-money-modern"
                    required
                    min="0.01"
                    step="0.01"
                    placeholder="0,00"
                  />
                </div>
              </div>

              <div class="form-group-modern form-group-full">
                <label class="form-label-modern">Descrição</label>
                <input
                  v-model="novaMovimentacao.descricao"
                  type="text"
                  class="form-input-modern"
                  required
                  placeholder="Ex: Recebimento de cliente, Pagamento de fornecedor..."
                />
              </div>

              <div class="form-group-modern form-group-full">
                <label class="form-label-modern">Categoria (Opcional)</label>
                <input
                  v-model="novaMovimentacao.categoria"
                  type="text"
                  class="form-input-modern"
                  placeholder="Ex: Vendas, Despesas, Fornecedores..."
                />
              </div>
            </div>

            <div class="form-actions-modern">
              <button type="submit" class="btn btn-primario btn-submit-modern">
                <PlusIcon class="btn-icon" />
                <span>Registrar Movimentação</span>
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Histórico de Movimentações -->
      <div v-if="caixaAtual" class="movimentacao-history-section">
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
            <p class="empty-hint">Registre uma nova movimentação para começar</p>
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
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda, formatarDataHora } from '@/utils/formatadores'
import {
  ArrowsRightLeftIcon,
  PlusIcon,
  ArrowUpIcon,
  ArrowDownIcon,
  ClockIcon
} from '@heroicons/vue/24/outline'
import Toast from '@/componentes/Toast.vue'

const movimentacoes = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroData = ref(new Date().toISOString().split('T')[0])
const mostrarToast = ref(false)
const mensagemToast = ref('')
const caixaAtual = ref(null)

const novaMovimentacao = ref({
  tipo: 'entrada',
  valor: 0,
  descricao: '',
  categoria: ''
})

const totalEntradas = computed(() => {
  return movimentacoes.value
    .filter(m => m.tipo === 'entrada')
    .reduce((sum, m) => sum + m.valor, 0)
})

const totalSaidas = computed(() => {
  return movimentacoes.value
    .filter(m => m.tipo === 'saida')
    .reduce((sum, m) => sum + m.valor, 0)
})

async function verificarCaixaAberto() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const hoje = new Date().toISOString().split('T')[0]
    const { data, error } = await supabase
      .from('caixas')
      .select('*')
      .eq('usuario_id', user.id)
      .eq('data', hoje)
      .is('data_fechamento', null)
      .limit(1)
      .single()

    if (error && error.code !== 'PGRST116') {
      throw error
    }

    caixaAtual.value = data

    if (caixaAtual.value) {
      await carregarMovimentacoes()
    }
  } catch (err) {
    erro.value = 'Erro ao verificar caixa: ' + err.message
    console.error(err)
  }
}

function mostrarMensagemSucesso(mensagem) {
  mensagemToast.value = mensagem
  mostrarToast.value = true
}

async function carregarMovimentacoes() {
  if (!caixaAtual.value) {
    movimentacoes.value = []
    return
  }

  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('movimentacoes_caixa')
      .select('*')
      .eq('caixa_id', caixaAtual.value.id)
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

async function registrarMovimentacao() {
  erro.value = ''

  if (!caixaAtual.value) {
    erro.value = 'Nenhum caixa aberto. Abra um caixa primeiro na página de Caixa.'
    return
  }

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    const { error } = await supabase
      .from('movimentacoes_caixa')
      .insert([{
        caixa_id: caixaAtual.value.id,
        usuario_id: user.id,
        tipo: novaMovimentacao.value.tipo,
        valor: novaMovimentacao.value.valor,
        descricao: novaMovimentacao.value.descricao,
        categoria: novaMovimentacao.value.categoria
      }])

    if (error) throw error

    mostrarMensagemSucesso('Movimentação registrada com sucesso!')
    novaMovimentacao.value = {
      tipo: 'entrada',
      valor: 0,
      descricao: '',
      categoria: ''
    }

    await carregarMovimentacoes()
    
    // Disparar evento para atualizar outros componentes
    window.dispatchEvent(new CustomEvent('movimentacao-registrada', {
      detail: {
        tipo: novaMovimentacao.value.tipo,
        valor: novaMovimentacao.value.valor,
        caixa_id: caixaAtual.value.id,
        atualizouCaixa: true,
        atualizouRelatorios: true
      }
    }))
  } catch (err) {
    erro.value = 'Erro ao registrar movimentação: ' + err.message
    console.error(err)
  }
}

function onVendaFinalizada() {
  carregarMovimentacoes()
}

onMounted(() => {
  verificarCaixaAberto()
  
  // Ouvir eventos de venda finalizada
  window.addEventListener('venda-finalizada', onVendaFinalizada)
})

onUnmounted(() => {
  window.removeEventListener('venda-finalizada', onVendaFinalizada)
})
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

.movimentacoes-container {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.movimentacao-form-section,
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

.card-form-modern {
  background: white;
  border-radius: 1rem;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
  border: 1px solid #e5e7eb;
  overflow: hidden;
  transition: all 0.3s ease;
}

.card-form-modern:hover {
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
}

.form-movimentacao-modern {
  padding: 2rem;
}

.form-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.form-group-modern {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.form-group-full {
  grid-column: 1 / -1;
}

.form-label-modern {
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  letter-spacing: -0.01em;
}

.form-label-modern:has(+ input[required]),
.form-label-modern:has(+ .tipo-selector) {
  position: relative;
}

.form-label-modern:has(+ input[required])::after,
.form-label-modern:has(+ .tipo-selector)::after {
  content: '*';
  color: #ef4444;
  margin-left: 0.25rem;
  font-weight: 600;
}

.form-input-modern {
  width: 100%;
  padding: 0.75rem 1rem;
  font-size: 0.9375rem;
  border: 1.5px solid #e5e7eb;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
  background: white;
  color: #111827;
}

.form-input-modern:focus {
  outline: none;
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
}

.form-input-modern::placeholder {
  color: #9ca3af;
}

.input-wrapper-modern {
  position: relative;
  display: flex;
  align-items: center;
}

.input-prefix-modern {
  position: absolute;
  left: 1rem;
  font-weight: 600;
  color: #6b7280;
  font-size: 0.9375rem;
  z-index: 1;
}

.form-input-money-modern {
  padding-left: 3rem !important;
  font-size: 1.125rem;
  font-weight: 600;
  text-align: right;
}

.tipo-selector {
  display: flex;
  gap: 0.75rem;
}

.tipo-option {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.875rem 1rem;
  border: 2px solid #e5e7eb;
  border-radius: 0.5rem;
  background: white;
  color: #6b7280;
  font-weight: 500;
  font-size: 0.9375rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.tipo-option:hover {
  border-color: #0ea5e9;
  color: #0ea5e9;
  background: #f0f9ff;
}

.tipo-option-active {
  border-color: #0ea5e9;
  background: #f0f9ff;
  color: #0ea5e9;
  font-weight: 600;
}

.tipo-icon {
  width: 1.25rem;
  height: 1.25rem;
}

.tipo-icon-entrada {
  color: #10b981;
}

.tipo-icon-saida {
  color: #ef4444;
}

.tipo-option-active .tipo-icon-entrada {
  color: #10b981;
}

.tipo-option-active .tipo-icon-saida {
  color: #ef4444;
}

.form-actions-modern {
  display: flex;
  justify-content: flex-end;
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

.btn-submit-modern {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.875rem 2rem;
  font-weight: 600;
  font-size: 0.9375rem;
}

.btn-icon {
  width: 1.25rem;
  height: 1.25rem;
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

  .form-movimentacao-modern {
    padding: 1.5rem;
  }

  .form-grid {
    grid-template-columns: 1fr;
    gap: 1.25rem;
  }

  .tipo-selector {
    flex-direction: column;
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
