<script setup lang="ts">
import { formatContentDate } from '~/utils/contentDate'

const route = useRoute()
const path = computed(() => `/articles/${route.params.slug}`)
const { data: article } = await useAsyncData(path.value, () => queryCollection('articles').path(path.value).first())

if (!article.value || article.value.draft) {
  throw createError({ statusCode: 404, statusMessage: '文档不存在' })
}

useSeoMeta({
  title: () => `${article.value?.title} — powderblueX`,
  description: () => article.value?.description,
  ogTitle: () => article.value?.title,
  ogDescription: () => article.value?.description,
  ogType: 'article',
  articlePublishedTime: () => article.value?.publishedAt,
  articleModifiedTime: () => article.value?.updatedAt || article.value?.publishedAt,
  articleTag: () => article.value?.tags,
  twitterCard: 'summary'
})
useHead({ link: [{ rel: 'canonical', href: () => `https://pblue.dpdns.org${path.value}` }] })
</script>

<template>
  <main v-if="article" class="article-page">
    <header class="article-header page-grid">
      <NuxtLink to="/articles" class="back-link mono">← 返回</NuxtLink>
      <div class="article-heading">
        <div class="article-heading-meta">
          <time :datetime="article.publishedAt">{{ formatContentDate(article.publishedAt) }}</time>
          <span v-if="article.updatedAt">更新于 {{ formatContentDate(article.updatedAt) }}</span>
        </div>
        <h1>{{ article.title }}</h1>
        <p>{{ article.description }}</p>
        <ul v-if="article.tags?.length" class="tag-list" aria-label="文档主题">
          <li v-for="tag in article.tags ?? []" :key="tag">{{ tag }}</li>
        </ul>
      </div>
    </header>
    <div class="article-rule page-grid" />
    <article class="prose-wrap">
      <ContentRenderer :value="article" />
    </article>
    <nav class="article-end page-grid" aria-label="文档导航">
      <p class="mono">写到这里 / {{ article.title }}</p>
      <NuxtLink to="/articles">返回文档 →</NuxtLink>
    </nav>
  </main>
</template>
