<template>
  <div class="caixa-view">
    <div class="view-header">
      <div class="header-acoes">
        <button
          v-if="!caixaAberto"
          class="btn btn-primario"
          @click="abrirCaixa"
        >
          Abrir Caixa
        </button>
        <button
          v-else
          class="btn btn-perigo"
          @click="fecharCaixa"
        >
          Fechar Caixa
        </button>
      </div>
    </div>

    <div v-if="erro" class="alert alert-erro">
      {{ erro }}
    </div>

    <!-- Toast de Sucesso -->
    <Toast
      :mostrar="mostrarToast"
      :mensagem="mensagemToast"
      tipo="success"
      :duracao="3000"
      @fechar="mostrarToast = false"
    />

    <div v-if="!caixaAberto" class="empty-caixa-state animate-fade-in">
      <div class="empty-caixa-content">
        <div class="empty-caixa-icon caixa-fechado">
          <CurrencyDollarIcon class="h-16 w-16" />
        </div>
        <h3 class="caixa-fechado-texto">Caixa Fechado</h3>
        <p>Abra o caixa para começar a realizar vendas</p>
      </div>
    </div>

    <!-- Modal para Abrir Caixa -->
    <div v-if="mostrarModalAbrirCaixa" class="modal-overlay" @click.self="fecharModalAbrirCaixa">
      <div class="modal-content modal-abrir-caixa">
        <div class="modal-header">
          <h3>Abrir Caixa</h3>
          <button class="btn-close" @click="fecharModalAbrirCaixa">×</button>
        </div>
        <form @submit.prevent="confirmarAbrirCaixa" class="modal-body">
          <div v-if="erroAbrirCaixa" class="alert alert-erro">
            {{ erroAbrirCaixa }}
          </div>
          <div class="form-section">
            <div class="form-group">
              <label class="form-label">Valor Inicial</label>
              <div class="input-wrapper">
                <span class="input-prefix">R$</span>
                <input
                  ref="inputValorInicial"
                  v-model.number="valorInicialInput"
                  type="number"
                  class="form-input form-input-money"
                  required
                  min="0"
                  step="0.01"
                  placeholder="0,00"
                  autofocus
                />
              </div>
              <small class="form-hint">Informe o valor em dinheiro disponível no caixa</small>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-ghost" @click="fecharModalAbrirCaixa">
              Cancelar
            </button>
            <button type="submit" class="btn btn-primario" :disabled="valorInicialInput === null || valorInicialInput === undefined || isNaN(valorInicialInput) || valorInicialInput < 0">
              Abrir Caixa
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Sistema de Vendas -->
    <div v-if="caixaAberto" class="view-section animate-slide-up">
      <SistemaVendas
        :caixa-id="caixaAtual.id"
        @venda-finalizada="onVendaFinalizada"
      />
    </div>

    <!-- Modal de Fechar Caixa -->
    <ModalFecharCaixa
      v-if="mostrarModalFecharCaixa"
      :caixa="caixaAtual"
      :movimentacoes="[]"
      @fechar="mostrarModalFecharCaixa = false"
      @fechado="onCaixaFechado"
    />

    <!-- Modal de Confirmação -->
    <ModalConfirmacao
      :mostrar="mostrarModalConfirmacao"
      :titulo="tituloConfirmacao"
      :mensagem="mensagemConfirmacao"
      :tipo="tipoConfirmacao"
      texto-confirmar="Confirmar"
      texto-cancelar="Cancelar"
      @confirmar="executarConfirmacao"
      @cancelar="cancelarConfirmacao"
      @fechar="mostrarModalConfirmacao = false"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarMoeda } from '@/utils/formatadores'
import { CurrencyDollarIcon } from '@heroicons/vue/24/outline'
import ModalConfirmacao from '@/componentes/ModalConfirmacao.vue'
import Toast from '@/componentes/Toast.vue'
import SistemaVendas from './SistemaVendas.vue'
import ModalFecharCaixa from './ModalFecharCaixa.vue'
import { 
  caixaAberto, 
  caixaAtual, 
  carregando,
  erro,
  verificarCaixaAberto, 
  abrirCaixa, 
  fecharCaixa as fecharCaixaService,
  refreshCaixaState
} from '@/stores/caixa'

const mostrarModalAbrirCaixa = ref(false)
const valorInicialInput = ref(0)
const erroAbrirCaixa = ref('')
const inputValorInicial = ref(null)
const mostrarModalConfirmacao = ref(false)
const tituloConfirmacao = ref('')
const mensagemConfirmacao = ref('')
const tipoConfirmacao = ref('warning')
const callbackConfirmacao = ref(null)
const mostrarToast = ref(false)
const mensagemToast = ref('')
const mostrarModalFecharCaixa = ref(false)

// Using imported function from caixa store
// async function verificarCaixaAberto() { ... }

function abrirCaixa() {
  mostrarModalAbrirCaixa.value = true
  valorInicialInput.value = 0
  erroAbrirCaixa.value = ''
  // Focar no input após o modal aparecer
  setTimeout(() => {
    if (inputValorInicial.value) {
      inputValorInicial.value.focus()
    }
  }, 100)
}

function fecharModalAbrirCaixa() {
  mostrarModalAbrirCaixa.value = false
  valorInicialInput.value = 0
  erroAbrirCaixa.value = ''
}

async function confirmarAbrirCaixa() {
  erroAbrirCaixa.value = ''
  erro.value = ''

  if (valorInicialInput.value === null || valorInicialInput.value === undefined || isNaN(valorInicialInput.value) || valorInicialInput.value < 0) {
    erroAbrirCaixa.value = 'Valor inicial inválido. Informe um valor maior ou igual a zero.'
    return
  }

  try {
    await abrirCaixa(valorInicialInput.value)
    mostrarMensagemSucesso('Caixa aberto com sucesso!')
    fecharModalAbrirCaixa()
  } catch (err) {
    erroAbrirCaixa.value = err.message
    console.error(err)
  }
}

function fecharCaixa() {
  mostrarModalFecharCaixa.value = true
}

async function onCaixaFechado() {
  mostrarMensagemSucesso('Caixa fechado com sucesso!')
  mostrarModalFecharCaixa.value = false
  // State is managed by the store
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
}

function cancelarConfirmacao() {
  callbackConfirmacao.value = null
}

function mostrarMensagemSucesso(mensagem) {
  mensagemToast.value = mensagem
  mostrarToast.value = true
}

function onVendaFinalizada(dados) {
  const venda = dados.venda || dados
  let mensagem = `Venda ${venda.numero_venda} finalizada com sucesso!`
  
  // Adicionar informações sobre integrações realizadas
  const integracoes = []
  if (dados.atualizouEstoque) integracoes.push('Estoque atualizado')
  if (dados.atualizouCaixa) integracoes.push('Caixa atualizado')
  if (dados.atualizouFinanceiro) integracoes.push('Financeiro atualizado')
  if (dados.atualizouCliente) integracoes.push('Histórico do cliente atualizado')
  
  if (integracoes.length > 0) {
    mensagem += `\n${integracoes.join(', ')}.`
  }
  
  mostrarMensagemSucesso(mensagem)
  
  // Disparar evento customizado para outros componentes ouvirem
  window.dispatchEvent(new CustomEvent('venda-finalizada', {
    detail: dados
  }))
}

onMounted(async () => {
  await refreshCaixaState()
})
</script>

<style scoped>
.view-header {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  margin-bottom: 1.5rem;
}

/* Animações */
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

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideInRight {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.animate-fade-in {
  animation: fadeIn 0.5s ease-out forwards;
  opacity: 0;
}

.animate-slide-up {
  animation: slideUp 0.5s ease-out forwards;
  opacity: 0;
}

.table-row-animate {
  animation: slideInRight 0.4s ease-out forwards;
  opacity: 0;
}

/* Modal para Abrir Caixa */
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
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
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

.modal-abrir-caixa {
  max-width: 450px;
  width: 100%;
}

.modal-abrir-caixa .modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.75rem 2rem;
  border-bottom: 1px solid #e5e7eb;
  background: linear-gradient(to right, #f9fafb, #ffffff);
}

.modal-abrir-caixa .modal-header h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.modal-abrir-caixa .btn-close {
  background: #f3f4f6;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #6b7280;
  line-height: 1;
  padding: 0;
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.5rem;
  transition: all 0.2s ease;
}

.modal-abrir-caixa .btn-close:hover {
  background: #e5e7eb;
  color: #111827;
  transform: rotate(90deg);
}

.modal-abrir-caixa .modal-body {
  padding: 2rem;
}

.modal-abrir-caixa .modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
  padding-left: 2rem;
  padding-right: 2rem;
  padding-bottom: 1.5rem;
  border-bottom-left-radius: 1rem;
  border-bottom-right-radius: 1rem;
}

.input-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.input-prefix {
  position: absolute;
  left: 1rem;
  font-weight: 600;
  color: #6b7280;
  font-size: 0.875rem;
  z-index: 1;
}

.form-input-money {
  padding-left: 3rem !important;
  font-size: 1.125rem;
  font-weight: 600;
  text-align: right;
}

.form-hint {
  display: block;
  margin-top: 0.5rem;
  font-size: 0.75rem;
  color: #6b7280;
}

/* Estado vazio quando caixa fechado */
.empty-caixa-state {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 300px;
  margin-bottom: 2rem;
}

.empty-caixa-content {
  text-align: center;
  padding: 3rem 2rem;
  max-width: 400px;
}

.empty-caixa-icon {
  margin-bottom: 1.5rem;
  animation: pulse 2s ease-in-out infinite;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.3s ease;
}

.empty-caixa-icon.caixa-fechado {
  color: #ef4444;
}

.empty-caixa-content h3.caixa-fechado-texto {
  color: #ef4444;
}


@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.1);
  }
}

.empty-caixa-content h3 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin-bottom: 0.5rem;
}

.empty-caixa-content p {
  font-size: 1rem;
  color: #6b7280;
  margin: 0;
}


.view-section {
  margin-bottom: 2rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.25rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.section-header h3 {
  font-size: 1.375rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.form-input-filter {
  max-width: 200px;
  transition: all 0.2s ease;
}

.form-input-filter:focus {
  transform: translateY(-1px);
  box-shadow: 0 4px 6px -1px rgba(14, 165, 233, 0.1), 0 2px 4px -1px rgba(14, 165, 233, 0.06);
}

.card-form {
  transition: all 0.3s ease;
}

.card-form:hover {
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
}

.card-table {
  overflow: hidden;
}

.form-movimentacao {
  max-width: 650px;
  padding: 2rem;
}

.form-movimentacao .form-group {
  margin-bottom: 1.75rem;
  position: relative;
}

.form-movimentacao .form-group:last-of-type {
  margin-bottom: 0;
}

.form-section {
  padding: 1.5rem;
  border-bottom: 1px solid #f3f4f6;
}

.form-section:last-of-type {
  border-bottom: none;
}

.section-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin: 0 0 1.25rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.form-movimentacao .form-label {
  display: block;
  font-size: 0.8125rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
  letter-spacing: -0.01em;
  transition: color 0.2s ease;
}

.form-movimentacao .form-group:focus-within .form-label {
  color: #0ea5e9;
}

.form-movimentacao .form-label:has(+ input[required]),
.form-movimentacao .form-label:has(+ select[required]) {
  position: relative;
}

.form-movimentacao .form-label:has(+ input[required])::after,
.form-movimentacao .form-label:has(+ select[required])::after {
  content: '*';
  color: #ef4444;
  margin-left: 0.25rem;
  font-weight: 600;
}

.form-movimentacao .form-input,
.form-movimentacao .form-select {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  border-width: 1.5px;
}

.form-movimentacao .form-input:focus,
.form-movimentacao .form-select:focus {
  border-color: #ea580c;
  box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.1);
}

.form-movimentacao .form-row {
  gap: 1.5rem;
}

.form-movimentacao .btn-primario {
  margin-top: 1.5rem;
  width: 100%;
  padding: 0.875rem 1.5rem;
  font-weight: 600;
  font-size: 0.9375rem;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
}

.form-movimentacao .btn-primario::before {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 0;
  height: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.3);
  transform: translate(-50%, -50%);
  transition: width 0.6s, height 0.6s;
}

.form-movimentacao .btn-primario:hover::before {
  width: 300px;
  height: 300px;
}

.form-movimentacao .btn-primario:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px -5px rgba(14, 165, 233, 0.4), 0 4px 6px -2px rgba(14, 165, 233, 0.3);
}

.form-movimentacao .btn-primario:active {
  transform: translateY(0);
}

.valor-positivo {
  color: #10b981;
  font-weight: 600;
}

.valor-negativo {
  color: #ef4444;
  font-weight: 600;
}

.text-center {
  text-align: center;
}

/* Tabela com animações */
.tabela {
  width: 100%;
  border-collapse: collapse;
}

.tabela thead {
  background-color: #f9fafb;
}

.tabela th {
  padding: 0.75rem 1.5rem;
  text-align: left;
  font-size: 0.75rem;
  font-weight: 600;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 2px solid #e5e7eb;
}

.tabela tbody tr {
  transition: all 0.2s ease;
  border-bottom: 1px solid #e5e7eb;
}

.tabela tbody tr:last-child {
  border-bottom: none;
}

.tabela tbody tr:hover {
  background-color: #f9fafb;
  transform: scale(1.005);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.tabela tbody td {
  padding: 1rem 1.5rem;
  font-size: 0.875rem;
  color: #374151;
  transition: color 0.2s ease;
}

.tabela tbody tr:hover td {
  color: #111827;
}

.tabela-caixa th,
.tabela-caixa td {
  text-align: center;
}

/* Badges animados */
.badge {
  transition: all 0.2s ease;
  display: inline-block;
}

.badge:hover {
  transform: scale(1.05);
}

/* Alertas com animação */
.alert {
  animation: slideUp 0.4s ease-out;
  margin-bottom: 1.5rem;
}

</style>
