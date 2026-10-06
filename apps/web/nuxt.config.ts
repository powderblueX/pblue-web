import tailwindcss from '@tailwindcss/vite'

const isDev = process.env.NODE_ENV !== 'production'

export default defineNuxtConfig({
  compatibilityDate: '2026-09-01',
  runtimeConfig: {
    public: {
      amapKey: '',
      amapSecurityCode: ''
    }
  },
  modules: ['@nuxt/content', '@nuxt/eslint'],
  content: {
    experimental: { sqliteConnector: 'native' }
  },
  css: ['~/assets/css/main.css'],
  devtools: { enabled: false },
  typescript: { strict: true, typeCheck: true },
  vite: {
    plugins: [tailwindcss()],
    server: {
      allowedHosts: ['pblue.dpdns.org'],
      strictPort: true,
      headers: isDev
        ? {
            'Cache-Control': 'no-store, no-cache, must-revalidate',
            'CDN-Cache-Control': 'no-store',
            'Cloudflare-CDN-Cache-Control': 'no-store'
          }
        : undefined
    }
  },
  app: {
    buildAssetsDir: isDev ? '/_nuxt-dev/' : '/_nuxt/',
    head: {
      htmlAttrs: { lang: 'zh-CN' },
      link: [{ rel: 'icon', type: 'image/svg+xml', href: '/favicon.svg' }],
      meta: [
        { name: 'theme-color', media: '(prefers-color-scheme: light)', content: '#eef7ff' },
        { name: 'theme-color', media: '(prefers-color-scheme: dark)', content: '#101b2a' }
      ],
      script: [{
        innerHTML: "try{const t=localStorage.getItem('pblue-theme');if(t==='dark'||(!t&&matchMedia('(prefers-color-scheme: dark)').matches))document.documentElement.classList.add('dark')}catch(e){}",
        tagPosition: 'head'
      }]
    }
  },
  nitro: {
    prerender: {
      crawlLinks: true
    }
  },
  routeRules: {
    '/topics': { redirect: { to: '/blog', statusCode: 301 } }
  }
})
