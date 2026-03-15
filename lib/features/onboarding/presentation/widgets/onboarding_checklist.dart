import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_pm/l10n/app_localizations.dart';
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
          : _buildFab(context, ref),
    );
  }

  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () =>
          ref.read(onboardingProvider.notifier).setChecklistVisible(true),
      backgroundColor: const Color(0xFF1A237E),
      label: Text(AppLocalizations.of(context)!.onboardingGuideFab, style: const TextStyle(color: Colors.white)),
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
        ClipboardData(text: AppLocalizations.of(context)!.sharePersonalCopy(shareUrl)));

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
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFFFB300)),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.onboardingShareSnackbarTitle,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.onboardingShareSnackbarCopied,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.onboardingShareSnackbarPaste,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context)!.onboardingShareSnackbarFriend,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
              Text(
                AppLocalizations.of(context)!.onboardingChecklistTitle,
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
                    title: AppLocalizations.of(context)!.onboardingItem1,
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
                    title: AppLocalizations.of(context)!.onboardingItem2,
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
                    title: AppLocalizations.of(context)!.onboardingItem3,
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
                    title: AppLocalizations.of(context)!.onboardingItem4,
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
                    title: AppLocalizations.of(context)!.onboardingItem5,
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
                    title: AppLocalizations.of(context)!.onboardingItem6,
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
          Text(
            AppLocalizations.of(context)!.onboardingDone,
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
                AppLocalizations.of(context)!.onboardingHideList,
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
        title: Text(AppLocalizations.of(context)!.onboardingExitDialogTitle),
        content: Text(AppLocalizations.of(context)!.onboardingExitDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.onboardingContinueLearn),
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
            child: Text(AppLocalizations.of(context)!.onboardingEndTutorial),
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
