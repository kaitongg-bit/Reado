// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '抖书';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get appearance => '外观';

  @override
  String get appearanceDark => '深色模式';

  @override
  String get appearanceLight => '浅色模式';

  @override
  String get login => '登陆';

  @override
  String get signUp => '注册';

  @override
  String get createAccount => '创建账号';

  @override
  String get createAccountSubtitle => '开始你的知识内化之旅';

  @override
  String get continueLearning => '继续你的学习';

  @override
  String get emailHint => '电子邮箱';

  @override
  String get passwordHint => '密码';

  @override
  String get usernameHint => '用户名';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get alreadyHaveAccount => '已有账号？登陆';

  @override
  String get noAccount => '没有账号？注册';

  @override
  String get orDivider => '或';

  @override
  String get signInWithGoogle => '使用 Google 登陆';

  @override
  String get agreeTerms => '登陆即表示同意用户协议与隐私政策。';

  @override
  String get home => '首页';

  @override
  String get navStudy => '学习';

  @override
  String get navVault => '收藏';

  @override
  String get explore => '发现';

  @override
  String get lab => '实验室';

  @override
  String get warRoom => '作战室';

  @override
  String get profile => '我的';

  @override
  String get logout => '退出登录';

  @override
  String get securityQuestion => '密保问题';

  @override
  String get securityQuestionSubtitle => '忘记密码时可通过密保找回';

  @override
  String get hiddenContent => '隐藏的内容';

  @override
  String get hiddenContentSubtitle => '恢复被隐藏的知识库或卡片';

  @override
  String get contactUs => '联系我们 / 反馈';

  @override
  String get aboutReado => '关于 Reado';

  @override
  String get aboutReadoSubtitle => '了解功能指南与设计理念';

  @override
  String get forgotPasswordTitle => '忘记密码';

  @override
  String get forgotPasswordIntro => '输入注册邮箱，可选择以下任一方式找回密码：';

  @override
  String get sendResetEmail => '发送重置邮件';

  @override
  String get useSecurityIfNoEmail => '若收不到邮件（如国内邮箱），可使用密保找回';

  @override
  String get securityRecover => '通过密保找回';

  @override
  String get securityAnswerHint => '密保答案';

  @override
  String get newPasswordHint => '新密码（至少 6 位）';

  @override
  String get confirmPasswordHint => '再次输入新密码';

  @override
  String get confirmResetPassword => '确认重置密码';

  @override
  String get successResetEmail => '重置邮件已发送，请查收。未收到可查看垃圾邮件或使用密保找回。';

  @override
  String get successPasswordReset => '密码已重置，请使用新密码登录';

  @override
  String get errorFillEmail => '请填写邮箱';

  @override
  String get errorFillEmailFirst => '请先填写邮箱';

  @override
  String get errorSecurityAnswer => '请填写密保答案';

  @override
  String get errorPasswordMin => '新密码至少 6 位';

  @override
  String get errorPasswordMismatch => '两次输入的密码不一致';

  @override
  String get errorNoSecurity => '未设置密保，请使用邮件重置';

  @override
  String get errorGetSecurity => '获取密保问题失败';

  @override
  String get errorResetFailed => '重置失败';

  @override
  String get errorNetwork => '网络异常，请稍后重试';

  @override
  String get errorSendFailed => '发送失败，请稍后重试';

  @override
  String get tabOfficial => '官方';

  @override
  String get tabPersonal => '个人';

  @override
  String get tabRecent => '最近在学';

  @override
  String get emptyHere => '这里空空如也';

  @override
  String get aiDeconstruct => 'AI 拆解';

  @override
  String get aiNotes => 'AI 笔记';

  @override
  String get taskCenter => '任务中心';

  @override
  String get searchKnowledgeHint => '搜索知识...';

  @override
  String get goodMorning => '早上好';

  @override
  String get goodAfternoon => '下午好';

  @override
  String get goodEvening => '晚上好';

  @override
  String get lateNight => '夜深了';

  @override
  String get createModule => '创建知识库';

  @override
  String get moduleTitle => '标题';

  @override
  String get moduleTitleHint => '例如：面试准备';

  @override
  String get moduleDesc => '描述（可选）';

  @override
  String get moduleDescHint => '这个知识库是关于什么的？';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get errorLoginToCreate => '请先登录以创建您的专属知识库';

  @override
  String successModuleCreated(String title) {
    return '知识库 \"\$title\" 已准备就绪!';
  }

  @override
  String get errorCreateFailed => '创建失败';

  @override
  String get tutorialTextAiDeconstruct => '点击 [AI 拆解] 按钮开启智能学习之旅';

  @override
  String get tutorialTextTaskCenter =>
      '可以在这里看到正在后台进行的任务。等待任务生成好后，可以回到你刚刚所在的知识库（例如：个人 > 默认知识库），点击进去即可学习。';

  @override
  String get tutorialTextMultimodal => '多模态解析也从这里开始，点击 [AI 拆解] 并切换标签页';

  @override
  String get tutorialTextAllCards =>
      '点击一个知识库，跳转到学习页面，点击右上角的【全部】按钮即可查看该知识库的全部知识卡片。';

  @override
  String get tutorialTextAiNotes => '点击 [AI 笔记] 查看所有聚合笔记。';

  @override
  String get quote1 => '今天学了吗？你这个囤囤鼠 🐹';

  @override
  String get quote2 => '卷又卷不赢，躺又躺不平？那就学一点点吧 📖';

  @override
  String get quote3 => '你的大脑正在渴望新的知识，快喂喂它 💡';

  @override
  String get quote4 => '现在的努力，是为了以后能理直气壮地摸鱼 🐟';

  @override
  String get quote5 => '碎片时间也是时间，哪怕入脑一个点也是赚到 ✨';

  @override
  String get quote6 => '知识入脑带来的多巴胺，比短视频香多了 🧠';

  @override
  String get quote7 => '先去电脑端批量拆解，再躺在床上刷知识 🛏️';

  @override
  String shareStatsFormat(int views, int saves, int likes) {
    return '\$views 人浏览 · \$saves 人保存 · \$likes 人点赞';
  }

  @override
  String get creditsRuleTitle => '积分规则 💰';

  @override
  String get creditsRuleNewUser => '新用户注册';

  @override
  String get creditsRuleNewUserValue => '+200 积分';

  @override
  String get creditsRuleDaily => '每日签到';

  @override
  String get creditsRuleDailyValue => '+20 积分/天';

  @override
  String get creditsRuleAiChat => 'AI 聊天 & 陪练';

  @override
  String get creditsRuleAiChatValue => '目前免费 ⚡️';

  @override
  String get creditsRuleExtraction => '内容提取 / 解析';

  @override
  String get creditsRuleExtractionValue => '目前免费 ⚡️';

  @override
  String get creditsRuleAiDeconstruct => 'AI 智能拆解';

  @override
  String get creditsRuleAiDeconstructValue => '10-40 积分/次';

  @override
  String get creditsRuleShare => '点击分享按钮';

  @override
  String get creditsRuleShareValue => '+10 积分/次';

  @override
  String get creditsRuleInvite => '邀请好友加入';

  @override
  String get creditsRuleInviteValue => '+50 积分/位';

  @override
  String get creditsTipLow => '💡 积分不足时，只需点击分享您喜欢的知识库即可立即获得奖励！';

  @override
  String get creditsTipBeta => '⚠️ 系统目前处于内测阶段，暂未开启积分支付与充值功能，敬请期待。';

  @override
  String get creditsGotIt => '我知道了';

  @override
  String get masteredRuleTitle => '如何算\"已掌握\"？🎓';

  @override
  String get masteredRuleIntro => '在沉浸式阅读中，点击底部的【记入收藏】并将卡片标记为：';

  @override
  String get masteredExpert => '熟练 (Expert)';

  @override
  String get masteredMedium => '一般 (Medium)';

  @override
  String get masteredNewbie => '生疏 (Newbie)';

  @override
  String get masteredRuleOutro => '系统会将这些标记过的知识点统计为\"已掌握\"，你可以在【收藏】页面统一进行回顾。';

  @override
  String get masteredUnderstood => '了解了';

  @override
  String get profileSetNickname => '设置昵称';

  @override
  String get profileKnowledgePoints => '知识点';

  @override
  String profileMasteredCount(int count) {
    return '\$count 已掌握';
  }

  @override
  String get profileMyCredits => '我的积分';

  @override
  String profileShareClicks(int count) {
    return '推广点击: \$count';
  }

  @override
  String get settingsSection => '设置';

  @override
  String get settingsTutorial => '新手引导';

  @override
  String get settingsTutorialOn => '已开启 (每次都显示)';

  @override
  String get settingsTutorialDefault => '默认 (仅首次显示)';

  @override
  String get settingsShareNotes => '分享时开放我的笔记';

  @override
  String get settingsShareNotesOn => '他人通过链接可看到你的笔记';

  @override
  String get settingsShareNotesOff => '仅展示卡片正文';

  @override
  String get settingsAdhdTitle => '阅读辅助 (ADHD Focus)';

  @override
  String get settingsAdhdOn => '已开启三色随机引导';

  @override
  String get settingsAdhdOff => '未开启';

  @override
  String get settingsAdhdMode => '辅助模式';

  @override
  String get settingsAdhdColor => '标色';

  @override
  String get settingsAdhdBold => '加粗';

  @override
  String get settingsAdhdHybrid => '混合';

  @override
  String get settingsAdhdStrength => '引导强度';

  @override
  String get settingsAdhdTip => '💡 采用动态随机算法，在文中分布三色视觉锚点，防止视线漂移。';

  @override
  String sharePersonalCopy(String url) {
    return '嘿！我正在使用 Reado 学习，这个 AI 工具太强了，快来看看：\n\$url';
  }

  @override
  String get shareSuccessReward => '分享成功！获得 10 积分动作奖励 🎁';

  @override
  String get shareCopiedToClipboard => '已经为您复制到剪贴板';

  @override
  String get sharePasteToFriends => '分享链接已复制到剪贴板，快粘贴给你的朋友使用吧';

  @override
  String get shareFriendJoinReward => '好友通过您的链接加入时，您将再获得 50 积分';

  @override
  String checkInCreditsReceived(int credits) {
    return '已领取每日签到积分，\$credits 积分';
  }

  @override
  String get checkInAlreadyToday => '今日已签到，已领取 20 积分';

  @override
  String get profileEditProfile => '编辑资料';

  @override
  String get profileChooseAvatar => '选择头像';

  @override
  String get profileNicknameLabel => '昵称';

  @override
  String get profileNicknameHint => '输入你的昵称';

  @override
  String get profileSave => '保存';

  @override
  String get feedbackThanks => '感谢您的反馈！我们会尽快处理。';

  @override
  String feedbackSubmitFailed(String e) {
    return '提交失败: \$e';
  }

  @override
  String get contactUsTitle => '联系我们';

  @override
  String get contactSubtitle => 'Bug 反馈、功能建议或合作';

  @override
  String get feedbackTypeLabel => '反馈类型';

  @override
  String get feedbackTypeBug => '🐛 Bug 反馈';

  @override
  String get feedbackTypeAdvice => '💡 功能建议';

  @override
  String get feedbackTypeCoop => '🤝 商务合作';

  @override
  String get feedbackTypeOther => '💬 其他';

  @override
  String get feedbackContentRequired => '请输入内容';

  @override
  String get feedbackDescLabel => '详细描述';

  @override
  String get feedbackDescHint => '请详细描述您遇到的问题或建议...';

  @override
  String get feedbackContactLabel => '联系方式 (选填)';

  @override
  String get feedbackContactHint => '邮箱或微信，方便我们需要时联系您';

  @override
  String get feedbackSubmit => '提交';

  @override
  String get securityAnswerMin => '答案至少 2 个字符';

  @override
  String get securitySetSuccess => '密保已设置，可用于忘记密码时找回';

  @override
  String get securitySetFailed => '设置失败';

  @override
  String get securitySetDialogTitle => '设置密保问题';

  @override
  String get securitySetDialogIntro => '用于忘记密码时找回，请牢记答案。';

  @override
  String get securitySelectQuestion => '选择问题';

  @override
  String get securityAnswerLabel => '答案（至少 2 个字符）';

  @override
  String get securityQuestions0 => '您母亲的姓名是？';

  @override
  String get securityQuestions1 => '您出生的城市是？';

  @override
  String get securityQuestions2 => '您的第一个宠物名字是？';

  @override
  String get securityQuestions3 => '您的小学名称是？';

  @override
  String get securityQuestions4 => '您的配偶生日（MMDD，如 0315）是？';

  @override
  String get onboardingGuideFab => '入门指南';

  @override
  String get onboardingChecklistTitle => '🎓 新手任务清单';

  @override
  String get onboardingItem1 => '1. AI 文本拆解';

  @override
  String get onboardingItem2 => '2. 查看后台任务';

  @override
  String get onboardingItem3 => '3. 多模态链接解析';

  @override
  String get onboardingItem4 => '4. 查看全部知识卡';

  @override
  String get onboardingItem5 => '5. 查看 AI 笔记';

  @override
  String get onboardingItem6 => '6. 分享以获得积分';

  @override
  String get onboardingDone => '🎉 太棒了！你已顺利上手 Reado';

  @override
  String get onboardingHideList => '不再显示教程';

  @override
  String get onboardingExitDialogTitle => '暂时关闭入门指南？';

  @override
  String get onboardingExitDialogContent =>
      '如果您已经掌握了基本操作，可以关闭此清单。您之后可以随时在\"个人中心 - 设置\"中重新开启。';

  @override
  String get onboardingContinueLearn => '继续学习';

  @override
  String get onboardingEndTutorial => '结束教程';

  @override
  String get onboardingShareSnackbarTitle => '分享成功！获得 10 积分动作奖励 🎁';

  @override
  String get onboardingShareSnackbarCopied => '已经为您复制到剪贴板';

  @override
  String get onboardingShareSnackbarPaste => '分享链接已复制到剪贴板，快粘贴给你的朋友使用吧';

  @override
  String get onboardingShareSnackbarFriend => '好友通过您的链接加入时，您将再获得 50 积分';

  @override
  String get addMaterialSelectModule => '选择知识库';

  @override
  String get addMaterialSelectWhere => '请选择存储位置：';

  @override
  String get addMaterialClickToSelect => '点击选择知识库';

  @override
  String get addMaterialUnknownModule => '未知知识库';

  @override
  String get addMaterialDefaultModule => '默认知识库';

  @override
  String get addMaterialStoreTo => '存储至: ';

  @override
  String get addMaterialTaskSubmitted => '✅ 任务已提交！AI 正在后台为您拆解知识。';

  @override
  String get addMaterialFileTooBig => '文件大小不能超过 10MB';

  @override
  String get addMaterialSelectFileFailed => '选择文件失败';

  @override
  String get addMaterialUploadOrPaste => '请先上传文件或粘贴链接';

  @override
  String get addMaterialCannotReadFile => '无法读取文件内容';

  @override
  String get addMaterialInvalidUrl => '请输入有效的 http/https 链接';

  @override
  String get addMaterialSelectTarget => '选择目标知识库';

  @override
  String get addMaterialSelectTargetHint => '请选择存储拆解结果的知识库：';

  @override
  String get addMaterialNoModule => '暂无知识库';

  @override
  String get addMaterialImportSuccess => '✅ 导入成功！知识卡片已添加到学习库';

  @override
  String get addMaterialSaveFailed => '保存失败';

  @override
  String get addMaterialTutorialIncomplete => '新手教程未完成';

  @override
  String get addMaterialTutorialSuggestion =>
      '建议完成教程以获得最佳体验。完成后将不再显示。\n\n(完成后可获得 0 积分特权)';

  @override
  String get addMaterialContinueAnyway => '继续体验';

  @override
  String get addMaterialSkipTutorial => '暂不完成';

  @override
  String get addMaterialTitleBatch => '添加学习资料 (批量)';

  @override
  String get addMaterialTitle => '添加学习资料';

  @override
  String get addMaterialTutorialMode => '新手引导模式';

  @override
  String get addMaterialTabText => '文本导入';

  @override
  String get addMaterialTabMultimodal => '多模态 (AI)';

  @override
  String addMaterialQueueCount(int count) {
    return '批量处理队列 (\$count)';
  }

  @override
  String get addMaterialQueueEmpty => '队列为空';

  @override
  String get addMaterialQueueEmptyHint => '在左侧添加内容以开始处理';

  @override
  String get addMaterialRunningInBg => '后台运行中，可安全离开';

  @override
  String get addMaterialClearDone => '清除已完成';

  @override
  String get addMaterialLeaveTemporary => '暂时离开 (后台继续)';

  @override
  String get addMaterialAllDone => '全部完成';

  @override
  String get addMaterialStartBatch => '开始批量处理';

  @override
  String get addMaterialPasteHint =>
      '在此粘贴文章内容、笔记或网页文本...\n\n示例：\n# 什么是 Flutter\nFlutter 是 Google 开源的 UI 工具包...\n\n# 特点\n1. 跨平台\n2. 高性能...';

  @override
  String get addMaterialDirectTipTitle => '直接导模式的小贴士：';

  @override
  String get addMaterialDirectTipBody => '使用 Markdown 标题 (如 ';

  @override
  String get addMaterialDirectTipBody2 => '# 标题';

  @override
  String get addMaterialDirectTipBody3 =>
      ') 可手动拆分卡片，无需消耗 AI 额度。若无标题，将默认使用第一句话作为标题。';

  @override
  String get addMaterialDirectImport => '直接导入';

  @override
  String get addMaterialAddedToQueue => '已直接加入队列';

  @override
  String get addMaterialDirectQueue => '直接导队列';

  @override
  String get addMaterialAddedToAiQueue => '已加入AI队列';

  @override
  String get addMaterialAiQueue => 'AI队列';

  @override
  String get addMaterialAiParsing => 'AI 智能解析中...';

  @override
  String get addMaterialAiDeconstruct => 'AI 智能拆解';

  @override
  String get addMaterialGenerating => '生成中...';

  @override
  String addMaterialGeneratedCount(int count) {
    return '已生成 \$count 个知识点';
  }

  @override
  String get addMaterialLeaveForNow => '暂且离开';

  @override
  String get addMaterialReedit => '重新编辑';

  @override
  String get addMaterialConnecting => '正在连接 AI...';

  @override
  String get addMaterialAiReading => 'AI 正在阅读并分析您的内容\n第一张卡片通常需要 5-10 秒...';

  @override
  String get addMaterialNextCard => '正在生成下一张卡片...';

  @override
  String get addMaterialQuestion => '提问: ';

  @override
  String get addMaterialNone => '无';

  @override
  String get addMaterialBackToEdit => '返回修改';

  @override
  String get addMaterialConfirmSave => '确认并保存';

  @override
  String get addMaterialPickedFile => '已选择 (点击更换)';

  @override
  String get addMaterialFileHint => '支持PDF, Word, Markdown';

  @override
  String get addMaterialUrlHint => '支持大部分网页、YouTube等';

  @override
  String addMaterialCharsCount(int count, String time) {
    return '包含 \$count 字符 · 预计耗时 \$time';
  }

  @override
  String get addMaterialFileInQueue => '文件已加入队列';

  @override
  String get addMaterialLinkInQueue => '链接已加入队列';

  @override
  String get addMaterialJoinQueue => '加入队列';

  @override
  String get addMaterialParse => '解析';

  @override
  String addMaterialStartDeconstruct(int credits) {
    return '开始智能拆解 (\$credits 积分)';
  }

  @override
  String get addMaterialWaitParse => '等待解析...';

  @override
  String get addMaterialDirectSave => '直接收藏 (不拆解)';

  @override
  String get addMaterialComingSoon => '即将支持 / Coming Soon';

  @override
  String get addMaterialQueueBusy => '队列中已有待处理任务。请清空队列或使用批量模式。';

  @override
  String get addMaterialConfirmBatch => '确认批量处理';

  @override
  String get addMaterialConfirmBatchDirectOnly => '当前队列中仅有「直接导入」项，不会消耗积分。是否开始？';

  @override
  String get addMaterialStart => '开始';

  @override
  String addMaterialCreditsDeduct(int credits) {
    return '本次将扣除 \$credits 积分';
  }

  @override
  String addMaterialCreditsSummaryAi(int aiCount) {
    return '共 \$aiCount 项，将按内容长度逐项扣费（约 10～40 积分/项）';
  }

  @override
  String addMaterialCreditsSummaryMixed(int extractedCredits, int rest) {
    return '已解析项合计 \$extractedCredits 积分；其余 \$rest 项将按长度逐项扣费（10～40 积分/项）';
  }

  @override
  String get addMaterialConfirmDeconstruct => '确认开始批量拆解？';

  @override
  String addMaterialConfirmBatchFull(int total, int aiCount) {
    return '共 \$total 项待处理（其中 \$aiCount 项为 AI 智能拆解）。';
  }

  @override
  String get addMaterialCreditsTip => '💡 每项将根据字数按规则扣费（约 10～40 积分/项），与单次拆解一致。';

  @override
  String get addMaterialStartGenerate => '开始生成';

  @override
  String get addMaterialConfirmSingle => '确认开始拆解？';

  @override
  String addMaterialCharsRecognized(int count) {
    return '系统已识别内容：约 \$count 字';
  }

  @override
  String addMaterialEstTime(String time) {
    return '预计耗时：\$time';
  }

  @override
  String get addMaterialDeductLabel => '本次将扣除：';

  @override
  String get addMaterialCreditsUnit => ' 积分';

  @override
  String get addMaterialFreeParseTip =>
      '💡 提示：AI 解析内容是免费的，智能拆解将根据内容深度自动匹配最佳方案。';

  @override
  String get addMaterialReadoFree => 'Reado 福利：AI 聊天、解析文件完全免费';

  @override
  String get addMaterialInsufficientCredits => '积分不足';

  @override
  String get addMaterialInsufficientMessage =>
      '执行 AI 解析或生成卡片需要 10 积分。您可以去分享知识库获取更多奖励！';

  @override
  String get addMaterialLearnMore => '了解';

  @override
  String get addMaterialGoShare => '去分享奖励';

  @override
  String get addMaterialStyleTitle => 'AI 拆解风格';

  @override
  String get addMaterialModeStandard => '普通';

  @override
  String get addMaterialModeStandardDesc => '严谨全面';

  @override
  String get addMaterialModeGrandma => '老奶奶';

  @override
  String get addMaterialModeGrandmaDesc => '极其通俗';

  @override
  String get addMaterialModePhd => '智障博士';

  @override
  String get addMaterialModePhdDesc => '大白话';

  @override
  String get addMaterialModePodcast => '播客';

  @override
  String get addMaterialModePodcastDesc => '两人对谈讲解';
}
