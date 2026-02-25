#!/bin/bash

# QuickPM 生产环境一键部署脚本
# 用途：将应用编译并发布到 Firebase Hosting，自动注入代理地址并递增版本号。
#
# 运行方式（在项目根目录打开终端执行）：
#   ./deploy_to_web.sh
# 若无执行权限，先执行：
#   chmod +x deploy_to_web.sh
# 再运行 ./deploy_to_web.sh
#
# 说明：本脚本仅部署「前端 + Hosting」。若修改了 functions/ 下的云函数，
#       需单独执行：firebase deploy --only functions

echo "🌐 准备部署到生产环境..."

# 1. 获取 API/代理配置：优先用环境变量（CI、Secret Manager 注入等），其次 .env
CURRENT_KEY="${GEMINI_API_KEY:-}"
CURRENT_PROXY="${GEMINI_PROXY_URL:-}"
if [ -f .env ]; then
  [ -z "$CURRENT_KEY" ] && CURRENT_KEY=$(grep -E '^GEMINI_API_KEY=' .env | cut -d '=' -f2-)
  [ -z "$CURRENT_PROXY" ] && CURRENT_PROXY=$(grep -E '^GEMINI_PROXY_URL=' .env | cut -d '=' -f2-)
fi

if [ -n "$CURRENT_PROXY" ]; then
  echo "📡 使用代理: ${CURRENT_PROXY%%\?*}"
elif [ -n "$CURRENT_KEY" ]; then
  echo "🔑 使用 API Key (前缀): ${CURRENT_KEY:0:10}..."
else
  echo "⚠️ 未设置 GEMINI_PROXY_URL 或 GEMINI_API_KEY，将使用空代理编译（可在应用内或后端配置）。"
fi

# 2. 自动递增构建号（解决浏览器缓存问题，确保用户获取最新版本）
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//')
BASE_VERSION=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUM=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
NEW_BUILD_NUM=$((BUILD_NUM + 1))
NEW_VERSION="${BASE_VERSION}+${NEW_BUILD_NUM}"
sed "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
echo "📌 版本已更新: $CURRENT_VERSION -> $NEW_VERSION"

# 3. 清理并编译（失败则中止，避免把旧 build 部署上去）
echo "📦 正在执行 Flutter Web 编译 (安全生产模式)..."
flutter clean
flutter pub get
# dart-define 必须有 KEY=value，不能只有 KEY；空代理时传空字符串
GEMINI_PROXY_VALUE="${CURRENT_PROXY:-}"
if ! flutter build web --release \
  --dart-define=GEMINI_PROXY_URL="$GEMINI_PROXY_VALUE"; then
  echo "❌ Flutter Web 编译失败，已中止。请先解决编译错误再重新运行本脚本。"
  exit 1
fi

# 4. Cache bust：注入构建号，让浏览器和 Service Worker 都拉最新代码，用户无需强刷
echo "🔧 注入版本号 (v=$NEW_BUILD_NUM)，避免浏览器/SW 使用旧缓存..."

# 4.1 index.html：入口脚本和静态资源加 ?v=BUILD_NUM
INDEX_FILE="build/web/index.html"
if [ -f "$INDEX_FILE" ]; then
  sed -e "s|src=\"flutter_bootstrap.js\"[^\"]*\"|src=\"flutter_bootstrap.js?v=$NEW_BUILD_NUM\"|g" \
      -e "s|\(href=\"[^\"]*\)?v=[0-9][0-9]*\"|\1?v=$NEW_BUILD_NUM\"|g" \
      -e "s|\(src=\"[^\"]*\)?v=[0-9][0-9]*\"|\1?v=$NEW_BUILD_NUM\"|g" \
      "$INDEX_FILE" > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
  # 首行插入构建号注释，查看网页源代码可见 <!-- Build: 27 --> 即是最新部署
  { echo "<!-- Build: $NEW_BUILD_NUM -->"; cat "$INDEX_FILE"; } > "${INDEX_FILE}.tmp" && mv "${INDEX_FILE}.tmp" "$INDEX_FILE"
fi
# 写入 version.json，访问 /version.json 可确认当前部署的构建号
echo "{\"build\":$NEW_BUILD_NUM,\"version\":\"$NEW_VERSION\"}" > build/web/version.json

# 4.2 flutter_bootstrap.js：主脚本 URL 加版本号；并关闭 Service Worker，避免 SW 长期缓存旧代码
BOOTSTRAP_FILE="build/web/flutter_bootstrap.js"
if [ -f "$BOOTSTRAP_FILE" ]; then
  # mainJsPath 可能是 "main.dart.js" 或 "main.dart.js?v=23"，统一成当前构建号
  sed -e "s/\"mainJsPath\":\"main\.dart\.js[^\"]*\"/\"mainJsPath\":\"main.dart.js?v=$NEW_BUILD_NUM\"/g" \
      "$BOOTSTRAP_FILE" > "${BOOTSTRAP_FILE}.tmp" && mv "${BOOTSTRAP_FILE}.tmp" "$BOOTSTRAP_FILE"
  # 用 perl 多行移除 serviceWorkerSettings 整块（sed [^}] 不匹配换行会破坏 JS 导致白屏），使 load({}) 不注册 SW
  perl -i -0pe 's/\s*serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*"[^"]*"\s*\}\s*,?\s*//s' "$BOOTSTRAP_FILE"
fi

# 5. 发布到 Firebase
if [ -f "firebase.json" ]; then
  echo "🚀 正在发布到 Firebase Hosting..."
  firebase deploy --only hosting
else
  echo "⚠️ 未发现 firebase.json，部署跳过。你可以手动将 build/web 目录上传到服务器。"
fi

echo "✅ 部署流程结束！"
echo ""
echo "💡 若用户端仍看到旧界面（签到、剪贴板等未更新）："
echo "   1. 让用户访问 你的域名/version.json 看 build 是否为本次构建号；"
echo "   2. 让用户打开 你的域名 → 右键「查看网页源代码」看首行是否为 <!-- Build: $NEW_BUILD_NUM -->；"
echo "   3. 若两者都是旧号，请让用户在 Chrome 里：设置 → 隐私与安全 → 清除浏览数据 → 勾选「缓存的图片和文件」→ 清除；"
echo "   4. 或 打开网站 → F12 → Application → Service Workers → 对该域名点 Unregister，再刷新。"
