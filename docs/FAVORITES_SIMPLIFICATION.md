# 系统简化：从"复习"到"收藏"

## 📋 变更总结

### ✅ 已完成的简化

#### 1. **底部导航栏**
- **之前**: `复习` (Icons.inventory_2)
- **现在**: `收藏` (Icons.favorite_border / Icons.favorite)

#### 2. **VaultPage (现在是 FavoritesPage)**
- **AppBar标题**: "Your Vault" → **"收藏"**
- **搜索框**: "Search cards..." → **"搜索收藏的卡片..."**
- **空状态**: 
  - 图标：`Icons.search_off` → `Icons.favorite_border`
  - 文案：**"还没有收藏任何卡片"**
  - 提示：**"在"学习"中点击❤️来收藏内容"**

#### 3. **筛选逻辑**
```dart
// ❌ 之前：显示收藏的 OR 到期需要复习的
return item.isFavorited || isDue;

// ✅ 现在：只显示收藏的
if (!item.isFavorited) return false;
return true;  // 然后应用mastery/search过滤
```

---

## 🎯 现在的功能

### 核心功能
1. **收藏** - 点击❤️保存感兴趣的卡片
2. **标签** - 使用 masteryLevel (hard/medium/easy/unknown) 标记难度
3. **筛选** - 按难度标签和搜索词过滤

### 用户流程
1. 在"学习"tab浏览内容
2. 点击❤️收藏感兴趣的卡片
3. 切换到"收藏"tab查看所有收藏
4. 使用筛选器按难度查看（例如只看"Hard"标记的）
5. 使用搜索框快速找到特定卡片

---

## 🗑️ 移除的功能

### 时间相关的SRS逻辑
- ❌ `nextReviewTime` 判断
- ❌ "到期需要复习"的逻辑
- ❌ 时间间隔算法（虽然model字段还在，但不再使用）

**注意**：
- `nextReviewTime`, `interval`, `easeFactor` 等字段仍保留在model中
- SRSReviewPage页面也还在（从FeedItemView跳转）
- 但这些不再影响"收藏"tab的显示逻辑
- 如果未来想恢复SRS，可以轻松启用

---

## 🔄 未来扩展建议

### 可选的标签系统
如果用户想要比 masteryLevel 更丰富的分类：

```dart
// 可以添加自定义标签
class FeedItem {
  final List<String> tags;  // ["重点", "待复习", "已掌握"]
  final String? category;   // "产品管理", "数据分析"
}
```

### 可选的智能排序
- 按收藏时间排序
- 按阅读次数排序
- 按最后访问时间排序

---

## ✅ 测试清单

刷新浏览器后验证：
- [ ] 底部导航显示"收藏"图标（❤️空心）
- [ ] 点击"收藏"tab，标题显示"收藏"
- [ ] 如果没有收藏，显示友好的空状态提示
- [ ] 在"学习"中收藏一张卡片后，立即出现在"收藏"tab
- [ ] 取消收藏后，卡片消失
- [ ] masteryLevel筛选器工作正常
- [ ] 搜索功能仅在收藏的卡片中搜索

---

## 🎨 UI改进建议（可选）

### 收藏按钮动画
```dart
// 在FeedItemView中添加
AnimatedScale(
  scale: _isAnimating ? 1.3 : 1.0,
  duration: Duration(milliseconds: 200),
  child: Icon(
    isFavorited ? Icons.favorite : Icons.favorite_border,
    color: isFavorited ? Colors.red : Colors.white,
  ),
)
```

### 收藏计数badge
在底部导航显示收藏数量：
```dart
NavigationDestination(
  icon: Badge(
    label: Text('5'),  // 收藏数量
    child: Icon(Icons.favorite_border),
  ),
  label: '收藏',
)
```

---

## 📊 数据统计（未来）

如果想要添加学习进度：
- 总收藏数
- 按难度分布（5个Hard、10个Medium、3个Easy）
- 本周新增收藏
- 最常收藏的模块

这些可以在HomeTab的统计面板显示。
