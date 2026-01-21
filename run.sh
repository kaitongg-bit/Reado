#!/bin/bash

# QuickPM 快速启动脚本
# 用途：简化带有 Gemini API Key 的应用启动流程

echo "🚀 QuickPM 启动中..."
echo ""

# 检查 API Key 是否已设置
if [ -z "$GEMINI_API_KEY" ]; then
  echo "⚠️  警告：GEMINI_API_KEY 环境变量未设置"
  echo ""
  echo "请选择以下方式之一："
  echo "  1. 在当前终端中设置："
  echo "     export GEMINI_API_KEY='你的Key'"
  echo "     ./run.sh"
  echo ""
  echo "  2. 或者直接运行："
  echo "     GEMINI_API_KEY='你的Key' ./run.sh"
  echo ""
  echo "  3. 或创建 .env 文件："
  echo "     echo \"GEMINI_API_KEY=你的Key\" > .env"
  echo "     然后运行: source .env && ./run.sh"
  echo ""
  echo "💡 获取 API Key: https://aistudio.google.com/app/apikey"
  exit 1
fi

echo "✅ API Key 已配置"
echo "Key 前缀: ${GEMINI_API_KEY:0:10}..."
echo ""

# 选择运行平台
echo "请选择运行平台:"
echo "  1) Web (默认，端口 3000)"
echo "  2) Chrome (调试模式)"
echo "  3) macOS 桌面"
echo ""
read -p "输入选项 [1-3, 回车默认 1]: " PLATFORM

case $PLATFORM in
  2)
    echo "🌐 在 Chrome 中启动..."
    flutter run -d chrome \
      --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
    ;;
  3)
    echo "🖥️  在 macOS 桌面启动..."
    flutter run -d macos \
      --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
    ;;
  *)
    echo "🌐 在 Web 服务器启动（端口 3000）..."
    flutter run -d web-server --web-port 3000 \
      --dart-define=GEMINI_API_KEY=$GEMINI_API_KEY
    ;;
esac
