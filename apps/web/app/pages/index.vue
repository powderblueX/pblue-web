<script setup lang="ts">
import { formatContentDate } from '~/utils/contentDate'

useSeoMeta({
  title: 'powderblueX',
  description: '涟漪。',
  ogTitle: 'powderblueX',
  ogDescription: '涟漪。',
  twitterCard: 'summary'
})

useHead({ link: [{ rel: 'canonical', href: 'https://pblue.dpdns.org/' }] })

const { data: latestNote } = await useAsyncData('home-latest-note', () => queryCollection('blog')
  .where('draft', '=', false)
  .order('publishedAt', 'DESC')
  .first())

const { data: latestArticle } = await useAsyncData('home-latest-article', () => queryCollection('articles')
  .where('draft', '=', false)
  .order('publishedAt', 'DESC')
  .first())
</script>

<template>
  <main>
    <section class="hero page-grid" aria-labelledby="hero-title">
      <div class="hero-kicker"><span class="signal-dot" aria-hidden="true" /> 祝完成那些“可以吃想要玩能去看”</div>
      <div class="hero-main">
        <h1 class="hero-handwriting" aria-hidden="true">和世界</h1>
        <h1 id="hero-title"><em>飘然又静默</em></h1>
        <p class="hero-copy">某时，喧嚣繁华透过他的眼到达最深处只剩一片死寂，不生涟漪。</p>
      </div>
      <LyricMotion />
    </section>

    <section class="section page-grid" aria-label="最新内容">
      <div class="home-content-grid">
        <section class="home-content-column" aria-labelledby="latest-note-heading">
          <div class="section-label">
            <div>
              <p class="eyebrow mono">Ripples</p>
              <h2 id="latest-note-heading">记录</h2>
            </div>
            <NuxtLink to="/blog" class="section-link">全部 <span aria-hidden="true">→</span></NuxtLink>
          </div>

          <NuxtLink v-if="latestNote" :to="latestNote.path" class="home-content-card">
            <time class="note-date mono" :datetime="latestNote.publishedAt">{{ formatContentDate(latestNote.publishedAt) }}</time>
            <h3>{{ latestNote.title }}</h3>
            <p>{{ latestNote.description }}</p>
            <ul class="tag-list" aria-label="标签"><li v-for="tag in latestNote.tags" :key="tag">{{ tag }}</li></ul>
            <span class="row-arrow" aria-hidden="true">↗</span>
          </NuxtLink>
          <div v-else class="notes-empty">
            <h3>空白。</h3>
          </div>
        </section>

        <section class="home-content-column" aria-labelledby="latest-article-heading">
          <div class="section-label">
            <div>
              <p class="eyebrow mono">Articles</p>
              <h2 id="latest-article-heading">文档</h2>
            </div>
            <NuxtLink to="/articles" class="section-link">全部 <span aria-hidden="true">→</span></NuxtLink>
          </div>

          <NuxtLink v-if="latestArticle" :to="latestArticle.path" class="home-content-card home-content-card-article">
            <time class="note-date mono" :datetime="latestArticle.publishedAt">{{ formatContentDate(latestArticle.publishedAt) }}</time>
            <h3>{{ latestArticle.title }}</h3>
            <p>{{ latestArticle.description }}</p>
            <ul v-if="latestArticle.tags?.length" class="tag-list" aria-label="标签"><li v-for="tag in latestArticle.tags" :key="tag">{{ tag }}</li></ul>
            <span class="row-arrow" aria-hidden="true">↗</span>
          </NuxtLink>
          <div v-else class="notes-empty">
            <h3>空白。</h3>
          </div>
        </section>
      </div>
    </section>

    <!-- 
    <section class="section page-grid" aria-labelledby="focus-heading">
      <div class="section-label"><p class="eyebrow mono">最近在意</p><h2 id="focus-heading">生活正在播放</h2></div>
      <div class="focus-grid">
        <div class="focus-card focus-card-blue"><p class="mono focus-number">01</p><h3>散步时想到的</h3><p>有些念头要走一段路才会出现，刚好顺手把它们带回来。</p></div>
        <div class="focus-card focus-card-yellow"><p class="mono focus-number">02</p><h3>普通的一天</h3><p>没有大事发生也没关系，日子本身就值得被认真看一眼。</p></div>
        <div class="focus-card focus-card-pink"><p class="mono focus-number">03</p><h3>想说又没说的</h3><p>给迟到的感受一个位置，不急着得出结论，也不急着解释。</p></div>
      </div>
    </section>-->

    <section class="closing-note page-grid" aria-labelledby="closing-heading">
      <div class="closing-sticker" aria-hidden="true">祝你好运</div>
      <!--
      <div>
        <h3 id="closing-heading">“如果我告诉你我的梦，也许你会遗忘它。<br>如果我让你进入我的梦，那也会成为你的梦。”</h3>
      </div>
      -->
      <div><p> “依我看啊，每段人生都是由许多好事和坏事组成的。那些美好的事情啊，有时并不能消解那些坏事，但反过来说，坏事也并不一定会破坏那些美好的事，或者让它们打折扣。”</p>
      <div class="section-label">
        <p />
        <p> ——《神秘博士》</p>
      </div>
      </div>
    </section>
  </main>
</template>
