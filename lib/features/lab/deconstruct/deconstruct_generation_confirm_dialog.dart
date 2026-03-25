import 'package:flutter/material.dart';
import 'package:quick_pm/l10n/add_material_strings.dart';
import 'package:quick_pm/l10n/app_localizations.dart';
import 'deconstruct_ai_mode_selector.dart';

/// 单次 AI 拆解前的积分与风格确认（与 AddMaterialModal 行为对齐）
Future<bool?> showDeconstructGenerationConfirmDialog(
  BuildContext context, {
  required int credits,
  required String estTime,
  required int charCount,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      final l10n = AppLocalizations.of(dialogCtx)!;
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFee8f4b)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AddMaterialL10n.singleDeconstructTitle(dialogCtx)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AddMaterialL10n.recognizedChars(dialogCtx, charCount)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${AddMaterialL10n.estTimePrefix(dialogCtx)}$estTime',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFee8f4b).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFee8f4b).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Color(0xFFee8f4b), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    AddMaterialL10n.deductThisTime(dialogCtx),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$credits',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFee8f4b),
                    ),
                  ),
                  Text(AddMaterialL10n.creditsUnit(dialogCtx)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AddMaterialL10n.tipParseFree(dialogCtx),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24),
            const DeconstructAiModeSelector(),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.volunteer_activism_outlined,
                    size: 14, color: Colors.green[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AddMaterialL10n.readoPerk(dialogCtx),
                    style: TextStyle(fontSize: 11, color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFee8f4b),
            ),
            child: Text(AddMaterialL10n.startGenerate(dialogCtx)),
          ),
        ],
      );
    },
  );
}
