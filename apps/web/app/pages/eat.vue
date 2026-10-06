<script setup lang="ts">
type Party = '单人' | '多人'

type Restaurant = {
  id: string
  name: string
  district: string
  party: Party[]
  price: string
  address: string
  coordinates: [number, number]
  order: string
  note: string
  mapUrl: string
}

useSeoMeta({
  title: '上海进食地图 · powderblueX',
  description: '一张可以点开的上海进食地图',
  ogTitle: '上海进食地图 · powderblueX',
  ogDescription: '一张可以点开的上海进食地图。',
  twitterCard: 'summary'
})

useHead({ link: [{ rel: 'canonical', href: 'https://pblue.dpdns.org/eat' }] })

const { data: foodEntries } = await useAsyncData('food-restaurants', () => queryCollection('food')
  .order('order', 'ASC')
  .all())

const restaurants = computed<Restaurant[]>(() => (foodEntries.value ?? []).map(entry => ({
  id: entry.slug,
  name: entry.name,
  district: entry.district,
  party: entry.party,
  price: entry.price ?? '',
  address: entry.address,
  coordinates: [entry.longitude, entry.latitude],
  order: entry.recommendation,
  note: entry.note ?? '',
  mapUrl: entry.mapUrl
})))

const districts = computed(() => ['全部区域', ...new Set(restaurants.value.map(restaurant => restaurant.district))])
const parties: Array<'全部人数' | Party> = ['全部人数', '单人', '多人']
const activeDistrict = ref('全部区域')
const activeParty = ref<'全部人数' | Party>('全部人数')
const activeId = ref(restaurants.value[0]?.id ?? '')

const filteredRestaurants = computed(() => restaurants.value.filter((restaurant) => {
  const districtMatches = activeDistrict.value === '全部区域' || restaurant.district === activeDistrict.value
  const partyMatches = activeParty.value === '全部人数' || restaurant.party.includes(activeParty.value)
  return districtMatches && partyMatches
}))

watch(filteredRestaurants, (items) => {
  if (!items.some(item => item.id === activeId.value)) activeId.value = items[0]?.id ?? ''
})

function selectRestaurant(id: string) {
  activeId.value = id
  if (import.meta.client && window.matchMedia('(max-width: 800px)').matches) {
    document.querySelector(`[data-restaurant="${id}"]`)?.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }
}
</script>

<template>
  <main class="eat-page page-grid">
    <header class="eat-heading">
      <div>
        <p class="eyebrow mono">Shanghai food map · 01</p>
        <h1>上海进食<br><em>地图</em></h1>
      </div>
      
    </header>

    <div class="eat-toolbar" aria-label="筛选餐厅">
      <label class="eat-filter-group">
        <span class="eat-filter-label mono">区域</span>
        <span class="eat-select-wrap">
          <select v-model="activeDistrict" aria-label="按区域筛选">
            <option v-for="district in districts" :key="district" :value="district">{{ district }}</option>
          </select>
        </span>
      </label>
      <label class="eat-filter-group">
        <span class="eat-filter-label mono">人数</span>
        <span class="eat-select-wrap">
          <select v-model="activeParty" aria-label="按用餐人数筛选">
            <option v-for="party in parties" :key="party" :value="party">{{ party }}</option>
          </select>
        </span>
      </label>
      <span class="eat-count mono">{{ String(filteredRestaurants.length).padStart(2, '0') }} places</span>
    </div>

    <section class="eat-explorer" aria-label="上海餐厅推荐">
      <div class="eat-map-panel">
        <ClientOnly>
          <ShanghaiFoodMap :restaurants="restaurants" :active-id="activeId" @select="selectRestaurant" />
          <template #fallback><div class="food-map food-map-loading">地图正在展开…</div></template>
        </ClientOnly>
        <p class="map-caption">点地图上的数字，也可以点右侧店名。</p>
      </div>

      <ol class="restaurant-list">
        <li v-if="filteredRestaurants.length === 0" class="restaurant-empty">
          <strong>这一组暂时还没有店。</strong>
          <span>换一个区域或人数看看。</span>
        </li>
        <li
          v-for="restaurant in filteredRestaurants"
          :key="restaurant.id"
          :data-restaurant="restaurant.id"
          :class="['restaurant-card', { 'is-active': activeId === restaurant.id }]"
        >
          <button type="button" class="restaurant-select" @click="selectRestaurant(restaurant.id)">
            <span class="restaurant-index mono">{{ String(restaurants.indexOf(restaurant) + 1).padStart(2, '0') }}</span>
            <span class="restaurant-copy">
              <span class="restaurant-meta mono">{{ restaurant.district }} · {{ restaurant.party.join(' / ') }}<template v-if="restaurant.price"> · {{ restaurant.price }}</template></span>
              <strong>{{ restaurant.name }}</strong>
              <span v-if="restaurant.note" class="restaurant-note">{{ restaurant.note }}</span>
            </span>
          </button>
          <div class="restaurant-address">
            <span>{{ restaurant.address }}</span>
            <a :href="restaurant.mapUrl" target="_blank" rel="noreferrer">去地图 <span aria-hidden="true">↗</span></a>
          </div>
        </li>
      </ol>
    </section>

    <aside class="eat-notice">
      <p class="mono">Before you go</p>
      <p>店铺营业时间、排队情况和菜单都会变化，专程前往之前建议再打开地图确认一次。</p>
    </aside>
  </main>
</template>
