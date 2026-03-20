import 'package:flutter/material.dart';

bool _en(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return !code.startsWith('zh');
}

/// 用户协议、隐私政策等法律文案（中英）
abstract final class LegalSupportStrings {
  static String termsTitle(BuildContext c) =>
      _en(c) ? 'Terms of service' : '用户协议';

  static String privacyTitle(BuildContext c) =>
      _en(c) ? 'Privacy policy' : '隐私政策';

  static String lastUpdated(BuildContext c) => _en(c)
      ? 'Last updated: February 2026'
      : '最近更新：2026 年 2 月';

  /// 用户协议（简版，非律师意见）
  static List<String> termsBody(BuildContext c) {
    if (_en(c)) {
      return [
        'By using Reado, you agree to these terms. If you disagree, please stop using the service.',
        '**1. The service**',
        'Reado provides learning tools including content import, card generation, AI features, and related functionality. We may change, suspend, or discontinue features with reasonable notice when possible.',
        '**2. Beta**',
        'The product may be labeled beta / early access. It is provided “as is” without warranties of uninterrupted or error-free operation.',
        '**3. Your account**',
        'You are responsible for your account credentials and for activity under your account. Notify us if you suspect unauthorized access.',
        '**4. Your content**',
        'You retain rights to content you upload or create. You grant us the license needed to operate the service (e.g., store, process, and display your content to you and, if you choose, to people you share with).',
        'Do not upload illegal content or content you do not have the right to use.',
        '**5. AI output**',
        'AI-generated text may be inaccurate or incomplete. It is not professional, medical, or legal advice. You are responsible for how you use outputs.',
        '**6. Acceptable use**',
        'No scraping or abuse of the service, no attempts to bypass limits or security, and no use that violates applicable law.',
        '**7. Termination**',
        'You may stop using Reado anytime. We may suspend or terminate access for violations of these terms or legal requirements.',
        '**8. Limitation of liability**',
        'To the maximum extent permitted by law, we are not liable for indirect or consequential damages arising from use of the service.',
        '**9. Contact**',
        'Questions about these terms: use Contact us in the app (or the link on our website) to send feedback.',
      ];
    }
    return [
      '使用 Reado 即表示你同意本协议；如不同意，请停止使用本服务。',
      '**1. 服务说明**',
      'Reado 提供内容导入、知识卡片、AI 功能等相关学习工具。我们可能视情况调整、暂停或下线部分功能，并将尽量以合理方式提示重要变更。',
      '**2. 内测 / 公测**',
      '产品可能处于内测或早期阶段，按「现状」提供，不保证服务持续、无中断或无错误。',
      '**3. 账号**',
      '你需对账号与密码负责，并对账号下的行为负责。如发现未授权使用，请及时联系我们。',
      '**4. 你的内容**',
      '你保留所上传或创建内容的权利；为提供服务，你授予我们必要的许可（例如存储、处理、向你展示；若你主动分享，则向被分享方展示）。',
      '请勿上传违法内容或你无权使用的内容。',
      '**5. AI 生成内容**',
      'AI 输出可能存在错误或不完整，不构成专业、医疗或法律意见。你需自行判断并承担使用后果。',
      '**6. 合理使用**',
      '禁止滥用、爬取、攻击或绕过安全与限制，禁止违反法律法规的使用行为。',
      '**7. 终止**',
      '你可随时停止使用；若你违反本协议或法律要求，我们可能暂停或终止你的访问。',
      '**8. 责任限制**',
      '在法律允许的最大范围内，我们对因使用本服务产生的间接或后果性损害不承担责任。',
      '**9. 联系**',
      '有关本协议的问题，请通过应用内或官网的「联系我们」提交反馈。',
    ];
  }

  /// 隐私政策（简版）
  static List<String> privacyBody(BuildContext c) {
    if (_en(c)) {
      return [
        'This policy describes how Reado handles information when you use our web/app experience.',
        '**1. What we collect**',
        '• **Account:** email, display name, and authentication data from providers such as Google when you sign in.',
        '• **Content:** materials you import, cards, notes, and AI chat you choose to save, stored to provide the product.',
        '• **Usage & diagnostics:** basic technical data (e.g., device/browser type) and, if enabled, product analytics to improve UX (e.g., session replay tools).',
        '• **Credits / sharing:** data needed to run rewards or referral features you use.',
        '**2. How we use data**',
        'To run and improve the service, secure accounts, communicate about the product, and comply with law.',
        '**3. AI processing**',
        'To provide AI features, parts of your content may be sent to model providers (e.g., Google Gemini) under their terms. Do not submit highly sensitive personal data you are not comfortable processing with third-party AI.',
        '**4. Sharing**',
        'We use infrastructure providers (e.g., Google Firebase / Cloud). We do not sell your personal data. We may disclose information if required by law.',
        '**5. Retention**',
        'We keep data while your account is active and as needed for legal or operational purposes. You may request deletion where applicable.',
        '**6. Security**',
        'We use industry-standard measures, but no method is 100% secure.',
        '**7. Your choices**',
        'You can manage some data in-app. For privacy requests, use Contact us in the app (or the website link) to send a message.',
        '**8. Children**',
        'Reado is not directed at children under 13 (or the minimum age in your region).',
        '**9. Changes**',
        'We may update this policy; the “last updated” date will change. Continued use means you accept the updated policy.',
      ];
    }
    return [
      '本政策说明你在使用 Reado（网页 / 应用形态）时，我们如何处理相关信息。',
      '**1. 我们可能收集的信息**',
      '• **账号：** 邮箱、昵称，以及通过 Google 等第三方登录返回的认证信息。',
      '• **内容：** 你导入的资料、知识卡片、笔记及你选择保存的 AI 对话等，用于提供产品功能。',
      '• **使用与诊断：** 基础设备/浏览器信息；若启用，可能包含用于改进体验的产品分析数据（例如会话回放类工具）。',
      '• **积分 / 分享：** 运行你使用的奖励或分享功能所需的数据。',
      '**2. 使用目的**',
      '用于提供与改进服务、保障账号安全、就产品与你沟通，以及遵守法律法规。',
      '**3. AI 处理**',
      '为提供 AI 能力，部分内容可能被发送至模型服务商（如 Google Gemini）处理，并受其条款约束。请勿提交你不愿由第三方 AI 处理的高度敏感个人信息。',
      '**4. 共享与披露**',
      '我们使用云与基础设施服务商（如 Google Firebase 等）。不出售你的个人信息。在法律要求时可能依法披露。',
      '**5. 保存期限**',
      '在账号存续及法律/运营所需期间内保存；在适用情况下你可申请删除。',
      '**6. 安全**',
      '我们采取合理的技术与管理措施，但无法保证绝对安全。',
      '**7. 你的权利与选择**',
      '部分数据可在应用内管理；隐私相关请求可通过应用内或官网「联系我们」提交。',
      '**8. 儿童**',
      'Reado 不面向未满 13 周岁（或你所在地区规定的最低年龄）的儿童。',
      '**9. 变更**',
      '我们可能更新本政策，并在文首更新「最近更新」日期。继续使用即表示你接受更新后的政策。',
    ];
  }

  /// 将 **title** 粗体行解析为简单展示用（避免引入 markdown 依赖）
  static List<InlineSpan> paragraphToSpans(
    String paragraph,
    TextStyle base,
    TextStyle bold,
  ) {
    if (!paragraph.contains('**')) {
      return [TextSpan(text: paragraph, style: base)];
    }
    final spans = <TextSpan>[];
    final parts = paragraph.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? bold : base,
      ));
    }
    return spans;
  }
}
