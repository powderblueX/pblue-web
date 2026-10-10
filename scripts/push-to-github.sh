#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly COMMIT_MESSAGE="${*:-Update website}"

fail() {
  printf '错误：%s\n' "$*" >&2
  exit 1
}

cd "${PROJECT_DIR}"

[[ "$(git rev-parse --show-toplevel)" == "${PROJECT_DIR}" ]] || fail "请在本项目的 Git 仓库中运行。"
[[ "$(git branch --show-current)" == "main" ]] || fail "当前不在 main 分支。"
git remote get-url origin >/dev/null 2>&1 || fail "未配置 origin 远端仓库。"

git add -A

while IFS= read -r -d '' file; do
  case "${file}" in
    .env|*/.env|.env.*|*/.env.*|*.pem|*.key|*credential*|*secret*)
      case "${file}" in
        .env.example|*/.env.example) ;;
        *) fail "暂存区包含可能敏感的文件：${file}。请先检查并移出暂存区。" ;;
      esac
      ;;
  esac
done < <(git diff --cached --name-only -z)

if git diff --cached --quiet; then
  printf '没有新改动，检查远端是否需要推送。\n'
else
  printf '本次提交的文件：\n'
  git diff --cached --name-only
  read -r -p '确认提交并推送这些文件？输入 yes 继续：' confirmation || fail "未获得确认，已停止。"
  [[ "${confirmation}" == "yes" ]] || fail "已取消提交和推送。"
  git commit -m "${COMMIT_MESSAGE}"
fi

git push -u origin main
printf '已推送到 GitHub。Cloudflare Pages 会自动开始构建。\n'
