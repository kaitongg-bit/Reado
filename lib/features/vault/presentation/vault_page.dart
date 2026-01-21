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
    final allItems = ref.watch(feedProvider);
    
    // Filter Logic
    final filteredItems = allItems.where((item) {
      // 1. Mastery Filter
      if (_libraryFilter != null && item.masteryLevel != _libraryFilter) {
        return false;
      }
      
      // 2. Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = item.title.toLowerCase().contains(query);
        // Can add more search fields if needed
        return matchesTitle;
      }
      
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Light background
      appBar: AppBar(
        title: const Text(
          'Review', 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Filter Button? Or maybe just rely on chips
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                 // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search cards...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All', 
                        isSelected: _libraryFilter == null, 
                        onTap: () => _updateLibraryFilter(null)
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Hard', 
                        isSelected: _libraryFilter == FeedItemMastery.hard, 
                        color: Colors.redAccent,
                        onTap: () => _updateLibraryFilter(FeedItemMastery.hard)
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Medium', 
                        isSelected: _libraryFilter == FeedItemMastery.medium, 
                        color: Colors.orangeAccent,
                        onTap: () => _updateLibraryFilter(FeedItemMastery.medium)
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Easy', 
                        isSelected: _libraryFilter == FeedItemMastery.easy, 
                        color: Colors.green,
                        onTap: () => _updateLibraryFilter(FeedItemMastery.easy)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: filteredItems.isEmpty 
              ? _buildEmptyState() 
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _ReviewCard(item: item);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No cards found',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final FeedItem item;

  const _ReviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SRSReviewPage(item: item)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
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
              child: Icon(_getModuleIcon(item.moduleId), color: _getModuleColor(item.moduleId)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
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
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
  
  Color _getModuleColor(String moduleId) {
    switch (moduleId) {
      case 'A': return Colors.blueAccent;
      case 'B': return Colors.orangeAccent;
      case 'C': return Colors.purpleAccent;
      case 'D': return Colors.redAccent;
      default: return Colors.blueGrey;
    }
  }
  
  IconData _getModuleIcon(String moduleId) {
    switch (moduleId) {
      case 'A': return Icons.auto_awesome;
      case 'B': return Icons.lightbulb;
      case 'C': return Icons.science;
      case 'D': return Icons.gavel;
      default: return Icons.article;
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
    switch(level) {
      case FeedItemMastery.hard: color = Colors.red; text = 'Hard'; break;
      case FeedItemMastery.medium: color = Colors.orange; text = 'Medium'; break;
      case FeedItemMastery.easy: color = Colors.green; text = 'Easy'; break;
      default: color = Colors.grey; text = 'New';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF0D9488); // Default Teal
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[200]!),
          boxShadow: isSelected ? [
            BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 13
          ),
        ),
      ),
    );
  }
}
