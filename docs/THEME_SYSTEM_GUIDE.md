# QuickPM 主题系统与用户中心完成

## ✅ 已实现功能

### 1. 主题管理系统
**文件：** `lib/core/theme/theme_provider.dart`

**功能：**
- ✅ 深色/浅色模式切换
- ✅ 主题持久化（使用 SharedPreferences）
- ✅ 统一的主题配置

**使用方式：**
```dart
// 切换主题
ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
ref.read(themeProvider.notifier).setTheme(ThemeMode.light);

// 读取当前主题
final isDark = ref.watch(themeProvider) == ThemeMode.dark;
```

---

### 2. 主应用主题集成
**文件：** `lib/main.dart`

**改动：**
- ✅ `QuickPMApp` 改为 `ConsumerWidget`
- ✅ 应用 `AppTheme.lightTheme` 和 `AppTheme.darkTheme`
- ✅ 动态响应主题切换

---

### 3. 底部导航栏优化
**文件：** `lib/features/home/presentation/home_page.dart`

**改进：**
- ✅ 高度增加至 70
- ✅ 添加阴影效果（elevation: 8）
- ✅ 指示器不透明度增加至 0.3
- ✅ Load 按钮保留底部导航栏

---

## 📝 接下来需要手动完成的

由于代码编辑器遇到问题，以下是你需要手动添加的代码：

### 步骤 1：更新 home_tab.dart 的导入

在文件顶部添加：
```dart
import 'package:flutter/material.dart' hide ThemeMode;
import '../../../../core/theme/theme_provider.dart';
```

### 步骤 2：在头像位置添加菜单

找到这部分代码（约第 42-66 行）：
```dart
// 1. Top Bar: Title & Avatar
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(...),
    GestureDetector(...),  // ← 替换这里
  ],
),
```

替换为：
```dart
// 1. Top Bar: Title & Avatar Menu
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      'QuickPM',
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),
    PopupMenuButton(
      offset: const Offset(0, 50),
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey
            : Colors.grey[300],
        child: Icon(
          Icons.person,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.person, size: 20),
            title: const Text('个人主页'),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              // 这里可以导航到 Profile 页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('个人主页功能开发中...')),
              );
            },
          ),
        ),
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.settings, size: 20),
            title: const Text('设置'),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置功能开发中...')),
              );
            },
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          child: Consumer(
            builder: (context, ref, _) {
              final isDark = ref.watch(themeProvider) != ThemeMode.light;
              return ListTile(
                leading: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                ),
                title: Text(isDark ? '浅色模式' : '深色模式'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  ref.read(themeProvider.notifier).setTheme(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    ),
  ],
),
```

### 步骤 3：更新 Scaffold 背景色

在 `build` 方法中，将：
```dart
return Scaffold(
  backgroundColor: Colors.black,
```

改为：
```dart
return Scaffold(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
```

---

## 🧪 测试方法

1. **Hot Restart** 应用（按 `R`）
2. 刷新页面
3. 点击右上角头像
4. 应该看到菜单：
   - 个人主页
   - 设置
   - 深色模式/浅色模式切换

5. 点击主题切换
6. 整个应用应该立即切换主题！

---

## 🎯 完成后的效果

- ✅ 点击头像出现菜单
- ✅ 可以切换深色/浅色模式
- ✅ 主题切换立即生效
- ✅ 重启应用后主题保持
- ✅ 所有页面统一主题

---

**现在你可以手动完成这些修改，或者告诉我遇到任何问题！** 🚀
