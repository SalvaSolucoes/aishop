<template>
  <div class="modal-overlay" @click.self="fechar">
    <div class="modal-content">
      <div class="modal-header">
        <h3>Histórico do Cliente</h3>
        <button class="btn-close" @click="fechar">×</button>
      </div>

      <div class="modal-body">
        <div v-if="carregando" class="text-center" style="padding: 2rem;">
          Carregando histórico...
        </div>

        <div v-else>
          <div class="info-cliente">
            <strong>{{ cliente.nome }}</strong>
            <br>
            <span v-if="cliente.email">{{ cliente.email }}</span>
          </div>

          <div v-if="historico.length === 0" class="text-center" style="padding: 2rem;">
            <p style="color: #6b7280;">Nenhuma compra registrada para este cliente.</p>
          </div>

          <div v-else class="historico-lista">
            <div v-for="venda in historico" :key="venda.id" class="historico-item">
              <div class="historico-header">
                <div class="historico-data">{{ formatarDataHora(venda.created_at) }}</div>
                <div class="historico-valor">{{ formatarMoeda(venda.total) }}</div>
              </div>
              <div class="historico-info">
                <div class="historico-tipo">
                  <span class="badge badge-venda">Venda {{ venda.numero_venda }}</span>
                  <span class="badge badge-pagamento">{{ formatarFormaPagamento(venda.forma_pagamento) }}</span>
                </div>
                <div v-if="venda.observacoes" class="historico-descricao">
                  {{ venda.observacoes }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" @click="fechar">
          Fechar
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/servicos/supabase'
import { formatarDataHora, formatarMoeda } from '@/utils/formatadores'

const props = defineProps({
  cliente: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['fechar'])

const historico = ref([])
const carregando = ref(false)

async function carregarHistorico() {
  carregando.value = true

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Carregar histórico de vendas do cliente
    const { data, error } = await supabase
      .from('vendas')
      .select('*')
      .eq('usuario_id', user.id)
      .eq('cliente_id', props.cliente.id)
      .order('created_at', { ascending: false })
      .limit(50)

    if (error) throw error
    historico.value = data || []
  } catch (error) {
    console.error('Erro ao carregar histórico:', error)
    historico.value = []
  } finally {
    carregando.value = false
  }
}

function formatarFormaPagamento(forma) {
  const formas = {
    dinheiro: 'Dinheiro',
    debito: 'Débito',
    credito: 'Crédito',
    pix: 'Pix',
    vale: 'Vale/Convênio',
    mistura: 'Misto'
  }
  return formas[forma] || forma
}

function fechar() {
  emit('fechar')
}

onMounted(() => {
  carregarHistorico()
})
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: white;
  border-radius: 0.5rem;
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  box-shadow: var(--sombra-lg);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid var(--cor-borda);
}

.modal-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: var(--cor-texto);
}

.btn-close {
  background: none;
  border: none;
  font-size: 2rem;
  cursor: pointer;
  color: var(--cor-texto-secundario);
  line-height: 1;
  padding: 0;
  width: 2rem;
  height: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.btn-close:hover {
  color: var(--cor-texto);
}

.modal-body {
  padding: 1.5rem;
  overflow-y: auto;
  flex: 1;
}

.info-cliente {
  background-color: var(--cor-fundo);
  padding: 1rem;
  border-radius: 0.375rem;
  margin-bottom: 1.5rem;
}

.historico-lista {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.historico-item {
  padding: 1rem;
  border: 1px solid #e5e7eb;
  border-radius: 0.5rem;
  background: #f9fafb;
  transition: all 0.2s;
}

.historico-item:hover {
  background: #ffffff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.historico-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.historico-data {
  font-size: 0.875rem;
  color: #6b7280;
}

.historico-valor {
  font-size: 1.125rem;
  font-weight: 600;
  color: #059669;
}

.historico-info {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.historico-tipo {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.badge {
  display: inline-flex;
  align-items: center;
  padding: 0.25rem 0.75rem;
  border-radius: 0.375rem;
  font-size: 0.75rem;
  font-weight: 500;
}

.badge-venda {
  background: #dbeafe;
  color: #1e40af;
}

.badge-pagamento {
  background: #f3f4f6;
  color: #374151;
}

.historico-descricao {
  color: #6b7280;
  font-size: 0.875rem;
  font-style: italic;
}

.text-center {
  text-align: center;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.5rem;
  border-top: 1px solid var(--cor-borda);
}
</style>
