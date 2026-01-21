import '../models/feed_item.dart';

class MockData {
  static List<FeedItem> get initialFeedItems {
    // 产品经理基础 (Module B) - 10个基础知识点
    final pmBasics = [
      FeedItem(
        id: 'b001',
        moduleId: 'B',
        title: '什么是产品经理？(What is a PM)',
        category: '职位理解',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# 产品经理的角色定义

产品经理 (Product Manager) 是负责产品全生命周期管理的专业人员。硅谷著名投资人 Ben Horowitz 曾说："产品经理是产品的 CEO。"

### 核心职责 (The Big 3)
1.  **产品策略 (Strategy)**：决定做什么（Vision）、为谁做（Target User）、为什么做（Why）。
2.  **执行落地 (Execution)**：撰写文档（PRD）、协调研发设计（Cross-functional）、把控进度（Roadmap）。
3.  **用户洞察 (Research)**：数据分析、用户访谈、市场调研。

### 常见误区
*   **PM 不是经理**：你通常没有行政权力 (No Authority)，必须通过**影响力** (Influence) 来领导团队。
*   **PM 不是"接需求的人"**：不要只做传声筒，要思考需求背后的价值。

### 核心能力模型
*   **同理心**：站在用户角度思考。
*   **逻辑思维**：拆解复杂问题。
*   **沟通能力**：在不同职能间翻译语言。
            ''',
            flashcardQuestion: 'PM 最核心的领导力来源是什么？',
            flashcardAnswer:
                '非职权影响力 (Influence without Authority)。因为 PM 通常不是研发或设计的行政主管，必须依靠愿景、逻辑和数据来说服团队。',
          ),
        ],
      ),
      FeedItem(
        id: 'b002',
        moduleId: 'B',
        title: '真伪需求：福特的快马',
        category: '需求分析',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# 用户需求 vs 产品需求

在产品经理的日常工作中，最容易犯的错误就是把"用户想要什么"直接等同于"产品要做什么"。

### 经典案例：福特的快马
亨利·福特曾说过一句名言："如果我问人们想要什么，他们会说想要一匹更快的马。"

*   **User Want (表面)**: 更快的马。
*   **User Need (本质)**: 更快地从 A 到达 B。
*   **Product (方案)**: 汽车。

### 深层洞察
用户往往受限于当前的认知（他们只知道马），无法构想未知的解决方案（汽车）。

### 5 Whys 分析法
通过连续追问"为什么"，我们可以找到问题的根本原因。
*   Q: 为什么要更快的马？ -> A: 怕迟到。
*   Q: 为什么怕迟到？ -> A: 路太远。
*   Q: 核心痛点是**通勤效率**。
            ''',
            flashcardQuestion: '"用户想要更快的马"中，用户的真实痛点是什么？',
            flashcardAnswer: '更高的通勤效率（更短的时间到达目的地），而不是对"马"这种生物的执着。',
          ),
        ],
      ),
      FeedItem(
        id: 'b003',
        moduleId: 'B',
        title: 'MVP：最小可行性产品',
        category: '产品策略',
        difficulty: 'Medium',
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
*   **MVP**：一个视频，演示"如果是这样会有多爽"。
*   **结果**：等待列表一夜暴增 75,000 人。

### 误区
MVP 不是"半成品"或"烂产品"。它必须是 **Viable**（可用的），必须能解决核心问题，哪怕功能很简陋。
            ''',
            flashcardQuestion: 'MVP 的核心目的是什么？',
            flashcardAnswer:
                '验证假设 (Validating Assumptions)。MVP 不是为了做产品而做，而是为了学习（Learning）用户是否真的需要这个东西。',
          ),
        ],
      ),
      FeedItem(
        id: 'b004',
        moduleId: 'B',
        title: '案例拆解：抖音的成瘾性机制',
        category: '产品设计',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# 抖音的成瘾性机制

刷抖音为什么停不下来？从心理学和产品设计的角度来看，抖音完美运用了"斯金纳箱" (Skinner Box) 理论。

### 1. 变量奖励 (Variable Reward)
你永远不知道下一个视频是什么，这种不确定性带来了多巴胺的爆发。

### 2. 极低的操作成本
单手竖划。没有"选择"的负担。在其他平台你还要想看哪个，在抖音你只需要"跳过"不喜欢的。

### 3. 被动式沉浸
全屏显示，隐藏状态栏。让用户失去时间感。

### 4. 算法的冷启动
抖音通过前 10 个视频快速建立你的兴趣画像，不仅看你点什么，还看你的**完播率**。
            ''',
            flashcardQuestion: '为什么"竖划切换"比"瀑布流选择"更有助于沉浸？',
            flashcardAnswer:
                '因为它将用户的认知成本降到了最低。瀑布流需要用户进行"选择决策"，而竖划让用户进入"被动接受"状态，减少了思考中断。',
          ),
        ],
      ),
      FeedItem(
        id: 'b005',
        moduleId: 'B',
        title: 'PRD 文档撰写要点',
        category: '文档能力',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# PRD 文档撰写要点

PRD (Product Requirements Document) 是产品经理最重要的交付物之一。

### 核心内容
1. **需求背景**：为什么要做这个功能？
2. **目标用户**：这个功能为谁服务？
3. **功能描述**：详细的功能说明
4. **交互流程**：用户如何使用
5. **优先级**：P0/P1/P2 划分
6. **成功指标**：如何衡量成功？

### 5W1H 法则
- Who：目标用户是谁？
- What：产品要做什么？
- When：什么时候发布？
- Where：在哪里使用？
- Why：为什么要这样做？
- How：如何实现？
            ''',
            flashcardQuestion: 'PRD 文档的核心作用是什么？',
            flashcardAnswer:
                '统一团队认知，减少返工，提高开发效率。它通过清晰描述产品需求，确保团队成员对产品目标、功能和实现方式达成一致。',
          ),
        ],
      ),
      FeedItem(
        id: 'b006',
        moduleId: 'B',
        title: '数据驱动决策',
        category: '数据分析',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# 数据驱动决策

优秀的产品经理不凭感觉做决策，而是用数据说话。

###关键指标
1. **DAU/MAU**：日活/月活用户数
2. **留存率**：次日/7日/30日留存
3. **转化率**：漏斗各环节转化情况
4. **ARPU**：平均每用户收入

### A/B 测试
通过对比测试验证假设：
- 设置对照组和实验组
- 只改变一个变量
- 收集足够样本后分析
- 基于数据做决策
            ''',
            flashcardQuestion: '为什么要进行 A/B 测试？',
            flashcardAnswer:
                '为了用科学方法验证假设，通过对比实验组和对照组的数据差异，客观评估新功能或改动的实际效果，避免主观判断导致的决策失误。',
          ),
        ],
      ),
      FeedItem(
        id: 'b007',
        moduleId: 'B',
        title: '用户画像与用户旅程',
        category: '用户研究',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# 用户画像与用户旅程

理解用户是产品成功的第一步。

### 用户画像 (Persona)
虚拟的典型用户，包含：
- **基本信息**：年龄、职业、收入
- **行为特征**：使用习惯、偏好
- **痛点需求**：遇到的问题

### 用户旅程地图
描述用户与产品互动的完整过程：
1. 发现阶段
2. 考虑阶段
3. 购买/使用阶段
4. 留存阶段
5. 推荐阶段

每个阶段关注不同的指标和优化点。
            ''',
            flashcardQuestion: '用户画像的核心价值是什么？',
            flashcardAnswer: '帮助团队形成对目标用户的统一认知，在做产品决策时能够站在真实用户的角度思考，避免自嗨式设计。',
          ),
        ],
      ),
      FeedItem(
        id: 'b008',
        moduleId: 'B',
        title: '竞品分析方法论',
        category: '市场研究',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# 竞品分析方法论

知己知彼，百战不殆。

### 分析维度
1. **产品定位**：目标用户、核心价值
2. **功能对比**：核心功能有哪些
3. **交互体验**：操作流程、视觉设计
4. **商业模式**：如何盈利
5. **数据表现**：用户规模、增长趋势

### SWOT 分析
- Strengths：竞品优势
- Weaknesses：竞品劣势
- Opportunities：市场机会
- Threats：潜在威胁

基于分析结果制定差异化策略。
            ''',
            flashcardQuestion: '竞品分析的最终目的是什么？',
            flashcardAnswer: '不是抄袭竞品，而是通过了解市场和对手，找到自己的差异化定位和突破点，制定更有效的产品策略。',
          ),
        ],
      ),
      FeedItem(
        id: 'b009',
        moduleId: 'B',
        title: '优先级排序：RICE 模型',
        category: '项目管理',
        difficulty: 'Hard',
        pages: [
          OfficialPage(
            '''
# RICE 优先级模型

面对一堆需求，如何决定先做哪个？

### RICE 公式
**Priority = (Reach × Impact × Confidence) / Effort**

- **Reach**：影响多少用户？
- **Impact**：影响程度如何？(3=巨大,2=高,1=中,0.5=低,0.25=最小)
- **Confidence**：有多确定？(百分比)
- **Effort**：需要多少人月？

### 示例
功能A: (1000 × 3 × 80%) / 2 = 1200
功能B: (500 × 2 × 100%) / 0.5 = 2000
→ 应该先做功能B

优先做高分数的需求。
            ''',
            flashcardQuestion: 'RICE 模型中的 Confidence 代表什么？',
            flashcardAnswer:
                '对估算的信心程度。如果你对Reach和Impact的判断很确定，Confidence就高；如果只是猜测，Confidence就低。这避免了过度自信导致的错误决策。',
          ),
        ],
      ),
      FeedItem(
        id: 'b010',
        moduleId: 'B',
        title: 'B端与C端产品的区别',
        category: '产品类型',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# B端与C端产品的区别

不同类型的产品，方法论完全不同。

### C端产品 (ToC)
- **用户**：个人消费者
- **决策链**：短，用户即决策者
- **关注点**：体验、情感、病毒传播
- **盈利**：广告、增值服务
- **例子**：抖音、微信

### B端产品 (ToB)
- **用户**：企业/组织
- **决策链**：长，涉及多方审批
- **关注点**：效率、ROI、可定制性
- **盈利**：订阅、License
- **例子**：钉钉、Salesforce

不同类型需要不同的PM技能组合。
            ''',
            flashcardQuestion: 'B端产品和C端产品最大的区别是什么？',
            flashcardAnswer:
                '决策路径和关注重点不同。B端产品的购买决策涉及多方（老板、财务、IT、用户），关注ROI和效率；C端产品用户即决策者，关注体验和情感满足。',
          ),
        ],
      ),
    ];

    // 硬核基础 (Module A) - 所有进阶内容
    final hardcore = List.generate(20, (index) {
      return FeedItem(
        id: 'a${100 + index}',
        moduleId: 'A',
        title: '[硬核] AI产品经理进阶 #${index + 1}',
        category: 'AI产品',
        difficulty: index < 5 ? 'Easy' : (index < 15 ? 'Medium' : 'Hard'),
        pages: [
          OfficialPage(
            '# AI产品经理进阶内容 #${index + 1}\n\n此处为硬核进阶内容占位。\n\n### 关键点\n1. AI技术理解\n2. 模型评估\n3. 数据标注\n4. 算法优化',
            flashcardQuestion: 'AI产品经理需要关注哪些核心指标？',
            flashcardAnswer: '模型准确率、响应时间、成本控制、用户满意度等。需要在技术性能和用户体验之间找到平衡。',
          )
        ],
      );
    });

    return [...pmBasics, ...hardcore];
  }
}
