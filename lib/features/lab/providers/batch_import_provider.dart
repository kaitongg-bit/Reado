import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/content_extraction_service.dart';
import '../../../models/feed_item.dart';
import '../../feed/presentation/feed_provider.dart';
import '../../../core/providers/credit_provider.dart';

enum BatchType { url, file, text }

enum BatchProcessingMode { ai, direct }

enum BatchStatus { pending, extracting, generating, completed, error }

class BatchItem {
  final String id;
  final BatchType type;
  final String title; // Display name (filename, url, or snippet)
  final dynamic content; // URL string, Text string, or Uint8List (for file)
  final String stringContent; // Original URL or Text, or Filename for file
  final BatchStatus status;
  final String statusMessage;
  final double progress; // 0.0 to 1.0 (approximate)
  final String? errorMessage;
  final List<FeedItem>? resultItems;

  final BatchProcessingMode processingMode;

  BatchItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.stringContent,
    this.status = BatchStatus.pending,
    this.statusMessage = '等待中...',
    this.progress = 0.0,
    this.errorMessage,
    this.resultItems,
    this.processingMode = BatchProcessingMode.ai,
  });

  BatchItem copyWith({
    BatchStatus? status,
    String? statusMessage,
    double? progress,
    String? errorMessage,
    List<FeedItem>? resultItems,
    BatchProcessingMode? processingMode,
  }) {
    return BatchItem(
      id: id,
      type: type,
      title: title,
      content: content,
      stringContent: stringContent,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      resultItems: resultItems ?? this.resultItems,
      processingMode: processingMode ?? this.processingMode,
    );
  }
}

class BatchImportState {
  final List<BatchItem> queue;
  final bool isProcessing;
  final double globalProgress; // 0.0 to 1.0 (completed items / total items)

  BatchImportState({
    this.queue = const [],
    this.isProcessing = false,
    this.globalProgress = 0.0,
  });

  BatchImportState copyWith({
    List<BatchItem>? queue,
    bool? isProcessing,
    double? globalProgress,
  }) {
    return BatchImportState(
      queue: queue ?? this.queue,
      isProcessing: isProcessing ?? this.isProcessing,
      globalProgress: globalProgress ?? this.globalProgress,
    );
  }
}

class BatchImportNotifier extends StateNotifier<BatchImportState> {
  final Ref ref;

  BatchImportNotifier(this.ref) : super(BatchImportState());

  void addToQueue(BatchItem item) {
    state = state.copyWith(queue: [...state.queue, item]);
    _updateGlobalProgress();
  }

  void removeFromQueue(String id) {
    state = state.copyWith(
      queue: state.queue.where((item) => item.id != id).toList(),
    );
    _updateGlobalProgress();
  }

  void clearCompleted() {
    state = state.copyWith(
      queue: state.queue
          .where((item) => item.status != BatchStatus.completed)
          .toList(),
    );
    _updateGlobalProgress();
  }

  void addItem(BatchType type, dynamic content, String title,
      {BatchProcessingMode mode = BatchProcessingMode.ai}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    addToQueue(BatchItem(
      id: id,
      type: type,
      title: title,
      content: content,
      stringContent: title,
      processingMode: mode,
    ));
  }

  Future<void> startProcessing(String targetModuleId) async {
    if (state.isProcessing) return;

    state = state.copyWith(isProcessing: true);

    // Process items sequentially to avoid rate limits and memory issues
    // Using a loop allows us to re-check the queue if new items are added
    bool hasPending = true;

    while (hasPending) {
      final pendingIndex =
          state.queue.indexWhere((item) => item.status == BatchStatus.pending);

      if (pendingIndex == -1) {
        hasPending = false;
        break;
      }

      final item = state.queue[pendingIndex];
      await _processItem(item, targetModuleId);
    }

    state = state.copyWith(isProcessing: false);
  }

  Future<void> _processItem(BatchItem item, String moduleId) async {
    _updateItemStatus(item.id, BatchStatus.extracting, '正在提取内容...', 0.1);

    try {
      ExtractionResult? extraction;

      // 1. Extraction
      switch (item.type) {
        case BatchType.url:
          extraction =
              await ContentExtractionService.extractFromUrl(item.content);
          break;
        case BatchType.text:
          extraction = ContentExtractionService.extractFromText(item.content,
              title: item.title);
          break;
        case BatchType.file:
          extraction = await ContentExtractionService.extractContentFromFile(
              item.content,
              filename: item.title);
          break;
      }

      List<FeedItem> generatedItems = [];

      if (item.processingMode == BatchProcessingMode.direct) {
        // Direct Import
        final feedItem = FeedItem(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
          moduleId: moduleId,
          title: extraction.title,
          category: '用户导入',
          readingTimeMinutes: (extraction.content.length / 500).ceil(),
          pages: [OfficialPage(extraction.content)],
          isCustom: true,
          isFavorited: false,
          masteryLevel: FeedItemMastery.unknown,
        );

        generatedItems.add(feedItem);

        // Save
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await ref
              .read(dataServiceProvider)
              .saveCustomFeedItem(feedItem, user.uid);
        }
        ref.read(feedProvider.notifier).addCustomItems([feedItem]);
      } else {
        // AI Generation
        // 2. Generation (Streaming)
        _updateItemStatus(item.id, BatchStatus.generating, 'AI 正在分析...', 0.3);

        await for (final event
            in ContentExtractionService.generateKnowledgeCardsStream(
          extraction,
          moduleId: moduleId,
          onChunkProcess: (credits) async {
            // 每开始一个 chunk，扣除对应等级的积分
            final canUse =
                await ref.read(creditProvider.notifier).useAI(amount: credits);
            // 批量处理中如果不满足积分，将直接返回 false 中断流处理
            return canUse;
          },
        )) {
          if (event.type == StreamingEventType.outline) {
            // just outline
          } else if (event.type == StreamingEventType.status) {
            _updateItemStatus(item.id, BatchStatus.generating,
                event.statusMessage ?? '', 0.4);
          } else if (event.type == StreamingEventType.card) {
            if (event.card != null) {
              generatedItems.add(event.card!);
              // Save to DB immediately
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await ref
                    .read(dataServiceProvider)
                    .saveCustomFeedItem(event.card!, user.uid);
              }
              // Update UI
              ref.read(feedProvider.notifier).addCustomItems([event.card!]);

              final progress = 0.4 +
                  (0.6 * ((event.currentIndex ?? 0) / (event.totalCards ?? 1)));
              _updateItemStatus(
                  item.id,
                  BatchStatus.generating,
                  '已生成 ${event.currentIndex}/${event.totalCards}',
                  progress.clamp(0.0, 0.99));
            }
          } else if (event.type == StreamingEventType.error) {
            throw Exception(event.error);
          }
        }
      }

      // 3. Complete
      state = state.copyWith(
        queue: state.queue.map((i) {
          if (i.id == item.id) {
            return i.copyWith(
              status: BatchStatus.completed,
              statusMessage: '完成',
              progress: 1.0,
              resultItems: generatedItems,
            );
          }
          return i;
        }).toList(),
      );
    } catch (e) {
      if (kDebugMode) print('❌ Batch Process Error for ${item.id}: $e');
      state = state.copyWith(
        queue: state.queue.map((i) {
          if (i.id == item.id) {
            return i.copyWith(
              status: BatchStatus.error,
              errorMessage: e.toString(),
              statusMessage: '失败',
              progress: 0.0,
            );
          }
          return i;
        }).toList(),
      );
    }

    _updateGlobalProgress();
  }

  void _updateItemStatus(
      String id, BatchStatus status, String msg, double progress) {
    state = state.copyWith(
      queue: state.queue.map((item) {
        if (item.id == id) {
          return item.copyWith(
              status: status, statusMessage: msg, progress: progress);
        }
        return item;
      }).toList(),
    );
  }

  void _updateGlobalProgress() {
    if (state.queue.isEmpty) {
      state = state.copyWith(globalProgress: 0.0);
      return;
    }
    final completed =
        state.queue.where((i) => i.status == BatchStatus.completed).length;
    state = state.copyWith(globalProgress: completed / state.queue.length);
  }
}

final batchImportProvider =
    StateNotifierProvider<BatchImportNotifier, BatchImportState>((ref) {
  return BatchImportNotifier(ref);
});
