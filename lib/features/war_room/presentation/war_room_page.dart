import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import 'mock_interview_page.dart';

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
  WarRoomDocument? _selectedUserDoc; // Currently selected User Document (if any)

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

    if (items.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Initial Selection Logic
    if (_selectedItemId == null && _selectedUserDoc == null && items.isNotEmpty) {
      // Defer to next frame to avoid setState during build if needed, 
      // but here we are just setting initial state if null.
      // Better done in initState but items might not be loaded yet.
      // We can just set it here directly for local state sync.
      _selectedItemId = items.first.id;
      final page = items.first.pages.first as OfficialPage;
      _textController.text = page.markdownContent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('⚔️ 面经军火库 (War Room)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _startMockInterview(context),
            icon: const Icon(Icons.bolt, color: Colors.orange),
            label: const Text('模拟面试', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isDesktop 
        ? Row(
            children: [
              // Left Column: Doc Tree (Official Templates)
              _buildDocTree(items),
              
              // Middle Column: Editor
              Expanded(
                flex: 3,
                child: _buildEditorArea(),
              ),
              
              // Right Column: My Docs / AI Chat
              _buildRightPanel(),
            ],
          )
        : _buildMobileView(items),
    );
  }

  Widget _buildDocTree(List<FeedItem> items) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: const Text('📚 官方模板库', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = item.id == _selectedItemId;
                return ListTile(
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFFEF4444) : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFFFEF2F2),
                  onTap: () => _selectOfficialItem(item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorArea() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Editor Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                if (_selectedUserDoc != null)
                  Chip(label: const Text('✏️ 编辑中'), backgroundColor: Colors.blue[50], labelStyle: TextStyle(color: Colors.blue[700], fontSize: 12))
                else
                  const Chip(label: Text('🔒 只读模板'), backgroundColor: Color(0xFFF1F5F9), labelStyle: TextStyle(color: Colors.grey, fontSize: 12)),
                
                const Spacer(),
                
                // Clone Button (Visible if Official Item is selected)
                if (_selectedItemId != null)
                  ElevatedButton.icon(
                    onPressed: () => _cloneWithAI(context),
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('AI 克隆 (生成我的版本)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),

                // Save Button (Visible if User Doc is selected)
                if (_selectedUserDoc != null)
                  TextButton.icon(
                    onPressed: () {
                      // Update logic (Mock)
                      setState(() {
                         _selectedUserDoc!.content = _textController.text;
                         _selectedUserDoc!.title = _textController.text.split('\n').firstWhere((l) => l.isNotEmpty, orElse: () => 'Untitled');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存')));
                    },
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('保存'),
                  )
              ],
            ),
          ),

          // Main Editor
          Expanded(
            child: TextField(
              controller: _textController,
              readOnly: _isReadOnly,
              maxLines: null, // Expands freely
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(40),
                border: InputBorder.none,
                hintText: 'Start writing...',
              ),
              style: const TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Tab Bar
          Row(
            children: [
              _buildRightTabBtn('我的文档', RightPanelTab.docs),
              _buildRightTabBtn('AI 助手', RightPanelTab.chat),
            ],
          ),
          
          Expanded(
            child: _currentRightTab == RightPanelTab.docs 
              ? _buildMyDocsList()
              : _buildAIChat(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRightTabBtn(String label, RightPanelTab tab) {
    final isActive = _currentRightTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentRightTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : const Color(0xFFF1F5F9),
            border: isActive ? null : Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          alignment: Alignment.center,
          child: Text(
            label, 
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyDocsList() {
    return Column(
      children: [
        Expanded(
          child: _myDocuments.isEmpty 
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                     const SizedBox(height: 12),
                     const Text('暂无文档', style: TextStyle(color: Colors.grey)),
                     TextButton(
                        onPressed: () {
                          // Switch to a template to clone
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('👈 请先在左侧选择一个模板进行克隆')));
                        }, 
                        child: const Text('去克隆模板')
                     )
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myDocuments.length,
                itemBuilder: (context, index) {
                  final doc = _myDocuments[index];
                  final isSelected = _selectedUserDoc?.id == doc.id;
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected ? Colors.blue[50] : Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isSelected ? Colors.blue[200]! : Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: ListTile(
                      onTap: () => _selectUserDoc(doc),
                      leading: const Icon(Icons.article, color: Color(0xFFEF4444), size: 20),
                      title: Text(doc.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
                      subtitle: Text('刚刚更新', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      dense: true,
                    ),
                  );
                },
              ),
        ),
        // Resume Upload Area
        Padding(
          padding: const EdgeInsets.all(16),
          child: _isResumeUploaded 
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('简历已就绪', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))),
                    IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.green),
                        onPressed: () => setState(() => _isResumeUploaded = false),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                  ],
                ),
              )
            : OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating upload... 📤')));
                  Future.delayed(const Duration(seconds: 1), () {
                    setState(() => _isResumeUploaded = true);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('简历上传成功！解析完成 ✅'), backgroundColor: Colors.green));
                  });
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('上传简历'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!)
                ),
              ),
        )
      ],
    );
  }
  
  Widget _buildAIChat() {
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
                   mainAxisAlignment: isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
                   children: [
                     if(isAi) ...[
                        const CircleAvatar(backgroundColor: Color(0xFFF3E8FF), radius: 12, child: Icon(Icons.smart_toy, size: 14, color: Colors.deepPurple)),
                        const SizedBox(width: 8),
                     ],
                     Flexible(
                       child: Container(
                         padding: const EdgeInsets.all(10),
                         decoration: BoxDecoration(
                           color: isAi ? Colors.white : const Color(0xFFF3E8FF),
                           borderRadius: BorderRadius.circular(12),
                           border: isAi ? Border.all(color: Colors.grey[100]!) : null,
                         ),
                         child: SelectableText(msg['content'], style: const TextStyle(fontSize: 13)),
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
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
             children: [
               Expanded(
                 child: TextField(
                   controller: _chatController,
                   style: const TextStyle(fontSize: 13),
                   decoration: const InputDecoration(
                     hintText: 'Ask AI...',
                     isDense: true,
                     border: InputBorder.none,
                   ),
                   onSubmitted: (val) => _sendChatMessage(),
                 ),
               ),
               IconButton(
                 icon: const Icon(Icons.send, color: Colors.deepPurple, size: 18),
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
    if(text.isEmpty) return;
    
    setState(() {
      _chatMessages.add({'role': 'user', 'content': text});
      _chatController.clear();
      
      // Mock Response
      Future.delayed(const Duration(milliseconds: 600), () {
        if(!mounted) return;
        setState(() {
          _chatMessages.add({'role': 'ai', 'content': '好的，针对这个问题，你可以尝试这样描述：\n\n“我主导了...（点击复制）”'});
        });
      });
    });
  }

  Widget _buildMobileView(List<FeedItem> items) {
     final selectedItem = items.firstWhere((i) => i.id == _selectedItemId, orElse: () => items.first);
     // Simplified mobile view
     return Column(
       children: [
          Container(
             height: 50, 
             color: Colors.white,
             child: ListView(
               scrollDirection: Axis.horizontal, 
               children: items.map((i) => Padding(padding: const EdgeInsets.all(8.0), child: Text(i.title))).toList()
             )
          ),
          Expanded(child: _buildEditorArea()),
       ],
     );
  }

  // --- Actions ---

  void _cloneWithAI(BuildContext context) {
    if (!_isResumeUploaded) {
      setState(() => _currentRightTab = RightPanelTab.docs); // Focus on docs tab to show button
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
              Text('正在深度分析你的简历...', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('构建 STAR 模型回答中...', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
        updatedAt: DateTime.now()
      );

      setState(() {
        _myDocuments.add(newItem);
        _selectUserDoc(newItem); // Switch view to new doc
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 克隆成功！已切换到你的专属文档'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        )
      );
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
