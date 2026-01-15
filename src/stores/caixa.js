import { ref } from 'vue'
import { supabase } from '@/servicos/supabase'

// Reactive state
const caixaAberto = ref(false)
const caixaAtual = ref(null)
const carregando = ref(false)
const erro = ref('')

// Cache expiration time (5 minutes)
const CACHE_DURATION = 5 * 60 * 1000
let cacheTimestamp = 0
let cachedUserId = null

/**
 * Gets today's date in YYYY-MM-DD format
 */
function getDataHoje() {
  return new Date().toISOString().split('T')[0]
}

/**
 * Checks if cache is valid for current user and date
 */
function isCacheValid(userId) {
  const now = Date.now()
  const hoje = getDataHoje()
  const cachedDate = localStorage.getItem('caixa_data_cache')
  
  return (
    userId === cachedUserId &&
    cachedDate === hoje &&
    (now - cacheTimestamp) < CACHE_DURATION
  )
}

/**
 * Updates cache with current data
 */
function updateCache(userId, caixaData) {
  const hoje = getDataHoje()
  cacheTimestamp = Date.now()
  cachedUserId = userId
  
  localStorage.setItem('caixa_data_cache', hoje)
  localStorage.setItem('caixa_aberto', caixaData ? 'true' : 'false')
  if (caixaData) {
    localStorage.setItem('caixa_atual', JSON.stringify({
      id: caixaData.id,
      data: caixaData.data,
      valor_inicial: caixaData.valor_inicial,
      data_abertura: caixaData.data_abertura
    }))
  } else {
    localStorage.removeItem('caixa_atual')
  }
}

/**
 * Loads cash register state from cache
 */
function loadFromCache() {
  try {
    const aberto = localStorage.getItem('caixa_aberto') === 'true'
    const caixaStr = localStorage.getItem('caixa_atual')
    
    caixaAberto.value = aberto
    
    if (caixaStr && aberto) {
      caixaAtual.value = JSON.parse(caixaStr)
    } else {
      caixaAtual.value = null
    }
    
    return true
  } catch (err) {
    console.warn('Failed to load cash register from cache:', err)
    clearCache()
    return false
  }
}

/**
 * Clears cache
 */
function clearCache() {
  cacheTimestamp = 0
  cachedUserId = null
  localStorage.removeItem('caixa_data_cache')
  localStorage.removeItem('caixa_aberto')
  localStorage.removeItem('caixa_atual')
}

/**
 * Verifies if there's an open cash register for today
 */
export async function verificarCaixaAberto(forceRefresh = false) {
  carregando.value = true
  erro.value = ''
  
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      caixaAberto.value = false
      caixaAtual.value = null
      clearCache()
      return false
    }

    // Check cache first (unless forced refresh)
    if (!forceRefresh && isCacheValid(user.id) && loadFromCache()) {
      carregando.value = false
      return caixaAberto.value
    }

    // Query database
    const hoje = getDataHoje()
    const { data, error } = await supabase
      .from('caixas')
      .select('*')
      .eq('usuario_id', user.id)
      .eq('data', hoje)
      .is('data_fechamento', null)
      .limit(1)
      .single()

    if (error && error.code !== 'PGRST116') {
      throw error
    }

    const isOpen = !!data
    caixaAberto.value = isOpen
    caixaAtual.value = data || null
    
    // Update cache
    updateCache(user.id, data)
    
    return isOpen
  } catch (err) {
    erro.value = 'Erro ao verificar caixa: ' + err.message
    console.error(err)
    return false
  } finally {
    carregando.value = false
  }
}

/**
 * Opens a new cash register for today
 */
export async function abrirCaixa(valorInicial = 0) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    const hoje = getDataHoje()
    
    // Check if there's already an open cash register
    const jaEstaAberto = await verificarCaixaAberto(true)
    if (jaEstaAberto) {
      throw new Error('Já existe um caixa aberto para hoje')
    }

    const { data, error } = await supabase
      .from('caixas')
      .insert([{
        usuario_id: user.id,
        data: hoje,
        valor_inicial: valorInicial
      }])
      .select()
      .single()

    if (error) throw error

    // Update state and cache
    caixaAberto.value = true
    caixaAtual.value = data
    updateCache(user.id, data)
    
    return data
  } catch (err) {
    throw new Error('Erro ao abrir caixa: ' + err.message)
  }
}

/**
 * Closes the current cash register and transfers total to financial system
 */
export async function fecharCaixa(dadosFechamento) {
  try {
    if (!caixaAtual.value) {
      throw new Error('Nenhum caixa aberto para fechar')
    }

    // First, get all sales for this cash register to calculate total
    const { data: vendas } = await supabase
      .from('vendas')
      .select('total')
      .eq('caixa_id', caixaAtual.value.id)

    const totalVendas = vendas ? vendas.reduce((sum, venda) => sum + venda.total, 0) : 0
    
    // Calculate total entries (sales + other entries)
    const totalEntradas = totalVendas + (dadosFechamento.total_suprimento || 0)
    
    // Calculate total withdrawals
    const totalSaidas = dadosFechamento.total_sangria || 0
    
    // Calculate final value
    const valorFinal = caixaAtual.value.valor_inicial + totalEntradas - totalSaidas
    
    // Update cash register with all calculated values
    const { error } = await supabase
      .from('caixas')
      .update({
        data_fechamento: new Date().toISOString(),
        valor_final: valorFinal,
        saldo_real: dadosFechamento.saldo_real,
        diferenca_caixa: dadosFechamento.diferenca_caixa,
        total_dinheiro: dadosFechamento.total_dinheiro,
        total_debito: dadosFechamento.total_debito,
        total_credito: dadosFechamento.total_credito,
        total_pix: dadosFechamento.total_pix,
        total_vale: dadosFechamento.total_vale,
        total_sangria: dadosFechamento.total_sangria,
        total_suprimento: dadosFechamento.total_suprimento,
        motivo_fechamento: dadosFechamento.motivo_fechamento,
        observacoes: dadosFechamento.observacoes
      })
      .eq('id', caixaAtual.value.id)

    if (error) throw error

    // Transfer total collected amount to financial system (only once per day)
    await transferirParaFinanceiro(caixaAtual.value, totalVendas)

    // Update state and clear cache
    caixaAberto.value = false
    caixaAtual.value = null
    clearCache()
    
    return true
  } catch (err) {
    throw new Error('Erro ao fechar caixa: ' + err.message)
  }
}

/**
 * Gets the current cash register ID
 */
export function getCaixaId() {
  return caixaAtual.value?.id || null
}

/**
 * Gets the current cash register data
 */
export function getCaixaAtual() {
  return caixaAtual.value
}

/**
 * Forces refresh of cash register state
 */
export async function refreshCaixaState() {
  return await verificarCaixaAberto(true)
}

/**
 * Initializes cash register state on app startup
 */
export async function initCaixaState() {
  await verificarCaixaAberto()
}

// Export reactive refs for composition API usage
export { caixaAberto, caixaAtual, carregando, erro }

/**
 * Transfers total collected amount to financial system (only once per day)
 */
async function transferirParaFinanceiro(caixa, totalVendas) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Check if financial transfer was already made for this day
    const { data: transferencias } = await supabase
      .from('contas_financeiras')
      .select('id')
      .eq('usuario_id', user.id)
      .eq('categoria', 'Vendas Diárias')
      .eq('descricao', `Total vendas dia ${caixa.data}`)

    // If already transferred, don't do it again
    if (transferencias && transferencias.length > 0) {
      console.log('Transferência financeira já realizada para este dia')
      return
    }

    // Create financial entry for daily sales total
    if (totalVendas > 0) {
      const { error: errorConta } = await supabase
        .from('contas_financeiras')
        .insert([{
          usuario_id: user.id,
          tipo: 'receber',
          descricao: `Total vendas dia ${caixa.data}`,
          valor: totalVendas,
          data_vencimento: caixa.data,
          status: 'pendente',
          categoria: 'Vendas Diárias',
          observacoes: `Transferido automaticamente do caixa do dia ${caixa.data}`
        }])

      if (errorConta) {
        console.error('Erro ao transferir para financeiro:', errorConta)
      } else {
        console.log(`Transferido R$ ${totalVendas.toFixed(2)} para o financeiro`)
      }
    }
  } catch (err) {
    console.error('Erro ao transferir para financeiro:', err)
  }
}