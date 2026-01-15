<template>
  <div class="financeiro-view">
    <div class="view-header">
      <button class="btn btn-primario" @click="abrirModalConta">
        + Adicionar Conta
      </button>
    </div>

    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <div class="resumo-financeiro">
      <div class="card card-resumo">
        <h3>Total a Receber</h3>
        <p class="valor-positivo">{{ formatarMoeda(totalReceber) }}</p>
      </div>
      <div class="card card-resumo">
        <h3>Total a Pagar</h3>
        <p class="valor-negativo">{{ formatarMoeda(totalPagar) }}</p>
      </div>
      <div class="card card-resumo">
        <h3>Saldo</h3>
        <p :class="saldo >= 0 ? 'valor-positivo' : 'valor-negativo'">
          {{ formatarMoeda(saldo) }}
        </p>
      </div>
    </div>

    <div class="filtros">
      <div class="filtro-group">
        <label class="form-label">Tipo:</label>
        <select v-model="filtroTipo" class="form-select" style="max-width: 200px;">
          <option value="">Todos</option>
          <option value="receber">A Receber</option>
          <option value="pagar">A Pagar</option>
        </select>
      </div>
      <div class="filtro-group">
        <label class="form-label">Status:</label>
        <select v-model="filtroStatus" class="form-select" style="max-width: 200px;">
          <option value="">Todos</option>
          <option value="pendente">Pendente</option>
          <option value="pago">Pago/Pago</option>
          <option value="vencido">Vencido</option>
        </select>
      </div>
      <div class="busca-produto-card" style="position: relative; max-width: 400px;">
        <div class="busca-produto">
          <input
            v-model="filtroBusca"
            type="text"
            class="form-input busca-input"
            placeholder="Buscar por descrição..."
            @input="filtrarContas"
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
        <div v-if="contasFiltradas.length > 0 && filtroBusca && contasFiltradas.length < contas.length" class="resultados-busca">
          <div class="resultado-info">
            {{ contasFiltradas.length }} conta(s) encontrada(s)
          </div>
        </div>
      </div>
    </div>

    <div class="card">
      <div v-if="carregando" class="text-center" style="padding: 2rem;">
        Carregando contas...
      </div>

      <div v-else-if="contasFiltradas.length === 0" class="text-center" style="padding: 2rem;">
        Nenhuma conta encontrada.
      </div>

      <table v-else class="tabela tabela-financeiro">
        <thead>
          <tr>
            <th class="text-center">Descrição</th>
            <th class="text-center">Tipo</th>
            <th class="text-center">Categoria</th>
            <th class="text-center">Valor</th>
            <th class="text-center">Vencimento</th>
            <th class="text-center">Status</th>
            <th class="text-center">Ações</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="conta in contasFiltradas" :key="conta.id" :class="{ 'linha-vencida': conta.status === 'vencido' }">
            <td>{{ conta.descricao }}</td>
            <td>
              <span :class="conta.tipo === 'receber' ? 'badge badge-sucesso' : 'badge badge-erro'">
                {{ conta.tipo === 'receber' ? 'A Receber' : 'A Pagar' }}
              </span>
            </td>
            <td>{{ conta.categoria || '-' }}</td>
            <td :class="conta.tipo === 'receber' ? 'valor-positivo' : 'valor-negativo'">
              {{ formatarMoeda(conta.valor) }}
            </td>
            <td>{{ formatarData(conta.data_vencimento) }}</td>
            <td>
              <span :class="getBadgeStatusClass(conta.status)">
                {{ getStatusText(conta.status) }}
              </span>
            </td>
            <td>
              <button
                v-if="conta.status === 'pendente'"
                class="btn btn-ghost"
                @click="marcarComoPago(conta)"
                style="margin-right: 0.5rem;"
              >
                Marcar como Pago
              </button>
              <button class="btn btn-ghost" @click="editarConta(conta)" style="margin-right: 0.5rem;">
                Editar
              </button>
              <button class="btn btn-perigo" @click="confirmarExclusao(conta)">
                Excluir
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal de Conta -->
    <ModalConta
      v-if="mostrarModalConta"
      :conta="contaSelecionada"
      @fechar="fecharModalConta"
      @salvar="salvarConta"
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
import { formatarMoeda, formatarData } from '@/utils/formatadores'
import ModalConta from './ModalConta.vue'
import ModalConfirmacao from '@/componentes/ModalConfirmacao.vue'

const contas = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroTipo = ref('')
const filtroStatus = ref('')
const filtroBusca = ref('')
const timeoutBusca = ref(null)
const mostrarModalConta = ref(false)
const contaSelecionada = ref(null)
const mostrarModalConfirmacao = ref(false)
const tituloConfirmacao = ref('')
const mensagemConfirmacao = ref('')
const tipoConfirmacao = ref('danger')
const callbackConfirmacao = ref(null)
const itemParaExcluir = ref(null)

const contasFiltradas = computed(() => {
  let filtradas = contas.value

  if (filtroTipo.value) {
    filtradas = filtradas.filter(c => c.tipo === filtroTipo.value)
  }

  if (filtroStatus.value) {
    filtradas = filtradas.filter(c => c.status === filtroStatus.value)
  }

  if (filtroBusca.value) {
    const busca = filtroBusca.value.toLowerCase().trim()
    if (busca) {
      filtradas = filtradas.filter(c => 
        c.descricao.toLowerCase().includes(busca) ||
        (c.categoria && c.categoria.toLowerCase().includes(busca))
      )
    }
  }

  return filtradas
})

function filtrarContas() {
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

const totalReceber = computed(() => {
  return contas.value
    .filter(c => c.tipo === 'receber' && c.status === 'pendente')
    .reduce((sum, c) => sum + c.valor, 0)
})

const totalPagar = computed(() => {
  return contas.value
    .filter(c => c.tipo === 'pagar' && c.status === 'pendente')
    .reduce((sum, c) => sum + c.valor, 0)
})

const saldo = computed(() => {
  return totalReceber.value - totalPagar.value
})

async function carregarContas() {
  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('contas_financeiras')
      .select('*')
      .eq('usuario_id', user.id)
      .order('data_vencimento')

    if (error) throw error

    // Atualizar status de contas vencidas
    const hoje = new Date()
    hoje.setHours(0, 0, 0, 0)

    const contasAtualizadas = (data || []).map(conta => {
      if (conta.status === 'pendente') {
        const dataVencimento = new Date(conta.data_vencimento)
        dataVencimento.setHours(0, 0, 0, 0)

        if (dataVencimento < hoje) {
          return { ...conta, status: 'vencido' }
        }
      }
      return conta
    })

    contas.value = contasAtualizadas
  } catch (err) {
    erro.value = 'Erro ao carregar contas: ' + err.message
    console.error(err)
  } finally {
    carregando.value = false
  }
}

function abrirModalConta() {
  contaSelecionada.value = null
  mostrarModalConta.value = true
}

function editarConta(conta) {
  contaSelecionada.value = conta
  mostrarModalConta.value = true
}

function fecharModalConta() {
  mostrarModalConta.value = false
  contaSelecionada.value = null
}

async function salvarConta() {
  await carregarContas()
  window.dispatchEvent(new CustomEvent('conta-financeira-registrada', {
    detail: {
      origem: 'financeiro',
      tipo: contaSelecionada.value?.id ? 'atualizacao' : 'criacao'
    }
  }))
  fecharModalConta()
}

function confirmarExclusao(conta) {
  itemParaExcluir.value = conta
  mostrarConfirmacao(
    'Excluir Conta',
    'Deseja realmente excluir esta conta? Esta ação não pode ser desfeita.',
    'danger',
    () => excluirConta(itemParaExcluir.value.id)
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

async function excluirConta(id) {
  try {
    const { error } = await supabase
      .from('contas_financeiras')
      .delete()
      .eq('id', id)

    if (error) throw error
    await carregarContas()
    window.dispatchEvent(new CustomEvent('conta-financeira-registrada', {
      detail: {
        origem: 'financeiro',
        tipo: 'exclusao',
        conta_id: id
      }
    }))
  } catch (err) {
    erro.value = 'Erro ao excluir conta: ' + err.message
    console.error(err)
  }
}

async function marcarComoPago(conta) {
  try {
    const { error } = await supabase
      .from('contas_financeiras')
      .update({
        status: 'pago',
        data_pagamento: new Date().toISOString().split('T')[0]
      })
      .eq('id', conta.id)

    if (error) throw error
    await carregarContas()
  } catch (err) {
    erro.value = 'Erro ao marcar como pago: ' + err.message
    console.error(err)
  }
}

function getStatusText(status) {
  const mapa = {
    pendente: 'Pendente',
    pago: 'Pago',
    vencido: 'Vencido'
  }
  return mapa[status] || status
}

function getBadgeStatusClass(status) {
  const mapa = {
    pendente: 'badge badge-aviso',
    pago: 'badge badge-sucesso',
    vencido: 'badge badge-erro'
  }
  return mapa[status] || 'badge'
}

// Listener para recarregar quando uma venda é finalizada
function onVendaFinalizada(event) {
  if (event.detail?.atualizouFinanceiro) {
    carregarContas()
  }
}

// Listener para recarregar quando uma conta financeira é registrada
function onContaFinanceiraRegistrada() {
  carregarContas()
}

onMounted(() => {
  carregarContas()
  // Escutar eventos de venda finalizada
  window.addEventListener('venda-finalizada', onVendaFinalizada)
  // Escutar eventos de conta financeira registrada
  window.addEventListener('conta-financeira-registrada', onContaFinanceiraRegistrada)
})

onUnmounted(() => {
  window.removeEventListener('venda-finalizada', onVendaFinalizada)
  window.removeEventListener('conta-financeira-registrada', onContaFinanceiraRegistrada)
})
</script>

<style scoped>
.view-header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-bottom: 1rem;
}

.resumo-financeiro {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.card-resumo {
  text-align: center;
  padding: 1.25rem;
}

.card-resumo h3 {
  font-size: 0.875rem;
  color: #6b7280;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.card-resumo p {
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0;
}

.filtros {
  display: flex;
  gap: 0.75rem;
  align-items: flex-end;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.filtro-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.valor-positivo {
  color: #059669;
  font-weight: 600;
}

.valor-negativo {
  color: #dc2626;
  font-weight: 600;
}

.linha-vencida {
  background-color: #fee2e2;
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

.tabela-financeiro th,
.tabela-financeiro td {
  text-align: center;
}

.text-center {
  text-align: center;
}

@media (max-width: 768px) {
  .resumo-financeiro {
    grid-template-columns: 1fr;
  }

  .filtros {
    flex-direction: column;
    align-items: stretch;
  }

  .filtro-group {
    width: 100%;
  }

  .filtro-group .form-select,
  .filtros .form-input {
    max-width: 100% !important;
  }
}
</style>
