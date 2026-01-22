import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../models/feed_item.dart';
import '../../models/knowledge_module.dart';

// Interface for Data Service (Repo Pattern)
abstract class DataService {
  Future<List<FeedItem>> fetchFeedItems(String moduleId);
  Future<List<FeedItem>> fetchCustomFeedItems(String userId); // 获取用户自定义内容
  Future<void> saveUserNote(String itemId, String question, String answer);
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
}

class FirestoreService implements DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _feedRef => _db.collection('feed_items');
  CollectionReference get _usersRef => _db.collection('users');

  // Fetch feed items for a specific module (with user notes merged)
  @override
  Future<List<FeedItem>> fetchFeedItems(String moduleId) async {
    try {
      if (kDebugMode) print('📥 Fetching items for module: $moduleId');
      final querySnapshot = await _feedRef
          .where('module', isEqualTo: moduleId)
          .orderBy('id')
          .get();

      final items = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['firestoreId'] = doc.id;
        return data;
      }).toList();

      // Merge user notes for each item
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        for (var item in items) {
          final itemId = item['id'] as String?;
          if (itemId == null) continue;

          final userNotes = await _fetchUserNotesForItem(user.uid, itemId);
          if (userNotes.isNotEmpty) {
            // Merge user notes into pages array
            final pages = List<Map<String, dynamic>>.from(item['pages'] ?? []);
            pages.addAll(userNotes);
            item['pages'] = pages;
          }

          // ✅ Merge user mastery level
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

      // Convert to FeedItem objects
      final feedItems = items.map((data) => FeedItem.fromJson(data)).toList();

      if (kDebugMode)
        print('✅ Fetched ${feedItems.length} items for module $moduleId');
      return feedItems;
    } catch (e) {
      if (kDebugMode) print('Error fetching items: $e');
      return [];
    }
  }

  // Helper: Fetch user notes for a specific item
  Future<List<Map<String, dynamic>>> _fetchUserNotesForItem(
      String userId, String itemId) async {
    try {
      final noteDoc = await FirebaseFirestore.instance
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

      // Save to: users/{uid}/notes/{itemId}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(itemId)
          .set({
        'pages': FieldValue.arrayUnion([
          {
            'type': 'user_note',
            'question': question,
            'answer': answer,
            'createdAt':
                Timestamp.now(), // ✅ Fixed: use Timestamp.now() instead
          }
        ])
      }, SetOptions(merge: true));

      debugPrint('✅ User note saved: itemId=$itemId, user=${user.uid}');
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
  Future<List<KnowledgeModule>> fetchUserModules(String userId) async {
    try {
      final snapshot = await _usersRef
          .doc(userId)
          .collection('modules')
          .orderBy('createdAt', descending: true)
          .get();
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
      print('Updating SRS for $itemId: $nextReview');
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

      // Save to: users/{uid}/mastery/{itemId}
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
    // Safety Check: Don't overwrite if data exists!
    final snapshot = await _feedRef.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      print(
          '⚠️ Database already has data. Skipping Seed to prevent overwrite.');
      return;
    }

    final batch = _db.batch();

    for (var item in items) {
      final docRef = _feedRef.doc(item.id);
      batch.set(docRef, item.toJson());
    }

    await batch.commit();
    print('Seeding completed: ${items.length} items.');
  }
}
