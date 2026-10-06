import { defineCollection, defineContentConfig, z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    blog: defineCollection({
      type: 'page',
      source: 'blog/**/*.md',
      schema: z.object({
        title: z.string(),
        description: z.string(),
        publishedAt: z.string(),
        updatedAt: z.string().optional(),
        tags: z.array(z.string()),
        draft: z.boolean().default(false)
      })
    }),
    articles: defineCollection({
      type: 'page',
      source: 'articles/**/*.md',
      schema: z.object({
        title: z.string(),
        description: z.string(),
        publishedAt: z.string(),
        updatedAt: z.string().optional(),
        tags: z.array(z.string()).default([]),
        draft: z.boolean().default(false)
      })
    }),
    food: defineCollection({
      type: 'page',
      source: 'food/*.md',
      schema: z.object({
        slug: z.string(),
        name: z.string(),
        order: z.number(),
        district: z.string(),
        party: z.array(z.enum(['单人', '多人'])).min(1),
        price: z.string().default(''),
        address: z.string(),
        longitude: z.number(),
        latitude: z.number(),
        recommendation: z.string(),
        note: z.string().default(''),
        mapUrl: z.string().url()
      })
    })
  }
})
