import 'package:flutter/widgets.dart';
import 'package:quick_pm/core/providers/ai_settings_provider.dart';
import 'package:quick_pm/data/services/content_extraction_service.dart';
import 'package:quick_pm/l10n/app_localizations.dart';

bool _zh(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return code == 'zh' || code.startsWith('zh_');
}

/// 对话式 AI 拆解文案（中英，与 locale 一致）
abstract final class DeconstructChatStrings {
  static String pageTitle(BuildContext context) =>
      _zh(context) ? 'AI 拆解' : 'AI Deconstruct';

  static String welcome(BuildContext context) => _zh(context)
      ? '嗨，我是 **囤囤鼠**～在 Reado 里专门帮你把资料啃碎、囤成知识卡片的那只 🐹\n\n'
          '你把想问的打成一段话发我就行，也支持链接、长文、PDF。**拆解风格**（标准 / 大白话 / 博士风 / 播客感）和**存进哪个知识库**都可以直接口语改，例如「换成大白话」「存默认库」。\n\n'
          '准备好了回一句 **「确认拆解」** 我就去后台开拆。聊不转时点右上角 **表单** 也行。'
      : 'Hey—I’m **囤囤鼠** 🐹, your Reado buddy for turning stuff into study cards.\n\n'
          'Paste a question or topic as plain text, or send a link/long read/PDF. Say if you want another **deconstruction style** or **target library** in plain words.\n\n'
          'When ready, say **“confirm”** to start the job. Tap **Form** (top right) if chat feels awkward.';

  static String appBarFallbackTooltip(BuildContext context) =>
      _zh(context) ? '表单模式（选库、风格、上传）' : 'Form (library, style, upload)';

  static String fallbackFormTitle(BuildContext context) =>
      _zh(context) ? '囤囤鼠 · 表单模式' : 'Form mode';

  static String fallbackFormSubtitle(BuildContext context) => _zh(context)
      ? '对话不顺手时用这里：选好知识库和拆解风格，再粘贴正文、链接或上传文件，导入回聊天后继续确认拆解。'
      : 'Pick library & style, then paste text/URL or upload a file—imports back into the chat.';

  static String fallbackTargetLibrary(BuildContext context) =>
      _zh(context) ? '目标知识库' : 'Target library';

  static String fallbackPickLibraryHint(BuildContext context) =>
      _zh(context) ? '点选知识库' : 'Tap to choose';

  static String fallbackDeconstructStyle(BuildContext context) =>
      _zh(context) ? '拆解风格' : 'Deconstruction style';

  static String fallbackPasteOrUrl(BuildContext context) => _zh(context)
      ? '粘贴正文或网页链接（可与文件二选一）'
      : 'Paste text or URL (optional if you use a file)';

  static String fallbackPickFile(BuildContext context) =>
      _zh(context) ? '选择文件（PDF / Word / Markdown…）' : 'Pick file (PDF, Word, Markdown…)';

  static String fallbackImportToChat(BuildContext context) =>
      _zh(context) ? '导入到对话' : 'Import to chat';

  static String fallbackNeedContent(BuildContext context) => _zh(context)
      ? '请至少填写一段文字、链接或选择一个文件。'
      : 'Add some text, a URL, or a file.';

  static String fallbackImportSuccessChat(BuildContext context) => _zh(context)
      ? '已从表单读入内容啦～看一下上面的摘要，没问题就对我说 **确认拆解**。'
      : 'Imported from the form—check the summary above, then say **confirm** to start.';

  static String snackSuggestForm(BuildContext context) => _zh(context)
      ? '要不试试表单模式？能直接选库、风格和上传文件。'
      : 'Try the form to pick library, style, and upload.';

  static String openFormAction(BuildContext context) =>
      _zh(context) ? '打开表单' : 'Open form';

  static String chipPasteArticle(BuildContext context) =>
      _zh(context) ? '粘贴文章' : 'Paste article';

  static String chipUploadFile(BuildContext context) =>
      _zh(context) ? '上传文件' : 'Upload file';

  static String chipPasteLink(BuildContext context) =>
      _zh(context) ? '贴链接' : 'Paste link';

  static String hintComposer(BuildContext context) => _zh(context)
      ? '发链接/长文/文件来拆解，或随便问点什么…'
      : 'Send a link, text, or file—or just ask something…';

  static String parsing(BuildContext context) =>
      _zh(context) ? '正在读你的内容…' : 'Reading what you sent…';

  static String aiThinking(BuildContext context) =>
      _zh(context) ? '正在想怎么回你…' : 'Thinking…';

  static String orchestratorOffline(BuildContext context) => _zh(context)
      ? '我这边暂时连不上智能回复，你可以先发链接、长文或文件，本地解析仍可用；或稍后再试。'
      : 'I can’t reach the AI right now—try sending a link or text for local parsing, or try again later.';

  static String assistantFallback(BuildContext context) => _zh(context)
      ? '我没听太懂，能再说一下你想拆什么、存哪个知识库吗？'
      : 'Could you say that again—what should I deconstruct and which library?';

  /// 解析完成后由客户端追加，保证用户看到积分后再口头确认
  static String creditsFooter(
    BuildContext context,
    int credits,
    String estTime,
  ) =>
      _zh(context)
          ? '——\n大约需要 **$credits** 积分，预计 **$estTime** 左右。想好了就回复 **「确认拆解」**；想取消可以说 **换一条** 或 **不拆了**。'
          : '—\nAbout **$credits** credits, roughly **$estTime**. Reply **“confirm”** or **“go ahead”** to start—or say you want to cancel / try something else.';

  static String sourceTypeLabel(BuildContext context, SourceType t) {
    if (_zh(context)) {
      return switch (t) {
        SourceType.text => '纯文本',
        SourceType.url => '网页/链接',
        SourceType.youtube => 'YouTube',
        SourceType.pdf => 'PDF',
      };
    }
    return switch (t) {
      SourceType.text => 'Plain text',
      SourceType.url => 'Web / URL',
      SourceType.youtube => 'YouTube',
      SourceType.pdf => 'PDF',
    };
  }

  static String aiModeShortLabel(BuildContext context, AiDeconstructionMode m) {
    final l10n = AppLocalizations.of(context)!;
    return switch (m) {
      AiDeconstructionMode.standard => l10n.addMaterialModeStandard,
      AiDeconstructionMode.grandma => l10n.addMaterialModeGrandma,
      AiDeconstructionMode.phd => l10n.addMaterialModePhd,
      AiDeconstructionMode.podcast => l10n.addMaterialModePodcast,
    };
  }

  /// 比模板更口语化的解析结果说明
  static String parsedSummaryWarm(
    BuildContext context, {
    required String workingTitle,
    required int charCount,
    required String sourceLabel,
    required String estTime,
    required int credits,
    required String modeName,
    required String libraryName,
  }) =>
      _zh(context)
          ? '好啦，我读完了。\n\n'
              '先叫它「$workingTitle」吧（不满意可以点「换一条」重来）。\n'
              '大约 $charCount 字 · 来源：$sourceLabel\n'
              '拆解风格：$modeName\n'
              '卡片会进：$libraryName\n\n'
              '预计 $estTime 左右，这次大概 $credits 积分。\n'
              '没问题就点下面「确认拆解」～'
          : 'All read.\n\n'
              'Let’s call it “$workingTitle” for now (tap “Start over” if you want to redo).\n'
              '~$charCount chars · Source: $sourceLabel\n'
              'Style: $modeName\n'
              'Cards go to: $libraryName\n\n'
              'Roughly $estTime · about $credits credits this run.\n'
              'Tap “Confirm deconstruct” when you’re ready.';

  static String confirmDeconstructButton(BuildContext context) =>
      _zh(context) ? '确认拆解' : 'Confirm deconstruct';

  static String resetInput(BuildContext context) =>
      _zh(context) ? '换一条' : 'Start over';

  static String afterResetPrompt(BuildContext context) => _zh(context)
      ? '好呀，发新的链接、长文或文件就行，想聊两句也可以～'
      : 'Sure—send a new link, text, or file, or just chat.';

  static String submitted(BuildContext context) => _zh(context)
      ? '收到啦，已经在后台帮你拆啦，去任务中心瞄一眼进度就行～'
      : 'On it—processing in the background. Peek at Task Center for progress.';

  static String openTaskCenter(BuildContext context) =>
      _zh(context) ? '打开任务中心' : 'Open Task Center';

  static String emptyInput(BuildContext context) => _zh(context)
      ? '先输入点什么，或选个文件再发送～'
      : 'Type something or pick a file first.';

  static String fileTooBig(BuildContext context) => _zh(context)
      ? '文件不能超过 10MB。'
      : 'File must be 10MB or smaller.';

  static String errorGeneric(BuildContext context, String detail) =>
      _zh(context) ? '哎呀，出了点问题：$detail' : 'Hmm, something went wrong: $detail';

  static String changeLibraryButton(BuildContext context) =>
      _zh(context) ? '更换知识库' : 'Change library';

  static String styleSectionTitle(BuildContext context) =>
      _zh(context) ? '拆解风格' : 'Deconstruction style';

  static String styleAppliesNote(BuildContext context) => _zh(context)
      ? '点「确认拆解」时会用这里选中的风格。'
      : 'The style selected here is used when you confirm.';

  static String targetLibraryLabel(BuildContext context) =>
      _zh(context) ? '保存到' : 'Save to';

  static String libraryNotResolved(BuildContext context) =>
      _zh(context) ? '（未选择）' : '(not selected)';

  /// 右上角菜单：清空云端/本地对话记录
  static String menuClearHistory(BuildContext context) =>
      _zh(context) ? '清空聊天记录' : 'Clear chat history';

  static String clearHistoryDialogTitle(BuildContext context) =>
      _zh(context) ? '清空聊天记录？' : 'Clear chat history?';

  static String clearHistoryDialogBody(BuildContext context) => _zh(context)
      ? '将删除本页已保存的对话（登录用户会同步从云端移除）。此操作不可恢复。'
      : 'This removes saved messages on this page (and from the cloud if you’re signed in). This can’t be undone.';

  static String clearHistoryConfirm(BuildContext context) =>
      _zh(context) ? '清空' : 'Clear';

  static String clearHistoryCancel(BuildContext context) =>
      _zh(context) ? '取消' : 'Cancel';
}
