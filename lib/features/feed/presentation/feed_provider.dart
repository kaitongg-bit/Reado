import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock_data.dart';
import '../../../models/feed_item.dart';

class FeedNotifier extends StateNotifier<List<FeedItem>> {
  FeedNotifier() : super(MockData.initialFeedItems);

  /// 模拟从后端加载数据
  void loadModule(String moduleId) {
    // 简单过滤 Mock Data
    state = MockData.initialFeedItems
        .where((item) => item.moduleId == moduleId)
        .toList();
  }

  /// 模拟搜索逻辑
  void searchItems(String query) {
    if (query.isEmpty) {
      state = [];
      return;
    }
    
    state = MockData.initialFeedItems.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query.toLowerCase());
      // 也可以搜 markdown 内容，这里简单处理搜标题
      return titleMatch;
    }).toList();
  }

  /// Pin 笔记逻辑：找到对应 ID 的 Item，追加 UserNotePage
  void pinNoteToItem(String itemId, String question, String answer) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          item.copyWith(
            pages: [
              ...item.pages,
              UserNotePage(
                question: question,
                answer: answer,
                createdAt: DateTime.now(),
              )
            ],
          )
        else
          item
    ];
  }
}

/// 全局 Feed Provider
final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedItem>>((ref) {
  return FeedNotifier();
});
