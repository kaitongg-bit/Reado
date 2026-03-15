/**
 * Prompt templates by output locale (zh | en).
 * Used by processExtractionJob to generate outline and cards in the user's language.
 */

/**
 * @param {'zh'|'en'} locale
 * @param {object} opts - { contentLen, minPoints, maxPoints, pointRange, modeOutlineInstructions, content }
 */
function getOutlinePrompt(locale, opts) {
    const { contentLen, minPoints, maxPoints, pointRange, modeOutlineInstructions, content } = opts;
    if (locale === 'en') {
        return `
You are a senior educational content expert. Quickly analyze the learning material and identify core knowledge points.

${modeOutlineInstructions}

## Task
1. Read the learning material (about ${contentLen} characters).
2. Identify at least ${minPoints} and at most ${maxPoints} independent knowledge points. More content should yield more points; do not output only 3-5 big chunks.
3. Summarize each point with a concise title (10-20 words).

## Output format
Output valid JSON only, no other text.
**Important: All output must be in English.**

{
  "topics": [
    {"title": "Topic 1 title", "category": "Category", "difficulty": "Easy|Medium|Hard"},
    {"title": "Topic 2 title", "category": "Category", "difficulty": "Medium"}
  ]
}

## Learning material:
${content.substring(0, 30000)}
`;
    }
    // zh (default)
    return `
你是一位资深的教育内容专家。请快速分析用户提供的学习资料，识别出其中的核心知识点。

${modeOutlineInstructions}

## 任务
1. 阅读用户的学习资料（当前约 ${contentLen} 字）
2. **必须至少识别出 ${minPoints} 个、最多 ${maxPoints} 个**独立的核心知识点。内容越长，知识点数量应越多，严禁只输出 3～5 个大块；请按内容密度合理拆分。
3. 每个知识点用一个简洁的标题概括（10-20字）

## 输出格式
严格按照以下 JSON 格式输出（只输出 JSON，不要有其他文字）。
**重要提示：所有输出内容必须使用简体中文，即使原文是英文。**

{
  "topics": [
    {"title": "知识点1的标题", "category": "分类", "difficulty": "Easy|Medium|Hard"},
    {"title": "知识点2的标题", "category": "分类", "difficulty": "Medium"}
  ]
}

## 用户的学习资料：
${content.substring(0, 30000)}
`;
}

/**
 * @param {'zh'|'en'} locale
 * @param {object} opts - mode, modeInstructions, title, content, topic, isPodcast
 */
function getCardPrompt(locale, opts) {
    const { mode, modeInstructions, title, content, topic, isPodcast } = opts;
    if (locale === 'en') {
        if (isPodcast) {
            return `
You are a **popular-science podcast** expert: explain the knowledge point in dialogue form for listeners who are beginners and want to understand quickly.

${modeInstructions}

## Topic title
${title}

## Reference material
${content.substring(0, 30000)}

## Requirements
1. **Host B**: Must ask "Why?", "Can you give a real-life example?", "I didn't get that, can you simplify?". At least half of B's lines should be questions or follow-ups.
2. **Host A**: Answer in plain language; use everyday analogies when helpful. Explain terms before continuing.
3. **content field**: Dialogue only. Prefix each line with "Host A:" or "Host B:", then newline and text; double newline between turns. No Markdown.
4. **Flashcard**: question and answer each 100-200 words, in English.
5. Output a single JSON object only.

## Output format (JSON only)
{
  "title": "${title}",
  "category": "${topic.category || 'AI Generated'}",
  "difficulty": "${topic.difficulty || 'Medium'}",
  "content": "Host A:\\n[first line]\\n\\nHost B:\\n[question]\\n\\nHost A:\\n[answer]\\n\\n...",
  "flashcard": {
    "question": "Concrete test question",
    "answer": "Concise but complete answer"
  }
}
`;
        }
        return `
You are a senior educational content expert. Generate a detailed knowledge card for the following topic.

${modeInstructions}

## Topic title
${title}

## Reference material
${content.substring(0, 30000)}

## Requirements
1. **Body**: 300-800 words. ${mode === 'grandma' ? 'Use plain language and everyday analogies.' : (mode === 'phd' ? 'Use plain language and strict logic; no analogies.' : 'Use "what → why → how" structure.')}
2. **Flashcard**: One concrete question + concise answer (100-200 words).
3. Use Markdown.
4. **Language**: All output must be in English.

## Output format (JSON only)
{
  "title": "${title}",
  "category": "${topic.category || 'AI Generated'}",
  "difficulty": "${topic.difficulty || 'Medium'}",
  "content": "# Title\\n\\n[Body content, at least 300 words]",
  "flashcard": {
    "question": "Concrete test question",
    "answer": "Concise but complete answer"
  }
}
`;
    }
    // zh
    if (isPodcast) {
        return `
你是一位**通俗播客**内容专家：用对话形式把知识点讲给「零基础、记性一般、希望一听就懂」的听众。假设听众不够聪明，需要多问、多举例、多重复重点。

${modeInstructions}

## 知识点标题
${title}

## 参考资料（从中提取相关内容）
${content.substring(0, 30000)}

## 硬性要求
1. **主持人B**：不能只会说「好的」「然后呢」。B 要替听众问出「为什么？」「能举个生活中的例子吗？」「这里我没懂，能再说简单点？」「和 XXX 有啥区别？」。B 的发言里至少一半以上要是**疑问或追问**，这样对话才好学。
2. **主持人A**：用极简大白话回答，必要时用生活类比（买菜、做饭、日常事）。遇到术语先解释再继续。被 B 问到时再展开，不要一口气倒完。
3. **content 字段**：纯对话稿。每句对白前写「主持人A:」或「主持人B:」，换行写内容；段与段之间两个换行。禁止 #、**、列表等 Markdown。
4. **Flashcard**：question 与 answer 各 100-200 字，简体中文。
5. 输出只包含一个 JSON 对象，不要其他文字。

## 输出格式（只输出 JSON）
{
  "title": "${title}",
  "category": "${topic.category || 'AI Generated'}",
  "difficulty": "${topic.difficulty || 'Medium'}",
  "content": "主持人A:\\n[第一段对白]\\n\\n主持人B:\\n[追问或疑问]\\n\\n主持人A:\\n[用大白话/举例回答]\\n\\n主持人B:\\n[再问或确认]\\n\\n...",
  "flashcard": {
    "question": "具体的测试问题",
    "answer": "简洁但完整的答案"
  }
}
`;
    }
    return `
你是一位资深的教育内容专家。请针对以下知识点，生成一张详细的知识卡片。

${modeInstructions}

## 知识点标题
${title}

## 参考资料（从中提取相关内容）
${content.substring(0, 30000)}

## 要求
1. **正文内容**：必须生成 300-800 字的详细解释。${mode === 'grandma' ? "采用极简大白话和生活类比。" : (mode === 'phd' ? "采用极简大白话，严密逻辑拆解，禁止类比。" : "采用\"是什么 → 为什么 → 怎么做\"的结构。")}
2. **Flashcard**：一个具体的测试问题 + 简洁但完整的答案（100-200字）
3. 使用 Markdown 格式。
4. **语言要求**：输出的所有内容必须使用简体中文。

## 输出格式
严格按照以下 JSON 格式输出：

{
  "title": "${title}",
  "category": "${topic.category || 'AI Generated'}",
  "difficulty": "${topic.difficulty || 'Medium'}",
  "content": "# 标题\\n\\n[在此处填写详细的知识点正文内容，不少于300字]",
  "flashcard": {
    "question": "具体的测试问题",
    "answer": "简洁但完整的答案"
  }
}
`;
}

/**
 * Mode-specific instructions for outline (by locale).
 */
function getModeOutlineInstructions(locale, mode) {
    if (locale === 'en') {
        return mode === 'grandma'
            ? 'Use "plain language" style: identify the most basic, accessible core points; titles should be simple and clear.'
            : (mode === 'phd' ? 'Use "strict logic" style: plain language but very rigorous; no flashy analogies, only logical structure.' : (mode === 'podcast' ? 'Identify points suitable for dialogue explanation; keep titles concise for podcast topics.' : ''));
    }
    return mode === 'grandma'
        ? '采用极简大白话风格：识别出最基础、最通俗的核心知识点，标题要平实直白。'
        : (mode === 'phd' ? '采用智障博士生风格：极简大白话，但逻辑极严密，不要任何花哨类比，直接提取硬核逻辑支柱。' : (mode === 'podcast' ? '识别适合用对话讲解的核心知识点，标题简洁便于作为播客话题。' : ''));
}

/**
 * Mode-specific instructions for card body (by locale).
 */
function getModeInstructions(locale, mode) {
    if (locale === 'en') {
        if (mode === 'grandma') {
            return `
## Important: Plain language style
- No jargon; if you must use a term, explain it with an everyday analogy.
- Include a very down-to-earth analogy (e.g. shopping, cooking, daily life).
- Be direct; no small talk, go straight to the content.
`;
        }
        if (mode === 'phd') {
            return `
## Important: Strict logic style
- Target: explain to someone who is very logical but thinks simply.
- Use plain language; avoid jargon and long sentences. No extra spaces in text.
- Logic only: no emotional analogies; use clear cause-effect and facts.
- Be direct; no small talk.
`;
        }
        if (mode === 'podcast') {
            return `
## Podcast dialogue: accessible + Host B must ask and challenge
- Format: content must be dialogue only with "Host A:" and "Host B:" alternating. No Markdown. Two newlines between turns.
- Host B: represents the confused listener. B must often ask "Why?", "Can you give an example?", "I didn't get that", "How is that different from X?". At least 2/3 of B's lines should be questions or follow-ups.
- Plain language; assume zero background. Use simple words and everyday analogies. A explains in small steps and repeats key points.
- 6-12 turns. Use "Host A" and "Host B" only.
`;
        }
        return '';
    }
    // zh
    if (mode === 'grandma') {
        return `
## 🚨 重要：采用"极简大白话"风格 🚨
- **语言风格**：严禁使用专业术语。如果必须使用，必须通过"生活化类比"进行降维解释。
- **类比要求**：必须包含一个极其生活化、接地气的类比（如：买菜、做饭、点外卖等）。
- **讲解要求**：亲切直白。禁止任何寒暄，直接开始讲解知识点本身。
`;
    }
    if (mode === 'phd') {
        return `
## 🚨 重要：采用"智障博士生"级别拆解 🚨
- **目标**：像是在给逻辑非常严密、但认知极简的人解释。
- **语言风格**：必须使用**极简的大白话**，傻子都能听懂的语言。严禁堆砌专业术语，严禁使用长句。**严禁在文字之间添加任何多余的空格或空格占位**。
- **逻辑要求**：禁止任何感性类比（如：买菜、带孩子）。必须通过严密的逻辑推导、事实陈述、因果链条来拆解核心。
- **语气**：直白。禁止任何寒暄，直接开始讲解知识点本身。
`;
    }
    if (mode === 'podcast') {
        return `
## 🚨 播客对话稿：通俗好学 + B 必须追问质疑 🚨
- **格式**：正文 content 只能是「主持人A:」「主持人B:」交替的纯文本，禁止 Markdown。每段对白前写「主持人A:」或「主持人B:」，换行写内容，段与段之间两个换行。
- **主持人B 的人设**：B 代表「听得不太懂、想搞明白」的听众。B **必须**经常：问「为什么？」、问「能举个生活中的例子吗？」、说「这里我没懂，能再说简单点吗？」、问「那和 XXX 有啥区别？」。禁止 B 只会「好的」「然后呢」「明白了」敷衍附和；至少 2/3 的 B 的发言要带疑问或追问。
- **通俗易懂**：假设听众零基础、记不住复杂东西。用**极简大白话**，少用术语，必要时用生活类比（买菜、做饭、日常事）。A 要拆成小步讲，重复重点，被 B 问到时再讲透。
- **轮数**：6-12 轮对白，有问有答、有来有回。称呼固定「主持人A」「主持人B」。
`;
    }
    return '';
}

module.exports = {
    getOutlinePrompt,
    getCardPrompt,
    getModeOutlineInstructions,
    getModeInstructions,
};
