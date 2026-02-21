import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/widgets/app_background.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/pending_login_return_path.dart';
import '../../../core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 官网页主价值句，便于后续改文案或多语言
const String _kOnboardingValueProp =
    '把长文、课程、笔记变成可刷的知识卡片，随时复习、随时问 AI。';

/// 过程图单步：用于展开后的步骤/流程图展示
class _ProcessStep {
  final String label;
  final IconData icon;
  const _ProcessStep(this.label, this.icon);
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _isAuthView = false;
  bool _obscurePassword = true;
  /// 官网页「Reado 能做什么」当前展开的卡片索引，null 表示都收起
  int? _expandedFeatureIndex;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    // 检查是否有重定向回调（Web 端）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authService.checkRedirectResult();
    });

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) {
        final path = PendingLoginReturnPath.take();
        context.go(path != null && path.isNotEmpty ? path : '/');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _controller.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      // 跳转由 authStateChanges 监听器统一处理（含 returnUrl）
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('登录失败: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写邮箱和密码')),
      );
      return;
    }

    if (_isSignUpMode && _usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写用户名')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUpMode) {
        final username = _usernameController.text.trim();
        await _authService.signUpWithEmail(email, password,
            displayName: username);
      } else {
        await _authService.signInWithEmail(email, password);
      }
      if (!mounted) return;
      // 跳转由 authStateChanges 监听器统一处理（含 returnUrl）
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = _isAuthView;
    // 官网页与登录/注册页统一白底（Notion 风格），避免登录页内容较短时底部露出深色
    final isDark = isAuth ? Theme.of(context).brightness == Brightness.dark : false;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.white),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                // 登录/注册页背景固定为白，故始终用浅色样式，避免深色主题下出现黑框+白字
                child: isAuth
                    ? _buildAuthView(false, Colors.black87, Colors.grey[600])
                    : _buildIntroView(false, Colors.black87, Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _kContentMaxWidth = 900.0;

  Widget _buildIntroView(bool isDark, Color textColor, Color? subTextColor) {
    return Column(
      key: const ValueKey('IntroView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOnboardingTopBar(isDark, textColor),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 1. Hero：标题 + 价值句 + CTA，主视觉 reado_ip_banner.png（宽屏 Row / 窄屏 Column）
                      _buildHeroSection(context, textColor, subTextColor),
                      const SizedBox(height: 40),

                      // 2. 信任线（Notion 风格）
                      Text(
                        '学习者和职场人都在用 Reado 沉淀知识。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: subTextColor?.withOpacity(0.9) ?? Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // 3. Reado 能做什么（4 个卖点，用 IP 头像 + 对话式场景展示）
                      _buildSectionTitle(textColor, 'Reado 能做什么'),
                      const SizedBox(height: 20),
                      _buildFeatureDialogueCard(
                        index: 0,
                        isExpanded: _expandedFeatureIndex == 0,
                        onTap: () => setState(() {
                          _expandedFeatureIndex =
                              _expandedFeatureIndex == 0 ? null : 0;
                        }),
                        isDark: isDark,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        imagePath: 'assets/images/reado_ip_5_coder.png',
                        title: '智能拆解',
                        dialogue: '我丢了个链接进去，一会儿就拆成好几张卡片，太省事了。',
                        steps: const [
                          _ProcessStep('粘贴链接或上传 PDF', Icons.link),
                          _ProcessStep('AI 自动拆解', Icons.auto_awesome),
                          _ProcessStep('生成知识卡片', Icons.style),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureDialogueCard(
                        index: 1,
                        isExpanded: _expandedFeatureIndex == 1,
                        onTap: () => setState(() {
                          _expandedFeatureIndex =
                              _expandedFeatureIndex == 1 ? null : 1;
                        }),
                        isDark: isDark,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        imagePath: 'assets/images/reado_ip_1_reader.png',
                        title: '闪读记忆',
                        dialogue: '像刷短视频一样上下滑，碎片时间就能刷完一沓卡片。',
                        steps: const [
                          _ProcessStep('上下滑动切换卡片', Icons.swap_vert),
                          _ProcessStep('标记难易度', Icons.trending_up),
                          _ProcessStep('间隔复习', Icons.schedule),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureDialogueCard(
                        index: 2,
                        isExpanded: _expandedFeatureIndex == 2,
                        onTap: () => setState(() {
                          _expandedFeatureIndex =
                              _expandedFeatureIndex == 2 ? null : 2;
                        }),
                        isDark: isDark,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        imagePath: 'assets/images/reado_ip_7_idea.png',
                        title: '深度内化',
                        dialogue: '看不懂的地方直接问 AI，问完还能 Pin 成笔记，下次复习一起看。',
                        steps: const [
                          _ProcessStep('随时提问', Icons.chat_bubble_outline),
                          _ProcessStep('Pin 成笔记', Icons.push_pin),
                          _ProcessStep('复习时一起看', Icons.menu_book),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildFeatureDialogueCard(
                        index: 3,
                        isExpanded: _expandedFeatureIndex == 3,
                        onTap: () => setState(() {
                          _expandedFeatureIndex =
                              _expandedFeatureIndex == 3 ? null : 3;
                        }),
                        isDark: isDark,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        imagePath: 'assets/images/reado_ip_3_builder_v2.png',
                        title: '多端同步',
                        dialogue: '电脑上拆好的知识库，手机上也一样，通勤、睡前都能接着刷。',
                        steps: const [
                          _ProcessStep('网页端拆解与学习', Icons.computer),
                          _ProcessStep('自动同步', Icons.cloud_sync),
                          _ProcessStep('手机端接着刷', Icons.phone_android),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // 4. 引用线（Notion 风格）
                      Text(
                        '你的知识，随时可刷、随时可问。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: subTextColor ?? Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 48),

                      _buildOnboardingFooter(isDark, subTextColor),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const double _kHeroBannerBreakpoint = 700.0;

  Widget _buildHeroSection(
      BuildContext context, Color textColor, Color? subTextColor) {
    final width = MediaQuery.of(context).size.width;
    final useRow = width > _kHeroBannerBreakpoint;

    Widget textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '知识极速入脑',
          style: TextStyle(
            fontSize: useRow ? 40 : 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: textColor,
            height: 1.1,
            fontFamily: 'JinghuaSong',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _kOnboardingValueProp,
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
            color: subTextColor ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: useRow ? null : double.infinity,
          child: ElevatedButton(
            onPressed: () => setState(() => _isAuthView = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A65),
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '立即开始体验',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );

    Widget banner = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/reado_ip_banner.png',
        fit: BoxFit.contain,
        width: useRow ? 420 : null,
        height: useRow ? 280 : 220,
      ),
    );

    if (useRow) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: textBlock),
          const SizedBox(width: 40),
          banner,
        ],
      );
    }
    // 窄屏：图片在上，文字和「立即开始体验」在下
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        banner,
        const SizedBox(height: 32),
        textBlock,
      ],
    );
  }

  Widget _buildOnboardingTopBar(bool isDark, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kIsWeb ? 32 : 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/icon_1024x1024.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Reado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              fontFamily: 'JinghuaSong',
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUpMode = true;
                _isAuthView = true;
              });
            },
            child: Text('注册', style: TextStyle(color: textColor)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _isSignUpMode = false;
                _isAuthView = true;
              });
            },
            child: Text('登陆', style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingFooter(bool isDark, Color? subTextColor) {
    final linkColor = subTextColor ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.only(top: 48, bottom: 32),
      child: Column(
        children: [
          Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              TextButton(
                onPressed: () => context.go('/profile/about'),
                child: Text('支持', style: TextStyle(color: linkColor)),
              ),
              TextButton(
                onPressed: () => context.go('/profile/about'),
                child: Text('联系我们', style: TextStyle(color: linkColor)),
              ),
              TextButton(
                onPressed: () => context.go('/profile/about'),
                child: Text('用户协议', style: TextStyle(color: linkColor)),
              ),
              TextButton(
                onPressed: () => context.go('/profile/about'),
                child: Text('隐私政策', style: TextStyle(color: linkColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} Reado',
            style: TextStyle(
              fontSize: 12,
              color: linkColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(Color textColor, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  /// 功能卖点：IP 头像 + 对话式场景句，可展开看过程图
  Widget _buildFeatureDialogueCard({
    required int index,
    required bool isExpanded,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color? subTextColor,
    required String imagePath,
    required String title,
    required String dialogue,
    required List<_ProcessStep> steps,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded
                  ? const Color(0xFFFF8A65).withOpacity(0.4)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipOval(
                    child: Image.asset(
                      imagePath,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFFF8A65).withOpacity(0.2),
                        child: const Icon(
                            Icons.person, color: Color(0xFFFF8A65)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dialogue,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: subTextColor ?? Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: subTextColor ?? Colors.grey,
                    size: 28,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: Colors.black.withOpacity(0.08),
                ),
                const SizedBox(height: 16),
                _buildProcessSteps(steps, isDark, textColor, subTextColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 展开后的过程图：步骤条 + 箭头（文案一律换行展示，避免「粘贴链...」等被截断）
  Widget _buildProcessSteps(
    List<_ProcessStep> steps,
    bool isDark,
    Color textColor,
    Color? subTextColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 窄屏用竖排，宽屏用横排；提高阈值使手机端多用竖排
        final isNarrow = constraints.maxWidth < 520;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                _buildProcessStepNode(
                    steps[i], isDark, textColor, subTextColor),
                if (i < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Icon(
                      Icons.arrow_downward,
                      size: 20,
                      color: subTextColor ?? Colors.grey,
                    ),
                  ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              Expanded(
                child: _buildProcessStepNode(
                    steps[i], isDark, textColor, subTextColor),
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(top: 14, left: 4, right: 4),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: subTextColor ?? Colors.grey,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  /// 步骤节点：文案始终换行，不再用省略号（节点占满父级宽度以便横排时也能换行）
  Widget _buildProcessStepNode(
    _ProcessStep step,
    bool isDark,
    Color textColor,
    Color? subTextColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF8A65).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              step.icon,
              size: 20,
              color: const Color(0xFFFF8A65),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  /// 用例卡片。添加图片后可在此处使用 Image.asset(imagePath)：onboarding_use_study.png / onboarding_use_work.png / onboarding_use_life.png
  Widget _buildUseCaseCard({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A65).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A65).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFFF8A65), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 产品展示区。替换为 Image.asset('assets/images/onboarding_product_demo.png') 或视频可显示真实素材
  Widget _buildProductDemoPlaceholder(bool isDark, Color? subTextColor) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF8A65).withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android,
              size: 48,
              color: subTextColor ?? Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              '产品截图 / 演示图',
              style: TextStyle(
                fontSize: 14,
                color: subTextColor ?? Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 可选徽章/用户数图。替换为 Image.asset('assets/images/onboarding_badges.png') 可显示
  Widget _buildBadgesPlaceholder(bool isDark, Color? subTextColor) {
    return const SizedBox.shrink();
  }

  Widget _buildFeatureRow(
      {required IconData icon,
      required String title,
      required String subtitle,
      required bool isDark}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF8A65).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFFFF8A65), size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthView(bool isDark, Color textColor, Color? subTextColor) {
    // 普通黑白：浅色用黑、深色用白；输入框背景接近白/深灰，不用黄
    final hintColor = subTextColor ?? Colors.grey;
    final inputFill = isDark ? Colors.grey.shade800 : Colors.grey.shade50;
    final inputBorder = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final accentColor = const Color(0xFFFF8A65);
    return SingleChildScrollView(
      key: const ValueKey('AuthView'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
                    onPressed: () => setState(() => _isAuthView = false),
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/icon_1024x1024.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isSignUpMode ? '创建账号' : '登陆',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUpMode ? '开始你的知识内化之旅' : '继续你的学习',
                  style: TextStyle(fontSize: 14, color: hintColor),
                ),
                const SizedBox(height: 32),

                if (_isSignUpMode) ...[
                  TextField(
                    controller: _usernameController,
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '用户名',
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.person_outline, color: hintColor, size: 22),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: inputBorder),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: textColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '电子邮箱',
                    hintStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.email_outlined, color: hintColor, size: 22),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: textColor, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: '密码',
                    hintStyle: TextStyle(color: hintColor),
                    prefixIcon: Icon(Icons.lock_outline, color: hintColor, size: 22),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: hintColor,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isSignUpMode ? '注册' : '登陆',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _isSignUpMode = !_isSignUpMode),
                  child: Text(
                    _isSignUpMode ? '已有账号？登陆' : '没有账号？注册',
                    style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: inputBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('或', style: TextStyle(fontSize: 13, color: hintColor)),
                    ),
                    Expanded(child: Divider(color: inputBorder)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: inputBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => Icon(Icons.login, size: 22, color: textColor),
                        ),
                        const SizedBox(width: 10),
                        Text('使用 Google 登陆', style: TextStyle(fontSize: 15, color: textColor)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '登陆即表示同意用户协议与隐私政策',
                  style: TextStyle(fontSize: 12, color: hintColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
