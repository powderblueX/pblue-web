<script setup lang="ts">
import { formatContentDate } from '~/utils/contentDate'

const route = useRoute()
const { data: posts } = await useAsyncData('blog-index', () => queryCollection('blog')
  .where('draft', '=', false)
  .order('publishedAt', 'DESC')
  .all())

const selectedTag = computed(() => typeof route.query.tag === 'string' ? route.query.tag : '')
const visiblePosts = computed(() => selectedTag.value
  ? posts.value?.filter(post => post.tags.includes(selectedTag.value)) ?? []
  : posts.value ?? [])

const allTags = computed(() => [...new Set(posts.value?.flatMap(post => post.tags) ?? [])].sort())
useSeoMeta({
  title: '记录',
  description: '涟漪。',
  ogTitle: '记录',
  ogDescription: '涟漪。',
  twitterCard: 'summary'
})
useHead({ link: [{ rel: 'canonical', href: 'https://pblue.dpdns.org/blog' }] })
</script>

<template>
  <main class="page-grid page-main">
    <header class="blog-masthead">
      <div class="blog-masthead-copy">
        <p class="eyebrow mono">ripples</p>
        <h1>记录</h1>
      </div>
    </header>

    <div v-if="posts?.length" class="blog-layout">
      <aside class="tag-filter" aria-label="按主题筛选">
        <p class="mono">按标签翻阅</p>
        <NuxtLink to="/blog" :class="{ active: !selectedTag }">全部 <span>{{ posts?.length ?? 0 }}</span></NuxtLink>
        <NuxtLink v-for="tag in allTags" :key="tag" :to="{ path: '/blog', query: { tag } }" :class="{ active: selectedTag === tag }">
          {{ tag }} <span>{{ posts?.filter(post => post.tags.includes(tag)).length }}</span>
        </NuxtLink>
      </aside>

      <section aria-labelledby="notes-heading">
        <div class="list-header">
          <h2 id="notes-heading">{{ selectedTag || '全部' }}</h2>
          <span class="mono">共 {{ visiblePosts.length.toString().padStart(2, '0') }} 篇</span>
        </div>
        <div class="article-index">
          <article v-for="(post, index) in visiblePosts" :key="post.path" class="article-index-row">
            <span class="mono index-number">{{ (index + 1).toString().padStart(2, '0') }}</span>
            <div>
              <h3><NuxtLink :to="post.path">{{ post.title }}</NuxtLink></h3>
              <p>{{ post.description }}</p>
              <div class="article-meta">
                <time :datetime="post.publishedAt">{{ formatContentDate(post.publishedAt) }}</time>
                <span aria-hidden="true">·</span>
                <span>{{ post.tags.join(' / ') }}</span>
              </div>
            </div>
          </article>
        </div>
      </section>
    </div>

    <section v-else class="journal-empty" aria-labelledby="empty-heading">
      <div class="journal-empty-number mono">00</div>
      <div class="journal-empty-copy">
        <p class="eyebrow mono">Current state / 空白</p>
        <h2 id="empty-heading">空白。</h2>
        <p>空白。</p>
      </div>
      <div class="journal-empty-mark" aria-hidden="true"><span /></div>
    </section>
  </main>
</template>
