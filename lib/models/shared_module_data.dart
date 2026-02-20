import 'feed_item.dart';
import 'knowledge_module.dart';

/// 共享知识库的只读数据：模块元信息 + 卡片列表（供游客或「保存到我的知识库」使用）
class SharedModuleData {
  final KnowledgeModule module;
  final List<FeedItem> items;

  const SharedModuleData({
    required this.module,
    required this.items,
  });
}
