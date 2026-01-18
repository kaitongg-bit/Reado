import 'package:flutter/material.dart';
import 'war_room_page.dart'; // For WarRoomDocument

class MockInterviewPage extends StatefulWidget {
  final List<WarRoomDocument> documents;

  const MockInterviewPage({super.key, required this.documents});

  @override
  State<MockInterviewPage> createState() => _MockInterviewPageState();
}

class _MockInterviewPageState extends State<MockInterviewPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<InterviewMessage> _messages = [];
  bool _isAiTyping = false;
  int _questionCount = 0;

  @override
  void initState() {
    super.initState();
    _startInterview();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(String content, bool isUser, {bool isFeedback = false}) {
    setState(() {
      _messages.add(InterviewMessage(
        content: content,
        isUser: isUser,
        isFeedback: isFeedback,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _startInterview() async {
    setState(() => _isAiTyping = true);
    await Future.delayed(const Duration(seconds: 1));
    
    String intro = "你好！我是你的 AI 面试官。";
    if (widget.documents.isNotEmpty) {
      final validDocs = widget.documents.where((d) => d.title.length > 5).toList();
      final targetDoc = validDocs.isNotEmpty ? validDocs.first : widget.documents.first;
      intro += "\n\n我刚才仔细阅读了你的简历，对 **“${targetDoc.title}”** 这段经历很感兴趣。";
      _addMessage(intro, false);
      
      await Future.delayed(const Duration(milliseconds: 1500));
      _addMessage("你能简单介绍一下在这个项目中，你遇到的最大挑战是什么吗？请尝试用 STAR 法则来回答。", false);
    } else {
      intro += "\n\n看来你还没有上传具体的项目经历。没关系，我们先来聊聊基础问题。";
      _addMessage(intro, false);
      
      await Future.delayed(const Duration(milliseconds: 1500));
      _addMessage("请做一个简单的自我介绍，重点突出你的产品/技术能力。", false);
    }
    
    setState(() => _isAiTyping = false);
  }

  void _handleUserReply(String text) async {
    _controller.clear();
    _addMessage(text, true);
    
    setState(() => _isAiTyping = true);
    _scrollToBottom();
    
    // Simulate AI thinking and analyzing
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isAiTyping = false);
    
    _questionCount++;
    
    // Mock Feedback Logic
    if (_questionCount == 1) {
       _addMessage("📝 **AI 点评**：\n回答结构比较清晰，但缺少具体的量化数据支持。例如“提升了性能”可以改为“QPS 提升了 50%”。", false, isFeedback: true);
       await Future.delayed(const Duration(seconds: 1));
       _addMessage("接着问一个细节：在该项目中，如果当时方案 A 失败了，你有准备 Plan B 吗？", false);
    } else if (_questionCount == 2) {
       _addMessage("📝 **AI 点评**：\n这次回答得很好，体现了你的风险控制意识 (Risk Management)。", false, isFeedback: true);
       await Future.delayed(const Duration(seconds: 1));
       _addMessage("最后一个问题：如果给你重新做一次该项目的机会，你会由哪些不同的做法？", false);
    } else {
       _addMessage("🎉 面试结束！\n\n总体评价：你的表达逻辑性很强，但在数据敏感度上还有提升空间。建议多从业务价值 (Business Value) 的角度复盘项目。\n\n你可以点击左上角退出，或者输入任意内容开始新的一轮。", false);
       _questionCount = 0; // Reset loop
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('模拟面试 (AI Interviewer)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             Text('🟢 在线 · 正在录音中...', style: TextStyle(fontSize: 10, color: Colors.green)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black),
      ),
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isAiTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const _TypingIndicator(); // Show typing indicator at the end
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: '输入你的回答 (Enter 发送)...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (value) {
                         if (value.trim().isNotEmpty) _handleUserReply(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) _handleUserReply(_controller.text);
                    },
                    backgroundColor: Colors.black,
                    elevation: 0,
                    mini: true,
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(InterviewMessage msg) {
    final isUser = msg.isUser;
    final isFeedback = msg.isFeedback;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.black,
              radius: 18,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFF2563EB) 
                    : (isFeedback ? const Color(0xFFFEF3C7) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isFeedback ? Border.all(color: Colors.amber.withOpacity(0.5)) : null,
                boxShadow: [
                  if (!isUser && !isFeedback)
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ]
              ),
              child: SelectableText( // Allow copying feedback
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : (isFeedback ? Colors.black87 : Colors.black87),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 18,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class InterviewMessage {
  final String content;
  final bool isUser;
  final bool isFeedback;
  final DateTime timestamp;

  InterviewMessage({
    required this.content,
    required this.isUser,
    this.isFeedback = false,
    required this.timestamp,
  });
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 20),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(12),
             ),
             child: const Row(
               children: [
                  SizedBox(width: 6, height: 6, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('面试官正在思考...', style: TextStyle(fontSize: 12, color: Colors.grey)),
               ],
             ),
           )
        ],
      ),
    );
  }
}
