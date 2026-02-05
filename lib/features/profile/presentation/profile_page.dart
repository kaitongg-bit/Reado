import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart' as custom_theme;
import '../../../core/theme/theme_provider.dart' show themeProvider;
import 'package:firebase_auth/firebase_auth.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import '../../../core/providers/credit_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = ref.watch(allItemsProvider);
    final masteredCount =
        items.where((i) => i.masteryLevel != FeedItemMastery.unknown).length;

    void handleLogout() async {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) context.go('/onboarding');
    }

    void _showCreditRules(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('积分规则 💰'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem(Icons.fiber_new, '新用户注册', '+200 积分'),
              _buildRuleItem(Icons.auto_awesome, 'AI 智能拆解/解析', '-10 积分/次'),
              _buildRuleItem(Icons.share, '分享知识库链接', '+50 积分/次'),
              _buildRuleItem(Icons.person_add, '邀请好友加入', '+50 积分/位'),
              const SizedBox(height: 16),
              const Text('💡 积分不足时，只需分享您喜欢的知识库给好友即可立即获得积分！',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('我知道了'),
            ),
          ],
        ),
      );
    }

    // Helper to show edit dialog
    void _showEditProfile(BuildContext context, User user) {
      showDialog(
        context: context,
        builder: (context) => _EditProfileDialog(user: user),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background effects...
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65)
                        .withOpacity(isDark ? 0.15 : 0.2),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar section...
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.userChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      if (user == null) return const SizedBox();

                      return Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.orangeAccent
                                            .withOpacity(0.5),
                                        width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orangeAccent
                                            .withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      )
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: user.photoURL != null
                                          ? Image.network(
                                              user.photoURL!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.network(
                                                  'https://api.dicebear.com/7.x/adventurer/png?seed=${user.uid}',
                                                  fit: BoxFit.cover,
                                                );
                                              },
                                            )
                                          : Image.network(
                                              'https://api.dicebear.com/7.x/adventurer/png?seed=${user.uid}',
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showEditProfile(context, user),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orangeAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                          )
                                        ],
                                      ),
                                      child: const Icon(Icons.edit,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  user.displayName ?? '设置昵称',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showEditProfile(context, user),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                              label: '知识点',
                              value: '$masteredCount 已掌握',
                              icon: Icons.school,
                              color: Colors.blue,
                              isDark: isDark)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final statsAsync = ref.watch(creditProvider);
                            return _StatCard(
                              label: '我的积分',
                              value: statsAsync.when(
                                data: (stats) => '${stats.credits}',
                                loading: () => '...',
                                error: (_, __) => '0',
                              ),
                              icon: Icons.stars,
                              color: const Color(0xFFFFB300),
                              isDark: isDark,
                              subtitle: statsAsync.when(
                                data: (stats) => '推广点击: ${stats.shareClicks}',
                                loading: () => '',
                                error: (_, __) => '',
                              ),
                              onTap: () => _showCreditRules(context),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Settings Section
                  _SectionHeader(title: '设置', isDark: isDark),
                  const SizedBox(height: 16),

                  _GlassTile(
                    icon: isDark ? Icons.light_mode : Icons.dark_mode,
                    title: '外观',
                    subtitle: isDark ? '深色模式' : '浅色模式',
                    isDark: isDark,
                    trailing: Switch(
                      value: isDark,
                      activeColor: Colors.orangeAccent,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).setTheme(val
                            ? custom_theme.ThemeMode.dark
                            : custom_theme.ThemeMode.light);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  _GlassTile(
                    icon: Icons.workspace_premium,
                    title: '积分任务',
                    subtitle: '分享赚取更多积分',
                    isDark: isDark,
                    onTap: () => _showCreditRules(context),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

                  // Log Out
                  InkWell(
                    onTap: handleLogout,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.red.withOpacity(0.3), width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          '退出登录',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCard(
      {required this.label,
      required this.value,
      this.subtitle,
      required this.icon,
      required this.color,
      required this.isDark,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.orangeAccent)),
                ],
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
    );
  }
}

class _GlassTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDark;
  final Color? iconColor;
  final Color? textColor;

  const _GlassTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    required this.isDark,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? (isDark ? Colors.white : Colors.black))
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      size: 20,
                      color: iconColor ??
                          (isDark ? Colors.white : Colors.black87)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor ??
                                  (isDark ? Colors.white : Colors.black87))),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600])),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final User user;
  const _EditProfileDialog({required this.user});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late TextEditingController _nameController;
  late String _selectedAvatarUrl;
  bool _isSaving = false;

  final List<String> _officialAvatars = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Zack',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Midnight',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Luna',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Jasper',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Willow',
    'https://api.dicebear.com/7.x/adventurer/png?seed=River',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Bear',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Fox',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Owl',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Cat',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _selectedAvatarUrl = widget.user.photoURL ?? _officialAvatars[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      if (_nameController.text.trim().isNotEmpty) {
        await widget.user.updateDisplayName(_nameController.text.trim());
      }
      await widget.user.updatePhotoURL(_selectedAvatarUrl);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('编辑资料',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orangeAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.2),
                          blurRadius: 10)
                    ],
                  ),
                  child: ClipOval(
                    child: Image.network(_selectedAvatarUrl, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('选择头像',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _officialAvatars.length,
                itemBuilder: (context, index) {
                  final url = _officialAvatars[index];
                  final isSelected = url == _selectedAvatarUrl;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatarUrl = url),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.orangeAccent, width: 3)
                            : null,
                      ),
                      child: ClipOval(
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: '昵称',
                  hintText: '输入你的昵称',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('保存'),
        ),
      ],
    );
  }
}
