import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_pm/core/locale/locale_provider.dart';
import 'package:quick_pm/core/providers/ai_settings_provider.dart';
import 'package:quick_pm/data/services/content_extraction_service.dart';
import 'package:quick_pm/features/feed/presentation/feed_provider.dart';
import 'package:quick_pm/features/home/presentation/module_provider.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_chat_orchestrator.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_fallback_form_sheet.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_chat_route_args.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_flow_service.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_module_picker.dart';
import 'package:quick_pm/features/onboarding/providers/onboarding_provider.dart';
import 'package:quick_pm/l10n/add_material_strings.dart';
import 'package:quick_pm/l10n/deconstruct_chat_strings.dart';
import 'package:quick_pm/l10n/module_display_strings.dart';
import 'package:quick_pm/models/knowledge_module.dart';

enum _ChatRole { user, assistant }

class _ChatMessage {
  final _ChatRole role;
  final String text;
  final DateTime at;
  /// 为 false 时不写入 Firestore（如「正在解析…」「正在想…」）
  final bool persist;

  _ChatMessage({
    required this.role,
    required this.text,
    DateTime? at,
    this.persist = true,
  }) : at = at ?? DateTime.now();
}

/// 对话式 AI 拆解：以模型对话为主，自然语言选库/风格/确认；解析与扣费在本地完成。
class DeconstructChatPage extends ConsumerStatefulWidget {
  final String? targetModuleId;
  final bool isTutorialMode;
  final String? tutorialStep;

  const DeconstructChatPage({
    super.key,
    this.targetModuleId,
    this.isTutorialMode = false,
    this.tutorialStep,
  });

  factory DeconstructChatPage.fromArgs(DeconstructChatRouteArgs? args) {
    return DeconstructChatPage(
      targetModuleId: args?.targetModuleId,
      isTutorialMode: args?.isTutorialMode ?? false,
      tutorialStep: args?.tutorialStep,
    );
  }

  @override
  ConsumerState<DeconstructChatPage> createState() =>
      _DeconstructChatPageState();
}

class _DeconstructChatPageState extends ConsumerState<DeconstructChatPage> {
  /// 与学习页卡片/AI 对话一致：宽屏居中、窄屏至少左右留白
  static const double _kReadableContentMaxWidth = 720;
  static const double _kMinHorizontalPadding = 24;

  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<_ChatMessage> _messages = [];

  bool _loadingHistory = true;
  Timer? _persistTimer;

  ExtractionResult? _pendingExtraction;
  bool _busy = false;
  bool _submitting = false;
  bool _submittedSuccessfully = false;

  Uint8List? _pickedBytes;
  String? _pickedName;
  final FocusNode _composerFocus = FocusNode();

  String? _resolvedModuleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await _loadChatHistory();
    if (!mounted) return;
    _syncDefaultModuleFromProvider();
    if (widget.tutorialStep == 'multimodal') {
      _composer.text = 'https://zh.wikipedia.org/wiki/Flutter';
    }
    if (_messages.isNotEmpty) _scrollToBottom();
  }

  Future<void> _loadChatHistory() async {
    final welcome = _ChatMessage(
      role: _ChatRole.assistant,
      text: DeconstructChatStrings.welcome(context),
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
          _messages = [welcome];
        });
      }
      return;
    }
    try {
      final raw =
          await ref.read(dataServiceProvider).fetchDeconstructChatHistory(user.uid);
      if (!mounted) return;
      if (raw.isEmpty) {
        setState(() {
          _loadingHistory = false;
          _messages = [welcome];
        });
        return;
      }
      final loaded = <_ChatMessage>[];
      for (final row in raw) {
        final roleStr = row['role'] as String?;
        final role =
            roleStr == 'user' ? _ChatRole.user : _ChatRole.assistant;
        final text = row['text'] as String? ?? '';
        if (text.trim().isEmpty) continue;
        final atStr = row['at'] as String?;
        final at = DateTime.tryParse(atStr ?? '') ?? DateTime.now();
        loaded.add(_ChatMessage(role: role, text: text, at: at));
      }
      loaded.sort((a, b) => a.at.compareTo(b.at));
      setState(() {
        _loadingHistory = false;
        _messages = loaded.isEmpty ? [welcome] : loaded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _messages = [welcome];
      });
    }
  }

  void _schedulePersistChat() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_flushPersistChat(user.uid));
    });
  }

  Future<void> _flushPersistChat(String uid) async {
    final list = _messages
        .where((m) => m.persist)
        .map((m) => {
              'role': m.role == _ChatRole.user ? 'user' : 'assistant',
              'text': m.text,
              'at': m.at.toIso8601String(),
            })
        .toList();
    try {
      await ref.read(dataServiceProvider).saveDeconstructChatHistory(uid, list);
    } catch (_) {}
  }

  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: Text(DeconstructChatStrings.clearHistoryDialogTitle(dialogCtx)),
            content: Text(DeconstructChatStrings.clearHistoryDialogBody(dialogCtx)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(DeconstructChatStrings.clearHistoryCancel(dialogCtx)),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(DeconstructChatStrings.clearHistoryConfirm(dialogCtx)),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || !mounted) return;

    _persistTimer?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    final welcome = _ChatMessage(
      role: _ChatRole.assistant,
      text: DeconstructChatStrings.welcome(context),
    );
    setState(() {
      _pendingExtraction = null;
      _submittedSuccessfully = false;
      _busy = false;
      _messages = [welcome];
    });
    if (user != null) {
      try {
        await ref.read(dataServiceProvider).clearDeconstructChatHistory(user.uid);
      } catch (_) {}
    }
    _scrollToBottom();
  }

  void _syncDefaultModuleFromProvider() {
    final mid = widget.targetModuleId;
    if (mid != null && mid.isNotEmpty) {
      _resolvedModuleId = mid;
      return;
    }
    if (widget.isTutorialMode) {
      final custom = ref.read(moduleProvider).custom;
      if (custom.isNotEmpty) {
        _resolvedModuleId = custom.first.id;
        return;
      }
    }
    final moduleState = ref.read(moduleProvider);
    final all = [...moduleState.custom, ...moduleState.officials];
    if (all.isEmpty) return;
    try {
      final def = all.firstWhere(
        (m) => ModuleDisplayStrings.isDefaultModuleTitle(m.title),
        orElse: () => all.first,
      );
      _resolvedModuleId = def.id;
    } catch (_) {
      _resolvedModuleId = all.first.id;
    }
  }

  Set<String> _validModuleIds() {
    final moduleState = ref.read(moduleProvider);
    final all = [...moduleState.custom, ...moduleState.officials];
    return all.map((m) => m.id).toSet();
  }

  String _modulesJsonForPrompt() {
    final moduleState = ref.read(moduleProvider);
    final all = [...moduleState.custom, ...moduleState.officials];
    final loc = ref.read(localeProvider).outputLocale;
    final list = all
        .map((m) => {
              'id': m.id,
              'title': ModuleDisplayStrings.moduleTitle(m, loc),
              'official': m.isOfficial,
            })
        .toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  String _libraryTitleForId(String? id) {
    if (id == null || id.isEmpty) {
      return DeconstructChatStrings.libraryNotResolved(context);
    }
    final moduleState = ref.read(moduleProvider);
    final all = [...moduleState.custom, ...moduleState.officials];
    KnowledgeModule? found;
    try {
      found = all.firstWhere((m) => m.id == id);
    } catch (_) {
      return id;
    }
    final loc = ref.read(localeProvider).outputLocale;
    return ModuleDisplayStrings.moduleTitle(found, loc);
  }

  String _conversationTranscript() {
    final thinking = DeconstructChatStrings.aiThinking(context);
    var end = _messages.length;
    if (end > 0 &&
        _messages.last.role == _ChatRole.assistant &&
        _messages.last.text == thinking) {
      end -= 1;
    }
    final buf = StringBuffer();
    for (var i = 0; i < end; i++) {
      final m = _messages[i];
      if (!m.persist) continue;
      if (m.text.trim().isEmpty) continue;
      buf.writeln(
        m.role == _ChatRole.user ? '用户: ${m.text}' : '助手: ${m.text}',
      );
    }
    return buf.toString();
  }

  String _modeDisplayName() {
    final mode = ref.read(aiSettingsProvider).mode;
    return DeconstructChatStrings.aiModeShortLabel(context, mode);
  }

  String? _pendingSummaryLine() {
    final r = _pendingExtraction;
    if (r == null) return null;
    final credits = DeconstructFlowService.creditsFor(r);
    return 'title=${r.title}; chars=${r.content.length}; credits≈$credits; type=${r.sourceType.name}';
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    _composer.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _addUser(String text) {
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text));
    });
    _scrollToBottom();
    _schedulePersistChat();
  }

  void _addAssistant(String text, {bool persist = true}) {
    setState(() {
      _messages.add(
        _ChatMessage(
          role: _ChatRole.assistant,
          text: text,
          persist: persist,
        ),
      );
    });
    _scrollToBottom();
    if (persist) _schedulePersistChat();
  }

  void _removeLastAssistantIfThinking() {
    final t = DeconstructChatStrings.aiThinking(context);
    if (_messages.isNotEmpty &&
        _messages.last.role == _ChatRole.assistant &&
        _messages.last.text == t) {
      setState(() => _messages.removeLast());
    }
  }

  /// 短句控制语：不要当成「待拆解正文」去 parse（交给编排模型理解）
  bool _isShortControlPhrase(String text) {
    final s = text.trim();
    if (s.length > 36) return false;
    return RegExp(
      r'^(确认|好|可以|开始|行|嗯|OK|ok|yes|go|换一条|取消|不拆了|不用了|算了|不要了)',
      caseSensitive: false,
    ).hasMatch(s);
  }

  /// 用户说「拆我这个问题 / 上面那句」等：把**上一条**较长的用户话当作正文。返回是否刚恢复了 pending。
  bool _maybeRecoverPendingFromPreviousUserMessage(String latestUserText) {
    if (_pendingExtraction != null) return false;
    final t = latestUserText.trim();
    if (t.length > 72) return false;
    if (!RegExp(
      r'(拆.*(这个|我|上面|那句|那段)|就.*拆|上面.*(说|发|那段)|刚才.*(说|发)|之前.*发|这句|这段)',
    ).hasMatch(t)) {
      return false;
    }
    for (var i = _messages.length - 2; i >= 0; i--) {
      if (_messages[i].role != _ChatRole.user) continue;
      var block = _messages[i].text.trim();
      if (block.length < 12) continue;
      if (_isShortControlPhrase(block)) continue;
      // 仅「[附件] 文件名」一行、无正文时跳过
      if (block.startsWith('[') &&
          !block.contains('\n') &&
          block.length < 120) {
        continue;
      }
      final locale = ref.read(localeProvider).outputLocale;
      setState(() {
        _pendingExtraction = ContentExtractionService.extractFromText(
          block,
          outputLocale: locale,
        );
      });
      return true;
    }
    return false;
  }

  bool _shouldParseMaterial(String text, bool hasFile) {
    if (hasFile) return true;
    final t = text.trim();
    if (t.isEmpty) return false;
    if (_isShortControlPhrase(t)) return false;
    if (DeconstructFlowService.isHttpUrl(t)) return true;
    if (t.length > 550) return true;
    final lines = t.split(RegExp(r'\r?\n'));
    if (lines.length >= 6 && t.length > 140) return true;
    // 用户把「问题/想了解的事」直接打在输入框里，也应视为可拆解材料（不必非要链接/文件）
    if (t.length >= 28) return true;
    if (t.length >= 16 &&
        RegExp(r'[?？]|什么|怎么|为什么|有没有|区别|介绍|了解|讲讲|说说')
            .hasMatch(t)) {
      return true;
    }
    return false;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'md', 'markdown', 'docx', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        if (mounted) _addAssistant(DeconstructChatStrings.fileTooBig(context));
        return;
      }
      setState(() {
        _pickedBytes = file.bytes;
        _pickedName = file.name;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_pickedName ?? '')),
        );
      }
    } catch (e) {
      if (mounted) {
        _addAssistant(DeconstructChatStrings.errorGeneric(context, e.toString()));
      }
    }
  }

  Future<void> _showInsufficientCredits() async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Center(
          child: Icon(Icons.stars, color: Color(0xFFFFB300), size: 48),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AddMaterialL10n.insufficientCreditsTitle(dialogCtx),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              AddMaterialL10n.insufficientCreditsBody(dialogCtx),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(AddMaterialL10n.understood(dialogCtx)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              dialogCtx.push('/task-center');
            },
            child: Text(AddMaterialL10n.goShareReward(dialogCtx)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSubmit() async {
    if (_pendingExtraction == null || _submitting) return;

    var moduleId = _resolvedModuleId;
    final valid = _validModuleIds();
    if (moduleId == null || !valid.contains(moduleId)) {
      moduleId = await DeconstructModulePicker.ensureTargetModuleId(
        context: context,
        ref: ref,
        selectedModuleId: _resolvedModuleId,
        targetModuleId: widget.targetModuleId,
        isTutorialMode: widget.isTutorialMode,
      );
      if (!mounted) return;
      if (moduleId != null) {
        setState(() => _resolvedModuleId = moduleId);
      }
    }
    if (moduleId == null || !valid.contains(moduleId)) {
      _addAssistant(DeconstructChatStrings.assistantFallback(context));
      return;
    }

    setState(() => _submitting = true);
    final outcome = await DeconstructFlowService.submitDeconstructJob(
      ref,
      content: _pendingExtraction!.content,
      moduleId: moduleId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (outcome.insufficientCredits) {
      await _showInsufficientCredits();
      return;
    }
    if (!outcome.success) return;

    if (widget.tutorialStep != null) {
      ref.read(onboardingProvider.notifier).completeStep(
            widget.tutorialStep == 'multimodal' ? 'multimodal' : 'text',
          );
    } else if (widget.targetModuleId == null) {
      ref.read(onboardingProvider.notifier).setHighlightTaskCenter(true);
    }

    setState(() {
      _pendingExtraction = null;
      _submittedSuccessfully = true;
    });
    _addAssistant(DeconstructChatStrings.submitted(context));
  }

  Future<void> _onSend() async {
    final text = _composer.text;
    final hasFile = _pickedBytes != null && _pickedBytes!.isNotEmpty;

    if (text.trim().isEmpty && !hasFile) {
      _addAssistant(DeconstructChatStrings.emptyInput(context));
      return;
    }

    final fileBytes = _pickedBytes;
    final fileName = _pickedName;

    final userLine = StringBuffer();
    if (hasFile) {
      userLine.write('[${DeconstructChatStrings.chipUploadFile(context)}] ');
      userLine.write(fileName ?? 'file');
    }
    if (text.trim().isNotEmpty) {
      if (userLine.isNotEmpty) userLine.write('\n');
      userLine.write(text.trim());
    }
    _addUser(userLine.toString());
    _composer.clear();
    setState(() {
      _pickedBytes = null;
      _pickedName = null;
      _submittedSuccessfully = false;
      _busy = true;
    });

    var justParsed = false;
    final outputLocale = ref.read(localeProvider).outputLocale;

    if (_maybeRecoverPendingFromPreviousUserMessage(text)) {
      justParsed = true;
    }

    if (_shouldParseMaterial(text, hasFile)) {
      _addAssistant(DeconstructChatStrings.parsing(context), persist: false);
      try {
        final result = await DeconstructFlowService.parseMultimodalInput(
          messageText: text,
          fileBytes: fileBytes,
          fileName: fileName,
          outputLocale: outputLocale,
        );
        if (!mounted) return;
        setState(() {
          _pendingExtraction = result;
          justParsed = true;
        });
        if (_resolvedModuleId == null) _syncDefaultModuleFromProvider();
      } catch (e) {
        if (!mounted) return;
        setState(() => _busy = false);
        _removeLastAssistantIfThinking();
        _removeParsingBubble();
        _addAssistant(DeconstructChatStrings.errorGeneric(context, e.toString()));
        return;
      }
      _removeParsingBubble();
    }

    _addAssistant(DeconstructChatStrings.aiThinking(context));

    final est = _pendingExtraction != null
        ? DeconstructFlowService.estimatedTimeLabel(
            context,
            _pendingExtraction!.content.length,
          )
        : '';
    final credits = _pendingExtraction != null
        ? DeconstructFlowService.creditsFor(_pendingExtraction!)
        : 0;
    final src = _pendingExtraction != null
        ? DeconstructChatStrings.sourceTypeLabel(
            context,
            _pendingExtraction!.sourceType,
          )
        : '';

    final parseFactLine = _pendingExtraction == null
        ? '（本回合未解析新材料）'
        : '标题: ${_pendingExtraction!.title}; 字数: ${_pendingExtraction!.content.length}; '
            '来源类型: $src; 约 $credits 积分; 预计耗时: $est; '
            '当前默认知识库 id: ${_resolvedModuleId ?? "未设置"}; '
            '展示名: ${_libraryTitleForId(_resolvedModuleId)}; '
            '当前拆解风格: ${_modeDisplayName()}';

    final orch = await DeconstructChatOrchestrator.run(
      outputLocale: outputLocale,
      conversationTranscript: _conversationTranscript(),
      modulesJson: _modulesJsonForPrompt(),
      currentModeName: ref.read(aiSettingsProvider).mode.name,
      pendingSummary: _pendingSummaryLine(),
      justParsedThisTurn: justParsed,
      parseFactLine: parseFactLine,
    );

    if (!mounted) return;
    _removeLastAssistantIfThinking();
    setState(() => _busy = false);

    if (orch == null) {
      _addAssistant(DeconstructChatStrings.orchestratorOffline(context));
      return;
    }

    if (orch.clearPending) {
      setState(() => _pendingExtraction = null);
    }

    if (orch.setMode != null) {
      await ref.read(aiSettingsProvider.notifier).setMode(orch.setMode!);
    }

    if (!mounted) return;

    if (orch.setModuleId != null &&
        _validModuleIds().contains(orch.setModuleId)) {
      setState(() => _resolvedModuleId = orch.setModuleId);
    }

    var reply = orch.assistantMessage.trim();
    if (reply.isEmpty) {
      reply = DeconstructChatStrings.assistantFallback(context);
    }

    if (_pendingExtraction != null && justParsed) {
      reply +=
          '\n\n${DeconstructChatStrings.creditsFooter(context, credits, est)}';
    }

    _addAssistant(reply);

    if (orch.suggestFallbackForm && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(DeconstructChatStrings.snackSuggestForm(context)),
          action: SnackBarAction(
            label: DeconstructChatStrings.openFormAction(context),
            onPressed: _openFallbackFormSheet,
          ),
        ),
      );
    }

    final maySubmit = orch.requestSubmit &&
        _pendingExtraction != null &&
        !justParsed &&
        !orch.clearPending;
    if (maySubmit) {
      await _executeSubmit();
    }
  }

  Future<void> _openFallbackFormSheet() async {
    await showDeconstructFallbackFormSheet(
      context: context,
      ref: ref,
      initialModuleId: _resolvedModuleId,
      onImported: ({required extraction, moduleId}) {
        if (!mounted) return;
        setState(() {
          _pendingExtraction = extraction;
          if (moduleId != null && _validModuleIds().contains(moduleId)) {
            _resolvedModuleId = moduleId;
          }
        });
        final credits = DeconstructFlowService.creditsFor(extraction);
        final est = DeconstructFlowService.estimatedTimeLabel(
          context,
          extraction.content.length,
        );
        _addAssistant(
          '${DeconstructChatStrings.fallbackImportSuccessChat(context)}\n\n'
          '${DeconstructChatStrings.creditsFooter(context, credits, est)}',
        );
      },
    );
  }

  Widget _messageBody(_ChatMessage m, ThemeData theme) {
    if (m.role == _ChatRole.user) {
      return SelectableText(
        m.text,
        style: theme.textTheme.bodyMedium,
      );
    }
    return MarkdownBody(
      data: m.text,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        strong: TextStyle(
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  double _readableSidePadding(double viewportWidth) {
    if (viewportWidth <= _kReadableContentMaxWidth + _kMinHorizontalPadding * 2) {
      return _kMinHorizontalPadding;
    }
    return (viewportWidth - _kReadableContentMaxWidth) / 2;
  }

  void _removeParsingBubble() {
    final p = DeconstructChatStrings.parsing(context);
    if (_messages.isNotEmpty &&
        _messages.last.role == _ChatRole.assistant &&
        _messages.last.text == p) {
      setState(() => _messages.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(moduleProvider);
    ref.watch(aiSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(DeconstructChatStrings.pageTitle(context)),
        actions: [
          PopupMenuButton<String>(
            enabled: !_busy,
            onSelected: (v) {
              if (v == 'clear') unawaited(_confirmClearHistory());
            },
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'clear',
                child: Text(DeconstructChatStrings.menuClearHistory(ctx)),
              ),
            ],
          ),
          IconButton(
            tooltip: DeconstructChatStrings.appBarFallbackTooltip(context),
            onPressed: _busy ? null : _openFallbackFormSheet,
            icon: const Icon(Icons.article_outlined),
          ),
          TextButton.icon(
            onPressed: _busy ? null : () => context.push('/task-center'),
            icon: const Icon(Icons.task_alt, size: 20),
            label: Text(DeconstructChatStrings.openTaskCenter(context)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_loadingHistory) {
            return const Center(child: CircularProgressIndicator());
          }
          final side = _readableSidePadding(constraints.maxWidth);
          final contentW = (constraints.maxWidth - 2 * side).clamp(0.0, double.infinity);
          final bubbleMaxW = contentW * 0.88;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(side, 16, side, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final isUser = m.role == _ChatRole.user;
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(maxWidth: bubbleMaxW),
                        decoration: BoxDecoration(
                          color: isUser
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _messageBody(m, theme),
                      ),
                    );
                  },
                ),
              ),
              if (_submittedSuccessfully)
                Padding(
                  padding: EdgeInsets.fromLTRB(side, 0, side, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/task-center'),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: Text(
                        DeconstructChatStrings.openTaskCenter(context),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(side, 0, side, 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      label: Text(
                        DeconstructChatStrings.chipPasteArticle(context),
                      ),
                      onPressed: _busy
                          ? null
                          : () {
                              _composer.clear();
                              _composer.selection =
                                  const TextSelection.collapsed(offset: 0);
                              _composerFocus.requestFocus();
                            },
                    ),
                    ActionChip(
                      label: Text(
                        DeconstructChatStrings.chipUploadFile(context),
                      ),
                      onPressed: _busy ? null : _pickFile,
                    ),
                    ActionChip(
                      label: Text(
                        DeconstructChatStrings.chipPasteLink(context),
                      ),
                      onPressed: _busy
                          ? null
                          : () {
                              _composer.text = 'https://';
                              _composer.selection = TextSelection.collapsed(
                                offset: _composer.text.length,
                              );
                              _composerFocus.requestFocus();
                            },
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(side, 4, side, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: _busy ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _composer,
                          focusNode: _composerFocus,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText:
                                DeconstructChatStrings.hintComposer(context),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _busy ? null : _onSend(),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: _busy ? null : _onSend,
                        icon: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
