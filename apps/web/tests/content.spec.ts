import { access, readFile, readdir } from 'node:fs/promises'
import { resolve } from 'node:path'
import { describe, expect, it } from 'vitest'
import { formatContentDate } from '../app/utils/contentDate'

const root = resolve(import.meta.dirname, '..')
const contentRoot = resolve(root, 'content/blog')
const articlesRoot = resolve(root, 'content/articles')

describe('blog content', () => {
  it('contains the personal essay starter collection', async () => {
    const files = (await readdir(contentRoot)).filter(file => file.endsWith('.md'))
    expect(files).toHaveLength(4)
  })
})

describe('article content', () => {
  it('has the metadata required by article routes', async () => {
    const files = (await readdir(articlesRoot)).filter(file => file.endsWith('.md'))
    expect(files.length).toBeGreaterThan(0)

    for (const file of files) {
      const source = await readFile(resolve(articlesRoot, file), 'utf8')
      expect(source).toMatch(/^---\n/)
      expect(source).toMatch(/\ntitle: .+/)
      expect(source).toMatch(/\ndescription: .+/)
      expect(source).toMatch(/\npublishedAt: '\d{4}-\d{2}-\d{2}'/)
      expect(source).toMatch(/\ndraft: (true|false)/)
    }
  })

  it('does not throw when a content date is missing or invalid', () => {
    expect(formatContentDate()).toBe('日期未设置')
    expect(formatContentDate('not-a-date')).toBe('日期未设置')
    expect(formatContentDate('2026-09-25')).toBe('2026年9月25日')
  })
})

describe('public routes', () => {
  it('presents both writing collections on the home page', async () => {
    const home = await readFile(resolve(root, 'app/pages/index.vue'), 'utf8')
    expect(home).toContain("queryCollection('blog')")
    expect(home).toContain("queryCollection('articles')")
    expect(home).toContain('to="/blog"')
    expect(home).toContain('to="/articles"')
  })

  it('prevents public proxies from caching development assets', async () => {
    const config = await readFile(resolve(root, 'nuxt.config.ts'), 'utf8')
    expect(config).toContain("'Cloudflare-CDN-Cache-Control': 'no-store'")
    expect(config).toContain("buildAssetsDir: isDev ? '/_nuxt-dev/' : '/_nuxt/'")
  })

  it('declares the expected canonical sitemap routes', async () => {
    const sitemap = await readFile(resolve(root, 'public/sitemap.xml'), 'utf8')
    for (const path of ['/', '/blog', '/articles']) {
      expect(sitemap).toContain(`https://pblue.dpdns.org${path === '/' ? '/' : path}`)
    }
    for (const slug of ['2021-07-08-story', 'winter-break-2026', 'semi-in-ear-noise-cancelling', 'knicks-champions']) {
      expect(sitemap).toContain(`/blog/${slug}`)
    }
    expect(sitemap).toContain('/articles/ubuntu-huawei-matebook-sn6140-headphone-speaker-fix')
  })

  it('removes the topics page while preserving its redirect', async () => {
    await expect(access(resolve(root, 'app/pages/topics.vue'))).rejects.toThrow()

    const header = await readFile(resolve(root, 'app/components/SiteHeader.vue'), 'utf8')
    const config = await readFile(resolve(root, 'nuxt.config.ts'), 'utf8')
    expect(header).not.toContain('to="/topics"')
    expect(header).toContain('to="/articles"')
    expect(config).toContain("'/topics': { redirect: { to: '/blog', statusCode: 301 } }")
  })
})
