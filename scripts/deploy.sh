#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly IMAGE_NAME="${IMAGE_NAME:-pblue-web:latest}"
readonly CONTAINER_NAME="${CONTAINER_NAME:-pblue-web}"
readonly BACKUP_NAME="${CONTAINER_NAME}-rollback"
readonly HOST_PORT="${HOST_PORT:-8037}"
readonly PULL_BASE_IMAGES="${PULL_BASE_IMAGES:-0}"

log() {
  printf '\n\033[1;34m[pblue-web]\033[0m %s\n' "$*"
}

fail() {
  printf '\n\033[1;31m[pblue-web] 错误：\033[0m %s\n' "$*" >&2
  exit 1
}

if ! command -v docker >/dev/null 2>&1; then
  fail "未找到 Docker，请先安装并启动 Docker Engine。"
fi

if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
elif command -v sudo >/dev/null 2>&1 && sudo -n docker info >/dev/null 2>&1; then
  DOCKER=(sudo docker)
else
  fail "当前用户无权访问 Docker。请执行：sudo $0"
fi

cd "${PROJECT_DIR}"

log "构建新镜像 ${IMAGE_NAME}"
build_args=()
build_options=()
if [[ "${PULL_BASE_IMAGES}" == "1" ]]; then
  build_options+=(--pull)
fi
if [[ -n "${NUXT_PUBLIC_AMAP_KEY:-}" && -n "${NUXT_PUBLIC_AMAP_SECURITY_CODE:-}" ]]; then
  build_args+=(
    --build-arg "NUXT_PUBLIC_AMAP_KEY=${NUXT_PUBLIC_AMAP_KEY}"
    --build-arg "NUXT_PUBLIC_AMAP_SECURITY_CODE=${NUXT_PUBLIC_AMAP_SECURITY_CODE}"
  )
fi
"${DOCKER[@]}" build "${build_options[@]}" "${build_args[@]}" -t "${IMAGE_NAME}" .

had_previous=false
if "${DOCKER[@]}" container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
  had_previous=true

else
  listener_pid="$(ss -ltnp "( sport = :${HOST_PORT} )" 2>/dev/null \
    | sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p' \
    | head -n 1)"

  if [[ -n "${listener_pid}" && -r "/proc/${listener_pid}/cmdline" ]]; then
    listener_command="$(tr '\0' ' ' < "/proc/${listener_pid}/cmdline")"
    listener_cwd="$(readlink -f "/proc/${listener_pid}/cwd" 2>/dev/null || true)"

    if [[ "${listener_cwd}" == "${PROJECT_DIR}"* \
      && "${listener_command}" == *"nuxt"* \
      && "${listener_command}" == *"dev"* ]]; then
      log "镜像已构建，正在停止占用 ${HOST_PORT} 的本项目开发服务（PID ${listener_pid}）"
      kill -TERM "${listener_pid}"

      for _ in {1..20}; do
        if ! ss -ltn "( sport = :${HOST_PORT} )" 2>/dev/null | grep -q LISTEN; then
          break
        fi
        sleep .25
      done
    fi
  fi

  if ss -ltn "( sport = :${HOST_PORT} )" 2>/dev/null | grep -q LISTEN; then
    fail "端口 ${HOST_PORT} 已被其他程序占用。请先停止该程序后重试。"
  fi
fi

if [[ "${had_previous}" == true ]]; then

  if "${DOCKER[@]}" container inspect "${BACKUP_NAME}" >/dev/null 2>&1; then
    log "清理上次遗留的回滚容器"
    "${DOCKER[@]}" rm -f "${BACKUP_NAME}"
  fi

  log "暂存当前容器，以便失败时回滚"
  "${DOCKER[@]}" stop "${CONTAINER_NAME}" >/dev/null
  "${DOCKER[@]}" rename "${CONTAINER_NAME}" "${BACKUP_NAME}"
fi

rollback() {
  log "新版本启动失败，正在恢复旧容器"
  "${DOCKER[@]}" rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

  if [[ "${had_previous}" == true ]]; then
    "${DOCKER[@]}" rename "${BACKUP_NAME}" "${CONTAINER_NAME}"
    "${DOCKER[@]}" start "${CONTAINER_NAME}" >/dev/null
  fi

  fail "部署失败；旧版本已恢复。"
}

log "启动新容器，监听 127.0.0.1:${HOST_PORT}"
if ! "${DOCKER[@]}" run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "127.0.0.1:${HOST_PORT}:80" \
  "${IMAGE_NAME}" >/dev/null; then
  rollback
fi

healthy=false
for _ in {1..20}; do
  if "${DOCKER[@]}" exec "${CONTAINER_NAME}" \
    wget -qO- http://127.0.0.1/healthz >/dev/null 2>&1; then
    healthy=true
    break
  fi
  sleep 1
done

if [[ "${healthy}" != true ]]; then
  "${DOCKER[@]}" logs --tail 50 "${CONTAINER_NAME}" || true
  rollback
fi

if [[ "${had_previous}" == true ]]; then
  "${DOCKER[@]}" rm "${BACKUP_NAME}" >/dev/null
fi

log "部署完成"
printf '本机地址：http://127.0.0.1:%s\n' "${HOST_PORT}"
printf '公开地址：https://pblue.dpdns.org/\n'
printf 'Cloudflare Tunnel 无需重启。\n'
