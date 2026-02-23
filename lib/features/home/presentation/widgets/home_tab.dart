import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async'; // Add async import for StreamSubscription
import 'package:firebase_auth/firebase_auth.dart';
import '../../../feed/presentation/feed_provider.dart';
import '../../../../models/feed_item.dart';
import '../../../../models/knowledge_module.dart';
import '../module_provider.dart';
import '../../../lab/presentation/add_material_modal.dart';
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

  void _startTutorialStep(String type) {
    setState(() {
      if (type == 'text') {
        _tutorialText = '点击 [AI 拆解] 按钮开启智能学习之旅';
        _tutorialTargetKey = _aiDeconstructKey;
      } else if (type == 'task_center') {
        _tutorialText =
            '可以在这里看到正在后台进行的任务。等待任务生成好后，可以回到你刚刚所在的知识库（例如：个人 > 默认知识库），点击进去即可学习。';
        _tutorialTargetKey = _taskCenterKey;
      } else if (type == 'multimodal') {
        _tutorialText = '多模态解析也从这里开始，点击 [AI 拆解] 并切换标签页';
        _tutorialTargetKey = _aiDeconstructKey;
      } else if (type == 'all_cards') {
        _tutorialText = '点击一个知识库，跳转到学习页面，点击右上角的【全部】按钮即可查看该知识库的全部知识卡片。';
        _tutorialTargetKey = _starModuleKey;
      } else if (type == 'ai_notes') {
        _tutorialText = '点击 [AI 笔记] 查看所有聚合笔记。';
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
                            label: '官方',
                            isSelected: filterIndex == 0,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 0),
                        _FilterTabItem(
                            label: '个人',
                            isSelected: filterIndex == 1,
                            onTap: () => ref
                                .read(_homeModuleFilterProvider.notifier)
                                .state = 1),
                        _FilterTabItem(
                            label: '最近在学',
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
                                Text('这里空空如也',
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
                                    return _buildModuleCard(
                                      context,
                                      displayedModules[index],
                                      feedItems,
                                      index == 0,
                                      onboardingState,
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
                                  return _buildModuleCard(
                                    context,
                                    displayedModules[index],
                                    feedItems,
                                    index == 0,
                                    onboardingState,
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
                              _getGreeting(),
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
                            _buildSimpleQuote(isDark, feedItems.length),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20), // Wider gap
                      Hero(
                        tag: 'home_avatar',
                        child: GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
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
                          title: 'AI 拆解',
                          icon: Icons.auto_awesome,
                          color: const Color(0xFFFF5252),
                          bgColor: const Color(0xFFFFEBEE),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AddMaterialModal(
                                isTutorialMode:
                                    onboardingState.isTutorialActive,
                                tutorialStep: _tutorialTargetKey ==
                                        _aiDeconstructKey
                                    ? (_tutorialText?.contains('多模态') ?? false
                                        ? 'multimodal'
                                        : 'text')
                                    : null,
                              ),
                            ).then((_) {
                              if (mounted && _tutorialText != null) {
                                setState(() {
                                  _tutorialText = null;
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
                          title: 'AI 笔记',
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
                              title: '任务中心',
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
                              hintText: '搜索知识...',
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
                _tutorialTargetKey = null;
              }),
            ),
          OnboardingChecklist(
            onStartTextTutorial: () => _startTutorialStep('text'),
            onStartTaskCenterTutorial: () => _startTutorialStep('task_center'),
            onStartMultiTutorial: () => _startTutorialStep('multimodal'),
            onStartAllCardsTutorial: () => _startTutorialStep('all_cards'),
            onStartAiNotesTutorial: () =>
                _startTutorialStep('ai_notes'), // Added this line
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
    OnboardingState onboardingState,
  ) {
    final mItems =
        feedItems.where((i) => i.moduleId == module.id).toList();
    final count = mItems.length;
    final learned = mItems
        .where(
            (i) => i.masteryLevel != FeedItemMastery.unknown)
        .length;
    final progress = count > 0 ? learned / count : 0.0;
    final isStarModule = module.title.contains('STAR');

    return _WideKnowledgeCard(
      key: isStarModule ? _starModuleKey : null,
      title: module.title,
      description: module.description,
      progress: progress,
      cardCount: count,
      isHighlighted: isHighlighted,
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

  Widget _buildSimpleQuote(bool isDark, int totalItems) {
    final quotes = [
      '今天学了吗？你这个囤囤鼠 🐹',
      '卷又卷不赢，躺又躺不平？那就学一点点吧 📖',
      '你的大脑正在渴望新的知识，快喂喂它 💡',
      '现在的努力，是为了以后能理直气壮地摸鱼 🐟',
      '碎片时间也是时间，哪怕入脑一个点也是赚到 ✨',
      '知识入脑带来的多巴胺，比短视频香多了 🧠',
      '先去电脑端批量拆解，再躺在床上刷知识 🛏️',
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '早上好';
    } else if (hour >= 12 && hour < 18) {
      return '下午好';
    } else if (hour >= 18 && hour < 22) {
      return '晚上好';
    } else {
      return '夜深了';
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
        title: const Text('创建知识库'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '例如：面试准备',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '这个知识库是关于什么的？',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                Navigator.pop(context); // Close dialog
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    throw Exception('请先登录以创建您的专属知识库');
                  }

                  await ref.read(moduleProvider.notifier).createModule(
                        title,
                        descController.text.trim(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ 知识库 "$title" 已准备就绪!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ 创建失败: $e'),
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
            child: const Text('创建'),
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
  final VoidCallback onTap;

  const _WideKnowledgeCard({
    super.key,
    required this.title,
    required this.description,
    required this.progress,
    required this.cardCount,
    this.isHighlighted = false,
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
