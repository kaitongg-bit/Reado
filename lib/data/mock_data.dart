import '../models/feed_item.dart';

class MockData {
  static List<FeedItem> get initialFeedItems {
    final baseItems = [
      // Example 1: PM Role Definition
      FeedItem(
        id: '101',
        moduleId: 'A',
        title: '什么是产品经理？(What is a PM)',
        pages: [
          OfficialPage(
            '''
# 产品经理的角色定义

产品经理 (Product Manager) 是负责产品全生命周期管理的专业人员。硅谷著名投资人 Ben Horowitz 曾说：“产品经理是产品的 CEO。”

### 核心职责 (The Big 3)
1.  **产品策略 (Strategy)**：决定做什么（Vision）、为谁做（Target User）、为什么做（Why）。
2.  **执行落地 (Execution)**：撰写文档（PRD）、协调研发设计（Cross-functional）、把控进度（Roadmap）。
3.  **用户洞察 (Research)**：数据分析、用户访谈、市场调研。

### 常见误区
*   **PM 不是经理**：你通常没有行政权力 (No Authority)，必须通过**影响力** (Influence) 来领导团队。
*   **PM 不是“接需求的人”**：不要只做传声筒，要思考需求背后的价值。

### 核心能力模型
*   **同理心**：站在用户角度思考。
*   **逻辑思维**：拆解复杂问题。
*   **沟通能力**：在不同职能间翻译语言。
            ''',
            flashcardQuestion: 'PM 最核心的领导力来源是什么？',
            flashcardAnswer: '非职权影响力 (Influence without Authority)。因为 PM 通常不是研发或设计的行政主管，必须依靠愿景、逻辑和数据来说服团队。',
          ),
        ],
      ),

      // Example 2: Requirement Analysis
      FeedItem(
        id: '102',
        moduleId: 'A',
        title: '真伪需求：福特的快马',
        pages: [
          OfficialPage(
            '''
# 用户需求 vs 产品需求

在产品经理的日常工作中，最容易犯的错误就是把“用户想要什么”直接等同于“产品要做什么”。

### 经典案例：福特的快马
亨利·福特曾说过一句名言：“如果我问人们想要什么，他们会说想要一匹更快的马。”

*   **User Want (表面)**: 更快的马。
*   **User Need (本质)**: 更快地从 A 到达 B。
*   **Product (方案)**: 汽车。

### 深层洞察
用户往往受限于当前的认知（他们只知道马），无法构想未知的解决方案（汽车）。

### 5 Whys 分析法
通过连续追问“为什么”，我们可以找到问题的根本原因。
*   Q: 为什么要更快的马？ -> A: 怕迟到。
*   Q: 为什么怕迟到？ -> A: 路太远。
*   Q: 核心痛点是**通勤效率**。
            ''',
            flashcardQuestion: '“用户想要更快的马”中，用户的真实痛点是什么？',
            flashcardAnswer: '更高的通勤效率（更短的时间到达目的地），而不是对“马”这种生物的执着。',
          ),
        ],
      ),

      // Example 103: MVP Thinking
      FeedItem(
        id: '103',
        moduleId: 'A',
        title: 'MVP：最小可行性产品',
        pages: [
          OfficialPage(
             '''
# Minimum Viable Product (MVP)

MVP 是精益创业（Lean Startup）的核心概念。它的定义是：用最小的成本，验证最大的假设。

### 为什么要做 MVP？
1.  **降低试错成本**：避免开发了半年，上线发现没人用。
2.  **快速获取反馈**：尽早把产品推向市场，根据用户真实反馈迭代。

### 经典案例：Dropbox
Dropbox 的创始人并没有先开发复杂的文件同步代码，而是先做了一个 **3分钟的演示视频** (Demo Video)。
*   **假设**：用户需要一个多端同步的文件系统。
*   **MVP**：一个视频，演示“如果是这样会有多爽”。
*   **结果**：等待列表一夜暴增 75,000 人。

### 误区
MVP 不是“半成品”或“烂产品”。它必须是 **Viable**（可用的），必须能解决核心问题，哪怕功能很简陋。
            ''',
            flashcardQuestion: 'MVP 的核心目的是什么？',
            flashcardAnswer: '验证假设 (Validating Assumptions)。MVP 不是为了做产品而做，而是为了学习（Learning）用户是否真的需要这个东西。',
          ),
        ],
      ),

      // --- Module B Examples ---
      FeedItem(
        id: 'b01',
        moduleId: 'B',
        title: '案例拆解：抖音的成瘾性机制',
        pages: [
          OfficialPage(
            '''
# 抖音的成瘾性机制

刷抖音为什么停不下来？从心理学和产品设计的角度来看，抖音完美运用了“斯金纳箱” (Skinner Box) 理论。

### 1. 变量奖励 (Variable Reward)
你永远不知道下一个视频是什么，这种不确定性带来了多巴胺的爆发。

### 2. 极低的操作成本
单手竖划。没有“选择”的负担。在其他平台你还要想看哪个，在抖音你只需要“跳过”不喜欢的。

### 3. 被动式沉浸
全屏显示，隐藏状态栏。让用户失去时间感。

### 4. 算法的冷启动
抖音通过前 10 个视频快速建立你的兴趣画像，不仅看你点什么，还看你的**完播率**。
            ''',
            flashcardQuestion: '为什么“竖划切换”比“瀑布流选择”更有助于沉浸？',
            flashcardAnswer: '因为它将用户的认知成本降到了最低。瀑布流需要用户进行“选择决策”，而竖划让用户进入“被动接受”状态，减少了思考中断。',
          ),
        ],
      ),

      // --- Module C: Lab Items ---
      FeedItem(
        id: 'c01',
        moduleId: 'C',
        title: '实操：使用 Coze 搭建你的第一个 AI Bot',
        pages: [
          OfficialPage(
            '''
# 实操：使用 Coze 搭建 AI Bot

在本教程中，我们将使用字节跳动旗下的 Coze (扣子) 平台，在 10 分钟内搭建一个“产品经理面试助手”。

### Step 1: 注册与创建
1. 访问 [coze.cn](https://www.coze.cn)。
2. 点击“创建 Bot”，给它起个名字叫“Offer 收割机”。

### Step 2: 编写提示词 (Prompt)
在左侧的人设与回复逻辑中输入：
> 你是一个资深的产品经理面试官，擅长用 5 Whys 和 STAR 法则拆解问题。你的目标是指出用户回答中的逻辑漏洞。

### Step 3: 添加插件
点击“插件” -> “添加工具”，搜索并添加“Google Search”或“新闻搜索”，让你的 Bot 具备实时搜索能力。

### 💻 移动端用户注意
建议在电脑端打开 Coze 进行操作，本页面仅提供图文指引。
            ''',
            flashcardQuestion: '在 Coze 中，决定 Bot 行为逻辑的核心部分是什么？',
            flashcardAnswer: '提示词 (Prompt / Role Description)。它定义了 AI 的性格、知识背景和回复限制。',
          ),
        ],
      ),

      // --- Module D: War Room Items ---
      FeedItem(
        id: 'd01',
        moduleId: 'D',
        title: '【金标准】STAR 法则回答：请介绍一次你最有成就感的项目',
        pages: [
          OfficialPage(
            '''
# 面试金指标：STAR 法则

当你被问到“最有成就感的项目”时，千万不要记流水账。使用 STAR 法则结构化你的回答。

### 1. Situation (情景)
当时公司面临什么挑战？（例：APP 转化率在 3 个月内下降了 20%）。

### 2. Task (任务)
你的具体目标是什么？（例：在 1 个月内修复核心漏斗，将转化率提升回原水平）。

### 3. Action (行动) - 重点
**你**做了什么？（例：通过 SQL 分析发现支付页跳出率最高，进行了 3 组 A/B 测试，优化了三步支付流程为一键内购）。

### 4. Result (结果)
最终量化的产出。（例：支付转化率提升了 15%，带动月流水增加 50 万）。

---
### ⚔️ 专属功能
点击下方的“克隆”，AI 将引导你将这个模板转化为你的真实简历项目。
            ''',
            flashcardQuestion: 'STAR 法则中的 R 代表什么，为什么重要？',
            flashcardAnswer: 'Result (结果)。面试官通过量化的结果来判断你的工作价值和对业务的实际贡献。',
          ),
        ],
      ),
    ];
    
    // Auto-generate some more dummy items for variety
    final dummyItems = List.generate(20, (index) {
      final module = index % 4 == 0 ? 'A' : (index % 4 == 1 ? 'B' : (index % 4 == 2 ? 'C' : 'D'));
      return FeedItem(
        id: '90$index',
        moduleId: module,
        title: '[$module模块] 进阶知识点 #$index',
        pages: [
          OfficialPage(
            '# 进阶内容 $index\n\n此处为 $module 模块的内容占位。\n\n### 关键点\n1. 持续学习\n2. 深度思考',
            flashcardQuestion: '模块 $module 的核心精神？',
            flashcardAnswer: '不断迭代，快速反馈。',
          )
        ],
      );
    });

    return [...baseItems, ...dummyItems];
  }
}
