import 'package:flutter/material.dart';

/// 分享知识库 / 分享 Feed：界面语言跟随分享者（[ownerUiLocale] 为 `zh`/`en`）
class OwnerLocaleScope extends StatelessWidget {
  const OwnerLocaleScope({
    super.key,
    required this.ownerUiLocale,
    required this.child,
  });

  final String ownerUiLocale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final want = ownerUiLocale == 'zh' ? 'zh' : 'en';
    final have = Localizations.localeOf(context).languageCode.toLowerCase();
    final viewerIsZh = have.startsWith('zh');
    if (want == 'zh' && viewerIsZh) return child;
    if (want == 'en' && !viewerIsZh) return child;
    return Localizations.override(
      context: context,
      locale: Locale(want),
      child: child,
    );
  }
}
