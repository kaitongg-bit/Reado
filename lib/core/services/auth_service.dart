import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 认证服务
/// 支持：匿名登录、Google 登录
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;

  // 当前用户流
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 当前用户
  User? get currentUser => _auth.currentUser;

  // 是否已登录
  bool get isSignedIn => currentUser != null;

  // 是否是匿名用户
  bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// 匿名登录
  Future<UserCredential?> signInAnonymously() async {
    try {
      debugPrint('🔐 尝试匿名登录...');
      final credential = await _auth.signInAnonymously();
      debugPrint('✅ 匿名登录成功: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('❌ 匿名登录失败: $e');
      return null;
    }
  }

  /// 邮箱密码登录
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      debugPrint('🔐 尝试邮箱密码登录: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ 邮箱登录成功: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ 邮箱登录失败: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ 邮箱登录未知错误: $e');
      throw Exception('登录失败，请稍后重试');
    }
  }

  /// 邮箱密码注册
  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      debugPrint('📝 尝试邮箱密码注册: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ 注册成功: ${credential.user?.email}');
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ 注册失败: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('❌ 注册未知错误: $e');
      throw Exception('注册失败，请稍后重试');
    }
  }

  /// 处理 Firebase 认证异常
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('该邮箱尚未注册');
      case 'wrong-password':
        return Exception('密码错误');
      case 'email-already-in-use':
        return Exception('该邮箱已被注册');
      case 'invalid-email':
        return Exception('邮箱格式不正确');
      case 'weak-password':
        return Exception('密码强度不足');
      case 'too-many-requests':
        return Exception('尝试次数过多，请稍后再试');
      default:
        return Exception(e.message ?? '认证失败');
    }
  }

  /// Google 登录
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔐 尝试 Google 登录...');

      // Web 平台
      if (kIsWeb) {
        // Web 使用 Firebase Auth 的 Google Provider
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });

        try {
          final credential = await _auth.signInWithPopup(googleProvider);
          debugPrint('✅ Google 登录成功: ${credential.user?.email}');
          return credential;
        } catch (e) {
          debugPrint('⚠️ Popup 登录被拦截或失败 ($e)，尝试 Redirect 模式...');
          await _auth.signInWithRedirect(googleProvider);
          return null;
        }
      }
      // 移动平台
      else {
        // 1. 触发 Google 登录流程
        _googleSignIn ??= GoogleSignIn();
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

        if (googleUser == null) {
          debugPrint('⚠️  用户取消了 Google 登录');
          return null;
        }

        // 2. 获取认证详情
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // 3. 创建 Firebase 凭证
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // 4. 使用凭证登录 Firebase
        final userCredential = await _auth.signInWithCredential(credential);
        debugPrint('✅ Google 登录成功: ${userCredential.user?.email}');
        return userCredential;
      }
    } catch (e) {
      debugPrint('❌ Google 登录失败: $e');
      rethrow;
    }
  }

  /// 检查重定向登录结果 (仅 Web)
  Future<void> checkRedirectResult() async {
    if (!kIsWeb) return;
    try {
      final credential = await _auth.getRedirectResult();
      if (credential.user != null) {
        debugPrint('✅ 通过 Redirect 恢复登录成功: ${credential.user?.email}');
      }
    } catch (e) {
      debugPrint('ℹ️ Redirect 检查结束 (无重定向或失败): $e');
    }
  }

  /// 升级匿名账号为 Google 账号
  Future<UserCredential?> linkAnonymousWithGoogle() async {
    try {
      if (!isAnonymous) {
        throw Exception('当前用户不是匿名用户');
      }

      debugPrint('🔗 尝试将匿名账号升级为 Google 账号...');

      // Web 平台
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        try {
          final credential = await currentUser!.linkWithPopup(googleProvider);
          debugPrint('✅ 升级成功: ${credential.user?.email}');
          return credential;
        } catch (e) {
          debugPrint('⚠️ Popup 升级失败 ($e)，尝试 Redirect...');
          await currentUser!.linkWithRedirect(googleProvider);
          return null;
        }
      }
      // 移动平台
      else {
        _googleSignIn ??= GoogleSignIn();
        final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential =
            await currentUser!.linkWithCredential(credential);
        debugPrint('✅ 升级成功: ${userCredential.user?.email}');
        return userCredential;
      }
    } catch (e) {
      debugPrint('❌ 账号升级失败: $e');
      rethrow;
    }
  }

  /// 退出登录
  Future<void> signOut() async {
    try {
      debugPrint('👋 退出登录...');
      await _auth.signOut();

      // Web 端使用 Firebase Auth 的 Popup 登录，不需要 (也不能) 调用 GoogleSignIn 插件的 signOut，
      // 因为如果没有配置 Client ID 会报错。
      if (!kIsWeb) {
        try {
          // 只在非 Web 端尝试退出 GoogleSignIn 插件会话
          await _googleSignIn?.signOut();
        } catch (e) {
          debugPrint('⚠️ Google Sign In signOut error (safe to ignore): $e');
        }
      }

      debugPrint('✅ 已退出登录');
    } catch (e) {
      debugPrint('❌ 退出失败: $e');
      rethrow;
    }
  }

  /// 获取用户显示名称
  String get displayName {
    if (currentUser == null) return '未登录';
    if (currentUser!.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!;
    }
    if (currentUser!.email != null) {
      return currentUser!.email!;
    }
    if (isAnonymous) {
      return '匿名用户';
    }
    return '用户 ${currentUser!.uid.substring(0, 6)}';
  }

  /// 获取用户头像 URL
  String? get photoURL => currentUser?.photoURL;
}
