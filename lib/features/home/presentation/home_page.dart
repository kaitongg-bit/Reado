import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../vault/presentation/vault_page.dart';
import '../../feed/presentation/feed_page.dart';
import 'widgets/home_tab.dart'; // New Home Tab

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeTab(),
      const FeedPage(moduleId: 'A'), // Learn Tab: Hardcore logic
      const VaultPage(), // Review Tab: Library/Search logic
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
        backgroundColor: Colors.black, // Dark per design
        indicatorColor: const Color(0xFFFF8A65).withOpacity(0.2), // Matches accent
        height: 65,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home, color: Color(0xFFFF8A65)),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.school, color: Color(0xFFFF8A65)),
            label: '学习',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.inventory_2, color: Color(0xFFFF8A65)),
            label: '复习',
          ),
        ],
      ),
    );
  }
}

