import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quick_pm/l10n/onboarding_landing_strings.dart';

/// 产品理念 + 未来愿景：播客式对话（关于页与官网页共用，随语言切换文案）
class PhilosophyVisionSection extends StatefulWidget {
  final bool isDark;

  const PhilosophyVisionSection({super.key, required this.isDark});

  @override
  State<PhilosophyVisionSection> createState() => _PhilosophyVisionSectionState();
}

class _PhilosophyVisionSectionState extends State<PhilosophyVisionSection> {
  int _visibleCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final total = OnboardingLandingStrings.philosophyLines(context).length;
      _timer = Timer.periodic(const Duration(milliseconds: 320), (_) {
        if (!mounted) return;
        setState(() {
          if (_visibleCount < total) _visibleCount++;
        });
        if (_visibleCount >= total) _timer?.cancel();
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
    final lines = OnboardingLandingStrings.philosophyLines(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          OnboardingLandingStrings.philosophyTitle(context),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(lines.length, (i) {
          final line = lines[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: line.isFromUser
                ? _buildUserBubble(
                    text: line.text, isDark: isDark, show: _visibleCount > i)
                : _buildBubble(
                    text: line.text, isDark: isDark, show: _visibleCount > i),
          );
        }),
      ],
    );
  }
}
