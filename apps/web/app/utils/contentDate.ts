export function formatContentDate(date?: string | null) {
  if (!date) return '日期未设置'

  const normalized = /^\d{4}-\d{2}-\d{2}$/.test(date) ? `${date}T00:00:00Z` : date
  const value = new Date(normalized)
  if (Number.isNaN(value.getTime())) return '日期未设置'

  return new Intl.DateTimeFormat('zh-CN', { dateStyle: 'long', timeZone: 'UTC' }).format(value)
}
