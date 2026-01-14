/**
 * Formata um valor numérico como moeda brasileira
 * @param {number} valor - Valor a ser formatado
 * @returns {string} Valor formatado como R$ X.XXX,XX
 */
export function formatarMoeda(valor) {
  if (valor === null || valor === undefined) {
    return 'R$ 0,00'
  }

  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(valor)
}

/**
 * Formata uma data para o formato brasileiro
 * @param {string|Date} data - Data a ser formatada
 * @returns {string} Data formatada como DD/MM/AAAA
 */
export function formatarData(data) {
  if (!data) return ''

  const dataObj = typeof data === 'string' ? new Date(data) : data
  
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  }).format(dataObj)
}

/**
 * Formata data e hora para o formato brasileiro
 * @param {string|Date} dataHora - Data e hora a serem formatadas
 * @returns {string} Data e hora formatadas como DD/MM/AAAA HH:MM
 */
export function formatarDataHora(dataHora) {
  if (!dataHora) return ''

  const dataObj = typeof dataHora === 'string' ? new Date(dataHora) : dataHora
  
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  }).format(dataObj)
}
