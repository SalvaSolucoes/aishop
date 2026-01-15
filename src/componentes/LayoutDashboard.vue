<template>
  <div class="flex min-h-screen bg-gray-50">
    <!-- Sidebar -->
    <aside
      :class="[
        'bg-gray-900 border-r border-gray-800 flex flex-col transition-all duration-300 fixed lg:static inset-y-0 left-0 z-30',
        menuColapsado ? 'w-20' : 'w-72'
      ]"
    >
      <!-- Header do Sidebar -->
      <div class="relative flex items-center px-4 py-5 border-b border-gray-800 min-h-[4rem]">
        <div v-if="!menuColapsado" class="flex items-center gap-3 flex-1 pr-10">
          <div class="flex-shrink-0">
            <img src="/AIShopLogo.png" alt="AIShop Logo" class="h-10 w-auto object-contain" />
          </div>
          <h2 class="text-xl font-bold text-white truncate">
            AIShop
          </h2>
        </div>
        <div v-else class="flex-1 flex justify-center">
          <img src="/AIShopLogo.png" alt="AIShop Logo" class="h-10 w-auto object-contain" />
        </div>
        <button
          @click="toggleMenu"
          class="absolute right-3 top-1/2 -translate-y-1/2 p-2 rounded-lg text-gray-400 hover:bg-gray-800 hover:text-white transition-all duration-200 flex items-center justify-center"
          :class="menuColapsado ? 'right-2' : 'right-3'"
          aria-label="Alternar menu"
        >
          <ChevronRightIcon v-if="menuColapsado" class="h-5 w-5" />
          <ChevronLeftIcon v-else class="h-5 w-5" />
        </button>
      </div>

      <!-- Navegação -->
      <nav class="flex-1 px-3 py-4 space-y-1 overflow-y-auto scrollbar-thin">
        <template v-for="item in itensMenu" :key="item.rota || item.nome">
          <!-- Item com submenu -->
          <div v-if="item.submenu">
            <!-- Item principal (clicável para expandir) -->
            <button
              @click="toggleSubmenu(item.nome)"
              class="w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 group relative"
              :class="
                isSubmenuActive(item)
                  ? 'bg-orange-600 text-white shadow-lg shadow-orange-600/20'
                  : 'text-gray-300 hover:bg-gray-800 hover:text-white'
              "
            >
              <component :is="item.icone" class="h-5 w-5 flex-shrink-0" />
              <span v-if="!menuColapsado" class="ml-3 flex-1 text-left">{{ item.nome }}</span>
              <ChevronDownIcon
                v-if="!menuColapsado"
                class="h-4 w-4 transition-transform duration-200"
                :class="submenusAbertos[item.nome] ? 'rotate-180' : ''"
              />
              <span
                v-if="menuColapsado"
                class="absolute left-full ml-2 px-2 py-1 text-xs font-medium text-white bg-gray-900 rounded shadow-lg opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-50"
              >
                {{ item.nome }}
              </span>
            </button>

            <!-- Submenu (dropdown) -->
            <transition
              enter-active-class="transition-all duration-200 ease-out"
              enter-from-class="opacity-0 -translate-y-1"
              enter-to-class="opacity-100 translate-y-0"
              leave-active-class="transition-all duration-150 ease-in"
              leave-from-class="opacity-100 translate-y-0"
              leave-to-class="opacity-0 -translate-y-1"
            >
              <div
                v-if="submenusAbertos[item.nome] && !menuColapsado"
                class="mt-1.5 ml-3 mr-1 py-1.5 px-2 bg-gray-800/30 backdrop-blur-sm rounded-lg border border-gray-700/30"
              >
                <router-link
                  v-for="subitem in item.submenu"
                  :key="subitem.rota"
                  :to="subitem.rota"
                  class="flex items-center px-3 py-2 text-sm font-normal rounded-md transition-all duration-150 group relative"
                  :class="
                    $route.path === subitem.rota
                      ? 'bg-orange-500/90 text-white'
                      : 'text-gray-400 hover:bg-gray-700/50 hover:text-gray-200'
                  "
                >
                  <component :is="subitem.icone" class="h-3.5 w-3.5 flex-shrink-0 opacity-70" />
                  <span class="ml-2.5 text-xs">{{ subitem.nome }}</span>
                </router-link>
              </div>
            </transition>
          </div>

          <!-- Item simples (sem submenu) -->
          <router-link
            v-else
            :to="item.rota"
            class="flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-all duration-200 group relative"
            :class="
              $route.path === item.rota || ($route.path === '/' && item.rota === '/')
                ? 'bg-orange-600 text-white shadow-lg shadow-orange-600/20'
                : 'text-gray-300 hover:bg-gray-800 hover:text-white'
            "
          >
            <component :is="item.icone" class="h-5 w-5 flex-shrink-0" />
            <span v-if="!menuColapsado" class="ml-3">{{ item.nome }}</span>
            <span
              v-if="menuColapsado && ($route.path === item.rota || ($route.path === '/' && item.rota === '/'))"
              class="absolute left-full ml-2 px-2 py-1 text-xs font-medium text-white bg-gray-900 rounded shadow-lg opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-50"
            >
              {{ item.nome }}
            </span>
          </router-link>
        </template>
      </nav>

      <!-- Footer do Sidebar -->
      <div class="p-4 border-t border-gray-800">
        <div v-if="!menuColapsado" class="mb-3 px-3 py-2 bg-gray-800/50 rounded-lg">
          <p class="text-xs font-semibold text-gray-400 mb-1 uppercase tracking-wider">Usuário</p>
          <p class="text-sm text-white truncate font-medium">{{ usuarioEmail }}</p>
        </div>
        <button
          @click="fazerLogout"
          class="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-semibold text-gray-300 bg-gray-800/50 rounded-lg hover:bg-gray-800 hover:text-white transition-all duration-200"
        >
          <ArrowRightOnRectangleIcon class="h-5 w-5" />
          <span v-if="!menuColapsado">Sair</span>
        </button>
      </div>
    </aside>

    <!-- Overlay para mobile -->
    <div
      v-if="!menuColapsado"
      @click="menuColapsado = true"
      class="fixed inset-0 bg-black/60 backdrop-blur-sm z-20 lg:hidden transition-opacity"
    ></div>

    <!-- Conteúdo Principal -->
    <main class="flex-1 flex flex-col overflow-hidden lg:ml-0">
      <!-- Topbar -->
      <header class="bg-white border-b border-gray-200 px-4 lg:px-6 py-4 sticky top-0 z-10 shadow-sm">
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-xl font-semibold text-gray-900">{{ tituloPagina }}</h1>
            <p class="text-xs text-gray-500 mt-0.5">Gerencie seu negócio de forma eficiente</p>
          </div>
        </div>
      </header>

      <!-- Área de Conteúdo -->
      <div class="flex-1 overflow-y-auto p-4 lg:p-6 scrollbar-thin">
        <router-view />
      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useAutenticacaoStore } from '@/stores/autenticacao'
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  ChevronDownIcon,
  HomeIcon,
  CubeIcon,
  CurrencyDollarIcon,
  UserGroupIcon,
  CreditCardIcon,
  DocumentChartBarIcon,
  ArrowRightOnRectangleIcon,
  ArrowsRightLeftIcon,
  ClockIcon,
} from '@heroicons/vue/24/outline'

const menuColapsado = ref(false)
const submenusAbertos = ref({})
const rota = useRoute()
const autenticacaoStore = useAutenticacaoStore()

const usuarioEmail = computed(() => autenticacaoStore.usuario?.email || '')

const tituloPagina = computed(() => {
  const mapaTitulos = {
    Dashboard: 'Dashboard',
    Estoque: 'Controle de Estoque',
    Caixa: 'Controle de Caixa',
    Movimentacoes: 'Movimentações de Caixa',
    HistoricoMovimentacoes: 'Histórico de Movimentações',
    Clientes: 'Cadastro de Clientes',
    Financeiro: 'Controle Financeiro',
    Relatorios: 'Relatórios'
  }
  return mapaTitulos[rota.name] || 'Dashboard'
})

const itensMenu = [
  { nome: 'Dashboard', rota: '/', icone: HomeIcon },
  { nome: 'Estoque', rota: '/estoque', icone: CubeIcon },
  { 
    nome: 'Caixa', 
    icone: CurrencyDollarIcon,
    submenu: [
      { nome: 'Caixa', rota: '/caixa', icone: CurrencyDollarIcon },
      { nome: 'Movimentações', rota: '/movimentacoes', icone: ArrowsRightLeftIcon },
      { nome: 'Histórico de Movimentações', rota: '/historico-movimentacoes', icone: ClockIcon }
    ]
  },
  { nome: 'Clientes', rota: '/clientes', icone: UserGroupIcon },
  { nome: 'Financeiro', rota: '/financeiro', icone: CreditCardIcon },
  { nome: 'Relatórios', rota: '/relatorios', icone: DocumentChartBarIcon }
]

function toggleMenu() {
  menuColapsado.value = !menuColapsado.value
}

function toggleSubmenu(nomeItem) {
  submenusAbertos.value[nomeItem] = !submenusAbertos.value[nomeItem]
}

function isSubmenuActive(item) {
  if (!item.submenu) return false
  return item.submenu.some(subitem => rota.path === subitem.rota)
}

async function fazerLogout() {
  await autenticacaoStore.logout()
}
</script>
