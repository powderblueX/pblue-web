<script setup lang="ts">
const route = useRoute()
const open = ref(false)
const isDark = ref(false)

function toggleTheme() {
  isDark.value = !isDark.value
  document.documentElement.classList.toggle('dark', isDark.value)
  localStorage.setItem('pblue-theme', isDark.value ? 'dark' : 'light')
}

onMounted(() => {
  const saved = localStorage.getItem('pblue-theme')
  isDark.value = saved ? saved === 'dark' : window.matchMedia('(prefers-color-scheme: dark)').matches
  document.documentElement.classList.toggle('dark', isDark.value)
})

watch(() => route.fullPath, () => { open.value = false })
</script>

<template>
  <header class="site-header">
    <div class="page-grid header-inner">
      <NuxtLink to="/" class="wordmark" aria-label="powderblueX 首页">
        <span class="wordmark-mark" aria-hidden="true">px</span>
        <span>powderblue<span class="wordmark-x">X</span></span>
      </NuxtLink>
      <button class="mobile-menu" type="button" :aria-expanded="open" aria-controls="primary-navigation" @click="open = !open">
        <span>{{ open ? '关闭' : '菜单' }}</span>
      </button>
      <nav id="primary-navigation" class="primary-nav" :class="{ 'is-open': open }" aria-label="主导航">
        <NuxtLink to="/eat">上海进食</NuxtLink>
        <NuxtLink to="/blog">记录</NuxtLink>
        <NuxtLink to="/articles">文档</NuxtLink>
        <button class="theme-toggle" type="button" :aria-label="`切换为${isDark ? '浅色' : '深色'}模式`" @click="toggleTheme">
          <span aria-hidden="true">{{ isDark ? '浅色' : '深色' }}</span>
        </button>
      </nav>
    </div>
  </header>
</template>
