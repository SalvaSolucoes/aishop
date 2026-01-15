<template>
  <div class="cupom-fiscal" ref="cupomRef">
    <!-- Cabeçalho Empresa (Padrão ECF-SC) -->
    <div class="cupom-header">
      <h2>{{ empresaNome }}</h2>
      <p class="cupom-cnpj">CNPJ: {{ empresaCNPJ }}</p>
      <p class="cupom-ie">IE: {{ empresaIE }}</p>
      <p class="cupom-endereco">{{ empresaEndereco }}</p>
      <p class="cupom-cidade">{{ empresaCidade }}</p>
      <p class="cupom-contato">Tel: {{ empresaTelefone }}</p>
    </div>

    <div class="cupom-divider-thick"></div>

    <!-- Identificação do Cupom (ECF-SC) -->
    <div class="cupom-info">
      <div class="info-linha cupom-tipo">
        <span>CUPOM FISCAL NÃO-FISCAL</span>
      </div>
      <div class="info-linha">
        <span>COO: {{ venda.numero_venda || '000000' }}</span>
      </div>
      <div class="info-linha">
        <span>{{ formatarDataHoraBR(venda.created_at) }}</span>
      </div>
      <div v-if="cliente" class="info-linha">
        <span>CONSUMIDOR</span>
      </div>
      <div v-if="cliente" class="info-linha cliente-info">
        <span>{{ cliente.nome }}</span>
      </div>
      <div v-if="cliente && cliente.documento" class="info-linha">
        <span>{{ formatarDocumento(cliente.documento) }}</span>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <!-- Itens (Formato ECF-SC) -->
    <div class="cupom-itens">
      <div class="itens-header-ecf">
        <span>ITEM CODIGO DESCRICAO QTD UN VL UNIT(R$) VL ITEM(R$)</span>
      </div>
      <div
        v-for="(item, index) in itens"
        :key="index"
        class="item-linha-ecf"
      >
        <div class="item-linha-principal">
          <span class="item-numero">{{ String(index + 1).padStart(3, '0') }}</span>
          <span class="item-codigo">{{ getProdutoCodigo(item) }}</span>
          <span class="item-descricao">{{ getProdutoNome(item) }}</span>
        </div>
        <div class="item-linha-valores">
          <span class="item-qtd">{{ formatarQuantidade(item.quantidade) }}</span>
          <span class="item-un">{{ getProdutoUnidade(item) || 'UN' }}</span>
          <span class="item-vlunit">{{ formatarValorECF(item.preco_unitario) }}</span>
          <span class="item-vltotal">{{ formatarValorECF(item.subtotal) }}</span>
        </div>
        <div v-if="item.desconto > 0" class="item-desconto-ecf">
          DESCONTO: {{ formatarValorECF(item.desconto) }}
        </div>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <!-- Totais (Formato ECF-SC) -->
    <div class="cupom-totais-ecf">
      <div class="total-linha-ecf">
        <span>TOTAL R$</span>
        <span class="total-valor-ecf">{{ formatarValorECF(venda.total) }}</span>
      </div>
      <div v-if="venda.desconto > 0" class="total-linha-ecf desconto-linha">
        <span>Desconto R$</span>
        <span>{{ formatarValorECF(venda.desconto) }}</span>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <!-- Forma de Pagamento (ECF-SC) -->
    <div class="cupom-pagamento-ecf">
      <div class="pagamento-titulo">
        <span>FORMA DE PAGAMENTO</span>
      </div>
      <div class="pagamento-linha-ecf">
        <span>{{ formatarFormaPagamento(venda.forma_pagamento) }}</span>
        <span class="pagamento-valor">{{ formatarValorECF(venda.total) }}</span>
      </div>
      <div v-if="venda.valor_recebido > 0 && venda.forma_pagamento === 'dinheiro'" class="pagamento-linha-ecf">
        <span>Valor Recebido</span>
        <span>{{ formatarValorECF(venda.valor_recebido) }}</span>
      </div>
      <div v-if="venda.troco > 0" class="pagamento-linha-ecf troco-linha">
        <span>TROCO R$</span>
        <span class="troco-valor">{{ formatarValorECF(venda.troco) }}</span>
      </div>
    </div>

    <div class="cupom-divider-thick"></div>

    <!-- Rodapé (ECF-SC) -->
    <div class="cupom-footer-ecf">
      <p class="footer-linha">{{ empresaNome }}</p>
      <p class="footer-linha">OBRIGADO PELA PREFERENCIA</p>
      <p class="footer-linha volte-sempre">VOLTE SEMPRE!</p>
      <div v-if="venda.observacoes" class="cupom-observacoes">
        <p>OBS: {{ venda.observacoes }}</p>
      </div>
      <div class="cupom-sistema">
        <p>Sistema: AIShop</p>
        <p>{{ formatarDataHoraBR(new Date()) }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { formatarMoeda, formatarDataHora } from '@/utils/formatadores'

const props = defineProps({
  venda: {
    type: Object,
    required: true
  },
  itens: {
    type: Array,
    required: true
  },
  cliente: {
    type: Object,
    default: null
  }
})

const cupomRef = ref(null)
const empresaNome = ref('AISHOP COMERCIO LTDA')
const empresaCNPJ = ref('00.000.000/0001-00')
const empresaIE = ref('000.000.000')
const empresaEndereco = ref('RUA EXEMPLO, 123 - CENTRO')
const empresaCidade = ref('FLORIANOPOLIS - SC - CEP 88000-000')
const empresaTelefone = ref('(48) 0000-0000')
const qrCodeUrl = ref(null)

function formatarFormaPagamento(forma) {
  const formas = {
    dinheiro: 'DINHEIRO',
    debito: 'CARTAO DEBITO',
    credito: 'CARTAO CREDITO',
    pix: 'PIX',
    vale: 'VALE/CONVENIO',
    mistura: 'PAGAMENTO MISTO'
  }
  return formas[forma] || forma.toUpperCase()
}

function getProdutoNome(item) {
  if (item.produto) {
    const nome = Array.isArray(item.produto) ? item.produto[0]?.nome : item.produto.nome
    return nome ? nome.toUpperCase() : 'PRODUTO NAO ENCONTRADO'
  }
  return 'PRODUTO NAO ENCONTRADO'
}

function getProdutoCodigo(item) {
  if (item.produto) {
    const produto = Array.isArray(item.produto) ? item.produto[0] : item.produto
    return produto?.codigo || produto?.codigo_barras || '000000'
  }
  return '000000'
}

function getProdutoUnidade(item) {
  if (item.produto) {
    const produto = Array.isArray(item.produto) ? item.produto[0] : item.produto
    return produto?.unidade?.toUpperCase() || 'UN'
  }
  return 'UN'
}

function formatarValorECF(valor) {
  // Formato ECF-SC: com vírgula e 2 decimais
  return valor.toFixed(2).replace('.', ',')
}

function formatarQuantidade(qtd) {
  // Formato ECF-SC: com vírgula e 3 decimais
  return qtd.toFixed(3).replace('.', ',')
}

function formatarDocumento(doc) {
  if (!doc) return ''
  const apenasNumeros = doc.replace(/\D/g, '')
  if (apenasNumeros.length === 11) {
    return 'CPF: ' + apenasNumeros.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4')
  } else if (apenasNumeros.length === 14) {
    return 'CNPJ: ' + apenasNumeros.replace(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '$1.$2.$3/$4-$5')
  }
  return doc
}

function formatarDataHoraBR(data) {
  const d = new Date(data)
  const dia = String(d.getDate()).padStart(2, '0')
  const mes = String(d.getMonth() + 1).padStart(2, '0')
  const ano = d.getFullYear()
  const hora = String(d.getHours()).padStart(2, '0')
  const minuto = String(d.getMinutes()).padStart(2, '0')
  const segundo = String(d.getSeconds()).padStart(2, '0')
  return `${dia}/${mes}/${ano} ${hora}:${minuto}:${segundo}`
}

function gerarQRCode() {
  // Gerar QR Code com informações da venda
  // Você pode usar uma biblioteca como qrcode.js ou gerar via API
  const dados = {
    numero: props.venda.numero_venda,
    total: props.venda.total,
    data: props.venda.created_at
  }
  // TODO: Implementar geração de QR Code
  qrCodeUrl.value = null
}

function imprimir() {
  window.print()
}

function gerarPDF() {
  // Usar biblioteca como jsPDF ou html2pdf
  // TODO: Implementar geração de PDF
  console.log('Gerando PDF...')
}

onMounted(() => {
  gerarQRCode()
})

defineExpose({
  imprimir,
  gerarPDF
})
</script>

<style scoped>
/* Estilo ECF-SC (Padrão Brasileiro) */
.cupom-fiscal {
  width: 100%;
  max-width: 300px;
  margin: 0 auto;
  padding: 0.5rem;
  background: white;
  font-family: 'Courier New', monospace;
  font-size: 10px;
  line-height: 1.2;
  color: #000;
}

.cupom-header {
  text-align: center;
  margin-bottom: 0.5rem;
}

.cupom-header h2 {
  font-size: 12px;
  font-weight: bold;
  margin: 0 0 0.25rem 0;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.cupom-cnpj,
.cupom-ie,
.cupom-endereco,
.cupom-cidade,
.cupom-contato {
  font-size: 9px;
  margin: 0.125rem 0;
  line-height: 1.3;
}

.cupom-divider {
  border-top: 1px dashed #000;
  margin: 0.4rem 0;
}

.cupom-divider-thick {
  border-top: 1px solid #000;
  margin: 0.5rem 0;
}

.cupom-info {
  text-align: center;
  margin: 0.5rem 0;
}

.info-linha {
  margin: 0.15rem 0;
  font-size: 10px;
  font-weight: bold;
}

.cupom-tipo {
  font-size: 11px;
  margin-bottom: 0.3rem;
}

.cliente-info {
  font-size: 9px;
  font-weight: normal;
}

/* Itens formato ECF-SC */
.cupom-itens {
  margin: 0.5rem 0;
}

.itens-header-ecf {
  font-size: 8px;
  font-weight: bold;
  margin-bottom: 0.3rem;
  word-spacing: -0.1em;
}

.item-linha-ecf {
  margin-bottom: 0.4rem;
  font-size: 9px;
}

.item-linha-principal {
  display: flex;
  gap: 0.25rem;
  margin-bottom: 0.1rem;
  align-items: flex-start;
}

.item-numero {
  min-width: 18px;
  font-weight: bold;
}

.item-codigo {
  min-width: 45px;
  font-size: 8px;
}

.item-descricao {
  flex: 1;
  font-weight: bold;
  word-break: break-word;
}

.item-linha-valores {
  display: grid;
  grid-template-columns: 45px 20px 50px 1fr;
  gap: 0.25rem;
  font-size: 9px;
  text-align: right;
  padding-left: 18px;
}

.item-qtd,
.item-vlunit,
.item-vltotal {
  font-weight: bold;
}

.item-un {
  text-align: left;
}

.item-desconto-ecf {
  padding-left: 18px;
  font-size: 8px;
  margin-top: 0.1rem;
  font-style: italic;
}

/* Totais ECF-SC */
.cupom-totais-ecf {
  margin: 0.5rem 0;
  text-align: right;
}

.total-linha-ecf {
  display: flex;
  justify-content: space-between;
  margin: 0.2rem 0;
  font-size: 10px;
}

.total-valor-ecf {
  font-weight: bold;
  font-size: 14px;
  min-width: 80px;
  text-align: right;
}

.desconto-linha {
  font-size: 9px;
}

/* Pagamento ECF-SC */
.cupom-pagamento-ecf {
  margin: 0.5rem 0;
}

.pagamento-titulo {
  text-align: center;
  font-size: 9px;
  font-weight: bold;
  margin-bottom: 0.3rem;
}

.pagamento-linha-ecf {
  display: flex;
  justify-content: space-between;
  margin: 0.2rem 0;
  font-size: 10px;
}

.pagamento-valor {
  font-weight: bold;
  min-width: 70px;
  text-align: right;
}

.troco-linha {
  font-weight: bold;
  font-size: 11px;
  margin-top: 0.3rem;
}

.troco-valor {
  font-size: 12px;
}

/* Rodapé ECF-SC */
.cupom-footer-ecf {
  text-align: center;
  margin-top: 0.5rem;
}

.footer-linha {
  margin: 0.15rem 0;
  font-size: 10px;
  font-weight: bold;
}

.volte-sempre {
  font-size: 11px;
  margin-top: 0.3rem;
  margin-bottom: 0.5rem;
}

.cupom-observacoes {
  margin: 0.5rem 0;
  font-size: 8px;
  text-align: left;
  font-style: italic;
  border-top: 1px dashed #000;
  padding-top: 0.3rem;
}

.cupom-sistema {
  margin-top: 0.5rem;
  font-size: 8px;
  color: #666;
  border-top: 1px dashed #000;
  padding-top: 0.3rem;
}

.cupom-sistema p {
  margin: 0.1rem 0;
}

@media print {
  .cupom-fiscal {
    max-width: 100%;
    padding: 0;
  }

  @page {
    size: 80mm auto;
    margin: 0;
  }

  body {
    margin: 0;
    padding: 0;
  }
}
</style>