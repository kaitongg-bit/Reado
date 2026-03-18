// Flutter gen-l10n 会把 ARB 占位符生成成字面量 '\$n'，界面显示「$n」。
// 每次执行 `flutter gen-l10n` 后请运行：
//   dart run tool/fix_l10n_placeholders.dart

import 'dart:io';

void main() {
  final re = RegExp(r'\\\$([a-zA-Z_][a-zA-Z0-9_]*)');
  for (final path in [
    'lib/l10n/app_localizations_zh.dart',
    'lib/l10n/app_localizations_en.dart',
  ]) {
    final f = File(path);
    if (!f.existsSync()) {
      stderr.writeln('Skip: $path');
      continue;
    }
    var s = f.readAsStringSync();
    final before = s;
    s = s.replaceAllMapped(re, (m) => '\$${m[1]}');
    if (path.endsWith('app_localizations_zh.dart')) {
      s = s.replaceAll(
        'return \'知识库 \\"\$title\\" 已准备就绪!\'',
        'return \'知识库 "\$title" 已准备就绪!\'',
      );
    } else {
      s = s.replaceAll(
        'return \'Knowledge base \\"\$title\\" is ready!\'',
        'return \'Knowledge base "\$title" is ready!\'',
      );
      s = s.replaceAll(
        'This is my library \\"\$title\\".',
        'This is my library "\$title".',
      );
    }
    if (s != before) {
      f.writeAsStringSync(s);
      stdout.writeln('Fixed: $path');
    } else {
      stdout.writeln('Already OK: $path');
    }
  }
}
