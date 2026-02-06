import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../models/feed_item.dart';
import 'srs_review_page.dart';

class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> {
  // Filters
  FeedItemMastery? _libraryFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateLibraryFilter(FeedItemMastery? filter) {
    setState(() {
      _libraryFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(allItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ SIMPLIFIED: Show ONLY favorited items (with optional filters)
    final filteredItems = allItems.where((item) {
      // First check: Must be favorited
      if (!item.isFavorited) return false;

      // Then apply mastery level filter if set
      if (_libraryFilter != null && item.masteryLevel != _libraryFilter) {
        return false;
      }

      // Finally apply search filter if query exists
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return item.title.toLowerCase().contains(query);
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('收藏', // Changed from "Your Vault" to "Favorites"
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
                color: (isDark ? Colors.black : Colors.white).withOpacity(0.5)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Ambient Background - Top Left
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A65)
                        .withOpacity(isDark ? 0.15 : 0.2),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // Ambient Background - Bottom Right
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(isDark ? 0.1 : 0.15),
                    blurRadius: 150,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Glassy Search & Filter Container
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            // Search Bar
                            TextField(
                              controller: _searchController,
                              style: TextStyle(
                                  color:
                                      isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText:
                                    '搜索收藏的卡片...', // Changed from "Search cards..."
                                hintStyle: TextStyle(
                                    color: isDark
                                        ? Colors.grey[500]
                                        : Colors.grey[500]),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Color(0xFFFF8A65),
                                  ),
                                  onPressed: () {
                                    // Search is already reactive via onChanged
                                    // This button can trigger focus loss or just be visual
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            // Filter Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _FilterChip(
                                      label: '全部',
                                      isSelected: _libraryFilter == null,
                                      isDark: isDark,
                                      onTap: () => _updateLibraryFilter(null)),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                      label: '生疏',
                                      isSelected: _libraryFilter ==
                                          FeedItemMastery.hard,
                                      color: Colors.redAccent,
                                      isDark: isDark,
                                      onTap: () => _updateLibraryFilter(
                                          FeedItemMastery.hard)),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                      label: '一般',
                                      isSelected: _libraryFilter ==
                                          FeedItemMastery.medium,
                                      color: Colors.orangeAccent,
                                      isDark: isDark,
                                      onTap: () => _updateLibraryFilter(
                                          FeedItemMastery.medium)),
                                  const SizedBox(width: 8),
                                  _FilterChip(
                                      label: '熟练',
                                      isSelected: _libraryFilter ==
                                          FeedItemMastery.easy,
                                      color: Colors.green,
                                      isDark: isDark,
                                      onTap: () => _updateLibraryFilter(
                                          FeedItemMastery.easy)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            return _ReviewCard(
                              items: filteredItems,
                              currentIndex: index,
                              isDark: isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, // Changed icon
              size: 64,
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            '还没有收藏任何卡片', // Changed from "No cards found"
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '在“学习”中点击❤️来收藏内容', // Hint text
            style: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
                fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final List<FeedItem> items;
  final int currentIndex;
  final bool isDark;

  const _ReviewCard({
    required this.items,
    required this.currentIndex,
    required this.isDark,
  });

  FeedItem get item => items[currentIndex];

  @override
  Widget build(BuildContext context) {
    // Glassmorphism Card Style
    final backgroundColor = isDark
        ? Colors.white.withOpacity(0.05)
        : Colors.white.withOpacity(0.65);

    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SRSReviewPage(
              items: items,
              initialIndex: currentIndex,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon / Type Indicator
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getModuleColor(item.moduleId).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getModuleIcon(item.moduleId),
                        color: _getModuleColor(item.moduleId)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.masteryLevel != FeedItemMastery.unknown)
                              _MasteryBadge(level: item.masteryLevel),
                          ],
                        )
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getModuleColor(String moduleId) {
    switch (moduleId) {
      case 'A':
        return Colors.blueAccent;
      case 'B':
        return Colors.orangeAccent;
      case 'C':
        return Colors.purpleAccent;
      case 'D':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'A':
        return Icons.auto_awesome;
      case 'B':
        return Icons.lightbulb;
      case 'C':
        return Icons.science;
      case 'D':
        return Icons.gavel;
      default:
        return Icons.article;
    }
  }
}

class _MasteryBadge extends StatelessWidget {
  final FeedItemMastery level;

  const _MasteryBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (level) {
      case FeedItemMastery.hard:
        color = Colors.red;
        text = '生疏';
        break;
      case FeedItemMastery.medium:
        color = Colors.orange;
        text = '一般';
        break;
      case FeedItemMastery.easy:
        color = Colors.green;
        text = '熟练';
        break;
      default:
        color = Colors.grey;
        text = '新';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final bool isDark;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      required this.isDark,
      this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF0D9488); // Default Teal

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[200]!)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
    );
  }
}
