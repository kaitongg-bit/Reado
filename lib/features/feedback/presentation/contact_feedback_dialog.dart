import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_pm/features/feed/presentation/feed_provider.dart';
import 'package:quick_pm/l10n/app_localizations.dart';

/// 与「设置 → 联系我们」相同的反馈表单，提交到 Firestore `feedback` 集合。
class ContactFeedbackDialog extends ConsumerStatefulWidget {
  const ContactFeedbackDialog({
    super.key,
    this.showGuestHint = false,
    this.feedbackSource,
  });

  /// 未登录访客场景下在标题下展示一句说明（如官网底栏）
  final bool showGuestHint;

  /// 写入 `feedback.source`，便于区分入口（如 `landing`、`profile`）
  final String? feedbackSource;

  @override
  ConsumerState<ContactFeedbackDialog> createState() =>
      _ContactFeedbackDialogState();
}

class _ContactFeedbackDialogState extends ConsumerState<ContactFeedbackDialog> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'bug';
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(dataServiceProvider).submitFeedback(
            _type,
            _contentController.text.trim(),
            _contactController.text.trim().isEmpty
                ? null
                : _contactController.text.trim(),
            source: widget.feedbackSource,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.feedbackThanks)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.feedbackSubmitFailed(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final typeLabels = <String, String>{
      'bug': l10n.feedbackTypeBug,
      'advice': l10n.feedbackTypeAdvice,
      'cooperation': l10n.feedbackTypeCoop,
      'other': l10n.feedbackTypeOther,
    };

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.contactUsTitle,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          if (widget.showGuestHint) ...[
            const SizedBox(height: 8),
            Text(
              l10n.feedbackGuestHint,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                height: 1.35,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor:
                      isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.feedbackTypeLabel,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: typeLabels.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _type = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.feedbackContentRequired
                      : null,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.feedbackDescLabel,
                    hintText: l10n.feedbackDescHint,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.feedbackContactLabel,
                    hintText: l10n.feedbackContactHint,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: isDark ? Colors.grey : null),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            disabledBackgroundColor: Colors.orangeAccent.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.feedbackSubmit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
