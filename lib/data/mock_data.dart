import '../models/feed_item.dart';

class MockData {
  static List<FeedItem> get initialFeedItems {
    // -------------------------------------------------------------------------
    // Module A: STAR 面试法 (The Gold Standard)
    // -------------------------------------------------------------------------
    final starMethod = [
      FeedItem(
        id: 'a001',
        moduleId: 'A',
        title: '什么是 STAR 法则？',
        category: '核心概念',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# 行为面试的金标准：STAR

**STAR 法则**是全球顶尖科技公司（Amazon, Google, Meta）在行为面试（Behavioral Interview）中通用的评估标准。

它的核心逻辑是：**过去的行为是预测未来表现的最好指标。**

### 四大支柱
1.  **S - Situation (情境)**: 故事发生的背景。
2.  **T - Task (任务)**: 你面临的挑战或目标。
3.  **A - Action (行动)**: **你**具体做了什么？（这是最重要的部分）
4.  **R - Result (结果)**: 最终的成就在哪里？

面试官不关心这种“空话”：“我是一个很好的团队合作者。”
面试官关心的是：“请给我讲一次你不得不与一个难搞的同事合作的经历。”
            ''',
            flashcardQuestion: 'STAR 法则中，面试官最看重哪一个部分？',
            flashcardAnswer:
                'Action (行动)。因为只有“行动”才能展示你的个人能力、决策逻辑和软技能。背景和结果只是为了验证行动的有效性和真实性。',
          ),
        ],
      ),
      FeedItem(
        id: 'a002',
        moduleId: 'A',
        title: 'S - Situation：搭建舞台',
        category: '实战技巧',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# Situation：给故事一个张力

很多候选人在 S 阶段花费太多时间，讲了一堆无关紧要的公司背景。
**S 的目的是为了衬托 T 的难。**

### 好的 S 应该包含：
*   **紧迫性**：Timeline 非常紧。
*   **资源匮乏**：没有预算，没有人手。
*   **复杂度**：没人做过，且涉及多个部门。

### 例子
*   ❌ "我在腾讯做产品经理的时候，有一个项目..." (太干了)
*   ✅ "当时距离双11大促只有2周，我们的核心支付接口却突然出现了 1% 的丢单率，如果不解决，预计损失超过千万。" (张力拉满)
            ''',
            flashcardQuestion: 'Situation (情境) 部分的主要目的是什么？',
            flashcardAnswer:
                '为 Task (任务) 的艰巨性做铺垫。通过描述资源的匮乏、时间的紧迫或环境的复杂，来凸显后续 Action (行动) 的含金量。',
          ),
        ],
      ),
      FeedItem(
        id: 'a003',
        moduleId: 'A',
        title: 'T - Task：定义不可能',
        category: '实战技巧',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# Task：定义你的北极星

Task 必须简洁有力。它是你给自己定下的**具体的**、**可衡量的**目标。

### 常见的错误
把 Task 描述成老板给的任务。
*   ❌ "老板让我去修复这个 bug。"
*   ✅ "我决定不仅要修复这个 bug，还要建立一套自动化监控机制，彻底杜绝此类问题再次发生。"

**Ownership (主人翁感)** 通常就在 T 这一环节体现。是你主动选择了挑战，而不是被动接受了命令。
            ''',
            flashcardQuestion: '如何通过 Task 展现 Leadership (领导力)？',
            flashcardAnswer:
                '不要只描述被分配的任务，要描述你**主动设定**的更高标准的目标。展现出你面对困难时，敢于承担责任并重新定义问题的能力。',
          ),
        ],
      ),
      FeedItem(
        id: 'a004',
        moduleId: 'A',
        title: 'A - Action：你才是主角',
        category: '核心技巧',
        difficulty: 'Hard',
        pages: [
          OfficialPage(
            '''
# Action：把光打在自己身上

这是整个回答的核心，应该占据 60% 以上的篇幅。

### 致命错误：只说"我们"
很多候选人习惯说："然后**我们**开了个会，**我们**决定..."
面试官的潜台词是："那你在里面干嘛了？你是那个倒水的吗？"

### 黄金法则
*   多用 **"I" (我)**。
*   多用**动词**：I analyzed (分析), I proposed (提议), I negotiated (谈判), I built (构建)。
*   展示**决策过程**：不仅说你做了什么，还要说你**为什么**这么做（而不是那样做）。
            ''',
            flashcardQuestion: '在 Action 环节，为什么要避免过度使用 "We" (我们)？',
            flashcardAnswer:
                '因为面试官招聘的是**你**，而不是你的团队。过度使用 "We" 会掩盖你的个人贡献，让面试官无法评估你的独立能力和具体作用。',
          ),
        ],
      ),
      FeedItem(
        id: 'a005',
        moduleId: 'A',
        title: 'R - Result：数据说话',
        category: '实战技巧',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# Result：没有结果就是没做

一个没有 Result 的故事是烂尾的。

### 好的 Result 有三个特征：
1.  **量化 (Quantified)**：不要说 "提升了很多"，要说 "提升了 25%"。
2.  **对比 (Compared)**：不要说 "赚了100万"，要说 "比去年同期增长了 200%"。
3.  **影响力 (Impact)**：除了数据，还有什么深远影响？（比如：这套方案后来成为了全公司的标准模板）。

### 如果结果是失败的？
也可以讲！重点在于 **Learning (复盘)**。
"虽然项目失败了，但我总结了3个教训，并在下一个项目中应用，成功避免了..."
            ''',
            flashcardQuestion: '如果项目最终没有达到预期的数据指标，R 部分该要在怎么讲？',
            flashcardAnswer:
                '重点转向 **Learning (复盘与成长)**。诚实地量化差距，分析根本原因，并展示你如何将这次失败的经验转化为后续成功的基石。',
          ),
        ],
      ),
      FeedItem(
        id: 'a006',
        moduleId: 'A',
        title: '[实战] 亚马逊行为面试真题',
        category: '案例分析',
        difficulty: 'Hard',
        pages: [
          OfficialPage(
            '''
# 题目：Tell me about a time you disagreed with your manager.

### 错误示范
"老板非要改需求，我觉得不对，就跟他吵了一架。最后证明我是对的，老板没说话。"
(评价：固执、难以合作、缺乏情商)

### STAR 示范
*   **S**: 产品上线前夕，经理因为担心风险，突然要求砍掉这期核心功能。
*   **T**: 我需要在**不激怒经理**的前提下，用数据证明该功能的稳定性，确保如期上线。
*   **A**: 我没有当面反驳。私下里，我拉取了灰度测试的 5000 条用户数据，制作了一份对比报告。然后我约了经理喝咖啡，展示如果砍掉功能将导致的用户流失预期。
*   **R**: 经理被数据说服，同意保留功能。最终上线后，该功能贡献了 15% 的日活增长。经理还在周会上公开表扬了我的严谨。
            ''',
            flashcardQuestion: '在回答"与上级冲突"类问题时，Action 的核心不仅仅是证明"你是对的"，更重要的是什么？',
            flashcardAnswer:
                '**建设性的冲突处理方式 (Constructive Conflict Resolution)**。展示你如何通过数据、沟通和同理心来解决分歧，而不是单纯的情绪对抗或证明对方愚蠢。',
          ),
        ],
      ),
    ];

    // -------------------------------------------------------------------------
    // Module B: Reado 官方指南 (User Manual)
    // -------------------------------------------------------------------------
    final readoGuide = [
      FeedItem(
        id: 'b001',
        moduleId: 'B',
        title: '欢迎：不止是收藏，更是内化',
        category: '理念',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# 为什么你的收藏夹在吃灰？

在这个信息爆炸的时代，我们**囤积**了太多文章，却**内化**了太少知识。

Reado 的诞生就是为了解决这个问题。我们相信：**知识不应该是线性的长文，而应该是可交互的、原子化的小卡片。**

在这里，你不再是“读完”一篇文章，而是把文章“拆解”成一个个知识点，然后通过闪卡（Flashcards）真正把它装进脑子里。
            ''',
            flashcardQuestion: 'Reado 提倡的所谓“原子化知识”是什么意思？',
            flashcardAnswer:
                '将冗长的文章拆解为独立的、在这个概念下最小单位的知识点（卡片）。这样可以降低认知负担，便于单独复习、重组和建立连接。',
          ),
        ],
      ),
      FeedItem(
        id: 'b002',
        moduleId: 'B',
        title: '操作：像刷短视频一样刷知识',
        category: '基础',
        difficulty: 'Easy',
        pages: [
          OfficialPage(
            '''
# 极简手势指南

为了让你进入“心流”状态，我们设计了极简的手势系统：

### 1. 上下划动
在不同的知识点卡片之间切换。不喜欢？划走。感兴趣？停下来。

### 2. 左划 (Left Swipe) -> 详情
**这是最重要的手势。** 当你对卡片感兴趣时，**左划**进入深度阅读模式。

### 3. 右划 (Right Swipe) -> 收藏
标记为 **Like**。这些卡片会自动进入你的 Vault，并安排复习。
            ''',
            flashcardQuestion: '在 Reado 中，如果想查看某个知识点的详细解释，应该怎么操作？',
            flashcardAnswer: '左划 (Swipe Left)。这个动作模拟了“翻开书页”的感觉，带你从概览进入深度阅读。',
          ),
        ],
      ),
      FeedItem(
        id: 'b003',
        moduleId: 'B',
        title: '核心：Lab 拆解 + Vault 复习',
        category: '进阶',
        difficulty: 'Medium',
        pages: [
          OfficialPage(
            '''
# Reado 的双引擎

### 1. Lab (实验室) - 你的加工厂
觉得首页内容不够？把任何文章链接、PDF 扔进 Lab。
AI 引擎会自动提取核心观点，把它变成精美的知识卡片。**万物皆可拆解。**

### 2. Vault (金库) - 你的第二大脑
所有收藏的内容都会进入 Vault。
内置的 **SRS (间隔重复算法)** 会在你快忘记时，自动提醒你复习。告别“收藏即遗忘”。
            ''',
            flashcardQuestion: '为什么说 Vault 不仅仅是一个收藏夹？',
            flashcardAnswer:
                '因为它集成了 SRS (间隔重复系统)。普通的收藏夹是被动的仓库，而 Vault 会主动管理你的记忆周期，确保知识真正内化。',
          ),
        ],
      ),
    ];

    return [...starMethod, ...readoGuide];
  }
}
