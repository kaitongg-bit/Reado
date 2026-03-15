// Centralized prompt helpers for AI generation.
// Use outputLocale 'zh' | 'en' to control output language.
// Keep in sync with functions/prompts.js for backend jobs.

/// Language instruction line for JSON/card output (zh or en).
String languageInstruction(String outputLocale) {
  return outputLocale == 'en'
      ? '**Important: All output must be in English.**'
      : '**重要提示：所有输出内容必须使用简体中文，即使原文是英文。**';
}

/// Instruction for card body language (no leading number).
String cardBodyLanguageRequirement(String outputLocale) {
  return outputLocale == 'en'
      ? '**Language**: All output must be in English.'
      : '**语言要求**：输出的所有内容必须使用简体中文。';
}
