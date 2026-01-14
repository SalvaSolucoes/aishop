<template>
  <Transition name="toast">
    <div v-if="mostrar" class="toast-container" :class="tipoClasse">
      <div class="toast-icon-wrapper">
        <component :is="iconeComponente" class="toast-icon" />
      </div>
      <div class="toast-content">
        <p class="toast-message">{{ mensagem }}</p>
      </div>
      <button class="toast-close" @click="fechar" aria-label="Fechar">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  </Transition>
</template>

<script setup>
import { computed, onMounted, watch } from 'vue'
import { 
  CheckCircleIcon,
  ExclamationCircleIcon,
  InformationCircleIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'

const props = defineProps({
  mostrar: {
    type: Boolean,
    default: false
  },
  mensagem: {
    type: String,
    required: true
  },
  tipo: {
    type: String,
    default: 'success', // success, error, warning, info
    validator: (value) => ['success', 'error', 'warning', 'info'].includes(value)
  },
  duracao: {
    type: Number,
    default: 4000 // milissegundos
  }
})

const emit = defineEmits(['fechar'])

const iconeComponente = computed(() => {
  switch (props.tipo) {
    case 'error':
      return XCircleIcon
    case 'warning':
      return ExclamationCircleIcon
    case 'info':
      return InformationCircleIcon
    default:
      return CheckCircleIcon
  }
})

const tipoClasse = computed(() => {
  return `toast-${props.tipo}`
})

let timeoutId = null

function fechar() {
  if (timeoutId) {
    clearTimeout(timeoutId)
    timeoutId = null
  }
  emit('fechar')
}

watch(() => props.mostrar, (novoValor) => {
  if (novoValor) {
    if (timeoutId) {
      clearTimeout(timeoutId)
    }
    timeoutId = setTimeout(() => {
      fechar()
    }, props.duracao)
  } else {
    if (timeoutId) {
      clearTimeout(timeoutId)
      timeoutId = null
    }
  }
})

onMounted(() => {
  if (props.mostrar) {
    timeoutId = setTimeout(() => {
      fechar()
    }, props.duracao)
  }
})
</script>

<style scoped>
.toast-container {
  position: fixed;
  bottom: 1.5rem;
  right: 1.5rem;
  min-width: 320px;
  max-width: 420px;
  background: white;
  border-radius: 0.75rem;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem 1.25rem;
  z-index: 9999;
  border-left: 4px solid;
  animation: slideInRight 0.3s ease-out;
}

@keyframes slideInRight {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.toast-success {
  border-left-color: #10b981;
}

.toast-error {
  border-left-color: #ef4444;
}

.toast-warning {
  border-left-color: #f59e0b;
}

.toast-info {
  border-left-color: #ea580c;
}

.toast-icon-wrapper {
  flex-shrink: 0;
  width: 2.5rem;
  height: 2.5rem;
  border-radius: 0.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
}

.toast-success .toast-icon-wrapper {
  background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%);
  color: #059669;
}

.toast-error .toast-icon-wrapper {
  background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
  color: #dc2626;
}

.toast-warning .toast-icon-wrapper {
  background: linear-gradient(135deg, #fef3c7 0%, #fde68a 100%);
  color: #d97706;
}

.toast-info .toast-icon-wrapper {
  background: linear-gradient(135deg, #ffedd5 0%, #fed7aa 100%);
  color: #ea580c;
}

.toast-icon {
  width: 1.5rem;
  height: 1.5rem;
}

.toast-content {
  flex: 1;
  min-width: 0;
}

.toast-message {
  margin: 0;
  font-size: 0.9375rem;
  font-weight: 500;
  color: #111827;
  line-height: 1.5;
}

.toast-close {
  flex-shrink: 0;
  background: none;
  border: none;
  cursor: pointer;
  color: #9ca3af;
  line-height: 1;
  padding: 0.25rem;
  width: 1.75rem;
  height: 1.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 0.375rem;
  transition: all 0.2s ease;
}

.toast-close:hover {
  background-color: #f3f4f6;
  color: #111827;
}

/* Transições */
.toast-enter-active {
  transition: all 0.3s ease-out;
}

.toast-leave-active {
  transition: all 0.3s ease-in;
}

.toast-enter-from {
  transform: translateX(100%);
  opacity: 0;
}

.toast-leave-to {
  transform: translateX(100%);
  opacity: 0;
}

@media (max-width: 640px) {
  .toast-container {
    bottom: 1rem;
    right: 1rem;
    left: 1rem;
    min-width: auto;
    max-width: none;
  }
}
</style>
