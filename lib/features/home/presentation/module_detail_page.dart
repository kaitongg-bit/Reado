import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quick_pm/l10n/app_localizations.dart';
import 'package:quick_pm/l10n/l10n_numeric_strings.dart';
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/locale/owner_locale_scope.dart';
import '../../../../core/router/pending_login_return_path.dart';
import '../../../../core/widgets/save_error_dialog.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import '../../../models/knowledge_module.dart';
import '../../../models/shared_module_data.dart';
import '../../../models/share_stats.dart';
import 'module_provider.dart';
import 'home_page.dart'; // Import for homeTabControlProvider
import '../../lab/deconstruct/deconstruct_chat_route_args.dart';
import '../../../../core/providers/credit_provider.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../l10n/module_display_strings.dart';

class ModuleDetailPage extends ConsumerWidget {
  static final Set<String> _shareViewRecorded = {};

  final String moduleId;
  final String? ownerId;
  final bool afterLoginSave;

  const ModuleDetailPage({
    super.key,
    required this.moduleId,
    this.ownerId,
    this.afterLoginSave = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ownerId != null) {
      return _buildSharedView(context, ref);
    }
    return _buildLoggedInView(context, ref);
  }

  Widget _buildSharedView(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sharedAsync = ref.watch(sharedModuleProvider((ownerId!, moduleId)));

    return sharedAsync.when(
      data: (shared) {
        // 统计：分享页被浏览一次（每会话每链接只记一次）
        if (!ModuleDetailPage._shareViewRecorded.contains('$ownerId-$moduleId')) {
          ModuleDetailPage._shareViewRecorded.add('$ownerId-$moduleId');
          ref.read(dataServiceProvider).recordShareView(ownerId!, moduleId);
        }
        final scoped = OwnerLocaleScope(
          ownerUiLocale: shared.ownerUiLocale,
          child: _buildGuestSharedBody(context, ref, isDark, shared),
        );
        if (afterLoginSave) {
          return _AutoSaveAfterLogin(
            moduleId: moduleId,
            ownerId: ownerId!,
            onSave: () => _onSaveToMyLibrary(
              context,
              ref,
              shared,
              '/module/$moduleId?ref=$ownerId',
            ),
            onClearParam: () =>
                context.go('/module/$moduleId?ref=$ownerId'),
            child: scoped,
          );
        }
        return scoped;
      },
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('${AppLocalizations.of(context)!.moduleLoadFailed}: $e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => context.go('/onboarding'),
                  icon: const Icon(Icons.login),
                  label: Text(AppLocalizations.of(context)!.moduleGoLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestSharedBody(
      BuildContext context, WidgetRef ref, bool isDark, SharedModuleData shared) {
    final loc = ref.watch(localeProvider).outputLocale;
    final module = shared.module;
    final moduleItems = shared.items;
    final cardCount = moduleItems.length;
    final baseUrl = html.window.location.origin;
    final returnPath =
        '/module/$moduleId?ref=$ownerId&afterLogin=save';
    final currentShareUrl = '$baseUrl/#$returnPath';
    final user = FirebaseAuth.instance.currentUser;

    return _ShareStatsRefreshWrapper(
      ownerId: ownerId!,
      moduleId: moduleId,
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () =>
                        user == null ? context.go('/onboarding') : context.go('/'),
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.moduleSharedLibrary,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(ModuleDisplayStrings.moduleTitle(module, loc),
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(ModuleDisplayStrings.moduleDescription(module, loc),
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54)),
                    const SizedBox(height: 8),
                    Text(L10nNumbers.moduleCardCount(context, cardCount),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black45)),
                    const SizedBox(height: 8),
                    _buildShareStatsRow(context, ref, isDark),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _onSaveToMyLibrary(
                                context, ref, shared, returnPath),
                            icon: const Icon(Icons.bookmark_add_outlined),
                            label: Text(AppLocalizations.of(context)!.moduleSaveToMyLibrary),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push(
                                  '/shared-feed/$moduleId?ref=$ownerId');
                            },
                            icon: const Icon(Icons.menu_book),
                            label: Text(AppLocalizations.of(context)!.moduleStartReading),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ...moduleItems.asMap().entries.map((e) {
                      final item = e.value;
                      final index = e.key;
                      return _buildCompactCard(context, item, index, isDark,
                          ref, false,
                          sharedModuleId: moduleId, sharedOwnerId: ownerId);
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _onSaveToMyLibrary(BuildContext context, WidgetRef ref,
      SharedModuleData shared, String returnPath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PendingLoginReturnPath.set(returnPath);
      context.go('/onboarding');
      return;
    }
    if (!context.mounted) return;
    // 立即弹出加载框，避免用户以为没反应
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 20),
            Text(AppLocalizations.of(context)!.moduleSavingToLibrary),
          ],
        ),
      ),
    );
    try {
      if (shared.module.isOfficial) {
        ref.read(lastActiveModuleProvider.notifier).setActiveModule(moduleId);
        ref.read(homeTabControlProvider.notifier).state = 1;
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) context.go('/');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.moduleAddedGoHome),
                behavior: SnackBarBehavior.floating),
          );
        }
      } else {
        final dataService = ref.read(dataServiceProvider);
        final newId =
            await dataService.copySharedModuleToMine(ownerId!, moduleId);
        dataService.recordShareSave(ownerId!, moduleId);
        ref.invalidate(shareStatsProvider((ownerId!, moduleId)));
        if (!context.mounted) {
          Navigator.of(context).pop();
          return;
        }
        await ref.read(moduleProvider.notifier).refresh();
        await ref.read(feedProvider.notifier).loadAllData();
        ref.read(feedProvider.notifier).loadModule(newId);
        await Future.delayed(const Duration(milliseconds: 80));
        if (!context.mounted) return;
        Navigator.of(context).pop();
        context.go('/module/$newId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.moduleSavedToLibrary),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        showSaveToLibraryErrorDialog(context, error: e, onRetry: () {
          _onSaveToMyLibrary(context, ref, shared, returnPath);
        });
      }
    }
  }

  Widget _buildShareStatsRow(BuildContext context, WidgetRef ref, bool isDark) {
    if (ownerId == null) return const SizedBox.shrink();
    final statsAsync = ref.watch(shareStatsProvider((ownerId!, moduleId)));
    final likedKeys = ref.watch(shareLikedKeysProvider);
    final user = FirebaseAuth.instance.currentUser;
    final likedKey = '${ownerId}_$moduleId';
    return statsAsync.when(
      data: (stats) {
        final v = stats?.viewCount ?? 0;
        final s = stats?.saveCount ?? 0;
        final l = stats?.likeCount ?? 0;
        final hasLiked = (stats?.hasLiked(user?.uid) ?? false) || likedKeys.contains(likedKey);
        final subColor = isDark ? Colors.white54 : Colors.black45;
        return Row(
          children: [
            Icon(Icons.visibility_outlined, size: 14, color: subColor),
            const SizedBox(width: 4),
            Text(L10nNumbers.moduleViews(context, v), style: TextStyle(fontSize: 12, color: subColor)),
            const SizedBox(width: 12),
            Icon(Icons.bookmark_outline, size: 14, color: subColor),
            const SizedBox(width: 4),
            Text(L10nNumbers.moduleSaves(context, s), style: TextStyle(fontSize: 12, color: subColor)),
            const SizedBox(width: 12),
            Icon(Icons.thumb_up_outlined, size: 14, color: subColor),
            const SizedBox(width: 4),
            Text(L10nNumbers.moduleLikes(context, l), style: TextStyle(fontSize: 12, color: subColor)),
            const Spacer(),
            IconButton(
              icon: Icon(
                hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 20,
                color: hasLiked ? Colors.orange : subColor,
              ),
              onPressed: () async {
                final dataService = ref.read(dataServiceProvider);
                final isNewLike = await dataService.recordShareLike(ownerId!, moduleId);
                if (isNewLike) {
                  ref.read(shareLikedKeysProvider.notifier).state = {...likedKeys, likedKey};
                }
                ref.invalidate(shareStatsProvider((ownerId!, moduleId)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isNewLike ? AppLocalizations.of(context)!.moduleThanksLike : AppLocalizations.of(context)!.moduleAlreadyLiked),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 20),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOwnerShareStats(BuildContext context, WidgetRef ref, bool isDark) {
    final user = FirebaseAuth.instance.currentUser;
    final moduleState = ref.watch(moduleProvider);
    final isOwnCustom = user != null &&
        moduleState.custom.any((m) => m.id == moduleId);
    if (!isOwnCustom) return const SizedBox.shrink();
    final statsAsync = ref.watch(shareStatsProvider((user!.uid, moduleId)));
    return statsAsync.when(
      data: (stats) {
        if (stats == null || (stats.viewCount == 0 && stats.saveCount == 0 && stats.likeCount == 0)) {
          return const SizedBox.shrink();
        }
        final subColor = isDark ? Colors.white54 : Colors.black45;
        return Row(
          children: [
            Icon(Icons.bar_chart_outlined, size: 16, color: subColor),
            const SizedBox(width: 6),
            Text(
              L10nNumbers.moduleShareData(context, stats.viewCount,
                  stats.saveCount, stats.likeCount),
              style: TextStyle(fontSize: 13, color: subColor),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static final Set<String> _detailTouchedModuleIds = {};

  Widget _buildLoggedInView(BuildContext context, WidgetRef ref) {
    // 「最近在学」：进入模块详情页即标记该模块为刚访问（仅一次 per 会话）
    if (moduleId != 'ALL' &&
        moduleId != 'AI_NOTES' &&
        !_detailTouchedModuleIds.contains(moduleId)) {
      _detailTouchedModuleIds.add(moduleId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(moduleLastAccessedAtProvider.notifier).touch(moduleId);
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moduleState = ref.watch(moduleProvider);
    final feedItems = ref.watch(allItemsProvider);
    print('🔍 ModuleDetailPage build: moduleId=$moduleId');

    if (moduleState.isLoading &&
        moduleState.officials.isEmpty &&
        moduleState.custom.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    KnowledgeModule module;
    if (moduleId == 'ALL') {
      module = KnowledgeModule(
        id: 'ALL',
        title: AppLocalizations.of(context)!.moduleAllKnowledge,
        description: AppLocalizations.of(context)!.moduleAllKnowledgeDesc,
        ownerId: 'official',
        isOfficial: true,
        // cardCount will be calculated below
      );
    } else {
      module = [...moduleState.officials, ...moduleState.custom].firstWhere(
        (m) => m.id == moduleId,
        orElse: () {
          print('⚠️ ModuleDetailPage: Module $moduleId not found in state!');
          // Fallback: Check static official modules directly
          return KnowledgeModule.officials.firstWhere(
            (m) => m.id == moduleId,
            orElse: () {
              print(
                  '❌ ModuleDetailPage: Module $moduleId not found in STATIC officials either!');
              return KnowledgeModule(
                id: moduleId,
                title: '${AppLocalizations.of(context)!.moduleUnknown} ($moduleId)',
                description: AppLocalizations.of(context)!.moduleNotFound,
                ownerId: 'unknown',
                isOfficial: false,
              );
            },
          );
        },
      );
    }

    // Get module items
    final List<FeedItem> moduleItems;
    if (moduleId == 'ALL') {
      moduleItems = feedItems;
    } else {
      moduleItems =
          feedItems.where((item) => item.moduleId == moduleId).toList();
    }
    final cardCount = moduleItems.length;
    final learned = moduleItems
        .where((i) => i.masteryLevel != FeedItemMastery.unknown)
        .length;
    final progress = cardCount > 0 ? learned / cardCount : 0.0;
    final loc = ref.watch(localeProvider).outputLocale;

    // Get current progress for this module
    final currentProgress = ref.watch(feedProgressProvider);
    final currentModuleIndex = currentProgress[moduleId] ?? 0;
    final user = FirebaseAuth.instance.currentUser;
    final isOwnCustom = user != null &&
        moduleState.custom.any((m) => m.id == moduleId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            if (isOwnCustom)
              _ShareStatsRefreshRunner(
                ownerId: user!.uid,
                moduleId: moduleId,
              ),
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final includeNotes = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(AppLocalizations.of(context)!.moduleShareLibrary),
                          content: Text(
                              AppLocalizations.of(context)!.moduleShareWithNotes),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, false),
                              child: Text(AppLocalizations.of(context)!.moduleShareLibraryOnly),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(ctx, true),
                              child: Text(AppLocalizations.of(context)!.moduleShareLibraryAndNotes),
                            ),
                          ],
                        ),
                      );
                      if (includeNotes == null || !context.mounted) return;

                      await ref
                          .read(dataServiceProvider)
                          .setShareNotesPublic(user.uid, includeNotes);

                      final String baseUrl = html.window.location.origin;
                      final String shareUrl =
                          '$baseUrl/#/module/$moduleId?ref=${user.uid}';

                      Clipboard.setData(ClipboardData(
                          text: L10nNumbers.moduleShareCopyBody(
                          context, shareUrl, module.title)));

                      ref.read(creditProvider.notifier).rewardShare(amount: 10);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.stars,
                                        color: Color(0xFFFFB300)),
                                    const SizedBox(width: 8),
                                    Text(
                                        AppLocalizations.of(context)!.shareSuccessReward,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(AppLocalizations.of(context)!.shareCopiedToClipboard,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                    AppLocalizations.of(context)!.sharePasteToFriends,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white)),
                                const SizedBox(height: 6),
                                Text(
                                    AppLocalizations.of(context)!.shareFriendJoinReward,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70)),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'rename' && !module.isOfficial) {
                        final controller = TextEditingController(text: module.title);
                        final newTitle = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.moduleRenameLibrary),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.moduleNameLabel,
                                hintText: AppLocalizations.of(context)!.moduleNameHint,
                                border: const OutlineInputBorder(),
                              ),
                              autofocus: true,
                              onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(AppLocalizations.of(context)!.cancel)),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, controller.text.trim()),
                                  child: Text(AppLocalizations.of(context)!.dialogConfirm)),
                            ],
                          ),
                        );
                        if (newTitle != null && newTitle.isNotEmpty && newTitle != module.title) {
                          await ref
                              .read(moduleProvider.notifier)
                              .updateModule(moduleId, newTitle, null);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.moduleUpdatedName)));
                          }
                        }
                        return;
                      }
                      if (value == 'edit_details' && !module.isOfficial) {
                        final controller = TextEditingController(text: module.description);
                        final newDesc = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.moduleEditDetails),
                            content: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.moduleDescLabel,
                                hintText: AppLocalizations.of(context)!.moduleDescHint,
                                alignLabelWithHint: true,
                              ),
                              maxLines: 4,
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(AppLocalizations.of(context)!.cancel)),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(ctx, controller.text.trim()),
                                  child: Text(AppLocalizations.of(context)!.dialogConfirm)),
                            ],
                          ),
                        );
                        if (newDesc != null && newDesc != module.description) {
                          await ref
                              .read(moduleProvider.notifier)
                              .updateModule(moduleId, null, newDesc);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(AppLocalizations.of(context)!.moduleUpdatedDetails)));
                          }
                        }
                        return;
                      }
                      if (value == 'delete' || value == 'hide') {
                        final isHide = value == 'hide';
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(isHide ? AppLocalizations.of(context)!.moduleHideLibrary : AppLocalizations.of(context)!.moduleDeleteLibrary),
                            content: Text(isHide
                                ? AppLocalizations.of(context)!.moduleHideLibraryDesc
                                : AppLocalizations.of(context)!.moduleDeleteLibraryDesc),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(isHide ? AppLocalizations.of(context)!.moduleHide : AppLocalizations.of(context)!.moduleDelete,
                                    style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          if (isHide) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              await ref
                                  .read(dataServiceProvider)
                                  .hideOfficialModule(user.uid, moduleId);
                              ref.read(moduleProvider.notifier).refresh();
                            }
                          } else {
                            await ref
                                .read(moduleProvider.notifier)
                                .deleteModule(moduleId);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(isHide ? AppLocalizations.of(context)!.moduleLibraryHidden : AppLocalizations.of(context)!.moduleLibraryDeleted)),
                            );
                            context.pop();
                          }
                        }
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuItem<String>>[];
                      if (!module.isOfficial) {
                        items.addAll([
                          PopupMenuItem(
                            value: 'rename',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.moduleRename),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit_details',
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 20),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.moduleEditDetails),
                              ],
                            ),
                          ),
                        ]);
                      }
                      items.addAll([
                        PopupMenuItem(
                          value: 'hide',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_off_outlined,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.moduleHide, style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.modulePermanentDelete, style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ]);
                      return items;
                    },
                  ),
                ],
              ),
            ),

            // Module Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ModuleDisplayStrings.moduleTitle(module, loc),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ModuleDisplayStrings.moduleDescription(module, loc),
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildTag(L10nNumbers.moduleCardsTag(context, cardCount), isDark),
                      _buildTag(module.isOfficial ? AppLocalizations.of(context)!.moduleOfficial : AppLocalizations.of(context)!.modulePrivate, isDark),
                      _buildTag(
                          L10nNumbers.moduleMasteredPct(
                              context, (progress * 100).toInt()),
                          isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOwnerShareStats(context, ref, isDark),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 1. Filter items for this module to find how many we have
                            final moduleItems = feedItems
                                .where((item) => item.moduleId == moduleId)
                                .toList();

                            // 2. Determine random starting index
                            int targetIndex = 0;
                            if (moduleItems.isNotEmpty) {
                              targetIndex =
                                  Random().nextInt(moduleItems.length);
                            }

                            // 3. Save active module
                            ref
                                .read(lastActiveModuleProvider.notifier)
                                .setActiveModule(moduleId);

                            // 4. Set progress to the random index
                            ref
                                .read(feedProgressProvider.notifier)
                                .setProgress(moduleId, targetIndex);

                            // 5. Switch to Feed tab via provider
                            ref.read(homeTabControlProvider.notifier).state = 1;

                            // 6. Pop back to HomePage
                            context.pop();
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: Text(AppLocalizations.of(context)!.moduleStartLearning,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFCDFF64),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () {
                            context.push(
                              '/deconstruct-chat',
                              extra: DeconstructChatRouteArgs(
                                targetModuleId: moduleId,
                              ),
                            );
                          },
                          icon: const Icon(Icons.add, color: Colors.black),
                          iconSize: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Card List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: moduleItems.length,
                itemBuilder: (context, index) {
                  final item = moduleItems[index];
                  final isCurrentlyViewing = index == currentModuleIndex;
                  return _buildCompactCard(
                      context, item, index, isDark, ref, isCurrentlyViewing);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFCDFF64).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCDFF64).withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFCDFF64) : const Color(0xFF7C9A00),
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context, FeedItem item, int index,
      bool isDark, WidgetRef ref, bool isCurrentlyViewing,
      {String? sharedModuleId, String? sharedOwnerId}) {
    // Get preview text
    String previewText = '';
    if (item.pages.isNotEmpty) {
      final firstPage = item.pages.first;
      if (firstPage is OfficialPage) {
        previewText = firstPage.markdownContent
            .replaceAll(RegExp(r'[#*\[\]`>]'), '')
            .replaceAll(RegExp(r'\n+'), ' ')
            .trim();
        if (previewText.length > 60) {
          previewText = '${previewText.substring(0, 60)}...';
        }
      }
    }

    final isGuestShared = sharedModuleId != null && sharedOwnerId != null;

    return GestureDetector(
      onTap: () {
        if (isGuestShared) {
          context.push(
              '/shared-feed/$sharedModuleId?ref=$sharedOwnerId&index=$index');
          return;
        }
        // Save the active module and card index
        ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(item.moduleId);
        ref
            .read(feedProgressProvider.notifier)
            .setProgress(item.moduleId, index);

        // Switch HomePage tab to Feed (index 1)
        ref.read(homeTabControlProvider.notifier).state = 1;

        // Simply pop back to HomePage!
        context.pop();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentlyViewing
              ? (isDark
                  ? const Color(0xFFCDFF64).withOpacity(0.1)
                  : const Color(0xFFCDFF64).withOpacity(0.05))
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentlyViewing
                ? const Color(0xFFCDFF64)
                : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2)),
            width: isCurrentlyViewing ? 2.0 : 1.0,
          ),
          boxShadow: isCurrentlyViewing
              ? [
                  BoxShadow(
                    color: const Color(0xFFCDFF64).withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Index
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCurrentlyViewing
                    ? const Color(0xFFCDFF64)
                    : (item.masteryLevel != FeedItemMastery.unknown
                        ? const Color(0xFFCDFF64).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2)),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isCurrentlyViewing
                      ? (isDark ? Colors.black87 : const Color(0xFF7C9A00))
                      : (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCurrentlyViewing
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (previewText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      previewText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.pages.length > 1)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: isDark
                      ? Colors.amber.shade300
                      : Colors.amber.shade700,
                ),
              ),
            // Arrow / Actions
            if (true) // Allow hiding official cards too based on USER request
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz,
                  color: isCurrentlyViewing
                      ? (isDark
                          ? const Color(0xFFCDFF64)
                          : const Color(0xFF7C9A00))
                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if (value == 'move' && item.isCustom && !isGuestShared) {
                    final modules = ref
                        .read(moduleProvider)
                        .custom
                        .where((m) => m.id != item.moduleId)
                        .toList();
                    if (modules.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(AppLocalizations.of(context)!.moduleMovePrompt)));
                      }
                      return;
                    }
                    final target = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.moduleMoveToLibrary),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: modules
                                .map((m) => ListTile(
                                      title: Text(m.title),
                                      subtitle: m.description.isNotEmpty
                                          ? Text(m.description,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis)
                                          : null,
                                      onTap: () =>
                                          Navigator.pop(ctx, m.id),
                                    ))
                                .toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(AppLocalizations.of(context)!.cancel)),
                        ],
                      ),
                    );
                    if (target != null && context.mounted) {
                      await ref
                          .read(feedProvider.notifier)
                          .moveFeedItem(item.id, target);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.moduleMoved)));
                      }
                    }
                    return;
                  }
                  if (value == 'delete' || value == 'hide') {
                    final isHide = value == 'hide';
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(isHide ? AppLocalizations.of(context)!.moduleHideCard : AppLocalizations.of(context)!.moduleDeleteCard),
                        content:
                            Text(isHide ? AppLocalizations.of(context)!.moduleHideCardDesc : AppLocalizations.of(context)!.moduleDeleteCardDesc),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(isHide ? AppLocalizations.of(context)!.moduleHide : AppLocalizations.of(context)!.moduleDelete,
                                style: const TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      if (isHide) {
                        await ref
                            .read(feedProvider.notifier)
                            .hideFeedItem(item.id);
                      } else {
                        await ref
                            .read(feedProvider.notifier)
                            .deleteFeedItem(item.id);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isHide ? AppLocalizations.of(context)!.moduleCardHidden : AppLocalizations.of(context)!.moduleCardRemoved)),
                      );
                    }
                  }
                },
                itemBuilder: (context) {
                  final list = <PopupMenuItem<String>>[];
                  if (item.isCustom && !isGuestShared) {
                    list.add(PopupMenuItem(
                      value: 'move',
                      height: 32,
                      child: Text(AppLocalizations.of(context)!.moduleMove,
                          style: const TextStyle(fontSize: 13, color: Colors.blue)),
                    ));
                  }
                  list.addAll([
                    PopupMenuItem(
                      value: 'hide',
                      height: 32,
                      child: Text(AppLocalizations.of(context)!.moduleHide,
                          style: const TextStyle(fontSize: 13, color: Colors.orange)),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      height: 32,
                      child: Text(AppLocalizations.of(context)!.modulePermanentDelete,
                          style: const TextStyle(fontSize: 13, color: Colors.red)),
                    ),
                  ]);
                  return list;
                },
              )
            else
              Icon(
                isCurrentlyViewing
                    ? Icons.play_circle_filled
                    : Icons.chevron_right,
                color: isCurrentlyViewing
                    ? (isDark
                        ? const Color(0xFFCDFF64)
                        : const Color(0xFF7C9A00))
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}

/// 分享页展示时每 15 秒刷新一次统计，实现准实时更新
class _ShareStatsRefreshWrapper extends ConsumerStatefulWidget {
  final String ownerId;
  final String moduleId;
  final Widget child;

  const _ShareStatsRefreshWrapper({
    required this.ownerId,
    required this.moduleId,
    required this.child,
  });

  @override
  ConsumerState<_ShareStatsRefreshWrapper> createState() => _ShareStatsRefreshWrapperState();
}

class _ShareStatsRefreshWrapperState extends ConsumerState<_ShareStatsRefreshWrapper> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          ref.invalidate(shareStatsProvider((widget.ownerId, widget.moduleId)));
        }
      });
    }
    return widget.child;
  }
}

/// 主人端知识库详情页：仅跑定时器刷新分享数据，不占布局
class _ShareStatsRefreshRunner extends ConsumerStatefulWidget {
  final String ownerId;
  final String moduleId;

  const _ShareStatsRefreshRunner({
    required this.ownerId,
    required this.moduleId,
  });

  @override
  ConsumerState<_ShareStatsRefreshRunner> createState() => _ShareStatsRefreshRunnerState();
}

class _ShareStatsRefreshRunnerState extends ConsumerState<_ShareStatsRefreshRunner> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          ref.invalidate(shareStatsProvider((widget.ownerId, widget.moduleId)));
        }
      });
    }
    return const SizedBox.shrink();
  }
}

/// 登录后回跳时自动执行一次「保存到我的知识库」，并显示「正在保存」弹窗
class _AutoSaveAfterLogin extends StatefulWidget {
  final String moduleId;
  final String ownerId;
  final VoidCallback onSave;
  final VoidCallback onClearParam;
  final Widget child;

  const _AutoSaveAfterLogin({
    required this.moduleId,
    required this.ownerId,
    required this.onSave,
    required this.onClearParam,
    required this.child,
  });

  @override
  State<_AutoSaveAfterLogin> createState() => _AutoSaveAfterLoginState();
}

class _AutoSaveAfterLoginState extends State<_AutoSaveAfterLogin> {
  bool _didRun = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_didRun) return;
      _didRun = true;
      widget.onSave();
      widget.onClearParam();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
