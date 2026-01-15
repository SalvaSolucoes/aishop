<template>
  <div class="modal-overlay" @click.self="fechar">
    <div class="modal-content">
      <div class="modal-header">
        <h3>{{ produto ? 'Editar Produto' : 'Novo Produto' }}</h3>
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
            <label class="form-label">Nome do Produto</label>
            <input
              v-model="dados.nome"
              type="text"
              class="form-input"
              required
              placeholder="Digite o nome do produto"
            />
          </div>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Código Interno</label>
              <input
                v-model="dados.codigo"
                type="text"
                class="form-input"
                placeholder="Código único"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Código de Barras</label>
              <input
                v-model="dados.codigo_barras"
                type="text"
                class="form-input"
                placeholder="7891234567890"
                @blur="validarCodigoBarras"
              />
              <small v-if="erroCodigoBarras" class="text-erro">{{ erroCodigoBarras }}</small>
            </div>
          </div>
        </div>

        <!-- Estoque -->
        <div class="form-section">
          <h4 class="section-title">Estoque</h4>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Quantidade</label>
              <input
                v-model.number="dados.quantidade"
                type="number"
                class="form-input"
                required
                min="0"
                step="1"
                placeholder="0"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Estoque Mínimo</label>
              <input
                v-model.number="dados.estoque_minimo"
                type="number"
                class="form-input"
                min="0"
                step="1"
                placeholder="0"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Unidade</label>
              <select v-model="dados.unidade" class="form-select">
                <option value="un">Unidade (un)</option>
                <option value="kg">Quilograma (kg)</option>
                <option value="g">Grama (g)</option>
                <option value="l">Litro (l)</option>
                <option value="ml">Mililitro (ml)</option>
                <option value="m">Metro (m)</option>
                <option value="cm">Centímetro (cm)</option>
                <option value="cx">Caixa (cx)</option>
                <option value="pct">Pacote (pct)</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Preços -->
        <div class="form-section">
          <h4 class="section-title">Preços</h4>
          <div class="form-row">
            <div class="form-group">
              <label class="form-label">Preço de Custo</label>
              <input
                v-model.number="dados.preco_custo"
                type="number"
                class="form-input"
                min="0"
                step="0.01"
                placeholder="0,00"
                @input="calcularMargemLucro"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Preço de Venda</label>
              <input
                v-model.number="dados.preco_unitario"
                type="number"
                class="form-input"
                required
                min="0"
                step="0.01"
                placeholder="0,00"
                @input="calcularMargemLucro"
              />
            </div>
            <div class="form-group">
              <label class="form-label">Margem de Lucro (%)</label>
              <input
                v-model="margemLucroFormatada"
                type="text"
                class="form-input form-input-readonly"
                placeholder="0,00%"
                readonly
              />
              <small class="form-hint">Calculada automaticamente</small>
            </div>
          </div>
        </div>

        <!-- Classificação -->
        <div class="form-section">
          <h4 class="section-title">Classificação</h4>
          <div class="form-group">
            <label class="form-label">Categoria</label>
            <div class="relative">
              <input
                v-model="dados.categoria"
                type="text"
                class="form-input"
                placeholder="Nome da categoria"
                @input="buscarCategoriasSugeridas"
                @focus="mostrarSugestoes = true"
              />
              <!-- Lista de Sugestões -->
              <div v-if="mostrarSugestoes && categoriasSugeridas.length > 0" class="sugestoes-dropdown">
                <button
                  v-for="categoria in categoriasSugeridas"
                  :key="categoria.id"
                  type="button"
                  class="sugestao-item"
                  @click="selecionarCategoria(categoria.nome)"
                >
                  <span class="sugestao-nome">{{ categoria.nome }}</span>
                  <span class="sugestao-badge">Usado {{ categoria.vezes_usado }}x</span>
                </button>
              </div>
            </div>
            <small class="form-hint">A categoria será salva para sugestões futuras</small>
          </div>
          <div class="form-group">
            <label class="form-label">Descrição</label>
            <textarea
              v-model="dados.descricao"
              class="form-textarea"
              placeholder="Descrição detalhada do produto"
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
import { ref, onMounted, onUnmounted, computed } from 'vue'
import { supabase } from '@/servicos/supabase'

const props = defineProps({
  produto: {
    type: Object,
    default: null
  }
})

const emit = defineEmits(['fechar', 'salvar'])

const dados = ref({
  codigo: '',
  codigo_barras: '',
  nome: '',
  quantidade: 0,
  estoque_minimo: 0,
  preco_custo: 0,
  preco_unitario: 0,
  margem_lucro: 0,
  unidade: 'un',
  categoria: '',
  descricao: ''
})

const salvando = ref(false)
const erro = ref('')
const erroCodigoBarras = ref('')
const mostrarSugestoes = ref(false)
const categoriasSugeridas = ref([])
const timeoutBusca = ref(null)

const margemLucroFormatada = computed(() => {
  if (!dados.value.margem_lucro || dados.value.margem_lucro === 0) {
    return '0,00%'
  }
  return dados.value.margem_lucro.toFixed(2).replace('.', ',') + '%'
})

onMounted(() => {
  if (props.produto) {
    dados.value = { ...props.produto }
  }
  // Carregar categorias ao abrir o modal
  carregarCategorias()
  // Fechar sugestões ao clicar fora
  document.addEventListener('click', fecharSugestoesAoClicarFora)
})

onUnmounted(() => {
  document.removeEventListener('click', fecharSugestoesAoClicarFora)
})

async function salvar() {
  salvando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    const dadosParaSalvar = {
      ...dados.value,
      usuario_id: user.id
    }

    if (props.produto) {
      // Atualizar
      const { error } = await supabase
        .from('produtos')
        .update(dadosParaSalvar)
        .eq('id', props.produto.id)

      if (error) throw error
    } else {
      // Criar
      const { error } = await supabase
        .from('produtos')
        .insert([dadosParaSalvar])

      if (error) throw error
    }

    // Salvar ou atualizar categoria
    if (dados.value.categoria && dados.value.categoria.trim()) {
      await salvarCategoria(user.id, dados.value.categoria.trim())
    }

    emit('salvar')
  } catch (err) {
    erro.value = 'Erro ao salvar produto: ' + err.message
    console.error(err)
  } finally {
    salvando.value = false
  }
}

async function salvarCategoria(userId, nomeCategoria) {
  try {
    // Verificar se a categoria já existe
    const { data: categoriaExistente } = await supabase
      .from('categorias_produtos')
      .select('*')
      .eq('usuario_id', userId)
      .eq('nome', nomeCategoria)
      .maybeSingle()

    if (categoriaExistente) {
      // Atualizar contador de uso
      await supabase
        .from('categorias_produtos')
        .update({
          vezes_usado: categoriaExistente.vezes_usado + 1,
          usado_em: new Date().toISOString()
        })
        .eq('id', categoriaExistente.id)
    } else {
      // Criar nova categoria
      await supabase
        .from('categorias_produtos')
        .insert([{
          usuario_id: userId,
          nome: nomeCategoria,
          vezes_usado: 1,
          usado_em: new Date().toISOString()
        }])
    }
  } catch (err) {
    console.error('Erro ao salvar categoria:', err)
    // Não bloqueia o salvamento do produto
  }
}

async function carregarCategorias() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('categorias_produtos')
      .select('*')
      .eq('usuario_id', user.id)
      .order('vezes_usado', { ascending: false })

    if (error) throw error
    categoriasSugeridas.value = data || []
  } catch (err) {
    console.error('Erro ao carregar categorias:', err)
  }
}

function buscarCategoriasSugeridas() {
  // Debounce para evitar muitas consultas
  clearTimeout(timeoutBusca.value)
  
  timeoutBusca.value = setTimeout(() => {
    if (!dados.value.categoria || dados.value.categoria.length < 2) {
      mostrarSugestoes.value = false
      return
    }

    const termoBusca = dados.value.categoria.toLowerCase()
    const sugestoesFiltradas = categoriasSugeridas.value.filter(cat => {
      return cat.nome.toLowerCase().includes(termoBusca)
    })

    categoriasSugeridas.value = sugestoesFiltradas
    mostrarSugestoes.value = sugestoesFiltradas.length > 0
  }, 300)
}

function selecionarCategoria(nomeCategoria) {
  dados.value.categoria = nomeCategoria
  mostrarSugestoes.value = false
}

function fecharSugestoesAoClicarFora(event) {
  // Fechar sugestões se clicar fora do dropdown
  const dropdown = event.target.closest('.sugestoes-dropdown')
  const input = event.target.closest('.form-input')
  
  if (!dropdown && !input) {
    mostrarSugestoes.value = false
  }
}

function fechar() {
  emit('fechar')
}

function calcularMargemLucro() {
  if (dados.value.preco_custo > 0 && dados.value.preco_unitario > 0) {
    const lucro = dados.value.preco_unitario - dados.value.preco_custo
    const margem = (lucro / dados.value.preco_custo) * 100
    // Limitar a 2 casas decimais
    dados.value.margem_lucro = Math.round(margem * 100) / 100
  } else {
    dados.value.margem_lucro = 0
  }
}

function validarCodigoBarras() {
  erroCodigoBarras.value = ''
  if (!dados.value.codigo_barras) return

  const codigo = dados.value.codigo_barras.replace(/\D/g, '')
  
  // EAN-13: 13 dígitos
  // EAN-8: 8 dígitos
  // UPC: 12 dígitos
  if (codigo.length === 8 || codigo.length === 12 || codigo.length === 13) {
    dados.value.codigo_barras = codigo
  } else if (codigo.length > 0) {
    erroCodigoBarras.value = 'Código de barras deve ter 8, 12 ou 13 dígitos'
  }
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

.form-input-readonly {
  background-color: #f9fafb;
  cursor: not-allowed;
}

.text-erro {
  color: #dc2626;
  font-size: 0.75rem;
  display: block;
  margin-top: 0.375rem;
  font-weight: 500;
}

.form-hint {
  display: block;
  margin-top: 0.375rem;
  font-size: 0.75rem;
  color: #6b7280;
  line-height: 1.4;
}

.relative {
  position: relative;
}

.sugestoes-dropdown {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  margin-top: 0.25rem;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
  max-height: 200px;
  overflow-y: auto;
  z-index: 50;
  animation: slideDown 0.2s ease-out;
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.sugestao-item {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  border: none;
  background: white;
  cursor: pointer;
  transition: all 0.15s ease;
  text-align: left;
  border-bottom: 1px solid #f3f4f6;
}

.sugestao-item:last-child {
  border-bottom: none;
}

.sugestao-item:hover {
  background: #f9fafb;
}

.sugestao-nome {
  font-size: 0.875rem;
  color: #111827;
  font-weight: 500;
}

.sugestao-badge {
  font-size: 0.75rem;
  color: #6b7280;
  background: #f3f4f6;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
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
