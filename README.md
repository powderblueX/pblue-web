# powderblueX Web

powderblueX 是一个使用 Nuxt Content 构建的个人随笔网站。

The repository is intentionally a platform foundation, not a generic blog template. It establishes a clear boundary between the web application, deployment configuration, and learning documentation without creating unused services or packages.

## Architecture

```text
Markdown content + Nuxt/Vue
          │
          ▼
   static generation
          │
          ▼
    Nginx container :80
          │
          ▼
 host 127.0.0.1:8037
          │
          ▼
   Cloudflare Tunnel
```

The browser receives static HTML, CSS, and JavaScript. There is no database, application server, authentication layer, or runtime secret in v0.1. See [the architecture overview](docs/architecture/overview.md) for decisions and future boundaries.

## Technology stack

- Nuxt 4, Vue 3, and strict TypeScript
- Nuxt Content 3 for typed Markdown collections and Shiki code highlighting
- Tailwind CSS 4 as the CSS toolchain; the visual system lives in one intentional stylesheet
- pnpm workspace with one real application (`apps/web`)
- Vitest and Nuxt type checking
- Multi-stage Docker build and Nginx runtime
- Plain Kubernetes Deployment and Service manifests

## Repository structure

```text
.
├── apps/web/                 # Nuxt application and Markdown content
├── docs/
│   ├── architecture/         # Current boundaries and evolution triggers
│   └── learning/             # Project-specific deployment and K8s notes
├── infra/
│   ├── k8s/                  # Minimal Deployment and Service
│   └── nginx/                # Static runtime configuration
├── .github/workflows/ci.yml  # Verification only; no production deploy
├── Dockerfile
├── package.json
└── pnpm-workspace.yaml
```

There is no `packages/` or `services/` directory yet because no shared package or backend exists.

## Prerequisites

- Node.js 24.x
- pnpm 10.15 or compatible 10.x
- Docker Engine for container verification

## Local development

```bash
pnpm install
pnpm dev
```

开发服务固定运行在 `http://localhost:8037`，保存文件后自动更新。完整说明见 [开发手册](docs/development.md)。

## Verification and static build

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm generate
```

Generated production files are written to `apps/web/.output/public`.

## Docker

Build and run without relying on a host Node installation at runtime:

```bash
docker build -t pblue-web .
docker run --rm --name pblue-web -p 127.0.0.1:8037:80 pblue-web
```

Then open:

- `http://127.0.0.1:8037`
- `http://127.0.0.1:8037/blog`
- `http://127.0.0.1:8037/healthz`

The host port `8037` is deployment configuration. The application and container only know port `80`.

### One-command update

After changing the site, rebuild and replace the running container with:

```bash
sudo ./scripts/deploy.sh
```

The script builds the new image before stopping the current container, starts it
with `--restart unless-stopped`, checks `/healthz`, and restores the previous
container if the new version cannot start. The Cloudflare Tunnel continues to use
`127.0.0.1:8037`, so it normally does not need to be restarted.

## Adding a blog post

Create `apps/web/content/blog/my-note.md`:

```yaml
---
title: My Note
description: A concrete one-sentence summary.
publishedAt: 2026-09-23
tags:
  - Systems
draft: false
---
```

Use a lowercase kebab-case filename; it becomes `/blog/my-note`. The static crawler discovers published articles from the blog index automatically. Add the canonical URL to `apps/web/public/sitemap.xml` so search-engine discovery remains explicit and reviewable.

## Infrastructure and learning path

- [Ubuntu and Docker deployment](docs/learning/deployment.md)
- [Kubernetes objects in this project](docs/learning/kubernetes.md)
- [Architecture and future evolution](docs/architecture/overview.md)
- [Visual system](docs/design.md)

`infra/` contains deployable configuration, never credentials. Cloudflare Tunnel credentials, DNS management, server paths, and tokens stay outside this repository.

## Future evolution

The next module should be introduced only when a real capability requires it. An independent API becomes justified when the site needs live metrics, container or cluster state, AI workloads, or other privileged integrations. Shared packages become justified only after at least two real consumers need the same code. Kubernetes becomes operationally useful when reconciliation, rollout, or multi-instance behavior is worth its added complexity.
