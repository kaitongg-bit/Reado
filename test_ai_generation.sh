#!/bin/bash

# QuickPM - Gemini AI 测试工具
# 用途：验证AI生成的知识点质量和格式

echo "╔════════════════════════════════════════════════════════════╗"
echo "║       QuickPM AI 知识点生成测试                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# 检查 API Key
if [ -z "$GEMINI_API_KEY" ]; then
  echo "⚠️  未设置 GEMINI_API_KEY 环境变量"
  echo ""
  echo "请先运行："
  echo "  export GEMINI_API_KEY='你的API_Key'"
  echo ""
  echo "或者在运行时设置："
  echo "  GEMINI_API_KEY='你的Key' ./test_ai_generation.sh"
  echo ""
  exit 1
fi

echo "✅ API Key: ${GEMINI_API_KEY:0:10}..."
echo ""

# 运行 Dart 测试脚本
echo "🚀 运行测试..."
echo ""

dart run --define=GEMINI_API_KEY="$GEMINI_API_KEY" test/test_gemini_generation.dart

# 检查结果
if [ $? -eq 0 ]; then
  echo ""
  echo "✅ 测试通过！"
else
  echo ""
  echo "❌ 测试失败"
  exit 1
fi
