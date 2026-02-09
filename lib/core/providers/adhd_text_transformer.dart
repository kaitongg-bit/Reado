import 'dart:math';
import 'package:flutter/material.dart';
import 'adhd_provider.dart';

class AdhdTextTransformer {
  /// 将纯文本转换为带有 ADHD 视觉辅助的 TextSpan 列表
  static List<InlineSpan> transform(
    String text,
    TextStyle baseStyle,
    AdhdSettings settings,
  ) {
    if (!settings.isEnabled || settings.mode == AdhdReadingMode.none) {
      return [TextSpan(text: text, style: baseStyle)];
    }

    final List<InlineSpan> spans = [];
    final characters = text.characters;
    final random = Random(text.length); // 使用文本长度作为种子，保证同一段文本显示一致

    // 状态管理
    int i = 0;
    final charList = characters.toList();
    final total = charList.length;

    // 标色池
    final colors = AdhdFocusColor.values.map((v) => v.color).toList();

    while (i < total) {
      // 1. 根据强度决定概率与间隔
      int prob;
      int maxGap;
      int minGap;

      switch (settings.intensity) {
        case AdhdIntensity.low:
          prob = 25;
          minGap = 8;
          maxGap = 16;
          break;
        case AdhdIntensity.medium:
          prob = 35;
          minGap = 6;
          maxGap = 12;
          break;
        case AdhdIntensity.high:
          prob = 50;
          minGap = 4;
          maxGap = 8;
          break;
      }

      // 决定当前的“标色块”还是“普通块”
      bool isHighlightBlock = random.nextInt(100) < prob;

      // 2. 决定块长度
      // 标色块长度保持随机在 3-5 之间
      // 普通块间隔长度根据强度动态调整
      int blockLen = isHighlightBlock
          ? random.nextInt(3) + 3 // 3, 4, 5
          : random.nextInt(maxGap - minGap + 1) + minGap;

      // 确保不越界
      if (i + blockLen > total) blockLen = total - i;

      // 3. 决定颜色（如果是高亮块）
      Color? highlightColor;
      if (isHighlightBlock) {
        highlightColor = colors[random.nextInt(colors.length)];
      }

      // 4. 构建当前块
      for (int k = 0; k < blockLen; k++) {
        final char = charList[i + k];
        final style = _getStyledStyle(
          baseStyle,
          settings,
          highlightColor: highlightColor,
        );
        spans.add(TextSpan(text: char, style: style));
      }

      i += blockLen;
    }

    return spans;
  }

  static TextStyle _getStyledStyle(
    TextStyle base,
    AdhdSettings settings, {
    Color? highlightColor,
  }) {
    if (highlightColor == null) return base;

    TextStyle style = base;

    // 1. 加粗模式 (标色块同时应用加粗)
    if (settings.mode == AdhdReadingMode.bold ||
        settings.mode == AdhdReadingMode.hybrid ||
        settings.mode == AdhdReadingMode.color) {
      style = style.copyWith(fontWeight: FontWeight.w900);
    }

    // 2. 标色模式
    if (settings.mode == AdhdReadingMode.color ||
        settings.mode == AdhdReadingMode.hybrid) {
      style = style.copyWith(color: highlightColor);
    }

    return style;
  }
}
