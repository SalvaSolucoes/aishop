<template>
  <div class="estoque-view">
    <div class="view-header">
      <button class="btn btn-primario" @click="abrirModalProduto">
        + Adicionar Produto
      </button>
    </div>

    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <div v-if="alertaEstoqueBaixo.length > 0" class="alert alert-aviso">
      <strong>Atenção!</strong> {{ alertaEstoqueBaixo.length }} produto(s) com estoque baixo.
      <ul style="margin-top: 0.5rem; margin-left: 1.5rem;">
        <li v-for="produto in alertaEstoqueBaixo" :key="produto.id">
          {{ produto.nome }} - Estoque: {{ produto.quantidade }}
        </li>
      </ul>
    </div>

    <div class="filtros">
      <div class="busca-produto-card" style="position: relative; max-width: 400px;">
        <div class="busca-produto">
          <input
            v-model="filtroBusca"
            type="text"
            class="form-input busca-input"
            placeholder="Buscar produtos por nome ou código..."
            @input="filtrarProdutos"
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
        <div v-if="produtosFiltrados.length > 0 && filtroBusca && produtosFiltrados.length < produtos.length" class="resultados-busca">
          <div class="resultado-info">
            {{ produtosFiltrados.length }} produto(s) encontrado(s)
          </div>
        </div>
      </div>
    </div>

    <!-- Seção de Relatórios -->
    <div v-if="mostrarRelatorios" class="relatorios-section">
      <div class="relatorios-grid">
        <div class="card relatorio-card">
          <h4>Produtos Mais Vendidos</h4>
          <div v-if="carregandoRelatorios" class="text-center" style="padding: 1rem;">
            Carregando...
          </div>
          <div v-else-if="produtosMaisVendidos.length === 0" class="text-center" style="padding: 1rem; color: #6b7280;">
            Nenhuma venda registrada
          </div>
          <ul v-else class="lista-relatorio">
            <li v-for="(item, index) in produtosMaisVendidos" :key="item.produto_id" class="item-relatorio">
              <span class="posicao">{{ index + 1 }}º</span>
              <span class="nome">{{ item.nome }}</span>
              <span class="quantidade">{{ item.total_vendido }} {{ item.unidade || 'un' }}</span>
            </li>
          </ul>
        </div>

        <div class="card relatorio-card">
          <h4>Produtos Parados</h4>
          <div v-if="carregandoRelatorios" class="text-center" style="padding: 1rem;">
            Carregando...
          </div>
          <div v-else-if="produtosParados.length === 0" class="text-center" style="padding: 1rem; color: #10b981;">
            Todos os produtos tiveram movimentação
          </div>
          <ul v-else class="lista-relatorio">
            <li v-for="produto in produtosParados" :key="produto.id" class="item-relatorio">
              <span class="nome">{{ produto.nome }}</span>
              <span class="quantidade">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</span>
            </li>
          </ul>
        </div>

        <div class="card relatorio-card">
          <h4>Estoque Baixo</h4>
          <div v-if="carregandoRelatorios" class="text-center" style="padding: 1rem;">
            Carregando...
          </div>
          <div v-else-if="alertaEstoqueBaixo.length === 0" class="text-center" style="padding: 1rem; color: #10b981;">
            Nenhum produto com estoque baixo
          </div>
          <ul v-else class="lista-relatorio">
            <li v-for="produto in alertaEstoqueBaixo" :key="produto.id" class="item-relatorio alerta">
              <span class="nome">{{ produto.nome }}</span>
              <span class="quantidade">
                {{ produto.quantidade }} / {{ produto.estoque_minimo || 0 }} {{ produto.unidade || 'un' }}
              </span>
            </li>
          </ul>
        </div>
      </div>
    </div>

    <div class="card">
      <div v-if="carregando" class="text-center" style="padding: 2rem;">
        Carregando produtos...
      </div>

      <div v-else-if="produtosFiltrados.length === 0" class="text-center" style="padding: 2rem;">
        Nenhum produto encontrado.
      </div>

      <div v-else class="overflow-x-auto -mx-3 sm:mx-0">
        <table class="tabela tabela-estoque">
          <thead>
            <tr>
              <th>Código</th>
              <th>Nome</th>
              <th>Quantidade</th>
              <th>Preço Unitário</th>
              <th>Valor Total</th>
              <th>Status</th>
              <th>Ações</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="produto in produtosFiltrados" :key="produto.id">
              <td>{{ produto.codigo || '-' }}</td>
              <td>{{ produto.nome }}</td>
              <td>{{ produto.quantidade }}</td>
              <td>{{ formatarMoeda(produto.preco_unitario) }}</td>
              <td>{{ formatarMoeda(produto.preco_unitario * produto.quantidade) }}</td>
              <td>
                <span :class="getBadgeClass(produto.quantidade, produto.estoque_minimo)">
                  {{ getStatusEstoque(produto.quantidade, produto.estoque_minimo) }}
                </span>
              </td>
              <td>
                <div class="flex flex-col sm:flex-row gap-2">
                  <button class="btn btn-ghost btn-sm" @click="editarProduto(produto)">
                    Editar
                  </button>
                  <button class="btn btn-ghost btn-sm" @click="registrarMovimentacao(produto)">
                    Movimentar
                  </button>
                  <button class="btn btn-perigo btn-sm" @click="confirmarExclusao(produto)">
                    Excluir
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal de Produto -->
    <ModalProduto
      v-if="mostrarModalProduto"
      :produto="produtoSelecionado"
      @fechar="fecharModalProduto"
      @salvar="salvarProduto"
    />

    <!-- Modal de Movimentação -->
    <ModalMovimentacao
      v-if="mostrarModalMovimentacao"
      :produto="produtoSelecionado"
      @fechar="fecharModalMovimentacao"
      @salvar="salvarMovimentacao"
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
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import ModalProduto from './ModalProduto.vue'
import ModalMovimentacao from './ModalMovimentacao.vue'
import ModalConfirmacao from '@/componentes/ModalConfirmacao.vue'

const produtos = ref([])
const carregando = ref(false)
const erro = ref('')
const filtroBusca = ref('')
const timeoutBusca = ref(null)
const mostrarModalProduto = ref(false)
const mostrarModalMovimentacao = ref(false)
const produtoSelecionado = ref(null)
const mostrarModalConfirmacao = ref(false)
const tituloConfirmacao = ref('')
const mensagemConfirmacao = ref('')
const tipoConfirmacao = ref('danger')
const callbackConfirmacao = ref(null)
const itemParaExcluir = ref(null)
const mostrarRelatorios = ref(false)
const carregandoRelatorios = ref(false)
const produtosMaisVendidos = ref([])
const produtosParados = ref([])

const produtosFiltrados = computed(() => {
  if (!filtroBusca.value) return produtos.value

  const busca = filtroBusca.value.toLowerCase().trim()
  if (!busca) return produtos.value

  return produtos.value.filter(p =>
    p.nome.toLowerCase().includes(busca) ||
    (p.codigo && p.codigo.toLowerCase().includes(busca)) ||
    (p.codigo_barras && p.codigo_barras.toLowerCase().includes(busca))
  )
})

function filtrarProdutos() {
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

const alertaEstoqueBaixo = computed(() => {
  return produtos.value.filter(p => p.quantidade <= (p.estoque_minimo || 0))
})

function abrirModalProduto() {
  produtoSelecionado.value = null
  mostrarModalProduto.value = true
}

function editarProduto(produto) {
  produtoSelecionado.value = produto
  mostrarModalProduto.value = true
}

function fecharModalProduto() {
  mostrarModalProduto.value = false
  produtoSelecionado.value = null
}

function registrarMovimentacao(produto) {
  produtoSelecionado.value = produto
  mostrarModalMovimentacao.value = true
}

function fecharModalMovimentacao() {
  mostrarModalMovimentacao.value = false
  produtoSelecionado.value = null
}

async function salvarProduto() {
  await carregarProdutos()
  fecharModalProduto()
}

async function salvarMovimentacao() {
  await carregarProdutos()
  fecharModalMovimentacao()
}

function confirmarExclusao(produto) {
  itemParaExcluir.value = produto
  mostrarConfirmacao(
    'Excluir Produto',
    `Deseja realmente excluir o produto "${produto.nome}"? Esta ação não pode ser desfeita.`,
    'danger',
    () => excluirProduto(itemParaExcluir.value.id)
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

async function excluirProduto(id) {
  try {
    const { error } = await supabase
      .from('produtos')
      .delete()
      .eq('id', id)

    if (error) throw error
    await carregarProdutos()
  } catch (err) {
    erro.value = 'Erro ao excluir produto: ' + err.message
    console.error(err)
  }
}

function getStatusEstoque(quantidade, estoqueMinimo) {
  if (quantidade === 0) return 'Sem Estoque'
  if (estoqueMinimo && quantidade <= estoqueMinimo) return 'Estoque Baixo'
  return 'Normal'
}

function getBadgeClass(quantidade, estoqueMinimo) {
  if (quantidade === 0) return 'badge badge-erro'
  if (estoqueMinimo && quantidade <= estoqueMinimo) return 'badge badge-aviso'
  return 'badge badge-sucesso'
}

async function carregarRelatorios() {
  if (!mostrarRelatorios.value) return

  carregandoRelatorios.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Produtos mais vendidos
    const { data: vendas, error: errorVendas } = await supabase
      .from('itens_venda')
      .select(`
        produto_id,
        quantidade,
        produtos!inner(nome, unidade)
      `)
      .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()) // Últimos 30 dias

    if (!errorVendas && vendas) {
      const vendasPorProduto = {}
      vendas.forEach(item => {
        const produtoId = item.produto_id
        const produto = Array.isArray(item.produtos) ? item.produtos[0] : item.produtos
        if (!vendasPorProduto[produtoId]) {
          vendasPorProduto[produtoId] = {
            produto_id: produtoId,
            nome: produto?.nome || 'Produto não encontrado',
            unidade: produto?.unidade || 'un',
            total_vendido: 0
          }
        }
        vendasPorProduto[produtoId].total_vendido += item.quantidade
      })

      produtosMaisVendidos.value = Object.values(vendasPorProduto)
        .sort((a, b) => b.total_vendido - a.total_vendido)
        .slice(0, 10)
    }

    // Produtos parados (sem movimentação nos últimos 90 dias)
    const dataLimite = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000)
    const { data: movimentacoes, error: errorMov } = await supabase
      .from('movimentacoes_estoque')
      .select('produto_id')
      .gte('created_at', dataLimite.toISOString())

    if (!errorMov) {
      const produtosComMovimentacao = new Set(
        (movimentacoes || []).map(m => m.produto_id)
      )

      produtosParados.value = produtos.value
        .filter(p => !produtosComMovimentacao.has(p.id) && p.quantidade > 0)
        .slice(0, 10)
    }
  } catch (err) {
    console.error('Erro ao carregar relatórios:', err)
  } finally {
    carregandoRelatorios.value = false
  }
}

async function carregarProdutos() {
  carregando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const { data, error } = await supabase
      .from('produtos')
      .select('*')
      .eq('usuario_id', user.id)
      .order('nome')

    if (error) throw error
    produtos.value = data || []

    // Carregar relatórios se estiverem visíveis
    if (mostrarRelatorios.value) {
      await carregarRelatorios()
    }
  } catch (err) {
    erro.value = 'Erro ao carregar produtos: ' + err.message
    console.error(err)
  } finally {
    carregando.value = false
  }
}

// Watch para carregar relatórios quando mostrarRelatorios mudar
watch(mostrarRelatorios, (novoValor) => {
  if (novoValor) {
    carregarRelatorios()
  }
})

// Listener para recarregar quando uma venda é finalizada
function onVendaFinalizada(event) {
  if (event.detail?.atualizouEstoque) {
    carregarProdutos()
    if (mostrarRelatorios.value) {
      carregarRelatorios()
    }
  }
}

// Listener para recarregar quando uma movimentação de estoque é registrada
function onMovimentacaoEstoqueRegistrada() {
  carregarProdutos()
  if (mostrarRelatorios.value) {
    carregarRelatorios()
  }
}

onMounted(() => {
  carregarProdutos()
  // Escutar eventos de venda finalizada
  window.addEventListener('venda-finalizada', onVendaFinalizada)
  // Escutar eventos de movimentação de estoque
  window.addEventListener('movimentacao-estoque-registrada', onMovimentacaoEstoqueRegistrada)
})

onUnmounted(() => {
  window.removeEventListener('venda-finalizada', onVendaFinalizada)
  window.removeEventListener('movimentacao-estoque-registrada', onMovimentacaoEstoqueRegistrada)
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
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  gap: 0.75rem;
  flex-wrap: wrap;
}

.botoes-relatorios {
  display: flex;
  gap: 0.5rem;
}

.relatorios-section {
  margin-bottom: 1.5rem;
}

.relatorios-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
}

.relatorio-card {
  padding: 1.25rem;
}

.relatorio-card h4 {
  font-size: 1rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.75rem 0;
  padding-bottom: 0.625rem;
  border-bottom: 1px solid #e5e7eb;
}

.lista-relatorio {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.item-relatorio {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.625rem;
  background: #f9fafb;
  border-radius: 0.375rem;
  transition: background-color 0.2s;
}

.item-relatorio:hover {
  background: #f3f4f6;
}

.item-relatorio.alerta {
  background: #fef2f2;
  border-left: 2px solid #ef4444;
}

.posicao {
  font-weight: 700;
  color: #0ea5e9;
  min-width: 30px;
  text-align: center;
}

.nome {
  flex: 1;
  font-weight: 500;
  color: #111827;
}

.quantidade {
  font-weight: 600;
  color: #059669;
  font-size: 0.875rem;
}

.text-center {
  text-align: center;
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

.tabela-estoque th,
.tabela-estoque td {
  text-align: center;
}

.tabela-estoque td:last-child {
  text-align: center;
}
</style>
