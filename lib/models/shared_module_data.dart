import 'feed_item.dart';
import 'knowledge_module.dart';

/// 共享知识库的只读数据：模块元信息 + 卡片列表（供游客或「保存到我的知识库」使用）
/// [ownerUiLocale] 分享者在 share_settings 中公开的界面语言 `zh`/`en`，用于访客页与分享者一致。
class SharedModuleData {
  final KnowledgeModule module;
  final List<FeedItem> items;
  final String ownerUiLocale;

  const SharedModuleData({
    required this.module,
    required this.items,
    this.ownerUiLocale = 'en',
  });
}
