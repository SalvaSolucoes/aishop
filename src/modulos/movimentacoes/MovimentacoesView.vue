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
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import {
  ArrowsRightLeftIcon,
  PlusIcon,
  ArrowUpIcon,
  ArrowDownIcon
} from '@heroicons/vue/24/outline'
import Toast from '@/componentes/Toast.vue'

const carregando = ref(false)
const erro = ref('')
const mostrarToast = ref(false)
const mensagemToast = ref('')
const caixaAtual = ref(null)

const novaMovimentacao = ref({
  tipo: 'entrada',
  valor: 0,
  descricao: '',
  categoria: ''
})

const totalEntradas = ref(0)
const totalSaidas = ref(0)

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
      await carregarTotais()
    }
  } catch (err) {
    erro.value = 'Erro ao verificar caixa: ' + err.message
    console.error(err)
  }
}

async function carregarTotais() {
  if (!caixaAtual.value) return

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('movimentacoes_caixa')
      .select('tipo, valor')
      .eq('caixa_id', caixaAtual.value.id)
      .eq('usuario_id', user.id)

    if (error) throw error

    totalEntradas.value = (data || [])
      .filter(m => m.tipo === 'entrada')
      .reduce((sum, m) => sum + m.valor, 0)

    totalSaidas.value = (data || [])
      .filter(m => m.tipo === 'saida')
      .reduce((sum, m) => sum + m.valor, 0)
  } catch (err) {
    console.error('Erro ao carregar totais:', err)
  }
}

function mostrarMensagemSucesso(mensagem) {
  mensagemToast.value = mensagem
  mostrarToast.value = true
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

    await carregarTotais()
    
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
  carregarTotais()
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
