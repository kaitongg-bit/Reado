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
    if (geminiApiKey.isNotEmpty) {
      return geminiApiKey;
    }

    if (defaultApiKey.isNotEmpty) {
      return defaultApiKey;
    }

    throw Exception('Gemini API Key 未配置\n'
        '请在个人中心添加你的 API Key\n'
        '或使用 --dart-define=GEMINI_API_KEY=xxx 运行应用');
  }
}
