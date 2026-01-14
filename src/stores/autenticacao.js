import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/servicos/supabase'

export const useAutenticacaoStore = defineStore('autenticacao', () => {
  const usuario = ref(null)
  const carregando = ref(false)
  const erro = ref(null)

  const estaAutenticado = computed(() => usuario.value !== null)

  // Inicializar verificação de sessão
  async function inicializar() {
    try {
      const { data: { session } } = await supabase.auth.getSession()
      usuario.value = session?.user ?? null

      // Escutar mudanças de autenticação
      supabase.auth.onAuthStateChange((_event, session) => {
        usuario.value = session?.user ?? null
      })
    } catch (err) {
      console.error('Erro ao inicializar autenticação:', err)
      erro.value = err.message
    }
  }

  // Fazer login
  async function login(email, senha) {
    carregando.value = true
    erro.value = null

    try {
      const { data, error: errorAuth } = await supabase.auth.signInWithPassword({
        email,
        password: senha
      })

      if (errorAuth) {
        throw errorAuth
      }

      usuario.value = data.user
      return { sucesso: true }
    } catch (err) {
      erro.value = err.message || 'Erro ao fazer login'
      return { sucesso: false, erro: erro.value }
    } finally {
      carregando.value = false
    }
  }

  // Fazer logout
  async function logout() {
    carregando.value = true
    erro.value = null

    try {
      const { error: errorAuth } = await supabase.auth.signOut()
      if (errorAuth) {
        throw errorAuth
      }

      usuario.value = null
      window.location.href = '/login'
    } catch (err) {
      erro.value = err.message || 'Erro ao fazer logout'
    } finally {
      carregando.value = false
    }
  }

  // Registrar novo usuário
  async function registrar(email, senha, dadosExtras = {}) {
    carregando.value = true
    erro.value = null

    try {
      const { data, error: errorAuth } = await supabase.auth.signUp({
        email,
        password: senha,
        options: {
          data: dadosExtras
        }
      })

      if (errorAuth) {
        throw errorAuth
      }

      return { sucesso: true, usuario: data.user }
    } catch (err) {
      erro.value = err.message || 'Erro ao registrar usuário'
      return { sucesso: false, erro: erro.value }
    } finally {
      carregando.value = false
    }
  }

  return {
    usuario,
    carregando,
    erro,
    estaAutenticado,
    inicializar,
    login,
    logout,
    registrar
  }
})
