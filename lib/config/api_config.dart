import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API 配置管理
///
/// 用于存储和管理 Gemini API Key
class ApiConfig {
  /// Gemini API Key
  ///
  /// 获取方式：
  /// 1. 开发阶段：环境变量 (flutter run --dart-define=GEMINI_API_KEY=...)
  /// 2. 本地配置：.env 文件 (GEMINI_API_KEY=...)
  /// 3. 分发/生产：建议结合后端或 Obfuscation 使用
  static String get geminiApiKey {
    // 优先使用命令行参数
    const envArg = String.fromEnvironment('GEMINI_API_KEY');
    if (envArg.isNotEmpty) return envArg;

    // 回退到 .env 文件配置
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// 检查 API Key 是否已配置
  static bool get isConfigured => geminiApiKey.isNotEmpty;

  /// 默认的免费 API Key（可选）
  ///
  /// ⚠️ 注意：这个 Key 会被编译到前端代码中，存在被滥用的风险
  /// 建议：
  /// 1. 设置每日调用限制（在 Google AI Studio）
  /// 2. 在应用中限制每个用户的使用次数
  /// 3. 引导用户添加自己的 API Key
  static const String defaultApiKey = String.fromEnvironment(
    'DEFAULT_GEMINI_KEY',
    defaultValue: '',
  );

  /// 获取有效的 API Key
  ///
  /// 优先级：
  /// 1. 环境变量中的 GEMINI_API_KEY
  /// 2. 默认的 fallback Key
  /// 3. 抛出异常（需要用户提供）
  static String getApiKey() {
    // 允许通过环境变量覆盖 Key (如果使用了代理，Key 可以为空或者是伪造的，因为 Worker 会注入)
    if (geminiProxyUrl.isNotEmpty) {
      // 如果配置了代理，允许 Key 为空 (或者返回一个占位符)
      if (geminiApiKey.isEmpty) return 'PROXY_MODE_PLACEHOLDER';
    }

    if (geminiApiKey.isNotEmpty) {
      return geminiApiKey;
    }

    if (defaultApiKey.isNotEmpty) {
      return defaultApiKey;
    }

    throw Exception('Gemini API Key 未配置\n'
        '请在个人中心添加你的 API Key\n'
        '或配置 GEMINI_PROXY_URL');
  }

  /// 获取 Gemini 代理地址 (用于 Cloudflare Worker)
  static String get geminiProxyUrl {
    const envArg = String.fromEnvironment('GEMINI_PROXY_URL');
    if (envArg.isNotEmpty) return envArg;
    return dotenv.env['GEMINI_PROXY_URL'] ?? '';
  }
}
