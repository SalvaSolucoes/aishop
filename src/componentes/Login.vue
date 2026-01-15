<template>
  <div class="min-h-screen flex items-center justify-center bg-gray-50 px-4 py-12">
    <div class="w-full max-w-md">
      <div class="card">
        <div class="card-body p-8">
          <!-- Header -->
          <div class="text-center mb-8">
            <div class="mx-auto mb-4 flex justify-center">
              <img src="/AIShopLogo.png" alt="AIShop Logo" class="h-16 w-auto object-contain" />
            </div>
            <h1 class="text-2xl font-semibold text-gray-900 mb-1">AIShop</h1>
            <p class="text-sm text-gray-600">Sistema de Gestão Empresarial</p>
          </div>

          <!-- Formulário -->
          <form @submit.prevent="fazerLogin" class="login-form">
            <div v-if="erro" class="alert alert-danger">
              <ExclamationCircleIcon class="h-5 w-5 flex-shrink-0 mt-0.5" />
              <span>{{ erro }}</span>
            </div>

            <div class="form-group">
              <label for="email" class="form-label">E-mail</label>
              <input
                id="email"
                v-model="email"
                type="email"
                class="form-input"
                required
                placeholder="seu@email.com"
                :disabled="carregando"
                autocomplete="email"
              />
            </div>

            <div class="form-group">
              <label for="senha" class="form-label">Senha</label>
              <input
                id="senha"
                v-model="senha"
                type="password"
                class="form-input"
                required
                placeholder="Digite sua senha"
                :disabled="carregando"
                autocomplete="current-password"
              />
            </div>

            <button
              type="submit"
              class="btn btn-primary w-full btn-lg"
              :disabled="carregando"
            >
              <span v-if="carregando" class="spinner h-5 w-5"></span>
              <span>{{ carregando ? 'Entrando...' : 'Entrar' }}</span>
            </button>
          </form>
        </div>
      </div>

      <!-- Footer opcional -->
      <p class="text-center mt-8 text-xs text-gray-400">
        v1.0 ©SalvaSoluções
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAutenticacaoStore } from '@/stores/autenticacao.js'
import { ExclamationCircleIcon } from '@heroicons/vue/24/outline'

const email = ref('')
const senha = ref('')
const erro = ref('')
const carregando = ref(false)
const roteador = useRouter()
const autenticacaoStore = useAutenticacaoStore()

async function fazerLogin() {
  erro.value = ''
  carregando.value = true

  const resultado = await autenticacaoStore.login(email.value, senha.value)

  if (resultado.sucesso) {
    roteador.push('/')
  } else {
    erro.value = resultado.erro || 'Erro ao fazer login. Verifique suas credenciais.'
  }

  carregando.value = false
}
</script>

<style scoped>
.login-form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.form-group {
  margin-bottom: 0;
}

.form-label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
  letter-spacing: -0.01em;
}

.form-input:focus {
  border-color: #ea580c;
  box-shadow: 0 0 0 3px rgba(234, 88, 12, 0.1);
}
</style>
