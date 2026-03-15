#!/usr/bin/env bash
# 在 lib/ 下查找仍包含中文的 Dart 源码（排除 l10n 生成文件），便于按文件分批迁移到 ARB。
# 仅用系统自带 find + perl，无需安装 ripgrep。
# 用法: ./scripts/find_chinese_in_lib.sh

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# 用 perl 匹配 CJK 统一汉字（macOS 自带 perl）
perl_han='[\x{4e00}-\x{9fff}]'

echo "=== 仍包含中文的 lib 文件（不含 l10n 生成与 arb）==="
find lib -type f -name '*.dart' ! -path '*/l10n/app_localizations*' -print0 2>/dev/null | while IFS= read -r -d '' f; do
  perl -CSD -ne "print \"\$ARGV:\$.: \$_\" if /$perl_han/" "$f" 2>/dev/null || true
done

echo ""
echo "=== 按文件统计（含中文的行数）==="
find lib -type f -name '*.dart' ! -path '*/l10n/app_localizations*' -print0 2>/dev/null | while IFS= read -r -d '' f; do
  lines=$(perl -CSD -ne "print \"\$_\" if /$perl_han/" "$f" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$lines" -gt 0 ]; then
    echo "$lines $f"
  fi
done | sort -rn
