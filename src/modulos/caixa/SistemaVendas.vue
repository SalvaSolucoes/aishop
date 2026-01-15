<template>
  <div class="sistema-vendas">
    <!-- Indicador de Etapas Profissional -->
    <div class="checkout-steps">
      <div 
        v-for="(etapa, index) in etapas" 
        :key="etapa.id"
        class="step-item"
        :class="{ 
          'step-active': etapaAtual === index,
          'step-completed': etapaAtual > index,
          'step-pending': etapaAtual < index
        }"
      >
        <div class="step-connector" v-if="index > 0"></div>
        <div class="step-content">
          <div class="step-icon-wrapper">
            <component :is="etapa.icon" class="step-icon" />
            <div v-if="etapaAtual > index" class="step-check">
              <CheckIcon class="step-check-icon" />
            </div>
          </div>
          <div class="step-label">{{ etapa.label }}</div>
        </div>
      </div>
    </div>

    <!-- Etapa 1: Início / Seleção de Cliente -->
    <div v-if="etapaAtual === 0" class="checkout-stage">
      <div class="checkout-card">
        <div class="info-grid">
          <div class="info-card">
            <div class="info-icon">
              <UserGroupIcon class="h-5 w-5" />
            </div>
            <div class="info-content">
              <div class="info-label">Operador</div>
              <div class="info-value">{{ operadorNome }}</div>
            </div>
          </div>
          <div class="info-card">
            <div class="info-icon">
              <ClockIcon class="h-5 w-5" />
            </div>
            <div class="info-content">
              <div class="info-label">Data/Hora</div>
              <div class="info-value">{{ dataHoraAtual }}</div>
            </div>
          </div>
          <div class="info-card">
            <div class="info-icon">
              <CreditCardIcon class="h-5 w-5" />
            </div>
            <div class="info-content">
              <div class="info-label">Caixa</div>
              <div class="info-value">#{{ caixaId.slice(0, 8) }}</div>
            </div>
          </div>
        </div>

        <div class="form-section">
          <label class="form-label">Cliente (Opcional)</label>
          <div class="input-group">
            <div class="input-wrapper">
              <MagnifyingGlassIcon class="input-icon" />
              <input
                v-model="buscaCliente"
                type="text"
                class="form-input"
                placeholder="Buscar cliente por nome, CPF ou e-mail..."
                @input="buscarClientes"
              />
            </div>
            <button
              v-if="clienteSelecionado"
              class="btn btn-ghost btn-sm"
              @click="removerCliente"
            >
              <XMarkIcon class="h-4 w-4" />
            </button>
          </div>
          <div v-if="clientesEncontrados.length > 0 && buscaCliente && !clienteSelecionado" class="search-results">
            <div
              v-for="cliente in clientesEncontrados"
              :key="cliente.id"
              class="search-result-item"
              @click="selecionarCliente(cliente)"
            >
              <div class="result-content">
                <div class="result-name">{{ cliente.nome }}</div>
                <div v-if="cliente.documento" class="result-doc">{{ formatarDocumento(cliente.documento) }}</div>
              </div>
              <ArrowRightIcon class="h-5 w-5 text-gray-400" />
            </div>
          </div>
          <div v-if="clienteSelecionado" class="selected-client">
            <CheckCircleIcon class="h-5 w-5 text-green-600" />
            <div>
              <div class="selected-label">Cliente selecionado</div>
              <div class="selected-name">{{ clienteSelecionado.nome }}</div>
            </div>
          </div>
        </div>

        <div class="stage-actions">
          <button class="btn btn-primary btn-large" @click="iniciarCarrinho">
            <ShoppingCartIcon class="h-5 w-5" />
            Iniciar Carrinho
          </button>
        </div>
      </div>
    </div>

    <!-- Etapa 2: Carrinho / Adição de Produtos -->
    <div v-if="etapaAtual === 1" class="checkout-stage">
      <div class="stage-header">
        <div>
          <h2 class="stage-title">Carrinho de Compras</h2>
          <p class="stage-subtitle">Adicione produtos ao carrinho</p>
        </div>
        <button class="btn btn-ghost" @click="voltarEtapa">
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar
        </button>
      </div>

      <div v-if="erro" class="alert alert-error">
        <ExclamationCircleIcon class="h-5 w-5" />
        {{ erro }}
      </div>

      <div class="checkout-card">
        <div class="search-section">
          <label class="form-label">Buscar Produto</label>
          <div class="input-group">
            <div class="input-wrapper">
              <MagnifyingGlassIcon class="input-icon" />
              <input
                ref="inputBuscaProduto"
                v-model="buscaProduto"
                type="text"
                class="form-input"
                placeholder="Digite o código de barras ou nome do produto..."
                @keyup.enter="adicionarProdutoPorBusca"
                @input="buscarProdutos"
                @keydown="onKeyDown"
              />
            </div>
            <button
              v-if="buscaProduto"
              class="btn btn-ghost btn-sm"
              @click="limparBusca"
              title="Limpar busca"
            >
              <XMarkIcon class="h-4 w-4" />
            </button>
          </div>

        <div v-if="produtosEncontrados.length > 0 && buscaProduto" class="resultados-busca">
          <div
            v-for="produto in produtosEncontrados"
            :key="produto.id"
            class="produto-resultado"
            @click="adicionarAoCarrinho(produto)"
          >
            <div class="produto-info">
              <strong>{{ produto.nome }}</strong>
              <span class="produto-codigo">{{ produto.codigo_barras || produto.codigo || '-' }}</span>
            </div>
            <div class="produto-preco">
              {{ formatarMoeda(produto.preco_unitario) }}
              <span v-if="produto.quantidade > 0" class="estoque-disponivel">
                Estoque: {{ produto.quantidade }} {{ produto.unidade || 'un' }}
              </span>
              <span v-else class="sem-estoque">Sem estoque</span>
            </div>
          </div>
        </div>
      </div>

        <div class="cart-section">
          <div class="cart-header">
            <h3 class="section-title">Carrinho ({{ itensCarrinho.length }})</h3>
            <button
              v-if="itensCarrinho.length > 0"
              class="btn btn-ghost btn-sm"
              @click="limparCarrinho"
            >
              <TrashIcon class="h-4 w-4" />
              Limpar
            </button>
          </div>

          <div v-if="itensCarrinho.length === 0" class="empty-cart">
            <ShoppingCartIcon class="h-12 w-12 text-gray-300" />
            <p class="empty-cart-text">Nenhum item no carrinho</p>
            <p class="empty-cart-hint">Digite o código de barras ou busque um produto para começar</p>
          </div>

          <div v-else class="cart-items">
            <div
              v-for="(item, index) in itensCarrinho"
              :key="index"
              class="cart-item"
            >
              <div class="cart-item-info">
                <div class="cart-item-name">{{ item.produto.nome }}</div>
                <div class="cart-item-details">
                  {{ formatarMoeda(item.preco_unitario) }} × {{ item.quantidade }} {{ item.produto.unidade || 'un' }}
                </div>
                <div v-if="item.observacoes" class="cart-item-notes">
                  <DocumentTextIcon class="h-4 w-4" />
                  {{ item.observacoes }}
                </div>
              </div>
              <div class="cart-item-controls">
                <div class="quantity-controls">
                  <button
                    class="qty-btn"
                    @click="alterarQuantidade(index, item.quantidade - 1)"
                    :disabled="item.quantidade <= 1"
                  >
                    <MinusIcon class="h-4 w-4" />
                  </button>
                  <input
                    v-model.number="item.quantidade"
                    type="number"
                    class="qty-input"
                    min="1"
                    :max="item.produto.quantidade"
                    @change="atualizarItem(index)"
                  />
                  <button
                    class="qty-btn"
                    @click="alterarQuantidade(index, item.quantidade + 1)"
                    :disabled="item.quantidade >= item.produto.quantidade"
                  >
                    <PlusIcon class="h-4 w-4" />
                  </button>
                </div>
                <div class="item-actions">
                  <button
                    class="action-btn"
                    @click="editarItem(index)"
                    title="Editar"
                  >
                    <PencilIcon class="h-4 w-4" />
                  </button>
                  <button
                    class="action-btn action-btn-danger"
                    @click="removerItem(index)"
                    title="Remover"
                  >
                    <TrashIcon class="h-4 w-4" />
                  </button>
                </div>
              </div>
              <div class="cart-item-price">
                {{ formatarMoeda(item.subtotal) }}
              </div>
            </div>
          </div>

          <div class="cart-summary">
            <div class="summary-row">
              <span>Subtotal</span>
              <span>{{ formatarMoeda(subtotal) }}</span>
            </div>
            <div class="summary-row">
              <span>Desconto</span>
              <input
                v-model.number="descontoGeral"
                type="number"
                class="discount-input"
                min="0"
                step="0.01"
                placeholder="0.00"
                @input="calcularTotal"
              />
            </div>
            <div class="summary-row summary-total">
              <span>Total</span>
              <span class="total-value">{{ formatarMoeda(total) }}</span>
            </div>
          </div>
        </div>

        <div class="stage-actions">
          <button class="btn btn-ghost" @click="cancelarVenda">
            <XMarkIcon class="h-4 w-4" />
            Cancelar
          </button>
          <button
            class="btn btn-primary btn-large"
            @click="avancarParaRevisao"
            :disabled="itensCarrinho.length === 0"
          >
            Continuar para Revisão
            <ArrowRightIcon class="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>

    <!-- Etapa 3: Revisão -->
    <div v-if="etapaAtual === 2" class="checkout-stage">
      <div class="stage-header">
        <div>
          <h2 class="stage-title">Revisão do Pedido</h2>
          <p class="stage-subtitle">Revise os itens e valores antes de prosseguir</p>
        </div>
        <button class="btn btn-ghost" @click="voltarEtapa">
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar
        </button>
      </div>

      <div class="checkout-card">
        <div class="review-section">
          <h3 class="section-title">Itens do Pedido</h3>
          <div class="items-list">
            <div
              v-for="(item, index) in itensCarrinho"
              :key="index"
              class="review-item"
            >
              <div class="review-item-info">
                <div class="review-item-name">{{ item.produto.nome }}</div>
                <div class="review-item-details">
                  {{ item.quantidade }} × {{ formatarMoeda(item.preco_unitario) }}
                </div>
              </div>
              <div class="review-item-price">{{ formatarMoeda(item.subtotal) }}</div>
            </div>
          </div>
        </div>

        <div class="summary-section">
          <div class="summary-row">
            <span>Subtotal</span>
            <span>{{ formatarMoeda(subtotal) }}</span>
          </div>
          <div class="summary-row">
            <span>Desconto</span>
            <input
              v-model.number="descontoGeral"
              type="number"
              class="discount-input"
              min="0"
              step="0.01"
              placeholder="0.00"
              @input="calcularTotal"
            />
          </div>
          <div class="summary-row summary-total">
            <span>Total</span>
            <span class="total-value">{{ formatarMoeda(total) }}</span>
          </div>
        </div>

        <div class="stage-actions">
          <button class="btn btn-ghost" @click="voltarEtapa">
            <ArrowLeftIcon class="h-4 w-4" />
            Voltar
          </button>
          <button
            class="btn btn-primary btn-large"
            @click="avancarParaPagamento"
          >
            Continuar para Pagamento
            <ArrowRightIcon class="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>

    <!-- Etapa 4: Pagamento -->
    <div v-if="etapaAtual === 3" class="checkout-stage">
      <div class="stage-header">
        <div>
          <h2 class="stage-title">Pagamento</h2>
          <p class="stage-subtitle">Selecione a forma de pagamento</p>
        </div>
        <button class="btn btn-ghost" @click="voltarEtapa">
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar
        </button>
      </div>

      <div class="checkout-card">
        <div class="total-display">
          <div class="total-label">Total a Pagar</div>
          <div class="total-amount">{{ formatarMoeda(total) }}</div>
        </div>

        <div class="payment-methods">
          <label class="form-label">Forma de Pagamento</label>
          <div class="payment-grid">
            <button
              v-for="forma in formasPagamento"
              :key="forma.value"
              class="payment-option"
              :class="{ 'payment-option-active': formaPagamento === forma.value }"
              @click="selecionarFormaPagamento(forma.value)"
            >
              <component :is="forma.icon" class="payment-icon" />
              <span>{{ forma.label }}</span>
            </button>
          </div>
        </div>

        <!-- Pagamento em Dinheiro -->
        <div v-if="formaPagamento === 'dinheiro'" class="payment-form">
          <div class="form-section">
            <label class="form-label">Valor Recebido</label>
            <input
              ref="inputValorRecebido"
              v-model.number="valorRecebido"
              type="number"
              class="form-input form-input-large"
              min="0"
              step="0.01"
              placeholder="0.00"
              @input="calcularTroco"
            />
          </div>
          <div v-if="troco > 0" class="change-display change-positive">
            <span>Troco</span>
            <span class="change-value">{{ formatarMoeda(troco) }}</span>
          </div>
          <div v-else-if="valorRecebido > 0 && valorRecebido < total" class="change-display change-negative">
            <span>Valor insuficiente. Faltam {{ formatarMoeda(total - valorRecebido) }}</span>
          </div>
        </div>

        <!-- Pagamento Misto -->
        <div v-if="formaPagamento === 'mistura'" class="payment-form">
          <div class="form-section">
            <label class="form-label">Dinheiro</label>
            <input
              v-model.number="pagamentoMistura.dinheiro"
              type="number"
              class="form-input"
              min="0"
              step="0.01"
              placeholder="0.00"
              @input="calcularTotalMistura"
            />
          </div>
          <div class="form-section">
            <label class="form-label">Cartão de Débito</label>
            <input
              v-model.number="pagamentoMistura.debito"
              type="number"
              class="form-input"
              min="0"
              step="0.01"
              placeholder="0.00"
              @input="calcularTotalMistura"
            />
          </div>
          <div class="form-section">
            <label class="form-label">Cartão de Crédito</label>
            <div class="input-group">
              <input
                v-model.number="pagamentoMistura.credito"
                type="number"
                class="form-input"
                min="0"
                step="0.01"
                placeholder="0.00"
                @input="calcularTotalMistura"
              />
              <select v-model="parcelasCredito" class="form-select" style="max-width: 120px;">
                <option :value="1">À vista</option>
                <option :value="2">2x</option>
                <option :value="3">3x</option>
                <option :value="4">4x</option>
                <option :value="5">5x</option>
                <option :value="6">6x</option>
              </select>
            </div>
          </div>
          <div class="form-section">
            <label class="form-label">Pix</label>
            <input
              v-model.number="pagamentoMistura.pix"
              type="number"
              class="form-input"
              min="0"
              step="0.01"
              placeholder="0.00"
              @input="calcularTotalMistura"
            />
          </div>
          <div class="mixed-payment-summary">
            <div class="summary-row">
              <span>Total Recebido</span>
              <span class="font-semibold">{{ formatarMoeda(totalMistura) }}</span>
            </div>
            <div v-if="totalMistura < total" class="change-display change-negative">
              <span>Faltam</span>
              <span class="change-value">{{ formatarMoeda(total - totalMistura) }}</span>
            </div>
            <div v-else-if="totalMistura > total" class="change-display change-positive">
              <span>Troco</span>
              <span class="change-value">{{ formatarMoeda(totalMistura - total) }}</span>
            </div>
          </div>
        </div>

        <!-- Cartão de Crédito com Parcelamento -->
        <div v-if="formaPagamento === 'credito'" class="payment-form">
          <div class="form-section">
            <label class="form-label">Parcelas</label>
            <select v-model="parcelasCredito" class="form-select">
              <option :value="1">À vista</option>
              <option :value="2">2x sem juros</option>
              <option :value="3">3x sem juros</option>
              <option :value="4">4x sem juros</option>
              <option :value="5">5x sem juros</option>
              <option :value="6">6x sem juros</option>
            </select>
            <small class="form-hint">Valor por parcela: {{ formatarMoeda(total / parcelasCredito) }}</small>
          </div>
        </div>

        <div class="stage-actions">
          <button class="btn btn-ghost" @click="voltarEtapa">
            <ArrowLeftIcon class="h-4 w-4" />
            Voltar
          </button>
          <button
            class="btn btn-primary btn-large"
            @click="avancarParaFinalizacao"
            :disabled="!podeFinalizar"
          >
            Continuar para Confirmação
            <ArrowRightIcon class="h-5 w-5" />
          </button>
        </div>
      </div>
    </div>

    <!-- Etapa 5: Confirmação -->
    <div v-if="etapaAtual === 4" class="checkout-stage">
      <div class="stage-header">
        <div>
          <h2 class="stage-title">Confirmação</h2>
          <p class="stage-subtitle">Revise os detalhes e confirme a venda</p>
        </div>
        <button class="btn btn-ghost" @click="voltarEtapa">
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar
        </button>
      </div>

      <div v-if="erro" class="alert alert-error">
        <ExclamationCircleIcon class="h-5 w-5" />
        {{ erro }}
      </div>

      <div class="checkout-card">
        <div class="confirmation-summary">
          <h3 class="section-title">Resumo da Venda</h3>
          <div class="summary-grid">
            <div class="summary-item">
              <div class="summary-label">Cliente</div>
              <div class="summary-value">{{ clienteSelecionado ? clienteSelecionado.nome : 'Não informado' }}</div>
            </div>
            <div class="summary-item">
              <div class="summary-label">Itens</div>
              <div class="summary-value">{{ itensCarrinho.length }} produto(s)</div>
            </div>
            <div class="summary-item">
              <div class="summary-label">Subtotal</div>
              <div class="summary-value">{{ formatarMoeda(subtotal) }}</div>
            </div>
            <div class="summary-item">
              <div class="summary-label">Desconto</div>
              <div class="summary-value">{{ formatarMoeda(descontoGeral) }}</div>
            </div>
            <div class="summary-item summary-item-total">
              <div class="summary-label">Total</div>
              <div class="summary-value-total">{{ formatarMoeda(total) }}</div>
            </div>
            <div class="summary-item">
              <div class="summary-label">Forma de Pagamento</div>
              <div class="summary-value">{{ formasPagamento.find(f => f.value === formaPagamento)?.label }}</div>
            </div>
            <div v-if="troco > 0" class="summary-item">
              <div class="summary-label">Troco</div>
              <div class="summary-value text-green-600">{{ formatarMoeda(troco) }}</div>
            </div>
          </div>
        </div>

        <div class="form-section">
          <label class="form-label">Observações (Opcional)</label>
          <textarea
            v-model="observacoesVenda"
            class="form-textarea"
            placeholder="Adicione observações sobre esta venda..."
            rows="3"
          />
        </div>

        <div class="stage-actions">
          <button class="btn btn-ghost" @click="voltarEtapa">
            <ArrowLeftIcon class="h-4 w-4" />
            Voltar
          </button>
          <button
            class="btn btn-primary btn-large"
            @click="finalizarVenda"
            :disabled="processando"
          >
            <CheckCircleIcon v-if="!processando" class="h-5 w-5" />
            <span v-if="processando" class="spinner h-5 w-5"></span>
            {{ processando ? 'Processando...' : 'Finalizar Venda' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal de Edição de Item -->
    <div v-if="mostrarModalItem" class="modal-overlay" @click.self="fecharModalItem">
      <div class="modal-content modal-item">
        <div class="modal-header">
          <h3>Editar Item</h3>
          <button class="btn-close" @click="fecharModalItem">
            <XMarkIcon class="icone-btn" />
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">Desconto (R$)</label>
            <input
              v-model.number="itemEditando.desconto"
              type="number"
              class="form-input"
              min="0"
              step="0.01"
              placeholder="0.00"
              @input="atualizarItemEditando"
            />
          </div>
          <div class="form-group">
            <label class="form-label">Observações</label>
            <textarea
              v-model="itemEditando.observacoes"
              class="form-textarea"
              placeholder="Ex: peso variável, produto frágil..."
              rows="3"
            />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-ghost" @click="fecharModalItem">Cancelar</button>
          <button class="btn btn-primario" @click="salvarItemEditando">Salvar</button>
        </div>
      </div>
    </div>

    <!-- Modal de Cancelamento -->
    <div v-if="mostrarModalCancelamento" class="modal-overlay" @click.self="fecharModalCancelamento">
      <div class="modal-content modal-cancelamento">
        <div class="modal-header">
          <h3>Cancelar Venda</h3>
          <button class="btn-close" @click="fecharModalCancelamento">
            <XMarkIcon class="icone-btn" />
          </button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label class="form-label">Justificativa</label>
            <textarea
              v-model="justificativaCancelamento"
              class="form-textarea"
              placeholder="Informe o motivo do cancelamento..."
              rows="4"
              required
            />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn btn-ghost" @click="fecharModalCancelamento">Não Cancelar</button>
          <button class="btn btn-perigo" @click="confirmarCancelamento">Confirmar Cancelamento</button>
        </div>
      </div>
    </div>

    <!-- Modal de Cupom Fiscal -->
    <div v-if="mostrarCupomFiscal && vendaAtual" class="modal-overlay modal-cupom" @click.self="fecharCupomFiscal">
      <div class="modal-content modal-cupom-content">
        <div class="modal-header">
          <h3>Cupom Fiscal</h3>
          <div class="modal-acoes">
            <button class="btn btn-ghost btn-sm" @click="imprimirCupom">
              <PrinterIcon class="icone-btn" />
              Imprimir
            </button>
            <button class="btn-close" @click="fecharCupomFiscal">
              <XMarkIcon class="icone-btn" />
            </button>
          </div>
        </div>
        <div class="modal-body modal-cupom-body">
          <CupomFiscal
            :venda="vendaAtual"
            :itens="itensVendaAtual"
            :cliente="clienteSelecionado"
          />
        </div>
        <div class="modal-footer">
          <button class="btn btn-primario" @click="fecharCupomFiscal">
            Fechar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda, formatarDataHora } from '@/utils/formatadores'
import CupomFiscal from './CupomFiscal.vue'
import {
  ShoppingCartIcon,
  CubeIcon,
  MagnifyingGlassIcon,
  XMarkIcon,
  DocumentTextIcon,
  PencilIcon,
  CreditCardIcon,
  BanknotesIcon,
  DevicePhoneMobileIcon,
  GiftIcon,
  ArrowsRightLeftIcon,
  CheckIcon,
  ArrowLeftIcon,
  ArrowRightIcon,
  PrinterIcon,
  CheckCircleIcon,
  UserGroupIcon,
  ClockIcon,
  TrashIcon,
  ExclamationCircleIcon,
  MinusIcon,
  PlusIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  caixaId: {
    type: String,
    required: true
  }
})

const emit = defineEmits(['venda-finalizada'])

// Estados gerais
const etapaAtual = ref(0)
const operadorNome = ref('')
const dataHoraAtual = ref('')
const erro = ref('')
const processando = ref(false)

// Etapas do processo
const etapas = [
  { id: 'carrinho', label: 'Carrinho', icon: ShoppingCartIcon },
  { id: 'revisao', label: 'Revisão', icon: DocumentTextIcon },
  { id: 'pagamento', label: 'Pagamento', icon: CreditCardIcon },
  { id: 'confirmacao', label: 'Confirmação', icon: CheckCircleIcon }
]

// Cliente
const buscaCliente = ref('')
const clientesEncontrados = ref([])
const clienteSelecionado = ref(null)

// Produtos
const buscaProduto = ref('')
const produtosEncontrados = ref([])
const itensCarrinho = ref([])
const inputBuscaProduto = ref(null)
const bufferCodigoBarras = ref('')
const timeoutCodigoBarras = ref(null)
const timeoutBusca = ref(null)

// Valores
const descontoGeral = ref(0)
const total = ref(0)

// Pagamento
const formaPagamento = ref('dinheiro')
const valorRecebido = ref(0)
const parcelasCredito = ref(1)
const pagamentoMistura = ref({
  dinheiro: 0,
  debito: 0,
  credito: 0,
  pix: 0
})

const formasPagamento = [
  { value: 'dinheiro', label: 'Dinheiro', icon: BanknotesIcon },
  { value: 'debito', label: 'Débito', icon: CreditCardIcon },
  { value: 'credito', label: 'Crédito', icon: CreditCardIcon },
  { value: 'pix', label: 'Pix', icon: DevicePhoneMobileIcon },
  { value: 'vale', label: 'Vale/Convênio', icon: GiftIcon },
  { value: 'mistura', label: 'Misto', icon: ArrowsRightLeftIcon }
]

// Observações
const observacoesVenda = ref('')

// Modal de edição de item
const mostrarModalItem = ref(false)
const itemEditando = ref(null)
const indiceItemEditando = ref(-1)

// Modal de cancelamento
const mostrarModalCancelamento = ref(false)
const justificativaCancelamento = ref('')

// Modal de cupom fiscal
const mostrarCupomFiscal = ref(false)
const vendaAtual = ref(null)
const itensVendaAtual = ref([])

// Computed
const subtotal = computed(() => {
  return itensCarrinho.value.reduce((sum, item) => sum + item.subtotal, 0)
})

const troco = computed(() => {
  if (formaPagamento.value !== 'dinheiro' && formaPagamento.value !== 'mistura') return 0
  if (formaPagamento.value === 'dinheiro') {
    return Math.max(0, valorRecebido.value - total.value)
  }
  return 0
})

const totalMistura = computed(() => {
  return pagamentoMistura.value.dinheiro + 
         pagamentoMistura.value.debito + 
         pagamentoMistura.value.credito + 
         pagamentoMistura.value.pix
})

const podeFinalizar = computed(() => {
  if (itensCarrinho.value.length === 0) return false
  if (formaPagamento.value === 'mistura') {
    return totalMistura.value >= total.value
  }
  if (formaPagamento.value === 'dinheiro') {
    return valorRecebido.value >= total.value
  }
  return true
})

// Funções de inicialização
async function carregarOperador() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      operadorNome.value = user.email || 'Operador'
      dataHoraAtual.value = formatarDataHora(new Date())
    }
  } catch (err) {
    console.error('Erro ao carregar operador:', err)
  }
}

function atualizarDataHora() {
  setInterval(() => {
    dataHoraAtual.value = formatarDataHora(new Date())
  }, 1000)
}

// Funções de navegação
function iniciarCarrinho() {
  etapaAtual.value = 1
  nextTick(() => {
    if (inputBuscaProduto.value) {
      inputBuscaProduto.value.focus()
    }
  })
}

function avancarParaRevisao() {
  calcularTotal()
  etapaAtual.value = 2
}

function avancarParaPagamento() {
  calcularTotal()
  etapaAtual.value = 3
  nextTick(() => {
    if (formaPagamento.value === 'dinheiro' && document.querySelector('.form-input-grande')) {
      document.querySelector('.form-input-grande').focus()
    }
  })
}

function avancarParaFinalizacao() {
  etapaAtual.value = 4
}

function voltarEtapa() {
  if (etapaAtual.value > 0) {
    etapaAtual.value--
  }
}

// Funções de cliente
async function buscarClientes() {
  if (!buscaCliente.value || buscaCliente.value.length < 2) {
    clientesEncontrados.value = []
    return
  }

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const busca = buscaCliente.value.trim()
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .eq('usuario_id', user.id)
      .or(`nome.ilike.%${busca}%,email.ilike.%${busca}%,documento.ilike.%${busca}%`)
      .limit(10)

    if (error) throw error
    clientesEncontrados.value = data || []
  } catch (err) {
    console.error('Erro ao buscar clientes:', err)
    clientesEncontrados.value = []
  }
}

function selecionarCliente(cliente) {
  clienteSelecionado.value = cliente
  buscaCliente.value = cliente.nome
  clientesEncontrados.value = []
}

function removerCliente() {
  clienteSelecionado.value = null
  buscaCliente.value = ''
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

// Funções de produtos
function onKeyDown(event) {
  // Se for um dígito, pode ser código de barras sendo escaneado
  if (event.key.length === 1 && /[0-9]/.test(event.key)) {
    bufferCodigoBarras.value += event.key
    
    if (timeoutCodigoBarras.value) {
      clearTimeout(timeoutCodigoBarras.value)
    }
    
    // Se o buffer tiver 8 ou mais dígitos, pode ser um código de barras completo
    if (bufferCodigoBarras.value.length >= 8) {
      timeoutCodigoBarras.value = setTimeout(() => {
        if (bufferCodigoBarras.value.length >= 8 && /^\d+$/.test(bufferCodigoBarras.value)) {
          // Se o campo de busca estiver vazio ou igual ao buffer, é provavelmente um scanner
          if (!buscaProduto.value || buscaProduto.value === bufferCodigoBarras.value) {
            buscaProduto.value = bufferCodigoBarras.value
            buscarProdutoPorCodigoBarras(bufferCodigoBarras.value)
            bufferCodigoBarras.value = ''
          }
        }
      }, 150)
    }
  } else {
    // Se não for dígito, limpar buffer (usuário está digitando normalmente)
    bufferCodigoBarras.value = ''
    if (timeoutCodigoBarras.value) {
      clearTimeout(timeoutCodigoBarras.value)
    }
  }
}

async function buscarProdutoPorCodigoBarras(codigo) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const codigoLimpo = codigo.replace(/\D/g, '')
    if (![8, 12, 13].includes(codigoLimpo.length)) {
      erro.value = 'Código de barras inválido. Deve ter 8, 12 ou 13 dígitos.'
      return
    }

    const { data, error } = await supabase
      .from('produtos')
      .select('*')
      .eq('usuario_id', user.id)
      .or(`codigo_barras.eq.${codigoLimpo},codigo.eq.${codigoLimpo}`)
      .maybeSingle()

    if (error) throw error

    if (data) {
      adicionarAoCarrinho(data)
      buscaProduto.value = ''
    } else {
      erro.value = 'Produto não encontrado com este código de barras'
      produtosEncontrados.value = []
    }
  } catch (err) {
    console.error('Erro ao buscar produto por código de barras:', err)
    erro.value = 'Erro ao buscar produto: ' + err.message
  }
}

async function buscarProdutos() {
  // Limpar timeout anterior
  if (timeoutBusca.value) {
    clearTimeout(timeoutBusca.value)
  }

  // Se o campo estiver vazio, limpar resultados
  if (!buscaProduto.value || buscaProduto.value.trim().length === 0) {
    produtosEncontrados.value = []
    return
  }

  // Debounce: aguardar 300ms após parar de digitar
  timeoutBusca.value = setTimeout(async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return

      const busca = buscaProduto.value.trim()
      
      // Se não houver busca, limpar resultados
      if (!busca) {
        produtosEncontrados.value = []
        return
      }

      // Verificar se é um código numérico (pode ser código de barras ou código do produto)
      const apenasNumeros = busca.replace(/\D/g, '')
      const temApenasNumeros = apenasNumeros.length === busca.length && apenasNumeros.length > 0
      
      let query = supabase
        .from('produtos')
        .select('*')
        .eq('usuario_id', user.id)

      // Se for apenas números, buscar tanto por código de barras quanto por código
      // E também por nome (caso tenha produtos com nome numérico)
      if (temApenasNumeros) {
        // Buscar por código de barras, código do produto E nome (caso o nome seja numérico)
        query = query.or(
          `codigo_barras.ilike.%${busca}%,codigo.ilike.%${busca}%,nome.ilike.%${busca}%`
        )
      } else {
        // Buscar por nome, código de barras e código (caso o código tenha letras)
        query = query.or(
          `nome.ilike.%${busca}%,codigo_barras.ilike.%${busca}%,codigo.ilike.%${busca}%`
        )
      }

      const { data, error } = await query.limit(20) // Aumentar limite para mostrar mais resultados

      if (error) throw error
      produtosEncontrados.value = data || []
    } catch (err) {
      console.error('Erro ao buscar produtos:', err)
      produtosEncontrados.value = []
    }
  }, 300) // 300ms de debounce
}

function limparBusca() {
  buscaProduto.value = ''
  produtosEncontrados.value = []
  erro.value = ''
  bufferCodigoBarras.value = ''
  if (timeoutCodigoBarras.value) {
    clearTimeout(timeoutCodigoBarras.value)
  }
  if (timeoutBusca.value) {
    clearTimeout(timeoutBusca.value)
  }
  nextTick(() => {
    if (inputBuscaProduto.value) {
      inputBuscaProduto.value.focus()
    }
  })
}

function adicionarAoCarrinho(produto) {
  if (produto.quantidade <= 0) {
    erro.value = 'Produto sem estoque disponível'
    return
  }

  const itemExistente = itensCarrinho.value.find(
    item => item.produto.id === produto.id
  )

  if (itemExistente) {
    if (itemExistente.quantidade < produto.quantidade) {
      itemExistente.quantidade++
      calcularSubtotalItem(itemExistente)
    } else {
      erro.value = 'Quantidade máxima em estoque atingida'
    }
  } else {
    itensCarrinho.value.push({
      produto,
      quantidade: 1,
      preco_unitario: produto.preco_unitario,
      desconto: 0,
      observacoes: '',
      subtotal: produto.preco_unitario
    })
  }

  buscaProduto.value = ''
  produtosEncontrados.value = []
  erro.value = ''
  calcularTotal()
  nextTick(() => {
    if (inputBuscaProduto.value) {
      inputBuscaProduto.value.focus()
    }
  })
}

function adicionarProdutoPorBusca() {
  // Se houver apenas um resultado, adicionar automaticamente
  if (produtosEncontrados.value.length === 1) {
    adicionarAoCarrinho(produtosEncontrados.value[0])
  } else if (produtosEncontrados.value.length > 1) {
    // Se houver múltiplos resultados, não fazer nada (usuário deve clicar)
    return
  } else {
    // Se não houver resultados, tentar buscar novamente
    // Isso pode acontecer se o usuário pressionar Enter muito rápido
    buscarProdutos()
  }
}

function calcularSubtotalItem(item) {
  item.subtotal = (item.preco_unitario * item.quantidade) - (item.desconto || 0)
  calcularTotal()
}

function alterarQuantidade(index, novaQuantidade) {
  const item = itensCarrinho.value[index]
  if (novaQuantidade < 1) return
  if (novaQuantidade > item.produto.quantidade) {
    erro.value = 'Quantidade não pode ser maior que o estoque disponível'
    return
  }
  item.quantidade = novaQuantidade
  calcularSubtotalItem(item)
  erro.value = ''
}

function atualizarItem(index) {
  const item = itensCarrinho.value[index]
  if (item.quantidade < 1) item.quantidade = 1
  if (item.quantidade > item.produto.quantidade) {
    item.quantidade = item.produto.quantidade
    erro.value = 'Quantidade ajustada para o máximo disponível'
  }
  calcularSubtotalItem(item)
}

function editarItem(index) {
  indiceItemEditando.value = index
  itemEditando.value = {
    desconto: itensCarrinho.value[index].desconto || 0,
    observacoes: itensCarrinho.value[index].observacoes || ''
  }
  mostrarModalItem.value = true
}

function fecharModalItem() {
  mostrarModalItem.value = false
  itemEditando.value = null
  indiceItemEditando.value = -1
}

function atualizarItemEditando() {
  // Atualização em tempo real
}

function salvarItemEditando() {
  if (indiceItemEditando.value >= 0) {
    const item = itensCarrinho.value[indiceItemEditando.value]
    item.desconto = itemEditando.value.desconto || 0
    item.observacoes = itemEditando.value.observacoes || ''
    calcularSubtotalItem(item)
  }
  fecharModalItem()
}

function removerItem(index) {
  itensCarrinho.value.splice(index, 1)
  calcularTotal()
}

function limparCarrinho() {
  itensCarrinho.value = []
  descontoGeral.value = 0
  calcularTotal()
}

function calcularTotal() {
  total.value = Math.max(0, subtotal.value - descontoGeral.value)
}

// Funções de pagamento
function selecionarFormaPagamento(forma) {
  formaPagamento.value = forma
  if (forma === 'dinheiro') {
    valorRecebido.value = total.value
    nextTick(() => {
      const input = document.querySelector('.form-input-grande')
      if (input) {
        input.focus()
        input.select()
      }
    })
  }
}

function calcularTroco() {
  // Calculado automaticamente via computed
}

function calcularTotalMistura() {
  // Calculado automaticamente via computed
}

// Funções de finalização
async function finalizarVenda() {
  if (!podeFinalizar.value) return

  processando.value = true
  erro.value = ''

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Usuário não autenticado')

    // Gerar número sequencial da venda usando a função do banco
    const { data: numeroVenda, error: numeroError } = await supabase
      .rpc('get_proximo_numero_venda', { p_caixa_id: props.caixaId })
    
    if (numeroError) throw numeroError
    
    if (!numeroVenda) throw new Error('Erro ao gerar número da venda')

    // Calcular valores de pagamento misto
    let valorRecebidoFinal = total.value
    let trocoFinal = 0

    if (formaPagamento.value === 'dinheiro') {
      valorRecebidoFinal = valorRecebido.value
      trocoFinal = troco.value
    } else if (formaPagamento.value === 'mistura') {
      valorRecebidoFinal = totalMistura.value
      trocoFinal = Math.max(0, totalMistura.value - total.value)
    }

    // Criar venda
    const { data: venda, error: errorVenda } = await supabase
      .from('vendas')
      .insert([{
        caixa_id: props.caixaId,
        cliente_id: clienteSelecionado.value?.id || null,
        usuario_id: user.id,
        numero_venda: numeroVenda,
        subtotal: subtotal.value,
        desconto: descontoGeral.value,
        total: total.value,
        forma_pagamento: formaPagamento.value,
        valor_recebido: valorRecebidoFinal,
        troco: trocoFinal,
        observacoes: observacoesVenda.value
      }])
      .select()
      .single()

    if (errorVenda) throw errorVenda

    // Criar itens da venda e atualizar estoque
    const itensParaInserir = itensCarrinho.value.map(item => ({
      venda_id: venda.id,
      produto_id: item.produto.id,
      quantidade: item.quantidade,
      preco_unitario: item.preco_unitario,
      desconto: item.desconto || 0,
      subtotal: item.subtotal
    }))

    const { error: errorItens } = await supabase
      .from('itens_venda')
      .insert(itensParaInserir)

    if (errorItens) throw errorItens

    // Atualizar estoque e criar movimentações
    for (const item of itensCarrinho.value) {
      const novaQuantidade = item.produto.quantidade - item.quantidade

      const { error: errorProduto } = await supabase
        .from('produtos')
        .update({ quantidade: novaQuantidade })
        .eq('id', item.produto.id)

      if (errorProduto) throw errorProduto

      const { error: errorMov } = await supabase
        .from('movimentacoes_estoque')
        .insert([{
          produto_id: item.produto.id,
          usuario_id: user.id,
          tipo: 'venda',
          quantidade: item.quantidade,
          quantidade_anterior: item.produto.quantidade,
          quantidade_nova: novaQuantidade,
          motivo: `Venda ${numeroVenda}`,
          origem: 'venda',
          origem_id: venda.id
        }])

      if (errorMov) throw errorMov
    }

    // Registrar entrada no caixa (vinculada à venda)
    const { error: errorCaixa } = await supabase
      .from('movimentacoes_caixa')
      .insert([{
        caixa_id: props.caixaId,
        usuario_id: user.id,
        tipo: 'entrada',
        valor: total.value,
        descricao: `Venda ${numeroVenda}`,
        categoria: 'Vendas'
      }])

    if (errorCaixa) throw errorCaixa

    window.dispatchEvent(new CustomEvent('movimentacao-estoque-registrada', {
      detail: {
        venda_id: venda.id,
        numero_venda: numeroVenda,
        atualizouEstoque: true,
        atualizouRelatorios: true
      }
    }))

    window.dispatchEvent(new CustomEvent('movimentacao-registrada', {
      detail: {
        tipo: 'entrada',
        valor: total.value,
        caixa_id: props.caixaId,
        descricao: `Venda ${numeroVenda}`,
        categoria: 'Vendas',
        atualizouCaixa: true,
        atualizouRelatorios: true
      }
    }))

    // Integração com Financeiro: Criar conta a receber se necessário
    if (formaPagamento.value === 'credito' && parcelasCredito.value > 1) {
      // Para vendas parceladas, criar contas a receber
      const valorParcela = total.value / parcelasCredito.value
      const hoje = new Date()
      
      for (let i = 0; i < parcelasCredito.value; i++) {
        const dataVencimento = new Date(hoje)
        dataVencimento.setMonth(hoje.getMonth() + i + 1)
        
        const { error: errorConta } = await supabase
          .from('contas_financeiras')
          .insert([{
            usuario_id: user.id,
            tipo: 'receber',
            descricao: `Venda ${numeroVenda} - Parcela ${i + 1}/${parcelasCredito.value}`,
            valor: valorParcela,
            data_vencimento: dataVencimento.toISOString().split('T')[0],
            status: 'pendente',
            categoria: 'Vendas'
          }])

        if (errorConta) {
          console.error('Erro ao criar conta a receber:', errorConta)
          // Não interrompe o fluxo, apenas registra o erro
        }
      }
    } else if (formaPagamento.value === 'vale') {
      // Para vendas com vale, criar conta a receber
      const dataVencimento = new Date()
      dataVencimento.setDate(dataVencimento.getDate() + 30) // 30 dias para pagamento
      
      const { error: errorConta } = await supabase
        .from('contas_financeiras')
        .insert([{
          usuario_id: user.id,
          tipo: 'receber',
          descricao: `Venda ${numeroVenda} - Vale/Convênio`,
          valor: total.value,
          data_vencimento: dataVencimento.toISOString().split('T')[0],
          status: 'pendente',
          categoria: 'Vendas'
        }])

      if (errorConta) {
        console.error('Erro ao criar conta a receber:', errorConta)
      }
    }

    window.dispatchEvent(new CustomEvent('conta-financeira-registrada', {
      detail: {
        origem: 'venda',
        venda_id: venda.id,
        numero_venda: numeroVenda,
        atualizouFinanceiro: formaPagamento.value === 'credito' || formaPagamento.value === 'vale'
      }
    }))

    // Atualizar pontos de fidelidade do cliente (se houver cliente)
    if (clienteSelecionado.value?.id) {
      // Calcular pontos: 1 ponto para cada R$ 10,00 em compras
      const pontosGanhos = Math.floor(total.value / 10)
      
      if (pontosGanhos > 0) {
        const { data: clienteAtual } = await supabase
          .from('clientes')
          .select('pontos_fidelidade')
          .eq('id', clienteSelecionado.value.id)
          .single()

        if (clienteAtual) {
          const novosPontos = (clienteAtual.pontos_fidelidade || 0) + pontosGanhos
          
          const { error: errorPontos } = await supabase
            .from('clientes')
            .update({ pontos_fidelidade: novosPontos })
            .eq('id', clienteSelecionado.value.id)

          if (errorPontos) {
            console.error('Erro ao atualizar pontos de fidelidade:', errorPontos)
          }
        }
      }
    }

    // Gerar cupom fiscal (simulado - pode ser expandido)
    gerarCupomFiscal(venda)

    // Limpar e reiniciar
    resetarCarrinho()
    
    // Emitir evento completo com informações de integração
    emit('venda-finalizada', {
      venda,
      atualizouEstoque: true,
      atualizouCaixa: true,
      atualizouFinanceiro: formaPagamento.value === 'credito' || formaPagamento.value === 'vale',
      atualizouCliente: !!clienteSelecionado.value?.id
    })
  } catch (err) {
    erro.value = 'Erro ao finalizar venda: ' + err.message
    console.error(err)
  } finally {
    processando.value = false
  }
}

function gerarCupomFiscal(venda) {
  // Abrir modal com cupom fiscal
  mostrarCupomFiscal.value = true
  vendaAtual.value = venda
  
  // Carregar itens da venda
  carregarItensVenda(venda.id)
}

async function carregarItensVenda(vendaId) {
  try {
    const { data, error } = await supabase
      .from('itens_venda')
      .select(`
        *,
        produtos (*)
      `)
      .eq('venda_id', vendaId)

    if (error) throw error
    
    // Formatar itens para o formato esperado pelo cupom
    itensVendaAtual.value = (data || []).map(item => ({
      ...item,
      produto: Array.isArray(item.produtos) ? item.produtos[0] : item.produtos
    }))
  } catch (err) {
    console.error('Erro ao carregar itens da venda:', err)
    itensVendaAtual.value = []
  }
}

function imprimirCupom() {
  window.print()
}

function fecharCupomFiscal() {
  mostrarCupomFiscal.value = false
  vendaAtual.value = null
  itensVendaAtual.value = []
}

function resetarCarrinho() {
  etapaAtual.value = 0
  itensCarrinho.value = []
  descontoGeral.value = 0
  formaPagamento.value = 'dinheiro'
  valorRecebido.value = 0
  parcelasCredito.value = 1
  pagamentoMistura.value = {
    dinheiro: 0,
    debito: 0,
    credito: 0,
    pix: 0
  }
  observacoesVenda.value = ''
  clienteSelecionado.value = null
  buscaCliente.value = ''
  buscaProduto.value = ''
  erro.value = ''
}

// Funções de cancelamento
function cancelarVenda() {
  mostrarModalCancelamento.value = true
}

function fecharModalCancelamento() {
  mostrarModalCancelamento.value = false
  justificativaCancelamento.value = ''
}

function confirmarCancelamento() {
  if (!justificativaCancelamento.value.trim()) {
    erro.value = 'Informe a justificativa do cancelamento'
    return
  }
  
  console.log('Venda cancelada. Justificativa:', justificativaCancelamento.value)
  resetarCarrinho()
  fecharModalCancelamento()
}

onMounted(() => {
  carregarOperador()
  atualizarDataHora()
  calcularTotal()
})
</script>

<style scoped>
.sistema-vendas {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 0.75rem;
}

/* Checkout Steps - Indicador Profissional */
.checkout-steps {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 2.5rem;
  padding: 1.5rem;
  background: white;
  border-radius: 1rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  position: relative;
}

.step-item {
  display: flex;
  align-items: center;
  flex: 1;
  position: relative;
}

.step-connector {
  position: absolute;
  left: -50%;
  top: 50%;
  width: 100%;
  height: 2px;
  background: #e5e7eb;
  z-index: 0;
  transform: translateY(-50%);
}

.step-item:first-child .step-connector {
  display: none;
}

.step-item.step-completed .step-connector {
  background: #10b981;
}

.step-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  position: relative;
  z-index: 1;
  flex: 1;
}

.step-icon-wrapper {
  position: relative;
  width: 3rem;
  height: 3rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: #f3f4f6;
  border: 2px solid #e5e7eb;
  transition: all 0.3s ease;
}

.step-icon {
  width: 1.5rem;
  height: 1.5rem;
  color: #9ca3af;
  transition: all 0.3s ease;
}

.step-check {
  position: absolute;
  top: -0.25rem;
  right: -0.25rem;
  width: 1.25rem;
  height: 1.25rem;
  background: #10b981;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px solid white;
}

.step-check-icon {
  width: 0.75rem;
  height: 0.75rem;
  color: white;
}

.step-item.step-active .step-icon-wrapper {
  background: #ea580c;
  border-color: #ea580c;
  box-shadow: 0 0 0 4px rgba(234, 88, 12, 0.1);
}

.step-item.step-active .step-icon {
  color: white;
}

.step-item.step-completed .step-icon-wrapper {
  background: #10b981;
  border-color: #10b981;
}

.step-item.step-completed .step-icon {
  color: white;
}

.step-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: #6b7280;
  text-align: center;
  transition: all 0.3s ease;
}

.step-item.step-active .step-label {
  color: #ea580c;
  font-weight: 600;
}

.step-item.step-completed .step-label {
  color: #10b981;
}

.step-item.step-pending .step-label {
  color: #9ca3af;
}

/* Checkout Stage */
.checkout-stage {
  animation: fadeIn 0.3s ease-out;
}

.stage-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 2rem;
}

.stage-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 0.5rem 0;
}

.stage-subtitle {
  font-size: 0.9375rem;
  color: #6b7280;
  margin: 0;
}

.checkout-card {
  background: white;
  border-radius: 1rem;
  padding: 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.info-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

.info-icon {
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
  border-radius: 0.5rem;
  color: #ea580c;
}

.info-content {
  flex: 1;
}

.info-label {
  font-size: 0.75rem;
  color: #6b7280;
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.info-value {
  font-size: 0.9375rem;
  color: #111827;
  font-weight: 600;
}

.form-section {
  margin-bottom: 2rem;
}

.form-section:last-child {
  margin-bottom: 0;
}

.input-group {
  display: flex;
  gap: 0.75rem;
  align-items: flex-start;
}

.input-wrapper {
  position: relative;
  flex: 1;
}

.input-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  width: 1.25rem;
  height: 1.25rem;
  color: #9ca3af;
  pointer-events: none;
}

.input-wrapper .form-input {
  padding-left: 2.75rem;
}

.search-results {
  margin-top: 0.75rem;
  border: 1px solid #e5e7eb;
  border-radius: 0.75rem;
  overflow: hidden;
  background: white;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.search-result-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem;
  cursor: pointer;
  transition: background-color 0.2s;
  border-bottom: 1px solid #f3f4f6;
}

.search-result-item:last-child {
  border-bottom: none;
}

.search-result-item:hover {
  background: #f9fafb;
}

.result-content {
  flex: 1;
}

.result-name {
  font-weight: 600;
  color: #111827;
  margin-bottom: 0.25rem;
}

.result-doc {
  font-size: 0.875rem;
  color: #6b7280;
}

.selected-client {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-top: 0.75rem;
  padding: 1rem;
  background: #d1fae5;
  border-radius: 0.75rem;
  border: 1px solid #a7f3d0;
}

.selected-label {
  font-size: 0.75rem;
  color: #065f46;
  font-weight: 500;
  margin-bottom: 0.25rem;
}

.selected-name {
  font-size: 0.9375rem;
  color: #065f46;
  font-weight: 600;
}

.stage-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #e5e7eb;
}

.btn-primary {
  background: #ea580c;
  color: white;
  border: none;
  font-weight: 600;
  transition: all 0.2s ease;
}

.btn-primary:hover:not(:disabled) {
  background: #c2410c;
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(234, 88, 12, 0.3);
}

.btn-large {
  padding: 0.875rem 2rem;
  font-size: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.alert-error {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem;
  background: #fee2e2;
  border: 1px solid #fecaca;
  border-radius: 0.75rem;
  color: #991b1b;
  margin-bottom: 1.5rem;
}

/* Conteúdo das Etapas */
.etapa-conteudo {
  animation: fadeIn 0.3s ease-out;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.etapa-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.etapa-header h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.etapa-descricao {
  color: #6b7280;
  margin-top: 0.5rem;
}

/* Card de Início */
.card-inicio {
  background: white;
  border-radius: 0.75rem;
  padding: 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.info-carrinho {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.info-label {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.info-valor {
  font-size: 1rem;
  color: #111827;
  font-weight: 600;
}

.busca-cliente {
  display: flex;
  gap: 0.5rem;
}

.resultados-cliente {
  margin-top: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 200px;
  overflow-y: auto;
}

.cliente-resultado {
  padding: 0.75rem;
  background: #f9fafb;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: background-color 0.2s;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.cliente-resultado:hover {
  background: #e5e7eb;
}

.cliente-selecionado {
  margin-top: 0.5rem;
  padding: 0.75rem;
  background: #d1fae5;
  border-radius: 0.5rem;
  color: #065f46;
  font-weight: 500;
}

/* Busca de Produtos */
.busca-produto-card {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin-bottom: 1.5rem;
}

.busca-produto {
  display: flex;
  gap: 0.75rem;
}

.busca-input {
  flex: 1;
  font-size: 1rem;
  padding: 0.75rem 1rem;
}

.resultados-busca {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-height: 300px;
  overflow-y: auto;
  margin-top: 1rem;
}

.produto-resultado {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 1rem;
  border-radius: 0.5rem;
  cursor: pointer;
  transition: background-color 0.2s;
  background: #f9fafb;
}

.produto-resultado:hover {
  background: #e5e7eb;
}

.produto-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.produto-info strong {
  font-weight: 600;
  color: #111827;
}

.produto-codigo {
  font-size: 0.875rem;
  color: #6b7280;
}

.produto-preco {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.25rem;
  font-weight: 600;
  color: #059669;
}

.estoque-disponivel {
  font-size: 0.75rem;
  font-weight: normal;
  color: #6b7280;
}

.sem-estoque {
  font-size: 0.75rem;
  color: #dc2626;
}

/* Carrinho */
.carrinho-section {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.carrinho-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.carrinho-header h4 {
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.carrinho-vazio {
  text-align: center;
  padding: 3rem 2rem;
  color: #6b7280;
}

.hint {
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

.itens-carrinho {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.item-carrinho {
  display: grid;
  grid-template-columns: 1fr auto auto;
  gap: 1rem;
  align-items: center;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.item-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.item-nome {
  font-weight: 600;
  color: #111827;
}

.item-detalhes {
  font-size: 0.875rem;
  color: #6b7280;
}

.item-observacoes {
  font-size: 0.75rem;
  color: #6366f1;
  font-style: italic;
  margin-top: 0.25rem;
}

.item-controles {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.input-quantidade {
  width: 60px;
  text-align: center;
  padding: 0.375rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
}

.item-subtotal {
  font-weight: 600;
  color: #059669;
  font-size: 1.125rem;
}

.resumo-venda {
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
  margin-bottom: 1rem;
}

.resumo-linha {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.resumo-linha.total {
  border-bottom: none;
  border-top: 2px solid #e5e7eb;
  margin-top: 0.5rem;
  padding-top: 1rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.valor-total {
  color: #059669;
  font-size: 1.5rem;
}

.input-desconto {
  width: 120px;
  text-align: right;
  padding: 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
}

.acoes-carrinho {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

/* Pagamento */
.resumo-pagamento {
  margin-bottom: 1.5rem;
}

.resumo-total-card {
  background: linear-gradient(135deg, #0ea5e9 0%, #3b82f6 100%);
  color: white;
  padding: 2rem;
  border-radius: 0.75rem;
  text-align: center;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.resumo-label {
  display: block;
  font-size: 1rem;
  margin-bottom: 0.5rem;
  opacity: 0.9;
}

.resumo-valor-grande {
  font-size: 2.5rem;
  font-weight: 700;
}

.formas-pagamento {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin-bottom: 1.5rem;
}

.botoes-pagamento {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 0.75rem;
  margin-top: 1rem;
}

.btn-pagamento {
  padding: 1rem;
  border: 2px solid #e5e7eb;
  background: white;
  border-radius: 0.5rem;
  font-weight: 500;
  transition: all 0.2s;
  cursor: pointer;
}

.btn-pagamento:hover {
  border-color: #0ea5e9;
  background: #eff6ff;
  transform: translateY(-2px);
}

.btn-pagamento-ativo {
  border-color: #0ea5e9;
  background: #0ea5e9;
  color: white;
}

.pagamento-dinheiro,
.pagamento-mistura,
.pagamento-credito {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin-bottom: 1.5rem;
}

.form-input-grande {
  font-size: 1.5rem;
  font-weight: 600;
  text-align: center;
  padding: 1rem;
}

.troco-info {
  margin-top: 1rem;
  padding: 1rem;
  background: #d1fae5;
  border-radius: 0.5rem;
  color: #065f46;
  font-weight: 600;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.troco-insuficiente {
  background: #fee2e2;
  color: #991b1b;
}

.troco-label {
  font-size: 1rem;
}

.troco-valor {
  font-size: 1.5rem;
}

.credito-group {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 0.5rem;
}

.resumo-mistura {
  margin-top: 1rem;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.diferenca-negativa {
  color: #dc2626;
  font-weight: 600;
}

.diferenca-positiva {
  color: #059669;
  font-weight: 600;
}

.acoes-pagamento {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

/* Finalização */
.resumo-final {
  background: white;
  border-radius: 0.75rem;
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  margin-bottom: 1.5rem;
}

.resumo-card h4 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 1rem 0;
  padding-bottom: 0.75rem;
  border-bottom: 2px solid #e5e7eb;
}

.resumo-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.resumo-item.total {
  border-bottom: none;
  border-top: 2px solid #e5e7eb;
  margin-top: 0.5rem;
  padding-top: 1rem;
  font-size: 1.125rem;
  font-weight: 600;
}

.acoes-finalizacao {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.btn-grande {
  padding: 1rem 2rem;
  font-size: 1.125rem;
  font-weight: 600;
}

/* Modais */
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

.modal-content {
  background: white;
  border-radius: 1rem;
  width: 100%;
  max-width: 500px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
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
  padding: 1.75rem 2rem;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.btn-close {
  background: #f3f4f6;
  border: none;
  cursor: pointer;
  color: #6b7280;
  line-height: 1;
  padding: 0.5rem;
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
}

.icone-btn {
  width: 1.25rem;
  height: 1.25rem;
}

.icone-header {
  width: 1.5rem;
  height: 1.5rem;
  margin-right: 0.5rem;
}

.icone-label {
  width: 1rem;
  height: 1rem;
  margin-right: 0.5rem;
}

.icone-pagamento {
  width: 1.25rem;
  height: 1.25rem;
  margin-right: 0.5rem;
}

.icone-check {
  width: 1rem;
  height: 1rem;
  margin-right: 0.25rem;
}

.icone-observacao {
  width: 0.875rem;
  height: 0.875rem;
  margin-right: 0.25rem;
  display: inline-block;
  vertical-align: middle;
}

.icone-input {
  width: 1.25rem;
  height: 1.25rem;
  color: #6b7280;
  position: absolute;
  left: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  pointer-events: none;
}

.header-com-icone {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.form-label-com-icone {
  display: flex;
  align-items: center;
}

.cliente-selecionado-texto {
  display: flex;
  align-items: center;
}

.input-wrapper-com-icone {
  position: relative;
  flex: 1;
}

.input-wrapper-com-icone .busca-input {
  padding-left: 2.75rem;
}

.btn-close:hover {
  background: #e5e7eb;
  color: #111827;
  transform: rotate(90deg);
}

.modal-body {
  padding: 2rem;
  overflow-y: auto;
  flex: 1;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.5rem 2rem;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
}

.modal-cupom .modal-content {
  max-width: 400px;
}

.modal-cupom-body {
  padding: 0;
  background: white;
}

.modal-acoes {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

/* Utilitários */
.form-group {
  margin-bottom: 1.5rem;
}

.form-label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.form-input,
.form-select,
.form-textarea {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #d1d5db;
  border-radius: 0.5rem;
  font-size: 1rem;
  transition: all 0.2s ease;
}

.form-input:focus,
.form-select:focus,
.form-textarea:focus {
  outline: none;
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
}

.form-hint {
  display: block;
  margin-top: 0.5rem;
  font-size: 0.75rem;
  color: #6b7280;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 0.9375rem;
}

.btn-primario {
  background: #0ea5e9;
  color: white;
}

.btn-primario:hover:not(:disabled) {
  background: #0284c7;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.btn-ghost {
  background: transparent;
  color: #6b7280;
  border: 1px solid #e5e7eb;
}

.btn-ghost:hover:not(:disabled) {
  background: #f9fafb;
  border-color: #d1d5db;
}

.btn-perigo {
  background: #ef4444;
  color: white;
}

.btn-perigo:hover:not(:disabled) {
  background: #dc2626;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-sm {
  padding: 0.375rem 0.75rem;
  font-size: 0.875rem;
}

.alert {
  padding: 1rem;
  border-radius: 0.5rem;
  margin-bottom: 1rem;
}

.alert-erro {
  background: #fee2e2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

/* Cart Section */
.cart-section {
  margin-top: 1.5rem;
}

.cart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

.section-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.empty-cart {
  text-align: center;
  padding: 3rem 2rem;
}

.empty-cart-text {
  font-size: 1rem;
  color: #6b7280;
  margin: 1rem 0 0.5rem 0;
  font-weight: 500;
}

.empty-cart-hint {
  font-size: 0.875rem;
  color: #9ca3af;
}

.cart-items {
  display: flex;
  flex-direction: column;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.cart-item {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 1.25rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
  transition: all 0.2s;
}

.cart-item:hover {
  background: #ffffff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.cart-item-info {
  flex: 1;
  min-width: 0;
}

.cart-item-name {
  font-weight: 600;
  color: #111827;
  margin-bottom: 0.5rem;
}

.cart-item-details {
  font-size: 0.875rem;
  color: #6b7280;
}

.cart-item-notes {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 0.5rem;
  font-size: 0.8125rem;
  color: #6366f1;
  font-style: italic;
}

.cart-item-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.quantity-controls {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  padding: 0.25rem;
}

.qty-btn {
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border: none;
  background: transparent;
  color: #6b7280;
  cursor: pointer;
  border-radius: 0.375rem;
  transition: all 0.2s;
}

.qty-btn:hover:not(:disabled) {
  background: #f3f4f6;
  color: #111827;
}

.qty-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.qty-input {
  width: 3rem;
  text-align: center;
  border: none;
  background: transparent;
  font-weight: 600;
  color: #111827;
  font-size: 0.9375rem;
}

.item-actions {
  display: flex;
  gap: 0.5rem;
}

.action-btn {
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e5e7eb;
  background: white;
  color: #6b7280;
  cursor: pointer;
  border-radius: 0.375rem;
  transition: all 0.2s;
}

.action-btn:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
  color: #111827;
}

.action-btn-danger {
  color: #dc2626;
  border-color: #fecaca;
}

.action-btn-danger:hover {
  background: #fee2e2;
  border-color: #fca5a5;
}

.cart-item-price {
  font-size: 1.125rem;
  font-weight: 600;
  color: #059669;
  min-width: 100px;
  text-align: right;
}

.cart-summary {
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid #e5e7eb;
}

.summary-row:last-child {
  border-bottom: none;
}

.summary-row.summary-total {
  border-top: 2px solid #e5e7eb;
  margin-top: 0.5rem;
  padding-top: 1rem;
  font-size: 1.125rem;
  font-weight: 600;
}

.total-value {
  font-size: 1.5rem;
  color: #059669;
}

.discount-input {
  width: 120px;
  text-align: right;
  padding: 0.5rem;
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
  font-size: 0.9375rem;
}

/* Review Section */
.review-section {
  margin-bottom: 2rem;
}

.items-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.review-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.5rem;
}

.review-item-name {
  font-weight: 600;
  color: #111827;
  margin-bottom: 0.25rem;
}

.review-item-details {
  font-size: 0.875rem;
  color: #6b7280;
}

.review-item-price {
  font-weight: 600;
  color: #059669;
}

.summary-section {
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

/* Payment Section */
.total-display {
  text-align: center;
  padding: 2rem;
  background: linear-gradient(135deg, #ea580c 0%, #c2410c 100%);
  color: white;
  border-radius: 1rem;
  margin-bottom: 2rem;
}

.total-label {
  font-size: 0.9375rem;
  opacity: 0.9;
  margin-bottom: 0.5rem;
}

.total-amount {
  font-size: 2.5rem;
  font-weight: 700;
}

.payment-methods {
  margin-bottom: 2rem;
}

.payment-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 0.75rem;
  margin-top: 1rem;
}

.payment-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 1.25rem 1rem;
  border: 2px solid #e5e7eb;
  background: white;
  border-radius: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
  font-weight: 500;
  color: #374151;
}

.payment-option:hover {
  border-color: #ea580c;
  background: #fff7ed;
  transform: translateY(-2px);
  box-shadow: 0 4px 6px -1px rgba(234, 88, 12, 0.1);
}

.payment-option-active {
  border-color: #ea580c;
  background: #ea580c;
  color: white;
}

.payment-icon {
  width: 1.75rem;
  height: 1.75rem;
}

.payment-form {
  margin-top: 1.5rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

.form-input-large {
  font-size: 1.5rem;
  font-weight: 600;
  text-align: center;
  padding: 1rem;
}

.change-display {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-radius: 0.5rem;
  margin-top: 1rem;
  font-weight: 600;
}

.change-positive {
  background: #d1fae5;
  color: #065f46;
}

.change-negative {
  background: #fee2e2;
  color: #991b1b;
}

.change-value {
  font-size: 1.25rem;
}

/* Confirmation Section */
.confirmation-summary {
  margin-bottom: 2rem;
}

.summary-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 1.5rem;
}

.summary-item {
  padding: 1rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

.summary-item-total {
  grid-column: 1 / -1;
  background: linear-gradient(135deg, #f9fafb 0%, #f3f4f6 100%);
  border: 2px solid #e5e7eb;
}

.summary-label {
  font-size: 0.75rem;
  color: #6b7280;
  font-weight: 500;
  margin-bottom: 0.5rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.summary-value {
  font-size: 1.125rem;
  color: #111827;
  font-weight: 600;
}

.summary-value-total {
  font-size: 1.75rem;
  color: #059669;
}

.search-section {
  margin-bottom: 1.5rem;
}

.mixed-payment-summary {
  margin-top: 1.5rem;
  padding: 1.5rem;
  background: #f9fafb;
  border-radius: 0.75rem;
  border: 1px solid #e5e7eb;
}

.form-hint {
  display: block;
  margin-top: 0.5rem;
  font-size: 0.75rem;
  color: #6b7280;
}

.spinner {
  width: 1.25rem;
  height: 1.25rem;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (max-width: 768px) {
  .checkout-steps {
    flex-direction: column;
    gap: 1rem;
  }

  .step-connector {
    display: none;
  }

  .checkout-card {
    padding: 1.5rem;
  }

  .cart-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 1rem;
  }

  .cart-item-controls {
    width: 100%;
    justify-content: space-between;
  }

  .cart-item-price {
    width: 100%;
    text-align: left;
    margin-top: 0.5rem;
  }

  .payment-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .info-grid {
    grid-template-columns: 1fr;
  }

  .summary-grid {
    grid-template-columns: 1fr;
  }

  .stage-actions {
    flex-direction: column-reverse;
  }

  .stage-actions .btn {
    width: 100%;
  }
}
</style>
