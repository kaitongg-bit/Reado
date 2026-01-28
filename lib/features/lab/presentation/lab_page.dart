import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../feed/presentation/widgets/feed_item_view.dart';
import '../../../models/feed_item.dart';

class LabPage extends ConsumerStatefulWidget {
  const LabPage({super.key});

  @override
  ConsumerState<LabPage> createState() => _LabPageState();
}

class _LabPageState extends ConsumerState<LabPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(feedProvider.notifier).loadModule('C'));
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(feedProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('全栈实操实验室',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMobileToast(context),
            )
        ],
      ),
      body: Stack(
        children: [
          // Ambient Background - Top Right
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA)
                        .withOpacity(isDark ? 0.15 : 0.2),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Ambient Background - Bottom Left
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(isDark ? 0.1 : 0.15),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Row(
              children: [
                // Main Content (Reading Stream)
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    controller: _pageController,
                    itemCount: items.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      if (!isDesktop && index == 0) {
                        _showMobileToast(context);
                      }
                    },
                    itemBuilder: (context, index) {
                      return FeedItemView(
                        feedItem: items[index],
                        isReviewMode: false,
                      );
                    },
                  ),
                ),

                // AI Sidebar (Desktop Only)
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: 400,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const _AISidebar(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: () {
                // Open AI Chat Sheet (Placeholder logic)
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('AI 助手为您服务！')));
              },
              backgroundColor: const Color(0xFF9333EA),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            )
          : null,
    );
  }

  void _showMobileToast(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.monitor, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('建议使用电脑端访问以获得完整的实操体验 (Figma/Coze)')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF6B21A8),
          duration: Duration(seconds: 4),
        ),
      );
    });
  }
}

class _AISidebar extends StatelessWidget {
  const _AISidebar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF9333EA)),
              const SizedBox(width: 12),
              Text('实操助手',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildChatMessage(context, 'AI',
                  '你好！在实操过程中遇到任何报错（如 Coze 配置、Figma 组件问题），请随时把信息粘贴在这里问我。'),
              _buildChatMessage(context, '我', '我不知道怎么配置 Google Search 插件...',
                  isUser: true),
              _buildChatMessage(context, 'AI',
                  '没关系！在左栏点击“插件”，然后搜索“Google Search”。记得点击“添加”，然后在 Bot 设置里选择它。'),
            ],
          ),
        ),
        _buildChatInput(context),
      ],
    );
  }

  Widget _buildChatMessage(BuildContext context, String sender, String text,
      {bool isUser = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF9333EA)
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFF3E8FF)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: '描述你的问题或粘贴报错...',
                hintStyle: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600]),
                filled: true,
                fillColor:
                    isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.send, color: Color(0xFF9333EA)),
          ),
        ],
      ),
    );
  }
}
