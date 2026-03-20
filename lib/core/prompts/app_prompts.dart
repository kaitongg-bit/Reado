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

/// 卡片内 AI 对话（囤囤鼠）：随 [outputLocale] 使用中文或英文系统提示。
String aiTutorChatPrompt({
  required String contextContent,
  required String historyText,
  required String lastUserMessage,
  required String outputLocale,
}) {
  if (outputLocale == 'en') {
    return '''
You are an expert learning mentor. The user is studying the following material. Answer their questions based on this background.
Background:
"""
$contextContent
"""

Conversation so far:
$historyText

Answer the user's latest question ("$lastUserMessage").
Requirements:
1. **Direct answer**: Plain text (Markdown allowed), not JSON.
2. **Grounded**: Stay accurate to the background material.
3. **Clear and encouraging**: Concise, supportive tone. **Your entire reply must be in English.**
4. **Follow-up**: End with one short, thought-provoking question that goes deeper.

Output the answer only.
''';
  }
  return '''
你是一位资深的教育导师。用户正在学习以下内容。你需要基于这些内容回答用户的问题。
背景内容：
"""
$contextContent
"""

以下是对话记录：
$historyText

请回答用户最新的问题（"$lastUserMessage"）。
要求：
1. **直接回答**：不要使用 JSON 格式，直接输出纯文本（Markdown）。
2. **结合上下文**：解答必须基于背景内容，保持准确。
3. **通俗易懂**：用简洁、鼓励性的语言。**请全程使用简体中文回复。**
4. **追问**：在回答结束时，必须提出一个相关的、能引发思考的追问，引导用户更深一层。

请直接输出回答内容。
''';
}

/// 将选中对话整理为笔记：随 [outputLocale] 输出中文或英文 Q/A。
String aiSummarizeForPinPrompt({
  required String contextContent,
  required String selectedChatContent,
  required String outputLocale,
}) {
  if (outputLocale == 'en') {
    return '''
You are a smart note assistant. The user wants to turn a valuable conversation into a concise knowledge note.
Background (reference only):
"""
$contextContent
"""

Focus conversation (summarize this):
"""
$selectedChatContent
"""

Task:
Summarize only the "Focus conversation" into one structured takeaway. Use the background only to understand context; do not repeat it at length.
Requirements:
1. **Core insight**: Capture the main idea or method from the dialogue.
2. **Remove fluff**: Skip greetings and obvious filler.
3. **Format**:
   - Q: A short, strong question that captures the topic.
   - A: A polished answer using Markdown lists or bold for emphasis.
4. **Language**: **Write Q and A entirely in English.**
5. Output plain Q:/A: lines with real newlines (not the characters backslash-n).

Example:
Q: [core question]
A: [polished answer]
''';
  }
  return '''
你是一个智能笔记助手。用户的目标是将一段有价值的对话整理成精炼的知识点笔记。
背景内容（参考用）：
"""
$contextContent
"""

重点对话内容（需整理）：
"""
$selectedChatContent
"""

任务：
请仅基于"重点对话内容"中的信息，整理出一个结构化的知识点。背景内容仅用于帮助你理解上下文，不要大量重复背景内容。
要求：
1. **提炼核心**：归纳对话中 AI 解释的核心观点或方法论（干货）。
2. **脱水处理**：去除寒暄、废话和过于显而易见的信息。
3. **格式清晰**：
   - Q: 一个能概括这段对话核心议题的问题（简短有力）。
   - A: 经过整理的回答。使用 Markdown 列表或加粗来突出重点。
4. **语言**：**Q 与 A 必须使用简体中文。**
5. **直接输出**：不要使用 JSON，直接输出问答对。不要输出 "\\n" 字符本身，而是使用真正的换行。

输出示例：
Q: [核心问题]
A: [整理后的核心回答]
''';
}
