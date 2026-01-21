import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../vault/presentation/vault_page.dart';
import '../../feed/presentation/feed_page.dart';
import 'widgets/home_tab.dart';

class HomePage extends ConsumerStatefulWidget {
  final String? initialModule; // 用于从外部指定初始模块

  const HomePage({super.key, this.initialModule});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  String? _activeModule; // 当前激活的模块

  @override
  void initState() {
    super.initState();
    if (widget.initialModule != null) {
      _selectedIndex = 1; // 切换到学习 tab
      _activeModule = widget.initialModule;
    }
  }

  void _loadModule(String moduleId) {
    setState(() {
      _selectedIndex = 1; // 切换到学习 tab
      _activeModule = moduleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(onLoadModule: _loadModule), // 传递回调
      _activeModule != null
          ? FeedPage(moduleId: _activeModule!)
          : const FeedPage(moduleId: 'A'), // 默认显示 Module A
      const VaultPage(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
            if (index == 0) _activeModule = null; // 返回主页时清除模块
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
