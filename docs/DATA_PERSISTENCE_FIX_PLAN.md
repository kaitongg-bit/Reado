# QuickPM 数据持久化问题诊断 & 修复方案

## 🐛 发现的问题

### 问题1：首页卡片数字不对（需要点击才加载）
**症状**：
- 首次进入首页，卡片数量显示为0
- 点击"Continue Learning"后，数字才变正确

**根本原因**：
```dart
// home_page.dart
@override
void initState() {
  super.initState();
  if (widget.initialModule != null) {
    _selectedIndex = 1;
    _activeModule = widget.initialModule;
  }
  // ❌ 缺少：没有调用 loadAllData()
}
```

**后果**：
- FeedProvider的`_allItems`为空
- `allItemsProvider`返回空列表
- HomeTab显示"0 cards"
- 只有点击"Continue Learning"跳转到FeedPage时才触发加载

---

### 问题2：收藏区是空的
**症状**：
- 明明收藏了item
- VaultPage（收藏tab）是空的

**根本原因**：
- 同问题1，数据没有加载
- `allItemsProvider`为空
- VaultPage的筛选逻辑找不到收藏的item

---

### 问题3：难度标记刷新后丢失
**症状**：
- 标记item为Hard/Medium/Easy
- 刷新页面后，标记丢失

**根本原因**：
```dart
// firestore_service.dart
Future<void> updateSRSStatus(...) async {
  try {
    print('Updating SRS for $itemId: $nextReview');  // ❌ 只打印！
  } catch (e) {
    print('Error updating SRS: $e');
  }
}
```

**调用链**：
```
用户点击Hard → updateMastery() → updateSRSStatus()
                           ↓
                  只更新本地state，不保存到Firestore
                           ↓
                     刷新后数据丢失
```

---

## ✅ 修复方案

### 修复1：HomePage初始化时加载数据

#### 步骤1：添加加载调用
```dart
// lib/features/home/presentation/home_page.dart

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _activeModule;

  @override
  void initState() {
    super.initState();
    
    // ✅ 新增：首次进入时加载所有数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final container = ProviderScope.containerOf(context);
      container.read(feedProvider.notifier).loadAllData();
    });
    
    if (widget.initialModule != null) {
      _selectedIndex = 1;
      _activeModule = widget.initialModule;
    }
  }
  // ...
}
```

**工时**：5分钟  
**影响**：首页、收藏tab立即显示正确数据

---

### 修复2：实现masteryLevel的Firestore保存

#### 方法A：单独保存masteryLevel（推荐）
```dart
// lib/data/services/firestore_service.dart

Future<void> updateMasteryLevel(String itemId, String masteryLevel) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // 保存到用户的mastery collection
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('mastery')
        .doc(itemId)
        .set({
      'level': masteryLevel,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
    
    if (kDebugMode) print('✅ Mastery saved: $itemId -> $masteryLevel');
  } catch (e) {
    if (kDebugMode) print('❌ Error saving mastery: $e');
  }
}
```

#### 方法B：复用updateSRSStatus（简单但不优雅）
```dart
// lib/data/services/firestore_service.dart

Future<void> updateSRSStatus(
    String itemId, DateTime nextReview, int interval, double ease) async {
  try {
    await _feedRef.doc(itemId).update({
      'nextReviewTime': nextReview.toIso8601String(),
      'interval': interval,
      'easeFactor': ease,
    });
    print('✅ SRS updated for $itemId');
  } catch (e) {
    print('❌ Error updating SRS: $e');
  }
}
```

**工时**：15-20分钟  
**影响**：难度标记持久化

---

### 修复3：加载时合并用户的mastery数据

```dart
// lib/data/services/firestore_service.dart

Future<List<FeedItem>> fetchFeedItems(String moduleId) async {
  try {
    // 1. 加载官方内容
    final querySnapshot = await _feedRef
        .where('module', isEqualTo: moduleId)
        .orderBy('id')
        .get();

    final items = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['firestoreId'] = doc.id;
      return data;
    }).toList();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 2. 合并用户笔记
      for (var item in items) {
        final itemId = item['id'] as String?;
        if (itemId == null) continue;
        
        final userNotes = await _fetchUserNotesForItem(user.uid, itemId);
        if (userNotes.isNotEmpty) {
          final pages = List<Map<String, dynamic>>.from(item['pages'] ?? []);
          pages.addAll(userNotes);
          item['pages'] = pages;
        }
        
        // ✅ 新增：合并用户的mastery标记
        final masteryDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('mastery')
            .doc(itemId)
            .get();
        
        if (masteryDoc.exists) {
          final masteryData = masteryDoc.data();
          if (masteryData != null && masteryData['level'] != null) {
            item['masteryLevel'] = masteryData['level'];
          }
        }
      }
    }

    final feedItems = items.map((data) => FeedItem.fromJson(data)).toList();
    return feedItems;
  } catch (e) {
    if (kDebugMode) print('Error fetching items: $e');
    return [];
  }
}
```

**工时**：20分钟  
** 影响**：刷新后mastery标记保留

---

## 🔒 数据结构（用户私有数据）

```
firestore/
  feed_items/              ← 官方内容（所有人共享）
    b001/
      title: "..."
      pages: [...]
      
  users/                   ← 用户私有数据
    {uid}/
      notes/               ← 个人笔记
        b001/
          pages: [...]
          
      mastery/             ← 难度标记（新增）
        b001/
          level: "hard"
          updatedAt: Timestamp
        b002/
          level: "medium"
          
      favorites/           ← （可选）收藏标记
        b001: true
```

**隐私保证**：
- 每个用户的mastery标记完全隔离
- 不会互相看到对方的标记

---

## 📊 问题优先级

| 问题 | 影响 | 优先级 | 工时 |
|------|------|--------|------|
| **首页数字不对** | 用户体验差 | 🔴 P0 | 5分钟 |
| **收藏区为空** | 核心功能失效 | 🔴 P0 | 0（同问题1） |
| **难度标记丢失** | 功能不可用 | 🟡 P1 | 30-40分钟 |

---

## 🚀 推荐修复顺序

### 第一步：修复加载问题（5分钟）
1. 修改`home_page.dart`的`initState`
2. 添加`loadAllData()`调用
3. 热重载测试
4. ✅ 首页、收藏应该立即正常

### 第二步：实现mastery保存（40分钟）
1. 在`DataService`接口添加`updateMasteryLevel`方法
2. 在`FirestoreService`实现保存逻辑
3. 修改`FeedProvider.updateMastery`调用新方法
4. 修改`fetchFeedItems`合并mastery数据
5. 测试标记→刷新→标记保留

### 第三步：验证完整流程（10分钟）
1. 清除浏览器缓存
2. 刷新页面
3. 验证首页卡片数量正确
4. 收藏item → 去收藏tab验证
5. 标记难度 → 刷新 → 验证保留
6. Pin笔记 → 刷新 → 验证保留

**总工时：约1小时**

---

## 🎯 修复后的数据流

```
用户进入应用:
HomePage.initState() → loadAllData()
  ↓
加载所有模块数据 + 合并用户数据（notes, mastery, favorites）
  ↓
HomeTab显示正确卡片数量
VaultPage显示收藏的items

用户标记难度:
点击Hard → updateMastery() → updateMasteryLevel(Firestore)
  ↓
本地state更新 + Firebase保存
  ↓
刷新后: fetchFeedItems() → 合并mastery → 标记保留

用户Pin笔记:
点击Pin → saveUserNote(Firestore)
  ↓
本地state更新 + Firebase保存
  ↓
刷新后: fetchFeedItems() → 合并notes → 笔记保留
```

---

##💡 额外优化建议（可选）

### 优化1：Loading状态
```dart
// home_tab.dart
if (isLoading) {
  return Center(child: CircularProgressIndicator());
}
```

### 优化2：错误处理
```dart
try {
  await loadAllData();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('加载失败: $e')),
  );
}
```

### 优化3：缓存策略
```dart
// 首次加载后缓存
// 后续只在需要时刷新
```

---

**要我立即开始修复吗？** 🚀

我建议先修复问题1（5分钟），立即看到效果，然后再处理mastery保存！
