import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';

/// 忘记密码：支持「发送重置邮件」与「密保找回」两种方式
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  /// 第一步：输入邮箱
  bool _stepEmail = true;
  /// 第二步（密保）：已拉取的密保问题
  int? _questionId;
  String? _questionText;

  @override
  void dispose() {
    _emailController.dispose();
    _answerController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMsg != null) setState(() => _errorMsg = null);
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = '请填写邮箱');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('重置邮件已发送，请查收。未收到可查看垃圾邮件或使用密保找回。'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '发送失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToSecurityStep() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = '请先填写邮箱');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('getSecurityQuestion').call({'email': email});
      final data = result.data as Map<dynamic, dynamic>?;
      if (!mounted) return;
      final id = data?['questionId'] as int?;
      final text = data?['questionText'] as String?;
      if (id == null || text == null) {
        setState(() => _errorMsg = '未设置密保，请使用邮件重置');
        return;
      }
      setState(() {
        _questionId = id;
        _questionText = text;
        _stepEmail = false;
        _isLoading = false;
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.message ?? '获取密保问题失败';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = '网络异常，请稍后重试';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitSecurityReset() async {
    final email = _emailController.text.trim();
    final answer = _answerController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (answer.isEmpty) {
      setState(() => _errorMsg = '请填写密保答案');
      return;
    }
    if (newPwd.length < 6) {
      setState(() => _errorMsg = '新密码至少 6 位');
      return;
    }
    if (newPwd != confirm) {
      setState(() => _errorMsg = '两次输入的密码不一致');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseFunctions.instance.httpsCallable('resetPasswordWithSecurityAnswer').call({
        'email': email,
        'answer': answer,
        'newPassword': newPwd,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('密码已重置，请使用新密码登录'), behavior: SnackBarBehavior.floating),
      );
      context.pop();
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.message ?? '重置失败');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = '网络异常，请稍后重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final inputFill = isDark ? Colors.grey.shade800 : Colors.grey.shade50;
    final inputBorder = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final accentColor = const Color(0xFFFF8A65);

    return Scaffold(
      appBar: AppBar(
        title: Text('忘记密码', style: TextStyle(color: textColor, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => _stepEmail ? context.pop() : setState(() { _stepEmail = true; _questionId = null; _questionText = null; _errorMsg = null; }),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                if (_stepEmail) ...[
                  Text('输入注册邮箱，可选择以下任一方式找回密码：', style: TextStyle(color: hintColor, fontSize: 14)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _clearError(),
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '电子邮箱',
                      hintStyle: TextStyle(color: hintColor),
                      prefixIcon: Icon(Icons.email_outlined, color: hintColor, size: 22),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('发送重置邮件', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('若收不到邮件（如国内邮箱），可使用密保找回', style: TextStyle(color: hintColor, fontSize: 12)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _goToSecurityStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: inputBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('通过密保找回', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ] else ...[
                  Text(_questionText ?? '', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    onChanged: (_) => _clearError(),
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '密保答案',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    onChanged: (_) => _clearError(),
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '新密码（至少 6 位）',
                      hintStyle: TextStyle(color: hintColor),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: hintColor, size: 22),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    onChanged: (_) => _clearError(),
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '再次输入新密码',
                      hintStyle: TextStyle(color: hintColor),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: hintColor, size: 22),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: inputBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitSecurityReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('确认重置密码', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
