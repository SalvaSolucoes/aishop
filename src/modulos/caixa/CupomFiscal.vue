<template>
  <div class="cupom-fiscal" ref="cupomRef">
    <div class="cupom-header">
      <h2>{{ empresaNome }}</h2>
      <p class="cupom-endereco">{{ empresaEndereco }}</p>
      <p class="cupom-contato">{{ empresaContato }}</p>
    </div>

    <div class="cupom-divider"></div>

    <div class="cupom-info">
      <div class="info-linha">
        <span>CUPOM FISCAL</span>
      </div>
      <div class="info-linha">
        <span>Nº: {{ venda.numero_venda }}</span>
      </div>
      <div class="info-linha">
        <span>Data: {{ formatarDataHora(venda.created_at) }}</span>
      </div>
      <div v-if="cliente" class="info-linha">
        <span>Cliente: {{ cliente.nome }}</span>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <div class="cupom-itens">
      <div class="itens-header">
        <span>Item</span>
        <span>Qtd</span>
        <span>Vl.Unit</span>
        <span>Total</span>
      </div>
      <div
        v-for="(item, index) in itens"
        :key="index"
        class="item-linha"
      >
        <div class="item-nome">{{ getProdutoNome(item) }}</div>
        <div class="item-valores">
          <span>{{ item.quantidade }} {{ getProdutoUnidade(item) || 'un' }}</span>
          <span>{{ formatarMoeda(item.preco_unitario) }}</span>
          <span>{{ formatarMoeda(item.subtotal) }}</span>
        </div>
        <div v-if="item.desconto > 0" class="item-desconto">
          Desconto: {{ formatarMoeda(item.desconto) }}
        </div>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <div class="cupom-totais">
      <div class="total-linha">
        <span>Subtotal:</span>
        <span>{{ formatarMoeda(venda.subtotal) }}</span>
      </div>
      <div v-if="venda.desconto > 0" class="total-linha">
        <span>Desconto:</span>
        <span>-{{ formatarMoeda(venda.desconto) }}</span>
      </div>
      <div class="total-linha total-final">
        <span>TOTAL:</span>
        <span>{{ formatarMoeda(venda.total) }}</span>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <div class="cupom-pagamento">
      <div class="pagamento-linha">
        <span>Forma de Pagamento:</span>
        <span>{{ formatarFormaPagamento(venda.forma_pagamento) }}</span>
      </div>
      <div v-if="venda.valor_recebido > 0" class="pagamento-linha">
        <span>Valor Recebido:</span>
        <span>{{ formatarMoeda(venda.valor_recebido) }}</span>
      </div>
      <div v-if="venda.troco > 0" class="pagamento-linha">
        <span>Troco:</span>
        <span>{{ formatarMoeda(venda.troco) }}</span>
      </div>
    </div>

    <div class="cupom-divider"></div>

    <div class="cupom-footer">
      <p>Obrigado pela preferência!</p>
      <p class="cupom-qrcode" v-if="qrCodeUrl">
        <img :src="qrCodeUrl" alt="QR Code" />
      </p>
      <p class="cupom-obs" v-if="venda.observacoes">
        Obs: {{ venda.observacoes }}
      </p>
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
const empresaNome = ref('AIShop - Sistema de Gestão')
const empresaEndereco = ref('Endereço da Empresa')
const empresaContato = ref('Telefone: (00) 0000-0000 | Email: contato@aishop.com')
const qrCodeUrl = ref(null)

function formatarFormaPagamento(forma) {
  const formas = {
    dinheiro: 'Dinheiro',
    debito: 'Débito',
    credito: 'Crédito',
    pix: 'Pix',
    vale: 'Vale/Convênio',
    mistura: 'Pagamento Misto'
  }
  return formas[forma] || forma
}

function getProdutoNome(item) {
  if (item.produto) {
    return Array.isArray(item.produto) ? item.produto[0]?.nome : item.produto.nome
  }
  return 'Produto não encontrado'
}

function getProdutoUnidade(item) {
  if (item.produto) {
    const produto = Array.isArray(item.produto) ? item.produto[0] : item.produto
    return produto?.unidade
  }
  return 'un'
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
.cupom-fiscal {
  width: 100%;
  max-width: 300px;
  margin: 0 auto;
  padding: 1rem;
  background: white;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  line-height: 1.4;
}

.cupom-header {
  text-align: center;
  margin-bottom: 1rem;
}

.cupom-header h2 {
  font-size: 16px;
  font-weight: bold;
  margin: 0 0 0.5rem 0;
  text-transform: uppercase;
}

.cupom-endereco,
.cupom-contato {
  font-size: 10px;
  margin: 0.25rem 0;
  color: #666;
}

.cupom-divider {
  border-top: 1px dashed #000;
  margin: 0.75rem 0;
}

.cupom-info {
  margin-bottom: 0.75rem;
}

.info-linha {
  margin: 0.25rem 0;
  text-align: center;
  font-weight: bold;
}

.cupom-itens {
  margin-bottom: 0.75rem;
}

.itens-header {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  gap: 0.25rem;
  font-weight: bold;
  border-bottom: 1px solid #000;
  padding-bottom: 0.25rem;
  margin-bottom: 0.5rem;
  font-size: 10px;
}

.item-linha {
  margin-bottom: 0.5rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px dotted #ccc;
}

.item-nome {
  font-weight: bold;
  margin-bottom: 0.25rem;
  font-size: 11px;
}

.item-valores {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 0.25rem;
  font-size: 10px;
  text-align: right;
}

.item-desconto {
  font-size: 9px;
  color: #666;
  margin-top: 0.25rem;
  font-style: italic;
}

.cupom-totais {
  margin-bottom: 0.75rem;
}

.total-linha {
  display: flex;
  justify-content: space-between;
  margin: 0.5rem 0;
  font-size: 11px;
}

.total-final {
  font-weight: bold;
  font-size: 14px;
  border-top: 1px solid #000;
  padding-top: 0.5rem;
  margin-top: 0.75rem;
}

.cupom-pagamento {
  margin-bottom: 0.75rem;
}

.pagamento-linha {
  display: flex;
  justify-content: space-between;
  margin: 0.25rem 0;
  font-size: 10px;
}

.cupom-footer {
  text-align: center;
  margin-top: 1rem;
}

.cupom-footer p {
  margin: 0.5rem 0;
  font-size: 10px;
}

.cupom-qrcode {
  margin: 1rem 0;
}

.cupom-qrcode img {
  width: 100px;
  height: 100px;
}

.cupom-obs {
  font-size: 9px;
  color: #666;
  font-style: italic;
  margin-top: 0.5rem;
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
}
</style>