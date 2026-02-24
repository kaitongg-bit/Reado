import 'dart:async';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/feed_item.dart';
import '../feed_provider.dart';
import '../../../../core/providers/adhd_provider.dart';
import '../../../../core/providers/adhd_text_transformer.dart';

/// 解析「原味保存」的对话记录："我: ...\n\n囤囤鼠: ..." -> [{isUser, text}, ...]
List<({bool isUser, String text})> _parseConversationNote(String raw) {
  final list = <({bool isUser, String text})>[];
  final segments = raw.split(RegExp(r'\n\n+'));
  for (final s in segments) {
    final trimmed = s.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('我:')) {
      list.add((isUser: true, text: trimmed.replaceFirst(RegExp(r'^我:\s*'), '').trim()));
    } else if (trimmed.startsWith('囤囤鼠:')) {
      list.add((isUser: false, text: trimmed.replaceFirst(RegExp(r'^囤囤鼠:\s*'), '').trim()));
    } else if (list.isNotEmpty) {
      // 续行接到上一条
      final last = list.removeLast();
      list.add((isUser: last.isUser, text: '${last.text}\n\n$trimmed'));
    }
  }
  return list;
}

bool _isConversationNote(UserNotePage content) {
  return content.question == '对话记录' ||
      content.answer.contains('囤囤鼠:') ||
      content.answer.contains('我:');
}

class FeedItemView extends ConsumerStatefulWidget {
  final FeedItem feedItem;
  final bool isReviewMode;
  /// 分享知识库只读模式：不展示 Ask AI、Pin、编辑等
  final bool isSharedReadOnly;
  /// 正文原位编辑：为 true 时在 editingPageIndex 页显示编辑框
  final bool isEditingBody;
  final TextEditingController? bodyEditController;
  final int? editingPageIndex;

  const FeedItemView({
    super.key,
    required this.feedItem,
    this.isReviewMode = false,
    this.isSharedReadOnly = false,
    this.isEditingBody = false,
    this.bodyEditController,
    this.editingPageIndex,
    this.onNextTap,
    this.onViewModeChanged,
  });

  final VoidCallback? onNextTap;
  final ValueChanged<bool>? onViewModeChanged;

  @override
  ConsumerState<FeedItemView> createState() => _FeedItemViewState();
}

class _FeedItemViewState extends ConsumerState<FeedItemView> {
  final PageController _horizontalController = PageController();
  int _currentPageIndex = 0;

  // Editing State
  bool _isEditing = false;
  UserNotePage? _editingNote;
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  /// 收藏后是否显示「熟练/一般/生疏」快捷标注（点击即隐藏）
  bool _showMasteryQuickPick = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FeedItemView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect if a new page was added (e.g. Note pinned)
    if (widget.feedItem.pages.length > oldWidget.feedItem.pages.length) {
      // Scroll to the new page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_horizontalController.hasClients) {
          _horizontalController.animateToPage(
            widget.feedItem.pages.length - 1,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
    // 进入正文编辑时滚动到该页，便于用户看到编辑框
    if (widget.isEditingBody &&
        widget.editingPageIndex != null &&
        _currentPageIndex != widget.editingPageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_horizontalController.hasClients) {
          _currentPageIndex = widget.editingPageIndex!;
          _horizontalController.animateToPage(
            widget.editingPageIndex!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _showAskAISheet(BuildContext context) {
    if (widget.isSharedReadOnly) {
      _showAskAISheetShared(context);
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AskAISheet(
        feedItem: widget.feedItem,
        onPin: (question, answer) {
          ref.read(feedProvider.notifier).pinNoteToItem(
                widget.feedItem.id,
                question,
                answer,
              );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✨ 笔记已置顶成功！'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green[600],
            ),
          );
        },
      ),
    );
  }

  void _showAskAISheetShared(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AskAISheet(
        feedItem: widget.feedItem,
        onPin: (question, answer) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _showLoginDialogForPin(context);
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('分享内容暂不支持保存笔记到当前卡片'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showLoginDialogForPin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存笔记需要登录'),
        content: const Text(
            '登录后可将笔记保存到自己的知识库。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('暂不'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/onboarding');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialogForFavorite(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('收藏需要登录'),
        content: const Text('是否前往登录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('暂不'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/onboarding');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  void _onFavoriteTap() {
    if (widget.isSharedReadOnly) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showLoginDialogForFavorite(context);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('分享内容暂不支持收藏到复习区'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _toggleFavorite();
  }

  void _toggleFavorite() {
    final wasFavorited = widget.feedItem.isFavorited;
    ref.read(feedProvider.notifier).toggleFavorite(widget.feedItem.id);
    final isFavorited = !wasFavorited;
    setState(() => _showMasteryQuickPick = isFavorited);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorited ? '✨ 已收藏到复习区' : '已取消收藏'),
        duration: const Duration(seconds: 1),
        backgroundColor: isFavorited ? Colors.green[600] : Colors.grey[600],
      ),
    );
  }

  void _setMasteryAndHide(FeedItemMastery level) {
    final levelStr = level.name;
    ref.read(feedProvider.notifier).updateMastery(widget.feedItem.id, levelStr);
    setState(() => _showMasteryQuickPick = false);
    final label = level == FeedItemMastery.easy
        ? '熟练'
        : (level == FeedItemMastery.medium ? '一般' : '生疏');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已标记为 $label'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  void _handleDeleteNote(UserNotePage note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记？'),
        content: const Text('确定要删除这个置顶笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(feedProvider.notifier)
                  .deleteUserNote(widget.feedItem.id, note);
              Navigator.pop(context);
              // Scroll back if needed? PageView count changes automatically
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleEditNote(UserNotePage note) {
    setState(() {
      _isEditing = true;
      _editingNote = note;
      _titleController.text = note.question;
      _contentController.text = note.answer;
    });
  }

  void _cancelEditNote() {
    setState(() {
      _isEditing = false;
      _editingNote = null;
    });
  }

  void _saveEditNote() {
    if (_editingNote == null) return;
    ref.read(feedProvider.notifier).updateUserNote(
          widget.feedItem.id,
          _editingNote!,
          _titleController.text,
          _contentController.text,
        );
    _cancelEditNote();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.feedItem.pages;
    final userNoteCount = pages.whereType<UserNotePage>().length;
    // Check if current page index is valid (items might be deleted)
    if (_currentPageIndex >= pages.length) _currentPageIndex = 0;

    final isViewingNote = pages[_currentPageIndex] is UserNotePage;

    return Stack(
      children: [
        // 1. Horizontal PageView
        PageView.builder(
          controller: _horizontalController,
          itemCount: pages.length,
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
            // Notify parent to lock/unlock vertical nav
            final isNote = pages[index] is UserNotePage;
            widget.onViewModeChanged?.call(isNote);
          },
          itemBuilder: (context, index) {
            final pageContent = pages[index];
            if (widget.isEditingBody &&
                widget.editingPageIndex != null &&
                index == widget.editingPageIndex &&
                widget.bodyEditController != null) {
              return _buildBodyEditor();
            }
            return _buildPageContent(pageContent);
          },
        ),

        // 2. Progress Dots (Xiaohongshu Style)
        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (index) {
              final isSelected = index == _currentPageIndex;
              final isUserNote = pages[index] is UserNotePage;
              final currentPageIsNote =
                  pages[_currentPageIndex] is UserNotePage;

              // On note pages, make unselected dots more visible
              final unselectedOpacity = currentPageIsNote ? 0.6 : 0.35;

              return Container(
                width: isSelected ? 8 : 6,
                height: isSelected ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? (isUserNote ? Colors.amber : Colors.white)
                      : (currentPageIsNote
                          ? Colors.amber.withOpacity(unselectedOpacity)
                          : Colors.white.withOpacity(unselectedOpacity)),
                ),
              );
            }),
          ),
        ),

        // 3. User Notes Badge
        if (userNoteCount > 0 && !isViewingNote)
          Positioned(
            top: 130, // Below header
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.orange.withOpacity(0.5), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.push_pin, size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    '$userNoteCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 3. Action Bar（分享只读也展示：笔记入口、收藏、囤囤鼠；收藏/Pin 时游客弹窗提示登录）
        Positioned(
          right: 16,
          bottom: 110,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 收藏后冒出的「熟练 / 一般 / 生疏」快捷标注
              if (_showMasteryQuickPick) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _masteryChip('熟练', FeedItemMastery.easy),
                      const SizedBox(width: 6),
                      _masteryChip('一般', FeedItemMastery.medium),
                      const SizedBox(width: 6),
                      _masteryChip('生疏', FeedItemMastery.hard),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildActionButton(
                icon: widget.feedItem.isFavorited
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.feedItem.isFavorited
                    ? Colors.redAccent
                    : Colors.white,
                onTap: _onFavoriteTap,
              ),
              const SizedBox(height: 16),
              if (widget.feedItem.pages.length > 1) ...[
                _buildActionButton(
                  icon: Icons.note_alt_outlined,
                  color: Colors.white,
                  onTap: () {
                    if (_horizontalController.hasClients) {
                      _horizontalController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
              _buildActionButton(
                customChild: Padding(
                  padding: const EdgeInsets.all(
                      8.0),
                  child: SvgPicture.asset(
                    'assets/images/reado_traced.svg',
                  ),
                ),
                isPrimary: true,
                onTap: () => _showAskAISheet(context),
              ),
            ],
          ),
        ),

        // 4. "Next Topic" Button - 分享只读也显示，与学习页一致
        if (!widget.isReviewMode && !isViewingNote)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  widget.onNextTap?.call();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15), width: 1)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('下一节',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 原味保存的对话记录渲染为左右气泡（我右 / 囤囤鼠左）
  List<Widget> _buildConversationBubbles(
      BuildContext context, String answer, bool isDark) {
    final items = _parseConversationNote(answer);
    if (items.isEmpty) {
      return [
        SelectableText(
          answer,
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
            color: isDark
                ? Theme.of(context).colorScheme.onSurface
                : Colors.black87,
          ),
        ),
      ];
    }
    final textColorUser = Colors.white;
    final textColorAi = isDark
        ? Colors.white.withOpacity(0.9)
        : Colors.black87;
    final bubbleColorUser = isDark ? const Color(0xFF9333EA) : Colors.black;
    final bubbleColorAi =
        isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]!;
    return items.map<Widget>((e) {
      final isUser = e.isUser;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) const SizedBox(width: 40),
            Flexible(
              child: Container(
                margin: EdgeInsets.only(
                    left: isUser ? 40 : 0, right: isUser ? 16 : 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? bubbleColorUser : bubbleColorAi,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                ),
                child: isUser
                    ? SelectableText(
                        e.text,
                        style: TextStyle(
                            color: textColorUser, height: 1.5),
                      )
                    : MarkdownBody(
                        data: e.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context))
                            .copyWith(
                          p: TextStyle(
                              color: textColorAi,
                              height: 1.5,
                              fontFamily: 'JinghuaSong'),
                          strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'JinghuaSong'),
                        ),
                      ),
              ),
            ),
            if (isUser) const SizedBox(width: 40),
          ],
        ),
      );
    }).toList();
  }

  /// 可读性最佳实践：宽屏时限制内容最大宽度，左右边距随窗口加宽而增加（类似 Gemini 等）
  static const double _kReadableContentMaxWidth = 720.0;
  static const double _kMinHorizontalPadding = 24.0;

  EdgeInsets _responsiveContentPadding(BoxConstraints constraints,
      {required double top, required double bottom}) {
    final contentMaxWidth = constraints.maxWidth > _kReadableContentMaxWidth + _kMinHorizontalPadding * 2
        ? _kReadableContentMaxWidth
        : (constraints.maxWidth - _kMinHorizontalPadding * 2);
    final horizontal = (constraints.maxWidth - contentMaxWidth) / 2;
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  Widget _buildPageContent(CardPageContent content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final adhdSettings = ref.watch(adhdSettingsProvider);

    // Base Glass Style for the Page
    final backgroundColor =
        isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.85);

    if (content is OfficialPage) {
      return Container(
        color: backgroundColor, // Semi-transparent base
        child: SelectionArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentPadding = _responsiveContentPadding(constraints,
                  top: 88, bottom: 140);
              return ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: contentPadding,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - contentPadding.vertical + 1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // No redundant header here

                        DefaultTextStyle(
                          style: TextStyle(
                              fontFamily: 'JinghuaSong',
                              color: Theme.of(context).colorScheme.onSurface),
                          child: MarkdownBody(
                            data: content.markdownContent,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(Theme.of(context))
                                    .copyWith(
                              h1: TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  letterSpacing: -0.5,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              h2: TextStyle(
                                fontFamily: 'JinghuaSong',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.5,
                              ),
                              h3: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                              h4: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                              h5: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                              h6: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                              p: TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontSize: 18,
                                  height: 1.8,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.9),
                                  letterSpacing: 0.2),
                              listBullet: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                              strong: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontWeight: FontWeight.bold),
                              em: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  fontStyle: FontStyle.italic),
                              blockquote: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  color: Colors.grey),
                              code: const TextStyle(
                                  fontFamily: 'JinghuaSong',
                                  backgroundColor: Colors.transparent),
                              codeblockPadding: const EdgeInsets.all(8),
                              codeblockDecoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white10
                                    : Colors.grey[200],
                              ),
                            ),
                            builders: adhdSettings.isEnabled
                                ? {
                                    'p': AdhdMarkdownParagraphBuilder(
                                      adhdSettings: adhdSettings,
                                    ),
                                    'li': AdhdMarkdownParagraphBuilder(
                                      adhdSettings: adhdSettings,
                                    ),
                                    'blockquote': AdhdMarkdownParagraphBuilder(
                                      adhdSettings: adhdSettings,
                                    ),
                                    'h1': AdhdMarkdownParagraphBuilder(
                                      adhdSettings: adhdSettings,
                                    ),
                                    'h2': AdhdMarkdownParagraphBuilder(
                                      adhdSettings: adhdSettings,
                                    ),
                                    'h3': AdhdMarkdownParagraphBuilder(
                                      adhdSettings: adhdSettings,
                                    ),
                                  }
                                : {},
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Dynamic Flashcard Section
                        if (content.flashcardQuestion != null) ...[
                          _FlashcardWidget(
                            question: content.flashcardQuestion!,
                            answer: content.flashcardAnswer ?? '',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 40),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else if (content is UserNotePage) {
      // 笔记区与正文一致：窄屏最小 24 边距，宽屏随窗口加宽
      const noteTop = 88.0;
      const noteBottom = 0.0;

      // In-Place Editing Mode
      if (_isEditing && _editingNote == content) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final padding = _responsiveContentPadding(constraints,
                top: noteTop, bottom: 24);
            return Container(
              color: isDark ? const Color(0xFF2C2518) : const Color(0xFFFFFBE6),
              padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('编辑笔记',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JinghuaSong',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  labelText: '主题 / 问题',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontFamily: 'JinghuaSong',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    labelText: '笔记内容',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelEditNote,
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveEditNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A65),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        );
          },
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final notePadding = _responsiveContentPadding(constraints,
              top: noteTop, bottom: noteBottom);
          return Container(
            color: isDark
                ? const Color(0xFF2C2518) // Dark mode: Warmer dark grey
                : const Color(0xFFFFFBE6), // Light mode: Soft yellowish paper
            padding: notePadding,
            child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact header
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            widget.feedItem.id == 'b002'
                                ? Icons.verified_outlined
                                : Icons.push_pin,
                            color: Colors.amber,
                            size: 14),
                        const SizedBox(width: 6),
                        Text(widget.feedItem.id == 'b002' ? 'AI 官方指南' : 'AI 笔记',
                            style: TextStyle(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),

                  const Spacer(),
                  // Direct Action Buttons（分享只读模式下不展示）
                  if (!content.isReadOnly && !widget.isSharedReadOnly)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 20, color: Colors.grey),
                          tooltip: '编辑笔记',
                          onPressed: () => _handleEditNote(content),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              size: 20, color: Colors.redAccent),
                          tooltip: '删除笔记',
                          onPressed: () => _handleDeleteNote(content),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: const Text('官方精选',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                content.question,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JinghuaSong', // Custom Font
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3),
              ),
              const SizedBox(height: 20),
              Divider(
                  height: 1,
                  color:
                      isDark ? Colors.white24 : Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      if (_isConversationNote(content)) ...[
                        ..._buildConversationBubbles(
                            context, content.answer, isDark),
                      ] else
                        MarkdownBody(
                          data: content.answer,
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(Theme.of(context))
                                  .copyWith(
                            p: TextStyle(
                              fontSize: 18,
                              height: 1.8,
                              fontFamily: 'JinghuaSong',
                              color: isDark
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.9)
                                  : Colors.black87.withOpacity(0.85),
                            ),
                            h1: const TextStyle(
                                fontFamily: 'JinghuaSong',
                                fontWeight: FontWeight.bold),
                            h2: const TextStyle(
                                fontFamily: 'JinghuaSong',
                                fontWeight: FontWeight.bold),
                            h3: const TextStyle(
                                fontFamily: 'JinghuaSong',
                                fontWeight: FontWeight.bold),
                            listBullet: TextStyle(
                                fontFamily: 'JinghuaSong',
                                color: isDark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7)
                                    : Colors.black87),
                            strong: const TextStyle(
                                fontFamily: 'JinghuaSong',
                                fontWeight: FontWeight.bold),
                            em: const TextStyle(
                                fontFamily: 'JinghuaSong',
                                fontStyle: FontStyle.italic),
                          ),
                          builders: adhdSettings.isEnabled
                              ? {
                                  'p': AdhdMarkdownParagraphBuilder(
                                    adhdSettings: adhdSettings,
                                  ),
                                  'li': AdhdMarkdownParagraphBuilder(
                                    adhdSettings: adhdSettings,
                                  ),
                                  'blockquote': AdhdMarkdownParagraphBuilder(
                                    adhdSettings: adhdSettings,
                                  ),
                                }
                              : {},
                        ),
                      const SizedBox(height: 48),
                      // "Swipe Left to Return" Hint
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back,
                              size: 14,
                              color: isDark ? Colors.white54 : Colors.black45),
                          const SizedBox(width: 6),
                          Text(
                            '左滑回到正文',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'JinghuaSong',
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
        },
      );
    }
    return const SizedBox.shrink();
  }

  /// 正文原位编辑：与 OfficialPage 同区域、同 padding 的多行输入
  Widget _buildBodyEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.85);
    final c = widget.bodyEditController!;
    return Container(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentPadding = _responsiveContentPadding(constraints,
              top: 88, bottom: 140);
          return SingleChildScrollView(
            padding: contentPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    constraints.maxHeight - contentPadding.vertical + 1,
              ),
              child: SizedBox(
                height: constraints.maxHeight - contentPadding.vertical,
                child: TextField(
                  controller: c,
                  style: TextStyle(
                    fontFamily: 'JinghuaSong',
                    fontSize: 18,
                    height: 1.8,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: '输入正文（支持 Markdown）',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _masteryChip(String label, FeedItemMastery level) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _setMasteryAndHide(level),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    Widget? customChild,
    // Removed label required
    required VoidCallback onTap,
    bool isPrimary = false,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: isPrimary
                ? const Color(0xFFFF8A65) // Orange/Coral
                : Colors.black.withOpacity(0.3), // Changed primary to Orange
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        alignment: Alignment.center,
        child: customChild ?? Icon(icon, color: color, size: 24),
      ),
    );
  }
}

/// ADHD 专用 Markdown 段落构建器
class AdhdMarkdownParagraphBuilder extends MarkdownElementBuilder {
  final AdhdSettings adhdSettings;

  AdhdMarkdownParagraphBuilder({required this.adhdSettings});

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    if (!adhdSettings.isEnabled || preferredStyle == null) return null;

    return RichText(
      text: TextSpan(
        children: AdhdTextTransformer.transform(
          text.text,
          preferredStyle,
          adhdSettings,
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class _AskAISheet extends ConsumerStatefulWidget {
  final FeedItem feedItem;
  final Function(String q, String a) onPin;

  const _AskAISheet({required this.feedItem, required this.onPin});

  @override
  ConsumerState<_AskAISheet> createState() => _AskAISheetState();
}

class _AskAISheetState extends ConsumerState<_AskAISheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  // 多选逻辑：点击顶部 Pin 进入多选模式，再点消息/勾选框选择
  bool _isPinMode = false;
  final Set<int> _selectedMessageIndices = {};
  bool get _isSelectionMode => _isPinMode;

  // 已 Pin 标记
  final Set<int> _pinnedMessageIndices = {};

  bool _isLoading = false;
  bool _isSummarizing = false;
  bool _isLoadingHistory = true;

  // 等待期间轮换的占位提示（按时间切换，减轻前端负担）
  Timer? _placeholderTimer;
  int _placeholderIndex = 0;
  static const _placeholderInterval = Duration(seconds: 5);
  static const _loadingPlaceholders = [
    '正在思考中...',
    '马上生成好...',
    '快好了...',
  ];

  /// 无对话时的预设问题（通俗易懂，点击即填入并发送，不调用 LLM）
  static const List<String> _presetQuestions = [
    '举个例子讲解一下',
    '用简单的话总结一下',
    '这段在说什么？',
    '有什么重点？',
    '能再解释得通俗一点吗？',
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }
    try {
      final dataService = ref.read(dataServiceProvider);
      final stored =
          await dataService.fetchAiChatHistory(user.uid, widget.feedItem.id);
      if (!mounted) return;
      final loaded = <_ChatMessage>[];
      for (final m in stored) {
        final role = m['role'] as String? ?? 'user';
        final content = m['content'] as String? ?? '';
        final tsStr = m['timestamp'] as String?;
        final ts = tsStr != null
            ? (DateTime.tryParse(tsStr) ?? DateTime.now())
            : DateTime.now();
        loaded.add(_ChatMessage(
          content: content,
          isUser: role == 'user',
          timestamp: ts,
        ));
      }
      setState(() {
        _messages.addAll(loaded);
        _isLoadingHistory = false;
      });
      if (loaded.isNotEmpty) _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final dataService = ref.read(dataServiceProvider);
      final payload = _messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'content': m.content,
                'timestamp': m.timestamp.toIso8601String(),
              })
          .toList();
      await dataService.saveAiChatHistory(user.uid, widget.feedItem.id, payload);
    } catch (e) {
      // 静默失败，不打扰用户
    }
  }

  String _getContextContent() {
    return widget.feedItem.pages
        .whereType<OfficialPage>()
        .map((p) => p.markdownContent)
        .join('\n\n');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _placeholderTimer?.cancel();
    _placeholderTimer = null;

    setState(() {
      _messages.add(_ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();
    _saveChatHistory(); // 立即保存用户消息

    final aiTimestamp = DateTime.now();
    _placeholderIndex = 0;
    final initialPlaceholder = _loadingPlaceholders[0];

    setState(() {
      _messages.add(_ChatMessage(
        content: initialPlaceholder,
        isUser: false,
        timestamp: aiTimestamp,
      ));
    });
    _scrollToBottom();

    void switchPlaceholder() {
      if (!mounted || !_isLoading) return;
      _placeholderIndex =
          (_placeholderIndex + 1) % _loadingPlaceholders.length;
      final next = _loadingPlaceholders[_placeholderIndex];
      setState(() {
        if (_messages.isNotEmpty) {
          _messages[_messages.length - 1] = _ChatMessage(
            content: next,
            isUser: false,
            timestamp: aiTimestamp,
          );
        }
      });
    }

    _placeholderTimer = Timer.periodic(_placeholderInterval, (_) => switchPlaceholder());

    try {
      // 请求时排除当前占位消息，避免把「正在思考中」当作已发送的回复
      final listForHistory = _isLoading && _messages.length > 1
          ? _messages.sublist(0, _messages.length - 1)
          : _messages;
      final history = listForHistory
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'content': m.content,
              })
          .toList();

      final stream = ref
          .read(contentGeneratorProvider)
          .chatWithContentStream(_getContextContent(), history);

      final buffer = StringBuffer();
      await for (final chunk in stream) {
        if (!mounted) return;
        buffer.write(chunk);
      }

      if (!mounted) return;
      _placeholderTimer?.cancel();
      _placeholderTimer = null;
      final fullResponse = buffer.toString();
      setState(() {
        _isLoading = false;
        _messages[_messages.length - 1] = _ChatMessage(
          content: fullResponse.isEmpty ? '（暂无回复）' : fullResponse,
          isUser: false,
          timestamp: aiTimestamp,
        );
      });
      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _placeholderTimer?.cancel();
      _placeholderTimer = null;
      setState(() {
        _isLoading = false;
        _messages[_messages.length - 1] = _ChatMessage(
          content: 'Sorry, I encountered an error: $e',
          isUser: false,
          timestamp: aiTimestamp,
        );
      });
      _saveChatHistory();
      _scrollToBottom();
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedMessageIndices.contains(index)) {
        _selectedMessageIndices.remove(index);
      } else {
        _selectedMessageIndices.add(index);
      }
    });
  }

  /// 原味保存：选中内容原封不动存为笔记，不走 AI
  void _handleSaveAsIs() {
    if (_selectedMessageIndices.isEmpty) return;

    final sortedIndices = _selectedMessageIndices.toList()..sort();
    final rawContent = sortedIndices
        .map((i) =>
            "${_messages[i].isUser ? '我' : '囤囤鼠'}: ${_messages[i].content}")
        .join("\n\n");

    widget.onPin("对话记录", rawContent);

    setState(() {
      _pinnedMessageIndices.addAll(_selectedMessageIndices);
      _selectedMessageIndices.clear();
      _isPinMode = false;
    });
  }

  /// AI 整理并存：选中内容经 AI 整理后再存为笔记
  void _handlePinAction() async {
    if (_selectedMessageIndices.isEmpty) return;

    setState(() {
      _isSummarizing = true;
    });

    try {
      final sortedIndices = _selectedMessageIndices.toList()..sort();
      final selectedContent = sortedIndices
          .map((i) =>
              "${_messages[i].isUser ? 'User' : 'AI Mentor'}: ${_messages[i].content}")
          .join("\n\n");

      final summary = await ref
          .read(contentGeneratorProvider)
          .summarizeForPin(_getContextContent(), selectedContent);

      String finalQuestion = "AI Note";
      String finalAnswer = summary;

      final qIndex = summary.indexOf('Q:');
      final aIndex = summary.indexOf('A:');

      if (qIndex != -1 && aIndex != -1 && aIndex > qIndex) {
        final qLine = summary.substring(qIndex + 2, aIndex).trim();
        final aLine = summary.substring(aIndex + 2).trim();
        if (qLine.isNotEmpty && aLine.isNotEmpty) {
          finalQuestion = qLine;
          finalAnswer = aLine;
        }
      }

      if (!mounted) return;

      widget.onPin(finalQuestion, finalAnswer);

      setState(() {
        _pinnedMessageIndices.addAll(_selectedMessageIndices);
        _selectedMessageIndices.clear();
        _isPinMode = false;
        _isSummarizing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI 整理失败: $e')),
      );
      setState(() {
        _isSummarizing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism Sheet
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .canvasColor
                .withOpacity(0.9), // Adaptive background
          ),
          child: Column(
            children: [
              // Header：囤囤鼠标题 + 顶部 Pin 按钮（点击进入多选）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI 囤囤鼠',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          if (_isSelectionMode)
                            Text(
                                _selectedMessageIndices.isEmpty
                                    ? '选择要保存的对话'
                                    : '已选 ${_selectedMessageIndices.length} 条',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey))
                          else
                            const Text('点击 Pin 多选对话再保存',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: '多选对话并保存',
                        icon: Icon(
                          _isSelectionMode
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          size: 22,
                          color: _isSelectionMode ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () {
                          if (!_isSelectionMode) {
                            setState(() => _isPinMode = true);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_isSelectionMode)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => setState(() {
                            _selectedMessageIndices.addAll(
                                List.generate(_messages.length, (i) => i));
                          }),
                          child: const Text('全选'),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _isPinMode = false;
                            _selectedMessageIndices.clear();
                          }),
                          child: const Text('取消'),
                        ),
                      ],
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                ],
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

              // Message List
              Expanded(
                child: _isLoadingHistory
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    '关于卡片内容，尽管问我',
                                    style: TextStyle(
                                        color: Theme.of(context).hintColor),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '试试这些常见问题：',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: _presetQuestions.map((q) {
                                      return ActionChip(
                                        label: Text(q,
                                            style: const TextStyle(fontSize: 13)),
                                        onPressed: _isLoading
                                            ? null
                                            : () {
                                                _controller.text = q;
                                                _handleSend();
                                              },
                                        backgroundColor: Theme.of(context)
                                            .brightness == Brightness.dark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.grey[200],
                                        side: BorderSide.none,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        padding: const EdgeInsets.only(top: 16),
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isSelected =
                              _selectedMessageIndices.contains(index);
                          final isPinned =
                              _pinnedMessageIndices.contains(index);
                          return _buildMessageBubble(
                              msg, index, isSelected, isPinned);
                        },
                      ),
              ),

              // Bottom Area: Input OR 原味保存 / AI 整理并存
              const SizedBox(height: 16),
              if (_isSelectionMode)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSummarizing ? null : _handleSaveAsIs,
                        icon: const Icon(Icons.content_copy, size: 18),
                        label: const Text('原味保存'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white38
                                  : Colors.grey),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSummarizing ? null : _handlePinAction,
                        icon: _isSummarizing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isSummarizing
                            ? '整理中...'
                            : 'AI 整理并存'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9333EA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: '问问囤囤鼠...',
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        minLines: 1,
                        maxLines: 3,
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isLoading ? null : _handleSend,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            _isLoading ? Colors.grey : const Color(0xFFFF8A65),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.arrow_upward,
                                color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      _ChatMessage msg, int index, bool isSelected, bool isPinned) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleColor = isSelected
        ? Colors.amber[100]
        : (msg.isUser
            ? (isDark ? const Color(0xFF9333EA) : Colors.black)
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]));

    final textColor = isSelected
        ? Colors.black
        : (msg.isUser
            ? Colors.white
            : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (_isSelectionMode) ...[
            Checkbox(
              value: isSelected,
              onChanged: (v) => _toggleSelection(index),
              shape: const CircleBorder(),
              activeColor: Colors.amber,
            ),
          ] else
            const SizedBox(width: 16),

          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_isSelectionMode) _toggleSelection(index);
              },
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.only(
                        right: msg.isUser ? 16 : 40, left: msg.isUser ? 40 : 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      border: isSelected
                          ? Border.all(color: Colors.amber, width: 2)
                          : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        msg.isUser
                            ? SelectableText(
                                msg.content,
                                style: TextStyle(color: textColor, height: 1.5),
                              )
                            : MarkdownBody(
                                data: msg.content,
                                selectable: true,
                                styleSheet: MarkdownStyleSheet.fromTheme(
                                        Theme.of(context))
                                    .copyWith(
                                  p: TextStyle(
                                      color: textColor,
                                      height: 1.5,
                                      fontFamily: 'JinghuaSong'),
                                  strong: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'JinghuaSong'),
                                ),
                              ),
                      ],
                    ),
                  ),
                  if (isPinned && !isSelected)
                    Positioned(
                      top: -6,
                      right: msg.isUser ? 10 : 34,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.push_pin,
                            size: 10, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 多选模式下才显示每条 AI 消息旁的 Pin，用于勾选/取消
          if (_isSelectionMode && !msg.isUser) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isPinned
                    ? Icons.push_pin
                    : (isSelected ? Icons.push_pin : Icons.push_pin_outlined),
                size: 20,
                color: isPinned ? Colors.amber : (isSelected ? Colors.amber : Colors.grey),
              ),
              onPressed: () => _toggleSelection(index),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FlashcardWidget extends StatefulWidget {
  final String question;
  final String answer;
  final bool isDark;

  const _FlashcardWidget(
      {required this.question, required this.answer, required this.isDark});

  @override
  State<_FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<_FlashcardWidget> {
  void _showAnswerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // For custom rounded corners
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // 使用屏幕高度的 75%
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 1. Header (Fixed)
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text('Insight',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black87)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),

            // 2. Scrollable Content (Question & Answer)
            Expanded(
              child: SelectionArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q: ${widget.question}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.answer,
                        style: TextStyle(
                            fontSize: 18,
                            height: 1.6,
                            color: widget.isDark
                                ? Colors.grey[200]
                                : Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Bottom Button (Fixed)
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isDark ? Colors.white : Colors.black,
                  foregroundColor: widget.isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Got it!'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showAnswerSheet,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(widget.isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.touch_app,
                  color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Flashcard',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent.shade200),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Q: ${widget.question}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: widget.isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
