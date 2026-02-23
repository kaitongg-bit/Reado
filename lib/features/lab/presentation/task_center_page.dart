import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html; // Assuming Web target as per ProfilePage usage

import '../../../../core/providers/credit_provider.dart';

/// 任务状态
enum TaskStatus { pending, processing, completed, failed }

/// 单个任务的数据模型
class ExtractionTask {
  final String id;
  final String moduleId;
  final TaskStatus status;
  final double progress;
  final String message;
  final int? totalCards;
  final List<Map<String, dynamic>> cards;
  final DateTime? createdAt;
  final bool autoSaved;

  ExtractionTask({
    required this.id,
    required this.moduleId,
    required this.status,
    required this.progress,
    required this.message,
    this.totalCards,
    this.cards = const [],
    this.createdAt,
    this.autoSaved = false,
  });

  factory ExtractionTask.fromFirestore(String id, Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'pending';
    TaskStatus status;
    switch (statusStr) {
      case 'processing':
        status = TaskStatus.processing;
        break;
      case 'completed':
        status = TaskStatus.completed;
        break;
      case 'failed':
        status = TaskStatus.failed;
        break;
      default:
        status = TaskStatus.pending;
    }

    return ExtractionTask(
      id: id,
      moduleId: data['moduleId'] as String? ?? 'custom',
      status: status,
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      message: data['message'] as String? ?? '',
      totalCards: data['totalCards'] as int?,
      cards: (data['cards'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      autoSaved: data['autoSaved'] as bool? ?? false,
    );
  }

  bool get isActive =>
      status == TaskStatus.pending || status == TaskStatus.processing;
}

/// 任务中心 Provider
final taskCenterProvider = StreamProvider<List<ExtractionTask>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ TaskCenter: No user logged in');
    return Stream.value([]);
  }

  print('📋 TaskCenter: Loading jobs for user ${user.uid}');

  final db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'reado',
  );

  // 简化查询，不使用复合索引
  return db
      .collection('extraction_jobs')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) {
    print('📋 TaskCenter: Got ${snapshot.docs.length} jobs');
    final tasks = <ExtractionTask>[];
    for (final doc in snapshot.docs) {
      try {
        final task = ExtractionTask.fromFirestore(doc.id, doc.data());
        tasks.add(task);
        print(
            '📋 Parsed task: ${task.id}, status: ${task.status}, createdAt: ${task.createdAt}');
      } catch (e) {
        print('❌ Failed to parse task ${doc.id}: $e');
      }
    }
    // 客户端排序
    tasks.sort((a, b) => (b.createdAt ?? DateTime(1970))
        .compareTo(a.createdAt ?? DateTime(1970)));
    return tasks.take(20).toList();
  });
});

/// 活跃任务数量 Provider (用于显示徽章)
final activeTaskCountProvider = Provider<int>((ref) {
  final tasksAsync = ref.watch(taskCenterProvider);
  return tasksAsync.when(
    data: (tasks) => tasks.where((t) => t.isActive).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 任务中心页面
class TaskCenterPage extends ConsumerStatefulWidget {
  const TaskCenterPage({super.key});

  @override
  ConsumerState<TaskCenterPage> createState() => _TaskCenterPageState();
}

class _TaskCenterPageState extends ConsumerState<TaskCenterPage> {
  String? _expandedTaskId;

  // 处理分享逻辑
  void _handleShare() {
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

    // 4. 显示提示（不展示长链接，文案更大更清晰）
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

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskCenterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务中心'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: '清理已完成任务',
            onPressed: () => _showCleanupDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCreditsCard(context, ref, isDark),
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无任务',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '使用 AI 生成知识卡片后，任务会显示在这里',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isExpanded = _expandedTaskId == task.id;

                    return _TaskCard(
                      task: task,
                      isExpanded: isExpanded,
                      onTap: () {
                        setState(() {
                          _expandedTaskId = isExpanded ? null : task.id;
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('加载失败: $e'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsCard(BuildContext context, WidgetRef ref, bool isDark) {
    final statsAsync = ref.watch(creditProvider);
    final stats = statsAsync.value;
    final credits = stats?.credits ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)]
              : [const Color(0xFFFFF3E0), const Color(0xFFFFCC80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我的积分',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.brown[700],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$credits',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.brown[900],
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _handleShare, // Use the proper handler
            icon: const Icon(Icons.share, size: 18),
            label: const Text('分享赚积分'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange[800],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清理任务'),
        content: const Text('确定要删除所有已完成和失败的任务记录吗？\n（生成的内容不会被删除）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cleanupTasks();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanupTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'reado',
    );

    try {
      final snapshot = await db
          .collection('extraction_jobs')
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: ['completed', 'failed']).get();

      final batch = db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已清理 ${snapshot.docs.length} 条任务记录')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理失败: $e')),
        );
      }
    }
  }
}

/// 单个任务卡片
class _TaskCard extends StatelessWidget {
  final ExtractionTask task;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 状态颜色和图标
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case TaskStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case TaskStatus.processing:
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case TaskStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TaskStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：状态 + 时间 + 展开图标
              Row(
                children: [
                  // 状态图标（处理中时旋转）
                  _buildStatusIcon(statusIcon, statusColor),
                  const SizedBox(width: 12),

                  // 状态文字
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.message.isNotEmpty
                              ? task.message
                              : _getStatusText(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (task.createdAt != null)
                          Text(
                            _formatTime(task.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 卡片数量徽章
                  if (task.totalCards != null || task.cards.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${task.cards.length}/${task.totalCards ?? '?'}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  const SizedBox(width: 8),

                  // 展开/收起图标
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ],
              ),

              // 进度条（进行中时显示）
              if (task.status == TaskStatus.processing ||
                  task.status == TaskStatus.pending) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: task.progress,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                    minHeight: 6,
                  ),
                ),
              ],

              // 展开内容：生成的卡片列表
              if (isExpanded && task.cards.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  '生成的知识点',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...task.cards
                    .take(10)
                    .map((cardData) => _buildCardPreview(context, cardData)),
                if (task.cards.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '还有 ${task.cards.length - 10} 个...',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                // 自动保存提示
                if (task.autoSaved) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '已自动保存到你的知识库',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, Color color) {
    if (task.status == TaskStatus.processing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    return Icon(icon, color: color, size: 24);
  }

  String _getStatusText() {
    switch (task.status) {
      case TaskStatus.pending:
        return '等待处理...';
      case TaskStatus.processing:
        return 'AI 正在生成...';
      case TaskStatus.completed:
        return '生成完成';
      case TaskStatus.failed:
        return '生成失败';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  Widget _buildCardPreview(
      BuildContext context, Map<String, dynamic> cardData) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = cardData['title'] as String? ?? '未命名';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.article_outlined,
            size: 20,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
