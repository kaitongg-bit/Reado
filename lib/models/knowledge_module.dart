class KnowledgeModule {
  final String id;
  final String title;
  final String description;
  final String ownerId; // 'official' for official modules, or userId
  final bool isOfficial;
  final int cardCount;
  final int masteredCount;

  const KnowledgeModule({
    required this.id,
    required this.title,
    required this.description,
    required this.ownerId,
    this.isOfficial = false,
    this.cardCount = 0,
    this.masteredCount = 0,
  });

  factory KnowledgeModule.fromJson(Map<String, dynamic> json, String id) {
    return KnowledgeModule(
      id: id,
      title: json['title'] ?? 'Untitled Space',
      description: json['description'] ?? '',
      ownerId: json['ownerId'] ?? '',
      isOfficial: json['isOfficial'] ?? false,
      cardCount: json['cardCount'] ?? 0,
      masteredCount: json['masteredCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'ownerId': ownerId,
      'isOfficial': isOfficial,
      // Counts are usually computed, not stored, but can be cached
    };
  }

  // Predefined Official Modules
  static List<KnowledgeModule> get officials => [
        const KnowledgeModule(
          id: 'A',
          title: 'STAR 面试法',
          description: '行为面试金标准：情境、任务、行动、结果',
          ownerId: 'official',
          isOfficial: true,
          cardCount: 6,
        ),
        const KnowledgeModule(
          id: 'B',
          title: 'Reado 官方指南',
          description: '新手必读：如何像黑客一样拆解知识',
          ownerId: 'official',
          isOfficial: true,
          cardCount: 8,
        ),
      ];
}
