import 'dart:async';
import 'package:flutter/material.dart';

/// 一条对话：isFromUser 为 true 表示用户，false 表示囤囤鼠（用户无头像，有来有回播客式）
class _ChatLine {
  final bool isFromUser;
  final String text;
  const _ChatLine({required this.isFromUser, required this.text});
}

/// 产品理念 + 未来愿景：播客式对话，用户先说自己问题、会提问，囤囤鼠回答（关于页与官网页共用）
class PhilosophyVisionSection extends StatefulWidget {
  final bool isDark;

  const PhilosophyVisionSection({super.key, required this.isDark});

  @override
  State<PhilosophyVisionSection> createState() => _PhilosophyVisionSectionState();
}

class _PhilosophyVisionSectionState extends State<PhilosophyVisionSection> {
  int _visibleCount = 0;
  Timer? _timer;

  static const List<_ChatLine> _messages = [
    _ChatLine(isFromUser: true, text: '我有厌学症，老是收藏一堆东西和课件，但从来不会真的去看……一看到长文就发怵，觉得学东西好难。'),
    _ChatLine(isFromUser: false, text: '很多人都是这样！囤了不学，所以我们才做了 Reado～'),
    _ChatLine(isFromUser: true, text: 'Reado怎么帮助我？'),
    _ChatLine(isFromUser: false, text: '你可以把所有的文件、当下复制的一段文字、任何文字类的问题，甚至网页链接，都在这里解析成一个个短的知识点。'),
    _ChatLine(isFromUser: true, text: 'AI 解析我明白呀，但是解析完以后又会怎么样呢？它会是一个个单独的知识点吗？类似说，把一篇东西整理成一个个课程要学的知识点？'),
    _ChatLine(isFromUser: true, text: '然后呢，它会很长吗？长了的话我还是不爱看呐。'),
    _ChatLine(isFromUser: false, text: '我们用人人能听懂的「老奶模式」和「智障博士」把知识拆成小知识点，每次 3 分钟就够，一点一点就学完了。就像刷短视频一样上下滑～每个知识点一张卡片，滑一下就换下一张，不用自己筛选，沉浸着刷就行。通勤、睡前刷几张，压力小很多。'),
    _ChatLine(isFromUser: false, text: '而且每个知识点里面的 AI 对话，能够做得非常好，有启发性和针对性。'),
    _ChatLine(isFromUser: true, text: '那又如何，问其他ai不也一样？'),
    _ChatLine(isFromUser: false, text: '我们的 AI 对话问完可以 Pin 成笔记，全选ai整理，或者原味保存对话记录，非常方便。'),
    _ChatLine(isFromUser: true, text: '这个AI笔记很有意思欸，确实有时候跟AI聊完，觉得他的回答还是挺有价值的，但是就是懒得去复制到飞书或者Notion，懒得自己整理。'),
    _ChatLine(isFromUser: true, text: '我经常问 AI 各种各样的学习问题，和 AI 聊完当时懂了，过半年又像没学过一样，哈哈。'),
    _ChatLine(isFromUser: false, text: '是的呀，我们才想把「问过」变成「记住」呀。我们希望你可以喜欢这个AI拆解跟AI笔记的功能，它们是搭配着一起用的，绝对能让你觉得“学”这个事情不那么难开始和痛苦。'),
    _ChatLine(isFromUser: true, text: '那我还有一个问题，这个 AI 笔记是怎么查看呢？你说它像抖音一样上下滑去切换知识点，那 AI 笔记是在哪里呢？'),
    _ChatLine(isFromUser: false, text: '在每个知识点右滑就可以查看啦'),
    _ChatLine(isFromUser: false, text: '顺带一说，我们这些笔记是可以分享给别人的，也就是：你可以分享你的知识库给你的朋友，正文和你当时提问的笔记都能看到'),
    _ChatLine(isFromUser: true, text: '哈哈，有一说一，我觉得有时候我问的问题，可能他们心里也想问。对了，我朋友能保存下来我的知识库吗？'),
    _ChatLine(isFromUser: false, text: '哈哈，可以保存，现在就能把知识库链接发给朋友，他们打开就能读你分享的内容，不用登录也能先体验。'),
    _ChatLine(isFromUser: false, text: '而且，我们目前是免费体验阶段，通过「分享换积分」，我们希望让好内容被更多人看到。'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer = Timer.periodic(const Duration(milliseconds: 320), (_) {
        if (!mounted) return;
        setState(() {
          if (_visibleCount < _messages.length) _visibleCount++;
        });
        if (_visibleCount >= _messages.length) _timer?.cancel();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 囤囤鼠气泡（左侧头像 + 气泡）
  Widget _buildBubble({
    required String text,
    required bool isDark,
    required bool show,
  }) {
    final bubbleBg = isDark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      child: AnimatedSlide(
        offset: Offset(show ? 0 : -0.06, 0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipOval(
              child: Image.asset(
                'assets/images/reado_ip_1_reader.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFFF8A65).withOpacity(0.25),
                  child: const Icon(Icons.pets, color: Color(0xFFFF8A65), size: 24),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(4),
                    topRight: const Radius.circular(18),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.08 : 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 用户侧气泡（右侧，无头像）
  Widget _buildUserBubble({
    required String text,
    required bool isDark,
    required bool show,
  }) {
    const orange = Color(0xFFFF8A65);
    final bubbleBg = isDark
        ? orange.withOpacity(0.18)
        : orange.withOpacity(0.1);
    final textColor = isDark ? Colors.white : Colors.black87;
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      child: AnimatedSlide(
        offset: Offset(show ? 0 : 0.06, 0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(4),
                    bottomLeft: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.08 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '来聊几句',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(_messages.length, (i) {
          final line = _messages[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: line.isFromUser
                ? _buildUserBubble(text: line.text, isDark: isDark, show: _visibleCount > i)
                : _buildBubble(text: line.text, isDark: isDark, show: _visibleCount > i),
          );
        }),
      ],
    );
  }
}
