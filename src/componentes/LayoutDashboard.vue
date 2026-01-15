<template>
  <div class="flex min-h-screen bg-gray-50">
    <!-- Sidebar -->
    <aside
      class="bg-gray-900 border-r border-gray-800 flex flex-col w-72 hidden lg:flex fixed lg:static inset-y-0 left-0 z-30"
    >
      <!-- Header do Sidebar -->
      <div class="flex items-center px-4 py-5 border-b border-gray-800 min-h-[4rem]">
        <div class="flex items-center gap-3 flex-1">
          <div class="flex-shrink-0">
            <img src="/AIShopLogo.png" alt="AIShop Logo" class="h-10 w-auto object-contain" />
          </div>
          <h2 class="text-xl font-bold text-white truncate">
            AIShop
          </h2>
        </div>
      </div>

      <!-- Navegação -->
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto scrollbar-thin">
        <template v-for="item in itensMenu" :key="item.rota || item.nome">
          <!-- Item de menu simples (sem submenu) -->
          <router-link
            v-if="!item.submenu"
            :to="item.rota"
            class="flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200"
            :class="
              $route.path === item.rota || ($route.path === '/' && item.rota === '/')
                ? 'bg-orange-600 text-white shadow-lg shadow-orange-600/20'
                : 'text-gray-300 hover:bg-gray-800 hover:text-white'
            "
          >
            <component :is="item.icone" class="h-5 w-5 flex-shrink-0" />
            <span class="ml-3">{{ item.nome }}</span>
          </router-link>

          <!-- Item de menu com submenu (dropdown) -->
          <div v-else class="space-y-1">
            <button
              @click="toggleSubmenu(item.nome)"
              class="w-full flex items-center justify-between px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200"
              :class="
                $route.path.startsWith(item.rotaBase)
                  ? 'bg-orange-600 text-white shadow-lg shadow-orange-600/20'
                  : 'text-gray-300 hover:bg-gray-800 hover:text-white'
              "
            >
              <div class="flex items-center">
                <component :is="item.icone" class="h-5 w-5 flex-shrink-0" />
                <span class="ml-3">{{ item.nome }}</span>
              </div>
              <ChevronDownIcon
                class="h-4 w-4 transition-transform duration-200"
                :class="{ 'rotate-180': submenuAberto[item.nome] }"
              />
            </button>

            <!-- Submenu -->
            <div
              v-show="submenuAberto[item.nome]"
              class="ml-4 pl-4 border-l-2 border-gray-700 space-y-1"
            >
              <router-link
                v-for="subitem in item.submenu"
                :key="subitem.rota"
                :to="subitem.rota"
                class="flex items-center px-4 py-2.5 text-sm font-medium rounded-lg transition-all duration-200"
                :class="
                  $route.path === subitem.rota
                    ? 'bg-orange-500/20 text-orange-400'
                    : 'text-gray-400 hover:bg-gray-800 hover:text-gray-200'
                "
              >
                <component :is="subitem.icone" class="h-4 w-4 flex-shrink-0" />
                <span class="ml-3">{{ subitem.nome }}</span>
              </router-link>
            </div>
          </div>
        </template>
      </nav>

      <!-- Footer do Sidebar -->
      <div class="p-4 border-t border-gray-800">
        <div class="mb-3 px-3 py-2 bg-gray-800/50 rounded-lg">
          <p class="text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Usuário</p>
          <p class="text-sm text-white truncate font-medium">{{ usuarioEmail }}</p>
        </div>
        <button
          @click="fazerLogout"
          class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-gray-300 bg-gray-800/50 rounded-lg hover:bg-gray-800 hover:text-white transition-all duration-200"
        >
          <ArrowRightOnRectangleIcon class="h-5 w-5" />
          <span>Sair</span>
        </button>
      </div>
    </aside>

    <!-- Overlay para mobile -->
    <!-- Mobile: Sidebar hidden, no overlay needed -->

    <!-- Conteúdo Principal -->
    <main class="flex-1 flex flex-col overflow-hidden w-full">
      <!-- Área de Conteúdo -->
      <div class="flex-1 overflow-y-auto p-3 sm:p-4 lg:p-6 scrollbar-thin w-full max-w-full">
        <router-view />
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAutenticacaoStore } from '@/stores/autenticacao'
import {
  HomeIcon,
  CubeIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  CreditCardIcon,
  DocumentChartBarIcon,
  ArrowRightOnRectangleIcon,
  ShoppingCartIcon,
  ArrowsRightLeftIcon,
  ClockIcon,
  DocumentTextIcon,
  ChevronDownIcon,
} from '@heroicons/vue/24/outline'

const route = useRoute()
const autenticacaoStore = useAutenticacaoStore()

const usuarioEmail = computed(() => autenticacaoStore.usuario?.email || '')

const submenuAberto = ref({
  Caixa: false
})

// Abrir submenu automaticamente se a rota atual pertence a ele
watch(() => route.path, (novoCaminho) => {
  if (novoCaminho.startsWith('/caixa')) {
    submenuAberto.value.Caixa = true
  }
}, { immediate: true })

function toggleSubmenu(nomeMenu) {
  submenuAberto.value[nomeMenu] = !submenuAberto.value[nomeMenu]
}

const itensMenu = [
  { nome: 'Dashboard', rota: '/', icone: HomeIcon },
  { nome: 'Estoque', rota: '/estoque', icone: CubeIcon },
  {
    nome: 'Caixa',
    icone: CurrencyDollarIcon,
    rotaBase: '/caixa',
    submenu: [
      { nome: 'Carrinho', rota: '/caixa/carrinho', icone: ShoppingCartIcon },
      { nome: 'Registrar Movimentação', rota: '/caixa/movimentacoes', icone: ArrowsRightLeftIcon },
      { nome: 'Histórico de Vendas', rota: '/caixa/historico-vendas', icone: ClockIcon },
      { nome: 'Histórico de Movimentações', rota: '/caixa/historico-movimentacoes', icone: DocumentTextIcon }
    ]
  },
  { nome: 'Clientes', rota: '/clientes', icone: UserGroupIcon },
  { nome: 'Financeiro', rota: '/financeiro', icone: CreditCardIcon },
  { nome: 'Relatórios', rota: '/relatorios', icone: DocumentChartBarIcon }
]

async function fazerLogout() {
  await autenticacaoStore.logout()
}
</script>
