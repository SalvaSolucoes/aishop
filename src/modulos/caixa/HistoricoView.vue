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

    <!-- Cards de Resumo de Vendas -->
    <div v-if="caixaAtual" class="summary-cards">
      <div class="summary-card">
        <div class="summary-card-icon" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%);">
          <ShoppingCartIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Total de Vendas</div>
          <div class="summary-card-value" style="color: #10b981;">
            {{ vendas.length }}
          </div>
        </div>
      </div>
      <div class="summary-card">
        <div class="summary-card-icon" style="background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%);">
          <CurrencyDollarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Valor Total</div>
          <div class="summary-card-value" style="color: #3b82f6;">
            {{ formatarMoeda(totalVendas) }}
          </div>
        </div>
      </div>
      <div class="summary-card">
        <div class="summary-card-icon" style="background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);">
          <ChartBarIcon class="summary-icon" />
        </div>
        <div class="summary-card-content">
          <div class="summary-card-label">Ticket Médio</div>
          <div class="summary-card-value" style="color: #8b5cf6;">
            {{ formatarMoeda(ticketMedio) }}
          </div>
        </div>
      </div>
    </div>

    <div v-else class="caixa-fechado-alert">
      <div class="alert-content">
        <ShoppingCartIcon class="alert-icon" />
        <div>
          <h4 class="alert-title">Caixa Fechado</h4>
          <p class="alert-message">Abra um caixa no Carrinho para visualizar o histórico de vendas</p>
        </div>
      </div>
    </div>

    <!-- Histórico de Vendas -->
    <div v-if="caixaAtual" class="movimentacao-history-section">
      <div class="section-header-modern">
        <div class="section-header-content">
          <div class="section-icon-wrapper section-icon-history">
            <ClockIcon class="section-icon" />
          </div>
          <div>
            <h3 class="section-title-modern">Histórico de Vendas</h3>
            <p class="section-subtitle">Vendas realizadas pelo carrinho</p>
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
            @change="carregarVendas"
          />
        </div>
      </div>

      <div class="card card-table-modern">
        <div v-if="carregando" class="table-loading">
          <div class="loading-spinner"></div>
          <p>Carregando vendas...</p>
        </div>
        <div v-else-if="vendas.length === 0" class="table-empty">
          <ShoppingCartIcon class="empty-icon" />
          <p class="empty-text">Nenhuma venda encontrada</p>
          <p class="empty-hint">As vendas do carrinho aparecerão aqui</p>
        </div>
        <div v-else class="overflow-x-auto -mx-3 sm:mx-0">
          <table class="tabela tabela-movimentacoes">
            <thead>
              <tr>
                <th class="text-center">Data e Hora</th>
                <th class="text-center">Nº Venda</th>
                <th class="text-center">Cliente</th>
                <th class="text-center">Forma Pagamento</th>
                <th class="text-center">Total</th>
                <th class="text-center">Ações</th>
              </tr>
            </thead>
            <tbody>
              <tr 
                v-for="venda in vendas" 
                :key="venda.id"
                class="table-row-modern"
              >
                <td class="table-cell-date text-center">
                  {{ formatarDataHora(venda.created_at) }}
                </td>
                <td class="text-center">
                  <span class="badge badge-modern badge-info">
                    {{ venda.numero_venda }}
                  </span>
                </td>
                <td class="text-center">
                  {{ venda.cliente_nome || 'Cliente não informado' }}
                </td>
                <td class="text-center">
                  <span class="badge badge-modern" :class="getBadgeClassFormaPagamento(venda.forma_pagamento)">
                    {{ formatarFormaPagamento(venda.forma_pagamento) }}
                  </span>
                </td>
                <td class="text-center">
                  <span class="table-cell-valor valor-entrada">
                    {{ formatarMoeda(venda.total) }}
                  </span>
                </td>
                <td class="text-center" style="text-align: center;">
                  <button
                    @click="abrirDetalhes(venda)"
                    class="btn btn-ghost btn-sm"
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

    <!-- Modal de Detalhes da Venda -->
    <div v-if="mostrarModalDetalhes" class="modal-overlay" @click.self="fecharDetalhes">
      <div class="modal-content modal-detalhes">
        <div class="modal-header">
          <h3>Detalhes da Venda {{ vendaSelecionada?.numero_venda }}</h3>
          <button class="btn-close" @click="fecharDetalhes">×</button>
        </div>
        <div class="modal-body">
          <div v-if="carregandoDetalhes" class="text-center py-8">
            <div class="loading-spinner mx-auto"></div>
            <p class="mt-4 text-gray-600">Carregando detalhes...</p>
          </div>
          <div v-else class="detalhes-grid">
            <!-- Informações da Venda -->
            <div class="detalhe-section">
              <h4 class="detalhe-titulo">Informações da Venda</h4>
              <div class="detalhe-item">
                <span class="detalhe-label">Número da Venda:</span>
                <span class="font-semibold">{{ vendaSelecionada.numero_venda }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Cliente:</span>
                <span>{{ vendaSelecionada.cliente_nome || 'Cliente não informado' }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Data/Hora:</span>
                <span>{{ formatarDataHora(vendaSelecionada.created_at) }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label">Forma de Pagamento:</span>
                <span class="font-semibold">{{ formatarFormaPagamento(vendaSelecionada.forma_pagamento) }}</span>
              </div>
            </div>

            <!-- Itens da Venda -->
            <div v-if="itensVenda.length > 0" class="detalhe-section">
              <h4 class="detalhe-titulo">Itens da Venda</h4>
              <div class="space-y-2">
                <div v-for="item in itensVenda" :key="item.id" class="detalhe-item">
                  <div class="flex-1">
                    <div class="font-medium">{{ item.produto_nome }}</div>
                    <div class="text-sm text-gray-500">
                      {{ item.quantidade }} × {{ formatarMoeda(item.preco_unitario) }}
                    </div>
                  </div>
                  <span class="font-semibold">{{ formatarMoeda(item.subtotal) }}</span>
                </div>
              </div>
            </div>

            <!-- Valores -->
            <div class="detalhe-section">
              <h4 class="detalhe-titulo">Valores</h4>
              <div class="detalhe-item">
                <span class="detalhe-label">Subtotal:</span>
                <span>{{ formatarMoeda(vendaSelecionada.subtotal) }}</span>
              </div>
              <div v-if="vendaSelecionada.desconto > 0" class="detalhe-item">
                <span class="detalhe-label">Desconto:</span>
                <span class="text-red-600">- {{ formatarMoeda(vendaSelecionada.desconto) }}</span>
              </div>
              <div class="detalhe-item">
                <span class="detalhe-label text-lg">Total:</span>
                <span class="detalhe-valor text-green-600">{{ formatarMoeda(vendaSelecionada.total) }}</span>
              </div>
              <div v-if="vendaSelecionada.valor_recebido" class="detalhe-item">
                <span class="detalhe-label">Valor Recebido:</span>
                <span>{{ formatarMoeda(vendaSelecionada.valor_recebido) }}</span>
              </div>
              <div v-if="vendaSelecionada.troco > 0" class="detalhe-item">
                <span class="detalhe-label">Troco:</span>
                <span>{{ formatarMoeda(vendaSelecionada.troco) }}</span>
              </div>
            </div>

            <!-- Observações -->
            <div v-if="vendaSelecionada.observacoes" class="detalhe-section">
              <h4 class="detalhe-titulo">Observações</h4>
              <p class="text-sm text-gray-700">{{ vendaSelecionada.observacoes }}</p>
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
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import Toast from '@/componentes/Toast.vue'
import {
  ShoppingCartIcon,
  CurrencyDollarIcon,
  ChartBarIcon,
  ClockIcon,
  InformationCircleIcon,
} from '@heroicons/vue/24/outline'

const caixaAtual = ref(null)
const vendas = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroData = ref('')
const mostrarToast = ref(false)
const mensagemToast = ref('')
const mostrarModalDetalhes = ref(false)
const vendaSelecionada = ref(null)
const itensVenda = ref([])
const carregandoDetalhes = ref(false)

const totalVendas = computed(() => {
  return vendas.value.reduce((sum, v) => sum + parseFloat(v.total || 0), 0)
})

const ticketMedio = computed(() => {
  return vendas.value.length > 0 ? totalVendas.value / vendas.value.length : 0
})

onMounted(async () => {
  await carregarCaixaAtual()
  if (caixaAtual.value) {
    await carregarVendas()
  }
})

async function carregarCaixaAtual() {
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
      .maybeSingle()

    if (error) throw error
    caixaAtual.value = data
  } catch (err) {
    console.error('Erro ao carregar caixa:', err)
    erro.value = 'Erro ao carregar informações do caixa'
  }
}

async function carregarVendas() {
  if (!caixaAtual.value) return

  try {
    carregando.value = true
    let query = supabase
      .from('vendas')
      .select(`
        *,
        clientes (nome)
      `)
      .eq('caixa_id', caixaAtual.value.id)
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
    
    vendas.value = (data || []).map(v => ({
      ...v,
      cliente_nome: v.clientes?.nome || null
    }))
  } catch (err) {
    console.error('Erro ao carregar vendas:', err)
    erro.value = 'Erro ao carregar histórico de vendas'
  } finally {
    carregando.value = false
  }
}

async function abrirDetalhes(venda) {
  vendaSelecionada.value = venda
  mostrarModalDetalhes.value = true
  carregandoDetalhes.value = true
  itensVenda.value = []

  try {
    const { data, error } = await supabase
      .from('itens_venda')
      .select(`
        *,
        produtos (nome)
      `)
      .eq('venda_id', venda.id)

    if (error) throw error
    
    itensVenda.value = (data || []).map(item => ({
      ...item,
      produto_nome: item.produtos?.nome || 'Produto não encontrado'
    }))
  } catch (err) {
    console.error('Erro ao carregar itens da venda:', err)
  } finally {
    carregandoDetalhes.value = false
  }
}

function fecharDetalhes() {
  mostrarModalDetalhes.value = false
  vendaSelecionada.value = null
  itensVenda.value = []
}

function formatarFormaPagamento(forma) {
  const formas = {
    dinheiro: 'Dinheiro',
    debito: 'Cartão Débito',
    credito: 'Cartão Crédito',
    pix: 'PIX',
    vale: 'Vale/Convênio'
  }
  return formas[forma] || forma
}

function getBadgeClassFormaPagamento(forma) {
  const classes = {
    dinheiro: 'badge-entrada',
    debito: 'badge-info',
    credito: 'badge-info',
    pix: 'badge-info',
    vale: 'badge-saida'
  }
  return classes[forma] || 'badge-info'
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

/* Containers */
.movimentacao-form-section,
.movimentacao-history-section {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

/* Section Headers */
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

/* Cards e Forms */
.card-form-modern,
.card-table-modern {
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

/* Tipo Selector */
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

/* Form Actions */
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

.text-center {
  text-align: center;
}

/* Modal Específico */
.badge-info {
  background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
  color: #1e40af;
  border-color: #3b82f6;
}

.modal-detalhes {
  max-width: 700px;
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

.modal-footer {
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
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
}
</style>
