/// 知识库分享页的互动统计（浏览 / 保存 / 点赞）
class ShareStats {
  final int viewCount;
  final int saveCount;
  final int likeCount;
  final List<String> likedBy;

  const ShareStats({
    this.viewCount = 0,
    this.saveCount = 0,
    this.likeCount = 0,
    this.likedBy = const [],
  });

  bool hasLiked(String? userId) =>
      userId != null && likedBy.contains(userId);

  static ShareStats fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ShareStats();
    final list = data['likedBy'];
    return ShareStats(
      viewCount: (data['viewCount'] is num)
          ? (data['viewCount'] as num).toInt()
          : 0,
      saveCount: (data['saveCount'] is num)
          ? (data['saveCount'] as num).toInt()
          : 0,
      likeCount: (data['likeCount'] is num)
          ? (data['likeCount'] as num).toInt()
          : 0,
      likedBy: list is List
          ? list.map((e) => e.toString()).toList()
          : const [],
    );
  }
}
