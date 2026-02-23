import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/onboarding_provider.dart';
import '../../../../core/providers/credit_provider.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'package:firebase_auth/firebase_auth.dart';

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

  void _handleShare(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. 生成专属链接
    final String baseUrl = html.window.location.origin;
    final String shareUrl = "$baseUrl/#/onboarding?ref=${user.uid}";

    // 2. 复制到剪贴板
    Clipboard.setData(
        ClipboardData(text: '嘿！我正在使用 Reado 学习，这个 AI 工具太强了，快来看看：\n$shareUrl'));

    // 3. 奖励积分 (动作奖励)
    ref.read(creditProvider.notifier).rewardShare(amount: 10);

    // 4. 更新教程进度
    ref.read(onboardingProvider.notifier).completeStep('share_points');

    // 5. 显示提示（不展示长链接，文案更大更清晰）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.stars, color: Color(0xFFFFB300)),
                SizedBox(width: 8),
                Text('分享成功！获得 10 积分动作奖励 🎁',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            const Text('已经为您复制到剪贴板',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            const Text('分享链接已复制到剪贴板，快粘贴给你的朋友使用吧',
                style: TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('好友通过您的链接加入时，您将再获得 50 积分',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPanel(
      BuildContext context, WidgetRef ref, OnboardingState state) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 320),
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
            value: state.completedStepsCount / 6,
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
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .completeStep('text');
                      onStartTextTutorial?.call();
                    },
                    onToggle: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleStep('text'),
                  ),
                  _ChecklistItem(
                    title: '2. 查看后台任务',
                    isDone: state.hasSeenTaskCenter,
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .completeStep('task_center');
                      onStartTaskCenterTutorial?.call();
                    },
                    onToggle: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleStep('task_center'),
                  ),
                  _ChecklistItem(
                    title: '3. 多模态链接解析',
                    isDone: state.hasSeenMultimodalDeconstruction,
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .completeStep('multimodal');
                      onStartMultiTutorial?.call();
                    },
                    onToggle: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleStep('multimodal'),
                  ),
                  _ChecklistItem(
                    title: '4. 查看全部知识卡',
                    isDone: state.hasSeenAllCards,
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .completeStep('all_cards_p2');
                      onStartAllCardsTutorial?.call();
                    },
                    onToggle: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleStep('all_cards_p2'),
                  ),
                  _ChecklistItem(
                    title: '5. 查看 AI 笔记',
                    isDone: state.hasSeenAiNotesTutorial,
                    onTap: () {
                      ref
                          .read(onboardingProvider.notifier)
                          .completeStep('ai_notes');
                      onStartAiNotesTutorial?.call();
                    },
                    onToggle: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleStep('ai_notes'),
                  ),
                  _ChecklistItem(
                    title: '6. 分享以获得积分',
                    isDone: state.hasSharedForPoints,
                    onTap: () => _handleShare(context, ref),
                    onToggle: () => ref
                        .read(onboardingProvider.notifier)
                        .toggleStep('share_points'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '🎉 太棒了！你已顺利上手 Reado',
            style: TextStyle(
              color: Color(0xFFFF8A65),
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
        title: const Text('暂时关闭入门指南？'),
        content: const Text('如果您已经掌握了基本操作，可以关闭此清单。您之后可以随时在“个人中心 - 设置”中重新开启。'),
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
  final VoidCallback? onToggle;

  const _ChecklistItem({
    required this.title,
    required this.isDone,
    this.onTap,
    this.onToggle,
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
            GestureDetector(
              onTap: onToggle,
              child: Icon(
                isDone ? Icons.check_circle : Icons.circle_outlined,
                color: isDone ? Colors.green : Colors.grey[400],
                size: 20,
              ),
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
