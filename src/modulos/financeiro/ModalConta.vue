<template>
  <div class="modal-overlay" @click.self="fechar">
    <div class="modal-content">
      <div class="modal-header">
        <h3>{{ conta ? 'Editar Conta' : 'Nova Conta' }}</h3>
        <button class="btn-close" @click="fechar">×</button>
      </div>

      <form @submit.prevent="salvar" class="modal-body">
        <div v-if="erro" class="alert alert-erro">
          {{ erro }}
        </div>

        <!-- Informações Principais -->
        <div class="form-section">
          <h4 class="section-title">Informações Principais</h4>
          <div class="form-group">
            <label class="form-label">Tipo</label>
            <select v-model="dados.tipo" class="form-select" required>
              <option value="receber">A Receber</option>
              <option value="pagar">A Pagar</option>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Descrição</label>
            <input
              v-model="dados.descricao"
              type="text"
              class="form-input"
              required
              placeholder="Descreva a conta"
            />
          </div>
        </div>

        <!-- Valores e Datas -->
        <div class="form-section">
          <h4 class="section-title">Valores e Datas</h4>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Valor</label>
              <input
                v-model.number="dados.valor"
                type="number"
                class="form-input"
                required
                min="0.01"
                step="0.01"
                placeholder="0,00"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Data de Vencimento</label>
              <input
                v-model="dados.data_vencimento"
                type="date"
                class="form-input"
                required
              />
            </div>
          </div>
          <div v-if="conta && conta.status === 'pago'" class="form-group">
            <label class="form-label">Data de Pagamento</label>
            <input
              v-model="dados.data_pagamento"
              type="date"
              class="form-input"
            />
          </div>
        </div>

        <!-- Classificação -->
        <div class="form-section">
          <h4 class="section-title">Classificação</h4>
          <div class="form-group">
            <label class="form-label">Categoria</label>
            <input
              v-model="dados.categoria"
              type="text"
              class="form-input"
              placeholder="Ex: Vendas, Despesas, etc."
            />
          </div>
          <div class="form-group">
            <label class="form-label">Observações</label>
            <textarea
              v-model="dados.observacoes"
              class="form-textarea"
              placeholder="Informações adicionais"
              rows="3"
            />
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-ghost" @click="fechar">
            Cancelar
          </button>
          <button type="submit" class="btn btn-primario" :disabled="salvando">
            {{ salvando ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'

const props = defineProps({
  conta: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['fechar', 'salvar'])

const dados = ref({
  tipo: 'receber',
  descricao: '',
  valor: 0,
  data_vencimento: '',
  categoria: '',
  observacoes: '',
  status: 'pendente',
  data_pagamento: null
})

const salvando = ref(false)
const erro = ref('')

onMounted(() => {
  if (props.conta) {
    dados.value = {
      ...props.conta,
      data_vencimento: props.conta.data_vencimento ? props.conta.data_vencimento.split('T')[0] : '',
      data_pagamento: props.conta.data_pagamento ? props.conta.data_pagamento.split('T')[0] : null
    }
  } else {
    // Data padrão: 30 dias a partir de hoje
    const dataFutura = new Date()
    dataFutura.setDate(dataFutura.getDate() + 30)
    dados.value.data_vencimento = dataFutura.toISOString().split('T')[0]
  }
})

async function salvar() {
  salvando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    const dadosParaSalvar = {
      tipo: dados.value.tipo,
      descricao: dados.value.descricao,
      valor: dados.value.valor,
      data_vencimento: dados.value.data_vencimento,
      categoria: dados.value.categoria || null,
      observacoes: dados.value.observacoes || null,
      status: dados.value.status,
      usuario_id: user.id
    }

    if (dados.value.data_pagamento) {
      dadosParaSalvar.data_pagamento = dados.value.data_pagamento
    }

    if (props.conta) {
      // Atualizar
      const { error } = await supabase
        .from('contas_financeiras')
        .update(dadosParaSalvar)
        .eq('id', props.conta.id)

      if (error) throw error
    } else {
      // Criar
      const { error } = await supabase
        .from('contas_financeiras')
        .insert([dadosParaSalvar])

      if (error) throw error
    }

    // Disparar evento para atualizar outros componentes
    window.dispatchEvent(new CustomEvent('conta-financeira-registrada', {
      detail: {
        tipo: dados.value.tipo,
        valor: dados.value.valor,
        status: dados.value.status,
        atualizouFinanceiro: true,
        atualizouRelatorios: true
      }
    }))

    emit('salvar')
  } catch (err) {
    erro.value = 'Erro ao salvar conta: ' + err.message
    console.error(err)
  } finally {
    salvando.value = false
  }
}

function fechar() {
  emit('fechar')
}
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

.modal-content {
  background: white;
  border-radius: 1rem;
  width: 100%;
  max-width: 650px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  animation: slideUp 0.3s ease-out;
}

@keyframes slideUp {
  from {
    transform: translateY(20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
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
  overflow-y: auto;
  flex: 1;
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

.form-label:has(+ input[required]),
.form-label:has(+ select[required]),
.form-label:has(+ textarea[required]) {
  position: relative;
}

.form-label:has(+ input[required])::after,
.form-label:has(+ select[required])::after,
.form-label:has(+ textarea[required])::after {
  content: '*';
  color: #ef4444;
  margin-left: 0.25rem;
}

.form-input,
.form-select,
.form-textarea {
  transition: all 0.2s ease;
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
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.25rem 2rem;
  border-top: 1px solid #e5e7eb;
  background: #fafafa;
  border-bottom-left-radius: 1rem;
  border-bottom-right-radius: 1rem;
}

@media (max-width: 768px) {
  .modal-content {
    max-width: 100%;
    border-radius: 1rem 1rem 0 0;
    max-height: 95vh;
  }

  .modal-header {
    padding: 1.25rem 1.5rem;
  }

  .form-section {
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
