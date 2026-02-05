import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../vault/presentation/vault_page.dart';
import '../../feed/presentation/feed_page.dart';
import '../../feed/presentation/feed_provider.dart';
import 'module_provider.dart';
import 'widgets/home_tab.dart';

// Provider to control Home Tab programmatically
final homeTabControlProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerStatefulWidget {
  final String? initialModule;
  final int? initialTab;

  const HomePage({super.key, this.initialModule, this.initialTab});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();

    // Sync initial parameters to provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Prioritize initialTab > initialModule > default 0
      if (widget.initialTab != null) {
        ref.read(homeTabControlProvider.notifier).state = widget.initialTab!;
      } else if (widget.initialModule != null) {
        ref.read(homeTabControlProvider.notifier).state = 1; // Feed tab

        // Also save the active module
        ref
            .read(lastActiveModuleProvider.notifier)
            .setActiveModule(widget.initialModule!);
      } else {
        // Default to Home if no params (or current state if preserved)
        // If we want to persist tab state across navigation, we might need more logic,
        // but for now, if no param is passed, we let the provider keep its state or reset?
        // Let's reset to 0 to be safe if navigating to clean /home
        // ref.read(homeTabControlProvider.notifier).state = 0;
      }

      // Load all data on first entry
      ref.read(feedProvider.notifier).loadAllData();
    });
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initialTab changes (e.g. from navigation param), update provider
    if (widget.initialTab != null &&
        widget.initialTab != oldWidget.initialTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(homeTabControlProvider.notifier).state = widget.initialTab!;
      });
    }
  }

  void _loadModule(String moduleId) {
    // Save the active module to persistent storage
    ref.read(lastActiveModuleProvider.notifier).setActiveModule(moduleId);
    // Switch to Learning tab via provider
    ref.read(homeTabControlProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the tab provider - this is the source of truth for tab index
    final selectedIndex = ref.watch(homeTabControlProvider);

    // Watch the persisted last active module
    final lastActiveModule = ref.watch(lastActiveModuleProvider);
    // Default to 'ALL' or 'A' if null?
    // The requirement is to show the clicked module.
    // Detail page saves it to lastActiveModuleProvider.
    final currentModuleId = lastActiveModule ?? 'ALL';

    final screens = [
      HomeTab(onLoadModule: _loadModule),
      FeedPage(key: ValueKey(currentModuleId), moduleId: currentModuleId),
      const VaultPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(homeTabControlProvider.notifier).state = index;
        },
        backgroundColor:
            Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        indicatorColor: const Color(0xFFFF8A65).withOpacity(0.3),
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
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF8A65)),
            label: '收藏',
          ),
        ],
      ),
    );
  }
}
