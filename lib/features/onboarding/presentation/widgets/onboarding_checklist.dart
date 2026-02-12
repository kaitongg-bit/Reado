import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';

class OnboardingChecklist extends ConsumerWidget {
  final VoidCallback? onStartTextTutorial;
  final VoidCallback? onStartTaskCenterTutorial;
  final VoidCallback? onStartMultiTutorial;
  final VoidCallback? onStartAllCardsTutorial;

  final VoidCallback? onStartAiNotesTutorial;

  const OnboardingChecklist({
    super.key,
    this.onStartTextTutorial,
    this.onStartTaskCenterTutorial,
    this.onStartMultiTutorial,
    this.onStartAllCardsTutorial,
    this.onStartAiNotesTutorial,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    if (!state.isTutorialActive) return const SizedBox();

    return Positioned(
      right: 16,
      bottom: 16,
      child: state.isChecklistVisible
          ? _buildPanel(context, ref, state)
          : _buildFab(ref),
    );
  }

  Widget _buildFab(WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () =>
          ref.read(onboardingProvider.notifier).setChecklistVisible(true),
      backgroundColor: const Color(0xFF1A237E),
      label: const Text('入门指南', style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.list_alt, color: Colors.white),
    );
  }

  Widget _buildPanel(
      BuildContext context, WidgetRef ref, OnboardingState state) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 450),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎓 新手任务清单',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => ref
                    .read(onboardingProvider.notifier)
                    .setChecklistVisible(false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.completedStepsCount / 5,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChecklistItem(
                    title: '1. AI 文本拆解',
                    isDone: state.hasSeenTextDeconstruction,
                    onTap: onStartTextTutorial,
                  ),
                  _ChecklistItem(
                    title: '2. 查看后台任务',
                    isDone: state.hasSeenTaskCenter,
                    onTap: onStartTaskCenterTutorial,
                  ),
                  _ChecklistItem(
                    title: '3. 多模态链接解析',
                    isDone: state.hasSeenMultimodalDeconstruction,
                    onTap: onStartMultiTutorial,
                  ),
                  _ChecklistItem(
                    title: '4. 查看全部知识卡',
                    isDone: state.hasSeenAllCards,
                    onTap: onStartAllCardsTutorial,
                  ),
                  _ChecklistItem(
                    title: '5. 查看 AI 笔记',
                    isDone: state.hasSeenAiNotesTutorial,
                    onTap: onStartAiNotesTutorial,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (state.isAllCompleted)
            const Text(
              '🎉 太棒了！你已掌握核心功能',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          const Divider(height: 24),
          Center(
            child: TextButton(
              onPressed: () {
                _showExitConfirmDialog(context, ref);
              },
              child: Text(
                '不再显示教程',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束新手教程？'),
        content: const Text('如果您已经掌握了基本操作，可以选择结束教程。任务清单将不再显示。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续学习'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(onboardingProvider.notifier).completeTutorial();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('结束教程'),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final String title;
  final bool isDone;
  final VoidCallback? onTap;

  const _ChecklistItem({
    required this.title,
    required this.isDone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDone ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? Colors.green : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : Colors.black87,
                  fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
            if (!isDone && onTap != null)
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
