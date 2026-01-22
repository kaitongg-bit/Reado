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
          title: 'Product Management',
          description: 'Zero to Hero: Essential PM skills & frameworks',
          ownerId: 'official',
          isOfficial: true,
        ),
        const KnowledgeModule(
          id: 'B',
          title: 'CS Fundamentals',
          description: 'Data structures, algorithms & system design',
          ownerId: 'official',
          isOfficial: true,
        ),
      ];
}
