// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Reado';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '中文';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceDark => 'Dark mode';

  @override
  String get appearanceLight => 'Light mode';

  @override
  String get login => 'Log in';

  @override
  String get signUp => 'Sign up';

  @override
  String get createAccount => 'Create account';

  @override
  String get createAccountSubtitle => 'Start your knowledge journey';

  @override
  String get continueLearning => 'Continue your learning';

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get usernameHint => 'Username';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get noAccount => 'No account? Sign up';

  @override
  String get orDivider => 'or';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get agreeTerms =>
      'By signing in you agree to the terms and privacy policy.';

  @override
  String get home => 'Home';

  @override
  String get navStudy => 'Study';

  @override
  String get navVault => 'Vault';

  @override
  String get explore => 'Explore';

  @override
  String get lab => 'Lab';

  @override
  String get warRoom => 'War Room';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Log out';

  @override
  String get securityQuestion => 'Security question';

  @override
  String get securityQuestionSubtitle => 'Recover password if you forget it';

  @override
  String get hiddenContent => 'Hidden content';

  @override
  String get hiddenContentSubtitle => 'Restore hidden modules or cards';

  @override
  String get contactUs => 'Contact / Feedback';

  @override
  String get aboutReado => 'About Reado';

  @override
  String get aboutReadoSubtitle => 'Features and design';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordIntro =>
      'Enter your email and choose one way to recover:';

  @override
  String get sendResetEmail => 'Send reset email';

  @override
  String get useSecurityIfNoEmail =>
      'If you don\'t receive the email (e.g. some regions), use security question.';

  @override
  String get securityRecover => 'Recover via security question';

  @override
  String get securityAnswerHint => 'Your answer';

  @override
  String get newPasswordHint => 'New password (at least 6 characters)';

  @override
  String get confirmPasswordHint => 'Confirm new password';

  @override
  String get confirmResetPassword => 'Reset password';

  @override
  String get successResetEmail =>
      'Reset email sent. Check your inbox or spam, or use security question.';

  @override
  String get successPasswordReset =>
      'Password reset. Please sign in with your new password.';

  @override
  String get errorFillEmail => 'Please enter your email';

  @override
  String get errorFillEmailFirst => 'Please enter your email first';

  @override
  String get errorSecurityAnswer => 'Please enter your security answer';

  @override
  String get errorPasswordMin => 'Password must be at least 6 characters';

  @override
  String get errorPasswordMismatch => 'Passwords do not match';

  @override
  String get errorNoSecurity =>
      'Security question not set. Use email reset or contact support.';

  @override
  String get errorGetSecurity => 'Failed to load security question';

  @override
  String get errorResetFailed => 'Reset failed';

  @override
  String get errorNetwork => 'Network error. Please try again.';

  @override
  String get errorSendFailed => 'Failed to send. Please try again.';

  @override
  String get tabOfficial => 'Official';

  @override
  String get officialCurated => 'Official picks';

  @override
  String get tabPersonal => 'Personal';

  @override
  String get tabRecent => 'Recent';

  @override
  String get emptyHere => 'Nothing here yet';

  @override
  String get aiDeconstruct => 'AI Deconstruct';

  @override
  String get aiNotes => 'AI Notes';

  @override
  String get taskCenter => 'Task Center';

  @override
  String get searchKnowledgeHint => 'Search knowledge...';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get lateNight => 'Late night';

  @override
  String get createModule => 'Create knowledge base';

  @override
  String get moduleTitle => 'Title';

  @override
  String get moduleTitleHint => 'e.g. Interview prep';

  @override
  String get moduleDesc => 'Description (optional)';

  @override
  String get moduleDescHint => 'Enter description';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get errorLoginToCreate =>
      'Please sign in to create your knowledge base';

  @override
  String successModuleCreated(String title) {
    return 'Knowledge base \"\$title\" is ready!';
  }

  @override
  String get errorCreateFailed => 'Failed to create';

  @override
  String get tutorialTextAiDeconstruct =>
      'Tap [AI Deconstruct] to start your smart learning journey';

  @override
  String get tutorialTextTaskCenter =>
      'See background tasks here. When ready, go back to your knowledge base (e.g. Personal > Default) and tap to learn.';

  @override
  String get tutorialTextMultimodal =>
      'Multimodal parsing starts here too. Tap [AI Deconstruct] and switch tabs.';

  @override
  String get tutorialTextAllCards =>
      'Tap a knowledge base to open it, then tap [All] on the top right to see all cards.';

  @override
  String get tutorialTextAiNotes =>
      'Tap [AI Notes] to see all aggregated notes.';

  @override
  String get quote1 => 'Did you learn today? You little hoarder 🐹';

  @override
  String get quote2 =>
      'Can\'t outwork others, can\'t fully chill? Then learn a little 📖';

  @override
  String get quote3 => 'Your brain is craving new knowledge. Feed it 💡';

  @override
  String get quote4 =>
      'Work hard now so you can slack off with a clear conscience later 🐟';

  @override
  String get quote5 =>
      'Pocket time counts too. One idea in your head is a win ✨';

  @override
  String get quote6 => 'The dopamine from learning beats short videos 🧠';

  @override
  String get quote7 => 'Batch on desktop, then brush cards in bed 🛏️';

  @override
  String shareStatsFormat(int views, int saves, int likes) {
    return '\$views views · \$saves saves · \$likes likes';
  }

  @override
  String get creditsRuleTitle => 'Credits rules 💰';

  @override
  String get creditsRuleNewUser => 'New user signup';

  @override
  String get creditsRuleNewUserValue => '+200 credits';

  @override
  String get creditsRuleDaily => 'Daily check-in';

  @override
  String get creditsRuleDailyValue => '+20 credits/day';

  @override
  String get creditsRuleAiChat => 'AI chat & practice';

  @override
  String get creditsRuleAiChatValue => 'Free for now ⚡️';

  @override
  String get creditsRuleExtraction => 'Content extraction / parsing';

  @override
  String get creditsRuleExtractionValue => 'Free for now ⚡️';

  @override
  String get creditsRuleAiDeconstruct => 'AI smart deconstruct';

  @override
  String get creditsRuleAiDeconstructValue => '10-40 credits/time';

  @override
  String get creditsRuleShare => 'Tap share button';

  @override
  String get creditsRuleShareValue => '+10 credits/time';

  @override
  String get creditsRuleInvite => 'Invite friends';

  @override
  String get creditsRuleInviteValue => '+50 credits/person';

  @override
  String get creditsTipLow =>
      '💡 Low on credits? Share a knowledge base you like to get rewards!';

  @override
  String get creditsTipBeta =>
      '⚠️ System is in beta; payment/recharge is not available yet.';

  @override
  String get creditsGotIt => 'Got it';

  @override
  String get masteredRuleTitle => 'What counts as \"mastered\"? 🎓';

  @override
  String get masteredRuleIntro =>
      'In reading view, tap [Save to vault] at the bottom and mark cards as:';

  @override
  String get masteredExpert => 'Expert';

  @override
  String get masteredMedium => 'Medium';

  @override
  String get masteredNewbie => 'Newbie';

  @override
  String get masteredRuleOutro =>
      'These marked items count as \"mastered\". You can review them in [Vault].';

  @override
  String get masteredUnderstood => 'Understood';

  @override
  String get profileSetNickname => 'Set nickname';

  @override
  String get profileKnowledgePoints => 'Knowledge points';

  @override
  String profileMasteredCount(int count) {
    return '\$count mastered';
  }

  @override
  String get profileMyCredits => 'My credits';

  @override
  String profileShareClicks(int count) {
    return 'Share clicks: \$count';
  }

  @override
  String get settingsSection => 'Settings';

  @override
  String get settingsTutorial => 'Tutorial';

  @override
  String get settingsTutorialOn => 'On (show every time)';

  @override
  String get settingsTutorialDefault => 'Default (first time only)';

  @override
  String get settingsShareNotes => 'Share my notes when sharing';

  @override
  String get settingsShareNotesOn => 'Viewers can see your notes';

  @override
  String get settingsShareNotesOff => 'Card content only';

  @override
  String get settingsAdhdTitle => 'Reading assist (ADHD Focus)';

  @override
  String get settingsAdhdOn => 'Three-color guide on';

  @override
  String get settingsAdhdOff => 'Off';

  @override
  String get settingsAdhdMode => 'Assist mode';

  @override
  String get settingsAdhdColor => 'Color';

  @override
  String get settingsAdhdBold => 'Bold';

  @override
  String get settingsAdhdHybrid => 'Hybrid';

  @override
  String get settingsAdhdStrength => 'Strength';

  @override
  String get settingsAdhdIntensityLow => 'Low';

  @override
  String get settingsAdhdIntensityMedium => 'Medium';

  @override
  String get settingsAdhdIntensityHigh => 'High';

  @override
  String get settingsAdhdTip =>
      '💡 Dynamic random algorithm places color anchors to reduce drift.';

  @override
  String sharePersonalCopy(String url) {
    return 'Hey! I\'m learning with Reado. Check it out:\n\$url';
  }

  @override
  String get shareSuccessReward => 'Shared! +10 credits 🎁';

  @override
  String get shareCopiedToClipboard => 'Copied to clipboard';

  @override
  String get sharePasteToFriends => 'Paste the link and share with friends.';

  @override
  String get shareFriendJoinReward =>
      'When a friend joins via your link, you get 50 more credits.';

  @override
  String checkInCreditsReceived(int credits) {
    return 'Daily check-in: \$credits credits';
  }

  @override
  String get checkInAlreadyToday => 'Already checked in today. 20 credits.';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileChooseAvatar => 'Choose avatar';

  @override
  String get profileNicknameLabel => 'Nickname';

  @override
  String get profileNicknameHint => 'Enter your nickname';

  @override
  String get profileSave => 'Save';

  @override
  String get feedbackThanks => 'Thanks! We\'ll get back to you.';

  @override
  String feedbackSubmitFailed(String e) {
    return 'Submit failed: \$e';
  }

  @override
  String get contactUsTitle => 'Contact us';

  @override
  String get contactSubtitle =>
      'Bug reports, feature suggestions, or partnership';

  @override
  String get feedbackTypeLabel => 'Feedback type';

  @override
  String get feedbackTypeBug => '🐛 Bug report';

  @override
  String get feedbackTypeAdvice => '💡 Feature suggestion';

  @override
  String get feedbackTypeCoop => '🤝 Partnership';

  @override
  String get feedbackTypeOther => '💬 Other';

  @override
  String get feedbackContentRequired => 'Please enter content';

  @override
  String get feedbackDescLabel => 'Description';

  @override
  String get feedbackDescHint => 'Describe your issue or suggestion...';

  @override
  String get feedbackContactLabel => 'Contact (optional)';

  @override
  String get feedbackContactHint => 'Email or WeChat for follow-up';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackGuestHint =>
      'You can submit without signing in. Add email or WeChat in Contact if you want a reply.';

  @override
  String get securityAnswerMin => 'Answer at least 2 characters';

  @override
  String get securitySetSuccess =>
      'Security question set. Use it to recover password.';

  @override
  String get securitySetFailed => 'Set failed';

  @override
  String get securitySetDialogTitle => 'Set security question';

  @override
  String get securitySetDialogIntro =>
      'For password recovery. Remember your answer.';

  @override
  String get securitySelectQuestion => 'Select question';

  @override
  String get securityAnswerLabel => 'Answer (min 2 characters)';

  @override
  String get securityQuestions0 => 'Your mother\'s first name?';

  @override
  String get securityQuestions1 => 'City you were born in?';

  @override
  String get securityQuestions2 => 'Your first pet\'s name?';

  @override
  String get securityQuestions3 => 'Your elementary school name?';

  @override
  String get securityQuestions4 => 'Spouse\'s birthday (MMDD, e.g. 0315)?';

  @override
  String get onboardingGuideFab => 'Getting started';

  @override
  String get onboardingChecklistTitle => '🎓 New user checklist';

  @override
  String get onboardingItem1 => '1. AI text deconstruct';

  @override
  String get onboardingItem2 => '2. View background tasks';

  @override
  String get onboardingItem3 => '3. Multimodal link parsing';

  @override
  String get onboardingItem4 => '4. View all cards';

  @override
  String get onboardingItem5 => '5. View AI notes';

  @override
  String get onboardingItem6 => '6. Share for credits';

  @override
  String get onboardingDone => '🎉 You\'re all set with Reado';

  @override
  String get onboardingHideList => 'Hide checklist';

  @override
  String get onboardingExitDialogTitle => 'Hide getting started?';

  @override
  String get onboardingExitDialogContent =>
      'You can turn it off if you\'re comfortable. You can turn it back on in Profile → Settings.';

  @override
  String get onboardingContinueLearn => 'Keep learning';

  @override
  String get onboardingEndTutorial => 'End tutorial';

  @override
  String get onboardingShareSnackbarTitle => 'Shared! +10 credits 🎁';

  @override
  String get onboardingShareSnackbarCopied => 'Copied to clipboard';

  @override
  String get onboardingShareSnackbarPaste =>
      'Paste the link and share with friends.';

  @override
  String get onboardingShareSnackbarFriend =>
      'When a friend joins via your link, you get 50 more credits.';

  @override
  String get addMaterialSelectModule => 'Select knowledge base';

  @override
  String get addMaterialSelectWhere => 'Choose storage:';

  @override
  String get addMaterialClickToSelect => 'Tap to select knowledge base';

  @override
  String get addMaterialUnknownModule => 'Unknown';

  @override
  String get addMaterialDefaultModule => 'Default knowledge base';

  @override
  String get addMaterialStoreTo => 'Store to: ';

  @override
  String get addMaterialTaskSubmitted =>
      '✅ Task submitted! AI is deconstructing in the background.';

  @override
  String get addMaterialFileTooBig => 'File size must not exceed 10MB';

  @override
  String get addMaterialSelectFileFailed => 'Select file failed';

  @override
  String get addMaterialUploadOrPaste =>
      'Please upload a file or paste a link first';

  @override
  String get addMaterialCannotReadFile => 'Cannot read file content';

  @override
  String get addMaterialInvalidUrl => 'Please enter a valid http/https link';

  @override
  String get addMaterialSelectTarget => 'Select target knowledge base';

  @override
  String get addMaterialSelectTargetHint => 'Choose where to store the result:';

  @override
  String get addMaterialNoModule => 'No knowledge base';

  @override
  String get addMaterialImportSuccess =>
      '✅ Imported! Cards added to your library.';

  @override
  String get addMaterialSaveFailed => 'Save failed';

  @override
  String get addMaterialTutorialIncomplete => 'Tutorial not completed';

  @override
  String get addMaterialTutorialSuggestion =>
      'We recommend completing the tutorial for the best experience. You can hide it later.\n\n(0 credits bonus when done)';

  @override
  String get addMaterialContinueAnyway => 'Continue anyway';

  @override
  String get addMaterialSkipTutorial => 'Skip for now';

  @override
  String get addMaterialTitleBatch => 'Add learning materials (batch)';

  @override
  String get addMaterialTitle => 'Add learning materials';

  @override
  String get addMaterialTutorialMode => 'Tutorial mode';

  @override
  String get addMaterialTabText => 'Text import';

  @override
  String get addMaterialTabMultimodal => 'Multimodal (AI)';

  @override
  String addMaterialQueueCount(int count) {
    return 'Batch queue (\$count)';
  }

  @override
  String get addMaterialQueueEmpty => 'Queue is empty';

  @override
  String get addMaterialQueueEmptyHint => 'Add content on the left to start';

  @override
  String get addMaterialRunningInBg => 'Running in background. Safe to leave.';

  @override
  String get addMaterialClearDone => 'Clear completed';

  @override
  String get addMaterialLeaveTemporary => 'Leave (continues in background)';

  @override
  String get addMaterialAllDone => 'All done';

  @override
  String get addMaterialStartBatch => 'Start batch';

  @override
  String get addMaterialPasteHint =>
      'Paste article, notes or web text here...\n\nExample:\n# What is Flutter\nFlutter is...\n\n# Features\n1. Cross-platform\n2. High performance...';

  @override
  String get addMaterialDirectTipTitle => 'Tips for direct import:';

  @override
  String get addMaterialDirectTipBody => 'Use Markdown headings (e.g. ';

  @override
  String get addMaterialDirectTipBody2 => '# Title';

  @override
  String get addMaterialDirectTipBody3 =>
      ') to split cards without AI. If no heading, first sentence is used as title.';

  @override
  String get addMaterialDirectImport => 'Direct import';

  @override
  String get addMaterialAddedToQueue => 'Added to queue';

  @override
  String get addMaterialDirectQueue => 'Direct queue';

  @override
  String get addMaterialAddedToAiQueue => 'Added to AI queue';

  @override
  String get addMaterialAiQueue => 'AI queue';

  @override
  String get addMaterialAiParsing => 'AI parsing...';

  @override
  String get addMaterialAiDeconstruct => 'AI smart deconstruct';

  @override
  String get addMaterialGenerating => 'Generating...';

  @override
  String addMaterialGeneratedCount(int count) {
    return 'Generated \$count items';
  }

  @override
  String get addMaterialLeaveForNow => 'Leave for now';

  @override
  String get addMaterialReedit => 'Re-edit';

  @override
  String get addMaterialConnecting => 'Connecting to AI...';

  @override
  String get addMaterialAiReading =>
      'AI is reading your content.\nFirst card usually takes 5-10 seconds...';

  @override
  String get addMaterialNextCard => 'Generating next card...';

  @override
  String get addMaterialQuestion => 'Q: ';

  @override
  String get addMaterialNone => 'None';

  @override
  String get addMaterialBackToEdit => 'Back to edit';

  @override
  String get addMaterialConfirmSave => 'Confirm & save';

  @override
  String get addMaterialPickedFile => 'Selected (tap to change)';

  @override
  String get addMaterialFileHint => 'PDF, Word, Markdown supported';

  @override
  String get addMaterialUrlHint => 'Most web pages, YouTube, etc.';

  @override
  String addMaterialCharsCount(int count, String time) {
    return '\$count chars · est. \$time';
  }

  @override
  String get addMaterialFileInQueue => 'File added to queue';

  @override
  String get addMaterialLinkInQueue => 'Link added to queue';

  @override
  String get addMaterialJoinQueue => 'Add to queue';

  @override
  String get addMaterialParse => 'Parse';

  @override
  String addMaterialStartDeconstruct(int credits) {
    return 'Start smart deconstruct (\$credits credits)';
  }

  @override
  String get addMaterialWaitParse => 'Waiting for parse...';

  @override
  String get addMaterialDirectSave => 'Save directly (no deconstruct)';

  @override
  String get addMaterialComingSoon => 'Coming soon';

  @override
  String get addMaterialQueueBusy =>
      'Queue has pending tasks. Clear the queue or use batch mode.';

  @override
  String get addMaterialConfirmBatch => 'Confirm batch';

  @override
  String get addMaterialConfirmBatchDirectOnly =>
      'Only direct-import items in queue. No credits. Start?';

  @override
  String get addMaterialStart => 'Start';

  @override
  String addMaterialCreditsDeduct(int credits) {
    return 'This will use \$credits credits';
  }

  @override
  String addMaterialCreditsSummaryAi(int aiCount) {
    return '\$aiCount items, charged by length (~10-40/item)';
  }

  @override
  String addMaterialCreditsSummaryMixed(int extractedCredits, int rest) {
    return '\$extractedCredits for parsed; \$rest items by length (10-40/item)';
  }

  @override
  String get addMaterialConfirmDeconstruct => 'Confirm smart deconstruct?';

  @override
  String addMaterialConfirmBatchFull(int total, int aiCount) {
    return '\$total items (\$aiCount AI deconstruct).';
  }

  @override
  String get addMaterialCreditsTip =>
      '💡 Charged by length (~10-40/item), same as single deconstruct.';

  @override
  String get addMaterialStartGenerate => 'Start generation';

  @override
  String get addMaterialConfirmSingle => 'Confirm deconstruct?';

  @override
  String addMaterialCharsRecognized(int count) {
    return 'Content recognized: ~\$count chars';
  }

  @override
  String addMaterialEstTime(String time) {
    return 'Est. time: \$time';
  }

  @override
  String get addMaterialDeductLabel => 'Credits to use:';

  @override
  String get addMaterialCreditsUnit => ' credits';

  @override
  String get addMaterialFreeParseTip =>
      '💡 Parsing is free. Smart deconstruct uses credits by content depth.';

  @override
  String get addMaterialReadoFree => 'Reado: AI chat & file parsing are free';

  @override
  String get addMaterialInsufficientCredits => 'Insufficient credits';

  @override
  String get addMaterialInsufficientMessage =>
      'AI parse or generate needs 10 credits. Share a knowledge base to earn more!';

  @override
  String get addMaterialLearnMore => 'Learn more';

  @override
  String get addMaterialGoShare => 'Share to earn';

  @override
  String get addMaterialStyleTitle => 'AI deconstruct style';

  @override
  String get addMaterialModeStandard => 'Standard';

  @override
  String get addMaterialModeStandardDesc => 'Rigorous & complete';

  @override
  String get addMaterialModeGrandma => 'Grandma';

  @override
  String get addMaterialModeGrandmaDesc => 'Super simple';

  @override
  String get addMaterialModePhd => 'PhD';

  @override
  String get addMaterialModePhdDesc => 'Plain language';

  @override
  String get addMaterialModePodcast => 'Podcast';

  @override
  String get addMaterialModePodcastDesc => 'Two-person dialogue';

  @override
  String get feedSwipeBackToBody => 'Swipe left for article';

  @override
  String get feedSwipeReleaseBackList => 'Release to return to feed';

  @override
  String get feedSwipeLeftBack => 'Swipe left to go back';

  @override
  String get feedSwipeReleasePrevious => 'Release for previous';

  @override
  String get feedSwipePullDownMore => 'Pull down';

  @override
  String get feedSwipeReleaseNext => 'Release for next';

  @override
  String get feedSwipePullUpMore => 'Pull up';

  @override
  String get studyTitleAll => 'All knowledge';

  @override
  String get studyTitleAiNotes => 'AI notes';

  @override
  String get studyTitleSearch => 'Search results';

  @override
  String get studyTitleModule => 'Knowledge module';

  @override
  String get studySingleColumn => 'Single column';

  @override
  String studyMinutes(int n) {
    return '\$n min';
  }

  @override
  String get studyAllButton => 'All';

  @override
  String get studyBodySaved => 'Content saved';

  @override
  String get studySaveFailed => 'Save failed';

  @override
  String get studyAllTutorialHint =>
      'Tap \"All\" to view all cards or switch between cards.';

  @override
  String get studyNextSection => 'Next';

  @override
  String get studyEditBody => 'Edit content';

  @override
  String get studyViewing => 'Viewing';

  @override
  String get studyDeleteCardTitle => 'Delete this card?';

  @override
  String get studyDeleteCardContent => 'Cannot be recovered. Delete anyway?';

  @override
  String get moduleLoadFailed => 'Load failed';

  @override
  String get moduleGoLogin => 'Go to login';

  @override
  String get moduleSharedLibrary => 'Shared knowledge base';

  @override
  String moduleCardCount(int count) {
    return '\$count cards';
  }

  @override
  String get moduleSaveToMyLibrary => 'Save to my library';

  @override
  String get moduleStartReading => 'Start reading';

  @override
  String get moduleSavingToLibrary => 'Saving to your library…';

  @override
  String get moduleAddedGoHome => 'Added. Go to Home to start learning.';

  @override
  String get moduleSavedToLibrary => 'Saved to your library';

  @override
  String moduleViews(int n) {
    return '\$n views';
  }

  @override
  String moduleSaves(int n) {
    return '\$n saves';
  }

  @override
  String moduleLikes(int n) {
    return '\$n likes';
  }

  @override
  String get moduleThanksLike => 'Thanks for the like!';

  @override
  String get moduleAlreadyLiked => 'You already liked this';

  @override
  String moduleShareData(int views, int saves, int likes) {
    return 'Share: \$views views · \$saves saves · \$likes likes';
  }

  @override
  String get moduleAllKnowledge => 'All knowledge';

  @override
  String get moduleAllKnowledgeDesc => 'All your knowledge cards are here';

  @override
  String get moduleUnknown => 'Unknown library';

  @override
  String get moduleNotFound => 'Library not found';

  @override
  String get moduleShareLibrary => 'Share library';

  @override
  String get moduleShareWithNotes => 'Share notes with viewers?';

  @override
  String get moduleShareLibraryOnly => 'Share library only';

  @override
  String get moduleShareLibraryAndNotes => 'Share library & notes';

  @override
  String get moduleRenameLibrary => 'Rename library';

  @override
  String get moduleNameLabel => 'Name';

  @override
  String get moduleNameHint => 'Enter library name';

  @override
  String get moduleUpdatedName => 'Name updated';

  @override
  String get moduleUpdatedDetails => 'Details updated';

  @override
  String get moduleEditDetails => 'Edit details';

  @override
  String get moduleDescLabel => 'Description';

  @override
  String get moduleHideLibrary => 'Hide this library?';

  @override
  String get moduleDeleteLibrary => 'Delete this library?';

  @override
  String get moduleHideLibraryDesc =>
      'It will be hidden. You can restore it in Profile → Hidden content.';

  @override
  String get moduleDeleteLibraryDesc =>
      'This cannot be undone. All cards will be removed.';

  @override
  String get moduleHide => 'Hide';

  @override
  String get moduleDelete => 'Delete';

  @override
  String get moduleLibraryHidden => 'Library hidden';

  @override
  String get moduleLibraryDeleted => 'Library deleted';

  @override
  String get moduleRename => 'Rename';

  @override
  String get modulePermanentDelete => 'Permanent delete';

  @override
  String moduleCardsTag(int count) {
    return '\$count cards';
  }

  @override
  String get moduleOfficial => 'Official';

  @override
  String get modulePrivate => 'Private';

  @override
  String moduleMasteredPct(int pct) {
    return '\$pct% mastered';
  }

  @override
  String get moduleStartLearning => 'Start learning';

  @override
  String get moduleMovePrompt => 'Create another library first to move cards.';

  @override
  String get moduleMoveToLibrary => 'Move to library';

  @override
  String get moduleMoved => 'Moved to target library';

  @override
  String get moduleHideCard => 'Hide this card?';

  @override
  String get moduleDeleteCard => 'Delete this card?';

  @override
  String get moduleHideCardDesc => 'You can restore it in settings.';

  @override
  String get moduleDeleteCardDesc => 'Cannot be recovered.';

  @override
  String get moduleCardHidden => 'Card hidden';

  @override
  String get moduleCardRemoved => 'Card removed';

  @override
  String get moduleMove => 'Move';

  @override
  String get dialogConfirm => 'OK';

  @override
  String get aiHoarderTitle => 'AI assistant';

  @override
  String get aiHoarderHint => 'Ask the assistant…';

  @override
  String get notePinnedSuccess => 'Note pinned!';

  @override
  String get noteShareNoSave =>
      'Cannot save note to this card from shared content';

  @override
  String get noteLoginToSave => 'Sign in to save notes';

  @override
  String get noteLoginToSaveDesc => 'Sign in to save notes to your library.';

  @override
  String get noteDeleteConfirm => 'Delete this note?';

  @override
  String get noteDeleteConfirmDesc => 'This pinned note will be removed.';

  @override
  String get noteEditNote => 'Edit note';

  @override
  String get noteContentLabel => 'Note content';

  @override
  String get noteAiGuide => 'Official guide';

  @override
  String get noteAiNotes => 'AI notes';

  @override
  String get noteTooltipEdit => 'Edit note';

  @override
  String get noteTooltipDelete => 'Delete note';

  @override
  String get aiNotesPageTitle => 'AI notes';

  @override
  String get aiNotesSearchHint => 'Search notes…';

  @override
  String get aiNotesEmpty => 'No AI notes yet';

  @override
  String get aiNotesEmptyHint =>
      'Tap \"Add note\" while learning and AI will summarize key points.';

  @override
  String noteReviewTitle(int current, int total) {
    return 'Note review \$current/\$total';
  }

  @override
  String get vaultFilterAll => 'All';

  @override
  String get vaultFilterNewbie => 'Newbie';

  @override
  String get vaultFilterMedium => 'Medium';

  @override
  String get vaultFilterExpert => 'Expert';

  @override
  String get vaultFilterNew => 'New';

  @override
  String aiNotesNoteCount(int count) {
    return '\$count notes';
  }

  @override
  String get notNow => 'Not now';

  @override
  String get collectLoginTitle => 'Sign in to save';

  @override
  String get collectLoginContent => 'Go to sign in?';

  @override
  String get shareNoCollect => 'Cannot save to vault from shared content';

  @override
  String get favoritedSnackbar => 'Saved to vault';

  @override
  String get unfavoritedSnackbar => 'Removed from vault';

  @override
  String markedAsLabel(String label) {
    return 'Marked as \$label';
  }

  @override
  String get delete => 'Delete';

  @override
  String get vaultTitle => 'Vault';

  @override
  String get vaultSearchHint => 'Search saved cards…';

  @override
  String get vaultEmpty => 'No saved cards yet';

  @override
  String get vaultEmptyHint => 'Tap ❤️ in Study to save content';

  @override
  String get noteReviewReleasePrev => 'Release to switch to previous';

  @override
  String get noteReviewPullPrev => 'Pull down to continue';

  @override
  String get noteReviewReleaseNext => 'Release to switch to next';

  @override
  String get noteReviewPullNext => 'Pull up to continue';

  @override
  String moduleShareCopyBody(String url, String title) {
    return 'Hey! I\'m learning this library with Reado. Check it out:\n\$url\n\nThis is my library \"\$title\". You can save it to yours.';
  }
}
