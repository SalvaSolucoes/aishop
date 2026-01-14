<template>
  <div class="clientes-view">
    <div class="view-header">
      <button class="btn btn-primario" @click="abrirModalCliente">
        + Adicionar Cliente
      </button>
    </div>

    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <div class="filtros">
      <div class="busca-produto-card" style="position: relative; max-width: 500px;">
        <div class="busca-produto">
          <input
            v-model="filtroBusca"
            type="text"
            class="form-input busca-input"
            placeholder="Buscar clientes por nome, e-mail ou documento..."
            @input="filtrarClientes"
            style="width: 100%;"
          />
          <button
            v-if="filtroBusca"
            class="btn btn-ghost btn-sm"
            @click="limparBusca"
            title="Limpar busca"
            style="margin-left: 0.5rem;"
          >
            ×
          </button>
        </div>
        <div v-if="clientesFiltrados.length > 0 && filtroBusca && clientesFiltrados.length < clientes.length" class="resultados-busca">
          <div class="resultado-info">
            {{ clientesFiltrados.length }} cliente(s) encontrado(s)
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div v-if="carregando" class="text-center" style="padding: 2rem;">
        Carregando clientes...
      </div>

      <div v-else-if="clientesFiltrados.length === 0" class="text-center" style="padding: 2rem;">
        Nenhum cliente encontrado.
      </div>

      <table v-else class="tabela tabela-clientes">
        <thead>
          <tr>
            <th>Nome</th>
            <th>E-mail</th>
            <th>Telefone</th>
            <th>Documento</th>
            <th>Cadastro</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="cliente in clientesFiltrados" :key="cliente.id">
            <td>{{ cliente.nome }}</td>
            <td>{{ cliente.email || '-' }}</td>
            <td>{{ cliente.telefone || '-' }}</td>
            <td>{{ formatarDocumento(cliente.documento) || '-' }}</td>
            <td>{{ formatarData(cliente.created_at) }}</td>
            <td>
              <button class="btn btn-ghost" @click="editarCliente(cliente)" style="margin-right: 0.5rem;">
                Editar
              </button>
              <button class="btn btn-ghost" @click="verHistorico(cliente)" style="margin-right: 0.5rem;">
                Histórico
              </button>
              <button class="btn btn-perigo" @click="confirmarExclusao(cliente)">
                Excluir
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal de Cliente -->
    <ModalCliente
      v-if="mostrarModalCliente"
      :cliente="clienteSelecionado"
      @fechar="fecharModalCliente"
      @salvar="salvarCliente"
    />

    <!-- Modal de Histórico -->
    <ModalHistorico
      v-if="mostrarModalHistorico"
      :cliente="clienteSelecionado"
      @fechar="fecharModalHistorico"
    />

    <!-- Modal de Confirmação -->
    <ModalConfirmacao
      :mostrar="mostrarModalConfirmacao"
      :titulo="tituloConfirmacao"
      :mensagem="mensagemConfirmacao"
      :tipo="tipoConfirmacao"
      texto-confirmar="Excluir"
      texto-cancelar="Cancelar"
      @confirmar="executarConfirmacao"
      @cancelar="cancelarConfirmacao"
      @fechar="mostrarModalConfirmacao = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarData } from '@/utils/formatadores'
import ModalCliente from './ModalCliente.vue'
import ModalHistorico from './ModalHistorico.vue'
import ModalConfirmacao from '@/componentes/ModalConfirmacao.vue'

const clientes = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroBusca = ref('')
const timeoutBusca = ref(null)
const mostrarModalCliente = ref(false)
const mostrarModalHistorico = ref(false)
const clienteSelecionado = ref(null)
const mostrarModalConfirmacao = ref(false)
const tituloConfirmacao = ref('')
const mensagemConfirmacao = ref('')
const tipoConfirmacao = ref('danger')
const callbackConfirmacao = ref(null)
const itemParaExcluir = ref(null)

const clientesFiltrados = computed(() => {
  if (!filtroBusca.value) return clientes.value

  const busca = filtroBusca.value.toLowerCase().trim()
  if (!busca) return clientes.value

  return clientes.value.filter(c =>
    c.nome.toLowerCase().includes(busca) ||
    (c.email && c.email.toLowerCase().includes(busca)) ||
    (c.telefone && c.telefone.replace(/\D/g, '').includes(busca.replace(/\D/g, ''))) ||
    (c.documento && c.documento.replace(/\D/g, '').includes(busca.replace(/\D/g, '')))
  )
})

function filtrarClientes() {
  // Limpar timeout anterior
  if (timeoutBusca.value) {
    clearTimeout(timeoutBusca.value)
  }

  // Debounce: aguardar 200ms após parar de digitar
  timeoutBusca.value = setTimeout(() => {
    // A filtragem já é feita pelo computed, apenas forçar atualização
  }, 200)
}

function limparBusca() {
  filtroBusca.value = ''
  if (timeoutBusca.value) {
    clearTimeout(timeoutBusca.value)
  }
}

async function carregarClientes() {
  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('usuario_id', user.id)
      .order('nome')

    if (error) throw error
    clientes.value = data || []
  } catch (err) {
    erro.value = 'Erro ao carregar clientes: ' + err.message
    console.error(err)
  } finally {
    carregando.value = false
  }
}

function abrirModalCliente() {
  clienteSelecionado.value = null
  mostrarModalCliente.value = true
}

function editarCliente(cliente) {
  clienteSelecionado.value = cliente
  mostrarModalCliente.value = true
}

function fecharModalCliente() {
  mostrarModalCliente.value = false
  clienteSelecionado.value = null
}

function verHistorico(cliente) {
  clienteSelecionado.value = cliente
  mostrarModalHistorico.value = true
}

function fecharModalHistorico() {
  mostrarModalHistorico.value = false
  clienteSelecionado.value = null
}

async function salvarCliente() {
  await carregarClientes()
  fecharModalCliente()
}

function confirmarExclusao(cliente) {
  itemParaExcluir.value = cliente
  mostrarConfirmacao(
    'Excluir Cliente',
    `Deseja realmente excluir o cliente "${cliente.nome}"? Esta ação não pode ser desfeita.`,
    'danger',
    () => excluirCliente(itemParaExcluir.value.id)
  )
}

function mostrarConfirmacao(titulo, mensagem, tipo, callback) {
  tituloConfirmacao.value = titulo
  mensagemConfirmacao.value = mensagem
  tipoConfirmacao.value = tipo
  callbackConfirmacao.value = callback
  mostrarModalConfirmacao.value = true
}

function executarConfirmacao() {
  if (callbackConfirmacao.value) {
    callbackConfirmacao.value()
  }
  itemParaExcluir.value = null
}

function cancelarConfirmacao() {
  callbackConfirmacao.value = null
  itemParaExcluir.value = null
}

async function excluirCliente(id) {
  try {
    const { error } = await supabase
      .from('clientes')
      .delete()
      .eq('id', id)

    if (error) throw error
    await carregarClientes()
  } catch (err) {
    erro.value = 'Erro ao excluir cliente: ' + err.message
    console.error(err)
  }
}

function formatarDocumento(doc) {
  if (!doc) return ''
  const apenasNumeros = doc.replace(/\D/g, '')
  if (apenasNumeros.length === 11) {
    return apenasNumeros.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
  } else if (apenasNumeros.length === 14) {
    return apenasNumeros.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5')
  }
  return doc
}

// Listener para recarregar quando uma venda é finalizada
function onVendaFinalizada(event) {
  if (event.detail?.atualizouCliente) {
    carregarClientes()
  }
}

onMounted(() => {
  carregarClientes()
  // Escutar eventos de venda finalizada
  window.addEventListener('venda-finalizada', onVendaFinalizada)
})

onUnmounted(() => {
  window.removeEventListener('venda-finalizada', onVendaFinalizada)
})
</script>

<style scoped>
.view-header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-bottom: 1rem;
}

.filtros {
  margin-bottom: 1rem;
}

.busca-produto {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.busca-input {
  flex: 1;
}

.resultados-busca {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  margin-top: 0.25rem;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  z-index: 10;
  max-height: 200px;
  overflow-y: auto;
}

.resultado-info {
  padding: 0.75rem 1rem;
  font-size: 0.875rem;
  color: #6b7280;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
}

.tabela-clientes th,
.tabela-clientes td {
  text-align: center;
}

.text-center {
  text-align: center;
}
</style>
