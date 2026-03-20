import 'package:quick_pm/models/knowledge_module.dart';

/// 知识库卡片/列表展示用标题与描述（官方库、默认库随语言切换；底层 Firestore 仍可为中文）。
abstract final class ModuleDisplayStrings {
  /// 是否为默认知识库（含历史中文名与英文 default/Default）
  static bool isDefaultModuleTitle(String title) {
    final t = title.trim();
    final lower = t.toLowerCase();
    return t == '默认知识库' || lower == 'default';
  }

  static String moduleTitle(KnowledgeModule m, String outputLocale) {
    final en = outputLocale == 'en';
    if (m.isOfficial) {
      switch (m.id) {
        case 'A':
          return en ? 'STAR Method' : 'STAR 面试法';
        case 'B':
          return en ? 'Reado Guide' : 'Reado 官方指南';
        default:
          return m.title;
      }
    }
    if (isDefaultModuleTitle(m.title)) {
      return en ? 'default' : '默认知识库';
    }
    return m.title;
  }

  static String moduleDescription(KnowledgeModule m, String outputLocale) {
    final en = outputLocale == 'en';
    if (m.isOfficial) {
      switch (m.id) {
        case 'A':
          return en
              ? 'Behavioral interviews: Situation, Task, Action, Result'
              : '行为面试金标准：情境、任务、行动、结果';
        case 'B':
          return en
              ? 'Get started: how to break down knowledge effectively'
              : '新手必读：如何像黑客一样拆解知识';
        default:
          return m.description;
      }
    }
    if (isDefaultModuleTitle(m.title)) {
      return en ? 'Your default library' : '系统预设的默认知识库';
    }
    return m.description;
  }

  /// 教程/STAR 模块定位（不依赖标题语言）
  static bool isStarOfficialModule(KnowledgeModule m) =>
      m.isOfficial && m.id == 'A';
}
