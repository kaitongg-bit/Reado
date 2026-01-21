# Learning Tracking System - Implementation Plan

## 📋 Overview
Implement comprehensive learning tracking to measure **true mastery** instead of simple view counts.

---

## 🎯 Goals

### 1. Track Meaningful Engagement
- ✅ Reading duration (prevent "speed scrolling")
- ✅ Favorites (shows interest)
- ✅ AI conversations with pinned notes (deep learning)
- ✅ SRS reviews (memory reinforcement)

### 2. Display Progress Accurately
- Show total cards per knowledge space (e.g., "5/30 cards mastered")
- Calculate mastery based on engagement, not just views

### 3. Fix Data Sync Issues
- ✅ VaultPage should use `allItemsProvider` (not `feedProvider`)
- ✅ Ensure `isFavorited` syncs correctly across all pages

---

## 🔧 Technical Implementation

### Phase 1: Extend `FeedItem` Model ✅ (30 min)

**File**: `lib/models/feed_item.dart`

```dart
class FeedItem {
  // Existing fields...
  final bool isFavorited;
  
  // NEW: Learning tracking fields
  final bool hasBeenRead;            // True if read with sufficient time
  final int readingDurationSeconds;  // Total reading time
  final DateTime? lastReadAt;        // Last time user viewed this
  final bool hasAIPinnedNotes;       // True if user pinned AI chat
  final bool hasBeenReviewed;        // True if reviewed in SRS
  
  // Computed property: True mastery indicator
  bool get isMastered {
    return hasBeenRead && 
           (isFavorited || hasAIPinnedNotes || hasBeenReviewed);
  }
  
  FeedItem({
    // ... existing params
    this.hasBeenRead = false,
    this.readingDurationSeconds = 0,
    this.lastReadAt,
    this.hasAIPinnedNotes = false,
    this.hasBeenReviewed = false,
  });
  
  // Update copyWith, toJson, fromJson accordingly
}
```

**Reading Time Validation**:
```dart
// Minimum reading time = readingTimeMinutes * 60 * 0.5 (50% threshold)
bool get hasBeenRead {
  return readingDurationSeconds >= (readingTimeMinutes * 60 * 0.5);
}
```

---

### Phase 2: Track Reading Duration ✅ (45 min)

**File**: `lib/features/feed/presentation/widgets/feed_item_view.dart`

```dart
class _FeedItemViewState extends ConsumerState<FeedItemView> {
  DateTime? _pageStartTime;
  int _totalReadingSeconds = 0;
  
  @override
  void initState() {
    super.initState();
    _pageStartTime = DateTime.now();
  }
  
  @override
  void dispose() {
    _saveReadingDuration();
    super.dispose();
  }
  
  void _onPageChanged(int index) {
    // Save duration for previous page
    _saveReadingDuration();
    
    // Reset timer for new page
    _pageStartTime = DateTime.now();
    setState(() => _currentPageIndex = index);
  }
  
  void _saveReadingDuration() {
    if (_pageStartTime != null) {
      final duration = DateTime.now().difference(_pageStartTime!).inSeconds;
      _totalReadingSeconds += duration;
      
      // Auto-mark as "read" if exceeds threshold
      final minReadTime = widget.feedItem.readingTimeMinutes * 60 * 0.5;
      if (_totalReadingSeconds >= minReadTime && !widget.feedItem.hasBeenRead) {
        _updateItemAsRead();
      }
    }
  }
  
  void _updateItemAsRead() {
    final updated = widget.feedItem.copyWith(
      hasBeenRead: true,
      readingDurationSeconds: _totalReadingSeconds,
      lastReadAt: DateTime.now(),
    );
    ref.read(feedProvider.notifier).updateItem(updated);
  }
}
```

---

### Phase 3: Update AI Pin Logic ✅ (20 min)

**File**: Same as above (`feed_item_view.dart`)

```dart
void _handlePinAction() {
  // ... existing pin logic
  
  // NEW: Mark item as having AI notes
  final updated = widget.feedItem.copyWith(hasAIPinnedNotes: true);
  ref.read(feedProvider.notifier).updateItem(updated);
  
  setState(() {
    _pinnedMessageIndices.addAll(_selectedMessageIndices);
    _selectedMessageIndices.clear();
  });
}
```

---

### Phase 4: Update SRS Review Logic ✅ (15 min)

**File**: `lib/features/vault/presentation/srs_review_page.dart`

```dart
void _handleReview(FeedItem currentItem, int intervalDays, FeedItemMastery mastery) {
  // ... existing logic
  
  final updatedItem = currentItem.copyWith(
    nextReviewTime: nextReview,
    interval: intervalDays,
    masteryLevel: mastery,
    hasBeenReviewed: true,  // NEW: Mark as reviewed
  );
  
  ref.read(feedProvider.notifier).updateItem(updatedItem);
  // ...
}
```

---

### Phase 5: Fix VaultPage Data Sync Bug 🐛 (10 min)

**File**: `lib/features/vault/presentation/vault_page.dart`

**Current (WRONG)**:
```dart
final allItems = ref.watch(feedProvider);  // ❌ Gets filtered state
```

**Fixed**:
```dart
final allItems = ref.watch(allItemsProvider);  // ✅ Gets complete state
```

---

### Phase 6: Update HomeTab Card Counts ✅ (30 min)

**File**: `lib/features/home/presentation/widgets/home_tab.dart`

```dart
Widget _buildKnowledgeSpaceCard({
  required String moduleId,
  // ... other params
}) {
  final feedItems = ref.watch(allItemsProvider);
  
  // Filter items for this module
  final moduleItems = feedItems.where((i) => i.moduleId == moduleId).toList();
  final totalCards = moduleItems.length;
  final masteredCards = moduleItems.where((i) => i.isMastered).length;
  final progress = totalCards > 0 ? masteredCards / totalCards : 0.0;
  
  return Container(
    // ... styling
    child: Column(
      children: [
        Text(title),
        Text(description),
        
        // Progress bar
        LinearProgressIndicator(value: progress),
        
        // NEW: Show counts
        Text('$masteredCards/$totalCards cards mastered',
          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        
        // Button
        ElevatedButton(child: Text('Continue Learning')),
      ],
    ),
  );
}
```

---

## 📊 Data Model Changes Summary

### FeedItem (5 new fields)
| Field | Type | Purpose |
|-------|------|---------|
| `hasBeenRead` | `bool` | Computed from duration |
| `readingDurationSeconds` | `int` | Total time spent reading |
| `lastReadAt` | `DateTime?` | Last view timestamp |
| `hasAIPinnedNotes` | `bool` | User created AI notes |
| `hasBeenReviewed` | `bool` | Reviewed in SRS |

### Firestore Schema
```json
{
  "id": "b001",
  "title": "...",
  "readingTimeMinutes": 5,
  "isFavorited": true,
  "hasBeenRead": true,
  "readingDurationSeconds": 180,
  "lastReadAt": "2026-01-21T17:00:00Z",
  "hasAIPinnedNotes": true,
  "hasBeenReviewed": false
}
```

**Migration**: All existing items will default to `false`/`0` for new fields.

---

## 🚀 Rollout Plan

### Quick Wins (1-2 hours)
1. ✅ Fix VaultPage to use `allItemsProvider`
2. ✅ Add card counts to HomeTab ("X/Y mastered")
3. ✅ Extend FeedItem model with new fields

### Medium Priority (3-4 hours)
4. ✅ Implement reading duration tracking
5. ✅ Update AI pin logic
6. ✅ Update SRS review logic

### Nice to Have (Future)
7. Analytics dashboard (time spent per module)
8. Streak tracking (days in a row)
9. Export learning report

---

## 🧪 Testing Checklist

- [ ] VaultPage shows correct favorite status
- [ ] Reading for 50% of `readingTimeMinutes` marks item as "read"
- [ ] Pinning AI note sets `hasAIPinnedNotes = true`
- [ ] SRS review sets `hasBeenReviewed = true`
- [ ] HomeTab displays accurate "X/Y cards mastered"
- [ ] Progress bar reflects true mastery (not just views)
- [ ] Firestore correctly persists all new fields

---

## 💡 Key Insights

### Why This Design Works
1. **Firestore-friendly**: All fields are simple types (bool, int, DateTime)
2. **Progressive enhancement**: Existing data continues to work
3. **Privacy-first**: All tracking is local to user's Firestore
4. **Flexible definition**: `isMastered` can be adjusted without schema changes

### Potential Issues
- **Clock manipulation**: User could fool reading time (acceptable for MVP)
- **Background tabs**: Need to pause timer when app goes to background
- **Partial reads**: User might read 80% but not mark complete (acceptable)

---

## 📝 Next Steps

Run this command to start:
```bash
# 1. Fix VaultPage immediately
# 2. Extend FeedItem model
# 3. Test with mock data
# 4. Deploy to Firestore
```
