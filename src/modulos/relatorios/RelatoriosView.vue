<template>
  <div class="space-y-6">
    <!-- Header com Seleção de Categoria -->
    <div class="card">
      <div class="card-body p-6">
        <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
          <div>
            <h2 class="text-2xl font-bold text-gray-900 mb-1">Relatórios</h2>
            <p class="text-sm text-gray-600">Análises detalhadas por categoria</p>
          </div>
          
          <!-- Dropdown de Categoria -->
          <div class="flex-1 max-w-xs">
            <label class="form-label text-xs">Selecione uma Categoria</label>
            <select
              v-model="categoriaSelecionada"
              class="form-input text-sm"
            >
              <option value="">-- Selecione --</option>
              <option value="estoque">Estoque</option>
              <option value="caixa">Caixa</option>
              <option value="clientes">Clientes</option>
              <option value="financeiro">Financeiro</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <!-- Estado Inicial - Nenhuma Categoria Selecionada -->
    <div v-if="!categoriaSelecionada" class="card">
      <div class="card-body">
        <div class="flex flex-col items-center justify-center py-16 text-center">
          <DocumentChartBarIcon class="h-16 w-16 text-gray-300 mb-4" />
          <h3 class="text-xl font-semibold text-gray-900 mb-2">Selecione uma Categoria</h3>
          <p class="text-sm text-gray-600 max-w-md">
            Para visualizar os relatórios, por favor selecione uma categoria no menu acima.
            Você pode escolher entre Estoque, Caixa, Clientes ou Financeiro.
          </p>
        </div>
      </div>
    </div>
    <!-- Categoria Selecionada - Filtros de Período e Cards de Resumo -->
    <div v-if="categoriaSelecionada" class="card">
      <div class="card-body p-4">
        <!-- Filtros de Data -->
        <div class="flex flex-wrap items-end gap-3 mb-4">
          <div class="flex-1 min-w-[140px]">
            <label class="form-label text-xs">Data Inicial</label>
            <input
              v-model="dataInicial"
              type="date"
              class="form-input text-sm"
              @change="carregarRelatorios"
            />
          </div>
          <div class="flex-1 min-w-[140px]">
            <label class="form-label text-xs">Data Final</label>
            <input
              v-model="dataFinal"
              type="date"
              class="form-input text-sm"
              @change="carregarRelatorios"
            />
          </div>
          <button
            @click="resetarFiltros"
            class="btn btn-ghost px-4 py-2 text-sm whitespace-nowrap"
          >
            Limpar
          </button>
        </div>

        <!-- Cards de Resumo por Categoria -->
        <div v-if="!carregando">
          <!-- ESTOQUE -->
          <div v-if="categoriaSelecionada === 'estoque'" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Produtos em Estoque</p>
                  <p class="text-2xl font-bold text-gray-900">{{ resumoEstoque.totalProdutos }}</p>
                </div>
                <div class="p-3 bg-blue-50 rounded-lg">
                  <CubeIcon class="h-6 w-6 text-blue-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Valor Total do Estoque</p>
                  <p class="text-2xl font-bold text-gray-900">{{ formatarMoeda(resumoEstoque.valorTotal) }}</p>
                </div>
                <div class="p-3 bg-green-50 rounded-lg">
                  <CurrencyDollarIcon class="h-6 w-6 text-green-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Produtos com Estoque Baixo</p>
                  <p class="text-2xl font-bold" :class="resumoEstoque.estoqueBaixo > 0 ? 'text-red-600' : 'text-gray-900'">
                    {{ resumoEstoque.estoqueBaixo }}
                  </p>
                </div>
                <div class="p-3 bg-red-50 rounded-lg">
                  <ExclamationTriangleIcon class="h-6 w-6 text-red-600" />
                </div>
              </div>
            </div>
          </div>

          <!-- CAIXA -->
          <div v-if="categoriaSelecionada === 'caixa'" class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Caixas Fechados</p>
                  <p class="text-2xl font-bold text-gray-900">{{ resumoCaixa.quantidadeCaixas }}</p>
                </div>
                <div class="p-3 bg-gray-50 rounded-lg">
                  <CreditCardIcon class="h-6 w-6 text-gray-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Total em Dinheiro</p>
                  <p class="text-2xl font-bold text-green-600">{{ formatarMoeda(resumoCaixa.totalDinheiro) }}</p>
                </div>
                <div class="p-3 bg-green-50 rounded-lg">
                  <BanknotesIcon class="h-6 w-6 text-green-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Total em Cartão</p>
                  <p class="text-2xl font-bold text-blue-600">{{ formatarMoeda(resumoCaixa.totalCartao) }}</p>
                </div>
                <div class="p-3 bg-blue-50 rounded-lg">
                  <CreditCardIcon class="h-6 w-6 text-blue-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Diferença Total</p>
                  <p class="text-2xl font-bold" :class="resumoCaixa.diferencaTotal >= 0 ? 'text-green-600' : 'text-red-600'">
                    {{ formatarMoeda(resumoCaixa.diferencaTotal) }}
                  </p>
                </div>
                <div class="p-3 rounded-lg" :class="resumoCaixa.diferencaTotal >= 0 ? 'bg-green-50' : 'bg-red-50'">
                  <ChartBarIcon class="h-6 w-6" :class="resumoCaixa.diferencaTotal >= 0 ? 'text-green-600' : 'text-red-600'" />
                </div>
              </div>
            </div>
          </div>

          <!-- CLIENTES -->
          <div v-if="categoriaSelecionada === 'clientes'" class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Clientes Ativos</p>
                  <p class="text-2xl font-bold text-gray-900">{{ resumoGeral.clientesAtivos }}</p>
                  <p class="text-xs text-gray-500 mt-1">no período</p>
                </div>
                <div class="p-3 bg-purple-50 rounded-lg">
                  <UserGroupIcon class="h-6 w-6 text-purple-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Ticket Médio</p>
                  <p class="text-2xl font-bold text-gray-900">{{ formatarMoeda(resumoGeral.ticketMedio) }}</p>
                  <p class="text-xs text-gray-500 mt-1">por venda</p>
                </div>
                <div class="p-3 bg-blue-50 rounded-lg">
                  <ChartBarIcon class="h-6 w-6 text-blue-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Total de Vendas</p>
                  <p class="text-2xl font-bold text-gray-900">{{ formatarMoeda(resumoGeral.totalVendas) }}</p>
                  <p class="text-xs text-gray-500 mt-1">{{ resumoGeral.quantidadeVendas }} vendas</p>
                </div>
                <div class="p-3 bg-green-50 rounded-lg">
                  <CurrencyDollarIcon class="h-6 w-6 text-green-600" />
                </div>
              </div>
            </div>
          </div>

          <!-- FINANCEIRO -->
          <div v-if="categoriaSelecionada === 'financeiro'" class="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Total a Receber</p>
                  <p class="text-2xl font-bold text-green-600">{{ formatarMoeda(resumoFinanceiro.totalReceber) }}</p>
                </div>
                <div class="p-3 bg-green-50 rounded-lg">
                  <ArrowDownCircleIcon class="h-6 w-6 text-green-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Total a Pagar</p>
                  <p class="text-2xl font-bold text-red-600">{{ formatarMoeda(resumoFinanceiro.totalPagar) }}</p>
                </div>
                <div class="p-3 bg-red-50 rounded-lg">
                  <ArrowUpCircleIcon class="h-6 w-6 text-red-600" />
                </div>
              </div>
            </div>

            <div class="summary-card">
              <div class="flex items-center justify-between">
                <div>
                  <p class="text-sm font-medium text-gray-600 mb-1">Saldo</p>
                  <p class="text-2xl font-bold" :class="resumoFinanceiro.saldo >= 0 ? 'text-green-600' : 'text-red-600'">
                    {{ formatarMoeda(resumoFinanceiro.saldo) }}
                  </p>
                </div>
                <div class="p-3 rounded-lg" :class="resumoFinanceiro.saldo >= 0 ? 'bg-green-50' : 'bg-red-50'">
                  <ChartBarIcon class="h-6 w-6" :class="resumoFinanceiro.saldo >= 0 ? 'text-green-600' : 'text-red-600'" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="categoriaSelecionada && carregando" class="card">
      <div class="card-body">
        <div class="flex items-center justify-center py-12">
          <div class="text-center">
            <div class="spinner mx-auto mb-4"></div>
            <p class="text-sm text-gray-500">Carregando relatórios...</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Conteúdo por Categoria -->
    <div v-else-if="categoriaSelecionada">
      <!-- ESTOQUE -->
      <div v-if="categoriaSelecionada === 'estoque'" class="space-y-6">
        <!-- Estoque Baixo -->
        <div class="card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Produtos com Estoque Baixo</h3>
          </div>
          <div class="card-body">
            <div v-if="estoqueBaixo.length === 0" class="text-center py-8">
              <CheckCircleIcon class="h-12 w-12 text-green-500 mx-auto mb-3" />
              <p class="text-sm text-gray-600">Nenhum produto com estoque baixo</p>
            </div>
            <div v-else class="overflow-x-auto">
              <table class="tabela-estoque min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Produto</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Quantidade</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Mínimo</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="produto in estoqueBaixo" :key="produto.id" class="hover:bg-gray-50">
                    <td class="px-4 py-3 text-sm text-gray-900">{{ produto.nome }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</td>
                    <td class="px-4 py-3 text-sm text-gray-600">{{ produto.estoque_minimo || 0 }} {{ produto.unidade || 'un' }}</td>
                    <td class="px-4 py-3">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        Crítico
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Produtos Sem Movimentação -->
        <div class="card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Produtos Sem Movimentação (90 dias)</h3>
          </div>
          <div class="card-body">
            <div v-if="produtosParados.length === 0" class="text-center py-8">
              <CheckCircleIcon class="h-12 w-12 text-green-500 mx-auto mb-3" />
              <p class="text-sm text-gray-600">Todos os produtos tiveram movimentação</p>
            </div>
            <div v-else class="overflow-x-auto">
              <table class="tabela-estoque min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Produto</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Quantidade</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Valor Estoque</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="produto in produtosParados" :key="produto.id" class="hover:bg-gray-50">
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ produto.nome }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ produto.quantidade }} {{ produto.unidade || 'un' }}</td>
                    <td class="px-4 py-3 text-sm font-semibold text-gray-900 text-center">{{ formatarMoeda(produto.quantidade * produto.preco_custo) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- CAIXA -->
      <div v-if="categoriaSelecionada === 'caixa'" class="space-y-6">
        <!-- Fechamentos de Caixa -->
        <div class="card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Fechamentos de Caixa</h3>
          </div>
          <div class="card-body">
            <div v-if="fechamentosCaixa.length === 0" class="text-center py-8">
              <p class="text-sm text-gray-500">Nenhum fechamento no período</p>
            </div>
            <div v-else class="overflow-x-auto">
              <table class="tabela-caixa min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Data</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Valor Inicial</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Valor Final</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Diferença</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="caixa in fechamentosCaixa" :key="caixa.id" class="hover:bg-gray-50">
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ formatarData(caixa.data) }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ formatarMoeda(caixa.valor_inicial) }}</td>
                    <td class="px-4 py-3 text-sm font-semibold text-gray-900 text-center">{{ formatarMoeda(caixa.valor_final || 0) }}</td>
                    <td class="px-4 py-3 text-sm text-center">
                      <span :class="caixa.diferenca_caixa >= 0 ? 'font-semibold text-green-600' : 'font-semibold text-red-600'">
                        {{ formatarMoeda(caixa.diferenca_caixa || 0) }}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- CLIENTES -->
      <div v-if="categoriaSelecionada === 'clientes'" class="space-y-6">
        <!-- Clientes Mais Compradores -->
        <div class="card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Clientes Mais Compradores</h3>
          </div>
          <div class="card-body">
            <div v-if="clientesMaisCompradores.length === 0" class="text-center py-8">
              <p class="text-sm text-gray-500">Nenhuma compra registrada</p>
            </div>
            <div v-else class="overflow-x-auto">
              <table class="tabela-clientes min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">#</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Cliente</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Total de Compras</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Valor Total</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="(cliente, index) in clientesMaisCompradores" :key="cliente.cliente_id || 'sem-cliente'" class="hover:bg-gray-50">
                    <td class="px-4 py-3 text-sm font-medium text-gray-900 text-center">{{ index + 1 }}º</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ cliente.nome || 'Cliente Não Cadastrado' }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ cliente.quantidade }} compra(s)</td>
                    <td class="px-4 py-3 text-sm font-semibold text-gray-900 text-center">{{ formatarMoeda(cliente.total) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <!-- FINANCEIRO -->
      <div v-if="categoriaSelecionada === 'financeiro'" class="space-y-6">
        <!-- Contas Vencidas -->
        <div class="card">
          <div class="card-header">
            <h3 class="text-lg font-semibold text-gray-900">Contas Vencidas</h3>
          </div>
          <div class="card-body">
            <div v-if="contasVencidas.length === 0" class="text-center py-8">
              <CheckCircleIcon class="h-12 w-12 text-green-500 mx-auto mb-3" />
              <p class="text-sm text-gray-600">Nenhuma conta vencida</p>
            </div>
            <div v-else class="overflow-x-auto">
              <table class="tabela-financeiro min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Descrição</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Tipo</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Valor</th>
                    <th class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider text-center">Vencimento</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  <tr v-for="conta in contasVencidas" :key="conta.id" class="hover:bg-gray-50">
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ conta.descricao }}</td>
                    <td class="px-4 py-3 text-center">
                      <span :class="conta.tipo === 'receber' ? 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800' : 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800'">
                        {{ conta.tipo === 'receber' ? 'A Receber' : 'A Pagar' }}
                      </span>
                    </td>
                    <td class="px-4 py-3 text-sm font-semibold text-gray-900 text-center">{{ formatarMoeda(conta.valor) }}</td>
                    <td class="px-4 py-3 text-sm text-gray-900 text-center">{{ formatarData(conta.data_vencimento) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda, formatarData } from '@/utils/formatadores'
import {
  CubeIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  CreditCardIcon,
  ChartBarIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  BanknotesIcon,
  ArrowDownCircleIcon,
  ArrowUpCircleIcon,
  DocumentChartBarIcon,
} from '@heroicons/vue/24/outline'

const categoriaSelecionada = ref('')

// Datas
const hoje = new Date()
const dataInicial = ref(new Date(hoje.getFullYear(), hoje.getMonth(), 1).toISOString().split('T')[0])
const dataFinal = ref(hoje.toISOString().split('T')[0])

// Estados
const carregando = ref(false)

// Resumo Geral
const resumoGeral = ref({
  totalVendas: 0,
  quantidadeVendas: 0,
  totalProdutosVendidos: 0,
  ticketMedio: 0,
  clientesAtivos: 0
})

// Estoque
const resumoEstoque = ref({
  totalProdutos: 0,
  valorTotal: 0,
  estoqueBaixo: 0
})
const estoqueBaixo = ref([])
const produtosParados = ref([])

// Financeiro
const resumoFinanceiro = ref({
  totalReceber: 0,
  totalPagar: 0,
  saldo: 0
})
const contasVencidas = ref([])

// Caixa
const resumoCaixa = ref({
  quantidadeCaixas: 0,
  totalDinheiro: 0,
  totalCartao: 0,
  diferencaTotal: 0
})
const fechamentosCaixa = ref([])

// Clientes
const clientesMaisCompradores = ref([])

function resetarFiltros() {
  const hoje = new Date()
  dataInicial.value = new Date(hoje.getFullYear(), hoje.getMonth(), 1).toISOString().split('T')[0]
  dataFinal.value = hoje.toISOString().split('T')[0]
  carregarRelatorios()
}

async function carregarRelatorios() {
  if (!categoriaSelecionada.value) {
    return
  }

  carregando.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const dataInicio = new Date(dataInicial.value)
    dataInicio.setHours(0, 0, 0, 0)
    const dataFim = new Date(dataFinal.value)
    dataFim.setHours(23, 59, 59, 999)

    // Carregar dados baseado na categoria selecionada
    switch (categoriaSelecionada.value) {
      case 'estoque':
        await Promise.all([
          carregarResumoEstoque(user.id),
          carregarEstoqueBaixo(user.id),
          carregarProdutosParados(user.id)
        ])
        break
      case 'caixa':
        await Promise.all([
          carregarResumoCaixa(user.id, dataInicio, dataFim),
          carregarFechamentosCaixa(user.id, dataInicio, dataFim)
        ])
        break
      case 'clientes':
        await Promise.all([
          carregarResumoGeral(user.id, dataInicio, dataFim),
          carregarClientesMaisCompradores(user.id, dataInicio, dataFim)
        ])
        break
      case 'financeiro':
        await Promise.all([
          carregarResumoFinanceiro(user.id, dataInicio, dataFim),
          carregarContasVencidas(user.id)
        ])
        break
    }
  } catch (error) {
    console.error('Erro ao carregar relatórios:', error)
  } finally {
    carregando.value = false
  }
}

async function carregarResumoGeral(userId, dataInicio, dataFim) {
  // Carregar vendas diretamente da tabela
  const { data: vendas } = await supabase
    .from('vendas')
    .select('id, total, cliente_id')
    .eq('usuario_id', userId)
    .gte('created_at', dataInicio.toISOString())
    .lte('created_at', dataFim.toISOString())

  if (vendas) {
    resumoGeral.value.totalVendas = vendas.reduce((acc, v) => acc + (v.total || 0), 0)
    resumoGeral.value.quantidadeVendas = vendas.length
    resumoGeral.value.ticketMedio = vendas.length > 0 ? resumoGeral.value.totalVendas / vendas.length : 0

    const clientesUnicos = new Set(vendas.filter(v => v.cliente_id).map(v => v.cliente_id))
    resumoGeral.value.clientesAtivos = clientesUnicos.size

    // Calcular total de produtos vendidos diretamente dos itens_venda
    const { data: itensVenda } = await supabase
      .from('itens_venda')
      .select('quantidade')
      .in('venda_id', vendas.map(v => v.id))

    if (itensVenda) {
      resumoGeral.value.totalProdutosVendidos = itensVenda.reduce((acc, item) => acc + (item.quantidade || 0), 0)
    } else {
      resumoGeral.value.totalProdutosVendidos = 0
    }
  } else {
    resumoGeral.value.totalVendas = 0
    resumoGeral.value.quantidadeVendas = 0
    resumoGeral.value.ticketMedio = 0
    resumoGeral.value.clientesAtivos = 0
    resumoGeral.value.totalProdutosVendidos = 0
  }
}

async function carregarResumoEstoque(userId) {
  const { data: produtos } = await supabase
    .from('produtos')
    .select('*')
    .eq('usuario_id', userId)

  if (produtos) {
    resumoEstoque.value.totalProdutos = produtos.length
    resumoEstoque.value.valorTotal = produtos.reduce((acc, p) => acc + (p.quantidade * (p.preco_custo || 0)), 0)
    resumoEstoque.value.estoqueBaixo = produtos.filter(p => p.estoque_minimo && p.quantidade <= p.estoque_minimo).length
  }
}

async function carregarEstoqueBaixo(userId) {
  const { data: produtos } = await supabase
    .from('produtos')
    .select('*')
    .eq('usuario_id', userId)
    .order('nome')

  if (produtos) {
    estoqueBaixo.value = produtos
      .filter(p => p.estoque_minimo && p.quantidade <= p.estoque_minimo)
      .slice(0, 20)
  }
}

async function carregarProdutosParados(userId) {
  const dataLimite = new Date()
  dataLimite.setDate(dataLimite.getDate() - 90)

  const { data: movimentacoes } = await supabase
    .from('movimentacoes_estoque')
    .select('produto_id')
    .eq('usuario_id', userId)
    .gte('created_at', dataLimite.toISOString())

  const produtosComMovimentacao = new Set(
    movimentacoes?.map(m => m.produto_id) || []
  )

  const { data: produtos } = await supabase
    .from('produtos')
    .select('*')
    .eq('usuario_id', userId)
    .gt('quantidade', 0)

  if (produtos) {
    produtosParados.value = produtos
      .filter(p => !produtosComMovimentacao.has(p.id))
      .slice(0, 20)
  }
}

async function carregarResumoFinanceiro(userId, dataInicio, dataFim) {
  const { data: contas } = await supabase
    .from('contas_financeiras')
    .select('tipo, valor, status')
    .eq('usuario_id', userId)
    .lte('data_vencimento', dataFim.toISOString().split('T')[0])

  if (contas) {
    resumoFinanceiro.value.totalReceber = contas
      .filter(c => c.tipo === 'receber' && c.status === 'pendente')
      .reduce((acc, c) => acc + (c.valor || 0), 0)
    
    resumoFinanceiro.value.totalPagar = contas
      .filter(c => c.tipo === 'pagar' && c.status === 'pendente')
      .reduce((acc, c) => acc + (c.valor || 0), 0)
    
    resumoFinanceiro.value.saldo = resumoFinanceiro.value.totalReceber - resumoFinanceiro.value.totalPagar
  }
}

async function carregarContasVencidas(userId) {
  const hoje = new Date().toISOString().split('T')[0]
  
  const { data: contas } = await supabase
    .from('contas_financeiras')
    .select('*')
    .eq('usuario_id', userId)
    .eq('status', 'vencido')
    .lt('data_vencimento', hoje)
    .order('data_vencimento', { ascending: true })
    .limit(20)

  contasVencidas.value = contas || []
}

async function carregarResumoCaixa(userId, dataInicio, dataFim) {
  // Carregar caixas fechados diretamente da tabela
  const { data: caixas } = await supabase
    .from('caixas')
    .select('*')
    .eq('usuario_id', userId)
    .not('data_fechamento', 'is', null)
    .gte('data', dataInicio.toISOString().split('T')[0])
    .lte('data', dataFim.toISOString().split('T')[0])

  if (caixas) {
    resumoCaixa.value.quantidadeCaixas = caixas.length
    resumoCaixa.value.totalDinheiro = caixas.reduce((acc, c) => acc + (c.total_dinheiro || 0), 0)
    resumoCaixa.value.totalCartao = caixas.reduce((acc, c) => acc + (c.total_debito || 0) + (c.total_credito || 0), 0)
    resumoCaixa.value.diferencaTotal = caixas.reduce((acc, c) => acc + (c.diferenca_caixa || 0), 0)
  } else {
    resumoCaixa.value.quantidadeCaixas = 0
    resumoCaixa.value.totalDinheiro = 0
    resumoCaixa.value.totalCartao = 0
    resumoCaixa.value.diferencaTotal = 0
  }
}

async function carregarFechamentosCaixa(userId, dataInicio, dataFim) {
  const { data: caixas } = await supabase
    .from('caixas')
    .select('*')
    .eq('usuario_id', userId)
    .not('data_fechamento', 'is', null)
    .gte('data', dataInicio.toISOString().split('T')[0])
    .lte('data', dataFim.toISOString().split('T')[0])
    .order('data', { ascending: false })
    .limit(10)

  fechamentosCaixa.value = caixas || []
}

async function carregarClientesMaisCompradores(userId, dataInicio, dataFim) {
  const { data: vendas } = await supabase
    .from('vendas')
    .select('id, cliente_id, total, clientes(nome)')
    .eq('usuario_id', userId)
    .gte('created_at', dataInicio.toISOString())
    .lte('created_at', dataFim.toISOString())

  if (vendas) {
    const agrupados = {}
    vendas.forEach(venda => {
      const clienteId = venda.cliente_id || 'sem-cliente'
      const cliente = Array.isArray(venda.clientes) ? venda.clientes[0] : venda.clientes
      
      if (!agrupados[clienteId]) {
        agrupados[clienteId] = {
          cliente_id: clienteId,
          nome: cliente?.nome || null,
          quantidade: 0,
          total: 0
        }
      }
      agrupados[clienteId].quantidade += 1
      agrupados[clienteId].total += venda.total || 0
    })

    clientesMaisCompradores.value = Object.values(agrupados)
      .sort((a, b) => b.total - a.total)
      .slice(0, 10)
  }
}

// Observar mudanças na categoria selecionada
watch(categoriaSelecionada, () => {
  if (categoriaSelecionada.value) {
    carregarRelatorios()
  }
})

// Listener para recarregar quando uma venda é finalizada
function onVendaFinalizada() {
  carregarRelatorios()
}

// Listener para recarregar quando uma movimentação é registrada
function onMovimentacaoRegistrada() {
  // Recarregar apenas seções relevantes (Caixa e Financeiro)
  if (categoriaSelecionada.value === 'caixa' || categoriaSelecionada.value === 'financeiro') {
    carregarRelatorios()
  }
}

// Listener para recarregar quando uma movimentação de estoque é registrada
function onMovimentacaoEstoqueRegistrada() {
  // Recarregar apenas seção de Estoque
  if (categoriaSelecionada.value === 'estoque') {
    carregarRelatorios()
  }
}

// Listener para recarregar quando uma conta financeira é registrada
function onContaFinanceiraRegistrada() {
  // Recarregar apenas seção de Financeiro
  if (categoriaSelecionada.value === 'financeiro') {
    carregarRelatorios()
  }
}

onMounted(() => {
  // Não carregar automaticamente, esperar seleção de categoria
  // Escutar eventos de venda finalizada
  window.addEventListener('venda-finalizada', onVendaFinalizada)
  // Escutar eventos de movimentação registrada
  window.addEventListener('movimentacao-registrada', onMovimentacaoRegistrada)
  // Escutar eventos de movimentação de estoque
  window.addEventListener('movimentacao-estoque-registrada', onMovimentacaoEstoqueRegistrada)
  // Escutar eventos de conta financeira
  window.addEventListener('conta-financeira-registrada', onContaFinanceiraRegistrada)
})

onUnmounted(() => {
  window.removeEventListener('venda-finalizada', onVendaFinalizada)
  window.removeEventListener('movimentacao-registrada', onMovimentacaoRegistrada)
  window.removeEventListener('movimentacao-estoque-registrada', onMovimentacaoEstoqueRegistrada)
  window.removeEventListener('conta-financeira-registrada', onContaFinanceiraRegistrada)
})
</script>

<style scoped>
.tabela-estoque th,
.tabela-estoque td {
  text-align: center;
}

.tabela-caixa th,
.tabela-caixa td {
  text-align: center;
}

.tabela-clientes th,
.tabela-clientes td {
  text-align: center;
}

.tabela-financeiro th,
.tabela-financeiro td {
  text-align: center;
}

.summary-card {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 1rem;
  transition: all 0.2s ease;
}

.summary-card:hover {
  background: white;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}
</style>