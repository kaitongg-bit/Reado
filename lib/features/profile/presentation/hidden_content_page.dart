import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/knowledge_module.dart';
import '../../../models/feed_item.dart';
import '../../home/presentation/module_provider.dart';
import '../../feed/presentation/feed_provider.dart';

class HiddenContentPage extends ConsumerStatefulWidget {
  const HiddenContentPage({super.key});

  @override
  ConsumerState<HiddenContentPage> createState() => _HiddenContentPageState();
}

class _HiddenContentPageState extends ConsumerState<HiddenContentPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<KnowledgeModule> _hiddenModules = [];
  List<FeedItem> _hiddenItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHiddenContent();
  }

  Future<void> _loadHiddenContent() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dataService = ref.read(dataServiceProvider);
    try {
      // 1. Fetch hidden modules
      final hiddenModuleIds = await dataService.fetchHiddenModuleIds(user.uid);

      // Combine Official + Custom
      final officialHidden = KnowledgeModule.officials
          .where((m) => hiddenModuleIds.contains(m.id))
          .toList();

      final allCustomModules = await dataService.fetchAllUserModules(user.uid);
      final customHidden = allCustomModules
          .where((m) => hiddenModuleIds.contains(m.id))
          .toList();

      _hiddenModules = [...officialHidden, ...customHidden];

      // 2. Fetch hidden items
      _hiddenItems = await dataService.fetchHiddenFeedItems(user.uid);
    } catch (e) {
      print('Error loading hidden content: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _unhideModule(KnowledgeModule module) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await ref
          .read(dataServiceProvider)
          .unhideOfficialModule(user.uid, module.id);
      // Refresh local list
      setState(() {
        _hiddenModules.removeWhere((m) => m.id == module.id);
      });
      // Notify module provider to refresh
      ref.read(moduleProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已恢复知识库: ${module.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    }
  }

  Future<void> _unhideItem(FeedItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await ref
          .read(dataServiceProvider)
          .unhideOfficialFeedItem(user.uid, item.id);
      // Refresh local list
      setState(() {
        _hiddenItems.removeWhere((i) => i.id == item.id);
      });
      // Feed items refresh automatically next time they are loaded
      // but we might want to trigger a refresh of current feed if needed.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已恢复知识卡: ${item.title}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('恢复失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('管理隐藏内容',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orangeAccent,
          labelColor: Colors.orangeAccent,
          unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
          tabs: const [
            Tab(text: '知识库'),
            Tab(text: '知识卡'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildModuleList(isDark),
                _buildItemList(isDark),
              ],
            ),
    );
  }

  Widget _buildModuleList(bool isDark) {
    if (_hiddenModules.isEmpty) {
      return _buildEmptyState('没有隐藏的知识库');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _hiddenModules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final module = _hiddenModules[index];
        return _buildTile(
          title: module.title,
          subtitle: module.description,
          icon: Icons.auto_stories,
          onRestore: () => _unhideModule(module),
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildItemList(bool isDark) {
    if (_hiddenItems.isEmpty) {
      return _buildEmptyState('没有隐藏的知识卡');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _hiddenItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _hiddenItems[index];
        return _buildTile(
          title: item.title,
          subtitle: '属于: ${item.moduleId}',
          icon: Icons.style,
          onRestore: () => _unhideItem(item),
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onRestore,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.orangeAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onRestore,
            icon: const Icon(Icons.undo, size: 16),
            label: const Text('恢复'),
            style: TextButton.styleFrom(foregroundColor: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
