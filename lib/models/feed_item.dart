import 'package:flutter/foundation.dart';

/// 页面基类
abstract class CardPageContent {
  final String type; // 'text', 'image', 'user_note'

  CardPageContent({required this.type});
}

/// 官方内容页
class OfficialPage extends CardPageContent {
  final String markdownContent;
  final String? flashcardQuestion;
  final String? flashcardAnswer;

  OfficialPage(
    this.markdownContent, {
    this.flashcardQuestion,
    this.flashcardAnswer,
  }) : super(type: 'text');
}

/// 用户私有笔记页 (动态生成)
class UserNotePage extends CardPageContent {
  final String question;
  final String answer;
  final DateTime createdAt;

  UserNotePage({
    required this.question,
    required this.answer,
    required this.createdAt,
  }) : super(type: 'user_note');
}

enum FeedItemMastery {
  unknown,
  hard,
  medium,
  easy,
}

/// 核心知识点容器
class FeedItem {
  final String id;
  final String moduleId; // 'A', 'B', 'C', 'D'
  final String title;
  
  // New Fields
  final String category;
  final String difficulty;

  // 页面列表
  final List<CardPageContent> pages;

  // SRS 算法数据
  final DateTime? nextReviewTime;
  final int interval; // Changed from intervalDays to interval (SRS standard)
  final double easeFactor; // Added for SRS
  
  // 掌握程度
  final FeedItemMastery masteryLevel;
  
  // 收藏状态
  final bool isFavorited;

  // Getters for compatibility
  String get module => moduleId; // Alias

  FeedItem({
    required this.id,
    required this.moduleId,
    required this.title,
    this.category = 'General',
    this.difficulty = 'Normal',
    required this.pages,
    this.nextReviewTime,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.masteryLevel = FeedItemMastery.unknown,
    this.isFavorited = false,
  });

  /// CopyWith
  FeedItem copyWith({
    String? id,
    String? moduleId,
    String? title,
    String? category,
    String? difficulty,
    List<CardPageContent>? pages,
    DateTime? nextReviewTime,
    int? interval,
    double? easeFactor,
    FeedItemMastery? masteryLevel,
    bool? isFavorited,
  }) {
    return FeedItem(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      pages: pages ?? this.pages,
      nextReviewTime: nextReviewTime ?? this.nextReviewTime,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'module': moduleId,
      'title': title,
      'category': category,
      'difficulty': difficulty,
      'nextReviewTime': nextReviewTime?.toIso8601String(),
      'interval': interval,
      'easeFactor': easeFactor,
      'masteryLevel': masteryLevel.name,
      'isFavorited': isFavorited,
      'pages': pages.map((p) {
        if (p is OfficialPage) {
           return {
             'type': 'text',
             'markdownContent': p.markdownContent,
             'flashcardQuestion': p.flashcardQuestion,
             'flashcardAnswer': p.flashcardAnswer,
           };
        } else if (p is UserNotePage) {
           return {
             'type': 'user_note',
             'question': p.question,
             'answer': p.answer,
             'createdAt': p.createdAt.toIso8601String(),
           };
        }
        return {'type': 'unknown'};
      }).toList(),
    };
  }

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    // Parse pages
    var pageList = <CardPageContent>[];
    if (json['pages'] != null) {
      for (var p in json['pages']) {
        if (p['type'] == 'text') {
          pageList.add(OfficialPage(
            p['markdownContent'] ?? '',
            flashcardQuestion: p['flashcardQuestion'],
            flashcardAnswer: p['flashcardAnswer'],
          ));
        } else if (p['type'] == 'user_note') {
          pageList.add(UserNotePage(
            question: p['question'] ?? 'Q',
            answer: p['answer'] ?? 'A',
            createdAt: p['createdAt'] != null ? DateTime.parse(p['createdAt']) : DateTime.now(),
          ));
        }
      }
    }

    // Parse Mastery
    FeedItemMastery mastery = FeedItemMastery.unknown;
    if (json['masteryLevel'] != null) {
      try {
        mastery = FeedItemMastery.values.firstWhere((e) => e.name == json['masteryLevel']);
      } catch (_) {}
    }

    return FeedItem(
      id: json['id'] ?? '',
      moduleId: json['module'] ?? 'A',
      title: json['title'] ?? 'Untitled',
      category: json['category'] ?? 'General',
      difficulty: json['difficulty'] ?? 'Normal',
      pages: pageList,
      nextReviewTime: json['nextReviewTime'] != null ? DateTime.parse(json['nextReviewTime']) : null,
      interval: json['interval'] ?? 0,
      easeFactor: (json['easeFactor'] ?? 2.5).toDouble(),
      masteryLevel: mastery,
      isFavorited: json['isFavorited'] ?? false,
    );
  }
}
