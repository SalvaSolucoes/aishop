/**
 * Utilitários para manipulação de vendas
 */

/**
 * Calcula o número sequencial visual de uma venda baseado na ordem cronológica
 * @param {Array} vendas - Lista de vendas ordenadas por created_at (ascendente)
 * @param {String} vendaId - ID da venda para calcular o número
 * @returns {Number} - Número sequencial da venda (1, 2, 3...)
 */
export function calcularNumeroSequencial(vendas, vendaId) {
  const index = vendas.findIndex(v => v.id === vendaId)
  return index >= 0 ? index + 1 : null
}

/**
 * Adiciona numeração sequencial a uma lista de vendas
 * @param {Array} vendas - Lista de vendas (será ordenada por created_at)
 * @returns {Array} - Lista de vendas com campo numeroSequencial adicionado
 */
export function adicionarNumeracaoSequencial(vendas) {
  if (!vendas || vendas.length === 0) return []
  
  // Ordenar por data de criação (mais antiga primeiro)
  const vendasOrdenadas = [...vendas].sort((a, b) => 
    new Date(a.created_at) - new Date(b.created_at)
  )
  
  // Adicionar número sequencial
  return vendasOrdenadas.map((venda, index) => ({
    ...venda,
    numeroSequencial: index + 1
  }))
}

/**
 * Formata o número da venda para exibição
 * @param {Number} numeroSequencial - Número sequencial da venda
 * @returns {String} - Formato: #venda1, #venda2, etc.
 */
export function formatarNumeroVenda(numeroSequencial) {
  return numeroSequencial ? `#venda${numeroSequencial}` : ''
}
