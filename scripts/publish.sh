#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly ENV_FILE="${PROJECT_DIR}/apps/web/.env"

log() {
  printf '\n\033[1;34m[pblue-web publish]\033[0m %s\n' "$*"
}

fail() {
  printf '\n\033[1;31m[pblue-web publish] 错误：\033[0m %s\n' "$*" >&2
  exit 1
}

if [[ ! -f "${ENV_FILE}" ]]; then
  fail "未找到 ${ENV_FILE}。请先从 apps/web/.env.example 复制并填写高德配置。"
fi

set -a
# 此文件由站点维护者管理，用于向 Nuxt 构建传递环境变量。
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if [[ -z "${NUXT_PUBLIC_AMAP_KEY:-}" ]]; then
  fail "apps/web/.env 中缺少 NUXT_PUBLIC_AMAP_KEY。"
fi

if [[ -z "${NUXT_PUBLIC_AMAP_SECURITY_CODE:-}" ]]; then
  fail "apps/web/.env 中缺少 NUXT_PUBLIC_AMAP_SECURITY_CODE。"
fi

log "开始构建并发布正式版本"

if [[ "${EUID}" -eq 0 ]]; then
  exec "${SCRIPT_DIR}/deploy.sh"
else
  exec sudo \
    --preserve-env=NUXT_PUBLIC_AMAP_KEY,NUXT_PUBLIC_AMAP_SECURITY_CODE,HOST_PORT,IMAGE_NAME,CONTAINER_NAME,PULL_BASE_IMAGES \
    "${SCRIPT_DIR}/deploy.sh"
fi
