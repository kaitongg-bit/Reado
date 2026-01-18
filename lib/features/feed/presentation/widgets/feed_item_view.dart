import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/feed_item.dart';
import '../feed_provider.dart';

class FeedItemView extends ConsumerStatefulWidget {
  final FeedItem feedItem;
  final bool isReviewMode;

  const FeedItemView({
    super.key, 
    required this.feedItem,
    this.isReviewMode = false,
  });

  @override
  ConsumerState<FeedItemView> createState() => _FeedItemViewState();
}

class _FeedItemViewState extends ConsumerState<FeedItemView> {
  final PageController _horizontalController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _showAskAISheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AskAISheet(
        feedItem: widget.feedItem,
        onPin: (question, answer) {
          // 调用 Provider 进行 Pin 操作
          ref.read(feedProvider.notifier).pinNoteToItem(
                widget.feedItem.id,
                question,
                answer,
              );
          
          Navigator.pop(context); // 关闭弹窗
          
          // 动效反馈
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✨ Note pinned successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green[600],
            ),
          );

          // 自动滚动到新添加的页面
          // 稍微延迟等待 Widget 重建
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_horizontalController.hasClients) {
              _horizontalController.animateToPage(
                widget.feedItem.pages.length, // target last index (length because we just added one so length is new index + 1, wait logic needs care)
                // Actually after rebuild, pages.length increased by 1. The index of new page is (length - 1).
                // Let's safe check later.
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              );
            }
          });
        },
      ),
    );
  }

  void _toggleFavorite() {
    // 使用 provider 更新状态
    ref.read(feedProvider.notifier).toggleFavorite(widget.feedItem.id);
    
    // 给用户反馈
    final isFavorited = !widget.feedItem.isFavorited; // 即将变成的状态
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorited ? '✨ 已收藏到复习区' : '已取消收藏'),
        duration: const Duration(seconds: 1),
        backgroundColor: isFavorited ? Colors.green[600] : Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Simply use pages from model (Official Page + User Notes)
    final pages = widget.feedItem.pages;
    
    // Calculate total user notes for badge
    final userNoteCount = pages.whereType<UserNotePage>().length;

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
          },
          itemBuilder: (context, index) {
            final pageContent = pages[index];
            return _buildPageContent(pageContent, userNoteCount);
          },
        ),

        // 2. Progress Indicator (Bottom)
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Row(
            children: List.generate(pages.length, (index) {
              final isSelected = index == _currentPageIndex;
              final isUserNote = pages[index] is UserNotePage;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isUserNote ? Colors.amber : Colors.white)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),

        // 3. Action Bar (Right side)
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(
                icon: widget.feedItem.isFavorited ? Icons.favorite : Icons.favorite_border,
                color: widget.feedItem.isFavorited ? Colors.redAccent : Colors.white,
                label: '收藏',
                onTap: _toggleFavorite,
              ),
              const SizedBox(height: 20),
              _buildActionButton(
                icon: Icons.smart_toy_outlined,
                label: 'Ask AI',
                isPrimary: true,
                onTap: () => _showAskAISheet(context),
              ),
            ],
          ),
        ),

        // 4. "Next / Prev" Hint Button (Bottom Center) - Hide in Review Mode
        if (!widget.isReviewMode)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Ideally this interacts with parent PageView. 
                  // For now, it's a visual cue.
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Next Topic', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }



  Widget _buildPageContent(CardPageContent content, int noteCount) {
    if (content is OfficialPage) {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            // Metadata Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 10),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('3 min read', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const Spacer(),
                  if (noteCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 10, color: Colors.brown),
                          const SizedBox(width: 4),
                          Text('$noteCount 笔记', style: const TextStyle(fontSize: 10, color: Colors.brown, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: content.markdownContent,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        h1: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.5),
                        p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Dynamic Flashcard Section
                    if (content.flashcardQuestion != null) ...[
                      _FlashcardWidget(
                        question: content.flashcardQuestion!,
                        answer: content.flashcardAnswer ?? '',
                      ),
                      // Add some bottom padding if flashcard is present
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else if (content is UserNotePage) {
      return Container(
        color: const Color(0xFFFFFBEB), // Amber tint for notes
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.push_pin, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text('MY PINNED NOTE', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              content.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content.answer,
                  style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.blue : Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
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

class _AskAISheet extends StatefulWidget {
  final FeedItem feedItem;
  final Function(String q, String a) onPin;

  const _AskAISheet({required this.feedItem, required this.onPin});

  @override
  State<_AskAISheet> createState() => _AskAISheetState();
}

class _AskAISheetState extends State<_AskAISheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  
  // 多选逻辑
  final Set<int> _selectedMessageIndices = {};
  bool get _isSelectionMode => _selectedMessageIndices.isNotEmpty;

  // 已 Pin 标记
  final Set<int> _pinnedMessageIndices = {};

  bool _isLoading = false;

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

    await Future.delayed(const Duration(seconds: 1));

    String aiReply = "这是一个关于“${widget.feedItem.title}”很好的问题。\n\n";
    if (_messages.length <= 2) {
       aiReply += "深层逻辑在于用户表面需求和潜在动机的错位。建议多用 5Whys 法则去深挖。";
    } else {
       aiReply += "除此之外，我们还需要考虑到市场环境的变化。您还有其他具体场景的疑问吗？";
    }

    setState(() {
      _isLoading = false;
      _messages.add(_ChatMessage(
        content: aiReply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
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

  void _handlePinAction() {
    if (_selectedMessageIndices.isEmpty) return;

    // 1. 获取选中内容
    final selectedContent = _selectedMessageIndices
        .map((i) => "${_messages[i].isUser ? 'Q' : 'AI'}: ${_messages[i].content}")
        .join("\n\n");

    String finalQuestion = "AI Summary";
    String finalAnswer = selectedContent;

    // 2. 如果是单选，优化一下格式
    if (_selectedMessageIndices.length == 1) {
      final index = _selectedMessageIndices.first;
      final msg = _messages[index];
      if (msg.isUser) {
        finalQuestion = "My Question";
        finalAnswer = msg.content;
      } else {
        // 尝试找上一条作为 Q
        if (index > 0) {
          finalQuestion = "关于 ${_messages[index - 1].content}...";
        } else {
          finalQuestion = "AI Insight";
        }
        finalAnswer = msg.content;
      }
    } else {
      // 多选逻辑：模拟“AI 整理”
      finalQuestion = "AI 整理笔记 (${_selectedMessageIndices.length} items)";
      finalAnswer = "=== Context ===\n$selectedContent\n\n(Generated by QuickPM AI)";
    }

    // 3. 执行 Pin
    widget.onPin(finalQuestion, finalAnswer);

    // 4. 更新标记并退出选择模式
    setState(() {
      _pinnedMessageIndices.addAll(_selectedMessageIndices);
      _selectedMessageIndices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('AI 导师',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_isSelectionMode 
                          ? '已选 ${_selectedMessageIndices.length} 条内容' 
                          : '长按气泡多选，点击 Pin',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              if (_isSelectionMode)
                TextButton(
                  onPressed: () => setState(() => _selectedMessageIndices.clear()),
                  child: const Text('取消'),
                )
              else
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
            ],
          ),
          const Divider(height: 1),

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
                          style: TextStyle(color: Colors.grey[400]),
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
                      final isSelected = _selectedMessageIndices.contains(index);
                      final isPinned = _pinnedMessageIndices.contains(index);
                      return _buildMessageBubble(msg, index, isSelected, isPinned);
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
                onPressed: _handlePinAction,
                icon: const Icon(Icons.push_pin),
                label: Text(_selectedMessageIndices.length > 1 
                  ? 'AI 整理并 Pin (${_selectedMessageIndices.length})' 
                  : 'Pin to Note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      hintText: '输入你的问题...',
                      filled: true,
                      fillColor: Colors.grey[100],
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
                    radius: 24,
                    backgroundColor: _isLoading ? Colors.grey : Colors.black,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, int index, bool isSelected, bool isPinned) {
    final bubbleColor = isSelected 
        ? Colors.amber[100] 
        : (msg.isUser ? Colors.black : Colors.grey[100]);
    final textColor = isSelected 
        ? Colors.black 
        : (msg.isUser ? Colors.white : Colors.black87);

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
          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                      right: msg.isUser ? 16 : 40, 
                      left: msg.isUser ? 40 : 0
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      border: isSelected ? Border.all(color: Colors.amber, width: 2) : null,
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
                        Text(
                          msg.content,
                          style: TextStyle(color: textColor, height: 1.5),
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
                        child: const Icon(Icons.push_pin, size: 10, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
            
            // Single Action Button (Only show for AI when not in selection mode)
            if (!msg.isUser && !_isSelectionMode) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                  size: 20, 
                  color: isPinned ? Colors.amber : Colors.grey
                ),
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

  const _FlashcardWidget({required this.question, required this.answer});

  @override
  State<_FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<_FlashcardWidget> {
  
  void _showAnswerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // For custom rounded corners
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text('Insight', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              'Q: ${widget.question}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              widget.answer,
              style: const TextStyle(fontSize: 18, height: 1.6, color: Colors.black87),
            ),
            const SizedBox(height: 48), // Bottom padding
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[100]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Quick Flashcard', 
                  style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)
                ),
                const Spacer(),
                const Icon(Icons.touch_app, size: 16, color: Colors.grey),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Q: ${widget.question}', 
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 12),
            const Text(
              '(Tap to reveal answer)', 
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
