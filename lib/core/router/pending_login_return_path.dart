/// 登录后待跳转路径（内存存储，不依赖 URL 解析）
/// 业界常见做法：跳登录前存 returnUrl，登录成功后从这里取并跳转，避免 URL 中 ? 截断等问题
class PendingLoginReturnPath {
  static String? _path;

  static void set(String path) {
    _path = path;
  }

  /// 取出并清除，登录成功后调用
  static String? take() {
    final p = _path;
    _path = null;
    return p;
  }
}
