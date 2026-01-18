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

/// 核心知识点容器
class FeedItem {
  final String id;
  final String moduleId; // 'A', 'B', 'C', 'D'
  final String title;

  // 页面列表：初始只有 officialPages，运行时会 append userNotes
  final List<CardPageContent> pages;

  // SRS 算法数据
  final DateTime? nextReviewTime;
  final int intervalDays;

  FeedItem({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.pages,
    this.nextReviewTime,
    this.intervalDays = 0,
  });

  /// CopyWith method to support immutability and state updates (Riverpod friendly)
  FeedItem copyWith({
    String? id,
    String? moduleId,
    String? title,
    List<CardPageContent>? pages,
    DateTime? nextReviewTime,
    int? intervalDays,
  }) {
    return FeedItem(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      pages: pages ?? this.pages,
      nextReviewTime: nextReviewTime ?? this.nextReviewTime,
      intervalDays: intervalDays ?? this.intervalDays,
    );
  }
}
