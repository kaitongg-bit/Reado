import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_pm/core/locale/locale_provider.dart';
import 'package:quick_pm/data/services/content_extraction_service.dart';
import 'package:quick_pm/features/home/presentation/module_provider.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_ai_mode_selector.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_flow_service.dart';
import 'package:quick_pm/features/lab/deconstruct/deconstruct_module_picker.dart';
import 'package:quick_pm/l10n/deconstruct_chat_strings.dart';
import 'package:quick_pm/l10n/module_display_strings.dart';
import 'package:quick_pm/models/knowledge_module.dart';

/// 对话拆解兜底：表单选库、拆解风格、链接/正文/文件导入（与聊天流衔接）
Future<void> showDeconstructFallbackFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  String? initialModuleId,
  required void Function({
    required ExtractionResult extraction,
    String? moduleId,
  }) onImported,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return _FallbackFormBody(
        initialModuleId: initialModuleId,
        onImported: onImported,
      );
    },
  );
}

class _FallbackFormBody extends ConsumerStatefulWidget {
  const _FallbackFormBody({
    this.initialModuleId,
    required this.onImported,
  });

  final String? initialModuleId;
  final void Function({
    required ExtractionResult extraction,
    String? moduleId,
  }) onImported;

  @override
  ConsumerState<_FallbackFormBody> createState() => _FallbackFormBodyState();
}

class _FallbackFormBodyState extends ConsumerState<_FallbackFormBody> {
  late String? _moduleId;
  final _textCtrl = TextEditingController();
  Uint8List? _fileBytes;
  String? _fileName;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _moduleId = widget.initialModuleId;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  String _moduleLabel() {
    final id = _moduleId;
    if (id == null || id.isEmpty) {
      return DeconstructChatStrings.fallbackPickLibraryHint(context);
    }
    final all = [
      ...ref.read(moduleProvider).custom,
      ...ref.read(moduleProvider).officials,
    ];
    KnowledgeModule? m;
    try {
      m = all.firstWhere((x) => x.id == id);
    } catch (_) {
      return id;
    }
    final loc = ref.read(localeProvider).outputLocale;
    return ModuleDisplayStrings.moduleTitle(m, loc);
  }

  Future<void> _pickLibrary() async {
    final id = await DeconstructModulePicker.ensureTargetModuleId(
      context: context,
      ref: ref,
      selectedModuleId: _moduleId,
      targetModuleId: null,
      isTutorialMode: false,
      alwaysShowPicker: true,
    );
    if (id != null && mounted) setState(() => _moduleId = id);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'md', 'markdown', 'docx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(DeconstructChatStrings.fileTooBig(context))),
        );
      }
      return;
    }
    setState(() {
      _fileBytes = f.bytes;
      _fileName = f.name;
    });
  }

  Future<void> _apply() async {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty && (_fileBytes == null || _fileBytes!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DeconstructChatStrings.fallbackNeedContent(context))),
      );
      return;
    }

    setState(() => _working = true);
    try {
      final locale = ref.read(localeProvider).outputLocale;
      final ExtractionResult extraction;
      if (_fileBytes != null && _fileBytes!.isNotEmpty) {
        extraction = await ContentExtractionService.extractContentFromFile(
          _fileBytes!,
          filename: _fileName ?? 'file',
        );
      } else if (DeconstructFlowService.isHttpUrl(raw)) {
        extraction = await ContentExtractionService.extractFromUrl(raw);
      } else {
        extraction = ContentExtractionService.extractFromText(
          raw,
          outputLocale: locale,
        );
      }
      if (!mounted) return;
      widget.onImported(extraction: extraction, moduleId: _moduleId);
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              DeconstructChatStrings.errorGeneric(context, e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              DeconstructChatStrings.fallbackFormTitle(context),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DeconstructChatStrings.fallbackFormSubtitle(context),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickLibrary,
              icon: const Icon(Icons.folder_outlined),
              label: Text(
                '${DeconstructChatStrings.fallbackTargetLibrary(context)}：${_moduleLabel()}',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              DeconstructChatStrings.fallbackDeconstructStyle(context),
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            const DeconstructAiModeSelector(
              hideHeading: false,
              useWrapLayout: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textCtrl,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: DeconstructChatStrings.fallbackPasteOrUrl(context),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _working ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _fileName ?? DeconstructChatStrings.fallbackPickFile(context),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _working ? null : _apply,
              child: _working
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(DeconstructChatStrings.fallbackImportToChat(context)),
            ),
          ],
        ),
      ),
    );
  }
}
