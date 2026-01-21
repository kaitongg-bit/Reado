import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 认证服务
/// 支持：匿名登录、Google 登录
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

        final credential = await _auth.signInWithPopup(googleProvider);
        debugPrint('✅ Google 登录成功: ${credential.user?.email}');
        return credential;
      }
      // 移动平台
      else {
        // 1. 触发 Google 登录流程
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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
        final credential = await currentUser!.linkWithPopup(googleProvider);
        debugPrint('✅ 升级成功: ${credential.user?.email}');
        return credential;
      }
      // 移动平台
      else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
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
