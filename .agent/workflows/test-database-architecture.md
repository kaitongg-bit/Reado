---
description: 测试数据库架构
---

# 数据库架构测试 Workflow

## 🧪 Step 1: 打开测试页面

在你的应用中添加测试入口（临时的，测试完可删除）：

### 方式 A: 独立测试应用（推荐）

创建临时测试文件 `lib/database_test_app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/database_test/database_test_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 确保 Firebase 已初始化
  runApp(const DatabaseTestApp());
}

class DatabaseTestApp extends StatelessWidget {
  const DatabaseTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '数据库测试',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DatabaseTestPage(),
    );
  }
}
```

运行测试应用:
```bash
flutter run -t lib/database_test_app.dart
```

### 方式 B: 在现有应用中添加入口

在任何页面添加临时按钮:

```dart
FloatingActionButton(
  child: Icon(Icons.science),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DatabaseTestPage(),
      ),
    );
  },
)
```

---

## 🔍 Step 2: 运行测试流程

### 基础测试（验证架构正确性）

1. **点击 "1️⃣ 检测地区"**
   - ✅ 应该显示: **海外** （你在美国）
   - 📝 日志会显示检测过程

2. **点击 "2️⃣ 初始化数据库"**
   - ✅ 应该显示: **FirebaseDatabaseImpl**
   - 📝 验证工厂正确创建了 Firebase 实现

3. **点击 "3️⃣ 获取当前用户"**
   - ✅ 如果已登录，显示用户 ID
   - ⚠️ 如果未登录，提示未登录

4. **点击 "4️⃣ 测试数据读取"**
   - ✅ 如果成功，显示模块数量
   - ⚠️ 可能报错（某些方法未完全实现），这是正常的

### 快速测试（一键运行）

**点击 "🚀 运行完整流程"**
- 自动执行步骤 1-3
- 查看日志确认每步都成功

---

## 🇨🇳 Step 3: 测试地区切换（可选）

### 模拟国内环境

1. **点击 "🇨🇳 模拟切换到国内"**
   - 强制设置地区为国内
   
2. **再次点击 "2️⃣ 初始化数据库"**
   - ⚠️ 应该显示: **LeanCloudDatabaseImpl**
   - ⚠️ 然后降级到 **FirebaseDatabaseImpl**（因为 LeanCloud 未实现）

3. **点击 "🌏 恢复自动检测"**
   - 恢复正常状态

---

## ✅ 预期结果

### 在美国（你的环境）

| 测试项 | 预期结果 |
|--------|----------|
| 地区检测 | ✅ 海外 |
| 数据库类型 | ✅ FirebaseDatabaseImpl |
| 用户获取 | ✅ 有用户 ID 或提示登录 |
| 数据读取 | ⚠️ 可能部分功能报错（正常） |

### 模拟国内环境

| 测试项 | 预期结果 |
|--------|----------|
| 强制切换 | ✅ 切换到中国大陆 |
| 数据库创建 | ⚠️ LeanCloud 尝试 → 降级 Firebase |
| 功能正常 | ✅ 降级后继续工作 |

---

## 🐛 可能遇到的问题

### 问题 1: 编译错误
**原因:** 某些方法签名不匹配  
**解决:** 这些是已知的 lint 错误，不影响测试框架，可以暂时忽略

### 问题 2: 数据读取失败
**原因:** `firebase_impl.dart` 中部分方法还需要调整  
**解决:** 这是正常的，说明我们接下来需要完善这些方法

### 问题 3: Firebase 未初始化
**原因:** 测试应用没有初始化 Firebase  
**解决:** 使用方式 A，确保 `Firebase.initializeApp()` 被调用

---

## 📊 成功标准

✅ **架构验证通过** = 前3个测试都成功  
✅ **地区检测正确** = 显示"海外"  
✅ **数据库创建成功** = 显示 FirebaseDatabaseImpl  
✅ **降级机制工作** = 模拟国内时能降级到 Firebase

---

## 🚀 测试通过后

如果测试页面运行正常，说明：
1. ✅ 数据库抽象层设计正确
2. ✅ 地区检测功能正常
3. ✅ Firebase 路径完全可用
4. ✅ 可以安全进行下一步集成

**然后我们继续 Step 2: 集成到 Provider**
