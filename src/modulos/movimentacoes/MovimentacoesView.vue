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

    <div v-if="!caixaAtual" class="caixa-fechado-alert">
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
                  <th class="text-center">Data e Hora</th>
                  <th class="text-center">Tipo</th>
                  <th class="text-center">Descrição</th>
                  <th class="text-center">Valor</th>
                  <th class="text-center">Ações</th>
                </tr>
              </thead>
              <tbody>
                <tr 
                  v-for="(mov, index) in movimentacoes" 
                  :key="mov.id"
                  class="table-row-modern"
                  :style="{ animationDelay: `${index * 0.03}s` }"
                >
                  <td class="text-center">
                    <div class="table-cell-datetime">
                      <div class="table-cell-date">{{ new Date(mov.created_at).toLocaleDateString('pt-BR') }}</div>
                      <div class="table-cell-time">
                        <ClockIcon class="table-time-icon" />
                        {{ new Date(mov.created_at).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }) }}
                      </div>
                    </div>
                  </td>
                  <td class="text-center">
                    <span :class="mov.tipo === 'entrada' ? 'badge badge-entrada' : 'badge badge-saida'">
                      <component :is="mov.tipo === 'entrada' ? ArrowUpIcon : ArrowDownIcon" class="badge-icon" />
                      <span class="badge-text">{{ mov.tipo === 'entrada' ? 'Entrada' : 'Saída' }}</span>
                    </span>
                  </td>
                  <td class="text-center">
                    <div class="table-cell-descricao-wrapper">
                      <div class="table-cell-descricao" :title="mov.descricao">{{ mov.descricao }}</div>
                      <span v-if="mov.categoria" class="table-cell-categoria-badge">{{ mov.categoria }}</span>
                    </div>
                  </td>
                  <td class="text-center">
                    <div :class="mov.tipo === 'entrada' ? 'valor-cell valor-entrada' : 'valor-cell valor-saida'">
                      <span class="valor-symbol">{{ mov.tipo === 'entrada' ? '+' : '-' }}</span>
                      <span class="valor-amount">{{ formatarMoeda(mov.valor) }}</span>
                    </div>
                  </td>
                  <td class="text-center">
                    <button
                      @click="abrirDetalhes(mov)"
                      class="btn-detalhes"
                      title="Ver detalhes"
                    >
                      <InformationCircleIcon class="h-5 w-5" />
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal de Detalhes -->
    <div v-if="mostrarModalDetalhes" class="modal-overlay" @click.self="fecharDetalhes">
      <div class="modal-content modal-detalhes">
        <div class="modal-header">
          <h3>Detalhes da Movimentação</h3>
          <button class="btn-close" @click="fecharDetalhes">×</button>
        </div>
        <div class="modal-body">
          <div v-if="carregandoDetalhes" class="text-center py-4">
            <div class="loading-spinner mx-auto mb-2"></div>
            <p>Carregando detalhes...</p>
          </div>
          <div v-else-if="movimentacaoSelecionada" class="detalhes-grid">
            <!-- Informações Básicas -->
            <div class="detalhe-section">
              <h4 class="detalhe-titulo">Informações Básicas</h4>
              <div class="detalhe-item">
                <span class="detalhe-label">Tipo:</span>
                <span :class="movimentacaoSelecionada.tipo === 'entrada' ? 'badge badge-entrada' : 'badge badge-saida'">
                  {{ movimentacaoSelecionada.tipo === 'entrada' ? 'Entrada' : 'Saída' }}
                </span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Valor:</span>
                <span class="detalhe-valor" :class="movimentacaoSelecionada.tipo === 'entrada' ? 'text-green-600' : 'text-red-600'">
                  {{ formatarMoeda(movimentacaoSelecionada.valor) }}
                </span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Data e Hora:</span>
                <span>{{ formatarDataHora(movimentacaoSelecionada.created_at) }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Descrição:</span>
                <span>{{ movimentacaoSelecionada.descricao }}</span>
              </div>
              <div v-if="movimentacaoSelecionada.categoria" class="detalhe-item">
                <span class="detalhe-label">Categoria:</span>
                <span class="table-cell-categoria-badge">{{ movimentacaoSelecionada.categoria }}</span>
              </div>
            </div>

            <!-- Informações da Venda (se aplicável) -->
            <div v-if="detalhesVenda" class="detalhe-section">
              <h4 class="detalhe-titulo">Informações da Venda</h4>
              <div class="detalhe-item">
                <span class="detalhe-label">Número da Venda:</span>
                <span class="font-semibold">{{ detalhesVenda.numero_venda }}</span>
              </div>
              <div v-if="detalhesVenda.cliente" class="detalhe-item">
                <span class="detalhe-label">Cliente:</span>
                <span>{{ detalhesVenda.cliente }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Forma de Pagamento:</span>
                <span>{{ formatarFormaPagamento(detalhesVenda.forma_pagamento) }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Subtotal:</span>
                <span>{{ formatarMoeda(detalhesVenda.subtotal) }}</span>
              </div>
              <div v-if="detalhesVenda.desconto > 0" class="detalhe-item">
                <span class="detalhe-label">Desconto:</span>
                <span class="text-red-600">{{ formatarMoeda(detalhesVenda.desconto) }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Total:</span>
                <span class="font-semibold text-green-600">{{ formatarMoeda(detalhesVenda.total) }}</span>
              </div>
              <div v-if="detalhesVenda.observacoes" class="detalhe-item">
                <span class="detalhe-label">Observações:</span>
                <span class="text-sm italic">{{ detalhesVenda.observacoes }}</span>
              </div>
            </div>

            <!-- Origem Manual -->
            <div v-else-if="movimentacaoSelecionada.categoria !== 'Vendas'" class="detalhe-section">
              <h4 class="detalhe-titulo">Origem</h4>
              <div class="detalhe-item">
                <span class="detalhe-label">Tipo de Registro:</span>
                <span class="badge badge-info">Registro Manual</span>
              </div>
              <p class="text-sm text-gray-600 mt-2">
                Esta movimentação foi registrada manualmente através do formulário de movimentações.
              </p>
            </div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-ghost" @click="fecharDetalhes">Fechar</button>
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
  ClockIcon,
  InformationCircleIcon
} from '@heroicons/vue/24/outline'
import Toast from '@/componentes/Toast.vue'
import { 
  caixaAtual as caixaAtualStore,
  refreshCaixaState
} from '@/stores/caixa.js'

const movimentacoes = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroData = ref(new Date().toISOString().split('T')[0])
const mostrarToast = ref(false)
const mensagemToast = ref('')
// Use store's reactive ref
const caixaAtual = caixaAtualStore
const mostrarModalDetalhes = ref(false)
const movimentacaoSelecionada = ref(null)
const detalhesVenda = ref(null)
const carregandoDetalhes = ref(false)

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
    await refreshCaixaState()
    
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

    // Carregar movimentações com informações relacionadas
    const { data, error } = await supabase
      .from('movimentacoes_caixa')
      .select('*')
      .eq('caixa_id', caixaAtual.value.id)
      .eq('usuario_id', user.id)
      .neq('categoria', 'Vendas')
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

async function abrirDetalhes(movimentacao) {
  movimentacaoSelecionada.value = movimentacao
  detalhesVenda.value = null
  mostrarModalDetalhes.value = true
  carregandoDetalhes.value = true

  try {
    // Se for uma movimentação de venda, buscar detalhes
    if (movimentacao.categoria === 'Vendas' && movimentacao.descricao.includes('Venda')) {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      // Extrair número da venda da descrição
      const numeroVenda = movimentacao.descricao.replace('Venda ', '').split(' ')[0]

      // Buscar venda
      const { data: venda, error: errorVenda } = await supabase
        .from('vendas')
        .select(`
          *,
          clientes (nome)
        `)
        .eq('numero_venda', numeroVenda)
        .eq('usuario_id', user.id)
        .maybeSingle()

      if (!errorVenda && venda) {
        detalhesVenda.value = {
          ...venda,
          cliente: venda.clientes ? (Array.isArray(venda.clientes) ? venda.clientes[0]?.nome : venda.clientes.nome) : 'Cliente não informado'
        }
      }
    }
  } catch (err) {
    console.error('Erro ao carregar detalhes:', err)
  } finally {
    carregandoDetalhes.value = false
  }
}

function fecharDetalhes() {
  mostrarModalDetalhes.value = false
  movimentacaoSelecionada.value = null
  detalhesVenda.value = null
}

function formatarFormaPagamento(forma) {
  const formas = {
    dinheiro: 'Dinheiro',
    debito: 'Cartão Débito',
    credito: 'Cartão Crédito',
    pix: 'PIX',
    vale: 'Vale/Convênio',
    mistura: 'Pagamento Misto'
  }
  return formas[forma] || forma
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

    const dadosMovimentacao = {
      caixa_id: caixaAtual.value.id,
      usuario_id: user.id,
      tipo: novaMovimentacao.value.tipo,
      valor: novaMovimentacao.value.valor,
      descricao: novaMovimentacao.value.descricao,
      categoria: novaMovimentacao.value.categoria
    }

    const { error } = await supabase
      .from('movimentacoes_caixa')
      .insert([dadosMovimentacao])

    if (error) throw error

    mostrarMensagemSucesso('Movimentação registrada com sucesso!')
    await carregarMovimentacoes()
    
    // Disparar evento para atualizar outros componentes
    window.dispatchEvent(new CustomEvent('movimentacao-registrada', {
      detail: {
        ...dadosMovimentacao,
        atualizouCaixa: true,
        atualizouRelatorios: true
      }
    }))

    novaMovimentacao.value = {
      tipo: 'entrada',
      valor: 0,
      descricao: '',
      categoria: ''
    }
  } catch (err) {
    erro.value = 'Erro ao registrar movimentação: ' + err.message
    console.error(err)
  }
}

function onVendaFinalizada() {
  carregarMovimentacoes()
}

onMounted(async () => {
  await verificarCaixaAberto()
  
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

.text-center {
  text-align: center;
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

.tabela-movimentacoes tbody td.text-center {
  text-align: center;
}

.tabela-movimentacoes tbody td:last-child {
  text-align: center;
  font-weight: 600;
}

.btn-detalhes {
  padding: 0.5rem;
  background: #f3f4f6;
  color: #6b7280;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.btn-detalhes:hover {
  background: #e5e7eb;
  color: #374151;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: white;
  border-radius: 1rem;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  animation: modalSlideIn 0.3s ease-out;
}

.modal-detalhes {
  max-width: 600px;
}

@keyframes modalSlideIn {
  from {
    opacity: 0;
    transform: translateY(-20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h3 {
  font-size: 1.25rem;
  font-weight: 700;
  color: #111827;
}

.btn-close {
  background: none;
  border: none;
  font-size: 2rem;
  color: #9ca3af;
  cursor: pointer;
  padding: 0;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
}

.btn-close:hover {
  background: #f3f4f6;
  color: #374151;
}

.modal-body {
  padding: 1.5rem;
}

.detalhes-grid {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.detalhe-section {
  background: #f9fafb;
  padding: 1.25rem;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

.detalhe-titulo {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 1rem;
  padding-bottom: 0.75rem;
  border-bottom: 2px solid #e5e7eb;
}

.detalhe-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.detalhe-item:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.detalhe-label {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.detalhe-valor {
  font-size: 1.125rem;
  font-weight: 700;
}

.badge-info {
  background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
  color: #1e40af;
  border-color: #3b82f6;
}

.modal-footer {
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.btn-ghost {
  padding: 0.625rem 1.25rem;
  background: #f3f4f6;
  color: #374151;
  border: none;
  border-radius: 0.5rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-ghost:hover {
  background: #e5e7eb;
  color: #111827;
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
