<script setup lang="ts">
import type { Map as MapLibreMap, Marker, Popup } from 'maplibre-gl'

type RestaurantPin = { id: string, name: string, address: string, coordinates: [number, number] }
type AMapInstance = {
  addControl: (control: unknown) => void
  destroy: () => void
  setZoomAndCenter: (zoom: number, center: [number, number]) => void
}
type AMapMarker = { on: (event: string, handler: () => void) => void }
type AMapInfoWindow = { close: () => void, open: (map: AMapInstance, position: [number, number]) => void }
type AMapNamespace = {
  Map: new (container: HTMLElement, options: Record<string, unknown>) => AMapInstance
  Marker: new (options: Record<string, unknown>) => AMapMarker
  InfoWindow: new (options: Record<string, unknown>) => AMapInfoWindow
  Pixel: new (x: number, y: number) => unknown
  ToolBar: new (options?: Record<string, unknown>) => unknown
}

declare global {
  interface Window {
    AMap?: AMapNamespace
    _AMapSecurityConfig?: { securityJsCode: string }
    __pblueAMapReady?: () => void
  }
}

const props = defineProps<{ restaurants: RestaurantPin[], activeId: string }>()
const emit = defineEmits<{ select: [id: string] }>()
const config = useRuntimeConfig()
const mapContainer = ref<HTMLElement | null>(null)
let mapLibreMap: MapLibreMap | undefined
let mapLibrePopup: Popup | undefined
let amapMap: AMapInstance | undefined
let amapInfoWindow: AMapInfoWindow | undefined
const mapLibreMarkers = new globalThis.Map<string, Marker>()
const markerElements = new globalThis.Map<string, HTMLElement>()

function markerElement(restaurant: RestaurantPin) {
  const element = document.createElement('button')
  const label = document.createElement('span')
  element.type = 'button'
  element.className = 'food-map-marker'
  label.textContent = Array.from(restaurant.name.trim())[0] ?? '店'
  element.append(label)
  element.setAttribute('aria-label', `查看${restaurant.name}`)
  markerElements.set(restaurant.id, element)
  return element
}

function popupContent(restaurant: RestaurantPin) {
  const content = document.createElement('div')
  const name = document.createElement('strong')
  const address = document.createElement('span')
  name.textContent = restaurant.name
  address.textContent = restaurant.address
  content.className = 'food-map-popup'
  content.append(name, address)
  return content
}

function updateActiveMarker() {
  markerElements.forEach((element, id) => element.classList.toggle('is-active', id === props.activeId))
}

watch(() => props.activeId, (id) => {
  updateActiveMarker()
  const restaurant = props.restaurants.find(item => item.id === id)
  if (!restaurant) return
  amapMap?.setZoomAndCenter(15, restaurant.coordinates)
  mapLibreMap?.flyTo({ center: gcj02ToWgs84(...restaurant.coordinates), zoom: 14.8, essential: true })
})

function loadAMap(key: string, securityCode: string) {
  return new Promise<AMapNamespace>((resolve, reject) => {
    if (window.AMap) return resolve(window.AMap)
    window._AMapSecurityConfig = { securityJsCode: securityCode }
    window.__pblueAMapReady = () => window.AMap ? resolve(window.AMap) : reject(new Error('高德地图加载失败'))
    const script = document.createElement('script')
    script.dataset.amapLoader = 'true'
    script.src = `https://webapi.amap.com/maps?v=2.0&key=${encodeURIComponent(key)}&plugin=AMap.ToolBar&callback=__pblueAMapReady`
    script.async = true
    script.onerror = () => reject(new Error('高德地图网络加载失败'))
    document.head.append(script)
  })
}

async function initAMap(key: string, securityCode: string) {
  if (!mapContainer.value) return
  const AMap = await loadAMap(key, securityCode)
  amapMap = new AMap.Map(mapContainer.value, {
    zoom: 12.4,
    center: [121.466, 31.221],
    viewMode: '2D',
    mapStyle: 'amap://styles/whitesmoke'
  })
  amapMap.addControl(new AMap.ToolBar({ position: 'RT' }))
  props.restaurants.forEach((restaurant) => {
    const element = markerElement(restaurant)
    const marker = new AMap.Marker({ map: amapMap, position: restaurant.coordinates, content: element, anchor: 'bottom-center' })
    marker.on('click', () => {
      emit('select', restaurant.id)
      amapInfoWindow?.close()
      amapInfoWindow = new AMap.InfoWindow({ content: popupContent(restaurant), offset: new AMap.Pixel(0, -28) })
      amapInfoWindow.open(amapMap!, restaurant.coordinates)
    })
  })
}

async function initMapLibre() {
  if (!mapContainer.value) return
  const maplibregl = await import('maplibre-gl')
  mapLibreMap = new maplibregl.Map({
    container: mapContainer.value,
    center: gcj02ToWgs84(121.466, 31.221),
    zoom: 12.4,
    minZoom: 10,
    maxZoom: 18,
    attributionControl: false,
    style: {
      version: 8,
      sources: { carto: { type: 'raster', tiles: ['https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', 'https://b.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'], tileSize: 256, attribution: '&copy; OpenStreetMap contributors &copy; CARTO' } },
      layers: [{ id: 'carto', type: 'raster', source: 'carto' }]
    }
  })
  mapLibreMap.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right')
  mapLibreMap.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right')
  props.restaurants.forEach((restaurant) => {
    const element = markerElement(restaurant)
    element.addEventListener('click', () => {
      emit('select', restaurant.id)
      mapLibrePopup?.remove()
      mapLibrePopup = new maplibregl.Popup({ offset: 24, closeButton: false })
        .setLngLat(gcj02ToWgs84(...restaurant.coordinates))
        .setDOMContent(popupContent(restaurant))
        .addTo(mapLibreMap!)
    })
    const marker = new maplibregl.Marker({ element, anchor: 'bottom' })
      .setLngLat(gcj02ToWgs84(...restaurant.coordinates))
      .addTo(mapLibreMap!)
    mapLibreMarkers.set(restaurant.id, marker)
  })
}

// AMap stores mainland coordinates as GCJ-02; the fallback map uses WGS84.
function gcj02ToWgs84(lng: number, lat: number): [number, number] {
  const a = 6378245
  const ee = 0.006693421622965943
  let dLat = transformLat(lng - 105, lat - 35)
  let dLng = transformLng(lng - 105, lat - 35)
  const radLat = lat / 180 * Math.PI
  let magic = Math.sin(radLat)
  magic = 1 - ee * magic * magic
  const sqrtMagic = Math.sqrt(magic)
  dLat = (dLat * 180) / ((a * (1 - ee) / (magic * sqrtMagic)) * Math.PI)
  dLng = (dLng * 180) / (a / sqrtMagic * Math.cos(radLat) * Math.PI)
  return [lng - dLng, lat - dLat]
}

function transformLat(x: number, y: number) {
  let value = -100 + 2 * x + 3 * y + .2 * y * y + .1 * x * y + .2 * Math.sqrt(Math.abs(x))
  value += (20 * Math.sin(6 * x * Math.PI) + 20 * Math.sin(2 * x * Math.PI)) * 2 / 3
  value += (20 * Math.sin(y * Math.PI) + 40 * Math.sin(y / 3 * Math.PI)) * 2 / 3
  return value + (160 * Math.sin(y / 12 * Math.PI) + 320 * Math.sin(y * Math.PI / 30)) * 2 / 3
}

function transformLng(x: number, y: number) {
  let value = 300 + x + 2 * y + .1 * x * x + .1 * x * y + .1 * Math.sqrt(Math.abs(x))
  value += (20 * Math.sin(6 * x * Math.PI) + 20 * Math.sin(2 * x * Math.PI)) * 2 / 3
  value += (20 * Math.sin(x * Math.PI) + 40 * Math.sin(x / 3 * Math.PI)) * 2 / 3
  return value + (150 * Math.sin(x / 12 * Math.PI) + 300 * Math.sin(x / 30 * Math.PI)) * 2 / 3
}

onMounted(async () => {
  const key = String(config.public.amapKey || '')
  const securityCode = String(config.public.amapSecurityCode || '')
  if (key && securityCode) {
    try {
      await initAMap(key, securityCode)
    } catch {
      await initMapLibre()
    }
  } else {
    await initMapLibre()
  }
  updateActiveMarker()
})

onBeforeUnmount(() => {
  amapInfoWindow?.close()
  amapMap?.destroy()
  mapLibrePopup?.remove()
  mapLibreMap?.remove()
  mapLibreMarkers.clear()
  markerElements.clear()
  delete window.__pblueAMapReady
})
</script>

<template>
  <div ref="mapContainer" class="food-map" role="application" aria-label="上海进食推荐地图" />
</template>
