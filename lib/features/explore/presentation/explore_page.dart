import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_background.dart';

/// Knowledge Marketplace - Explore Page
/// Displays official knowledge bases for discovery and user-sold knowledge bases
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Global App Background
          const AppBackground(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Fixed Header
                _buildHeader(context, isDark),

                // Search Bar
                _buildSearchBar(context, isDark),

                // Tab Bar
                _buildTabBar(context, isDark),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOfficialTab(isDark),
                      _buildCreatorTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              '探索',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // My Sales Button
          TextButton.icon(
            onPressed: () => _showComingSoon(context, '我的售卖'),
            icon: Icon(
              Icons.storefront_outlined,
              size: 16,
              color: const Color(0xFFEA580C),
            ),
            label: Text(
              '售卖',
              style: TextStyle(
                color: const Color(0xFFEA580C),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: '搜索知识库...',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _showComingSoon(context, '搜索「$value」');
            }
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TabBar(
        controller: _tabController,
        // Cleaner underline indicator
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3,
            color: isDark ? Colors.white : Colors.black87,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 40),
          borderRadius: BorderRadius.circular(2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent, // Remove default divider

        labelColor: isDark ? Colors.white : Colors.black87,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,

        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),

        overlayColor: MaterialStateProperty.all(
            Colors.transparent), // No ripple for clean look

        tabs: [
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined,
                    size: 18, color: const Color(0xFF0D9488)),
                const SizedBox(width: 8),
                const Text('官方精选'),
              ],
            ),
          ),
          Tab(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    size: 18, color: const Color(0xFFEA580C)),
                const SizedBox(width: 8),
                const Text('创作者广场'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialTab(bool isDark) {
    // Filter by search query
    final filteredItems = _officialItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item['title']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['description']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState(isDark, '没有找到相关知识库');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _KnowledgeCard(
          title: item['title']!,
          description: item['description']!,
          cardCount: int.parse(item['count']!),
          emoji: item['emoji']!,
          isOfficial: true,
          isFree: item['isFree'] == 'true',
          price: item['price'],
          onTap: () => _showComingSoon(context, item['title']!),
        );
      },
    );
  }

  Widget _buildCreatorTab(bool isDark) {
    // Filter by search query
    final filteredItems = _communityItems.where((item) {
      if (_searchQuery.isEmpty) return true;
      return item['title']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['description']!
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          item['author']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredItems.isEmpty) {
      return _buildEmptyState(isDark, '没有找到相关知识库');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _CommunityKnowledgeCard(
          title: item['title']!,
          description: item['description']!,
          cardCount: int.parse(item['count']!),
          authorName: item['author']!,
          authorAvatar: item['avatar']!,
          price: item['price']!,
          rating: double.parse(item['rating']!),
          salesCount: int.parse(item['sales']!),
          onTap: () => _showComingSoon(context, item['title']!),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rocket_launch,
                color: Color(0xFF0D9488),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '即将上线',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '「$title」功能正在开发中\n敬请期待！',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('知道了',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fake data for official knowledge bases
final List<Map<String, String>> _officialItems = [
  {
    'title': '硬核知识入门',
    'description': '从零开始掌握高效学习方法论',
    'count': '25',
    'emoji': '🎯',
    'isFree': 'true',
    'price': '',
  },
  {
    'title': '产品经理必备',
    'description': '系统化产品思维与实战技巧',
    'count': '32',
    'emoji': '💼',
    'isFree': 'true',
    'price': '',
  },
  {
    'title': '高效阅读术',
    'description': '快速吸收书籍精华的秘诀',
    'count': '18',
    'emoji': '📚',
    'isFree': 'false',
    'price': '¥9.9',
  },
  {
    'title': '思维导图精通',
    'description': '用可视化提升思考效率',
    'count': '22',
    'emoji': '🧠',
    'isFree': 'false',
    'price': '¥12.9',
  },
  {
    'title': 'AI 时代生存指南',
    'description': '掌握 AI 工具，提升 10x 效率',
    'count': '30',
    'emoji': '🤖',
    'isFree': 'false',
    'price': '¥19.9',
  },
  {
    'title': '极简写作法',
    'description': '高效输出清晰有力的文字',
    'count': '15',
    'emoji': '✍️',
    'isFree': 'false',
    'price': '¥6.9',
  },
];

// Fake data for community knowledge bases
final List<Map<String, String>> _communityItems = [
  {
    'title': 'iOS 面试八股文',
    'description': '覆盖 Swift、ObjC、架构设计',
    'count': '85',
    'author': '程序员小王',
    'avatar': 'W',
    'price': '¥29.9',
    'rating': '4.8',
    'sales': '1234',
  },
  {
    'title': '投资理财入门',
    'description': '建立正确的财富观与投资思维',
    'count': '45',
    'author': '财经达人',
    'avatar': 'F',
    'price': '¥19.9',
    'rating': '4.6',
    'sales': '892',
  },
  {
    'title': '英语口语精进',
    'description': '地道表达与日常会话场景',
    'count': '120',
    'author': 'English Pro',
    'avatar': 'E',
    'price': '¥39.9',
    'rating': '4.9',
    'sales': '2156',
  },
  {
    'title': '心理学通识',
    'description': '洞察人性，提升情商与沟通力',
    'count': '38',
    'author': '心理咨询师小李',
    'avatar': 'L',
    'price': '¥15.9',
    'rating': '4.7',
    'sales': '567',
  },
  {
    'title': '前端面试宝典',
    'description': 'React、Vue、JS 核心知识点',
    'count': '95',
    'author': '大厂前端',
    'avatar': 'D',
    'price': '¥35.9',
    'rating': '4.8',
    'sales': '1876',
  },
  {
    'title': '数据分析实战',
    'description': 'SQL、Python、可视化全覆盖',
    'count': '68',
    'author': '数据小姐姐',
    'avatar': 'S',
    'price': '¥25.9',
    'rating': '4.7',
    'sales': '743',
  },
];

/// Official Knowledge Base Card
class _KnowledgeCard extends StatelessWidget {
  final String title;
  final String description;
  final int cardCount;
  final String emoji;
  final bool isOfficial;
  final bool isFree;
  final String? price;
  final VoidCallback onTap;

  const _KnowledgeCard({
    required this.title,
    required this.description,
    required this.cardCount,
    required this.emoji,
    required this.isOfficial,
    required this.isFree,
    this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji & Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    if (isFree)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '免费',
                          style: TextStyle(
                            color: const Color(0xFF0D9488),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          price ?? '',
                          style: TextStyle(
                            color: const Color(0xFFEA580C),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Description
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Card Count
                Row(
                  children: [
                    Icon(
                      Icons.style_outlined,
                      size: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$cardCount 张卡片',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Community Creator Knowledge Card
class _CommunityKnowledgeCard extends StatelessWidget {
  final String title;
  final String description;
  final int cardCount;
  final String authorName;
  final String authorAvatar;
  final String price;
  final double rating;
  final int salesCount;
  final VoidCallback onTap;

  const _CommunityKnowledgeCard({
    required this.title,
    required this.description,
    required this.cardCount,
    required this.authorName,
    required this.authorAvatar,
    required this.price,
    required this.rating,
    required this.salesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author Row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFEA580C).withOpacity(0.2),
                      child: Text(
                        authorAvatar,
                        style: TextStyle(
                          color: const Color(0xFFEA580C),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authorName,
                        style: TextStyle(
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Description
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Rating & Sales
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '已售 $salesCount',
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Price & Card Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: const Color(0xFFEA580C),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$cardCount 张',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
