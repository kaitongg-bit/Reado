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
import '../../../core/providers/adhd_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;

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
              _buildRuleItem(
                  Icons.chat_bubble_outline, 'AI 聊天 & 陪练', '目前免费 ⚡️'),
              _buildRuleItem(
                  Icons.description_outlined, '内容提取 / 解析', '目前免费 ⚡️'),
              _buildRuleItem(Icons.auto_awesome, 'AI 智能拆解', '10-40 积分/次'),
              _buildRuleItem(Icons.share, '点击分享按钮', '+10 积分/次'),
              _buildRuleItem(Icons.person_add, '邀请好友加入', '+50 积分/位'),
              const SizedBox(height: 16),
              const Text('💡 积分不足时，只需点击分享您喜欢的知识库即可立即获得奖励！',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                ),
                child: const Text(
                  '⚠️ 系统目前处于内测阶段，暂未开启积分支付与充值功能，敬请期待。',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold),
                ),
              ),
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

    void _showMasteryInfo(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('如何算“已掌握”？🎓'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('在沉浸式阅读中，点击底部的【记入收藏】并将卡片标记为：',
                  style: TextStyle(height: 1.5)),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.sentiment_satisfied_alt,
                      color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text('熟练 (Expert)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sentiment_neutral, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text('一般 (Medium)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sentiment_dissatisfied,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('生疏 (Newbie)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Text('系统会将这些标记过的知识点统计为“已掌握”，你可以在【收藏】页面统一进行回顾。',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('了解了'),
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
                                      child: _buildAvatarImage(
                                          user.photoURL, user.uid),
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
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                            child: _StatCard(
                          label: '知识点',
                          value: '$masteredCount 已掌握',
                          icon: Icons.school,
                          color: Colors.blue,
                          isDark: isDark,
                          onTap: () => _showMasteryInfo(context),
                        )),
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
                                onShare: () =>
                                    _handleProfileShare(context, ref),
                                onTap: () => _showCreditRules(context),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Settings Section
                  _SectionHeader(title: '设置', isDark: isDark),
                  const SizedBox(height: 16),

                  Consumer(
                    builder: (context, ref, child) {
                      final onboardingState = ref.watch(onboardingProvider);
                      return _GlassTile(
                        icon: Icons.school_outlined,
                        title: '新手引导',
                        subtitle: onboardingState.isAlwaysShowTutorial
                            ? '已开启 (每次都显示)'
                            : '默认 (仅首次显示)',
                        isDark: isDark,
                        trailing: Switch(
                          value: onboardingState.isAlwaysShowTutorial,
                          activeColor: Colors.orangeAccent,
                          onChanged: (val) {
                            ref
                                .read(onboardingProvider.notifier)
                                .toggleAlwaysShowTutorial(val);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  Consumer(
                    builder: (context, ref, child) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return const SizedBox.shrink();
                      final shareNotesAsync =
                          ref.watch(shareNotesPublicProvider(user.uid));
                      return shareNotesAsync.when(
                        data: (shareNotesPublic) => _GlassTile(
                          icon: Icons.menu_book_outlined,
                          title: '分享时开放我的笔记',
                          subtitle: shareNotesPublic
                              ? '他人通过链接可看到你的笔记'
                              : '仅展示卡片正文',
                          isDark: isDark,
                          trailing: Switch(
                            value: shareNotesPublic,
                            activeColor: Colors.orangeAccent,
                            onChanged: (val) async {
                              await ref
                                  .read(dataServiceProvider)
                                  .setShareNotesPublic(user.uid, val);
                              ref.invalidate(shareNotesPublicProvider(user.uid));
                            },
                          ),
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  if (FirebaseAuth.instance.currentUser?.email ==
                      'kitatest@qq.com') ...[
                    _GlassTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Admin Console',
                      subtitle: 'Content Management System',
                      isDark: isDark,
                      iconColor: Colors.deepOrange,
                      textColor: Colors.deepOrange,
                      onTap: () => context.push('/admin'),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: Colors.deepOrange),
                    ),
                    const SizedBox(height: 12),
                  ],

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

                  _buildAdhdSettings(context, ref, isDark),
                  const SizedBox(height: 24),

                  _GlassTile(
                    icon: Icons.visibility_off_outlined,
                    title: '隐藏的内容',
                    subtitle: '恢复被隐藏的知识库或卡片',
                    isDark: isDark,
                    onTap: () => context.push('/profile/hidden'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

                  _GlassTile(
                    icon: Icons.contact_support_outlined,
                    title: '联系我们 / 反馈',
                    subtitle: 'Bug 反馈、功能建议或合作',
                    isDark: isDark,
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => const _ContactDialog()),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

                  _GlassTile(
                    icon: Icons.info_outline,
                    title: '关于 Reado',
                    subtitle: '了解功能指南与设计理念',
                    isDark: isDark,
                    onTap: () => context.push('/profile/about'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

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

  Widget _buildAdhdSettings(BuildContext context, WidgetRef ref, bool isDark) {
    final adhdSettings = ref.watch(adhdSettingsProvider);
    final notifier = ref.read(adhdSettingsProvider.notifier);

    return Column(
      children: [
        _GlassTile(
          icon: Icons.psychology_outlined,
          title: '阅读辅助 (ADHD Focus)',
          subtitle: adhdSettings.isEnabled ? '已开启三色随机引导' : '未开启',
          isDark: isDark,
          trailing: Switch(
            value: adhdSettings.isEnabled,
            activeColor: Colors.orangeAccent,
            onChanged: (val) => notifier.setEnabled(val),
          ),
        ),
        if (adhdSettings.isEnabled) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('辅助模式',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildModeChip(ref, '标色', AdhdReadingMode.color,
                            adhdSettings.mode, isDark),
                        const SizedBox(width: 8),
                        _buildModeChip(ref, '加粗', AdhdReadingMode.bold,
                            adhdSettings.mode, isDark),
                        const SizedBox(width: 8),
                        _buildModeChip(ref, '混合', AdhdReadingMode.hybrid,
                            adhdSettings.mode, isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('引导强度',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      children: AdhdIntensity.values.map((intensity) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildIntensityChip(ref, intensity.label,
                              intensity, adhdSettings.intensity, isDark),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('💡 采用动态随机算法，在文中分布三色视觉锚点，防止视线漂移。',
                        style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.grey[500] : Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIntensityChip(WidgetRef ref, String label,
      AdhdIntensity intensity, AdhdIntensity current, bool isDark) {
    final isSelected = intensity == current;
    return GestureDetector(
      onTap: () =>
          ref.read(adhdSettingsProvider.notifier).setIntensity(intensity),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orangeAccent.withOpacity(0.2)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.orangeAccent
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(WidgetRef ref, String label, AdhdReadingMode mode,
      AdhdReadingMode current, bool isDark) {
    final isSelected = mode == current;
    return GestureDetector(
      onTap: () => ref.read(adhdSettingsProvider.notifier).setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orangeAccent.withOpacity(0.2)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.orangeAccent
                : (isDark ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  void _handleProfileShare(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. 生成专属链接
    // 对于个人页分享，我们默认跳转到 onboarding
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

  Widget _buildAvatarImage(String? url, String uid) {
    // Only accept local asset paths
    if (url != null && url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
      );
    }

    // Default for everyone (including Google users)
    return Image.asset(
      'assets/images/reado_ip_1_reader.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person),
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
  final VoidCallback? onShare;

  const _StatCard(
      {required this.label,
      required this.value,
      this.subtitle,
      required this.icon,
      required this.color,
      required this.isDark,
      this.onTap,
      this.onShare});

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 28),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onShare != null)
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 18),
                            onPressed: onShare,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        if (onShare != null) const SizedBox(width: 8),
                        if (onTap != null)
                          Icon(Icons.info_outline,
                              size: 16,
                              color: isDark ? Colors.white38 : Colors.black26),
                      ],
                    ),
                  ],
                ),
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
                ] else
                  const SizedBox(height: 19), // Spacer for consistency
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
    'assets/images/reado_ip_1_reader.png',
    'assets/images/reado_ip_2_music.png',
    'assets/images/reado_ip_3_builder_v2.png',
    'assets/images/reado_ip_4_explorer.png',
    'assets/images/reado_ip_5_coder.png',
    'assets/images/reado_ip_6_artist.png',
    'assets/images/reado_ip_7_idea.png',
    'assets/images/reado_ip_8_stargazer.png',
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
                    child: _buildAvatarImagePreview(_selectedAvatarUrl, isDark),
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
                        child: _buildAvatarImagePreview(url, isDark),
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

  Widget _buildAvatarImagePreview(String url, bool isDark) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          child: const Icon(Icons.person, size: 24, color: Colors.grey),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        child: const Icon(Icons.person, size: 24, color: Colors.grey),
      ),
    );
  }
}

class _ContactDialog extends ConsumerStatefulWidget {
  const _ContactDialog();

  @override
  ConsumerState<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends ConsumerState<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'bug';
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _typeLabels = {
    'bug': '🐛 Bug 反馈',
    'advice': '💡 功能建议',
    'cooperation': '🤝 商务合作',
    'other': '💬 其他',
  };

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(dataServiceProvider).submitFeedback(
            _type,
            _contentController.text.trim(),
            _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('感谢您的反馈！我们会尽快处理。')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('联系我们',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '反馈类型',
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: _typeLabels.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? '请输入内容' : null,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: '详细描述',
                    hintText: '请详细描述您遇到的问题或建议...',
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  style:
                      TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: '联系方式 (选填)',
                    hintText: '邮箱或微信，方便我们需要时联系您',
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child:
              Text('取消', style: TextStyle(color: isDark ? Colors.grey : null)),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            disabledBackgroundColor: Colors.orangeAccent.withOpacity(0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('提交',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
