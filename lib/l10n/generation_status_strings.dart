/// AI 拆解/后台任务进度文案（随 [outputLocale]：`en` | `zh`），无 BuildContext 依赖。
abstract final class GenerationStatusStrings {
  static bool _en(String outputLocale) => outputLocale == 'en';

  static String waitingServer(String outputLocale) =>
      _en(outputLocale) ? 'Waiting for server...' : '等待服务器...';

  static String submittingTask(String outputLocale) =>
      _en(outputLocale) ? 'Submitting task...' : '正在提交任务...';

  static String taskSubmittedStarting(String outputLocale) =>
      _en(outputLocale)
          ? 'Task submitted, starting...'
          : '任务已提交，正在启动处理...';

  static String startJobFailed(String outputLocale, Object e) =>
      _en(outputLocale) ? 'Failed to start job: $e' : '启动任务失败: $e';

  static String processingChunk(
      String outputLocale, int index1Based, int total) =>
      _en(outputLocale)
          ? 'Processing part $index1Based/$total...'
          : '正在处理第 $index1Based/$total 段内容...';

  static String chunkFoundTopics(
      String outputLocale, int chunk1Based, int topicCount) =>
      _en(outputLocale)
          ? 'Part $chunk1Based: found $topicCount topics, generating...'
          : '第 $chunk1Based 段发现 $topicCount 个知识点，正在生成...';

  static String generatingCard(String outputLocale, String title, int i1Based,
          int total) =>
      _en(outputLocale)
          ? 'Generating: $title ($i1Based/$total)'
          : '正在生成: $title ($i1Based/$total)';

  static String insufficientCreditsStop(String outputLocale, bool multiChunk) =>
      _en(outputLocale)
          ? (multiChunk
              ? 'Not enough credits; stopped remaining parts.'
              : 'Not enough credits to generate.')
          : (multiChunk ? '积分不足，已停止处理后续分段' : '积分不足，无法开始生成');

  static String connectionError(String outputLocale, Object e) =>
      _en(outputLocale) ? 'Connection error: $e' : '连接错误: $e';

  static String unknownError(String outputLocale) =>
      _en(outputLocale) ? 'Unknown error' : '未知错误';

  // --- Batch import ---
  static String batchPreparing(String outputLocale) =>
      _en(outputLocale) ? 'Preparing...' : '准备中...';

  static String batchWaitingChars(String outputLocale, int chars) =>
      _en(outputLocale)
          ? 'Queued (~$chars chars)'
          : '等待中 ($chars 字)';

  static String batchParseFailed(String outputLocale, Object e) =>
      _en(outputLocale) ? 'Parse failed: $e' : '解析失败: $e';

  static String batchExtracting(String outputLocale) =>
      _en(outputLocale) ? 'Extracting content...' : '正在提取内容...';

  static String batchSubmittingJob(String outputLocale) =>
      _en(outputLocale) ? 'Submitting task...' : '正在提交任务...';

  static String batchAiProcessing(String outputLocale) =>
      _en(outputLocale) ? 'AI is working...' : 'AI 处理中...';

  static String batchGeneratedProgress(
      String outputLocale, int current, int? total) =>
      _en(outputLocale)
          ? 'Generated $current/${total ?? '?'}'
          : '已生成 $current/${total ?? '?'}';

  static String batchComplete(String outputLocale) =>
      _en(outputLocale) ? 'Done' : '完成';

  static String batchFailed(String outputLocale, String firstLine) =>
      _en(outputLocale) ? 'Failed: $firstLine' : '失败: $firstLine';

  static String batchInsufficientCredits(String outputLocale) =>
      _en(outputLocale)
          ? 'Not enough credits for AI.'
          : '积分不足，无法开始 AI 处理';
}
