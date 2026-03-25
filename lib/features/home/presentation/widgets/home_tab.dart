import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // Add async import for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quick_pm/l10n/app_localizations.dart';
import 'package:quick_pm/l10n/l10n_numeric_strings.dart';
import '../../../feed/presentation/feed_provider.dart';
import '../../../../models/feed_item.dart';
import '../../../../models/knowledge_module.dart';
import '../../../../models/share_stats.dart';
import '../module_provider.dart';
import '../../../../core/providers/credit_provider.dart';
import '../../../../core/locale/locale_provider.dart';
import '../../../../l10n/module_display_strings.dart';
import '../../../lab/deconstruct/deconstruct_chat_route_args.dart';
import '../../../lab/presentation/widgets/tutorial_pulse.dart';
import '../../../onboarding/providers/onboarding_provider.dart';
import '../../../onboarding/presentation/widgets/tutorial_overlay.dart';
import '../../../onboarding/presentation/widgets/onboarding_checklist.dart';

// Helper provider for the filter tab state
final _homeModuleFilterProvider = StateProvider.autoDispose<int>(
    (ref) => 0); // 0: Official, 1: Personal, 2: Recent

class HomeTab extends ConsumerStatefulWidget {
  final Function(String moduleId)? onLoadModule;
  final VoidCallback? onJumpToFeed;
  final VoidCallback? onStartAiNotesTutorial;

  const HomeTab({
    super.key,
    this.onLoadModule,
    this.onJumpToFeed,
    this.onStartAiNotesTutorial,
  });

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  final GlobalKey _aiDeconstructKey = GlobalKey();
  final GlobalKey _aiNotesKey = GlobalKey();
  final GlobalKey _taskCenterKey = GlobalKey();
  final GlobalKey _starModuleKey = GlobalKey();

  String? _tutorialText;
  String? _tutorialStepType;
  GlobalKey? _tutorialTargetKey;
  User? _currentUser;
  StreamSubscription<User?>? _userSubscription;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _userSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userSubscription?.cancel();
    super.dispose();
  }

  void _startTutorialStep(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _tutorialStepType = type;
      if (type == 'text') {
        _tutorialText = l10n.tutorialTextAiDeconstruct;
        _tutorialTargetKey = _aiDeconstructKey;
      } else if (type == 'task_center') {
        _tutorialText = l10n.tutorialTextTaskCenter;
        _tutorialTargetKey = _taskCenterKey;
      } else if (type == 'multimodal') {
        _tutorialText = l10n.tutorialTextMultimodal;
        _tutorialTargetKey = _aiDeconstructKey;
      } else if (type == 'all_cards') {
        _tutorialText = l10n.tutorialTextAllCards;
        _tutorialTargetKey = _starModuleKey;
      } else if (type == 'ai_notes') {
        _tutorialText = l10n.tutorialTextAiNotes;
        _tutorialTargetKey = _aiNotesKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filterIndex = ref.watch(_homeModuleFilterProvider);
    final onboardingState = ref.watch(onboardingProvider);

    // Data Sources
    final feedItems = ref.watch(allItemsProvider);
    final moduleState = ref.watch(moduleProvider);

    // 三个分类的列表都按「最后学习/访问时间」排序，使「最新」= 真正最近在学
    final lastAt = ref.watch(moduleLastAccessedAtProvider);
    List<KnowledgeModule> displayedModules = [];
    if (filterIndex == 0) {
      displayedModules = List<KnowledgeModule>.from(moduleState.officials)
        ..sort((a, b) {
          final ta = lastAt[a.id] ?? 0;
          final tb = lastAt[b.id] ?? 0;
          return tb.compareTo(ta);
        });
    } else if (filterIndex == 1) {
      displayedModules = List<KnowledgeModule>.from(moduleState.custom)
        ..sort((a, b) {
          final ta = lastAt[a.id] ?? 0;
          final tb = lastAt[b.id] ?? 0;
          return tb.compareTo(ta);
        });
    } else {
      final combined = [...moduleState.custom, ...moduleState.officials];
      displayedModules = List<KnowledgeModule>.from(combined)
        ..sort((a, b) {
          final ta = lastAt[a.id] ?? 0;
          final tb = lastAt[b.id] ?? 0;
          return tb.compareTo(ta);
        });
    }

    // 浅色：顶部偏米色，内容区纯白，控件用有层次的暖灰，避免灰成一团
    const topBeige = Color(0xFFFDF8F3); // 「晚上好」区域：偏米色
    const contentWhite = Colors.white;
    const inputBg = Color(0xFFF5F0E8);   // 搜索框等：暖灰，与白区分
    const tabSelectedBg = Color(0xFFEFE9E1); // 选中标签：再深一点暖灰
    const cardHighlight = Color(0xFFF8F6F3); // 卡片高亮：极浅暖灰

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : contentWhite,
      body: Stack(
        children: [
          if (_currentUser != null)
            _HomeShareStatsRefresher(
              userId: _currentUser!.uid,
              moduleIds: ref.watch(moduleProvider).custom.map((e) => e.id).toList(),
            ),
          // 1. 顶部区域：浅色用米色，深色不变
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : topBeige,
            ),
          ),

          // 2. 下方内容区：纯白，与顶部米色分层
          Container(
            margin: const EdgeInsets.only(top: 320),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : contentWhite,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(48)),
            ),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(48)),
              child: Column(
                children: [
                  // Tabs Area
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _FilterTabItem(
                            label: AppLocalizations.of(context)!.tabOfficial,
                            isSelected: filterIndex == 0,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 0),
                        _FilterTabItem(
                            label: AppLocalizations.of(context)!.tabPersonal,
                            isSelected: filterIndex == 1,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 1),
                        _FilterTabItem(
                            label: AppLocalizations.of(context)!.tabRecent,
                            isSelected: filterIndex == 2,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 2),
                      ],
                    ),
                  ),

                  // Module List (responsive: ListView on narrow, Grid on wide)
                  Expanded(
                    child: displayedModules.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(AppLocalizations.of(context)!.emptyHere,
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final width =
                                  MediaQuery.of(context).size.width;
                              final crossAxisCount = width >= 900
                                  ? 3
                                  : (width >= 600 ? 2 : 1);

                              if (crossAxisCount == 1) {
                                return ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 8),
                                  itemCount: displayedModules.length + 1,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 16),
                                  itemBuilder: (context, index) {
                                    if (index ==
                                        displayedModules.length) {
                                      return const SizedBox(height: 80);
                                    }
                                    final firstStarIndex = displayedModules
                                        .indexWhere(
                                            ModuleDisplayStrings.isStarOfficialModule);
                                    return _buildModuleCard(
                                      context,
                                      displayedModules[index],
                                      feedItems,
                                      index == 0,
                                      onboardingState,
                                      useStarKey: firstStarIndex >= 0 &&
                                          index == firstStarIndex,
                                    );
                                  },
                                );
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    24, 8, 24, 80),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisExtent: 116,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: displayedModules.length,
                                itemBuilder: (context, index) {
                                  final firstStarIndex = displayedModules
                                      .indexWhere(
                                          ModuleDisplayStrings.isStarOfficialModule);
                                  return _buildModuleCard(
                                    context,
                                    displayedModules[index],
                                    feedItems,
                                    index == 0,
                                    onboardingState,
                                    useStarKey: firstStarIndex >= 0 &&
                                        index == firstStarIndex,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Header & Search Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40), // Reduced top spacing by 10px
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(context),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF5D4037).withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getUserName(_currentUser),
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF3E2723),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily:
                                    'JinghuaSong', // Use custom serif font
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildSimpleQuote(context, isDark, feedItems.length),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20), // Wider gap
                      Hero(
                        tag: 'home_avatar',
                        child: GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.3),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: _buildAvatar(user: _currentUser, radius: 36),
                              ),
                              if (_currentUser != null)
                                ref.watch(dailyCheckInBadgeVisibleProvider).when(
                                  data: (showBadge) {
                                    if (!showBadge) return const SizedBox.shrink();
                                    return Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF8A65),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.notification_important,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Two Elegant Buttons
                  // Three Capsule Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: _ElegantMenuButton(
                          key: _aiDeconstructKey,
                          title: AppLocalizations.of(context)!.aiDeconstruct,
                          icon: Icons.auto_awesome,
                          color: const Color(0xFFFF5252),
                          bgColor: const Color(0xFFFFEBEE),
                          onTap: () {
                            context
                                .push(
                              '/deconstruct-chat',
                              extra: DeconstructChatRouteArgs(
                                isTutorialMode:
                                    onboardingState.isTutorialActive,
                                tutorialStep: _tutorialTargetKey ==
                                        _aiDeconstructKey
                                    ? (_tutorialStepType == 'multimodal'
                                        ? 'multimodal'
                                        : 'text')
                                    : null,
                              ),
                            )
                                .then((_) {
                              if (mounted && _tutorialText != null) {
                                setState(() {
                                  _tutorialText = null;
                                  _tutorialStepType = null;
                                  _tutorialTargetKey = null;
                                });
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 20), // Wider gap
                      Expanded(
                        child: _ElegantMenuButton(
                          key: _aiNotesKey,
                          title: AppLocalizations.of(context)!.aiNotes,
                          icon: Icons.menu_book,
                          color: const Color(0xFF1976D2),
                          bgColor: const Color(0xFFE3F2FD),
                          onTap: () {
                            if (onboardingState.isTutorialActive) {
                              if (_tutorialTargetKey == _aiNotesKey) {
                                setState(() {
                                  _tutorialText = null;
                                  _tutorialTargetKey = null;
                                });
                              }
                            }
                            context.push('/ai-notes');
                          },
                        ),
                      ),
                      const SizedBox(width: 20), // Wider gap
                      Expanded(
                        child: Consumer(builder: (context, ref, child) {
                          final highlight =
                              ref.watch(onboardingProvider).highlightTaskCenter;
                          return TutorialPulse(
                            isActive: highlight,
                            child: _ElegantMenuButton(
                              key: _taskCenterKey,
                              title: AppLocalizations.of(context)!.taskCenter,
                              icon: Icons.task_alt,
                              color: const Color(0xFF009688),
                              bgColor: const Color(0xFFE0F2F1),
                              onTap: () {
                                ref
                                    .read(onboardingProvider.notifier)
                                    .setHighlightTaskCenter(false);
                                if (onboardingState.isTutorialActive) {
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .completeStep('task_center');
                                }
                                context.push('/task-center');
                              },
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : inputBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                context.push(
                                    '/search?q=${Uri.encodeComponent(value.trim())}');
                              }
                            },
                            style: const TextStyle(fontSize: 14, height: 1.0),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.searchKnowledgeHint,
                              hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.grey[600],
                                fontSize: 14,
                                height: 1.0,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets
                                  .zero, // Crucial for center alignment
                              isDense: true,
                              suffixIconConstraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48), // Ensure touch target
                              suffixIcon: IconButton(
                                icon: Icon(Icons.search,
                                    size: 24,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600),
                                onPressed: () {
                                  final value = _searchController.text.trim();
                                  if (value.isNotEmpty) {
                                    context.push(
                                        '/search?q=${Uri.encodeComponent(value)}');
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20), // Wider gap
                      _CircleActionButton(
                        icon: Icons.explore,
                        color: Colors.black87,
                        onTap: () => context.push('/explore'),
                      ),
                      const SizedBox(width: 8),
                      _CircleActionButton(
                        icon: Icons.add,
                        color: Colors.black87,
                        isPrimary: true,
                        onTap: () => _showCreateModuleDialog(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_tutorialText != null)
            TutorialOverlay(
              targetKey: _tutorialTargetKey,
              text: _tutorialText!,
              onDismiss: () => setState(() {
                _tutorialText = null;
                _tutorialStepType = null;
                _tutorialTargetKey = null;
              }),
            ),
          OnboardingChecklist(
            onStartTextTutorial: () => _startTutorialStep(context, 'text'),
            onStartTaskCenterTutorial: () => _startTutorialStep(context, 'task_center'),
            onStartMultiTutorial: () => _startTutorialStep(context, 'multimodal'),
            onStartAllCardsTutorial: () => _startTutorialStep(context, 'all_cards'),
            onStartAiNotesTutorial: () => _startTutorialStep(context, 'ai_notes'),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    KnowledgeModule module,
    List<FeedItem> feedItems,
    bool isHighlighted,
    OnboardingState onboardingState, {
    bool useStarKey = false,
  }) {
    final mItems =
        feedItems.where((i) => i.moduleId == module.id).toList();
    final count = mItems.length;
    final learned = mItems
        .where(
            (i) => i.masteryLevel != FeedItemMastery.unknown)
        .length;
    final progress = count > 0 ? learned / count : 0.0;
    final isStarModule = ModuleDisplayStrings.isStarOfficialModule(module);
    final loc = ref.watch(localeProvider).outputLocale;
    final ShareStats? shareStats = (!module.isOfficial && _currentUser != null)
        ? ref.watch(shareStatsProvider((_currentUser!.uid, module.id))).valueOrNull
        : null;

    return _WideKnowledgeCard(
      key: useStarKey ? _starModuleKey : ValueKey('module_${module.id}'),
      title: ModuleDisplayStrings.moduleTitle(module, loc),
      description: ModuleDisplayStrings.moduleDescription(module, loc),
      progress: progress,
      cardCount: count,
      isHighlighted: isHighlighted,
      shareStats: shareStats,
      onTap: () {
        if (onboardingState.isTutorialActive &&
            _tutorialTargetKey == _starModuleKey &&
            isStarModule) {
          ref.read(onboardingProvider.notifier).completeStep('all_cards_p1');
        }
        if (widget.onLoadModule != null) {
          widget.onLoadModule!(module.id);
        } else {
          context.push('/module/${module.id}');
        }
      },
    );
  }

  Widget _buildSimpleQuote(BuildContext context, bool isDark, int totalItems) {
    final l10n = AppLocalizations.of(context)!;
    final quotes = [
      l10n.quote1,
      l10n.quote2,
      l10n.quote3,
      l10n.quote4,
      l10n.quote5,
      l10n.quote6,
      l10n.quote7,
    ];
    final index = DateTime.now().minute % quotes.length;

    return Text(
      quotes[index],
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  String _getGreeting(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return l10n.goodMorning;
    } else if (hour >= 12 && hour < 18) {
      return l10n.goodAfternoon;
    } else if (hour >= 18 && hour < 22) {
      return l10n.goodEvening;
    } else {
      return l10n.lateNight;
    }
  }

  String _getUserName([User? user]) {
    final currentUser = user ?? FirebaseAuth.instance.currentUser;
    if (currentUser != null &&
        currentUser.displayName != null &&
        currentUser.displayName!.isNotEmpty) {
      return currentUser.displayName!;
    }
    return 'kita'; // Default fallback
  }

  Widget _buildAvatar({User? user, double radius = 16}) {
    return Builder(
      builder: (context) {
        final currentUser = user ?? FirebaseAuth.instance.currentUser;
        ImageProvider? imageProvider;
        if (currentUser?.photoURL != null &&
            currentUser!.photoURL!.startsWith('assets/')) {
          imageProvider = AssetImage(currentUser.photoURL!);
        } else {
          imageProvider =
              const AssetImage('assets/images/reado_ip_1_reader.png');
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.transparent,
          backgroundImage: imageProvider,
        );
      },
    );
  }

  void _showCreateModuleDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        title: Text(AppLocalizations.of(context)!.createModule),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.moduleTitle,
                hintText: AppLocalizations.of(context)!.moduleTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.moduleDesc,
                hintText: AppLocalizations.of(context)!.moduleDescHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context); // Close dialog
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    throw Exception(l10n.errorLoginToCreate);
                  }

                  await ref.read(moduleProvider.notifier).createModule(
                        title,
                        descController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ ${l10n.successModuleCreated(title)}'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ ${l10n.errorCreateFailed}: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );
  }
}

class _ElegantMenuButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ElegantMenuButton({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44, // Reduced height for 3-up layout
        padding: const EdgeInsets.symmetric(horizontal: 4), // Tighter padding
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.8), // Glass-ish
          borderRadius: BorderRadius.circular(22), // Pill shape
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.white.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Circle
            Container(
              width: 32, // Smaller icon circle
              height: 32,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 8),
            // Text
            Text(
              title,
              style: TextStyle(
                fontSize: 13, // Smaller text
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF333333),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTabItem(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFFFFCC80) : const Color(0xFFEFE9E1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.bold,
                fontSize: 15,
                color: isSelected
                    ? (isDark ? const Color(0xFF3E2723) : Colors.black87)
                    : (isDark ? Colors.grey : Colors.grey[600]),
              ),
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFE65100) : Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
            )
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF1A237E)
              : (isDark ? Colors.white24 : Colors.white),
          shape: BoxShape.circle,
          boxShadow: [
            if (!isPrimary)
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? Colors.white
              : (isDark ? Colors.white : const Color(0xFF1A237E)),
          size: 24,
        ),
      ),
    );
  }
}

class _WideKnowledgeCard extends StatelessWidget {
  final String title;
  final String description;
  final double progress;
  final int cardCount;
  final bool isHighlighted;
  final ShareStats? shareStats;
  final VoidCallback onTap;

  const _WideKnowledgeCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.cardCount,
    this.isHighlighted = false,
    this.shareStats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Highlight colors（浅色用有层次的暖灰，与背景白区分）
    final cardHighlight = const Color(0xFFF8F6F3);
    final bg = isHighlighted
        ? (isDark
            ? const Color(0xFF3E2723)
            : cardHighlight)
        : (isDark ? Colors.white10 : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100, // Fixed height for consistency
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: isHighlighted
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            if (isHighlighted)
              BoxShadow(
                color: (isDark ? Colors.orange : Colors.grey).withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF2D2D2D),
                        ),
                      ),
                      if (isHighlighted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A65),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('RECENT',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '$cardCount items',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF8D6E63),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '·',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.white12
                                : const Color(0xFFEFEBE9),
                            color: const Color(0xFFFF8A65),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (shareStats != null &&
                      (shareStats!.viewCount > 0 ||
                          shareStats!.saveCount > 0 ||
                          shareStats!.likeCount > 0)) ...[
                    const SizedBox(height: 6),
                    Text(
                      L10nNumbers.shareStatsFormat(context, shareStats!.viewCount,
                          shareStats!.saveCount, shareStats!.likeCount),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF8D6E63).withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Right Arrow or Icon
            Icon(Icons.arrow_forward_ios,
                size: 14, color: isDark ? Colors.white30 : Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// 首页停留时每 15 秒刷新主人所有知识库的分享数据，列表上的浏览/保存/点赞会更新
class _HomeShareStatsRefresher extends ConsumerStatefulWidget {
  final String userId;
  final List<String> moduleIds;

  const _HomeShareStatsRefresher({
    required this.userId,
    required this.moduleIds,
  });

  @override
  ConsumerState<_HomeShareStatsRefresher> createState() => _HomeShareStatsRefresherState();
}

class _HomeShareStatsRefresherState extends ConsumerState<_HomeShareStatsRefresher> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timer == null && widget.moduleIds.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (!mounted) return;
        for (final moduleId in widget.moduleIds) {
          ref.invalidate(shareStatsProvider((widget.userId, moduleId)));
        }
      });
    }
    return const SizedBox.shrink();
  }
}
