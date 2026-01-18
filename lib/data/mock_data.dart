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
*   **PM 不是经理**：你通常没有行政权力（No Authority），必须通过**影响力**（Influence）来领导团队。
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

      // Example 3: MVP Thinking
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
    ];
    
    // Auto-generate 30 dummy items for testing
    final dummyItems = List.generate(30, (index) {
      final id = '90$index'; // 900, 901...
      
      return FeedItem(
        id: id,
        moduleId: 'A', // Put in "Fundamentals" module
        title: 'Mock Item #$index: 产品经理核心技能',
        pages: [
          OfficialPage(
            '# Mock Content $index\n\nThis is a generated mock item to test the list behavior.\n\n### Section 1\nLorem ipsum dolor sit amet.',
            flashcardQuestion: 'Question for item $index?',
            flashcardAnswer: 'Answer for item $index.',
          )
        ],
        // 不预设复习时间和难度，等用户收藏后才设置
      );
    });

    return [...baseItems, ...dummyItems];
  }
}
