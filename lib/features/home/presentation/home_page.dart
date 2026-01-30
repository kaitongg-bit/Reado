import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../vault/presentation/vault_page.dart';
import '../../feed/presentation/feed_page.dart';
import '../../feed/presentation/feed_provider.dart';
import 'widgets/home_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  final String? initialModule; // 用于从外部指定初始模块

  const HomePage({super.key, this.initialModule});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // ✅ Load all data on first entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadAllData();
    });

    if (widget.initialModule != null) {
      _selectedIndex = 1; // 切换到学习 tab
      // Save to provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(widget.initialModule!);
      });
    }
  }

  void _loadModule(String moduleId) {
    // Save the active module to persistent storage
    ref.read(lastActiveModuleProvider.notifier).setActiveModule(moduleId);
    setState(() {
      _selectedIndex = 1; // 切换到学习 tab
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the persisted last active module
    final lastActiveModule = ref.watch(lastActiveModuleProvider);

    // Use persisted module, or fallback to 'A'
    final currentModuleId = lastActiveModule ?? 'A';

    final screens = [
      HomeTab(onLoadModule: _loadModule), // 传递回调
      FeedPage(key: ValueKey(currentModuleId), moduleId: currentModuleId),
      const VaultPage(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        indicatorColor:
            const Color(0xFFFF8A65).withOpacity(0.3), // Keeping accent color
        height: 70,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFFF8A65)),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school, color: Color(0xFFFF8A65)),
            label: '学习',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border), // Changed to heart icon
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF8A65)),
            label: '收藏', // Changed from 复习 to 收藏
          ),
        ],
      ),
    );
  }
}
