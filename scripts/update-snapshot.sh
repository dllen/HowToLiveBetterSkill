#!/usr/bin/env bash
# update-snapshot.sh — 用 upstream/ 子模块的当前版本刷新 data/ 快照：
# 书的正文（book/ docs/ README.md index.html）+ 预构建索引（index/）+ SNAPSHOT 版本标记。
# data/ 提交进仓库，install.sh 在没子模块也没网时用它装出静态缓存。
# 同步上游的流程：git -C upstream pull && ./scripts/update-snapshot.sh && 提交。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UP="$ROOT/upstream"
DATA="$ROOT/data"

if [ ! -f "$UP/book/01-不要早死.md" ]; then
  echo "upstream/ 子模块未检出，先跑：git submodule update --init" >&2
  exit 1
fi

rm -rf "$DATA"
mkdir -p "$DATA"
cp -R "$UP/book" "$UP/docs" "$DATA/"
cp "$UP/README.md" "$UP/index.html" "$DATA/"

git -C "$UP" log -1 --format='commit=%h%ndate=%cd' --date=short > "$DATA/SNAPSHOT"

bash "$ROOT/skills/how-to-live-better/scripts/build-index.sh" "$UP" "$DATA/index"

echo "快照已刷新：${DATA}（$(tr '\n' ' ' < "$DATA/SNAPSHOT")）"
