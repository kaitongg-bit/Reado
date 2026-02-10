import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import '../../../models/knowledge_module.dart';
import 'module_provider.dart';
import 'home_page.dart'; // Import for homeTabControlProvider
import '../../lab/presentation/add_material_modal.dart';
import '../../../../core/providers/credit_provider.dart';

class ModuleDetailPage extends ConsumerStatefulWidget {
  final String moduleId;
  final String? ownerId; // 🆕 Added ownerId for shared content

  const ModuleDetailPage({super.key, required this.moduleId, this.ownerId});

  @override
  ConsumerState<ModuleDetailPage> createState() => _ModuleDetailPageState();
}

class _ModuleDetailPageState extends ConsumerState<ModuleDetailPage> {
  bool _isLoading = false;
  String? _errorMessage;
  KnowledgeModule? _sharedModule; // 🆕 Store fetched shared module metadata

  @override
  void initState() {
    super.initState();
    // Check if we need to load shared content
    // Load if ownerId is provided OR if it's an official module (for guests)
    final bool isOfficial = ['A', 'B', 'C', 'D'].contains(widget.moduleId);
    if (widget.ownerId != null || isOfficial) {
      _loadSharedContent();
    }
  }

  Future<void> _loadSharedContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Module Metadata (if not official)
      final bool isOfficial = ['A', 'B', 'C', 'D'].contains(widget.moduleId);
      if (!isOfficial && widget.ownerId != null) {
        final module = await ref
            .read(dataServiceProvider)
            .fetchModuleDetail(widget.ownerId!, widget.moduleId);
        if (mounted) {
          setState(() => _sharedModule = module);
        }
      }

      // 2. Fetch Feed Items
      final count = await ref
          .read(feedProvider.notifier)
          .loadSharedModule(widget.moduleId, widget.ownerId ?? 'official');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (count == 0) {
            _errorMessage = "未找到内容。可能是链接无效，或者您没有权限访问此私有知识库。";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "加载失败: ${e.toString()}\n请确保分享者已开启相关权限。";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载分享的内容...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('出错了')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moduleState = ref.watch(moduleProvider);
    final feedItems = ref.watch(allItemsProvider);

    // Find the module
    // If it's a shared module, it might not be in moduleState (which only has mine and official).
    // So if not found, we use the fetched _sharedModule or a placeholder.
    final module = [...moduleState.officials, ...moduleState.custom]
        .firstWhere((m) => m.id == widget.moduleId,
            orElse: () =>
                _sharedModule ??
                KnowledgeModule(
                  id: widget.moduleId,
                  title: '📑 正在加载分享内容...', // Placeholder while loading
                  description: '请稍候，我们正在为您加载云端内容',
                  ownerId: widget.ownerId ?? 'unknown',
                  isOfficial: false,
                ));

    // Get module items
    // Re-filter specifically for this moduleId to ensure consistency
    final moduleItems =
        feedItems.where((item) => item.moduleId == widget.moduleId).toList();
    final cardCount = moduleItems.length;
    final learned = moduleItems
        .where((i) => i.masteryLevel != FeedItemMastery.unknown)
        .length;
    final progress = cardCount > 0 ? learned / cardCount : 0.0;

    // Get current progress for this module
    final currentProgress = ref.watch(feedProgressProvider);
    final currentModuleIndex = currentProgress[widget.moduleId] ?? 0;

    final user = FirebaseAuth.instance.currentUser; // 🆕 Check current user

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
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
                  if (user != null) // Only show share action if logged in
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // 1. 生成专属链接
                        // 生产环境使用实际域名，开发环境使用 window.location.origin
                        final String baseUrl = html.window.location.origin;
                        // 显式添加 /#/ 以确保 Web Hash 模式下的路由匹配
                        // 🆕 关键修复：添加 ownerId 参数
                        final ownerParam = widget.ownerId != null
                            ? "&ownerId=${widget.ownerId}"
                            : "&ownerId=${user.uid}";

                        final String shareUrl =
                            "$baseUrl/#/module/${widget.moduleId}?ref=${user.uid}$ownerParam";

                        // 2. 复制到剪贴板
                        Clipboard.setData(ClipboardData(
                            text: '嘿！我正在使用 Reado 学习这个超棒的知识库，快来看看：\n$shareUrl'));

                        // 3. 奖励积分 (动作奖励)
                        ref
                            .read(creditProvider.notifier)
                            .rewardShare(amount: 10);

                        // 4. 显示提示
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.stars, color: Color(0xFFFFB300)),
                                    SizedBox(width: 8),
                                    Text('分享成功！获得 10 积分动作奖励 🎁'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('当好友通过您的链接加入时，您将再获得 50 积分！',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('专属链接已复制: $shareUrl',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  if (user != null) // Only show menu if logged in
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'delete' || value == 'hide') {
                          final isHide = value == 'hide';
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(isHide ? '隐藏此知识库？' : '彻底删除知识库？'),
                              content: Text(isHide
                                  ? '知识库将被隐藏，您可以在“个人中心 - 隐藏的内容”中恢复。'
                                  : '警告：此操作不可逆！该知识库及其包含的所有知识点将永久移除。'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(isHide ? '隐藏' : '彻底删除',
                                      style:
                                          const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            if (isHide) {
                              // Logic to hide (even if custom)
                              await ref
                                  .read(dataServiceProvider)
                                  .hideOfficialModule(
                                      user.uid, widget.moduleId);
                              ref.read(moduleProvider.notifier).refresh();
                            } else {
                              await ref
                                  .read(moduleProvider.notifier)
                                  .deleteModule(widget.moduleId);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(isHide ? '已隐藏知识库' : '已删除知识库')),
                              );
                              context.pop();
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'hide',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off_outlined,
                                  color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text('隐藏',
                                  style: TextStyle(color: Colors.orange)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('永久删除', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
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
                    module.title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    module.description,
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
                      _buildTag('$cardCount 张卡片', isDark),
                      _buildTag(module.isOfficial ? '官方' : '私有', isDark),
                      _buildTag('${(progress * 100).toInt()}% 已掌握', isDark),
                    ],
                  ),
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
                                .where(
                                    (item) => item.moduleId == widget.moduleId)
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
                                .setActiveModule(widget.moduleId);

                            // 4. Set progress to the random index
                            ref
                                .read(feedProgressProvider.notifier)
                                .setProgress(widget.moduleId, targetIndex);

                            // 5. Switch to Feed tab via provider
                            ref.read(homeTabControlProvider.notifier).state = 1;

                            // 6. Go to FeedPage directly
                            final ownerParam = widget.ownerId != null
                                ? '?ownerId=${widget.ownerId}'
                                : '';
                            context.push('/feed/${widget.moduleId}$ownerParam');
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('开始学习',
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
                      if (user != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFCDFF64),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AddMaterialModal(
                                    targetModuleId: widget.moduleId),
                              );
                            },
                            icon: const Icon(Icons.add, color: Colors.black),
                            iconSize: 28,
                          ),
                        ),
                      ],
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
      bool isDark, WidgetRef ref, bool isCurrentlyViewing) {
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

    return GestureDetector(
      onTap: () {
        // Save the active module and card index
        ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(item.moduleId);
        ref
            .read(feedProgressProvider.notifier)
            .setProgress(item.moduleId, index);

        // Switch HomePage tab to Feed (index 1)
        ref.read(homeTabControlProvider.notifier).state = 1;

        // Navigate directly to FeedPage
        final ownerParam =
            widget.ownerId != null ? '?ownerId=${widget.ownerId}' : '';
        context.push('/feed/${item.moduleId}$ownerParam');
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
            // Arrow / Actions
            if (FirebaseAuth.instance.currentUser !=
                null) // Only allow actions for logged in users
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
                  if (value == 'delete' || value == 'hide') {
                    final isHide = value == 'hide';
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(isHide ? '隐藏此知识卡？' : '删除知识卡？'),
                        content:
                            Text(isHide ? '知识卡将被隐藏，可以在设置中恢复。' : '删除后无法恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(isHide ? '隐藏' : '删除',
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
                        SnackBar(content: Text(isHide ? '已隐藏知识卡' : '已移除知识卡')),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'hide',
                    height: 32,
                    child: Text('隐藏',
                        style: TextStyle(fontSize: 13, color: Colors.orange)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    height: 32,
                    child: Text('永久删除',
                        style: TextStyle(fontSize: 13, color: Colors.red)),
                  ),
                ],
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
