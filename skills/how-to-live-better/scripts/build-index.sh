#!/usr/bin/env bash
# build-index.sh — 从《高性价比人生指南》正文生成三份速查索引：
#   entries.md    条目定位索引（编号/标题/成本标签/证据等级，只定位，不替代正文）
#   sections.md   节目录（这节回答什么问题 → book/ 下哪个文件）
#   algorithm.md  性价比档位算法（index.html 里的 COST_W 和 e.ratio 两行）
#
# 用法：build-index.sh [REPO_DIR] [OUT_DIR]
#   REPO_DIR  默认 ${XDG_CACHE_HOME:-~/.cache}/how-to-live-better/repo
#   OUT_DIR   默认 REPO_DIR 同级的 index/
# 输出全部落在缓存目录，不内嵌进 skill——正文更新后重跑本脚本即可。

set -euo pipefail

REPO="${1:-${XDG_CACHE_HOME:-$HOME/.cache}/how-to-live-better/repo}"
OUT="${2:-$(dirname "$REPO")/index}"

if [ ! -d "$REPO/book" ]; then
  echo "找不到 ${REPO}/book，跳过索引生成。" >&2
  exit 1
fi
mkdir -p "$OUT"

BOOK_DATE=$(git -C "$REPO" log -1 --format=%cd --date=short 2>/dev/null || echo "未知")

# 1) 条目索引
{
  echo "# 条目索引（正文版本 ${BOOK_DATE}，生成于 $(date +%F)）"
  echo
  echo "只用于定位：找到条目后必须回原文整条读完（备注栏有适用人群、争议、例外）。"
  echo
  echo "| 编号 | 标题 | 钱 | 时间 | 毅力 | 收益 | 口径 | 证据 |"
  echo "| --- | --- | --- | --- | --- | --- | --- | --- |"
  for f in "$REPO"/book/*.md; do
    sec=$(basename "$f" | cut -d- -f1)
    awk -v sec="$sec" '
      function flush() {
        if (num != "") {
          gsub(/\|/, "/", title)
          printf "| %s-%s | %s | %s | %s | %s | %s | %s | %s |\n", sec, num, title, money, time_, will, gain, dim, ev
        }
      }
      /^### / {
        flush()
        line = $0; sub(/^### /, "", line)
        num = line; sub(/\..*/, "", num)
        title = line; sub(/^[0-9]+\. */, "", title)
        money = time_ = will = gain = dim = ev = ""
        next
      }
      /成本标签:/ {
        for (i = 1; i <= NF; i++) {
          t = $i
          if (t ~ /^钱=/)   { sub(/^钱=/, "", t);   money = t }
          if (t ~ /^时间=/) { sub(/^时间=/, "", t); time_ = t }
          if (t ~ /^毅力=/) { sub(/^毅力=/, "", t); will = t }
          if (t ~ /^收益=/) { sub(/^收益=/, "", t); gain = t }
          if (t ~ /^口径=/) { sub(/^口径=/, "", t); dim = t }
        }
        next
      }
      /^- 证据等级：/ {
        t = $0; sub(/^- 证据等级：/, "", t); sub(/[ 　].*/, "", t); ev = t
        next
      }
      END { flush() }
    ' "$f"
  done
} > "$OUT/entries.md"

# 2) 节目录（解析 README「这本书想回答的问题」表）
{
  echo "# 节目录（正文版本 ${BOOK_DATE}）"
  echo
  echo "| 节 | 回答的问题 | 文件 |"
  echo "| --- | --- | --- |"
  grep -E '^\|.*\]\(.*book/' "$REPO/README.md" | awk -F'|' '
    {
      q = $2; gsub(/^[ \t]+|[ \t]+$/, "", q)
      name = $3; sub(/.*\[/, "", name); sub(/\].*/, "", name)
      secnum = name; sub(/\..*/, "", secnum)
      if (secnum ~ /^[0-9]+$/) printf "%s\t%s\t%s\n", secnum, q, name
    }' | sort -u -t"$(printf '\t')" -k1,1n | while IFS="$(printf '\t')" read -r secnum q name; do
      f=$(ls "$REPO/book/$(printf '%02d' "$secnum")"-*.md 2>/dev/null | head -1)
      [ -n "$f" ] && printf '| %s | %s | %s |\n' "$name" "$q" "$(basename "$f")"
    done
} > "$OUT/sections.md"

# 3) 性价比算法
{
  echo "# 性价比档位算法（摘自 index.html，正文版本 ${BOOK_DATE}）"
  echo
  echo '```js'
  grep -h 'const COST_W = ' "$REPO/index.html"
  grep -h -A1 'e\.ratio = ' "$REPO/index.html"
  echo '```'
  echo
  echo "成本分 = 钱档 + 时间档 + 毅力档（按 COST_W 查表折算成分数后相加）；e.ratio 那行是收益量级配上成本分落到「极高 / 高 / 一般」的规则。"
} > "$OUT/algorithm.md"

echo "索引已生成到 ${OUT}（entries $(grep -c '^|' "$OUT/entries.md") 行 / sections $(grep -c '^|' "$OUT/sections.md") 行）"
