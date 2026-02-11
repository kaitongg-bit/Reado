import 'package:flutter/material.dart';

class TutorialPulse extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color color;
  final double strokeWidth;

  const TutorialPulse({
    super.key,
    required this.child,
    this.isActive = false,
    this.color = Colors.orangeAccent,
    this.strokeWidth = 3.0,
  });

  @override
  State<TutorialPulse> createState() => _TutorialPulseState();
}

class _TutorialPulseState extends State<TutorialPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Pulse Effect
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(16), // Approximate match
                    border: Border.all(
                      color: widget.color,
                      width: widget.strokeWidth,
                    ),
                  ),
                  child:
                      widget.child, // Just for sizing, but painted via border
                ),
              ),
            );
          },
        ),
        // Actual Child
        widget.child,
      ],
    );
  }
}
