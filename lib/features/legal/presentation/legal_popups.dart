import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quick_pm/features/feedback/presentation/contact_feedback_dialog.dart';
import 'package:quick_pm/l10n/legal_support_strings.dart';

/// 官网底部：联系我们（与设置页相同，提交 Firestore）+ 用户协议 + 隐私政策（滚动弹窗）
abstract final class LegalPopups {
  /// 与「设置 → 联系我们」一致，写入 `feedback` 集合；`source` 为 `landing` 便于后台区分入口。
  static Future<void> showContactFeedbackDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const ContactFeedbackDialog(
        showGuestHint: true,
        feedbackSource: 'landing',
      ),
    );
  }

  static Future<void> showTermsDialog(BuildContext context) {
    return _showLegalScrollDialog(
      context,
      title: LegalSupportStrings.termsTitle(context),
      paragraphs: LegalSupportStrings.termsBody(context),
      showDisclaimer: true,
    );
  }

  static Future<void> showPrivacyDialog(BuildContext context) {
    return _showLegalScrollDialog(
      context,
      title: LegalSupportStrings.privacyTitle(context),
      paragraphs: LegalSupportStrings.privacyBody(context),
      showDisclaimer: true,
    );
  }

  static Future<void> _showLegalScrollDialog(
    BuildContext context, {
    required String title,
    required List<String> paragraphs,
    bool showDisclaimer = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subColor = isDark ? Colors.white70 : Colors.black54;
        final baseStyle = TextStyle(
          fontSize: 14,
          height: 1.45,
          color: textColor,
        );
        final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
        final mq = MediaQuery.of(ctx).size;
        final maxH = mq.height * 0.82;
        final w = math.min(520.0, mq.width - 40);

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SizedBox(
            width: w,
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    LegalSupportStrings.lastUpdated(ctx),
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...paragraphs.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: RichText(
                                  text: TextSpan(
                                    style: baseStyle,
                                    children: LegalSupportStrings
                                        .paragraphToSpans(p, baseStyle, boldStyle),
                                  ),
                                ),
                              )),
                          if (showDisclaimer) ...[
                            const SizedBox(height: 4),
                            Text(
                              Localizations.localeOf(ctx)
                                      .languageCode
                                      .toLowerCase()
                                      .startsWith('zh')
                                  ? '提示：以上为便于理解的摘要，不构成法律意见；正式合作或争议请以书面协议与适用法律为准。'
                                  : 'Note: This is a practical summary, not legal advice. For formal arrangements, use a written agreement and applicable law.',
                              style: TextStyle(
                                fontSize: 12,
                                color: subColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(MaterialLocalizations.of(ctx).closeButtonLabel),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
