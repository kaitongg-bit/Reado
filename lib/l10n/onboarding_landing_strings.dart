import 'package:flutter/widgets.dart';

bool _en(BuildContext context) {
  final code = Localizations.localeOf(context).languageCode.toLowerCase();
  return !code.startsWith('zh');
}

/// 官网 / Onboarding 营销文案（中/英），与 AppLocalizations 并行
abstract final class OnboardingLandingStrings {
  static String heroTitle(BuildContext context) => _en(context)
      ? 'Learn at light speed'
      : '知识极速入脑';

  static String valueProp(BuildContext context) => _en(context)
      ? 'Turn long reads, courses, and notes into swipeable knowledge cards—review anytime, ask AI anytime.'
      : '把长文、课程、笔记变成可刷的知识卡片，随时复习、随时问 AI。';

  static String trustLine(BuildContext context) => _en(context)
      ? 'Learners and professionals use Reado to grow what they know.'
      : '学习者和职场人都在用 Reado 沉淀知识。';

  static String sectionWhatWeDo(BuildContext context) =>
      _en(context) ? 'What Reado does' : 'Reado 能做什么';

  static String ctaStart(BuildContext context) =>
      _en(context) ? 'Get started' : '立即开始体验';

  static String closingLine(BuildContext context) => _en(context)
      ? 'Your knowledge—always there to swipe and to ask.'
      : '你的知识，随时可刷、随时可问。';

  static String sectionTestimonials(BuildContext context) =>
      _en(context) ? 'What people say' : '大家怎么说';

  static String philosophyTitle(BuildContext context) =>
      _en(context) ? 'Let’s chat' : '来聊几句';

  static String footerContact(BuildContext context) =>
      _en(context) ? 'Contact' : '联系我们';

  static String footerTerms(BuildContext context) =>
      _en(context) ? 'Terms' : '用户协议';

  static String footerPrivacy(BuildContext context) =>
      _en(context) ? 'Privacy' : '隐私政策';

  // --- Feature 0: 智能拆解 ---
  static String f0Title(BuildContext context) =>
      _en(context) ? 'Smart split' : '智能拆解';

  static String f0Dialogue(BuildContext context) => _en(context)
      ? 'I pasted a link—minutes later it was neat cards. Huge time-saver.'
      : '我丢了个链接进去，一会儿就拆成好几张卡片，太省事了。';

  static List<String> f0Steps(BuildContext context) => _en(context)
      ? [
          'Paste a link or upload PDF',
          'AI splits it for you',
          'Get knowledge cards',
        ]
      : ['粘贴链接或上传 PDF', 'AI 自动拆解', '生成知识卡片'];

  // --- Feature 1: 闪读 ---
  static String f1Title(BuildContext context) =>
      _en(context) ? 'Swipe to learn' : '闪读记忆';

  static String f1Dialogue(BuildContext context) => _en(context)
      ? 'Swipe up and down like shorts—finish a stack in spare minutes.'
      : '像刷短视频一样上下滑，碎片时间就能刷完一沓卡片。';

  static List<String> f1Steps(BuildContext context) => _en(context)
      ? [
          'Swipe to next card',
          'Rate how well you know it',
          'Spaced review',
        ]
      : ['上下滑动切换卡片', '标记难易度', '间隔复习'];

  // --- Feature 2: 深度 ---
  static String f2Title(BuildContext context) =>
      _en(context) ? 'Go deeper' : '深度内化';

  static String f2Dialogue(BuildContext context) => _en(context)
      ? 'Stuck? Ask the AI tutor, then Pin the good bits—review them next time.'
      : '看不懂的地方直接问 AI，问完还能 Pin 成笔记，下次复习一起看。';

  static List<String> f2Steps(BuildContext context) => _en(context)
      ? [
          'Ask anytime',
          'Pin as notes',
          'See them when you review',
        ]
      : ['随时提问', 'Pin 成笔记', '复习时一起看'];

  // --- Feature 3: 同步 ---
  static String f3Title(BuildContext context) =>
      _en(context) ? 'Sync everywhere' : '多端同步';

  static String f3Dialogue(BuildContext context) => _en(context)
      ? 'Split on the web, keep going on your phone—commute or bedtime.'
      : '电脑上拆好的知识库，手机上也一样，通勤、睡前都能接着刷。';

  static List<String> f3Steps(BuildContext context) => _en(context)
      ? [
          'Web for split & study',
          'Cloud sync',
          'Continue on mobile',
        ]
      : ['网页端拆解与学习', '自动同步', '手机端接着刷'];

  /// 理念区对话（顺序与原版一致）
  static List<({bool isFromUser, String text})> philosophyLines(
      BuildContext context) {
    if (_en(context)) {
      return [
        (
          isFromUser: true,
          text:
              'I hoard articles and slides but never open them… long text scares me.'
        ),
        (
          isFromUser: false,
          text:
              'You’re not alone—that’s exactly why we built Reado.'
        ),
        (isFromUser: true, text: 'How does Reado help?'),
        (
          isFromUser: false,
          text:
              'Paste text, files, or links—we turn them into short knowledge points.'
        ),
        (
          isFromUser: true,
          text:
              'After parsing, is it like mini lessons from one long piece?'
        ),
        (
          isFromUser: true,
          text: 'Will it still feel long? I won’t read walls of text.'
        ),
        (
          isFromUser: false,
          text:
              'We use modes like “Grandma plain talk” and “PhD in plain words” so each card is a few minutes—swipe like shorts, no picking what’s next. Commute or before bed, low pressure.'
        ),
        (
          isFromUser: false,
          text:
              'The in-card AI chat is tuned to be helpful and on-topic.'
        ),
        (
          isFromUser: true,
          text: 'Can’t I just use any chatbot?'
        ),
        (
          isFromUser: false,
          text:
              'Here you can Pin replies into notes—tidy them or keep the thread. Much less friction than copying to Notion.'
        ),
        (
          isFromUser: true,
          text:
              'Pinning is nice—I often chat, get it in the moment, then forget six months later.'
        ),
        (
          isFromUser: false,
          text:
              'That’s the point: turn “I asked once” into “I kept it.” Split + notes work best together—we want starting to feel less painful.'
        ),
        (
          isFromUser: true,
          text: 'Where do I see those notes? You said swipe cards like TikTok.'
        ),
        (
          isFromUser: false,
          text: 'Swipe right on a card to open notes for that topic.'
        ),
        (
          isFromUser: false,
          text:
              'You can share libraries—friends see the card and the notes you chose to share.'
        ),
        (
          isFromUser: true,
          text: 'Ha—sometimes my friends wonder the same things I ask. Can they save my library?'
        ),
        (
          isFromUser: false,
          text:
              'Yes. Send the link; they can read without logging in first.'
        ),
        (
          isFromUser: false,
          text:
              'We’re in a free-preview phase—share for credits so good content travels.'
        ),
      ];
    }
    return [
      (
        isFromUser: true,
        text: '我有厌学症，老是收藏一堆东西和课件，但从来不会真的去看……一看到长文就发怵，觉得学东西好难。'
      ),
      (
        isFromUser: false,
        text: '很多人都是这样！囤了不学，所以我们才做了 Reado～'
      ),
      (isFromUser: true, text: 'Reado怎么帮助我？'),
      (
        isFromUser: false,
        text: '你可以把所有的文件、当下复制的一段文字、任何文字类的问题，甚至网页链接，都在这里解析成一个个短的知识点。'
      ),
      (
        isFromUser: true,
        text: 'AI 解析我明白呀，但是解析完以后又会怎么样呢？它会是一个个单独的知识点吗？类似说，把一篇东西整理成一个个课程要学的知识点？'
      ),
      (
        isFromUser: true,
        text: '然后呢，它会很长吗？长了的话我还是不爱看呐。'
      ),
      (
        isFromUser: false,
        text: '我们用人人能听懂的「老奶模式」和「智障博士」把知识拆成小知识点，每次 3 分钟就够，一点一点就学完了。就像刷短视频一样上下滑～每个知识点一张卡片，滑一下就换下一张，不用自己筛选，沉浸着刷就行。通勤、睡前刷几张，压力小很多。'
      ),
      (
        isFromUser: false,
        text: '而且每个知识点里面的 AI 对话，能够做得非常好，有启发性和针对性。'
      ),
      (isFromUser: true, text: '那又如何，问其他ai不也一样？'),
      (
        isFromUser: false,
        text: '我们的 AI 对话问完可以 Pin 成笔记，全选ai整理，或者原味保存对话记录，非常方便。'
      ),
      (
        isFromUser: true,
        text: '这个AI笔记很有意思欸，确实有时候跟AI聊完，觉得他的回答还是挺有价值的，但是就是懒得去复制到飞书或者Notion，懒得自己整理。'
      ),
      (
        isFromUser: true,
        text: '我经常问 AI 各种各样的学习问题，和 AI 聊完当时懂了，过半年又像没学过一样，哈哈。'
      ),
      (
        isFromUser: false,
        text: '是的呀，我们才想把「问过」变成「记住」呀。我们希望你可以喜欢这个AI拆解跟AI笔记的功能，它们是搭配着一起用的，绝对能让你觉得“学”这个事情不那么难开始和痛苦。'
      ),
      (
        isFromUser: true,
        text: '那我还有一个问题，这个 AI 笔记是怎么查看呢？你说它像抖音一样上下滑去切换知识点，那 AI 笔记是在哪里呢？'
      ),
      (
        isFromUser: false,
        text: '在每个知识点右滑就可以查看啦'
      ),
      (
        isFromUser: false,
        text: '顺带一说，我们这些笔记是可以分享给别人的，也就是：你可以分享你的知识库给你的朋友，正文和你当时提问的笔记都能看到'
      ),
      (
        isFromUser: true,
        text: '哈哈，有一说一，我觉得有时候我问的问题，可能他们心里也想问。对了，我朋友能保存下来我的知识库吗？'
      ),
      (
        isFromUser: false,
        text: '哈哈，可以保存，现在就能把知识库链接发给朋友，他们打开就能读你分享的内容，不用登录也能先体验。'
      ),
      (
        isFromUser: false,
        text: '而且，我们目前是免费体验阶段，通过「分享换积分」，我们希望让好内容被更多人看到。'
      ),
    ];
  }

  static List<Map<String, String>> testimonials(BuildContext context) {
    if (_en(context)) {
      return [
        {
          'name': 'Lin',
          'tag': 'Product learner',
          'quote':
              'Free official libraries plus deep-learning basics—honest and helpful. Cards make it feel lighter; a few on the commute is perfect.',
        },
        {
          'name': 'Chen',
          'tag': 'Professional',
          'quote':
              'Pinning after AI chat is my favorite—I use it like a normal assistant, then save without tidying. No more “got it then forgot.”',
        },
        {
          'name': 'Mia',
          'tag': 'Exam prep',
          'quote':
              'Grandma mode is super down-to-earth. I still switch modes depending on the topic.',
        },
        {
          'name': 'Linda',
          'tag': 'Student abroad',
          'quote':
              'PhD-plain mode is great: slides on one side, Reado on the other—Chinese breakdowns, ask anything, one-tap notes. Love the flow.',
        },
        {
          'name': 'Yifan',
          'tag': 'PM job search',
          'quote':
              'Lots of links and files already work. If Xiaohongshu / WeChat could import more smoothly someday, it’d be even better.',
        },
      ];
    }
    return [
      {
        'name': '小林',
        'tag': '产品学习者',
        'quote':
            '官方免费知识库有aipm必学知识，我还学了深度学习basic知识库，良心。而且，拆成卡片后确实没那么大压力，通勤刷几张刚好。',
      },
      {
        'name': '阿橙',
        'tag': '职场人',
        'quote':
            '最喜欢的还是问完 AI 能直接 Pin 成笔记，我就当普通ai来用，想问啥问啥，不用自己整理太方便。再也不会「当时懂、过后忘」了。',
      },
      {
        'name': 'Mia',
        'tag': '备考党',
        'quote': '老奶模式讲得特别接地气。但我一般还是会针对不同情况，切换不同的模式。',
      },
      {
        'name': 'LindaWu_1111',
        'tag': '留学生',
        'quote':
            '智障博士模式太棒了，我现在把英语课件放在左边，把 Reado开在右边。一边看课件，一边看拆解出来的中文知识点，哪里不会问哪里，还能一键整理成笔记，爽死了这个用户体验',
      },
      {
        'name': '一凡',
        'tag': '产品经理求职',
        'quote':
            '现在已经支持挺多文件和链接的，但是如果国内的一些内容，比如能支持从小红书、微信公众号等平台导入内容，那就无敌了。我知道可以复制粘贴微信公众号的内容，但小红书就没那么方便，毕竟很多是图文笔记。',
      },
    ];
  }
}
