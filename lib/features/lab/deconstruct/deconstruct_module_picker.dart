import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_pm/l10n/app_localizations.dart';
import 'package:quick_pm/l10n/module_display_strings.dart';
import 'package:quick_pm/models/knowledge_module.dart';
import 'package:quick_pm/core/locale/locale_provider.dart';
import 'package:quick_pm/features/home/presentation/module_provider.dart';

/// 与 [AddMaterialModal] 中知识库选择逻辑一致：默认库优先、教程固定首库、否则弹窗选择。
class DeconstructModulePicker {
  DeconstructModulePicker._();

  static Future<String?> ensureTargetModuleId({
    required BuildContext context,
    required WidgetRef ref,
    String? selectedModuleId,
    String? targetModuleId,
    bool isTutorialMode = false,
    /// 为 true 时始终弹出选择框（如「更换知识库」）；[selectedModuleId]/[targetModuleId] 用作初始选中。
    bool alwaysShowPicker = false,
  }) async {
    try {
      if (!alwaysShowPicker) {
        if (selectedModuleId != null && selectedModuleId.isNotEmpty) {
          return selectedModuleId;
        }

        if (isTutorialMode) {
          final moduleState = ref.read(moduleProvider);
          if (moduleState.custom.isNotEmpty) {
            return moduleState.custom.first.id;
          }
        }

        if (targetModuleId != null && targetModuleId.isNotEmpty) {
          return targetModuleId;
        }
      }

      final moduleState = ref.read(moduleProvider);
      var allModules = [...moduleState.custom, ...moduleState.officials];

      if (allModules.isEmpty) {
        try {
          allModules = [
            KnowledgeModule(
              id: 'unknown_default',
              title: ref.read(localeProvider).outputLocale == 'en'
                  ? 'default'
                  : '默认知识库',
              description: ref.read(localeProvider).outputLocale == 'en'
                  ? 'Your default library'
                  : '系统默认',
              ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
              isOfficial: false,
              cardCount: 0,
            ),
          ];
        } catch (e) {
          debugPrint('DeconstructModulePicker placeholder: $e');
        }
      }

      if (!context.mounted) return null;

      return showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final preferred = (selectedModuleId != null &&
                  selectedModuleId.isNotEmpty &&
                  allModules.any((m) => m.id == selectedModuleId))
              ? selectedModuleId
              : (targetModuleId != null &&
                      targetModuleId.isNotEmpty &&
                      allModules.any((m) => m.id == targetModuleId))
                  ? targetModuleId
                  : null;

          String? tempSelectedId;
          if (allModules.isNotEmpty) {
            if (preferred != null) {
              tempSelectedId = preferred;
            } else {
              tempSelectedId = allModules.first.id;
              try {
                final defaultMod = allModules.firstWhere(
                  (m) => ModuleDisplayStrings.isDefaultModuleTitle(m.title),
                  orElse: () => allModules.first,
                );
                tempSelectedId = defaultMod.id;
              } catch (_) {}
            }
          }

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(AppLocalizations.of(context)!.addMaterialSelectTarget),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.addMaterialSelectTargetHint,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: allModules.isEmpty
                            ? Center(
                                child: Text(
                                  AppLocalizations.of(context)!.addMaterialNoModule,
                                ),
                              )
                            : ListView.separated(
                                itemCount: allModules.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (ctx, i) {
                                  final module = allModules[i];
                                  final isSelected = module.id == tempSelectedId;
                                  final loc = ref.read(localeProvider).outputLocale;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        tempSelectedId = module.id;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1)
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            module.isOfficial
                                                ? Icons.verified
                                                : Icons.folder,
                                            color: isSelected
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ModuleDisplayStrings.moduleTitle(
                                                      module, loc),
                                                  style: TextStyle(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : null,
                                                  ),
                                                ),
                                                if (module.description.isNotEmpty)
                                                  Text(
                                                    ModuleDisplayStrings
                                                        .moduleDescription(
                                                            module, loc),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(AppLocalizations.of(context)!.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(tempSelectedId),
                    child: Text(AppLocalizations.of(context)!.dialogConfirm),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e, st) {
      debugPrint('DeconstructModulePicker: $e\n$st');
      return null;
    }
  }
}
