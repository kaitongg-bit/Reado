import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/feed_item.dart';

// Interface for Data Service (Repo Pattern)
abstract class DataService {
  Future<List<FeedItem>> fetchFeedItems(String moduleId);
  Future<void> saveUserNote(String itemId, String question, String answer);
  Future<void> updateSRSStatus(String itemId, DateTime nextReview, int interval, double ease);
  Future<void> toggleFavorite(String itemId, bool isFavorited);
  Future<void> seedInitialData(List<FeedItem> items); // For migration
}

class FirestoreService implements DataService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _feedRef => _db.collection('feed_items');
  CollectionReference get _usersRef => _db.collection('users');

  // Fetch Items
  @override
  Future<List<FeedItem>> fetchFeedItems(String moduleId) async {
    try {
      print('Fetching module $moduleId...');
      final snapshot = await _feedRef
          .where('module', isEqualTo: moduleId)
          .orderBy('id')
          .get();

      final items = snapshot.docs.map<FeedItem>((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final item = FeedItem.fromJson(data);
        // Debug Log
        if (item.isFavorited) print('🔥 Found Favorite from DB: ${item.id}');
        return item;
      }).toList();
      
      return items;
    } catch (e) {
      print('Error fetching items for module $moduleId: $e');
      return [];
    }
  }

  // Save User Note
  @override
  Future<void> saveUserNote(String itemId, String question, String answer) async {
     print('TODO: Save note to users/{uid}/notes/$itemId');
  }

  // Update SRS
  @override
  Future<void> updateSRSStatus(String itemId, DateTime nextReview, int interval, double ease) async {
     try {
       print('Updating SRS for $itemId: $nextReview');
     } catch (e) {
       print('Error updating SRS: $e');
     }
  }

  @override
  Future<void> toggleFavorite(String itemId, bool isFavorited) async {
    try {
      print('☁️ Syncing Favorite: $itemId -> $isFavorited');
      await _feedRef.doc(itemId).update({
        'isFavorited': isFavorited,
        // Optional: Update review time if favoring
        if (isFavorited) 'nextReviewTime': DateTime.now().toIso8601String(),
      });
      print('✅ Sync Success');
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
      print('⚠️ Database already has data. Skipping Seed to prevent overwrite.');
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
