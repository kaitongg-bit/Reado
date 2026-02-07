import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../models/feed_item.dart';
import '../feed_provider.dart';

class FeedItemView extends ConsumerStatefulWidget {
  final FeedItem feedItem;
  final bool isReviewMode;

  const FeedItemView({
    super.key,
    required this.feedItem,
    this.isReviewMode = false,
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
  }

  void _showAskAISheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor, // Use theme color
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
          Navigator.pop(context); // 关闭弹窗
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

  void _toggleFavorite() {
    ref.read(feedProvider.notifier).toggleFavorite(widget.feedItem.id);
    final isFavorited = !widget.feedItem.isFavorited;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorited ? '✨ 已收藏到复习区' : '已取消收藏'),
        duration: const Duration(seconds: 1),
        backgroundColor: isFavorited ? Colors.green[600] : Colors.grey[600],
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

        // 3. Action Bar
        Positioned(
          right: 16,
          bottom: 110,
          child: Column(
            children: [
              _buildActionButton(
                icon: widget.feedItem.isFavorited
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: widget.feedItem.isFavorited
                    ? Colors.redAccent
                    : Colors.white,
                onTap: _toggleFavorite,
              ),
              const SizedBox(height: 16),
              // Note Navigation Icon (if notes exist)
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
                // icon: Icons.smart_toy_outlined,
                customChild: Padding(
                  padding: const EdgeInsets.all(
                      8.0), // Increased padding for smaller icon
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

        // 4. "Next Topic" Button - HIDDEN IF VIEWING NOTE
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

  Widget _buildPageContent(CardPageContent content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Base Glass Style for the Page
    final backgroundColor =
        isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.85);

    // Padding to clear the Top Header (which is in FeedPage)
    // Reduce from 130 to 88 to fix "giant gap" issue
    final contentPadding = const EdgeInsets.fromLTRB(24, 88, 24, 140);

    if (content is OfficialPage) {
      return Container(
        color: backgroundColor, // Semi-transparent base
        child: SelectionArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
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
      // No bottom padding for notes - maximize reading space
      final notePadding = const EdgeInsets.fromLTRB(24, 88, 24, 0);

      // In-Place Editing Mode
      if (_isEditing && _editingNote == content) {
        return Container(
          color: isDark ? const Color(0xFF2C2518) : const Color(0xFFFFFBE6),
          padding: notePadding.copyWith(bottom: 24),
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
      }

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
                        Icon(Icons.push_pin, color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Text('笔记',
                            style: TextStyle(
                                color: Colors.amber[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),

                  const Spacer(),
                  // Direct Action Buttons instead of Menu
                  if (!content.isReadOnly)
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
                      MarkdownBody(
                        data: content.answer,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: TextStyle(
                            fontSize: 18, // Slightly larger for reading
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
    }
    return const SizedBox.shrink();
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

  // 多选逻辑
  final Set<int> _selectedMessageIndices = {};
  bool get _isSelectionMode => _selectedMessageIndices.isNotEmpty;

  // 已 Pin 标记
  final Set<int> _pinnedMessageIndices = {};

  bool _isLoading = false;
  bool _isSummarizing = false;

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

    try {
      final history = _messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'content': m.content,
              })
          .toList();

      final aiResponse =
          await ref.read(contentGeneratorProvider).chatWithContent(
                _getContextContent(),
                history,
              );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          content: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _messages.add(_ChatMessage(
          content: "Sorry, I encountered an error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
    _scrollToBottom();
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

  void _handlePinAction() async {
    if (_selectedMessageIndices.isEmpty) return;

    setState(() {
      _isSummarizing = true;
    });

    try {
      // 1. 获取选中内容
      final sortedIndices = _selectedMessageIndices.toList()..sort();
      final selectedContent = sortedIndices
          .map((i) =>
              "${_messages[i].isUser ? 'User' : 'AI Mentor'}: ${_messages[i].content}")
          .join("\n\n");

      // 2. Call AI Helper
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

      // 3. 执行 Pin
      widget.onPin(finalQuestion, finalAnswer);

      // 4. 更新标记并退出选择模式
      setState(() {
        _pinnedMessageIndices.addAll(_selectedMessageIndices);
        _selectedMessageIndices.clear();
        _isSummarizing = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pin: $e')),
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
              // Header
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
                            Text('已选 ${_selectedMessageIndices.length}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey))
                          else
                            const Text('长按气泡多选',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  if (_isSelectionMode)
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedMessageIndices.clear()),
                      child: const Text('取消'),
                    )
                  else
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                ],
              ),
              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

              Divider(height: 1, color: Colors.grey.withOpacity(0.2)),

              // Message List
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              '关于卡片内容，尽管问我',
                              style:
                                  TextStyle(color: Theme.of(context).hintColor),
                            ),
                          ],
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

              // Bottom Area: Input OR Action Button
              const SizedBox(height: 16),
              if (_isSelectionMode)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSummarizing ? null : _handlePinAction,
                    icon: _isSummarizing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.push_pin),
                    label: Text(_isSummarizing
                        ? 'AI 正在整理...'
                        : (_selectedMessageIndices.length > 1
                            ? 'AI 整理并 Pin (${_selectedMessageIndices.length})'
                            : 'Pin to Note')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9333EA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
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

    return GestureDetector(
      onLongPress: () => _toggleSelection(index),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(index);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment:
              msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!msg.isUser && _isSelectionMode) ...[
              Checkbox(
                value: isSelected,
                onChanged: (v) => _toggleSelection(index),
                shape: const CircleBorder(),
                activeColor: Colors.amber,
              ),
            ] else
              const SizedBox(width: 16),

            Flexible(
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

            // Single Action Button (Only show for AI when not in selection mode)
            if (!msg.isUser && !_isSelectionMode) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 20, color: isPinned ? Colors.amber : Colors.grey),
                onPressed: () {
                  // Quick single pin
                  setState(() {
                    _selectedMessageIndices.clear();
                    _selectedMessageIndices.add(index);
                  });
                  _handlePinAction();
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
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
