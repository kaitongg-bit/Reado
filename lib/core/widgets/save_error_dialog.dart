import 'package:flutter/material.dart';

/// 根据异常类型返回简短说明 + 可能原因/建议，用于「保存到我的知识库」失败时的弹窗
({String shortMessage, String hint}) saveErrorToUserMessage(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('permission-denied') || s.contains('permission_denied')) {
    return (
      shortMessage: '权限不足，无法写入云端',
      hint: '请确认已登录当前账号。若在本地或测试环境，请部署最新 Firestore 规则（如运行 firebase deploy --only firestore）后重试。',
    );
  }
  if (s.contains('timeout') || s.contains('time-out') || s.contains('timed out')) {
    return (
      shortMessage: '请求超时',
      hint: '请检查网络是否稳定，稍后重试。',
    );
  }
  if (s.contains('unavailable') || s.contains('network') || s.contains('connection')) {
    return (
      shortMessage: '网络异常',
      hint: '请检查网络连接后重试。',
    );
  }
  if (s.contains('not-found') || s.contains('not_found')) {
    return (
      shortMessage: '分享内容不存在或已关闭',
      hint: '链接可能已失效，请让分享者重新分享。',
    );
  }
  return (
    shortMessage: '保存失败：$e',
    hint: '请稍后重试；若问题持续，可联系支持反馈。',
  );
}

/// 展示「保存到我的知识库」失败时的引导弹窗（带可能原因、建议与可选重试）
void showSaveToLibraryErrorDialog(
  BuildContext context, {
  required Object error,
  VoidCallback? onRetry,
}) {
  final (:shortMessage, :hint) = saveErrorToUserMessage(error);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
          SizedBox(width: 8),
          Text('保存失败'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shortMessage, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(
              '可能原因 / 建议',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).textTheme.bodySmall?.color ?? Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(ctx).textTheme.bodyMedium?.color ?? Colors.black87,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            child: const Text('重试'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}
