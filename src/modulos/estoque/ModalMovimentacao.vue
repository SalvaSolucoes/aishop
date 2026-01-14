<template>
  <div class="modal-overlay" @click.self="fechar">
    <div class="modal-content">
      <div class="modal-header">
        <h3>Movimentação de Estoque</h3>
        <button class="btn-close" @click="fechar">×</button>
      </div>

      <form @submit.prevent="salvar" class="modal-body">
        <div v-if="erro" class="alert alert-erro">
          {{ erro }}
        </div>

        <div class="info-produto">
          <div class="info-item">
            <span class="info-label">Produto:</span>
            <span class="info-value">{{ produto.nome }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Estoque Atual:</span>
            <span class="info-value">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</span>
          </div>
        </div>

        <div class="form-section">
          <h4 class="section-title">Movimentação</h4>
          <div class="form-group">
            <label class="form-label">Tipo</label>
            <select v-model="dados.tipo" class="form-select" required>
              <optgroup label="Entradas">
                <option value="compra">Compra</option>
                <option value="devolucao">Devolução</option>
                <option value="ajuste">Ajuste Manual</option>
              </optgroup>
              <optgroup label="Saídas">
                <option value="venda">Venda</option>
                <option value="perda">Perda / Avaria</option>
                <option value="troca">Troca</option>
                <option value="ajuste">Ajuste Manual</option>
              </optgroup>
            </select>
          </div>
          <div class="form-group">
            <label class="form-label">Quantidade</label>
            <input
              v-model.number="dados.quantidade"
              type="number"
              class="form-input"
              required
              min="1"
              step="1"
              placeholder="0"
              :max="dados.tipo === 'saida' ? produto.quantidade : null"
            />
            <small v-if="dados.tipo === 'saida' && dados.quantidade > produto.quantidade" class="text-erro">
              Quantidade não pode ser maior que o estoque atual
            </small>
          </div>
          <div class="form-group">
            <label class="form-label">Motivo</label>
            <textarea
              v-model="dados.motivo"
              class="form-textarea"
              placeholder="Descreva o motivo da movimentação"
              rows="3"
            />
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-ghost" @click="fechar">
            Cancelar
          </button>
          <button type="submit" class="btn btn-primario" :disabled="salvando || (dados.tipo === 'saida' && dados.quantidade > produto.quantidade)">
            {{ salvando ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { supabase } from '@/servicos/supabase'

const props = defineProps({
  produto: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['fechar', 'salvar'])

const dados = ref({
  tipo: 'entrada',
  quantidade: 1,
  motivo: ''
})

const salvando = ref(false)
const erro = ref('')

async function salvar() {
  if (dados.value.tipo === 'saida' && dados.value.quantidade > props.produto.quantidade) {
    erro.value = 'Quantidade não pode ser maior que o estoque atual'
    return
  }

  salvando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    // Calcular nova quantidade
    const novaQuantidade = dados.value.tipo === 'entrada'
      ? props.produto.quantidade + dados.value.quantidade
      : props.produto.quantidade - dados.value.quantidade

    // Atualizar quantidade do produto
    const { error: errorProduto } = await supabase
      .from('produtos')
      .update({ quantidade: novaQuantidade })
      .eq('id', props.produto.id)

    if (errorProduto) throw errorProduto

    // Registrar movimentação
    const { error: errorMov } = await supabase
      .from('movimentacoes_estoque')
      .insert([{
        produto_id: props.produto.id,
        usuario_id: user.id,
        tipo: dados.value.tipo,
        quantidade: dados.value.quantidade,
        quantidade_anterior: props.produto.quantidade,
        quantidade_nova: novaQuantidade,
        motivo: dados.value.motivo
      }])

    if (errorMov) throw errorMov

    // Disparar evento para atualizar outros componentes
    window.dispatchEvent(new CustomEvent('movimentacao-estoque-registrada', {
      detail: {
        produto_id: props.produto.id,
        tipo: dados.value.tipo,
        quantidade: dados.value.quantidade,
        atualizouEstoque: true,
        atualizouRelatorios: true
      }
    }))

    emit('salvar')
  } catch (err) {
    erro.value = 'Erro ao registrar movimentação: ' + err.message
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
  max-width: 550px;
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

.info-produto {
  background: #f8fafc;
  padding: 1.25rem 2rem;
  border-bottom: 1px solid #e5e7eb;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.info-label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: #6b7280;
  min-width: 100px;
}

.info-value {
  font-size: 0.875rem;
  font-weight: 600;
  color: #111827;
}

.form-section {
  padding: 1.5rem 2rem;
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

.text-erro {
  color: #dc2626;
  font-size: 0.75rem;
  display: block;
  margin-top: 0.375rem;
  font-weight: 500;
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

  .info-produto {
    padding: 1rem 1.5rem;
  }

  .form-section {
    padding: 1.25rem 1.5rem;
  }

  .modal-footer {
    padding: 1rem 1.5rem;
  }
}
</style>
