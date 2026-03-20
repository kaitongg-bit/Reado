import 'package:flutter/widgets.dart';

bool _zh(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code == 'zh' || code.startsWith('zh_');
}

/// 添加材料弹窗：队列、小贴士、解析/拆解确认等（中英文）
abstract final class AddMaterialL10n {
  static String textPasteHint(BuildContext context) => _zh(context)
      ? '在此粘贴文章内容、笔记或网页文本...\n\n示例：\n# 什么是 Flutter\nFlutter 是 Google 开源的 UI 工具包...\n\n# 特点\n1. 跨平台\n2. 高性能...'
      : 'Paste article, notes, or web text here...\n\nExample:\n# What is Flutter\nFlutter is Google\'s open UI toolkit...\n\n# Features\n1. Cross-platform\n2. High performance...';

  static String directTipTitle(BuildContext context) =>
      _zh(context) ? '直接导模式的小贴士：' : 'Direct import tip:';

  static String directTipMid1(BuildContext context) =>
      _zh(context) ? '使用 Markdown 标题 (如 ' : 'Use Markdown headings (e.g. ';

  static String directTipHashExample(BuildContext context) =>
      _zh(context) ? '# 标题' : '# Heading';

  static String directTipMid2(BuildContext context) => _zh(context)
      ? ') 可手动拆分卡片，无需消耗 AI 额度。若无标题，将默认使用第一句话作为标题。'
      : ') to split cards without using AI credits. Without headings, the first sentence becomes the title.';

  static String directImport(BuildContext context) =>
      _zh(context) ? '直接导入' : 'Direct import';

  static String directQueue(BuildContext context) =>
      _zh(context) ? '直接导队列' : 'Direct queue';

  static String aiQueue(BuildContext context) =>
      _zh(context) ? 'AI队列' : 'AI queue';

  static String snackDirectQueued(BuildContext context) =>
      _zh(context) ? '已直接加入队列' : 'Added to direct queue';

  static String snackAiQueued(BuildContext context) =>
      _zh(context) ? '已加入AI队列' : 'Added to AI queue';

  static String generating(BuildContext context) =>
      _zh(context) ? '正在生成...' : 'Generating...';

  static String submittingTask(BuildContext context) =>
      _zh(context) ? '正在提交任务...' : 'Submitting...';

  static String fileFormatsHint(BuildContext context) =>
      _zh(context) ? '支持PDF, Word, Markdown' : 'PDF, Word, Markdown';

  static String fileSelectedChange(BuildContext context) =>
      _zh(context) ? '已选择 (点击更换)' : 'Selected (tap to change)';

  static String urlHint(BuildContext context) => _zh(context)
      ? '支持大部分网页、YouTube等'
      : 'Web pages, YouTube links, etc.';

  static String charsAndEstTime(
      BuildContext context, int chars, String timeStr) =>
      _zh(context)
          ? '包含 $chars 字符 · 预计耗时 $timeStr'
          : '~$chars chars · est. $timeStr';

  static String snackFileQueued(BuildContext context) =>
      _zh(context) ? '文件已加入队列' : 'File added to queue';

  static String snackLinkQueued(BuildContext context) =>
      _zh(context) ? '链接已加入队列' : 'Link added to queue';

  static String addToQueue(BuildContext context) =>
      _zh(context) ? '加入队列' : 'Add to queue';

  static String parse(BuildContext context) =>
      _zh(context) ? '解析' : 'Parse';

  static String startDeconstructCredits(BuildContext context, int credits) =>
      _zh(context)
          ? '开始智能拆解 ($credits 积分)'
          : 'Start deconstruct ($credits credits)';

  static String waitParse(BuildContext context) =>
      _zh(context) ? '等待解析...' : 'Parse first...';

  static String saveWithoutDeconstruct(BuildContext context) =>
      _zh(context) ? '直接收藏 (不拆解)' : 'Save only (no AI split)';

  static String comingSoon(BuildContext context) =>
      _zh(context) ? '即将支持' : 'Coming soon';

  static String estSeconds(BuildContext context, int s) =>
      _zh(context) ? '$s 秒' : '${s}s';

  static String estMinutes(BuildContext context, double m) =>
      _zh(context) ? '${m.toStringAsFixed(1)} 分钟' : '${m.toStringAsFixed(1)} min';

  static String batchConfirmDirectTitle(BuildContext context) =>
      _zh(context) ? '确认批量处理' : 'Confirm batch';

  static String batchConfirmDirectBody(BuildContext context) => _zh(context)
      ? '当前队列中仅有「直接导入」项，不会消耗积分。是否开始？'
      : 'Only direct-import items in queue. No credits. Start?';

  static String batchStart(BuildContext context) =>
      _zh(context) ? '开始' : 'Start';

  static String batchDeconstructTitle(BuildContext context) =>
      _zh(context) ? '确认开始批量拆解？' : 'Start batch deconstruct?';

  static String batchPendingLine(
      BuildContext context, int total, int aiCount) =>
      _zh(context)
          ? '共 $total 项待处理（其中 $aiCount 项为 AI 智能拆解）。'
          : '$total item(s) pending ($aiCount AI deconstruct).';

  static String batchCreditsOnlyParsed(
      BuildContext context, int credits) =>
      _zh(context) ? '本次将扣除 $credits 积分' : 'This will use $credits credits';

  static String batchCreditsAiOnly(
      BuildContext context, int n) =>
      _zh(context)
          ? '共 $n 项，将按内容长度逐项扣费（约 10～40 积分/项）'
          : '$n item(s), ~10–40 credits each by length';

  static String batchCreditsMixed(BuildContext context, int parsedCredits,
          int rest) =>
      _zh(context)
          ? '已解析项合计 $parsedCredits 积分；其余 $rest 项将按长度逐项扣费（10～40 积分/项）'
          : '$parsedCredits credits for parsed; ~10–40/item for $rest more';

  static String batchPerItemTip(BuildContext context) => _zh(context)
      ? '💡 每项将根据字数按规则扣费（约 10～40 积分/项），与单次拆解一致。'
      : '💡 Charged by length (~10–40 credits/item), same as single run.';

  static String startGenerate(BuildContext context) =>
      _zh(context) ? '开始生成' : 'Start';

  static String singleDeconstructTitle(BuildContext context) =>
      _zh(context) ? '确认开始拆解？' : 'Start deconstruct?';

  static String recognizedChars(BuildContext context, int n) =>
      _zh(context) ? '系统已识别内容：约 $n 字' : 'About $n characters detected';

  static String estTimePrefix(BuildContext context) =>
      _zh(context) ? '预计耗时：' : 'Est. time: ';

  static String deductThisTime(BuildContext context) =>
      _zh(context) ? '本次将扣除：' : 'Credits to use:';

  static String creditsUnit(BuildContext context) =>
      _zh(context) ? ' 积分' : ' credits';

  static String tipParseFree(BuildContext context) => _zh(context)
      ? '💡 提示：AI 解析内容是免费的，智能拆解将根据内容深度自动匹配最佳方案。'
      : '💡 Parsing is free; smart deconstruct uses credits by content depth.';

  static String readoPerk(BuildContext context) => _zh(context)
      ? 'Reado 福利：AI 聊天、解析文件完全免费'
      : 'Reado: AI chat & file parsing are free';

  static String insufficientCreditsTitle(BuildContext context) =>
      _zh(context) ? '积分不足' : 'Not enough credits';

  static String insufficientCreditsBody(BuildContext context) => _zh(context)
      ? '执行 AI 解析或生成卡片需要 10 积分。您可以去分享知识库获取更多奖励！'
      : 'AI deconstruct needs credits. Share a library to earn more!';

  static String understood(BuildContext context) =>
      _zh(context) ? '了解' : 'OK';

  static String goShareReward(BuildContext context) =>
      _zh(context) ? '去分享奖励' : 'Share for credits';

  static String aiStyleTitle(BuildContext context) =>
      _zh(context) ? 'AI 拆解风格' : 'AI deconstruct style';

  static String flashcardQuestion(BuildContext context, String q) =>
      _zh(context) ? '提问: $q' : 'Q: $q';

  static String none(BuildContext context) => _zh(context) ? '无' : '—';
}
