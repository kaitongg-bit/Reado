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

# 1. 获取 API 配置
if [ -f .env ]; then
  CURRENT_KEY=$(grep GEMINI_API_KEY .env | cut -d '=' -f2)
  CURRENT_PROXY=$(grep GEMINI_PROXY_URL .env | cut -d '=' -f2)
fi

# 检查 key (如果没代理)
if [ -z "$CURRENT_PROXY" ] && [ -z "$CURRENT_KEY" ]; then
  echo "❌ 错误: 未找到 API 配置。请在 .env 中设置 GEMINI_API_KEY 或 GEMINI_PROXY_URL"
  exit 1
fi

echo "🔑 使用 API Key (前缀): ${CURRENT_KEY:0:10}..."
if [ -n "$CURRENT_PROXY" ]; then
  echo "📡 使用代理服务器: $CURRENT_PROXY"
fi

# 2. 自动递增构建号（解决浏览器缓存问题，确保用户获取最新版本）
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version:[[:space:]]*//')
BASE_VERSION=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUM=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
NEW_BUILD_NUM=$((BUILD_NUM + 1))
NEW_VERSION="${BASE_VERSION}+${NEW_BUILD_NUM}"
sed "s/^version:.*/version: $NEW_VERSION/" pubspec.yaml > pubspec.yaml.tmp && mv pubspec.yaml.tmp pubspec.yaml
echo "📌 版本已更新: $CURRENT_VERSION -> $NEW_VERSION"

# 3. 清理并编译
echo "📦 正在执行 Flutter Web 编译 (安全生产模式)..."
flutter clean
flutter pub get
flutter build web --release \
  --dart-define=GEMINI_PROXY_URL=$CURRENT_PROXY

# 4. 发布到 Firebase
if [ -f "firebase.json" ]; then
  echo "🚀 正在发布到 Firebase Hosting..."
  firebase deploy --only hosting
else
  echo "⚠️ 未发现 firebase.json，部署跳过。你可以手动将 build/web 目录上传到服务器。"
fi

echo "✅ 部署流程结束！"
