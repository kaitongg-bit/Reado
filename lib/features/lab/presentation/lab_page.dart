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

    if (items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('全栈实操 Lab', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showMobileToast(context),
            )
        ],
      ),
      body: Row(
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
            Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(left: BorderSide(color: Colors.grey[200]!)),
              ),
              child: const _AISidebar(),
            ),
        ],
      ),
      floatingActionButton: !isDesktop 
          ? FloatingActionButton(
              onPressed: () {
                 // Open AI Chat Sheet (Placeholder logic)
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('AI Assistant is here to help!'))
                 );
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: const Row(
            children: [
              Icon(Icons.psychology, color: Color(0xFF9333EA)),
              SizedBox(width: 12),
              Text('实操助手 (Companion AI)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildChatMessage('AI', '你好！在实操过程中遇到任何报错（如 Coze 配置、Figma 组件问题），请随时把信息粘贴在这里问我。'),
              _buildChatMessage('User', '我不知道怎么配置 Google Search 插件...', isUser: true),
              _buildChatMessage('AI', '没关系！在左栏点击“插件”，然后搜索“Google Search”。记得点击“添加”，然后在 Bot 设置里选择它。'),
            ],
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatMessage(String sender, String text, {bool isUser = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF9333EA) : const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '描述你的问题或粘贴报错...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
