import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_pm/core/locale/locale_provider.dart';
import 'package:quick_pm/core/providers/ai_settings_provider.dart';
import 'package:quick_pm/core/providers/credit_provider.dart';
import 'package:quick_pm/data/services/content_extraction_service.dart';
import 'package:quick_pm/features/feed/presentation/feed_provider.dart';
import 'package:quick_pm/l10n/add_material_strings.dart';

/// 解析 / 预估耗时 / 扣费并提交后台任务（对话页与弹窗共用）
class DeconstructFlowService {
  DeconstructFlowService._();

  /// 与 AddMaterialModal._calculateEstimatedTime 一致
  static String estimatedTimeLabel(BuildContext context, int length) {
    final seconds = 3 + (length / 1000 * 3).round();
    if (seconds < 60) {
      return AddMaterialL10n.estSeconds(context, seconds);
    }
    return AddMaterialL10n.estMinutes(context, seconds / 60);
  }

  static bool isHttpUrl(String s) {
    final t = s.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  /// 文件优先；否则整段文本若为 http(s) 则按 URL 解析；否则纯文本提取
  static Future<ExtractionResult> parseMultimodalInput({
    required String messageText,
    Uint8List? fileBytes,
    String? fileName,
    String outputLocale = 'zh',
  }) async {
    if (fileBytes != null && fileBytes.isNotEmpty) {
      return ContentExtractionService.extractContentFromFile(
        fileBytes,
        filename: fileName ?? 'file',
      );
    }
    final t = messageText.trim();
    if (t.isEmpty) {
      throw StateError('empty_input');
    }
    if (isHttpUrl(t)) {
      return ContentExtractionService.extractFromUrl(t);
    }
    return Future.value(
      ContentExtractionService.extractFromText(
        t,
        outputLocale: outputLocale,
      ),
    );
  }

  static int creditsFor(ExtractionResult r) {
    return ContentExtractionService.calculateRequiredCredits(r.content.length);
  }

  /// 已在外层完成知识库与确认弹窗时调用：扣积分并提交、订阅任务
  static Future<DeconstructSubmitResult> submitDeconstructJob(
    WidgetRef ref, {
    required String content,
    required String moduleId,
  }) async {
    final credits =
        ContentExtractionService.calculateRequiredCredits(content.length);
    final canUse =
        await ref.read(creditProvider.notifier).useAI(amount: credits);
    if (!canUse) {
      return DeconstructSubmitResult.insufficientCredits();
    }
    final jobId = await ContentExtractionService.submitJobAndForget(
      content,
      moduleId: moduleId,
      mode: ref.read(aiSettingsProvider).mode,
      outputLocale: ref.read(localeProvider).outputLocale,
    );
    ref.read(feedProvider.notifier).observeJob(jobId);
    return DeconstructSubmitResult.success(jobId);
  }
}

class DeconstructSubmitResult {
  final bool success;
  final bool insufficientCredits;
  final String? jobId;

  const DeconstructSubmitResult._({
    required this.success,
    this.insufficientCredits = false,
    this.jobId,
  });

  factory DeconstructSubmitResult.success(String id) {
    return DeconstructSubmitResult._(success: true, jobId: id);
  }

  factory DeconstructSubmitResult.insufficientCredits() {
    return const DeconstructSubmitResult._(
      success: false,
      insufficientCredits: true,
    );
  }
}
