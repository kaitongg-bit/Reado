import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../core/services/auth_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // Mock Settings State
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    // Access daily limit from FeedNotifier (assuming we expose it or just mock it here for now)
    // Since mock_data doesn't persist this well in provider solely for profile, we might mock it locally
    // or better, read it from the provider if available.
    // For now, let's use a local state synced with provider update logic.

    // We can't easily read the "daily limit" from feedProvider directly without a selector if it's not exposed.
    // But we previously added `updateDailyLimit`. Let's assume a default for display.
    const int currentDailyLimit = 20;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate-50
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              _buildHeader(),

              const SizedBox(height: 24),

              // 2. Stats Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildStatCard('🔥 坚持天数', '3', '天')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('📚 已学卡片', '42', '张')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('⏳ 学习时长', '12', '小时')),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Settings Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('设置 (Settings)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              _buildSettingsCard([
                _buildSliderTile(),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('每日提醒'),
                  subtitle: const Text('每天 20:00 提醒复习'),
                  value: _notificationsEnabled,
                  onChanged: (val) =>
                      setState(() => _notificationsEnabled = val),
                  activeColor: Colors.black,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('深色模式'),
                  subtitle: const Text('保护视力 (暂不可用)'),
                  value: _darkModeEnabled,
                  onChanged: (val) {
                    // setState(() => _darkModeEnabled = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('深色模式开发中...')));
                  },
                  activeColor: Colors.black,
                ),
              ]),

              const SizedBox(height: 24),

              // 4. Danger Zone / Actions
              _buildSettingsCard([
                ListTile(
                  leading:
                      const Icon(Icons.cleaning_services, color: Colors.orange),
                  title: const Text('清除缓存'),
                  onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('缓存已清除')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined,
                      color: Colors.blue),
                  title: const Text('管理员：初始化数据'),
                  subtitle: const Text('将本地 Mock 数据上传到 Firestore'),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                        const SnackBar(content: Text('正在初始化数据库...')));

                    try {
                      await ref.read(feedProvider.notifier).seedDatabase();
                      messenger.showSnackBar(const SnackBar(
                          content: Text('✅ 数据初始化成功！请下拉刷新 Feed 页。'),
                          backgroundColor: Colors.green));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                          content: Text('❌ 初始化失败: $e'),
                          backgroundColor: Colors.red));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('退出登录 (匿名用户)'),
                  onTap: () {
                    // Add logout logic later
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Firebase 接入后可用')));
                  },
                ),
              ]),

              const SizedBox(height: 40),
              const Center(
                child: Text('Version 1.0.0 (Beta)',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authService = AuthService();
    final user = authService.currentUser;
    final isAnonymous = authService.isAnonymous;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey[200],
                backgroundImage: authService.photoURL != null
                    ? NetworkImage(authService.photoURL!)
                    : const NetworkImage(
                        'https://api.dicebear.com/7.x/miniavs/png?seed=1'),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authService.displayName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAnonymous ? '匿名用户 · 限制功能' : 'Level 3 · 探索者',
                      style: TextStyle(
                        color: isAnonymous ? Colors.orange : Colors.grey,
                      ),
                    ),
                    if (user?.email != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.email!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isAnonymous)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                ),
            ],
          ),

          // Google 登录按钮（仅匿名用户显示）
          if (isAnonymous) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(content: Text('正在连接 Google...')),
                    );

                    // 升级匿名账号为 Google 账号
                    await authService.linkAnonymousWithGoogle();

                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ 已升级为 Google 账号！数据已保留'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {}); // 刷新页面
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('登录失败: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 20,
                  height: 20,
                ),
                label: const Text('使用 Google 账号登录'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 升级后可永久保存数据并跨设备同步',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSliderTile() {
    // Note: In a real app we would watch the provider state.
    // Here we use a local state for smoothness and would call the provider on change end.
    return StatefulBuilder(builder: (context, setState) {
      double sliderValue = 20.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('每日复习上限', style: TextStyle(fontSize: 16)),
                  Text('${sliderValue.toInt()} 张',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            Slider(
              value: sliderValue,
              min: 5,
              max: 50,
              divisions: 9,
              activeColor: Colors.black,
              onChanged: (val) {
                setState(() => sliderValue = val);
              },
              onChangeEnd: (val) {
                ref.read(feedProvider.notifier).updateDailyLimit(val.toInt());
              },
            ),
          ],
        ),
      );
    });
  }
}
