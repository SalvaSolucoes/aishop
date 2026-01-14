<template>
  <div class="modal-overlay" @click.self="fechar">
    <div class="modal-content">
      <div class="modal-header">
        <h3>{{ cliente ? 'Editar Cliente' : 'Novo Cliente' }}</h3>
        <button class="btn-close" @click="fechar">×</button>
      </div>

      <form @submit.prevent="salvar" class="modal-body">
        <div v-if="erro" class="alert alert-erro">
          {{ erro }}
        </div>

        <!-- Informações Básicas -->
        <div class="form-section">
          <h4 class="section-title">Informações Básicas</h4>
          <div class="form-group">
            <label class="form-label">Nome Completo</label>
            <input
              v-model="dados.nome"
              type="text"
              class="form-input"
              required
              placeholder="Digite o nome completo"
            />
          </div>

          <div class="form-row">
            <div class="form-group">
              <label class="form-label">E-mail</label>
              <input
                v-model="dados.email"
                type="email"
                class="form-input"
                placeholder="exemplo@email.com"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Telefone</label>
              <input
                v-model="dados.telefone"
                type="tel"
                class="form-input"
                placeholder="(00) 00000-0000"
                @input="formatarTelefone"
                maxlength="15"
              />
            </div>
          </div>
        </div>

        <!-- Documentação -->
        <div class="form-section">
          <h4 class="section-title">Documentação</h4>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Tipo</label>
              <select v-model="dados.tipo_cliente" class="form-select" required>
                <option value="fisica">Pessoa Física</option>
                <option value="juridica">Pessoa Jurídica</option>
              </select>
            </div>
            <div class="form-group">
              <label class="form-label">CPF/CNPJ</label>
              <input
                v-model="dados.documento"
                type="text"
                class="form-input"
                :placeholder="dados.tipo_cliente === 'fisica' ? '000.000.000-00' : '00.000.000/0000-00'"
                @input="formatarDocumento"
                :maxlength="dados.tipo_cliente === 'fisica' ? 14 : 18"
              />
            </div>
          </div>
        </div>

        <!-- Endereço -->
        <div class="form-section">
          <h4 class="section-title">Endereço</h4>
          <div class="form-group">
            <label class="form-label">Endereço Completo</label>
            <input
              v-model="dados.endereco"
              type="text"
              class="form-input"
              placeholder="Rua, número e complemento"
            />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Cidade</label>
              <input
                v-model="dados.cidade"
                type="text"
                class="form-input"
                placeholder="Nome da cidade"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Estado</label>
              <input
                v-model="dados.estado"
                type="text"
                class="form-input"
                placeholder="UF"
                maxlength="2"
              />
            </div>
            <div class="form-group">
              <label class="form-label">CEP</label>
              <input
                v-model="dados.cep"
                type="text"
                class="form-input"
                placeholder="00000-000"
              />
            </div>
          </div>
        </div>

        <!-- Informações Adicionais -->
        <div class="form-section">
          <h4 class="section-title">Informações Adicionais</h4>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Data de Nascimento</label>
              <input
                v-model="dados.data_nascimento"
                type="date"
                class="form-input"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Situação</label>
              <select v-model="dados.situacao" class="form-select">
                <option value="ativo">Ativo</option>
                <option value="inativo">Inativo</option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Limite de Crédito</label>
              <input
                v-model.number="dados.limite_credito"
                type="number"
                class="form-input"
                min="0"
                step="0.01"
                placeholder="0,00"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Pontos de Fidelidade</label>
              <input
                v-model.number="dados.pontos_fidelidade"
                type="number"
                class="form-input"
                min="0"
                step="1"
                placeholder="0"
              />
            </div>
          </div>
          <div class="form-group">
            <label class="form-label">Observações</label>
            <textarea
              v-model="dados.observacoes"
              class="form-textarea"
              placeholder="Informações adicionais sobre o cliente"
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
import { ref, onMounted, watch } from 'vue'
import { supabase } from '@/servicos/supabase'

const props = defineProps({
  cliente: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['fechar', 'salvar'])

const dados = ref({
  nome: '',
  email: '',
  telefone: '',
  documento: '',
  tipo_cliente: 'fisica',
  data_nascimento: '',
  endereco: '',
  cidade: '',
  estado: '',
  cep: '',
  limite_credito: 0,
  pontos_fidelidade: 0,
  situacao: 'ativo',
  observacoes: ''
})

const salvando = ref(false)
const erro = ref('')

// Watch para reformatar documento quando tipo de cliente mudar
watch(() => dados.value.tipo_cliente, () => {
  if (dados.value.documento) {
    const valor = dados.value.documento.replace(/\D/g, '')
    formatarDocumento(valor)
  }
})

onMounted(() => {
  if (props.cliente) {
    dados.value = { ...props.cliente }
    // Formatar campos ao carregar dados existentes
    if (dados.value.telefone) {
      formatarTelefone(dados.value.telefone)
    }
    if (dados.value.documento) {
      formatarDocumento(dados.value.documento)
    }
  }
})

async function salvar() {
  salvando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    // Validação de e-mail
    if (dados.value.email && !validarEmail(dados.value.email)) {
      erro.value = 'E-mail inválido'
      salvando.value = false
      return
    }

    const dadosParaSalvar = {
      ...dados.value,
      usuario_id: user.id
    }

    if (props.cliente) {
      // Atualizar
      const { error } = await supabase
        .from('clientes')
        .update(dadosParaSalvar)
        .eq('id', props.cliente.id)

      if (error) throw error
    } else {
      // Criar
      const { error } = await supabase
        .from('clientes')
        .insert([dadosParaSalvar])

      if (error) throw error
    }

    emit('salvar')
  } catch (err) {
    erro.value = 'Erro ao salvar cliente: ' + err.message
    console.error(err)
  } finally {
    salvando.value = false
  }
}

function validarEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return re.test(email)
}

function formatarTelefone(event) {
  const valorInput = typeof event === 'string' ? event : (event.target ? event.target.value : event)
  let valor = valorInput.replace(/\D/g, '')
  
  // Formatação progressiva conforme digita
  if (valor.length === 0) {
    dados.value.telefone = ''
    return
  }
  
  if (valor.length <= 2) {
    // Apenas DDD: (XX
    dados.value.telefone = `(${valor}`
  } else if (valor.length <= 6) {
    // DDD + início do número: (XX) XXXX
    dados.value.telefone = `(${valor.slice(0, 2)}) ${valor.slice(2)}`
  } else if (valor.length <= 10) {
    // Telefone fixo completo: (XX) XXXX-XXXX
    dados.value.telefone = `(${valor.slice(0, 2)}) ${valor.slice(2, 6)}-${valor.slice(6)}`
  } else {
    // Celular completo: (XX) XXXXX-XXXX
    dados.value.telefone = `(${valor.slice(0, 2)}) ${valor.slice(2, 7)}-${valor.slice(7, 11)}`
  }
}

function formatarDocumento(event) {
  const valorInput = typeof event === 'string' ? event : (event.target ? event.target.value : event)
  let valor = valorInput.replace(/\D/g, '')
  
  if (valor.length === 0) {
    dados.value.documento = ''
    return
  }
  
  if (dados.value.tipo_cliente === 'fisica') {
    // CPF: XXX.XXX.XXX-XX (11 dígitos)
    // Formatação progressiva
    if (valor.length <= 3) {
      dados.value.documento = valor
    } else if (valor.length <= 6) {
      dados.value.documento = `${valor.slice(0, 3)}.${valor.slice(3)}`
    } else if (valor.length <= 9) {
      dados.value.documento = `${valor.slice(0, 3)}.${valor.slice(3, 6)}.${valor.slice(6)}`
    } else {
      dados.value.documento = `${valor.slice(0, 3)}.${valor.slice(3, 6)}.${valor.slice(6, 9)}-${valor.slice(9, 11)}`
    }
  } else {
    // CNPJ: XX.XXX.XXX/XXXX-XX (14 dígitos)
    // Formatação progressiva
    if (valor.length <= 2) {
      dados.value.documento = valor
    } else if (valor.length <= 5) {
      dados.value.documento = `${valor.slice(0, 2)}.${valor.slice(2)}`
    } else if (valor.length <= 8) {
      dados.value.documento = `${valor.slice(0, 2)}.${valor.slice(2, 5)}.${valor.slice(5)}`
    } else if (valor.length <= 12) {
      dados.value.documento = `${valor.slice(0, 2)}.${valor.slice(2, 5)}.${valor.slice(5, 8)}/${valor.slice(8)}`
    } else {
      dados.value.documento = `${valor.slice(0, 2)}.${valor.slice(2, 5)}.${valor.slice(5, 8)}/${valor.slice(8, 12)}-${valor.slice(12, 14)}`
    }
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
  max-width: 750px;
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

.form-hint {
  display: block;
  margin-top: 0.375rem;
  font-size: 0.75rem;
  color: #6b7280;
  line-height: 1.4;
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
