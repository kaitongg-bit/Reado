import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:quick_pm/config/api_config.dart';
import 'package:quick_pm/core/prompts/app_prompts.dart';
import 'package:quick_pm/core/providers/ai_settings_provider.dart';
import 'package:quick_pm/core/services/proxy_http_client.dart';

/// 对话式拆解：用一次模型调用生成「像真人」的回复，并输出结构化动作（勿用于扣费，扣费由客户端校验后执行）。
class DeconstructChatOrchestrator {
  DeconstructChatOrchestrator._();

  static Future<DeconstructOrchestratorResult?> run({
    required String outputLocale,
    required String conversationTranscript,
    required String modulesJson,
    required String currentModeName,
    required String? pendingSummary,
    required bool justParsedThisTurn,
    required String parseFactLine,
  }) async {
    final key = ApiConfig.getApiKey();
    if (key.isEmpty) return null;

    final proxyUrl = ApiConfig.geminiProxyUrl;
    final client = proxyUrl.isNotEmpty ? ProxyHttpClient(proxyUrl) : null;

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: key,
      httpClient: client,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.75,
        topP: 0.95,
        maxOutputTokens: 900,
      ),
    );

    final langRule = languageInstruction(outputLocale);
    final langName = outputLocale == 'en' ? 'English' : '简体中文';

    final system = '''
你是 Reado 里「AI 拆解」对话页的助手，**昵称囤囤鼠**（一只爱囤知识、帮用户把资料啃碎的小助手；英文场景可自称 TunTun or “your hoarder hamster buddy”）。
说话像真人朋友：自然、简短，不要客服腔。

$langRule
回复语言：$langName
assistant_message 里可使用 Markdown（**加粗** 等），客户端会正确渲染。

【知识库列表】（set_module_id 必须填下列某个 id，或 null）
$modulesJson

【当前拆解风格代码】$currentModeName
用户可口头切换；对应 set_mode：standard（标准）, grandma（大白话）, phd（直白逻辑）, podcast（播客感）。

【当前状态】
- 是否已有待拆解正文：${pendingSummary == null ? '无' : '有'}
${pendingSummary != null ? '- 摘要：$pendingSummary' : ''}
- 本回合是否刚完成本地解析：$justParsedThisTurn
- 客观数据（口语转述，勿照抄字段名）：$parseFactLine

【必做：有正文时每轮都要提】
只要「有待拆解正文」，assistant_message 里**必须**包含两层信息（可融在一段话里）：
1) **拆解风格**：当前是哪种、用户可以说什么话来换（举例：「换成大白话」「用播客风」）。
2) **知识库**：默认会存进哪个库（用展示名）、用户可以说什么来换库（举例：「存到默认知识库」「换到官方那个」）。
若用户本句就是在改风格/改库，用 set_mode / set_module_id 落实，并在回复里确认。

【材料认定】
用户自己打的问题、话题、长段话都算合法材料；禁止再说「必须先有外链/文件」。

【无关、捣乱、连续说不清】
先轻松接一句（幽默或共情），再温柔拉回拆解主题。若用户明显在抬杠、连番跑题、或对话多轮仍无法进入正题，把 suggest_fallback_form 设为 true（客户端会提示用表单）。

【提交与清空】
- justParsedThisTurn=true 时：同一回合 request_submit 必须为 false。
- request_submit：仅当已有正文且用户明确同意扣积分开始后台任务。
- clear_pending：用户放弃、换一条、不拆了。

只输出 JSON，不要代码围栏：
{
  "assistant_message": "string",
  "set_mode": null,
  "set_module_id": null,
  "request_submit": false,
  "clear_pending": false,
  "suggest_fallback_form": false
}
''';

    final userBlock = '''
【对话记录】
$conversationTranscript

请根据**最后一条用户消息**和当前状态生成回复与动作。
''';

    try {
      final response = await model.generateContent([
        Content.text('$system\n\n$userBlock'),
      ]);
      final raw = response.text?.trim();
      if (raw == null || raw.isEmpty) return null;
      return DeconstructOrchestratorResult.fromJson(_extractJsonObject(raw));
    } catch (e, st) {
      debugPrint('DeconstructChatOrchestrator: $e\n$st');
      return null;
    }
  }

  static Map<String, dynamic> _extractJsonObject(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      final first = s.indexOf('{');
      final last = s.lastIndexOf('}');
      if (first >= 0 && last > first) {
        s = s.substring(first, last + 1);
      }
    }
    final decoded = jsonDecode(s);
    if (decoded is Map<String, dynamic>) return decoded;
    throw FormatException('not a json object');
  }
}

class DeconstructOrchestratorResult {
  DeconstructOrchestratorResult({
    required this.assistantMessage,
    this.setMode,
    this.setModuleId,
    required this.requestSubmit,
    required this.clearPending,
    required this.suggestFallbackForm,
  });

  final String assistantMessage;
  final AiDeconstructionMode? setMode;
  final String? setModuleId;
  final bool requestSubmit;
  final bool clearPending;
  final bool suggestFallbackForm;

  factory DeconstructOrchestratorResult.fromJson(Map<String, dynamic> j) {
    final msg = j['assistant_message'] as String? ?? '';
    final modeStr = j['set_mode'] as String?;
    final modId = j['set_module_id'] as String?;
    AiDeconstructionMode? mode;
    if (modeStr != null) {
      mode = switch (modeStr) {
        'standard' => AiDeconstructionMode.standard,
        'grandma' => AiDeconstructionMode.grandma,
        'phd' => AiDeconstructionMode.phd,
        'podcast' => AiDeconstructionMode.podcast,
        _ => null,
      };
    }
    return DeconstructOrchestratorResult(
      assistantMessage: msg,
      setMode: mode,
      setModuleId: (modId != null && modId.isNotEmpty) ? modId : null,
      requestSubmit: j['request_submit'] == true,
      clearPending: j['clear_pending'] == true,
      suggestFallbackForm: j['suggest_fallback_form'] == true,
    );
  }
}
