import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_pm/core/providers/ai_settings_provider.dart';
import 'package:quick_pm/l10n/add_material_strings.dart';
import 'package:quick_pm/l10n/app_localizations.dart';

/// AI 拆解风格选择（与 AddMaterialModal 内联逻辑一致，供确认弹窗复用）
class DeconstructAiModeSelector extends ConsumerWidget {
  const DeconstructAiModeSelector({
    super.key,
    this.hideHeading = false,
    /// 对话顶栏等窄区域：用 Wrap，避免 Row+Expanded 无界宽报错
    this.useWrapLayout = false,
  });

  final bool hideHeading;
  final bool useWrapLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final aiSettings = ref.watch(aiSettingsProvider);
    const accentColor = Color(0xFFee8f4b);
    final l10n = AppLocalizations.of(context)!;

    final specs = <(AiDeconstructionMode, String, String)>[
      (AiDeconstructionMode.standard, l10n.addMaterialModeStandard,
          l10n.addMaterialModeStandardDesc),
      (AiDeconstructionMode.grandma, l10n.addMaterialModeGrandma,
          l10n.addMaterialModeGrandmaDesc),
      (AiDeconstructionMode.phd, l10n.addMaterialModePhd,
          l10n.addMaterialModePhdDesc),
      (AiDeconstructionMode.podcast, l10n.addMaterialModePodcast,
          l10n.addMaterialModePodcastDesc),
    ];

    Widget oneChip(AiDeconstructionMode mode, String label, String sub) {
      final isSelected = aiSettings.mode == mode;
      final box = GestureDetector(
        onTap: () => ref.read(aiSettingsProvider.notifier).setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.1)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: useWrapLayout ? 12 : 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? accentColor
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              if (!useWrapLayout) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.grey : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      if (useWrapLayout) {
        return SizedBox(width: 76, child: box);
      }
      return Expanded(child: box);
    }

    final modeWidgets = <Widget>[];
    for (var i = 0; i < specs.length; i++) {
      final s = specs[i];
      if (i > 0 && !useWrapLayout) {
        modeWidgets.add(const SizedBox(width: 8));
      }
      modeWidgets.add(oneChip(s.$1, s.$2, s.$3));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hideHeading)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              AddMaterialL10n.aiStyleTitle(context),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
        if (useWrapLayout)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in specs) oneChip(s.$1, s.$2, s.$3),
            ],
          )
        else
          Row(children: modeWidgets),
      ],
    );
  }
}
