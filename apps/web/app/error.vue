<script setup lang="ts">
defineProps<{ error: { statusCode?: number, statusMessage?: string } }>()
</script>

<template>
  <main class="error-page page-grid">
    <p class="eyebrow mono">Error / {{ error.statusCode ?? 500 }}</p>
    <h1>{{ error.statusCode === 404 ? '这里没有这篇文档。' : '连接暂时中断。' }}</h1>
    <p>{{ error.statusMessage }}</p>
    <NuxtLink to="/">返回 powderblueX →</NuxtLink>
  </main>
</template>
