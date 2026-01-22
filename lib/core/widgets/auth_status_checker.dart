import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 调试工具：检查当前登录状态
class AuthStatusChecker extends StatelessWidget {
  const AuthStatusChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.red.withOpacity(0.1),
            child: const Text(
              '❌ 未登录',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        }

        final isAnonymous = user.isAnonymous;
        final email = user.email ?? 'N/A';
        final uid = user.uid;

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isAnonymous
                ? Colors.orange.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAnonymous ? Colors.orange : Colors.green,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAnonymous ? '⚠️ Guest Mode' : '✅ Logged In',
                style: TextStyle(
                  color: isAnonymous ? Colors.orange : Colors.green,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Email: $email'),
              Text('UID: ${uid.substring(0, 8)}...'),
              if (isAnonymous) ...[
                const SizedBox(height: 8),
                const Text(
                  '⚠️ 匿名模式无法保存笔记！',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '请退出并使用Google登录',
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
