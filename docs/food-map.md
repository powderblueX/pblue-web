# 上海进食地图维护手册

店铺文件位于 `apps/web/content/food/`。每家店一个 Markdown 文件，页面会自动读取、排序并生成地图标记。

## 添加店铺

复制任意现有文件并改成新的英文文件名，例如 `new-shop.md`：

```md
---
slug: new-shop
name: 新店名
order: 7
district: 黄浦
party:
  - 单人
  - 多人
price: ¥¥
address: 某某路 100 号
longitude: 121.000000
latitude: 31.000000
recommendation: 招牌菜一、招牌菜二
note: 一句自己的推荐理由。
mapUrl: https://ditu.amap.com/...
---
```

- `slug` 必须是唯一的英文小写标识，推荐与文件名一致。
- `order` 决定页面顺序，数字越小越靠前。
- `district` 用于自动生成区域筛选项，例如 `黄浦`、`虹口`。
- `party` 至少填写一项，可填 `单人`、`多人`，两项都填表示两种场景都适合。
- `price` 可填写 `¥`、`¥¥`、`¥¥¥`。
- 经纬度使用高德坐标拾取器给出的顺序：`longitude` 是经度，`latitude` 是纬度。
- `mapUrl` 填该店的高德详情页或搜索链接。

## 删除与调整

- 下架店铺：删除对应的 `.md` 文件。
- 修改店铺：直接编辑对应文件并保存。
- 调整顺序：修改各文件中的 `order`。
- 开发模式会自动刷新；正式站点仍需重新部署。

## 启用高德地图

高德地图 JS API 2.0 需要申请“Web 端（JS API）”Key 和安全密钥。创建 `apps/web/.env`：

```dotenv
NUXT_PUBLIC_AMAP_KEY=你的Key
NUXT_PUBLIC_AMAP_SECURITY_CODE=你的安全密钥
```

随后重启 `pnpm dev`。两个值都有时页面使用高德；未配置或加载失败时自动回退到免密地图。

当前是纯静态个人站，因此安全密钥会随前端代码公开。请务必在高德控制台为 Key 配置域名白名单，只允许 `pblue.dpdns.org` 和本地开发域名。若以后站点流量增大，应改用高德官方推荐的服务端代理模式。

Docker 部署直接运行自动发布脚本；它会读取同一个 `.env` 文件：

```bash
./scripts/publish.sh
```

## 发布前检查

```bash
pnpm typecheck
pnpm test
pnpm generate
```
