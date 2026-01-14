<template>
  <div class="modal-overlay" @click.self="fechar">
    <div class="modal-content modal-fechar-caixa">
      <div class="modal-header">
        <h3>Fechar Caixa</h3>
        <button class="btn-close" @click="fechar">×</button>
      </div>

      <div class="modal-body">
        <div v-if="erro" class="alert alert-erro">
          {{ erro }}
        </div>

        <div v-if="carregando" class="text-center" style="padding: 2rem;">
          Carregando informações...
        </div>

        <div v-else>
          <!-- Resumo do Caixa -->
          <div class="resumo-fechamento">
            <div class="resumo-item">
              <span class="resumo-label">Valor Inicial:</span>
              <span class="resumo-valor">{{ formatarMoeda(caixa.valor_inicial) }}</span>
            </div>
            <div class="resumo-item">
              <span class="resumo-label">Total de Vendas:</span>
              <span class="resumo-valor positivo">{{ formatarMoeda(totalVendas) }}</span>
            </div>
            <div class="resumo-item">
              <span class="resumo-label">Total Entradas:</span>
              <span class="resumo-valor positivo">{{ formatarMoeda(totalEntradas) }}</span>
            </div>
            <div class="resumo-item">
              <span class="resumo-label">Total Saídas:</span>
              <span class="resumo-valor negativo">{{ formatarMoeda(totalSaidas) }}</span>
            </div>
            <div class="resumo-item total">
              <span class="resumo-label">Saldo Esperado:</span>
              <span class="resumo-valor">{{ formatarMoeda(saldoEsperado) }}</span>
            </div>
          </div>

          <!-- Formas de Pagamento -->
          <div class="secao-pagamento">
            <h4>Total por Forma de Pagamento</h4>
            <div class="formas-pagamento-grid">
              <div class="forma-item">
                <span class="forma-label">
                  <BanknotesIcon class="icone-forma" />
                  Dinheiro:
                </span>
                <span class="forma-valor">{{ formatarMoeda(totaisPorForma.dinheiro) }}</span>
              </div>
              <div class="forma-item">
                <span class="forma-label">
                  <CreditCardIcon class="icone-forma" />
                  Débito:
                </span>
                <span class="forma-valor">{{ formatarMoeda(totaisPorForma.debito) }}</span>
              </div>
              <div class="forma-item">
                <span class="forma-label">
                  <CreditCardIcon class="icone-forma" />
                  Crédito:
                </span>
                <span class="forma-valor">{{ formatarMoeda(totaisPorForma.credito) }}</span>
              </div>
              <div class="forma-item">
                <span class="forma-label">
                  <DevicePhoneMobileIcon class="icone-forma" />
                  Pix:
                </span>
                <span class="forma-valor">{{ formatarMoeda(totaisPorForma.pix) }}</span>
              </div>
              <div class="forma-item">
                <span class="forma-label">
                  <GiftIcon class="icone-forma" />
                  Vale/Convênio:
                </span>
                <span class="forma-valor">{{ formatarMoeda(totaisPorForma.vale) }}</span>
              </div>
            </div>
          </div>

          <!-- Sangria e Suprimento -->
          <div class="secao-movimentacoes form-section">
            <h4 class="section-title">Movimentações Especiais</h4>
            <div class="form-row">
              <div class="form-group">
                <label class="form-label">Total Sangria</label>
                <input
                  v-model.number="dadosFechamento.total_sangria"
                  type="number"
                  class="form-input form-input-readonly"
                  min="0"
                  step="0.01"
                  placeholder="0,00"
                  readonly
                />
                <small class="form-hint">Total retirado do caixa</small>
              </div>
              <div class="form-group">
                <label class="form-label">Total Suprimento</label>
                <input
                  v-model.number="dadosFechamento.total_suprimento"
                  type="number"
                  class="form-input form-input-readonly"
                  min="0"
                  step="0.01"
                  placeholder="0,00"
                  readonly
                />
                <small class="form-hint">Total adicionado ao caixa</small>
              </div>
            </div>
          </div>

          <!-- Saldo Real e Diferença -->
          <div class="secao-saldo form-section">
            <h4 class="section-title">Fechamento</h4>
            <div class="form-group">
              <label class="form-label">Saldo Real em Dinheiro</label>
              <input
                v-model.number="dadosFechamento.saldo_real"
                type="number"
                class="form-input"
                min="0"
                step="0.01"
                placeholder="0,00"
                required
                @input="calcularDiferenca"
              />
              <small class="form-hint">Informe o valor real contado no caixa</small>
            </div>

            <div class="diferenca-caixa" :class="{ 'diferenca-positiva': diferencaCaixa > 0, 'diferenca-negativa': diferencaCaixa < 0, 'diferenca-zero': diferencaCaixa === 0 }">
              <span class="diferenca-label">Diferença de Caixa:</span>
              <span class="diferenca-valor">{{ formatarMoeda(Math.abs(diferencaCaixa)) }}</span>
              <span class="diferenca-tipo">
                {{ diferencaCaixa > 0 ? 'Sobra' : diferencaCaixa < 0 ? 'Falta' : 'OK' }}
              </span>
            </div>
          </div>

          <!-- Observações -->
          <div class="form-section">
            <h4 class="section-title">Observações</h4>
            <div class="form-group">
              <label class="form-label">Observações</label>
              <textarea
                v-model="dadosFechamento.observacoes"
                class="form-textarea"
                placeholder="Informações adicionais sobre o fechamento"
                rows="3"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" @click="fechar" :disabled="salvando">
          Cancelar
        </button>
        <button
          type="button"
          class="btn btn-primario"
          @click="confirmarFechamento"
          :disabled="salvando || !dadosFechamento.saldo_real"
        >
          {{ salvando ? 'Fechando...' : 'Confirmar Fechamento' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import {
  BanknotesIcon,
  CreditCardIcon,
  DevicePhoneMobileIcon,
  GiftIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  caixa: {
    type: Object,
    required: true
  },
  movimentacoes: {
    type: Array,
    default: () => []
  }
})

const emit = defineEmits(['fechar', 'fechado'])

const carregando = ref(true)
const salvando = ref(false)
const erro = ref('')
const vendas = ref([])
const totaisPorForma = ref({
  dinheiro: 0,
  debito: 0,
  credito: 0,
  pix: 0,
  vale: 0,
  mistura: 0
})

const dadosFechamento = ref({
  total_sangria: 0,
  total_suprimento: 0,
  saldo_real: 0,
  observacoes: ''
})

const totalVendas = computed(() => {
  return vendas.value.reduce((sum, v) => sum + v.total, 0)
})

const totalEntradas = computed(() => {
  return props.movimentacoes
    .filter(m => m.tipo === 'entrada' || m.tipo === 'suprimento')
    .reduce((sum, m) => sum + m.valor, 0)
})

const totalSaidas = computed(() => {
  return props.movimentacoes
    .filter(m => m.tipo === 'saida' || m.tipo === 'sangria')
    .reduce((sum, m) => sum + m.valor, 0)
})

const saldoEsperado = computed(() => {
  return props.caixa.valor_inicial + totalVendas.value + totalEntradas.value - totalSaidas.value
})

const diferencaCaixa = computed(() => {
  if (!dadosFechamento.value.saldo_real) return 0
  return dadosFechamento.value.saldo_real - (props.caixa.valor_inicial + totaisPorForma.value.dinheiro - dadosFechamento.value.total_sangria + dadosFechamento.value.total_suprimento)
})

async function carregarDados() {
  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Carregar vendas do caixa
    const { data: vendasData, error: errorVendas } = await supabase
      .from('vendas')
      .select('*')
      .eq('caixa_id', props.caixa.id)
      .eq('usuario_id', user.id)

    if (errorVendas) throw errorVendas
    vendas.value = vendasData || []

    // Calcular totais por forma de pagamento
    totaisPorForma.value = {
      dinheiro: 0,
      debito: 0,
      credito: 0,
      pix: 0,
      vale: 0,
      mistura: 0
    }

    vendas.value.forEach(venda => {
      if (venda.forma_pagamento === 'mistura') {
        // Para pagamento misto, precisaríamos de uma tabela separada
        // Por enquanto, vamos considerar o total
      } else if (totaisPorForma.value.hasOwnProperty(venda.forma_pagamento)) {
        totaisPorForma.value[venda.forma_pagamento] += venda.total
      }
    })

    // Calcular sangria e suprimento
    dadosFechamento.value.total_sangria = props.movimentacoes
      .filter(m => m.tipo === 'sangria')
      .reduce((sum, m) => sum + m.valor, 0)

    dadosFechamento.value.total_suprimento = props.movimentacoes
      .filter(m => m.tipo === 'suprimento')
      .reduce((sum, m) => sum + m.valor, 0)
  } catch (err) {
    erro.value = 'Erro ao carregar dados: ' + err.message
    console.error(err)
  } finally {
    carregando.value = false
  }
}

function calcularDiferenca() {
  // Calculado automaticamente via computed
}

async function confirmarFechamento() {
  if (!dadosFechamento.value.saldo_real) {
    erro.value = 'Informe o saldo real em dinheiro'
    return
  }

  salvando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    const { error } = await supabase
      .from('caixas')
      .update({
        data_fechamento: new Date().toISOString(),
        valor_final: saldoEsperado.value,
        total_dinheiro: totaisPorForma.value.dinheiro,
        total_debito: totaisPorForma.value.debito,
        total_credito: totaisPorForma.value.credito,
        total_pix: totaisPorForma.value.pix,
        total_vale: totaisPorForma.value.vale,
        total_sangria: dadosFechamento.value.total_sangria,
        total_suprimento: dadosFechamento.value.total_suprimento,
        diferenca_caixa: diferencaCaixa.value
      })
      .eq('id', props.caixa.id)

    if (error) throw error

    emit('fechado')
  } catch (err) {
    erro.value = 'Erro ao fechar caixa: ' + err.message
    console.error(err)
  } finally {
    salvando.value = false
  }
}

function fechar() {
  emit('fechar')
}

onMounted(() => {
  carregarDados()
})
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
  animation: fadeIn 0.2s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.modal-fechar-caixa {
  max-width: 700px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e5e7eb;
  background: #ffffff;
}

.modal-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
  letter-spacing: -0.01em;
}

.btn-close {
  background: #f3f4f6;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #6b7280;
  line-height: 1;
  padding: 0;
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
}

.btn-close:hover {
  background: #e5e7eb;
  color: #111827;
  transform: rotate(90deg);
}

.modal-body {
  padding: 0;
}

.resumo-fechamento {
  background: #f8fafc;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e5e7eb;
}

.resumo-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.resumo-item.total {
  border-bottom: none;
  border-top: 2px solid #e5e7eb;
  margin-top: 0.5rem;
  padding-top: 1rem;
  font-size: 1.125rem;
  font-weight: 600;
}

.resumo-label {
  color: #6b7280;
  font-weight: 500;
}

.resumo-valor {
  font-weight: 600;
  color: #111827;
}

.resumo-valor.positivo {
  color: #059669;
}

.resumo-valor.negativo {
  color: #dc2626;
}

.form-section {
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #f3f4f6;
}

.form-section:last-of-type {
  border-bottom: none;
}

.section-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 1.25rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.secao-pagamento {
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #f3f4f6;
}

.formas-pagamento-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 0.75rem;
}

.forma-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: white;
  border-radius: 0.5rem;
}

.forma-label {
  font-weight: 500;
  color: #374151;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.icone-forma {
  width: 1.25rem;
  height: 1.25rem;
  color: #6b7280;
}

.forma-valor {
  font-weight: 600;
  color: #059669;
}

.diferenca-caixa {
  padding: 1rem;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 1rem;
  font-weight: 600;
}

.diferenca-positiva {
  background: #d1fae5;
  color: #065f46;
}

.diferenca-negativa {
  background: #fee2e2;
  color: #991b1b;
}

.diferenca-zero {
  background: #dbeafe;
  color: #1e40af;
}

.diferenca-valor {
  font-size: 1.25rem;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.5rem 2rem;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group:last-of-type {
  margin-bottom: 0;
}

.form-label {
  display: block;
  font-size: 0.8125rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
  letter-spacing: -0.01em;
}

.form-hint {
  display: block;
  margin-top: 0.375rem;
  font-size: 0.75rem;
  color: #6b7280;
  line-height: 1.4;
}

.form-input-readonly {
  background-color: #f9fafb;
  cursor: not-allowed;
}

.form-input:focus,
.form-select:focus,
.form-textarea:focus {
  border-color: #ea580c;
  box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.1);
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1rem;
}

.modal-footer {
  background: #fafafa;
  padding: 1.25rem 2rem;
}

.text-center {
  text-align: center;
}

@media (max-width: 768px) {
  .form-section,
  .secao-pagamento {
    padding: 1.25rem 1.5rem;
  }

  .form-row {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .modal-footer {
    padding: 1rem 1.5rem;
  }
}
</style>
