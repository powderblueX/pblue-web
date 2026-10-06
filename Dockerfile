FROM node:24-alpine AS builder

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /workspace

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY apps/web/package.json apps/web/package.json
RUN pnpm install --frozen-lockfile

COPY apps/web apps/web
ARG NUXT_PUBLIC_AMAP_KEY=""
ARG NUXT_PUBLIC_AMAP_SECURITY_CODE=""
ENV NUXT_PUBLIC_AMAP_KEY=$NUXT_PUBLIC_AMAP_KEY
ENV NUXT_PUBLIC_AMAP_SECURITY_CODE=$NUXT_PUBLIC_AMAP_SECURITY_CODE
RUN pnpm --dir apps/web generate

FROM nginx:1.29-alpine AS runtime

COPY infra/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /workspace/apps/web/.output/public /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1
