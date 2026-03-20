import 'package:flutter/widgets.dart';

bool _zh(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code == 'zh' || code.startsWith('zh_');
}

/// 收藏复习页计数、任务中心文案（随界面语言切换）
abstract final class VaultTaskL10n {
  static String vaultReviewProgress(
          BuildContext context, int current, int total) =>
      _zh(context) ? '复习 $current/$total' : 'Review $current/$total';

  // —— 任务中心 ——
  static String taskCenterTitle(BuildContext context) =>
      _zh(context) ? '任务中心' : 'Task center';

  static String taskCenterClearTooltip(BuildContext context) =>
      _zh(context) ? '清理已完成任务' : 'Clear finished tasks';

  static String taskCenterEmpty(BuildContext context) =>
      _zh(context) ? '暂无任务' : 'No tasks yet';

  static String taskCenterEmptyHint(BuildContext context) => _zh(context)
      ? '使用 AI 生成知识卡片后，任务会显示在这里'
      : 'Tasks appear here after you generate cards with AI.';

  static String taskCenterLoadFailed(BuildContext context, Object e) =>
      _zh(context) ? '加载失败: $e' : 'Load failed: $e';

  static String taskCenterShareEarn(BuildContext context) =>
      _zh(context) ? '分享赚积分' : 'Share for credits';

  static String taskCenterCleanupTitle(BuildContext context) =>
      _zh(context) ? '清理任务' : 'Clear tasks';

  static String taskCenterCleanupBody(BuildContext context) => _zh(context)
      ? '确定要删除所有已完成和失败的任务记录吗？\n（生成的内容不会被删除）'
      : 'Delete all completed and failed task records?\n(Generated cards stay in your library.)';

  static String taskCenterCleanedCount(BuildContext context, int n) =>
      _zh(context) ? '已清理 $n 条任务记录' : 'Cleared $n task record(s)';

  static String taskCenterCleanupFailed(BuildContext context, Object e) =>
      _zh(context) ? '清理失败: $e' : 'Cleanup failed: $e';

  static String taskStatusPending(BuildContext context) =>
      _zh(context) ? '等待处理...' : 'Waiting...';

  static String taskStatusProcessing(BuildContext context) =>
      _zh(context) ? 'AI 正在生成...' : 'AI generating...';

  static String taskStatusCompleted(BuildContext context) =>
      _zh(context) ? '生成完成' : 'Done';

  static String taskStatusFailed(BuildContext context) =>
      _zh(context) ? '生成失败' : 'Failed';

  static String taskGeneratedCards(BuildContext context) =>
      _zh(context) ? '生成的知识点' : 'Generated cards';

  static String taskMoreCards(BuildContext context, int n) =>
      _zh(context) ? '还有 $n 个...' : '$n more...';

  static String taskAutoSaved(BuildContext context) =>
      _zh(context) ? '已自动保存到你的知识库' : 'Saved to your library';

  static String taskUnnamed(BuildContext context) =>
      _zh(context) ? '未命名' : 'Untitled';

  static String timeJustNow(BuildContext context) =>
      _zh(context) ? '刚刚' : 'Just now';

  static String timeMinutesAgo(BuildContext context, int m) =>
      _zh(context) ? '$m 分钟前' : '$m min ago';

  static String timeHoursAgo(BuildContext context, int h) =>
      _zh(context) ? '$h 小时前' : '$h h ago';

  static String timeDaysAgo(BuildContext context, int d) =>
      _zh(context) ? '$d 天前' : '$d d ago';

  static String shareInviteClipboard(BuildContext context, String url) =>
      _zh(context)
          ? '嘿！我正在使用 Reado 学习，这个 AI 工具太强了，快来看看：\n$url'
          : 'Hey! I\'m learning with Reado — check out this AI study app:\n$url';

  static String shareSuccessTitle(BuildContext context) =>
      _zh(context) ? '分享成功！获得 10 积分动作奖励 🎁' : 'Shared! +10 credits 🎁';

  static String shareCopiedLine1(BuildContext context) =>
      _zh(context) ? '已经为您复制到剪贴板' : 'Copied to clipboard';

  static String shareCopiedLine2(BuildContext context) => _zh(context)
      ? '分享链接已复制到剪贴板，快粘贴给你的朋友使用吧'
      : 'Paste the link and share with friends.';

  static String shareFriendReward(BuildContext context) => _zh(context)
      ? '好友通过您的链接加入时，您将再获得 50 积分'
      : '+50 credits when a friend joins via your link.';
}
