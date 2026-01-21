import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../feed/presentation/feed_provider.dart';
import '../../../../models/feed_item.dart';
import '../../../lab/presentation/add_material_modal.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamic Stats Calculation
    final feedItems = ref.watch(feedProvider);
    final hardcoreItems = feedItems.where((i) => i.moduleId == 'A').toList();
    final pmItems = feedItems.where((i) => i.moduleId == 'B').toList(); // Assuming B is PM Foundation
    
    final hardcoreCount = hardcoreItems.length;
    final hardcoreLearned = hardcoreItems.where((i) => i.masteryLevel != FeedItemMastery.unknown).length;
    final hardcoreProgress = hardcoreCount == 0 ? 0.0 : hardcoreLearned / hardcoreCount;

    final pmCount = pmItems.length;
    final pmLearned = pmItems.where((i) => i.masteryLevel != FeedItemMastery.unknown).length;
    final pmProgress = pmCount == 0 ? 0.0 : pmLearned / pmCount;

    return Scaffold(
      backgroundColor: Colors.black, // Dark mode as per request/image
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar: Title & Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(
                    'QuickPM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to settings or profile details if needed
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Search Bar
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search knowledge cards...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.orangeAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    context.push('/search?q=$value');
                  }
                },
              ),
              const SizedBox(height: 32),

              // 3. Knowledge Spaces Section
              const Text(
                'Knowledge Spaces',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Knowledge Card: Product Manager (Module B)
              _KnowledgeSpaceCard(
                title: '产品经理基础',
                description: '从零开始学习产品经理核心技能',
                cardCount: pmCount > 0 ? pmCount : 24, // Fallback if mock empty
                progress: pmCount > 0 ? pmProgress : 0.45,
                color: const Color(0xFF252525),
                badgeText: 'Official', 
                onLoad: () => context.push('/feed/B'),
              ),
              const SizedBox(height: 16),
              
              // Knowledge Card: Hardcore (Module A)
             _KnowledgeSpaceCard(
                title: '硬核基础',
                description: '计算机科学与编程基础知识',
                cardCount: hardcoreCount > 0 ? hardcoreCount : 18,
                progress: hardcoreCount > 0 ? hardcoreProgress : 0.20,
                color: const Color(0xFF252525),
                badgeText: 'Official', 
                onLoad: () => context.push('/feed/A'), // Navigate to Learn tab content directly using push for now
                // Since Learn tab IS Module A, we can switch tab, or just push feed A
                // But context.go('/home') might reset state. 
                // Let's just push feed for now to be safe, or user 'onDestinationSelected' logic if we had access.
              ),

              const SizedBox(height: 80), // Bottom padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddMaterialModal(),
          );
        },
        backgroundColor: const Color(0xFFFF8A65), // Coral color
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _KnowledgeSpaceCard extends StatelessWidget {
  final String title;
  final String description;
  final int cardCount;
  final double progress; // 0.0 to 1.0
  final Color color;
  final String badgeText;
  final VoidCallback? onLoad;

  const _KnowledgeSpaceCard({
    required this.title,
    required this.description,
    required this.cardCount,
    required this.progress,
    required this.color,
    required this.badgeText,
    this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Progress Bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[800],
            color: const Color(0xFFFF8A65), // Coral
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 12),

          // Stats
          Text(
            '${(progress * 100).toInt()}% · $cardCount cards',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onLoad,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A65),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: const Text('Load', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddMaterialModal(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF8A65)),
                    foregroundColor: const Color(0xFFFF8A65),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('+ Add Material', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
