#!/usr/bin/env bash
# 校验 skills/ 下所有 skill 是否符合 AGENTS.md 中的规则。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
errors=0

err() { echo "  ✗ $1"; errors=$((errors + 1)); }

# 读取 frontmatter 中某个字段（仅支持单行值）
fm_field() {
  awk -v key="$2" '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---" { exit }
    NR>1 { if (index($0, key ":")==1) { sub("^" key ":[ ]*", ""); print; exit } }
  ' "$1"
}

for dir in "$SKILLS_DIR"/*/; do
  [ -d "$dir" ] || continue
  dirname="$(basename "$dir")"
  skill_md="$dir/SKILL.md"
  echo "▸ $dirname"

  [[ "$dirname" =~ ^kai-[a-z0-9-]+$ ]] || err "目录名必须以 kai- 开头，且只含小写字母、数字、-"
  [ ${#dirname} -le 64 ] || err "名称超过 64 字符"

  if [ ! -f "$skill_md" ]; then
    err "缺少 SKILL.md"
    continue
  fi

  name="$(fm_field "$skill_md" name)"
  desc="$(fm_field "$skill_md" description)"
  [ "$name" = "$dirname" ] || err "frontmatter name ($name) 与目录名不一致"
  [ -n "$desc" ] || err "缺少 description"
  [ ${#desc} -le 1024 ] || err "description 超过 1024 字符 (${#desc})"

  lines=$(wc -l < "$skill_md" | tr -d ' ')
  [ "$lines" -le 500 ] || err "SKILL.md 共 $lines 行，建议拆分到 references/"

  # 检查 SKILL.md 中引用的 references/、assets/、scripts/ 文件是否存在
  while IFS= read -r ref; do
    [ -e "$dir/$ref" ] || err "引用的文件不存在：$ref"
  done < <(grep -oE '(references|assets|scripts)/[A-Za-z0-9._/-]+\.[a-z]+' "$skill_md" | sort -u)

  # 禁止引用 skill 目录之外的文件
  if grep -nE '\.\./' "$skill_md" >/dev/null; then
    err "SKILL.md 中存在 ../ 引用，skill 必须自包含"
  fi
done

if [ "$errors" -gt 0 ]; then
  echo "校验失败：$errors 个问题"
  exit 1
fi
echo "校验通过"
