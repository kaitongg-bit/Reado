import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import 'mock_interview_page.dart';

// ... (lines 7-487 same as replaced above)

// Removed misplaced code

class WarRoomPage extends ConsumerStatefulWidget {
  const WarRoomPage({super.key});

  @override
  ConsumerState<WarRoomPage> createState() => _WarRoomPageState();
}

// Basic model for user documents
class WarRoomDocument {
  final String id;
  String title;
  String content;
  final DateTime updatedAt;

  WarRoomDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });
}

enum RightPanelTab { docs, chat }

class _WarRoomPageState extends ConsumerState<WarRoomPage> {
  // Selection State
  String? _selectedItemId; // ID of the currently selected Official FeedItem
  WarRoomDocument?
      _selectedUserDoc; // Currently selected User Document (if any)

  // Editor State
  late TextEditingController _textController;
  bool _isReadOnly = true;

  // Right Panel State
  RightPanelTab _currentRightTab = RightPanelTab.docs;
  final List<WarRoomDocument> _myDocuments = [];
  bool _isResumeUploaded = false;

  // Chat State
  final List<Map<String, dynamic>> _chatMessages = [
    {'role': 'ai', 'content': '我是你的面试助攻 AI。在左侧选择一个模板，或者直接在这里问我！'}
  ];
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    Future.microtask(() => ref.read(feedProvider.notifier).loadModule('D'));
  }

  @override
  void dispose() {
    _textController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // Helper to switch content
  void _selectOfficialItem(FeedItem item) {
    setState(() {
      _selectedItemId = item.id;
      _selectedUserDoc = null;
      _isReadOnly = true;

      // Load content into editor
      final page = item.pages.first as OfficialPage;
      _textController.text = page.markdownContent;
    });
  }

  void _selectUserDoc(WarRoomDocument doc) {
    setState(() {
      _selectedUserDoc = doc;
      _selectedItemId = null;
      _isReadOnly = false; // User docs are editable
      _textController.text = doc.content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(feedProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Initial Selection (Keep logic)
    if (_selectedItemId == null &&
        _selectedUserDoc == null &&
        items.isNotEmpty) {
      _selectedItemId = items.first.id;
      final page = items.first.pages.first as OfficialPage;
      _textController.text = page.markdownContent;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('⚔️ War Room',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _startMockInterview(context),
              icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
              label: const Text('Mock Interview'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.orange.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Background - Top Left
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65)
                        .withOpacity(isDark ? 0.15 : 0.2),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Ambient Background - Bottom Right
          Positioned(
            bottom: -100,
            right: -100,
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: isDesktop
                  ? Row(
                      children: [
                        // Left Column: Doc Tree
                        _buildGlassPanel(
                          width: 260,
                          child: _buildDocTree(items, isDark),
                          isDark: isDark,
                        ),
                        const SizedBox(width: 16),
                        // Middle Column: Editor
                        Expanded(
                          flex: 3,
                          child: _buildGlassPanel(
                            child: _buildEditorArea(isDark),
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column: My Docs / AI Chat
                        _buildGlassPanel(
                          width: 340,
                          child: _buildRightPanel(isDark),
                          isDark: isDark,
                        ),
                      ],
                    )
                  : _buildMobileView(items, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPanel(
      {required Widget child, double? width, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildDocTree(List<FeedItem> items, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.library_books,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  size: 20),
              const SizedBox(width: 12),
              Text('TEMPLATES',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 1.2)),
            ],
          ),
        ),
        Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = item.id == _selectedItemId;
              final textColor = isSelected
                  ? const Color(0xFFEF4444)
                  : (isDark ? Colors.grey[300] : Colors.black87);

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEF4444).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectOfficialItem(item),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditorArea(bool isDark) {
    return Column(
      children: [
        // Editor Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05))),
          ),
          child: Row(
            children: [
              if (_selectedUserDoc != null)
                _StatusChip(
                    label: 'Editing', color: Colors.blue, isDark: isDark)
              else
                _StatusChip(
                    label: 'Read Only', color: Colors.grey, isDark: isDark),
              const Spacer(),
              if (_selectedItemId != null)
                ElevatedButton.icon(
                  onPressed: () => _cloneWithAI(context),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Clone with AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              if (_selectedUserDoc != null)
                TextButton.icon(
                  onPressed: () {
                    // Mock Save
                    setState(() {
                      _selectedUserDoc!.content = _textController.text;
                      _selectedUserDoc!.title = _textController.text
                          .split('\n')
                          .firstWhere((l) => l.isNotEmpty,
                              orElse: () => 'Untitled');
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Saved successfully!')));
                  },
                  icon: Icon(Icons.save_outlined,
                      color: isDark ? Colors.white : Colors.black87),
                  label: Text('Save',
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87)),
                )
            ],
          ),
        ),

        // Main Editor
        Expanded(
          child: TextField(
            controller: _textController,
            readOnly: _isReadOnly,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(40),
              border: InputBorder.none,
              hintText: 'Start writing...',
              hintStyle: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
            style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: isDark ? Colors.grey[200] : const Color(0xFF334155)),
            cursorColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel(bool isDark) {
    return Column(
      children: [
        // Tab Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildRightTabBtn('My Docs', RightPanelTab.docs, isDark),
                _buildRightTabBtn('AI Chat', RightPanelTab.chat, isDark),
              ],
            ),
          ),
        ),

        Expanded(
          child: _currentRightTab == RightPanelTab.docs
              ? _buildMyDocsList(isDark)
              : _buildAIChat(isDark),
        ),
      ],
    );
  }

  Widget _buildRightTabBtn(String label, RightPanelTab tab, bool isDark) {
    final isActive = _currentRightTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentRightTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? Colors.grey[800] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 4)
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyDocsList(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: _myDocuments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('No docs yet',
                          style: TextStyle(
                              color: isDark ? Colors.grey[500] : Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = _myDocuments[index];
                    final isSelected = _selectedUserDoc?.id == doc.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent.withOpacity(0.1)
                              : (isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blueAccent.withOpacity(0.5)
                                : Colors.transparent,
                          )),
                      child: ListTile(
                        onTap: () => _selectUserDoc(doc),
                        leading: const Icon(Icons.article,
                            color: Color(0xFFEF4444), size: 20),
                        title: Text(doc.title,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87),
                            maxLines: 1),
                        subtitle: Text('Just now',
                            style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500])),
                        dense: true,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
        ),
        // Resume Upload Area (Simplified)
        Padding(
          padding: const EdgeInsets.all(16),
          child: _isResumeUploaded
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('Resume Ready',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold))),
                      GestureDetector(
                        onTap: () => setState(() => _isResumeUploaded = false),
                        child: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.green),
                      )
                    ],
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Simulating upload... 📤')));
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() => _isResumeUploaded = true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Resume Parsed ✅'),
                          backgroundColor: Colors.green));
                    });
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Resume'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.grey[400] : Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
        )
      ],
    );
  }

  Widget _buildAIChat(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final msg = _chatMessages[index];
              final isAi = msg['role'] == 'ai';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    if (isAi) ...[
                      CircleAvatar(
                          backgroundColor: Colors.deepPurple.withOpacity(0.1),
                          radius: 12,
                          child: const Icon(Icons.smart_toy,
                              size: 14, color: Colors.deepPurple)),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAi
                              ? (isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white)
                              : const Color(0xFF9333EA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(msg['content'],
                            style: TextStyle(
                                fontSize: 13,
                                color: isAi
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
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
                  controller: _chatController,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Ask AI...',
                    hintStyle: TextStyle(
                        color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) => _sendChatMessage(),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.send, color: Colors.deepPurple, size: 18),
                onPressed: _sendChatMessage,
              )
            ],
          ),
        )
      ],
    );
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _chatController.clear();

      // Mock Response
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _chatMessages.add({
            'role': 'ai',
            'content':
                'Okay, here is a suggestion:\n\n"I led the initiative..."'
          });
        });
      });
    });
  }

  Widget _buildMobileView(List<FeedItem> items, bool isDark) {
    return Column(
      children: [
        Container(
            height: 50,
            child: ListView(
                scrollDirection: Axis.horizontal,
                children: items.map((i) {
                  final isSelected = i.id == _selectedItemId;
                  return GestureDetector(
                    onTap: () => _selectOfficialItem(i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orangeAccent.withOpacity(0.2)
                            : (isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.transparent),
                      ),
                      alignment: Alignment.center,
                      child: Text(i.title,
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : (isDark ? Colors.white : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList())),
        const SizedBox(height: 16),
        Expanded(
            child: _buildGlassPanel(
                child: _buildEditorArea(isDark), isDark: isDark)),
      ],
    );
  }

  // --- Actions ---

  void _cloneWithAI(BuildContext context) {
    if (!_isResumeUploaded) {
      setState(() => _currentRightTab =
          RightPanelTab.docs); // Focus on docs tab to show button
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('⚠️ 请先在右侧上传简历，AI 才能为你工作！'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // Direct Simulation: Create new doc
    _simulateCloneProcess();
  }

  void _simulateCloneProcess() {
    // 1. Show processing
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(height: 24),
              Text('正在深度分析你的简历...',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('构建 STAR 模型回答中...',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    // 2. Generate and Switch
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog

      final newItem = WarRoomDocument(
          id: DateTime.now().toString(),
          title: '我的 STAR 回答：项目经历',
          content: """# STAR 回答：高并发系统重构

### Situation (情景)
2023 年 Q4，公司的核心支付系统在“黑色星期五”大促期间面临前所未有的流量压力，峰值 QPS 达到 50,000，导致数据库连接池频繁耗尽，订单响应延迟从 200ms 飙升至 3s。

### Task (任务)
作为后端 Tech Lead，我的目标是在 2 周内完成系统热点瓶颈的优化，确保系统能稳定承载至少 80,000 QPS，并将 P99 延迟控制在 500ms 以内。

### Action (行动)
1. **架构拆分**：将原来单体的订单服务拆分为 3 个微服务（下单、支付、库存），并引入消息队列（Kafka）进行流量削峰。
2. **缓存策略**：引入 Redis Cluster，对热点商品（Hot Key）实施多级本地缓存策略，减少 80% 的 DB 穿透。
3. **数据库优化**：通过分库分表（ShardingSphere）将大表水平拆分，解决单表数据量过亿的查询性能问题。

### Result (结果)
*   **性能提升**：压测显示系统最大吞吐量提升至 100,000 QPS (+100%)。
*   **稳定性**：在随后的双11大促中，实现 0 故障，P99 延迟稳定在 150ms。
*   **团队贡献**：沉淀了一套《高并发应急手册》，被公司推广为全员必读标准。

(你可以直接在这里修改...)""",
          updatedAt: DateTime.now());

      setState(() {
        _myDocuments.add(newItem);
        _selectUserDoc(newItem); // Switch view to new doc
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🎉 克隆成功！已切换到你的专属文档'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    });
  }

  void _startMockInterview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MockInterviewPage(documents: _myDocuments),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _StatusChip(
      {required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
