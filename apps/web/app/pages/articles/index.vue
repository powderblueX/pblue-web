<script setup lang="ts">
import { formatContentDate } from '~/utils/contentDate'

const { data: articles } = await useAsyncData('articles-index', () => queryCollection('articles')
  .where('draft', '=', false)
  .order('publishedAt', 'DESC')
  .all())

useSeoMeta({
  title: '文档',
  description: '空白。',
  ogTitle: '文档',
  ogDescription: '空白。',
  twitterCard: 'summary'
})
useHead({ link: [{ rel: 'canonical', href: 'https://pblue.dpdns.org/articles' }] })
</script>

<template>
  <main class="page-grid page-main">
    <header class="page-heading">
      <p class="eyebrow mono">Articles</p>
      <h1>文档</h1>
    </header>

    <section v-if="articles?.length" class="article-index" aria-label="文档列表">
      <article v-for="(article, index) in articles" :key="article.path" class="article-index-row">
        <span class="mono index-number">{{ (index + 1).toString().padStart(2, '0') }}</span>
        <div>
          <h2><NuxtLink :to="article.path">{{ article.title }}</NuxtLink></h2>
          <p>{{ article.description }}</p>
          <div class="article-meta">
            <time :datetime="article.publishedAt">{{ formatContentDate(article.publishedAt) }}</time>
          </div>
        </div>
      </article>
    </section>

    <section v-else class="journal-empty" aria-labelledby="articles-empty-heading">
      <div class="journal-empty-number mono">00</div>
      <div class="journal-empty-copy">
        <h2 id="articles-empty-heading">空白。</h2>
      </div>
      <div class="journal-empty-mark" aria-hidden="true"><span /></div>
    </section>
  </main>
</template>
