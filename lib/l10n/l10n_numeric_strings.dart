import 'package:flutter/widgets.dart';

/// Flutter gen-l10n 会把 ARB 里的 `$n` 生成成字面量 `\$n`，界面显示「$n」。
/// 所有「数字 + 单位」的文案在此用代码拼接，不依赖生成器占位符。

bool _isZh(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code == 'zh' || code.startsWith('zh_');
}

/// 与 AppLocalizations 并行使用：仅负责带数字的短句。
abstract final class L10nNumbers {
  static String studyMinutes(BuildContext context, int n) =>
      _isZh(context) ? '$n 分钟' : '$n min';

  static String moduleViews(BuildContext context, int n) =>
      _isZh(context) ? '$n 人浏览' : '$n views';

  static String moduleSaves(BuildContext context, int n) =>
      _isZh(context) ? '$n 人保存' : '$n saves';

  static String moduleLikes(BuildContext context, int n) =>
      _isZh(context) ? '$n 人点赞' : '$n likes';

  static String moduleShareData(
      BuildContext context, int views, int saves, int likes) {
    return _isZh(context)
        ? '分享数据：$views 人浏览 · $saves 人保存 · $likes 人点赞'
        : 'Share: $views views · $saves saves · $likes likes';
  }

  static String moduleCardCount(BuildContext context, int count) =>
      _isZh(context) ? '共 $count 张卡片' : '$count cards';

  static String moduleCardsTag(BuildContext context, int count) =>
      _isZh(context) ? '$count 张卡片' : '$count cards';

  static String moduleMasteredPct(BuildContext context, int pct) =>
      _isZh(context) ? '$pct% 已掌握' : '$pct% mastered';

  static String shareStatsFormat(
      BuildContext context, int views, int saves, int likes) {
    return _isZh(context)
        ? '$views 人浏览 · $saves 人保存 · $likes 人点赞'
        : '$views views · $saves saves · $likes likes';
  }

  static String profileMasteredCount(BuildContext context, int count) =>
      _isZh(context) ? '$count 已掌握' : '$count mastered';

  static String checkInCreditsReceived(BuildContext context, int credits) =>
      _isZh(context)
          ? '已领取每日签到积分，$credits 积分'
          : 'Daily check-in: $credits credits';

  static String noteReviewTitle(
          BuildContext context, int current, int total) =>
      _isZh(context)
          ? '笔记回顾 $current/$total'
          : 'Note review $current/$total';

  static String addMaterialGeneratedCount(BuildContext context, int count) =>
      _isZh(context) ? '已生成 $count 个知识点' : 'Generated $count items';

  static String moduleShareCopyBody(
      BuildContext context, String url, String title) {
    return _isZh(context)
        ? '嘿！我正在使用 Reado 学习这个超棒的知识库，快来看看：\n$url\n\n这是我创建的名叫「$title」的知识库，欢迎你保存到自己的知识库中。'
        : 'Hey! I\'m learning this library with Reado. Check it out:\n$url\n\nThis is my library "$title". You can save it to yours.';
  }

  static String markedAsLabel(BuildContext context, String label) =>
      _isZh(context) ? '已标记为 $label' : 'Marked as $label';
}
