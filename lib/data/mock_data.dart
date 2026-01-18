import '../models/feed_item.dart';

class MockData {
  static List<FeedItem> get initialFeedItems {
    return [
      // 模块 A：基础 (Fundamentals)
      FeedItem(
        id: '101',
        moduleId: 'A',
        title: '产品经理的角色定义',
        pages: [
          OfficialPage(
            '# 产品经理的角色定义\n\n产品经理 (Product Manager) 是负责产品全生命周期管理的专业人员。\n\n## 核心职责\n- 需求分析\n- 产品规划\n- 项目管理\n- 数据分析',
          ),
          OfficialPage(
            '## 常见误区\n\n很多人认为 PM 是 CEO，但实际上 PM 更多是**影响力**而非**权力**的体现。',
          ),
        ],
      ),
      FeedItem(
        id: '102',
        moduleId: 'A',
        title: '用户需求 vs 产品需求',
        pages: [
          OfficialPage(
            '# 需求转换\n\n用户想要的是“更快的马”，而产品需求是“汽车”。\n\n> 核心在于洞察背后的痛点 (Pain Point)。',
          ),
          // 模拟一个用户已经 pinned 的笔记
          UserNotePage(
            question: '如果不清楚用户的真实痛点怎么办？',
            answer: '可以通过 5Whys 分析法，连续问5个为什么，直到找到根因。',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
        nextReviewTime: DateTime.now().subtract(const Duration(hours: 1)), // 模拟需要复习
        intervalDays: 1,
      ),
      
      // 模块 B：案例 (Case Studies)
      FeedItem(
        id: '201',
        moduleId: 'B',
        title: '微信红包的爆发',
        pages: [
          OfficialPage(
            '# 2014 春节战役\n\n微信红包是通过“社交裂变”打破支付壁垒的经典案例。',
          ),
        ],
      ),

      // 模块 C：实操 (Lab)
      FeedItem(
        id: '301',
        moduleId: 'C',
        title: '使用 Figma 画第一个原型',
        pages: [
          OfficialPage(
            '# 准备工作\n\n1. 注册 Figma 账号\n2. 创建 New Design File\n3. 熟悉左侧 Layers 和右侧 Properties。',
          ),
          OfficialPage(
            '# Step 1: 绘制 Frame\n\n按 `F` 键，在画布上拖动，选择 `iPhone 14` 尺寸。',
          ),
        ],
      ),
    ];
  }
}
