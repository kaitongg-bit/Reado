import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_provider.dart' as custom_theme;
import '../../../core/theme/theme_provider.dart' show themeProvider;
import '../../../core/locale/locale_provider.dart';
import 'package:quick_pm/l10n/app_localizations.dart';
import 'package:quick_pm/l10n/l10n_numeric_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import '../../../core/providers/credit_provider.dart';
import '../../../core/providers/adhd_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../feedback/presentation/contact_feedback_dialog.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';
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
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.creditsRuleTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem(Icons.fiber_new, l10n.creditsRuleNewUser, l10n.creditsRuleNewUserValue),
              _buildRuleItem(Icons.calendar_today, l10n.creditsRuleDaily, l10n.creditsRuleDailyValue),
              _buildRuleItem(Icons.chat_bubble_outline, l10n.creditsRuleAiChat, l10n.creditsRuleAiChatValue),
              _buildRuleItem(Icons.description_outlined, l10n.creditsRuleExtraction, l10n.creditsRuleExtractionValue),
              _buildRuleItem(Icons.auto_awesome, l10n.creditsRuleAiDeconstruct, l10n.creditsRuleAiDeconstructValue),
              _buildRuleItem(Icons.share, l10n.creditsRuleShare, l10n.creditsRuleShareValue),
              _buildRuleItem(Icons.person_add, l10n.creditsRuleInvite, l10n.creditsRuleInviteValue),
              const SizedBox(height: 16),
              Text(l10n.creditsTipLow, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orangeAccent.withOpacity(0.2)),
                ),
                child: Text(
                  l10n.creditsTipBeta,
                  style: const TextStyle(
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
              child: Text(l10n.creditsGotIt),
            ),
          ],
        ),
      );
    }

    void _showMasteryInfo(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.masteredRuleTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.masteredRuleIntro, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.sentiment_satisfied_alt,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.masteredExpert,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sentiment_neutral, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(l10n.masteredMedium,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.sentiment_dissatisfied,
                      color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(l10n.masteredNewbie,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Text(l10n.masteredRuleOutro,
                  style:
                      const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.masteredUnderstood),
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

    return _DailyCheckInOnEnter(
      ref: ref,
      child: Scaffold(
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
                                  user.displayName ?? AppLocalizations.of(context)!.profileSetNickname,
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
                          label: AppLocalizations.of(context)!.profileKnowledgePoints,
                          value: L10nNumbers.profileMasteredCount(context, masteredCount),
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
                                label: AppLocalizations.of(context)!.profileMyCredits,
                                value: statsAsync.when(
                                  data: (stats) => '${stats.credits}',
                                  loading: () => '...',
                                  error: (_, __) => '0',
                                ),
                                icon: Icons.stars,
                                color: const Color(0xFFFFB300),
                                isDark: isDark,
                                subtitle: statsAsync.when(
                                  data: (stats) => L10nNumbers.profileShareClicksLine(
                                      context, stats.shareClicks),
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
                  _SectionHeader(title: AppLocalizations.of(context)!.settingsSection, isDark: isDark),
                  const SizedBox(height: 16),

                  Consumer(
                    builder: (context, ref, child) {
                      final onboardingState = ref.watch(onboardingProvider);
                      return _GlassTile(
                        icon: Icons.school_outlined,
                        title: AppLocalizations.of(context)!.settingsTutorial,
                        subtitle: onboardingState.isAlwaysShowTutorial
                            ? AppLocalizations.of(context)!.settingsTutorialOn
                            : AppLocalizations.of(context)!.settingsTutorialDefault,
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
                          title: AppLocalizations.of(context)!.settingsShareNotes,
                          subtitle: shareNotesPublic
                              ? AppLocalizations.of(context)!.settingsShareNotesOn
                              : AppLocalizations.of(context)!.settingsShareNotesOff,
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
                    title: AppLocalizations.of(context)!.appearance,
                    subtitle: isDark
                        ? AppLocalizations.of(context)!.appearanceDark
                        : AppLocalizations.of(context)!.appearanceLight,
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
                    icon: Icons.language,
                    title: AppLocalizations.of(context)!.language,
                    subtitle: ref.watch(localeProvider).outputLocale == 'zh'
                        ? AppLocalizations.of(context)!.languageChinese
                        : AppLocalizations.of(context)!.languageEnglish,
                    isDark: isDark,
                    onTap: () => _showLanguagePicker(context, ref),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

                    if (FirebaseAuth.instance.currentUser?.email != null &&
                      FirebaseAuth.instance.currentUser?.email!.isNotEmpty == true) ...[
                    _GlassTile(
                      icon: Icons.lock_reset_outlined,
                      title: AppLocalizations.of(context)!.securityQuestion,
                      subtitle: AppLocalizations.of(context)!.securityQuestionSubtitle,
                      isDark: isDark,
                      onTap: () => _showSecurityQuestionDialog(context),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _buildAdhdSettings(context, ref, isDark),
                  const SizedBox(height: 24),

                  _GlassTile(
                    icon: Icons.visibility_off_outlined,
                    title: AppLocalizations.of(context)!.hiddenContent,
                    subtitle: AppLocalizations.of(context)!.hiddenContentSubtitle,
                    isDark: isDark,
                    onTap: () => context.push('/profile/hidden'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

                  _GlassTile(
                    icon: Icons.contact_support_outlined,
                    title: AppLocalizations.of(context)!.contactUs,
                    subtitle: AppLocalizations.of(context)!.contactSubtitle,
                    isDark: isDark,
                    onTap: () => showDialog(
                        context: context,
                        builder: (_) => const ContactFeedbackDialog(
                              feedbackSource: 'profile',
                            )),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                  ),
                  const SizedBox(height: 12),

                  _GlassTile(
                    icon: Icons.info_outline,
                    title: AppLocalizations.of(context)!.aboutReado,
                    subtitle: AppLocalizations.of(context)!.aboutReadoSubtitle,
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
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.logout,
                          style: const TextStyle(
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
          title: AppLocalizations.of(context)!.settingsAdhdTitle,
          subtitle: adhdSettings.isEnabled ? AppLocalizations.of(context)!.settingsAdhdOn : AppLocalizations.of(context)!.settingsAdhdOff,
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
                    Text(AppLocalizations.of(context)!.settingsAdhdMode,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildModeChip(ref, AppLocalizations.of(context)!.settingsAdhdColor, AdhdReadingMode.color,
                            adhdSettings.mode, isDark),
                        const SizedBox(width: 8),
                        _buildModeChip(ref, AppLocalizations.of(context)!.settingsAdhdBold, AdhdReadingMode.bold,
                            adhdSettings.mode, isDark),
                        const SizedBox(width: 8),
                        _buildModeChip(ref, AppLocalizations.of(context)!.settingsAdhdHybrid, AdhdReadingMode.hybrid,
                            adhdSettings.mode, isDark),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.settingsAdhdStrength,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.grey[400] : Colors.grey[700])),
                    const SizedBox(height: 12),
                    Row(
                      children: AdhdIntensity.values.map((intensity) {
                        final label = switch (intensity) {
                          AdhdIntensity.low =>
                            AppLocalizations.of(context)!.settingsAdhdIntensityLow,
                          AdhdIntensity.medium =>
                            AppLocalizations.of(context)!.settingsAdhdIntensityMedium,
                          AdhdIntensity.high =>
                            AppLocalizations.of(context)!.settingsAdhdIntensityHigh,
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildIntensityChip(ref, label, intensity,
                              adhdSettings.intensity, isDark),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.settingsAdhdTip,
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
        ClipboardData(text: AppLocalizations.of(context)!.sharePersonalCopy(shareUrl)));

    // 3. 奖励积分 (动作奖励)
    ref.read(creditProvider.notifier).rewardShare(amount: 10);

    // 4. 显示提示（不展示长链接，文案更大更清晰）
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
                Text(AppLocalizations.of(context)!.shareSuccessReward,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.shareCopiedToClipboard,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context)!.sharePasteToFriends,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 6),
            Text(AppLocalizations.of(context)!.shareFriendJoinReward,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
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

/// 进入个人中心时尝试领取每日签到并提示
class _DailyCheckInOnEnter extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Widget child;

  const _DailyCheckInOnEnter({required this.ref, required this.child});

  @override
  ConsumerState<_DailyCheckInOnEnter> createState() => _DailyCheckInOnEnterState();
}

class _DailyCheckInOnEnterState extends ConsumerState<_DailyCheckInOnEnter> {
  bool _tried = false;

  @override
  Widget build(BuildContext context) {
    if (!_tried && FirebaseAuth.instance.currentUser != null) {
      _tried = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryClaimAndMarkSeen());
    }
    return widget.child;
  }

  Future<void> _tryClaimAndMarkSeen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dataService = widget.ref.read(dataServiceProvider);
    final alreadyClaimed = await dataService.getDailyCheckInClaimedToday();
    if (!alreadyClaimed) {
      final result = await dataService.claimDailyCheckIn();
      widget.ref.invalidate(dailyCheckInClaimedTodayProvider);
      widget.ref.read(creditProvider.notifier).refresh();
      if (mounted) {
        final credits = result['credits'] ?? 20;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10nNumbers.checkInCreditsReceived(context, credits)),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('今日已签到，已领取 20 积分'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    await markCheckInSeenToday(widget.ref);
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
      title: Text(AppLocalizations.of(context)!.profileEditProfile,
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
              Text(AppLocalizations.of(context)!.profileChooseAvatar,
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
                  labelText: AppLocalizations.of(context)!.profileNicknameLabel,
                  hintText: AppLocalizations.of(context)!.profileNicknameHint,
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
          child: Text(AppLocalizations.of(context)!.cancel),
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
              : Text(AppLocalizations.of(context)!.profileSave),
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

/// 密保问题列表（与 Cloud Functions 一致）
List<String> _securityQuestions(BuildContext context) => [
  AppLocalizations.of(context)!.securityQuestions0,
  AppLocalizations.of(context)!.securityQuestions1,
  AppLocalizations.of(context)!.securityQuestions2,
  AppLocalizations.of(context)!.securityQuestions3,
  AppLocalizations.of(context)!.securityQuestions4,
];

void _showLanguagePicker(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(l10n.languageEnglish),
            onTap: () {
              ref.read(localeProvider.notifier).setLocaleCode('en');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: Text(l10n.languageChinese),
            onTap: () {
              ref.read(localeProvider.notifier).setLocaleCode('zh');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    ),
  );
}

void _showSecurityQuestionDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => const _SecurityQuestionDialog(),
  );
}

class _SecurityQuestionDialog extends StatefulWidget {
  const _SecurityQuestionDialog();

  @override
  State<_SecurityQuestionDialog> createState() => _SecurityQuestionDialogState();
}

class _SecurityQuestionDialogState extends State<_SecurityQuestionDialog> {
  int _selectedIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final answer = _answerController.text.trim();
    if (answer.length < 2) {
      setState(() => _errorMsg = AppLocalizations.of(context)!.securityAnswerMin);
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseFunctions.instance.httpsCallable('setSecurityQuestion').call({
        'questionId': _selectedIndex,
        'answer': answer,
      });
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.securitySetSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;
      setState(() => _errorMsg = e.message ?? AppLocalizations.of(context)!.securitySetFailed);
    } catch (e) {
      if (!context.mounted) return;
      setState(() => _errorMsg = AppLocalizations.of(context)!.errorNetwork);
    } finally {
      if (context.mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.securitySetDialogTitle, style: TextStyle(color: textColor)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context)!.securitySetDialogIntro, style: TextStyle(color: hintColor, fontSize: 13)),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedIndex,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.securitySelectQuestion,
                border: const OutlineInputBorder(),
              ),
              items: List.generate(_securityQuestions(context).length, (i) => DropdownMenuItem(value: i, child: Text(_securityQuestions(context)[i], overflow: TextOverflow.ellipsis))),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedIndex = v ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.securityAnswerLabel,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _errorMsg = null),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: hintColor)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(AppLocalizations.of(context)!.profileSave),
        ),
      ],
    );
  }
}
