import 'package:flutter/widgets.dart';

bool _zh(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code == 'zh' || code.startsWith('zh_');
}

/// AI 助手底部弹窗、ADHD 首次说明等：按界面语言切换中英文。
abstract final class PopupAssistantL10n {
  static List<String> aiPresetQuestions(BuildContext context) {
    return _zh(context)
        ? const [
            '举个例子讲解一下',
            '用简单的话总结一下',
            '这段在说什么？',
            '有什么重点？',
            '能再解释得通俗一点吗？',
          ]
        : const [
            'Explain with an example',
            'Summarize in simple terms',
            'What is this section about?',
            'What are the key points?',
            'Can you explain more simply?',
          ];
  }

  static List<String> aiLoadingPlaceholders(BuildContext context) {
    return _zh(context)
        ? const ['正在思考中...', '马上生成好...', '快好了...']
        : const ['Thinking...', 'Almost there...', 'Just a moment...'];
  }

  static String aiWelcomeLine(BuildContext context) =>
      _zh(context) ? '关于卡片内容，尽管问我' : 'Ask me anything about this card';

  static String aiTryThese(BuildContext context) =>
      _zh(context) ? '试试这些常见问题：' : 'Try asking:';

  static String aiSelectToSave(BuildContext context) =>
      _zh(context) ? '选择要保存的对话' : 'Select messages to save';

  static String aiSelectedCount(BuildContext context, int n) =>
      _zh(context) ? '已选 $n 条' : '$n selected';

  static String aiPinHint(BuildContext context) =>
      _zh(context) ? '点击 Pin 多选对话再保存' : 'Tap Pin to select messages to save';

  static String aiPinTooltip(BuildContext context) =>
      _zh(context) ? '多选对话并保存' : 'Select messages to save';

  static String aiSelectAll(BuildContext context) =>
      _zh(context) ? '全选' : 'Select all';

  static String aiSaveAsIs(BuildContext context) =>
      _zh(context) ? '原味保存' : 'Save as-is';

  static String aiSummarizeSave(BuildContext context) =>
      _zh(context) ? 'AI 整理并存' : 'Summarize & save';

  static String aiSummarizing(BuildContext context) =>
      _zh(context) ? '整理中...' : 'Summarizing...';

  static String aiSummarizeFailed(BuildContext context, Object e) =>
      _zh(context) ? 'AI 整理失败: $e' : 'Summarize failed: $e';

  static String aiChatLogTitle(BuildContext context) =>
      _zh(context) ? '对话记录' : 'Chat log';

  static String aiChatUserLabel(BuildContext context) =>
      _zh(context) ? '我' : 'Me';

  static String aiChatAssistantLabel(BuildContext context) =>
      _zh(context) ? '囤囤鼠' : 'Assistant';

  // ADHD 首次弹窗
  static String adhdDialogTitle(BuildContext context) =>
      _zh(context) ? '已启用沉浸阅读模式' : 'Immersive reading is on';

  static String adhdDialogBody(BuildContext context) => _zh(context)
      ? '为了帮助提升阅读专注力，我们默认开启了 ADHD 辅助变色模式。\n\n如需关闭或调整，请点击页面右上角的设置。'
      : 'To help you focus while reading, we turned on ADHD-friendly color highlighting by default.\n\nTurn it off or adjust it anytime from the settings icon at the top right.';

  static String adhdGotIt(BuildContext context) =>
      _zh(context) ? '知道了' : 'Got it';

  static String adhdTurnOff(BuildContext context) =>
      _zh(context) ? '关闭' : 'Turn off';

  static String adhdAssistOffSnackbar(BuildContext context) =>
      _zh(context) ? '已关闭辅助模式' : 'Reading assist turned off';

  // Study 空状态「添加内容」
  static String studyAddContent(BuildContext context) =>
      _zh(context) ? '添加内容' : 'Add content';

  static String sharedLibraryNoCards(BuildContext context) =>
      _zh(context) ? '暂无卡片' : 'No cards yet';
}
