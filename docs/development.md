# powderblueX 开发手册

项目目录：`/home/powderbluex/Projects/pblue-web`

## 1. 启动、关闭与重启

开发服务固定使用 `8037` 端口，保存文件后页面会自动更新。若端口被占用，服务会直接报错，不会自动改用 3000 等其他端口。

```bash
cd /home/powderbluex/Projects/pblue-web
pnpm dev
```

访问：

- 本机：<http://localhost:8037>
- 域名：<https://pblue.dpdns.org>

临时关闭：回到运行 `pnpm dev` 的终端，按 `Ctrl+C`。

重启：先按 `Ctrl+C`，再运行：

```bash
pnpm dev
```

检查服务是否正常：

```bash
curl -I http://localhost:8037
```

> 开发服务和 Docker 正式站点都使用 8037，不能同时运行。

## 2. 开发模式与正式站点

### 日常修改：开发模式

使用 `pnpm dev`。它支持热更新，适合写文档、改页面和调样式。

如果 Docker 正式站点正在占用 8037，先停止它：

```bash
docker stop pblue-web
pnpm dev
```

### 恢复 Docker 正式站点

先用 `Ctrl+C` 关闭开发服务，再运行：

```bash
docker start pblue-web
```

查看容器状态：

```bash
docker ps --filter name=pblue-web
```

代码修改后需要重新发布 Docker 版本时：

```bash
./scripts/publish.sh
```

发布脚本会自动读取 `apps/web/.env`、检查高德 Key，并调用带回滚能力的 Docker 部署流程。只有新镜像构建成功后，它才会停止本项目占用 8037 的开发服务；构建失败时，当前开发服务或正式容器会继续运行。若 8037 被其他程序占用，部署会停止并保留旧版本。

默认会优先复用本机已有的 Docker 基础镜像和构建缓存。如需主动检查并拉取基础镜像的新版本，可运行：

```bash
PULL_BASE_IMAGES=1 ./scripts/publish.sh
```

## 3. 写小作文

文档存放在：

```text
apps/web/content/blog/
```

编辑已有 `.md` 文件，保存后页面会自动更新。新增文档时创建一个英文小写文件名，例如 `weekend-coffee.md`：

```md
---
title: 周末的一杯咖啡
description: 显示在文档列表中的一句简介。
publishedAt: '2026-09-24'
tags:
  - 日常
  - 心情
draft: false
---

这里开始写正文。

可以使用普通 Markdown，包括标题、列表、引用和链接。
```

规则：

- 文件名会成为网址：`weekend-coffee.md` → `/blog/weekend-coffee`。
- `draft: true` 表示暂不公开，`false` 或不填写表示公开。
- 日期使用 `YYYY-MM-DD`。
- 新文档发布时，同时把网址添加到 `apps/web/public/sitemap.xml`。

### 写专业文档

在 `apps/web/content/articles/` 中新建 `.md` 文件，格式与小作文一致：

```md
---
title: 空白
description: 空白。
publishedAt: '2026-09-24'
tags: []
draft: false
---

空白。
```

文件名会成为 `/articles/文件名`。发布后，同样把该网址加入 `apps/web/public/sitemap.xml`。

## 4. 常用修改位置

| 内容 | 文件 |
| --- | --- |
| 首页文字与结构 | `apps/web/app/pages/index.vue` |
| 小作文列表 | `apps/web/app/pages/blog/index.vue` |
| 小作文阅读页 | `apps/web/app/pages/blog/[slug].vue` |
| 专业文档列表 | `apps/web/app/pages/articles/index.vue` |
| 专业文档阅读页 | `apps/web/app/pages/articles/[slug].vue` |
| 顶部导航 | `apps/web/app/components/SiteHeader.vue` |
| 页脚 | `apps/web/app/components/SiteFooter.vue` |
| 全站颜色、排版和动画 | `apps/web/app/assets/css/main.css` |
| 网站图标 | `apps/web/public/favicon.svg` |
| Nuxt 与域名配置 | `apps/web/nuxt.config.ts` |

上海进食地图的店铺增删、坐标填写和高德地图配置，见 [`docs/food-map.md`](food-map.md)。

## 5. 修改后的检查

日常修改至少运行：

```bash
pnpm typecheck
pnpm test
```

准备正式发布前运行：

```bash
pnpm typecheck
pnpm test
pnpm generate
```

静态构建结果位于：

```text
apps/web/.output/public/
```

## 6. 常见问题

### 8037 已被占用

通常是开发服务或 Docker 容器仍在运行。先关闭当前服务；若是 Docker：

```bash
docker stop pblue-web
```

### 修改文档后没有更新

确认终端中的 `pnpm dev` 仍在运行，然后刷新浏览器。若配置文件发生变化，Nuxt 会自动重启。

### 域名提示 `host is not allowed`

允许的域名配置在 `apps/web/nuxt.config.ts` 的 `vite.server.allowedHosts` 中。当前已经允许 `pblue.dpdns.org`。

### 依赖缺失

```bash
pnpm install
```
