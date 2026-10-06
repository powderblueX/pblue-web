<script setup lang="ts">
const props = defineProps<{
  code?: string
  language?: string
  filename?: string
  class?: string
}>()

const copied = ref(false)

async function copyCode() {
  if (!props.code) return
  await navigator.clipboard.writeText(props.code)
  copied.value = true
  window.setTimeout(() => { copied.value = false }, 1600)
}
</script>

<template>
  <div class="code-frame">
    <div class="code-toolbar">
      <span>{{ filename || language || 'text' }}</span>
      <button type="button" :aria-label="copied ? '代码已复制' : '复制代码'" @click="copyCode">{{ copied ? '已复制' : '复制' }}</button>
    </div>
    <pre :class="props.class"><slot /></pre>
  </div>
</template>
