<template>
  <div v-if="mostrar" class="modal-overlay" @click.self="cancelar">
    <div class="modal-content modal-confirmacao">
      <div class="modal-header">
        <div class="modal-icon-wrapper" :class="tipoIcone">
          <component :is="iconeComponente" class="modal-icon" />
        </div>
        <h3>{{ titulo }}</h3>
      </div>
      <div class="modal-body">
        <p>{{ mensagem }}</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-ghost" @click="cancelar">
          {{ textoCancelar }}
        </button>
        <button 
          type="button" 
          class="btn" 
          :class="classeBotaoConfirmar"
          @click="confirmar"
        >
          {{ textoConfirmar }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { 
  ExclamationTriangleIcon,
  TrashIcon,
  InformationCircleIcon,
  CheckCircleIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  mostrar: {
    type: Boolean,
    default: false
  },
  titulo: {
    type: String,
    default: 'Confirmar ação'
  },
  mensagem: {
    type: String,
    required: true
  },
  textoConfirmar: {
    type: String,
    default: 'Confirmar'
  },
  textoCancelar: {
    type: String,
    default: 'Cancelar'
  },
  tipo: {
    type: String,
    default: 'warning', // warning, danger, info, success
    validator: (value) => ['warning', 'danger', 'info', 'success'].includes(value)
  }
})

const emit = defineEmits(['confirmar', 'cancelar', 'fechar'])

const iconeComponente = computed(() => {
  switch (props.tipo) {
    case 'danger':
      return TrashIcon
    case 'info':
      return InformationCircleIcon
    case 'success':
      return CheckCircleIcon
    default:
      return ExclamationTriangleIcon
  }
})

const tipoIcone = computed(() => {
  return `icon-${props.tipo}`
})

const classeBotaoConfirmar = computed(() => {
  switch (props.tipo) {
    case 'danger':
      return 'btn-perigo'
    case 'success':
      return 'btn-primary'
    default:
      return 'btn-primario'
  }
})

function confirmar() {
  emit('confirmar')
  emit('fechar')
}

function cancelar() {
  emit('cancelar')
  emit('fechar')
}
</script>

<style scoped>
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

@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

.modal-content {
  background: white;
  border-radius: 1rem;
  width: 100%;
  max-width: 450px;
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

.modal-confirmacao .modal-header {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2rem 2rem 1rem;
  text-align: center;
}

.modal-icon-wrapper {
  width: 4rem;
  height: 4rem;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  animation: scaleIn 0.3s ease-out;
}

@keyframes scaleIn {
  from {
    transform: scale(0);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

.modal-icon {
  width: 2rem;
  height: 2rem;
}

  .icon-warning {
    background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
    color: #d97706;
  }

  .icon-danger {
    background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
    color: #dc2626;
  }

  .icon-info {
    background: linear-gradient(135deg, #ffedd5 0%, #fed7aa 100%);
    color: #ea580c;
  }

  .icon-success {
    background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
    color: #059669;
  }

.modal-confirmacao .modal-header h3 {
    font-size: 1.5rem;
    font-weight: 700;
    color: #111827;
    margin: 0;
  }

.modal-confirmacao .modal-body {
  padding: 0 2rem 1.5rem;
  text-align: center;
}

.modal-confirmacao .modal-body p {
    font-size: 0.9375rem;
    color: #4b5563;
    line-height: 1.6;
    margin: 0;
    font-weight: 400;
  }

.modal-confirmacao .modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.5rem 2rem;
  border-top: 1px solid #e5e7eb;
  background: #f9fafb;
  border-bottom-left-radius: 1rem;
  border-bottom-right-radius: 1rem;
}

@media (max-width: 768px) {
  .modal-content {
    max-width: 100%;
    border-radius: 1rem 1rem 0 0;
  }

  .modal-confirmacao .modal-header {
    padding: 1.5rem 1.5rem 1rem;
  }

  .modal-confirmacao .modal-body {
    padding: 0 1.5rem 1rem;
  }

  .modal-confirmacao .modal-footer {
    padding: 1.25rem 1.5rem;
  }
}
</style>
