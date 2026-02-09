import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_background.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isSignUpMode = false;
  bool _showEmailFields = false;
  bool _isAuthView = false;
  bool _obscurePassword = true;

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
        context.go('/');
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      context.go('/');
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

    setState(() => _isLoading = true);
    try {
      if (_isSignUpMode) {
        await _authService.signUpWithEmail(email, password);
      } else {
        await _authService.signInWithEmail(email, password);
      }
      if (!mounted) return;
      context.go('/');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Global App Background
          const AppBackground(),

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
                child: _isAuthView
                    ? _buildAuthView(isDark, textColor, subTextColor)
                    : _buildIntroView(isDark, textColor, subTextColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroView(bool isDark, Color textColor, Color? subTextColor) {
    return SingleChildScrollView(
      key: const ValueKey('IntroView'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero Image / Logo
            Hero(
              tag: 'logo',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8A65).withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/icon_1024x1024.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Reado',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.5,
                color: textColor,
                height: 1.0,
                fontFamily: 'JinghuaSong',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '知识极速入脑',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF8A65),
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 60),

            // Benefit points
            _buildFeatureRow(
              icon: Icons.auto_awesome_outlined,
              title: '智能拆解',
              subtitle: '长难内容 AI 一键解构成碎片化知识',
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              icon: Icons.style_outlined,
              title: '闪读记忆',
              subtitle: '像刷短视频一样刷知识卡片',
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              icon: Icons.psychology_outlined,
              title: '深度内化',
              subtitle: '内置 AI 导师，随时解答你的知识盲区',
              isDark: isDark,
            ),

            const SizedBox(height: 80),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () => setState(() => _isAuthView = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A65),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '立即开始体验',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
    return SingleChildScrollView(
      key: const ValueKey('AuthView'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Minimal Header back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => setState(() => _isAuthView = false),
              ),
            ),
            const SizedBox(height: 40),
            // Logo Small
            Hero(
              tag: 'logo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/icon_1024x1024.png',
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isSignUpMode ? '创建新账号' : '欢迎回来',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSignUpMode ? '开始你的知识内化之旅' : '继续探索未命名的知识领域',
              style: TextStyle(color: subTextColor),
            ),
            const SizedBox(height: 48),

            if (_showEmailFields) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: '电子邮箱',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A65),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isSignUpMode ? '立即注册' : '登录',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() => _isSignUpMode = !_isSignUpMode);
                },
                child: Text(
                  _isSignUpMode ? '已有账号？点击登录' : '没有账号？点击注册',
                  style: TextStyle(color: subTextColor),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('或者',
                        style:
                            TextStyle(color: subTextColor?.withOpacity(0.5))),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Google Login
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/53/Google_%22G%22_Logo.svg/512px-Google_%22G%22_Logo.svg.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.login, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '使用 Google 账号登录',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!_showEmailFields) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showEmailFields = true),
                child: Text(
                  '使用邮箱密码登录',
                  style: TextStyle(color: subTextColor),
                ),
              ),
            ],

            const SizedBox(height: 48),
            Text(
              '登录即代表同意用户协议与隐私政策',
              style: TextStyle(
                fontSize: 12,
                color: subTextColor?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
