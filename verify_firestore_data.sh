#!/bin/bash

# Firestore 数据验证脚本
# 用途：检查AI生成的知识点是否正确保存到 Firestore

echo "======================================"
echo "📦 Fire store 数据验证工具"
echo "======================================"
echo ""

PROJECT_ID="quickpm-8f9c9"

echo "项目ID: $PROJECT_ID"
echo ""

# 检查 Firebase CLI 是否安装
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI 未安装"
    echo ""
    echo "请运行以下命令安装："
    echo "npm install -g firebase-tools"
    exit 1
fi

echo "✅ Firebase CLI 已安装"
echo ""

# 登录检查
echo "检查登录状态..."
firebase projects:list --project "$PROJECT_ID" &> /dev/null

if [ $? -ne 0 ]; then
    echo "❌ 未登录或没有权限"
    echo ""
    echo "请运行以下命令登录："
    echo "firebase login"
    exit 1
fi

echo "✅ 已登录"
echo ""

# 获取当前用户UID（从最近的日志中提取）
echo "正在查找用户ID..."
echo ""
echo "请输入你的匿名用户 UID（从应用日志中查找）："
echo "或按回车使用测试查询"
read USER_UID

if [ -z "$USER_UID" ]; then
    echo ""
    echo "⚠️ 未提供UID，将显示所有 feed_items"
    echo ""
    echo "运行查询..."
    firebase firestore:get feed_items --project "$PROJECT_ID" --limit 5
else
    echo ""
    echo "📊 查询用户 $USER_UID 的自定义知识点..."
    echo ""
    
    # 查询自定义知识点
    echo "路径: users/$USER_UID/custom_items/"
    firebase firestore:get "users/$USER_UID/custom_items" --project "$PROJECT_ID"
fi

echo ""
echo "======================================"
echo "✨ 查询完成"
echo "======================================"
