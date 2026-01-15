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
          <p class="alert-message">Abra um caixa no Carrinho para registrar movimentações</p>
        </div>
      </div>
    </div>

    <!-- Formulário de Nova Movimentação -->
    <div v-if="caixaAtual" class="movimentacao-form-section">
      <div class="section-header-modern">
        <div class="section-header-content">
          <div class="section-icon-wrapper">
            <PlusIcon class="section-icon" />
          </div>
          <div>
            <h3 class="section-title-modern">Registrar Movimentação de Caixa</h3>
            <p class="section-subtitle">Registre entradas e saídas de valores do caixa</p>
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
                  <span>Entrada (Suprimento)</span>
                </button>
                <button
                  type="button"
                  class="tipo-option"
                  :class="{ 'tipo-option-active': novaMovimentacao.tipo === 'saida' }"
                  @click="novaMovimentacao.tipo = 'saida'"
                >
                  <ArrowDownIcon class="tipo-icon tipo-icon-saida" />
                  <span>Saída (Sangria)</span>
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
                placeholder="Ex: Suprimento inicial, Retirada para banco..."
              />
            </div>

            <div class="form-group-modern form-group-full">
              <label class="form-label-modern">Categoria (Opcional)</label>
              <input
                v-model="novaMovimentacao.categoria"
                type="text"
                class="form-input-modern"
                placeholder="Ex: Suprimento, Sangria, Despesas..."
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
  PlusIcon,
} from '@heroicons/vue/24/outline'
import { 
  caixaAtual as caixaAtualStore,
  refreshCaixaState
} from '@/stores/caixa'

// Use store's reactive ref
const caixaAtual = caixaAtualStore
const carregando = ref(false)
const erro = ref('')
const mostrarToast = ref(false)
const mensagemToast = ref('')

const novaMovimentacao = ref({
  tipo: 'entrada',
  valor: null,
  descricao: '',
  categoria: ''
})

onMounted(async () => {
  await refreshCaixaState()
})

// Removed unused function
// async function carregarCaixaAtual() { ... }

async function registrarMovimentacao() {
  if (!caixaAtual.value) return

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const categoria = novaMovimentacao.value.categoria || (novaMovimentacao.value.tipo === 'entrada' ? 'Suprimento' : 'Sangria')

    const { error } = await supabase
      .from('movimentacoes_caixa')
      .insert({
        caixa_id: caixaAtual.value.id,
        usuario_id: user.id,
        tipo: novaMovimentacao.value.tipo,
        valor: novaMovimentacao.value.valor,
        descricao: novaMovimentacao.value.descricao,
        categoria
      })

    if (error) throw error

    // Atualizar totais do caixa
    const campo = novaMovimentacao.value.tipo === 'entrada' ? 'total_suprimento' : 'total_sangria'
    const { error: errorUpdate } = await supabase
      .from('caixas')
      .update({
        [campo]: (caixaAtual.value[campo] || 0) + novaMovimentacao.value.valor
      })
      .eq('id', caixaAtual.value.id)

    if (errorUpdate) throw errorUpdate

    mensagemToast.value = 'Movimentação registrada com sucesso!'
    mostrarToast.value = true

    // Limpar formulário
    novaMovimentacao.value = {
      tipo: 'entrada',
      valor: null,
      descricao: '',
      categoria: ''
    }

    // Refresh cash register state
    await refreshCaixaState()
  } catch (err) {
    console.error('Erro ao registrar movimentação:', err)
    erro.value = 'Erro ao registrar movimentação'
  }
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

/* Forms */
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
