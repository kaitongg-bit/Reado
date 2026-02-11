import 'package:flutter/material.dart';

class TutorialOverlay extends StatelessWidget {
  final GlobalKey? targetKey;
  final String text;
  final VoidCallback onDismiss;
  final Offset? manualOffset;

  const TutorialOverlay({
    super.key,
    this.targetKey,
    required this.text,
    required this.onDismiss,
    this.manualOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dark background with hole
          if (targetKey != null)
            _buildHoleOverlay()
          else
            GestureDetector(
              onTap: onDismiss,
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),

          // Instruction Bubble
          _buildInstructionBubble(context),
        ],
      ),
    );
  }

  Widget _buildHoleOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.7),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          _HolePainter(targetKey: targetKey!),
        ],
      ),
    );
  }

  Widget _buildInstructionBubble(BuildContext context) {
    // Basic positioning - in a real app this would be more sophisticated (e.g. using CompositedTransformTarget)
    Offset bubbleOffset = manualOffset ?? const Offset(20, 100);

    if (targetKey != null) {
      final box = targetKey!.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final position = box.localToGlobal(Offset.zero);
        bubbleOffset = Offset(24, position.dy + box.size.height + 20);
      }
    }

    return Positioned(
      left: bubbleOffset.dx,
      top: bubbleOffset.dy,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '新手引导',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onDismiss,
                    child: const Text('知道了'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends StatelessWidget {
  final GlobalKey targetKey;

  const _HolePainter({required this.targetKey});

  @override
  Widget build(BuildContext context) {
    final box = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return const SizedBox();

    final position = box.localToGlobal(Offset.zero);
    final size = box.size;

    return Positioned(
      left: position.dx - 4,
      top: position.dy - 4,
      child: Container(
        width: size.width + 8,
        height: size.height + 8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
              size.height / 2 > 12 ? 12 : size.height / 2),
        ),
      ),
    );
  }
}
