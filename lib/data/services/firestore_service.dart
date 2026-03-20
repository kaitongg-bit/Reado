import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/feed_item.dart';
import '../../models/knowledge_module.dart';
import '../../models/shared_module_data.dart';
import '../../models/share_stats.dart';

// Interface for Data Service (Repo Pattern)
abstract class DataService {
  Future<List<FeedItem>> fetchFeedItems(String moduleId);
  Future<List<FeedItem>> fetchCustomFeedItems(String userId); // 获取用户自定义内容
  Future<void> saveUserNote(String itemId, String question, String answer);
  Future<void> deleteUserNote(String itemId, UserNotePage note);
  Future<void> updateUserNote(
      String itemId, UserNotePage oldNote, String newQ, String newA);
  Future<void> deleteCustomFeedItem(String itemId);
  Future<void> moveCustomFeedItem(
      String userId, String itemId, String targetModuleId);
  Future<void> updateSRSStatus(
      String itemId, DateTime nextReview, int interval, double ease);
  Future<void> updateMasteryLevel(String itemId, String masteryLevel);
  Future<void> toggleFavorite(String itemId, bool isFavorited);
  Future<void> seedInitialData(List<FeedItem> items,
      {bool force = false}); // For migration
  Future<void> saveCustomFeedItem(
      FeedItem item, String userId); // 保存AI生成的自定义知识点
  /// 更新自定义知识卡某一页的正文（原位编辑保存）
  Future<void> updateCustomFeedItemPageContent(
      String userId, String itemId, int pageIndex, String newMarkdownContent);
  Future<void> saveOfficialFeedItem(FeedItem item); // 管理员发布官方内容
  Future<List<KnowledgeModule>> fetchUserModules(String userId);
  Future<List<KnowledgeModule>> fetchAllUserModules(
      String userId); // Includes hidden ones
  Future<KnowledgeModule> createModule(
      String userId, String title, String description);
  Future<void> updateModule(String userId, String moduleId,
      {String? title, String? description});
  Future<int> fixOrphanItems(String userId, String targetModuleId);
  Future<void> saveModuleProgress(
      String userId, String moduleId, int index); // Save reading progress
  Future<Map<String, int>> fetchAllModuleProgress(
      String userId); // Fetch all progress
  /// 各模块最后学习时间（用于「最近在学」排序）moduleId -> 时间戳 ms
  Future<Map<String, int>> fetchModuleLastAccessed(String userId);
  Future<Map<String, int>> fetchUserStats(String userId); // 获取积分和点击数
  Stream<Map<String, int>> userStatsStream(String userId); // 实时监听积分和点击数
  Future<void> logShareClick(String referrerId); // 记录分享点击
  Future<int> fetchUserCredits(String userId); // [Deprecated] 获取用户积分
  Future<void> updateUserCredits(String userId, int amount); // 更新积分（增量更新）
  Future<void> ensureUserDocument(User user); // 确保用户文档存在（含基础资料）

  // Deletion & Hiding
  Future<void> deleteModule(String userId, String moduleId);
  Future<void> hideOfficialModule(String userId, String moduleId);
  Future<void> hideOfficialFeedItem(String userId, String itemId);
  Future<void> unhideOfficialModule(String userId, String moduleId);
  Future<void> unhideOfficialFeedItem(String userId, String itemId);
  Future<Set<String>> fetchHiddenModuleIds(String userId);
  Future<List<FeedItem>> fetchHiddenFeedItems(String userId);
  Future<void> submitFeedback(
    String type,
    String content,
    String? contact, {
    String? source,
  });

  /// 获取某知识点的 AI 囤囤鼠聊天记录
  Future<List<Map<String, dynamic>>> fetchAiChatHistory(
      String userId, String itemId);

  /// 保存某知识点的 AI 囤囤鼠聊天记录
  Future<void> saveAiChatHistory(
      String userId, String itemId, List<Map<String, dynamic>> messages);

  /// 获取共享知识库只读数据（游客或复制用）；ownerId 即分享链接中的 ref
  Future<SharedModuleData> fetchSharedModule(String ownerId, String moduleId);

  /// 是否分享时开放笔记 + 分享者公开界面语言（供访客页 Localizations）
  Future<({bool shareNotesPublic, String appLocale})> getShareSettingsPublic(
      String userId);

  /// 是否分享时开放笔记
  Future<bool> getShareNotesPublic(String userId);
  Future<void> setShareNotesPublic(String userId, bool value);

  /// 分享统计：获取某知识库分享页的浏览/保存/点赞数
  Future<ShareStats?> getShareStats(String ownerId, String moduleId);
  Future<void> recordShareView(String ownerId, String moduleId);
  Future<void> recordShareSave(String ownerId, String moduleId);
  /// 点赞（需登录），返回是否本次新点赞（false 表示已点过）
  Future<bool> recordShareLike(String ownerId, String moduleId);

  /// 将他人分享的自定义知识库复制到当前用户，返回新模块 id
  Future<String> copySharedModuleToMine(
      String ownerId, String sourceModuleId);

  /// 每日签到：今日是否已领取
  Future<bool> getDailyCheckInClaimedToday();
  /// 领取每日签到积分（20），返回 { claimed: 是否本次新领取, credits: 20 }
  Future<Map<String, dynamic>> claimDailyCheckIn();
}

class FirestoreService implements DataService {
  // ⚠️ 修复关键：指定数据库 ID 为 'reado'，而不是使用默认的 '(default)'
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'reado',
  );

  FirestoreService() {
    _init();
  }

  void _init() {
    try {
      print('🔥 FirestoreService: Initializing (DB: reado)...');
      // ⚠️ 关键修复：禁用 Persistence 以避免 Web 端的“假离线”同步问题
      // 特别是在切换账号或高频测试阶段
      _db.settings = const Settings(
        persistenceEnabled: false,
      );
      print('🔥 Target Project: ${_db.app.options.projectId}');
      print('🔥 Target Database: ${_db.databaseId}');
    } catch (e) {
      print(
          '⚠️ Firestore Settings Warning: $e (This is expected if set multiple times)');
    }
  }

  // Collection References
  CollectionReference<Map<String, dynamic>> get _feedRef =>
      _db.collection('feed_items');
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  // Fetch feed items for a specific module (with user notes merged)
  @override
  Future<List<FeedItem>> fetchFeedItems(String moduleId) async {
    try {
      print('📥 Fetching items for module: $moduleId (with 10s timeout)');
      final querySnapshot = await _feedRef
          .where('module', isEqualTo: moduleId)
          // Removed .orderBy('id') to avoid requiring composite indexes which often cause silent failures if not created
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('⏱️ Firestore GET timed out for module: $moduleId');
        throw Exception('数据库连接超时 (10s)。请检查网络或代理是否通畅。');
      });

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['firestoreId'] = doc.id;
        return data;
      }).toList();

      // Merge user notes and mastery level for each item
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && items.isNotEmpty) {
        print('🧠 Metadata fetching for ${items.length} items (Safe Mode)...');

        // 🚀 优化：分块并发 (Chunked Parallelism)
        // 以前是 Future.wait(所有)，现在我们 5 个一组，防止把浏览器 WebSocket 撑爆导致 offline
        const int chunkSize = 5;
        for (var i = 0; i < items.length; i += chunkSize) {
          final chunk = items.skip(i).take(chunkSize);
          await Future.wait(chunk.map((item) async {
            final itemId = item['id'] as String?;
            if (itemId == null) return;

            try {
              // Fetch Notes & Mastery (Parallel) for this single item
              final results = await Future.wait([
                _fetchUserNotesForItem(user.uid, itemId),
                _db
                    .collection('users')
                    .doc(user.uid)
                    .collection('mastery')
                    .doc(itemId)
                    .get()
                    .timeout(const Duration(seconds: 5)),
              ]);

              final userNotes = results[0] as List<Map<String, dynamic>>;
              if (userNotes.isNotEmpty) {
                final pages =
                    List<Map<String, dynamic>>.from(item['pages'] ?? []);
                pages.addAll(userNotes);
                item['pages'] = pages;
              }

              final masteryDoc =
                  results[1] as DocumentSnapshot<Map<String, dynamic>>;
              if (masteryDoc.exists) {
                final masteryData = masteryDoc.data();
                if (masteryData != null) {
                  item['masteryLevel'] = masteryData['level'];
                }
              }
            } catch (e) {
              // Log & silent ignore to prevent flow crash
              if (kDebugMode) print('⚠️ Metadata skip for $itemId: $e');
            }
          }));

          // 给浏览器喘息时间，防止并发太高被 Firestore 断开
          if (i + chunkSize < items.length) {
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      }

      final feedItems = items.map((data) => FeedItem.fromJson(data)).toList();

      // 4. Filter out hidden items
      if (user != null) {
        final hiddenSnapshot =
            await _usersRef.doc(user.uid).collection('hidden_items').get();
        final hiddenIds = hiddenSnapshot.docs.map((doc) => doc.id).toSet();
        if (hiddenIds.isNotEmpty) {
          feedItems.removeWhere((item) => hiddenIds.contains(item.id));
        }
      }

      if (kDebugMode)
        print('✅ Fetched ${feedItems.length} items for module $moduleId');
      return feedItems;
    } catch (e) {
      print('❌ Error fetching items for $moduleId: $e');
      rethrow; // Rethrow to let the UI know
    }
  }

  // Helper: Fetch user notes for a specific item
  Future<List<Map<String, dynamic>>> _fetchUserNotesForItem(
      String userId, String itemId) async {
    try {
      final noteDoc = await _db
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(itemId)
          .get();

      if (!noteDoc.exists) return [];

      final data = noteDoc.data();
      if (data == null || data['pages'] == null) return [];

      // Convert Timestamp to String for FeedItem.fromJson compatibility
      final pages = List<Map<String, dynamic>>.from(data['pages']);
      for (var page in pages) {
        if (page['createdAt'] is Timestamp) {
          final timestamp = page['createdAt'] as Timestamp;
          page['createdAt'] = timestamp.toDate().toIso8601String();
        }
      }

      return pages;
    } catch (e) {
      if (kDebugMode) print('Error fetching user notes for $itemId: $e');
      return [];
    }
  }

  // Fetch Custom Items (User's AI-generated content)
  @override
  Future<List<FeedItem>> fetchCustomFeedItems(String userId) async {
    try {
      print('📦 获取用户自定义内容: $userId');
      final snapshot =
          await _usersRef.doc(userId).collection('custom_items').get();

      final items = snapshot.docs.map<FeedItem>((doc) {
        final data = doc.data();
        data['isCustom'] = true; // Mark as custom
        return FeedItem.fromJson(data);
      }).toList();

      print('✅ 找到 ${items.length} 个自定义知识点');

      // Filter by hidden items
      final hiddenSnapshot =
          await _usersRef.doc(userId).collection('hidden_items').get();
      final hiddenIds = hiddenSnapshot.docs.map((doc) => doc.id).toSet();

      if (hiddenIds.isNotEmpty) {
        items.removeWhere((item) => hiddenIds.contains(item.id));
      }

      return items;
    } catch (e) {
      print('❌ 获取自定义内容失败: $e');
      return [];
    }
  }

  // Save User Note to Firestore (user-specific, per-item)
  @override
  Future<void> saveUserNote(
      String itemId, String question, String answer) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ User not logged in, note not saved to Firestore');
        return;
      }

      final notePage = {
        'type': 'user_note',
        'question': question,
        'answer': answer,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // 1️⃣ Custom Item: Embed note directly into the item's pages
      final customRef =
          _usersRef.doc(user.uid).collection('custom_items').doc(itemId);
      final customDoc = await customRef.get();

      if (customDoc.exists) {
        await customRef.update({
          'pages': FieldValue.arrayUnion([notePage])
        });
        debugPrint('✅ User note embedded in custom item: itemId=$itemId');
        return;
      }

      // 2️⃣ Official Item: Save to separate notes collection (Side-car)
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(itemId)
          .set({
        'pages': FieldValue.arrayUnion([
          {
            ...notePage,
            'createdAt': Timestamp.now(), // Official side uses Timestamp
          }
        ])
      }, SetOptions(merge: true));

      debugPrint(
          '✅ User note saved (Official): itemId=$itemId, user=${user.uid}');
    } catch (e) {
      debugPrint('❌ Error saving user note: $e');
      rethrow;
    }
  }

  // 保存AI生成的自定义知识点
  @override
  Future<void> saveCustomFeedItem(FeedItem item, String userId) async {
    try {
      print('💾 Saving AI Custom Item to Firestore...');
      await _usersRef
          .doc(userId)
          .collection('custom_items')
          .doc(item.id)
          .set(item.toJson());
      print('✅ Saved AI Custom Item: ${item.id}');
    } catch (e) {
      print('❌ Error saving custom item: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomFeedItemPageContent(
      String userId, String itemId, int pageIndex, String newMarkdownContent) async {
    try {
      final ref =
          _usersRef.doc(userId).collection('custom_items').doc(itemId);
      final doc = await ref.get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('自定义知识点不存在: $itemId');
      }
      final data = doc.data()!;
      final pages = List<Map<String, dynamic>>.from(data['pages'] ?? []);
      if (pageIndex < 0 || pageIndex >= pages.length) {
        throw Exception('页面索引无效: $pageIndex');
      }
      final page = Map<String, dynamic>.from(pages[pageIndex]);
      if (page['type'] != 'text') {
        throw Exception('该页不是正文页，无法编辑');
      }
      page['markdownContent'] = newMarkdownContent;
      pages[pageIndex] = page;
      await ref.update({'pages': pages});
    } catch (e) {
      print('❌ Error updating page content: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveOfficialFeedItem(FeedItem item) async {
    try {
      print('👑 Admin: Publishing official item ${item.id}...');
      await _feedRef.doc(item.id).set(item.toJson());
      print('✅ Published successfully!');
    } catch (e) {
      print('❌ Error publishing item: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCustomFeedItem(String itemId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🗑️ Deleting custom item: $itemId');
      await _usersRef
          .doc(user.uid)
          .collection('custom_items')
          .doc(itemId)
          .delete();
      print('✅ Deleted custom item');
    } catch (e) {
      print('❌ Error deleting custom item: $e');
      rethrow;
    }
  }

  @override
  Future<void> moveCustomFeedItem(
      String userId, String itemId, String targetModuleId) async {
    try {
      final ref =
          _usersRef.doc(userId).collection('custom_items').doc(itemId);
      final doc = await ref.get();
      if (!doc.exists) {
        throw Exception('该知识卡不存在或无法移动');
      }
      await ref.update({'module': targetModuleId});
      print('✅ Moved custom item $itemId to module $targetModuleId');
    } catch (e) {
      print('❌ Error moving custom item: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUserNote(String itemId, UserNotePage note) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('🗑️ Deleting user note from $itemId');

      final noteData = {
        'type': 'user_note',
        'question': note.question,
        'answer': note.answer,
        'createdAt': note.createdAt.toIso8601String(),
      };

      // 1️⃣ Try Custom Item
      final customRef =
          _usersRef.doc(user.uid).collection('custom_items').doc(itemId);
      final customDoc = await customRef.get();

      if (customDoc.exists) {
        await customRef.update({
          'pages': FieldValue.arrayRemove([noteData])
        });
        print('✅ Removed note from custom item');
        return;
      }

      // 2️⃣ Try Official Item (Notes collection)
      // Note: For official item, we might have saved it with Timestamp.
      // But arrayRemove needs EXACT match.
      // If timestamps differ by format (ISO string vs Timestamp), this might fail.
      // Strategy: Fetch the array, remove by filtering, update the array.
      // This is safer than arrayRemove for complex objects.

      final notesRef = _usersRef.doc(user.uid).collection('notes').doc(itemId);

      final noteDoc = await notesRef.get();
      if (noteDoc.exists) {
        final data = noteDoc.data();
        if (data != null && data['pages'] != null) {
          final pages = List<Map<String, dynamic>>.from(data['pages']);

          // Filter out the note to delete
          // Matching by question and content to be safe (Title might be enough?)
          final updatedPages = pages.where((p) {
            final q = p['question'] as String?;
            final a = p['answer'] as String?;
            return q != note.question || a != note.answer;
          }).toList();

          await notesRef.update({'pages': updatedPages});
          print('✅ Removed note from official item side-car');
        }
      }
    } catch (e) {
      print('❌ Error deleting user note: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserNote(
      String itemId, UserNotePage oldNote, String newQ, String newA) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      print('✏️ Updating user note in $itemId');

      // 1️⃣ Try Custom Item
      final customRef =
          _usersRef.doc(user.uid).collection('custom_items').doc(itemId);
      final customDoc = await customRef.get();

      if (customDoc.exists) {
        final data = customDoc.data();
        if (data != null && data['pages'] != null) {
          final pages = List<Map<String, dynamic>>.from(data['pages']);

          // Find and update the note
          final updatedPages = pages.map((p) {
            final q = p['question'] as String?;
            final a = p['answer'] as String?;
            if (q == oldNote.question && a == oldNote.answer) {
              return {
                'type': 'user_note',
                'question': newQ,
                'answer': newA,
                'createdAt': oldNote.createdAt.toIso8601String(),
              };
            }
            return p;
          }).toList();

          await customRef.update({'pages': updatedPages});
          print('✅ Updated note in custom item');
          return;
        }
      }

      // 2️⃣ Try Official Item (Notes collection)
      final notesRef = _usersRef.doc(user.uid).collection('notes').doc(itemId);
      final noteDoc = await notesRef.get();

      if (noteDoc.exists) {
        final data = noteDoc.data();
        if (data != null && data['pages'] != null) {
          final pages = List<Map<String, dynamic>>.from(data['pages']);

          final updatedPages = pages.map((p) {
            final q = p['question'] as String?;
            final a = p['answer'] as String?;
            if (q == oldNote.question && a == oldNote.answer) {
              return {
                'type': 'user_note',
                'question': newQ,
                'answer': newA,
                'createdAt': oldNote.createdAt.toIso8601String(),
              };
            }
            return p;
          }).toList();

          await notesRef.update({'pages': updatedPages});
          print('✅ Updated note in official item side-car');
        }
      }
    } catch (e) {
      print('❌ Error updating user note: $e');
      rethrow;
    }
  }

  @override
  Future<List<KnowledgeModule>> fetchUserModules(String userId) async {
    final modules = await fetchAllUserModules(userId);
    try {
      // Filter by hidden modules
      final hiddenSnapshot =
          await _usersRef.doc(userId).collection('hidden_modules').get();
      final hiddenIds = hiddenSnapshot.docs.map((doc) => doc.id).toSet();

      if (hiddenIds.isNotEmpty) {
        modules.removeWhere((m) => hiddenIds.contains(m.id));
      }
      return modules;
    } catch (e) {
      print('Error filtering modules: $e');
      return modules;
    }
  }

  @override
  Future<List<KnowledgeModule>> fetchAllUserModules(String userId) async {
    try {
      print('📥 Fetching all modules for user: $userId');
      final snapshot = await _usersRef
          .doc(userId)
          .collection('modules')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => KnowledgeModule.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching all user modules: $e');
      return [];
    }
  }

  @override
  Future<Set<String>> fetchHiddenModuleIds(String userId) async {
    try {
      final snapshot =
          await _usersRef.doc(userId).collection('hidden_modules').get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      print('Error fetching hidden module IDs: $e');
      return {};
    }
  }

  @override
  Future<KnowledgeModule> createModule(
      String userId, String title, String description) async {
    try {
      final docRef = await _usersRef.doc(userId).collection('modules').add({
        'title': title,
        'description': description,
        'ownerId': userId,
        'isOfficial': false,
        'createdAt': Timestamp.now(),
      });

      return KnowledgeModule(
        id: docRef.id,
        title: title,
        description: description,
        ownerId: userId,
        isOfficial: false,
      );
    } catch (e) {
      print('Error creating module: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateModule(String userId, String moduleId,
      {String? title, String? description}) async {
    try {
      final ref = _usersRef.doc(userId).collection('modules').doc(moduleId);
      final doc = await ref.get();
      if (!doc.exists) {
        throw Exception('该知识库不存在');
      }
      final Map<String, dynamic> updates = {};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (updates.isEmpty) return;
      await ref.update(updates);
      print('✅ Updated module $moduleId: $updates');
    } catch (e) {
      print('Error updating module: $e');
      rethrow;
    }
  }

  // 🛠️ 修复数据：将所有 module='custom' 的孤儿数据移动到指定 module
  Future<int> fixOrphanItems(String userId, String targetModuleId) async {
    try {
      final snapshot = await _usersRef
          .doc(userId)
          .collection('custom_items')
          .where('module', isEqualTo: 'custom')
          .get();

      if (snapshot.docs.isEmpty) return 0;

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'module': targetModuleId});
      }
      await batch.commit();

      print('✅ Fixed ${snapshot.docs.length} orphan items -> $targetModuleId');
      return snapshot.docs.length;
    } catch (e) {
      print('Error fixing orphans: $e');
      return 0;
    }
  }

  // Update SRS
  @override
  Future<void> updateSRSStatus(
      String itemId, DateTime nextReview, int interval, double ease) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final updateData = {
        'nextReviewTime': nextReview.toIso8601String(),
        'interval': interval,
        'easeFactor': ease,
        'lastReviewed': DateTime.now().toIso8601String(),
      };

      print('Updating SRS for $itemId: $nextReview');

      // 1️⃣ Custom Item
      final customRef =
          _usersRef.doc(user.uid).collection('custom_items').doc(itemId);
      final customDoc = await customRef.get();
      if (customDoc.exists) {
        await customRef.update(updateData);
        return;
      }

      // 2️⃣ Official Item -> Save to separate progress collection
      await _usersRef
          .doc(user.uid)
          .collection('progress')
          .doc(itemId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Error updating SRS: $e');
    }
  }

  // Update Mastery Level (user-specific)
  @override
  Future<void> updateMasteryLevel(String itemId, String masteryLevel) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) print('⚠️ User not logged in, mastery not saved');
        return;
      }

      // 1️⃣ Custom Item: Update directly
      final customRef =
          _usersRef.doc(user.uid).collection('custom_items').doc(itemId);
      final customDoc = await customRef.get();
      if (customDoc.exists) {
        await customRef.update({'masteryLevel': masteryLevel});
        if (kDebugMode)
          print('✅ Mastery saved (Custom): $itemId -> $masteryLevel');
        return;
      }

      // 2️⃣ Official Item: Save to side-car collection
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('mastery')
          .doc(itemId)
          .set({
        'level': masteryLevel,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (kDebugMode)
        print('✅ Mastery saved (Official): $itemId -> $masteryLevel');
    } catch (e) {
      if (kDebugMode) print('❌ Error saving mastery: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String itemId, bool isFavorited) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Data to update
      final updateData = {
        'isFavorited': isFavorited,
        if (isFavorited) 'nextReviewTime': DateTime.now().toIso8601String(),
      };

      print('☁️ Syncing Favorite: $itemId -> $isFavorited');

      // 1️⃣ Try updating Custom Item first (since we know the current user)
      if (user != null) {
        final customRef =
            _usersRef.doc(user.uid).collection('custom_items').doc(itemId);
        final customDoc = await customRef.get();
        if (customDoc.exists) {
          await customRef.update(updateData);
          print('✅ Sync Success (Custom Item)');
          return;
        }
      }

      // 2️⃣ Fallback to Official Feed Item
      await _feedRef.doc(itemId).update(updateData);
      print('✅ Sync Success (Official Item)');
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // SEEDING (Crucial for Step 4)
  @override
  @override
  Future<void> seedInitialData(List<FeedItem> items,
      {bool force = false}) async {
    print('🌱 Start seeding check (timeout 10s)...');
    try {
      // Safety Check: Don't overwrite if data exists!
      final snapshot = await _feedRef.limit(1).get().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('检查数据库状态超时，请确认网络连接'),
          );
      if (!force && snapshot.docs.isNotEmpty) {
        print(
            '⚠️ Database already has data. Skipping Seed to prevent overwrite.');
        return;
      }

      if (force) {
        print('⚡️ Force seed enabled. Overwriting existing data...');
      }

      print('🚀 Database is empty. Seeding ${items.length} items...');
      final batch = _db.batch();
      for (var item in items) {
        final docRef = _feedRef.doc(item.id);
        batch.set(docRef, item.toJson());
      }
      await batch.commit().timeout(const Duration(seconds: 15));
      print('✅ Seeding completed: ${items.length} items.');
    } catch (e) {
      print('❌ Seeding failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveModuleProgress(
      String userId, String moduleId, int index) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('module_progress')
          .doc(moduleId)
          .set({
        'lastIndex': index,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  @override
  Future<Map<String, int>> fetchAllModuleProgress(String userId) async {
    try {
      final snapshot =
          await _usersRef.doc(userId).collection('module_progress').get();
      final map = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        map[doc.id] = data['lastIndex'] as int? ?? 0;
      }
      return map;
    } catch (e) {
      print('Error fetching progress: $e');
      return {};
    }
  }

  @override
  Future<Map<String, int>> fetchModuleLastAccessed(String userId) async {
    try {
      final snapshot =
          await _usersRef.doc(userId).collection('module_progress').get();
      final map = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final updatedAt = data['updatedAt'];
        if (updatedAt == null) continue;
        int ms = 0;
        if (updatedAt is Timestamp) {
          ms = updatedAt.millisecondsSinceEpoch;
        } else if (updatedAt is DateTime) {
          ms = updatedAt.millisecondsSinceEpoch;
        }
        if (ms > 0) map[doc.id] = ms;
      }
      return map;
    } catch (e) {
      print('Error fetching module lastAccessed: $e');
      return {};
    }
  }

  @override
  Stream<Map<String, int>> userStatsStream(String userId) {
    return _usersRef.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return {'credits': 200, 'shareClicks': 0};
      }
      final data = doc.data() as Map<String, dynamic>?;
      return {
        'credits': (data?['credits'] as int?) ?? 200,
        'shareClicks': (data?['shareClicks'] as int?) ?? 0,
      };
    });
  }

  @override
  Future<Map<String, int>> fetchUserStats(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (!doc.exists) {
        await _usersRef.doc(userId).set({
          'credits': 200,
          'shareClicks': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return {'credits': 200, 'shareClicks': 0};
      }

      final data = doc.data() as Map<String, dynamic>?;
      return {
        'credits': (data?['credits'] as int?) ?? 200,
        'shareClicks': (data?['shareClicks'] as int?) ?? 0,
      };
    } catch (e) {
      print('Error fetching stats: $e');
      return {'credits': 200, 'shareClicks': 0};
    }
  }

  @Deprecated('Use fetchUserStats')
  Future<int> fetchUserCredits(String userId) async {
    final stats = await fetchUserStats(userId);
    return stats['credits']!;
  }

  @override
  Future<void> updateUserCredits(String userId, int amount) async {
    try {
      // ⚠️ 使用 set(merge: true) 确保文档不存在时也能创建并初始化
      await _usersRef.doc(userId).set({
        'credits': FieldValue.increment(amount),
      }, SetOptions(merge: true));
      print('💰 Credits updated (set/merge) for $userId: $amount');
    } catch (e) {
      print('Error updating credits: $e');
    }
  }

  Future<void> logShareClick(String referrerId) async {
    try {
      // 优先走 Cloud Function（服务端写入 reado 库，不依赖客户端 Firestore 规则）
      final callable = FirebaseFunctions.instance.httpsCallable('logShareClick');
      await callable.call<Map<String, dynamic>>({'referrerId': referrerId});
      if (kDebugMode) {
        print('📈 Share click tracked (via Cloud Function) for $referrerId');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ logShareClick failed: $e');
        print(st);
      }
      // 可选：若未部署 Cloud Function，可在此 fallback 到直接写 Firestore（需 rules 允许）
      // await _usersRef.doc(referrerId).set({...}, SetOptions(merge: true));
    }
  }

  @override
  Future<void> ensureUserDocument(User user) async {
    try {
      // 1. 先检查文档是否存在
      final doc = await _usersRef.doc(user.uid).get();
      final bool exists = doc.exists;

      // 2. 准备更新数据
      final Map<String, dynamic> updateData = {
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      // 3. 如果是新用户，初始化核心数值
      if (!exists) {
        updateData.addAll({
          'credits': 200,
          'shareClicks': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _usersRef.doc(user.uid).set(updateData, SetOptions(merge: true));
      print(
          '👤 User document ensured for ${user.uid} (${user.email}). New: ${!exists}');
    } catch (e) {
      print('Error ensuring user document: $e');
    }
  }

  @override
  Future<void> deleteModule(String userId, String moduleId) async {
    try {
      await _usersRef.doc(userId).collection('modules').doc(moduleId).delete();
      print('🗑️ Deleted custom module: $moduleId');
    } catch (e) {
      print('❌ Error deleting module: $e');
      rethrow;
    }
  }

  @override
  Future<void> hideOfficialModule(String userId, String moduleId) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('hidden_modules')
          .doc(moduleId)
          .set({
        'hiddenAt': FieldValue.serverTimestamp(),
      });
      print('👁️ Hidden official module: $moduleId');
    } catch (e) {
      print('❌ Error hiding module: $e');
      rethrow;
    }
  }

  @override
  Future<void> hideOfficialFeedItem(String userId, String itemId) async {
    try {
      await _usersRef.doc(userId).collection('hidden_items').doc(itemId).set({
        'hiddenAt': FieldValue.serverTimestamp(),
      });
      print('👁️ Hidden official feed item: $itemId');
    } catch (e) {
      print('❌ Error hiding feed item: $e');
      rethrow;
    }
  }

  @override
  Future<void> unhideOfficialModule(String userId, String moduleId) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('hidden_modules')
          .doc(moduleId)
          .delete();
      print('🔓 Unhidden official module: $moduleId');
    } catch (e) {
      print('❌ Error unhiding module: $e');
      rethrow;
    }
  }

  @override
  Future<void> unhideOfficialFeedItem(String userId, String itemId) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('hidden_items')
          .doc(itemId)
          .delete();
      print('🔓 Unhidden official feed item: $itemId');
    } catch (e) {
      print('❌ Error unhiding feed item: $e');
      rethrow;
    }
  }

  @override
  Future<List<FeedItem>> fetchHiddenFeedItems(String userId) async {
    try {
      final snapshot =
          await _usersRef.doc(userId).collection('hidden_items').get();
      final hiddenIds = snapshot.docs.map((doc) => doc.id).toList();

      if (hiddenIds.isEmpty) return [];

      final items = <FeedItem>[];
      for (var i = 0; i < hiddenIds.length; i += 10) {
        final chunk = hiddenIds.skip(i).take(10).toList();

        // 1. Check official feed_items
        final officialQuery =
            await _feedRef.where(FieldPath.documentId, whereIn: chunk).get();
        items.addAll(officialQuery.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['firestoreId'] = doc.id;
          return FeedItem.fromJson(data);
        }));

        // 2. Check user's custom_items
        final customQuery = await _usersRef
            .doc(userId)
            .collection('custom_items')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        items.addAll(customQuery.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['isCustom'] = true;
          return FeedItem.fromJson(data);
        }));
      }
      return items;
    } catch (e) {
      print('Error fetching hidden feed items: $e');
      return [];
    }
  }

  @override
  Future<void> submitFeedback(
    String type,
    String content,
    String? contact, {
    String? source,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final data = <String, dynamic>{
        'type': type,
        'content': content,
        'contact': contact,
        'userId': user?.uid,
        'userEmail': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': 'web',
        'status': 'pending',
      };
      if (source != null && source.isNotEmpty) {
        data['source'] = source;
      }
      await _db.collection('feedback').add(data);
      print('✅ Feedback submitted successfully');
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAiChatHistory(
      String userId, String itemId) async {
    try {
      final doc = await _usersRef
          .doc(userId)
          .collection('ai_chats')
          .doc(itemId)
          .get();

      if (!doc.exists) return [];

      final data = doc.data();
      if (data == null || data['messages'] == null) return [];

      final raw = data['messages'] as List<dynamic>;
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching AI chat for $itemId: $e');
      return [];
    }
  }

  @override
  Future<void> saveAiChatHistory(
      String userId, String itemId, List<Map<String, dynamic>> messages) async {
    try {
      await _usersRef
          .doc(userId)
          .collection('ai_chats')
          .doc(itemId)
          .set({
        'messages': messages,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('Error saving AI chat for $itemId: $e');
      rethrow;
    }
  }

  static const _officialModuleIds = {'A', 'B', 'C', 'D'};

  @override
  Future<SharedModuleData> fetchSharedModule(
      String ownerId, String moduleId) async {
    if (_officialModuleIds.contains(moduleId)) {
      return _fetchSharedOfficialModule(ownerId, moduleId);
    }
    return _fetchSharedCustomModule(ownerId, moduleId);
  }

  Future<SharedModuleData> _fetchSharedOfficialModule(
      String ownerId, String moduleId) async {
    final querySnapshot = await _feedRef
        .where('module', isEqualTo: moduleId)
        .get()
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('数据库连接超时');
    });
    final items = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['firestoreId'] = doc.id;
      return data;
    }).toList();

    final pub = await getShareSettingsPublic(ownerId);
    final shareNotesPublic = pub.shareNotesPublic;
    if (shareNotesPublic && items.isNotEmpty) {
      const chunkSize = 5;
      for (var i = 0; i < items.length; i += chunkSize) {
        final chunk = items.skip(i).take(chunkSize);
        for (final item in chunk) {
          final itemId = item['id'] as String?;
          if (itemId == null) continue;
          try {
            final notes =
                await _fetchUserNotesForItem(ownerId, itemId);
            if (notes.isNotEmpty) {
              final pages =
                  List<Map<String, dynamic>>.from(item['pages'] ?? []);
              pages.addAll(notes);
              item['pages'] = pages;
            }
          } catch (e) {
            if (kDebugMode) print('⚠️ Shared notes skip $itemId: $e');
          }
        }
        if (i + chunkSize < items.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }

    final feedItems = items.map((data) => FeedItem.fromJson(data)).toList();
    final officialList =
        KnowledgeModule.officials.where((m) => m.id == moduleId).toList();
    final module = officialList.isNotEmpty
        ? officialList.first
        : KnowledgeModule(
            id: moduleId,
            title: '知识库',
            description: '',
            ownerId: 'official',
            isOfficial: true,
          );
    return SharedModuleData(
        module: module, items: feedItems, ownerUiLocale: pub.appLocale);
  }

  Future<SharedModuleData> _fetchSharedCustomModule(
      String ownerId, String moduleId) async {
    final moduleDoc = await _usersRef
        .doc(ownerId)
        .collection('modules')
        .doc(moduleId)
        .get();
    if (!moduleDoc.exists) {
      throw Exception('该知识库不存在或已关闭分享');
    }
    final moduleData = moduleDoc.data()!;
    final module = KnowledgeModule.fromJson(moduleData, moduleId);

    final snapshot = await _usersRef
        .doc(ownerId)
        .collection('custom_items')
        .where('module', isEqualTo: moduleId)
        .get();
    final items = snapshot.docs.map<FeedItem>((doc) {
      final data = doc.data();
      data['isCustom'] = true;
      return FeedItem.fromJson(data);
    }).toList();

    final pub = await getShareSettingsPublic(ownerId);
    return SharedModuleData(
        module: module, items: items, ownerUiLocale: pub.appLocale);
  }

  @override
  Future<({bool shareNotesPublic, String appLocale})> getShareSettingsPublic(
      String userId) async {
    try {
      final doc = await _usersRef
          .doc(userId)
          .collection('share_settings')
          .doc('settings')
          .get();
      if (!doc.exists) {
        return (shareNotesPublic: false, appLocale: 'en');
      }
      final d = doc.data()!;
      final loc = d['appLocale'] as String?;
      final code = (loc == 'zh') ? 'zh' : 'en';
      return (
        shareNotesPublic: d['shareNotesPublic'] as bool? ?? false,
        appLocale: code
      );
    } catch (e) {
      if (kDebugMode) print('getShareSettingsPublic: $e');
      return (shareNotesPublic: false, appLocale: 'en');
    }
  }

  @override
  Future<bool> getShareNotesPublic(String userId) async {
    final s = await getShareSettingsPublic(userId);
    return s.shareNotesPublic;
  }

  @override
  Future<void> setShareNotesPublic(String userId, bool value) async {
    await _usersRef
        .doc(userId)
        .collection('share_settings')
        .doc('settings')
        .set({'shareNotesPublic': value}, SetOptions(merge: true));
  }

  @override
  Future<String> copySharedModuleToMine(
      String ownerId, String sourceModuleId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('请先登录');

    if (_officialModuleIds.contains(sourceModuleId)) {
      throw Exception('官方知识库无需复制，登录后直接在首页学习即可');
    }

    final shared = await _fetchSharedCustomModule(ownerId, sourceModuleId);
    final newModule = await createModule(
      user.uid,
      '${shared.module.title}（来自分享）',
      shared.module.description,
    );

    for (final item in shared.items) {
      final newId =
          '${DateTime.now().millisecondsSinceEpoch}_${item.id.hashCode.abs()}';
      final copy = item.copyWith(id: newId, moduleId: newModule.id);
      await saveCustomFeedItem(copy, user.uid);
    }
    return newModule.id;
  }

  @override
  Future<ShareStats?> getShareStats(String ownerId, String moduleId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('getShareStats');
      final result = await callable.call<Map<String, dynamic>>({
        'ownerId': ownerId,
        'moduleId': moduleId,
      });
      final data = result.data;
      if (data == null) return null;
      return ShareStats.fromMap(Map<String, dynamic>.from(data));
    } catch (e) {
      if (kDebugMode) print('getShareStats error: $e');
      return null;
    }
  }

  @override
  Future<void> recordShareView(String ownerId, String moduleId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('recordShareView');
      await callable.call<Map<String, dynamic>>({
        'ownerId': ownerId,
        'moduleId': moduleId,
      });
    } catch (e) {
      if (kDebugMode) print('recordShareView error: $e');
    }
  }

  @override
  Future<void> recordShareSave(String ownerId, String moduleId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('recordShareSave');
      await callable.call<Map<String, dynamic>>({
        'ownerId': ownerId,
        'moduleId': moduleId,
      });
    } catch (e) {
      if (kDebugMode) print('recordShareSave error: $e');
    }
  }

  @override
  Future<bool> recordShareLike(String ownerId, String moduleId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('recordShareLike');
      final result = await callable.call<Map<String, dynamic>>({
        'ownerId': ownerId,
        'moduleId': moduleId,
      });
      final data = result.data;
      // true = 本次新点赞成功，false = 已点过
      return data == null || data['alreadyLiked'] != true;
    } catch (e) {
      if (kDebugMode) print('recordShareLike error: $e');
      return false;
    }
  }

  @override
  Future<bool> getDailyCheckInClaimedToday() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final callable =
          FirebaseFunctions.instance.httpsCallable('getDailyCheckInStatus');
      final result = await callable.call<Map<String, dynamic>>({});
      final data = result.data;
      return data != null && data['claimedToday'] == true;
    } catch (e) {
      if (kDebugMode) print('getDailyCheckInClaimedToday error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> claimDailyCheckIn() async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('claimDailyCheckIn');
      final result = await callable.call<Map<String, dynamic>>({});
      final data = result.data ?? {};
      return {
        'success': data['success'] == true,
        'alreadyClaimed': data['alreadyClaimed'] == true,
        'credits': (data['credits'] is num) ? (data['credits'] as num).toInt() : 0,
      };
    } catch (e) {
      if (kDebugMode) print('claimDailyCheckIn error: $e');
      return {'success': false, 'alreadyClaimed': false, 'credits': 0};
    }
  }
}
