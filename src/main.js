import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import roteador from './rotas'
import { useAutenticacaoStore } from './stores/autenticacao'
import './estilos/principal.css'

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(roteador)

// Inicializar autenticação
const autenticacaoStore = useAutenticacaoStore()
autenticacaoStore.inicializar()

app.mount('#app')