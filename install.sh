#!/usr/bin/env bash
# install.sh — 把 how-to-live-better skill 装到本机各 Agent 的 skill 目录。
#
# 用法：
#   ./install.sh              自动检测本机装了哪些 Agent，装到对应目录
#   ./install.sh --all        不检测，全部目标都装
#   ./install.sh --no-book    跳过正文克隆（可与其它参数组合）
#   ./install.sh --uninstall  从所有目标目录移除（含正文缓存）
#   ./install.sh --list       列出支持的目标和检测结果
#
# 安装策略：实体文件放在通用目录 ~/.agents/skills/how-to-live-better
# （Codex / Cursor / Gemini CLI / GitHub Copilot / OpenCode 都读这里），
# 其余目标目录用符号链接指过去，以后 git pull 更新一处即可。
# 书的正文克隆到 ${XDG_CACHE_HOME:-~/.cache}/how-to-live-better/repo，
# 装完即离线可用；skill 运行时距上次更新超 24h 会自动 pull，
# 重跑本脚本也会更新正文。

set -euo pipefail

SKILL_NAME="how-to-live-better"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/$SKILL_NAME"
CANONICAL="$HOME/.agents/skills/$SKILL_NAME"
BOOK_REPO="${XDG_CACHE_HOME:-$HOME/.cache}/how-to-live-better/repo"

if [ ! -f "$SRC/SKILL.md" ]; then
  echo "找不到 $SRC/SKILL.md，请在项目根目录运行本脚本。" >&2
  exit 1
fi

# 目标列表：显示名 | skill 目录 | 检测依据（目录存在即认为装了该 Agent）
TARGETS=(
  "Universal (Codex/Cursor/Gemini CLI/Copilot/OpenCode)|$HOME/.agents/skills|$HOME/.codex|$HOME/.cursor|$HOME/.gemini|$HOME/.copilot|$HOME/.config/opencode|$HOME/.agents"
  "Claude Code|$HOME/.claude/skills|$HOME/.claude"
  "Hermes Agent|$HOME/.hermes/skills|$HOME/.hermes"
  "Gemini CLI (专属目录)|$HOME/.gemini/skills|$HOME/.gemini"
  "Cursor (专属目录)|$HOME/.cursor/skills|$HOME/.cursor"
  "GitHub Copilot (专属目录)|$HOME/.copilot/skills|$HOME/.copilot"
)

MODE="auto"
NO_BOOK=false
for arg in "$@"; do
  case "$arg" in
    --all) MODE="all" ;;
    --uninstall) MODE="uninstall" ;;
    --list) MODE="list" ;;
    --no-book) NO_BOOK=true ;;
    *) echo "未知参数：${arg}（支持 --all / --no-book / --uninstall / --list）" >&2; exit 1 ;;
  esac
done

target_detected() {
  local entry="$1"
  IFS='|' read -ra parts <<< "$entry"
  local probes=("${parts[@]:2}")
  for p in "${probes[@]}"; do
    [ -d "$p" ] && return 0
  done
  return 1
}

link_skill() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"
  local dest="$dest_dir/$SKILL_NAME"
  if [ -L "$dest" ] || [ -e "$dest" ]; then
    rm -rf "$dest"
  fi
  ln -s "$CANONICAL" "$dest"
  echo "  -> $dest"
}

if [ "$MODE" = "list" ]; then
  echo "支持的安装目标（* = 已检测到）："
  for entry in "${TARGETS[@]}"; do
    IFS='|' read -ra parts <<< "$entry"
    mark=" "
    target_detected "$entry" && mark="*"
    echo "  [$mark] ${parts[0]}  ->  ${parts[1]}"
  done
  exit 0
fi

if [ "$MODE" = "uninstall" ]; then
  echo "移除 ${SKILL_NAME}："
  for entry in "${TARGETS[@]}"; do
    IFS='|' read -ra parts <<< "$entry"
    dest="${parts[1]}/$SKILL_NAME"
    if [ -L "$dest" ] || [ -e "$dest" ]; then
      rm -rf "$dest"
      echo "  已移除 $dest"
    fi
  done
  if [ -d "$(dirname "$BOOK_REPO")" ]; then
    rm -rf "$(dirname "$BOOK_REPO")"
    echo "  已移除正文缓存 $(dirname "$BOOK_REPO")"
  fi
  echo "完成。"
  exit 0
fi

# 第一步：装实体文件到通用目录
mkdir -p "$(dirname "$CANONICAL")"
if [ -L "$CANONICAL" ]; then
  rm -f "$CANONICAL"
fi
if [ "$CANONICAL" != "$SRC" ]; then
  rm -rf "$CANONICAL"
  cp -R "$SRC" "$CANONICAL"
fi
echo "实体文件：$CANONICAL"

# 第二步：为其余目标建符号链接
installed_any=false
for entry in "${TARGETS[@]}"; do
  IFS='|' read -ra parts <<< "$entry"
  name="${parts[0]}"
  dest_dir="${parts[1]}"
  dest="$dest_dir/$SKILL_NAME"

  [ "$dest" = "$CANONICAL" ] && continue   # 通用目录已是实体

  if [ "$MODE" = "all" ] || target_detected "$entry"; then
    echo "${name}："
    link_skill "$dest_dir"
    installed_any=true
  fi
done

if [ "$installed_any" = false ] && [ "$MODE" = "auto" ]; then
  echo ""
  echo "没有检测到任何 Agent 的配置目录，只装了通用目录 ${CANONICAL}。"
  echo "Codex / Cursor / Gemini CLI / Copilot / OpenCode 会直接读到它。"
  echo "其他 Agent 可用 ./install.sh --all 强制全装，或看 README 手动安装。"
fi

# 第三步：克隆书的正文到缓存目录（装完即离线可用；重跑本脚本即更新）
if [ "$NO_BOOK" = true ]; then
  echo ""
  echo "按 --no-book 跳过正文克隆。"
elif [ -d "$BOOK_REPO/.git" ]; then
  echo ""
  echo "更新正文缓存："
  if git -C "$BOOK_REPO" pull --ff-only --quiet; then
    echo "  已是最新：${BOOK_REPO}（$(git -C "$BOOK_REPO" log -1 --format=%cd --date=short)）"
  else
    echo "  拉取失败，保留现有缓存（离线可继续用）。"
  fi
else
  echo ""
  echo "克隆正文（约 1.3 MB）："
  if git clone --depth 1 --quiet https://github.com/eternity4719/HowToLiveBetter.git "$BOOK_REPO"; then
    touch "$BOOK_REPO/.git/FETCH_HEAD"   # clone 不产生 FETCH_HEAD，补一个作为新鲜度时间戳
    echo "  -> $BOOK_REPO"
  else
    echo "  克隆失败（没网？）。skill 已装好，首次使用时会自动重试。" >&2
  fi
fi

echo ""
echo "完成。重启你的 Agent 后，问「每天通勤两小时值不值」之类的问题即可触发。"
