import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/feed_item.dart';
import '../../models/knowledge_module.dart';

// Interface for Data Service (Repo Pattern)
abstract class DataService {
  Future<List<FeedItem>> fetchFeedItems(String moduleId);
  Future<List<FeedItem>> fetchCustomFeedItems(String userId); // 获取用户自定义内容
  Future<void> saveUserNote(String itemId, String question, String answer);
  Future<void> deleteUserNote(String itemId, UserNotePage note);
  Future<void> updateUserNote(
      String itemId, UserNotePage oldNote, String newQ, String newA);
  Future<void> deleteCustomFeedItem(String itemId);
  Future<void> updateSRSStatus(
      String itemId, DateTime nextReview, int interval, double ease);
  Future<void> updateMasteryLevel(String itemId, String masteryLevel);
  Future<void> toggleFavorite(String itemId, bool isFavorited);
  Future<void> seedInitialData(List<FeedItem> items); // For migration
  Future<void> saveCustomFeedItem(
      FeedItem item, String userId); // 保存AI生成的自定义知识点
  Future<List<KnowledgeModule>> fetchUserModules(String userId);
  Future<KnowledgeModule> createModule(
      String userId, String title, String description);
  Future<int> fixOrphanItems(String userId, String targetModuleId);
  Future<void> saveModuleProgress(
      String userId, String moduleId, int index); // Save reading progress
  Future<Map<String, int>> fetchAllModuleProgress(
      String userId); // Fetch all progress
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
  CollectionReference get _feedRef => _db.collection('feed_items');
  CollectionReference get _usersRef => _db.collection('users');

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
        final data = doc.data() as Map<String, dynamic>;
        data['firestoreId'] = doc.id;
        return data;
      }).toList();

      // Merge user notes and mastery level for each item
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('🧠 Parallel fetching metadata for ${items.length} items...');
        await Future.wait(items.map((item) async {
          final itemId = item['id'] as String?;
          if (itemId == null) return;

          try {
            // 1. Fetch Notes & 2. Fetch Mastery (Parallel)
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

            final masteryDoc = results[1] as DocumentSnapshot;
            if (masteryDoc.exists) {
              final masteryData = masteryDoc.data() as Map<String, dynamic>?;
              if (masteryData != null && masteryData['level'] != null) {
                item['masteryLevel'] = masteryData['level'];
              }
            }
          } catch (e) {
            // Log & silent ignore to prevent flow crash
            if (kDebugMode) print('⚠️ Metadata skip for $itemId: $e');
          }
        }));
      }

      final feedItems = items.map((data) => FeedItem.fromJson(data)).toList();

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
    try {
      print('📥 Fetching modules for user: $userId (timeout 10s)');
      final snapshot = await _usersRef
          .doc(userId)
          .collection('modules')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
        print('⏱️ fetchUserModules timed out');
        throw Exception('获取个人库列表超时');
      });
      return snapshot.docs
          .map((doc) => KnowledgeModule.fromJson(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching modules: $e');
      return [];
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
  Future<void> seedInitialData(List<FeedItem> items) async {
    print('🌱 Start seeding check (timeout 10s)...');
    try {
      // Safety Check: Don't overwrite if data exists!
      final snapshot = await _feedRef.limit(1).get().timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('检查数据库状态超时，请确认网络连接'),
          );
      if (snapshot.docs.isNotEmpty) {
        print(
            '⚠️ Database already has data. Skipping Seed to prevent overwrite.');
        return;
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
        final data = doc.data() as Map<String, dynamic>;
        map[doc.id] = data['lastIndex'] as int? ?? 0;
      }
      return map;
    } catch (e) {
      print('Error fetching progress: $e');
      return {};
    }
  }
}
