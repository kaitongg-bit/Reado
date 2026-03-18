import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Reado'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get appearanceDark;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get appearanceLight;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your knowledge journey'**
  String get createAccountSubtitle;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue your learning'**
  String get continueLearning;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameHint;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get noAccount;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @agreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By signing in you agree to the terms and privacy policy.'**
  String get agreeTerms;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @navStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get navStudy;

  /// No description provided for @navVault.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get navVault;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @lab.
  ///
  /// In en, this message translates to:
  /// **'Lab'**
  String get lab;

  /// No description provided for @warRoom.
  ///
  /// In en, this message translates to:
  /// **'War Room'**
  String get warRoom;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @securityQuestion.
  ///
  /// In en, this message translates to:
  /// **'Security question'**
  String get securityQuestion;

  /// No description provided for @securityQuestionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recover password if you forget it'**
  String get securityQuestionSubtitle;

  /// No description provided for @hiddenContent.
  ///
  /// In en, this message translates to:
  /// **'Hidden content'**
  String get hiddenContent;

  /// No description provided for @hiddenContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore hidden modules or cards'**
  String get hiddenContentSubtitle;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact / Feedback'**
  String get contactUs;

  /// No description provided for @aboutReado.
  ///
  /// In en, this message translates to:
  /// **'About Reado'**
  String get aboutReado;

  /// No description provided for @aboutReadoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Features and design'**
  String get aboutReadoSubtitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and choose one way to recover:'**
  String get forgotPasswordIntro;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send reset email'**
  String get sendResetEmail;

  /// No description provided for @useSecurityIfNoEmail.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t receive the email (e.g. some regions), use security question.'**
  String get useSecurityIfNoEmail;

  /// No description provided for @securityRecover.
  ///
  /// In en, this message translates to:
  /// **'Recover via security question'**
  String get securityRecover;

  /// No description provided for @securityAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Your answer'**
  String get securityAnswerHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password (at least 6 characters)'**
  String get newPasswordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmPasswordHint;

  /// No description provided for @confirmResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get confirmResetPassword;

  /// No description provided for @successResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Reset email sent. Check your inbox or spam, or use security question.'**
  String get successResetEmail;

  /// No description provided for @successPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Please sign in with your new password.'**
  String get successPasswordReset;

  /// No description provided for @errorFillEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get errorFillEmail;

  /// No description provided for @errorFillEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email first'**
  String get errorFillEmailFirst;

  /// No description provided for @errorSecurityAnswer.
  ///
  /// In en, this message translates to:
  /// **'Please enter your security answer'**
  String get errorSecurityAnswer;

  /// No description provided for @errorPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get errorPasswordMin;

  /// No description provided for @errorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get errorPasswordMismatch;

  /// No description provided for @errorNoSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security question not set. Use email reset or contact support.'**
  String get errorNoSecurity;

  /// No description provided for @errorGetSecurity.
  ///
  /// In en, this message translates to:
  /// **'Failed to load security question'**
  String get errorGetSecurity;

  /// No description provided for @errorResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Reset failed'**
  String get errorResetFailed;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please try again.'**
  String get errorNetwork;

  /// No description provided for @errorSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send. Please try again.'**
  String get errorSendFailed;

  /// No description provided for @tabOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get tabOfficial;

  /// No description provided for @tabPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get tabPersonal;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @emptyHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyHere;

  /// No description provided for @aiDeconstruct.
  ///
  /// In en, this message translates to:
  /// **'AI Deconstruct'**
  String get aiDeconstruct;

  /// No description provided for @aiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI Notes'**
  String get aiNotes;

  /// No description provided for @taskCenter.
  ///
  /// In en, this message translates to:
  /// **'Task Center'**
  String get taskCenter;

  /// No description provided for @searchKnowledgeHint.
  ///
  /// In en, this message translates to:
  /// **'Search knowledge...'**
  String get searchKnowledgeHint;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @lateNight.
  ///
  /// In en, this message translates to:
  /// **'Late night'**
  String get lateNight;

  /// No description provided for @createModule.
  ///
  /// In en, this message translates to:
  /// **'Create knowledge base'**
  String get createModule;

  /// No description provided for @moduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get moduleTitle;

  /// No description provided for @moduleTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Interview prep'**
  String get moduleTitleHint;

  /// No description provided for @moduleDesc.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get moduleDesc;

  /// No description provided for @moduleDescHint.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get moduleDescHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @errorLoginToCreate.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to create your knowledge base'**
  String get errorLoginToCreate;

  /// No description provided for @successModuleCreated.
  ///
  /// In en, this message translates to:
  /// **'Knowledge base \"\$title\" is ready!'**
  String successModuleCreated(String title);

  /// No description provided for @errorCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create'**
  String get errorCreateFailed;

  /// No description provided for @tutorialTextAiDeconstruct.
  ///
  /// In en, this message translates to:
  /// **'Tap [AI Deconstruct] to start your smart learning journey'**
  String get tutorialTextAiDeconstruct;

  /// No description provided for @tutorialTextTaskCenter.
  ///
  /// In en, this message translates to:
  /// **'See background tasks here. When ready, go back to your knowledge base (e.g. Personal > Default) and tap to learn.'**
  String get tutorialTextTaskCenter;

  /// No description provided for @tutorialTextMultimodal.
  ///
  /// In en, this message translates to:
  /// **'Multimodal parsing starts here too. Tap [AI Deconstruct] and switch tabs.'**
  String get tutorialTextMultimodal;

  /// No description provided for @tutorialTextAllCards.
  ///
  /// In en, this message translates to:
  /// **'Tap a knowledge base to open it, then tap [All] on the top right to see all cards.'**
  String get tutorialTextAllCards;

  /// No description provided for @tutorialTextAiNotes.
  ///
  /// In en, this message translates to:
  /// **'Tap [AI Notes] to see all aggregated notes.'**
  String get tutorialTextAiNotes;

  /// No description provided for @quote1.
  ///
  /// In en, this message translates to:
  /// **'Did you learn today? You little hoarder 🐹'**
  String get quote1;

  /// No description provided for @quote2.
  ///
  /// In en, this message translates to:
  /// **'Can\'t outwork others, can\'t fully chill? Then learn a little 📖'**
  String get quote2;

  /// No description provided for @quote3.
  ///
  /// In en, this message translates to:
  /// **'Your brain is craving new knowledge. Feed it 💡'**
  String get quote3;

  /// No description provided for @quote4.
  ///
  /// In en, this message translates to:
  /// **'Work hard now so you can slack off with a clear conscience later 🐟'**
  String get quote4;

  /// No description provided for @quote5.
  ///
  /// In en, this message translates to:
  /// **'Pocket time counts too. One idea in your head is a win ✨'**
  String get quote5;

  /// No description provided for @quote6.
  ///
  /// In en, this message translates to:
  /// **'The dopamine from learning beats short videos 🧠'**
  String get quote6;

  /// No description provided for @quote7.
  ///
  /// In en, this message translates to:
  /// **'Batch on desktop, then brush cards in bed 🛏️'**
  String get quote7;

  /// No description provided for @shareStatsFormat.
  ///
  /// In en, this message translates to:
  /// **'\$views views · \$saves saves · \$likes likes'**
  String shareStatsFormat(int views, int saves, int likes);

  /// No description provided for @creditsRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Credits rules 💰'**
  String get creditsRuleTitle;

  /// No description provided for @creditsRuleNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user signup'**
  String get creditsRuleNewUser;

  /// No description provided for @creditsRuleNewUserValue.
  ///
  /// In en, this message translates to:
  /// **'+200 credits'**
  String get creditsRuleNewUserValue;

  /// No description provided for @creditsRuleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in'**
  String get creditsRuleDaily;

  /// No description provided for @creditsRuleDailyValue.
  ///
  /// In en, this message translates to:
  /// **'+20 credits/day'**
  String get creditsRuleDailyValue;

  /// No description provided for @creditsRuleAiChat.
  ///
  /// In en, this message translates to:
  /// **'AI chat & practice'**
  String get creditsRuleAiChat;

  /// No description provided for @creditsRuleAiChatValue.
  ///
  /// In en, this message translates to:
  /// **'Free for now ⚡️'**
  String get creditsRuleAiChatValue;

  /// No description provided for @creditsRuleExtraction.
  ///
  /// In en, this message translates to:
  /// **'Content extraction / parsing'**
  String get creditsRuleExtraction;

  /// No description provided for @creditsRuleExtractionValue.
  ///
  /// In en, this message translates to:
  /// **'Free for now ⚡️'**
  String get creditsRuleExtractionValue;

  /// No description provided for @creditsRuleAiDeconstruct.
  ///
  /// In en, this message translates to:
  /// **'AI smart deconstruct'**
  String get creditsRuleAiDeconstruct;

  /// No description provided for @creditsRuleAiDeconstructValue.
  ///
  /// In en, this message translates to:
  /// **'10-40 credits/time'**
  String get creditsRuleAiDeconstructValue;

  /// No description provided for @creditsRuleShare.
  ///
  /// In en, this message translates to:
  /// **'Tap share button'**
  String get creditsRuleShare;

  /// No description provided for @creditsRuleShareValue.
  ///
  /// In en, this message translates to:
  /// **'+10 credits/time'**
  String get creditsRuleShareValue;

  /// No description provided for @creditsRuleInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get creditsRuleInvite;

  /// No description provided for @creditsRuleInviteValue.
  ///
  /// In en, this message translates to:
  /// **'+50 credits/person'**
  String get creditsRuleInviteValue;

  /// No description provided for @creditsTipLow.
  ///
  /// In en, this message translates to:
  /// **'💡 Low on credits? Share a knowledge base you like to get rewards!'**
  String get creditsTipLow;

  /// No description provided for @creditsTipBeta.
  ///
  /// In en, this message translates to:
  /// **'⚠️ System is in beta; payment/recharge is not available yet.'**
  String get creditsTipBeta;

  /// No description provided for @creditsGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get creditsGotIt;

  /// No description provided for @masteredRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'What counts as \"mastered\"? 🎓'**
  String get masteredRuleTitle;

  /// No description provided for @masteredRuleIntro.
  ///
  /// In en, this message translates to:
  /// **'In reading view, tap [Save to vault] at the bottom and mark cards as:'**
  String get masteredRuleIntro;

  /// No description provided for @masteredExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get masteredExpert;

  /// No description provided for @masteredMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get masteredMedium;

  /// No description provided for @masteredNewbie.
  ///
  /// In en, this message translates to:
  /// **'Newbie'**
  String get masteredNewbie;

  /// No description provided for @masteredRuleOutro.
  ///
  /// In en, this message translates to:
  /// **'These marked items count as \"mastered\". You can review them in [Vault].'**
  String get masteredRuleOutro;

  /// No description provided for @masteredUnderstood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get masteredUnderstood;

  /// No description provided for @profileSetNickname.
  ///
  /// In en, this message translates to:
  /// **'Set nickname'**
  String get profileSetNickname;

  /// No description provided for @profileKnowledgePoints.
  ///
  /// In en, this message translates to:
  /// **'Knowledge points'**
  String get profileKnowledgePoints;

  /// No description provided for @profileMasteredCount.
  ///
  /// In en, this message translates to:
  /// **'\$count mastered'**
  String profileMasteredCount(int count);

  /// No description provided for @profileMyCredits.
  ///
  /// In en, this message translates to:
  /// **'My credits'**
  String get profileMyCredits;

  /// No description provided for @profileShareClicks.
  ///
  /// In en, this message translates to:
  /// **'Share clicks: \$count'**
  String profileShareClicks(int count);

  /// No description provided for @settingsSection.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSection;

  /// No description provided for @settingsTutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get settingsTutorial;

  /// No description provided for @settingsTutorialOn.
  ///
  /// In en, this message translates to:
  /// **'On (show every time)'**
  String get settingsTutorialOn;

  /// No description provided for @settingsTutorialDefault.
  ///
  /// In en, this message translates to:
  /// **'Default (first time only)'**
  String get settingsTutorialDefault;

  /// No description provided for @settingsShareNotes.
  ///
  /// In en, this message translates to:
  /// **'Share my notes when sharing'**
  String get settingsShareNotes;

  /// No description provided for @settingsShareNotesOn.
  ///
  /// In en, this message translates to:
  /// **'Viewers can see your notes'**
  String get settingsShareNotesOn;

  /// No description provided for @settingsShareNotesOff.
  ///
  /// In en, this message translates to:
  /// **'Card content only'**
  String get settingsShareNotesOff;

  /// No description provided for @settingsAdhdTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading assist (ADHD Focus)'**
  String get settingsAdhdTitle;

  /// No description provided for @settingsAdhdOn.
  ///
  /// In en, this message translates to:
  /// **'Three-color guide on'**
  String get settingsAdhdOn;

  /// No description provided for @settingsAdhdOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsAdhdOff;

  /// No description provided for @settingsAdhdMode.
  ///
  /// In en, this message translates to:
  /// **'Assist mode'**
  String get settingsAdhdMode;

  /// No description provided for @settingsAdhdColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get settingsAdhdColor;

  /// No description provided for @settingsAdhdBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get settingsAdhdBold;

  /// No description provided for @settingsAdhdHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get settingsAdhdHybrid;

  /// No description provided for @settingsAdhdStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get settingsAdhdStrength;

  /// No description provided for @settingsAdhdTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Dynamic random algorithm places color anchors to reduce drift.'**
  String get settingsAdhdTip;

  /// No description provided for @sharePersonalCopy.
  ///
  /// In en, this message translates to:
  /// **'Hey! I\'m learning with Reado. Check it out:\n\$url'**
  String sharePersonalCopy(String url);

  /// No description provided for @shareSuccessReward.
  ///
  /// In en, this message translates to:
  /// **'Shared! +10 credits 🎁'**
  String get shareSuccessReward;

  /// No description provided for @shareCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get shareCopiedToClipboard;

  /// No description provided for @sharePasteToFriends.
  ///
  /// In en, this message translates to:
  /// **'Paste the link and share with friends.'**
  String get sharePasteToFriends;

  /// No description provided for @shareFriendJoinReward.
  ///
  /// In en, this message translates to:
  /// **'When a friend joins via your link, you get 50 more credits.'**
  String get shareFriendJoinReward;

  /// No description provided for @checkInCreditsReceived.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in: \$credits credits'**
  String checkInCreditsReceived(int credits);

  /// No description provided for @checkInAlreadyToday.
  ///
  /// In en, this message translates to:
  /// **'Already checked in today. 20 credits.'**
  String get checkInAlreadyToday;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @profileChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar'**
  String get profileChooseAvatar;

  /// No description provided for @profileNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get profileNicknameLabel;

  /// No description provided for @profileNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your nickname'**
  String get profileNicknameHint;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get profileSave;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks! We\'ll get back to you.'**
  String get feedbackThanks;

  /// No description provided for @feedbackSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Submit failed: \$e'**
  String feedbackSubmitFailed(String e);

  /// No description provided for @contactUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUsTitle;

  /// No description provided for @contactSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bug reports, feature suggestions, or partnership'**
  String get contactSubtitle;

  /// No description provided for @feedbackTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback type'**
  String get feedbackTypeLabel;

  /// No description provided for @feedbackTypeBug.
  ///
  /// In en, this message translates to:
  /// **'🐛 Bug report'**
  String get feedbackTypeBug;

  /// No description provided for @feedbackTypeAdvice.
  ///
  /// In en, this message translates to:
  /// **'💡 Feature suggestion'**
  String get feedbackTypeAdvice;

  /// No description provided for @feedbackTypeCoop.
  ///
  /// In en, this message translates to:
  /// **'🤝 Partnership'**
  String get feedbackTypeCoop;

  /// No description provided for @feedbackTypeOther.
  ///
  /// In en, this message translates to:
  /// **'💬 Other'**
  String get feedbackTypeOther;

  /// No description provided for @feedbackContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter content'**
  String get feedbackContentRequired;

  /// No description provided for @feedbackDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get feedbackDescLabel;

  /// No description provided for @feedbackDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue or suggestion...'**
  String get feedbackDescHint;

  /// No description provided for @feedbackContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact (optional)'**
  String get feedbackContactLabel;

  /// No description provided for @feedbackContactHint.
  ///
  /// In en, this message translates to:
  /// **'Email or WeChat for follow-up'**
  String get feedbackContactHint;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// No description provided for @securityAnswerMin.
  ///
  /// In en, this message translates to:
  /// **'Answer at least 2 characters'**
  String get securityAnswerMin;

  /// No description provided for @securitySetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Security question set. Use it to recover password.'**
  String get securitySetSuccess;

  /// No description provided for @securitySetFailed.
  ///
  /// In en, this message translates to:
  /// **'Set failed'**
  String get securitySetFailed;

  /// No description provided for @securitySetDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Set security question'**
  String get securitySetDialogTitle;

  /// No description provided for @securitySetDialogIntro.
  ///
  /// In en, this message translates to:
  /// **'For password recovery. Remember your answer.'**
  String get securitySetDialogIntro;

  /// No description provided for @securitySelectQuestion.
  ///
  /// In en, this message translates to:
  /// **'Select question'**
  String get securitySelectQuestion;

  /// No description provided for @securityAnswerLabel.
  ///
  /// In en, this message translates to:
  /// **'Answer (min 2 characters)'**
  String get securityAnswerLabel;

  /// No description provided for @securityQuestions0.
  ///
  /// In en, this message translates to:
  /// **'Your mother\'s first name?'**
  String get securityQuestions0;

  /// No description provided for @securityQuestions1.
  ///
  /// In en, this message translates to:
  /// **'City you were born in?'**
  String get securityQuestions1;

  /// No description provided for @securityQuestions2.
  ///
  /// In en, this message translates to:
  /// **'Your first pet\'s name?'**
  String get securityQuestions2;

  /// No description provided for @securityQuestions3.
  ///
  /// In en, this message translates to:
  /// **'Your elementary school name?'**
  String get securityQuestions3;

  /// No description provided for @securityQuestions4.
  ///
  /// In en, this message translates to:
  /// **'Spouse\'s birthday (MMDD, e.g. 0315)?'**
  String get securityQuestions4;

  /// No description provided for @onboardingGuideFab.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get onboardingGuideFab;

  /// No description provided for @onboardingChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'🎓 New user checklist'**
  String get onboardingChecklistTitle;

  /// No description provided for @onboardingItem1.
  ///
  /// In en, this message translates to:
  /// **'1. AI text deconstruct'**
  String get onboardingItem1;

  /// No description provided for @onboardingItem2.
  ///
  /// In en, this message translates to:
  /// **'2. View background tasks'**
  String get onboardingItem2;

  /// No description provided for @onboardingItem3.
  ///
  /// In en, this message translates to:
  /// **'3. Multimodal link parsing'**
  String get onboardingItem3;

  /// No description provided for @onboardingItem4.
  ///
  /// In en, this message translates to:
  /// **'4. View all cards'**
  String get onboardingItem4;

  /// No description provided for @onboardingItem5.
  ///
  /// In en, this message translates to:
  /// **'5. View AI notes'**
  String get onboardingItem5;

  /// No description provided for @onboardingItem6.
  ///
  /// In en, this message translates to:
  /// **'6. Share for credits'**
  String get onboardingItem6;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'🎉 You\'re all set with Reado'**
  String get onboardingDone;

  /// No description provided for @onboardingHideList.
  ///
  /// In en, this message translates to:
  /// **'Hide checklist'**
  String get onboardingHideList;

  /// No description provided for @onboardingExitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide getting started?'**
  String get onboardingExitDialogTitle;

  /// No description provided for @onboardingExitDialogContent.
  ///
  /// In en, this message translates to:
  /// **'You can turn it off if you\'re comfortable. You can turn it back on in Profile → Settings.'**
  String get onboardingExitDialogContent;

  /// No description provided for @onboardingContinueLearn.
  ///
  /// In en, this message translates to:
  /// **'Keep learning'**
  String get onboardingContinueLearn;

  /// No description provided for @onboardingEndTutorial.
  ///
  /// In en, this message translates to:
  /// **'End tutorial'**
  String get onboardingEndTutorial;

  /// No description provided for @onboardingShareSnackbarTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared! +10 credits 🎁'**
  String get onboardingShareSnackbarTitle;

  /// No description provided for @onboardingShareSnackbarCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get onboardingShareSnackbarCopied;

  /// No description provided for @onboardingShareSnackbarPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste the link and share with friends.'**
  String get onboardingShareSnackbarPaste;

  /// No description provided for @onboardingShareSnackbarFriend.
  ///
  /// In en, this message translates to:
  /// **'When a friend joins via your link, you get 50 more credits.'**
  String get onboardingShareSnackbarFriend;

  /// No description provided for @addMaterialSelectModule.
  ///
  /// In en, this message translates to:
  /// **'Select knowledge base'**
  String get addMaterialSelectModule;

  /// No description provided for @addMaterialSelectWhere.
  ///
  /// In en, this message translates to:
  /// **'Choose storage:'**
  String get addMaterialSelectWhere;

  /// No description provided for @addMaterialClickToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select knowledge base'**
  String get addMaterialClickToSelect;

  /// No description provided for @addMaterialUnknownModule.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get addMaterialUnknownModule;

  /// No description provided for @addMaterialDefaultModule.
  ///
  /// In en, this message translates to:
  /// **'Default knowledge base'**
  String get addMaterialDefaultModule;

  /// No description provided for @addMaterialStoreTo.
  ///
  /// In en, this message translates to:
  /// **'Store to: '**
  String get addMaterialStoreTo;

  /// No description provided for @addMaterialTaskSubmitted.
  ///
  /// In en, this message translates to:
  /// **'✅ Task submitted! AI is deconstructing in the background.'**
  String get addMaterialTaskSubmitted;

  /// No description provided for @addMaterialFileTooBig.
  ///
  /// In en, this message translates to:
  /// **'File size must not exceed 10MB'**
  String get addMaterialFileTooBig;

  /// No description provided for @addMaterialSelectFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Select file failed'**
  String get addMaterialSelectFileFailed;

  /// No description provided for @addMaterialUploadOrPaste.
  ///
  /// In en, this message translates to:
  /// **'Please upload a file or paste a link first'**
  String get addMaterialUploadOrPaste;

  /// No description provided for @addMaterialCannotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Cannot read file content'**
  String get addMaterialCannotReadFile;

  /// No description provided for @addMaterialInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid http/https link'**
  String get addMaterialInvalidUrl;

  /// No description provided for @addMaterialSelectTarget.
  ///
  /// In en, this message translates to:
  /// **'Select target knowledge base'**
  String get addMaterialSelectTarget;

  /// No description provided for @addMaterialSelectTargetHint.
  ///
  /// In en, this message translates to:
  /// **'Choose where to store the result:'**
  String get addMaterialSelectTargetHint;

  /// No description provided for @addMaterialNoModule.
  ///
  /// In en, this message translates to:
  /// **'No knowledge base'**
  String get addMaterialNoModule;

  /// No description provided for @addMaterialImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Imported! Cards added to your library.'**
  String get addMaterialImportSuccess;

  /// No description provided for @addMaterialSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get addMaterialSaveFailed;

  /// No description provided for @addMaterialTutorialIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Tutorial not completed'**
  String get addMaterialTutorialIncomplete;

  /// No description provided for @addMaterialTutorialSuggestion.
  ///
  /// In en, this message translates to:
  /// **'We recommend completing the tutorial for the best experience. You can hide it later.\n\n(0 credits bonus when done)'**
  String get addMaterialTutorialSuggestion;

  /// No description provided for @addMaterialContinueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get addMaterialContinueAnyway;

  /// No description provided for @addMaterialSkipTutorial.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get addMaterialSkipTutorial;

  /// No description provided for @addMaterialTitleBatch.
  ///
  /// In en, this message translates to:
  /// **'Add learning materials (batch)'**
  String get addMaterialTitleBatch;

  /// No description provided for @addMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Add learning materials'**
  String get addMaterialTitle;

  /// No description provided for @addMaterialTutorialMode.
  ///
  /// In en, this message translates to:
  /// **'Tutorial mode'**
  String get addMaterialTutorialMode;

  /// No description provided for @addMaterialTabText.
  ///
  /// In en, this message translates to:
  /// **'Text import'**
  String get addMaterialTabText;

  /// No description provided for @addMaterialTabMultimodal.
  ///
  /// In en, this message translates to:
  /// **'Multimodal (AI)'**
  String get addMaterialTabMultimodal;

  /// No description provided for @addMaterialQueueCount.
  ///
  /// In en, this message translates to:
  /// **'Batch queue (\$count)'**
  String addMaterialQueueCount(int count);

  /// No description provided for @addMaterialQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get addMaterialQueueEmpty;

  /// No description provided for @addMaterialQueueEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add content on the left to start'**
  String get addMaterialQueueEmptyHint;

  /// No description provided for @addMaterialRunningInBg.
  ///
  /// In en, this message translates to:
  /// **'Running in background. Safe to leave.'**
  String get addMaterialRunningInBg;

  /// No description provided for @addMaterialClearDone.
  ///
  /// In en, this message translates to:
  /// **'Clear completed'**
  String get addMaterialClearDone;

  /// No description provided for @addMaterialLeaveTemporary.
  ///
  /// In en, this message translates to:
  /// **'Leave (continues in background)'**
  String get addMaterialLeaveTemporary;

  /// No description provided for @addMaterialAllDone.
  ///
  /// In en, this message translates to:
  /// **'All done'**
  String get addMaterialAllDone;

  /// No description provided for @addMaterialStartBatch.
  ///
  /// In en, this message translates to:
  /// **'Start batch'**
  String get addMaterialStartBatch;

  /// No description provided for @addMaterialPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Paste article, notes or web text here...\n\nExample:\n# What is Flutter\nFlutter is...\n\n# Features\n1. Cross-platform\n2. High performance...'**
  String get addMaterialPasteHint;

  /// No description provided for @addMaterialDirectTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips for direct import:'**
  String get addMaterialDirectTipTitle;

  /// No description provided for @addMaterialDirectTipBody.
  ///
  /// In en, this message translates to:
  /// **'Use Markdown headings (e.g. '**
  String get addMaterialDirectTipBody;

  /// No description provided for @addMaterialDirectTipBody2.
  ///
  /// In en, this message translates to:
  /// **'# Title'**
  String get addMaterialDirectTipBody2;

  /// No description provided for @addMaterialDirectTipBody3.
  ///
  /// In en, this message translates to:
  /// **') to split cards without AI. If no heading, first sentence is used as title.'**
  String get addMaterialDirectTipBody3;

  /// No description provided for @addMaterialDirectImport.
  ///
  /// In en, this message translates to:
  /// **'Direct import'**
  String get addMaterialDirectImport;

  /// No description provided for @addMaterialAddedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to queue'**
  String get addMaterialAddedToQueue;

  /// No description provided for @addMaterialDirectQueue.
  ///
  /// In en, this message translates to:
  /// **'Direct queue'**
  String get addMaterialDirectQueue;

  /// No description provided for @addMaterialAddedToAiQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to AI queue'**
  String get addMaterialAddedToAiQueue;

  /// No description provided for @addMaterialAiQueue.
  ///
  /// In en, this message translates to:
  /// **'AI queue'**
  String get addMaterialAiQueue;

  /// No description provided for @addMaterialAiParsing.
  ///
  /// In en, this message translates to:
  /// **'AI parsing...'**
  String get addMaterialAiParsing;

  /// No description provided for @addMaterialAiDeconstruct.
  ///
  /// In en, this message translates to:
  /// **'AI smart deconstruct'**
  String get addMaterialAiDeconstruct;

  /// No description provided for @addMaterialGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get addMaterialGenerating;

  /// No description provided for @addMaterialGeneratedCount.
  ///
  /// In en, this message translates to:
  /// **'Generated \$count items'**
  String addMaterialGeneratedCount(int count);

  /// No description provided for @addMaterialLeaveForNow.
  ///
  /// In en, this message translates to:
  /// **'Leave for now'**
  String get addMaterialLeaveForNow;

  /// No description provided for @addMaterialReedit.
  ///
  /// In en, this message translates to:
  /// **'Re-edit'**
  String get addMaterialReedit;

  /// No description provided for @addMaterialConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to AI...'**
  String get addMaterialConnecting;

  /// No description provided for @addMaterialAiReading.
  ///
  /// In en, this message translates to:
  /// **'AI is reading your content.\nFirst card usually takes 5-10 seconds...'**
  String get addMaterialAiReading;

  /// No description provided for @addMaterialNextCard.
  ///
  /// In en, this message translates to:
  /// **'Generating next card...'**
  String get addMaterialNextCard;

  /// No description provided for @addMaterialQuestion.
  ///
  /// In en, this message translates to:
  /// **'Q: '**
  String get addMaterialQuestion;

  /// No description provided for @addMaterialNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get addMaterialNone;

  /// No description provided for @addMaterialBackToEdit.
  ///
  /// In en, this message translates to:
  /// **'Back to edit'**
  String get addMaterialBackToEdit;

  /// No description provided for @addMaterialConfirmSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & save'**
  String get addMaterialConfirmSave;

  /// No description provided for @addMaterialPickedFile.
  ///
  /// In en, this message translates to:
  /// **'Selected (tap to change)'**
  String get addMaterialPickedFile;

  /// No description provided for @addMaterialFileHint.
  ///
  /// In en, this message translates to:
  /// **'PDF, Word, Markdown supported'**
  String get addMaterialFileHint;

  /// No description provided for @addMaterialUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Most web pages, YouTube, etc.'**
  String get addMaterialUrlHint;

  /// No description provided for @addMaterialCharsCount.
  ///
  /// In en, this message translates to:
  /// **'\$count chars · est. \$time'**
  String addMaterialCharsCount(int count, String time);

  /// No description provided for @addMaterialFileInQueue.
  ///
  /// In en, this message translates to:
  /// **'File added to queue'**
  String get addMaterialFileInQueue;

  /// No description provided for @addMaterialLinkInQueue.
  ///
  /// In en, this message translates to:
  /// **'Link added to queue'**
  String get addMaterialLinkInQueue;

  /// No description provided for @addMaterialJoinQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addMaterialJoinQueue;

  /// No description provided for @addMaterialParse.
  ///
  /// In en, this message translates to:
  /// **'Parse'**
  String get addMaterialParse;

  /// No description provided for @addMaterialStartDeconstruct.
  ///
  /// In en, this message translates to:
  /// **'Start smart deconstruct (\$credits credits)'**
  String addMaterialStartDeconstruct(int credits);

  /// No description provided for @addMaterialWaitParse.
  ///
  /// In en, this message translates to:
  /// **'Waiting for parse...'**
  String get addMaterialWaitParse;

  /// No description provided for @addMaterialDirectSave.
  ///
  /// In en, this message translates to:
  /// **'Save directly (no deconstruct)'**
  String get addMaterialDirectSave;

  /// No description provided for @addMaterialComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get addMaterialComingSoon;

  /// No description provided for @addMaterialQueueBusy.
  ///
  /// In en, this message translates to:
  /// **'Queue has pending tasks. Clear the queue or use batch mode.'**
  String get addMaterialQueueBusy;

  /// No description provided for @addMaterialConfirmBatch.
  ///
  /// In en, this message translates to:
  /// **'Confirm batch'**
  String get addMaterialConfirmBatch;

  /// No description provided for @addMaterialConfirmBatchDirectOnly.
  ///
  /// In en, this message translates to:
  /// **'Only direct-import items in queue. No credits. Start?'**
  String get addMaterialConfirmBatchDirectOnly;

  /// No description provided for @addMaterialStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get addMaterialStart;

  /// No description provided for @addMaterialCreditsDeduct.
  ///
  /// In en, this message translates to:
  /// **'This will use \$credits credits'**
  String addMaterialCreditsDeduct(int credits);

  /// No description provided for @addMaterialCreditsSummaryAi.
  ///
  /// In en, this message translates to:
  /// **'\$aiCount items, charged by length (~10-40/item)'**
  String addMaterialCreditsSummaryAi(int aiCount);

  /// No description provided for @addMaterialCreditsSummaryMixed.
  ///
  /// In en, this message translates to:
  /// **'\$extractedCredits for parsed; \$rest items by length (10-40/item)'**
  String addMaterialCreditsSummaryMixed(int extractedCredits, int rest);

  /// No description provided for @addMaterialConfirmDeconstruct.
  ///
  /// In en, this message translates to:
  /// **'Confirm smart deconstruct?'**
  String get addMaterialConfirmDeconstruct;

  /// No description provided for @addMaterialConfirmBatchFull.
  ///
  /// In en, this message translates to:
  /// **'\$total items (\$aiCount AI deconstruct).'**
  String addMaterialConfirmBatchFull(int total, int aiCount);

  /// No description provided for @addMaterialCreditsTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Charged by length (~10-40/item), same as single deconstruct.'**
  String get addMaterialCreditsTip;

  /// No description provided for @addMaterialStartGenerate.
  ///
  /// In en, this message translates to:
  /// **'Start generation'**
  String get addMaterialStartGenerate;

  /// No description provided for @addMaterialConfirmSingle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deconstruct?'**
  String get addMaterialConfirmSingle;

  /// No description provided for @addMaterialCharsRecognized.
  ///
  /// In en, this message translates to:
  /// **'Content recognized: ~\$count chars'**
  String addMaterialCharsRecognized(int count);

  /// No description provided for @addMaterialEstTime.
  ///
  /// In en, this message translates to:
  /// **'Est. time: \$time'**
  String addMaterialEstTime(String time);

  /// No description provided for @addMaterialDeductLabel.
  ///
  /// In en, this message translates to:
  /// **'Credits to use:'**
  String get addMaterialDeductLabel;

  /// No description provided for @addMaterialCreditsUnit.
  ///
  /// In en, this message translates to:
  /// **' credits'**
  String get addMaterialCreditsUnit;

  /// No description provided for @addMaterialFreeParseTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Parsing is free. Smart deconstruct uses credits by content depth.'**
  String get addMaterialFreeParseTip;

  /// No description provided for @addMaterialReadoFree.
  ///
  /// In en, this message translates to:
  /// **'Reado: AI chat & file parsing are free'**
  String get addMaterialReadoFree;

  /// No description provided for @addMaterialInsufficientCredits.
  ///
  /// In en, this message translates to:
  /// **'Insufficient credits'**
  String get addMaterialInsufficientCredits;

  /// No description provided for @addMaterialInsufficientMessage.
  ///
  /// In en, this message translates to:
  /// **'AI parse or generate needs 10 credits. Share a knowledge base to earn more!'**
  String get addMaterialInsufficientMessage;

  /// No description provided for @addMaterialLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get addMaterialLearnMore;

  /// No description provided for @addMaterialGoShare.
  ///
  /// In en, this message translates to:
  /// **'Share to earn'**
  String get addMaterialGoShare;

  /// No description provided for @addMaterialStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'AI deconstruct style'**
  String get addMaterialStyleTitle;

  /// No description provided for @addMaterialModeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get addMaterialModeStandard;

  /// No description provided for @addMaterialModeStandardDesc.
  ///
  /// In en, this message translates to:
  /// **'Rigorous & complete'**
  String get addMaterialModeStandardDesc;

  /// No description provided for @addMaterialModeGrandma.
  ///
  /// In en, this message translates to:
  /// **'Grandma'**
  String get addMaterialModeGrandma;

  /// No description provided for @addMaterialModeGrandmaDesc.
  ///
  /// In en, this message translates to:
  /// **'Super simple'**
  String get addMaterialModeGrandmaDesc;

  /// No description provided for @addMaterialModePhd.
  ///
  /// In en, this message translates to:
  /// **'PhD'**
  String get addMaterialModePhd;

  /// No description provided for @addMaterialModePhdDesc.
  ///
  /// In en, this message translates to:
  /// **'Plain language'**
  String get addMaterialModePhdDesc;

  /// No description provided for @addMaterialModePodcast.
  ///
  /// In en, this message translates to:
  /// **'Podcast'**
  String get addMaterialModePodcast;

  /// No description provided for @addMaterialModePodcastDesc.
  ///
  /// In en, this message translates to:
  /// **'Two-person dialogue'**
  String get addMaterialModePodcastDesc;

  /// No description provided for @studyTitleAll.
  ///
  /// In en, this message translates to:
  /// **'All knowledge'**
  String get studyTitleAll;

  /// No description provided for @studyTitleAiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI notes'**
  String get studyTitleAiNotes;

  /// No description provided for @studyTitleSearch.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get studyTitleSearch;

  /// No description provided for @studyTitleModule.
  ///
  /// In en, this message translates to:
  /// **'Knowledge module'**
  String get studyTitleModule;

  /// No description provided for @studySingleColumn.
  ///
  /// In en, this message translates to:
  /// **'Single column'**
  String get studySingleColumn;

  /// No description provided for @studyMinutes.
  ///
  /// In en, this message translates to:
  /// **'\$n min'**
  String studyMinutes(int n);

  /// No description provided for @studyAllButton.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get studyAllButton;

  /// No description provided for @studyBodySaved.
  ///
  /// In en, this message translates to:
  /// **'Content saved'**
  String get studyBodySaved;

  /// No description provided for @studySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get studySaveFailed;

  /// No description provided for @studyAllTutorialHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"All\" to view all cards or switch between cards.'**
  String get studyAllTutorialHint;

  /// No description provided for @studyNextSection.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get studyNextSection;

  /// No description provided for @studyEditBody.
  ///
  /// In en, this message translates to:
  /// **'Edit content'**
  String get studyEditBody;

  /// No description provided for @studyViewing.
  ///
  /// In en, this message translates to:
  /// **'Viewing'**
  String get studyViewing;

  /// No description provided for @studyDeleteCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this card?'**
  String get studyDeleteCardTitle;

  /// No description provided for @studyDeleteCardContent.
  ///
  /// In en, this message translates to:
  /// **'Cannot be recovered. Delete anyway?'**
  String get studyDeleteCardContent;

  /// No description provided for @moduleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get moduleLoadFailed;

  /// No description provided for @moduleGoLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to login'**
  String get moduleGoLogin;

  /// No description provided for @moduleSharedLibrary.
  ///
  /// In en, this message translates to:
  /// **'Shared knowledge base'**
  String get moduleSharedLibrary;

  /// No description provided for @moduleCardCount.
  ///
  /// In en, this message translates to:
  /// **'\$count cards'**
  String moduleCardCount(int count);

  /// No description provided for @moduleSaveToMyLibrary.
  ///
  /// In en, this message translates to:
  /// **'Save to my library'**
  String get moduleSaveToMyLibrary;

  /// No description provided for @moduleStartReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get moduleStartReading;

  /// No description provided for @moduleSavingToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saving to your library…'**
  String get moduleSavingToLibrary;

  /// No description provided for @moduleAddedGoHome.
  ///
  /// In en, this message translates to:
  /// **'Added. Go to Home to start learning.'**
  String get moduleAddedGoHome;

  /// No description provided for @moduleSavedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Saved to your library'**
  String get moduleSavedToLibrary;

  /// No description provided for @moduleViews.
  ///
  /// In en, this message translates to:
  /// **'\$n views'**
  String moduleViews(int n);

  /// No description provided for @moduleSaves.
  ///
  /// In en, this message translates to:
  /// **'\$n saves'**
  String moduleSaves(int n);

  /// No description provided for @moduleLikes.
  ///
  /// In en, this message translates to:
  /// **'\$n likes'**
  String moduleLikes(int n);

  /// No description provided for @moduleThanksLike.
  ///
  /// In en, this message translates to:
  /// **'Thanks for the like!'**
  String get moduleThanksLike;

  /// No description provided for @moduleAlreadyLiked.
  ///
  /// In en, this message translates to:
  /// **'You already liked this'**
  String get moduleAlreadyLiked;

  /// No description provided for @moduleShareData.
  ///
  /// In en, this message translates to:
  /// **'Share: \$views views · \$saves saves · \$likes likes'**
  String moduleShareData(int views, int saves, int likes);

  /// No description provided for @moduleAllKnowledge.
  ///
  /// In en, this message translates to:
  /// **'All knowledge'**
  String get moduleAllKnowledge;

  /// No description provided for @moduleAllKnowledgeDesc.
  ///
  /// In en, this message translates to:
  /// **'All your knowledge cards are here'**
  String get moduleAllKnowledgeDesc;

  /// No description provided for @moduleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown library'**
  String get moduleUnknown;

  /// No description provided for @moduleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Library not found'**
  String get moduleNotFound;

  /// No description provided for @moduleShareLibrary.
  ///
  /// In en, this message translates to:
  /// **'Share library'**
  String get moduleShareLibrary;

  /// No description provided for @moduleShareWithNotes.
  ///
  /// In en, this message translates to:
  /// **'Share notes with viewers?'**
  String get moduleShareWithNotes;

  /// No description provided for @moduleShareLibraryOnly.
  ///
  /// In en, this message translates to:
  /// **'Share library only'**
  String get moduleShareLibraryOnly;

  /// No description provided for @moduleShareLibraryAndNotes.
  ///
  /// In en, this message translates to:
  /// **'Share library & notes'**
  String get moduleShareLibraryAndNotes;

  /// No description provided for @moduleRenameLibrary.
  ///
  /// In en, this message translates to:
  /// **'Rename library'**
  String get moduleRenameLibrary;

  /// No description provided for @moduleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get moduleNameLabel;

  /// No description provided for @moduleNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter library name'**
  String get moduleNameHint;

  /// No description provided for @moduleUpdatedName.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get moduleUpdatedName;

  /// No description provided for @moduleUpdatedDetails.
  ///
  /// In en, this message translates to:
  /// **'Details updated'**
  String get moduleUpdatedDetails;

  /// No description provided for @moduleEditDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get moduleEditDetails;

  /// No description provided for @moduleDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get moduleDescLabel;

  /// No description provided for @moduleHideLibrary.
  ///
  /// In en, this message translates to:
  /// **'Hide this library?'**
  String get moduleHideLibrary;

  /// No description provided for @moduleDeleteLibrary.
  ///
  /// In en, this message translates to:
  /// **'Delete this library?'**
  String get moduleDeleteLibrary;

  /// No description provided for @moduleHideLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'It will be hidden. You can restore it in Profile → Hidden content.'**
  String get moduleHideLibraryDesc;

  /// No description provided for @moduleDeleteLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. All cards will be removed.'**
  String get moduleDeleteLibraryDesc;

  /// No description provided for @moduleHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get moduleHide;

  /// No description provided for @moduleDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get moduleDelete;

  /// No description provided for @moduleLibraryHidden.
  ///
  /// In en, this message translates to:
  /// **'Library hidden'**
  String get moduleLibraryHidden;

  /// No description provided for @moduleLibraryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Library deleted'**
  String get moduleLibraryDeleted;

  /// No description provided for @moduleRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get moduleRename;

  /// No description provided for @modulePermanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanent delete'**
  String get modulePermanentDelete;

  /// No description provided for @moduleCardsTag.
  ///
  /// In en, this message translates to:
  /// **'\$count cards'**
  String moduleCardsTag(int count);

  /// No description provided for @moduleOfficial.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get moduleOfficial;

  /// No description provided for @modulePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get modulePrivate;

  /// No description provided for @moduleMasteredPct.
  ///
  /// In en, this message translates to:
  /// **'\$pct% mastered'**
  String moduleMasteredPct(int pct);

  /// No description provided for @moduleStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get moduleStartLearning;

  /// No description provided for @moduleMovePrompt.
  ///
  /// In en, this message translates to:
  /// **'Create another library first to move cards.'**
  String get moduleMovePrompt;

  /// No description provided for @moduleMoveToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Move to library'**
  String get moduleMoveToLibrary;

  /// No description provided for @moduleMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved to target library'**
  String get moduleMoved;

  /// No description provided for @moduleHideCard.
  ///
  /// In en, this message translates to:
  /// **'Hide this card?'**
  String get moduleHideCard;

  /// No description provided for @moduleDeleteCard.
  ///
  /// In en, this message translates to:
  /// **'Delete this card?'**
  String get moduleDeleteCard;

  /// No description provided for @moduleHideCardDesc.
  ///
  /// In en, this message translates to:
  /// **'You can restore it in settings.'**
  String get moduleHideCardDesc;

  /// No description provided for @moduleDeleteCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Cannot be recovered.'**
  String get moduleDeleteCardDesc;

  /// No description provided for @moduleCardHidden.
  ///
  /// In en, this message translates to:
  /// **'Card hidden'**
  String get moduleCardHidden;

  /// No description provided for @moduleCardRemoved.
  ///
  /// In en, this message translates to:
  /// **'Card removed'**
  String get moduleCardRemoved;

  /// No description provided for @moduleMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get moduleMove;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogConfirm;

  /// No description provided for @aiHoarderTitle.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get aiHoarderTitle;

  /// No description provided for @aiHoarderHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the assistant…'**
  String get aiHoarderHint;

  /// No description provided for @notePinnedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Note pinned!'**
  String get notePinnedSuccess;

  /// No description provided for @noteShareNoSave.
  ///
  /// In en, this message translates to:
  /// **'Cannot save note to this card from shared content'**
  String get noteShareNoSave;

  /// No description provided for @noteLoginToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save notes'**
  String get noteLoginToSave;

  /// No description provided for @noteLoginToSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save notes to your library.'**
  String get noteLoginToSaveDesc;

  /// No description provided for @noteDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get noteDeleteConfirm;

  /// No description provided for @noteDeleteConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This pinned note will be removed.'**
  String get noteDeleteConfirmDesc;

  /// No description provided for @noteEditNote.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteEditNote;

  /// No description provided for @noteContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Note content'**
  String get noteContentLabel;

  /// No description provided for @noteAiGuide.
  ///
  /// In en, this message translates to:
  /// **'Official guide'**
  String get noteAiGuide;

  /// No description provided for @noteAiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI notes'**
  String get noteAiNotes;

  /// No description provided for @noteTooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get noteTooltipEdit;

  /// No description provided for @noteTooltipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get noteTooltipDelete;

  /// No description provided for @aiNotesPageTitle.
  ///
  /// In en, this message translates to:
  /// **'AI notes'**
  String get aiNotesPageTitle;

  /// No description provided for @aiNotesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes…'**
  String get aiNotesSearchHint;

  /// No description provided for @aiNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No AI notes yet'**
  String get aiNotesEmpty;

  /// No description provided for @aiNotesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add note\" while learning and AI will summarize key points.'**
  String get aiNotesEmptyHint;

  /// No description provided for @noteReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Note review \$current/\$total'**
  String noteReviewTitle(int current, int total);

  /// No description provided for @vaultFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get vaultFilterAll;

  /// No description provided for @vaultFilterNewbie.
  ///
  /// In en, this message translates to:
  /// **'Newbie'**
  String get vaultFilterNewbie;

  /// No description provided for @vaultFilterMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get vaultFilterMedium;

  /// No description provided for @vaultFilterExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get vaultFilterExpert;

  /// No description provided for @vaultFilterNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get vaultFilterNew;

  /// No description provided for @aiNotesNoteCount.
  ///
  /// In en, this message translates to:
  /// **'\$count notes'**
  String aiNotesNoteCount(int count);

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @collectLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save'**
  String get collectLoginTitle;

  /// No description provided for @collectLoginContent.
  ///
  /// In en, this message translates to:
  /// **'Go to sign in?'**
  String get collectLoginContent;

  /// No description provided for @shareNoCollect.
  ///
  /// In en, this message translates to:
  /// **'Cannot save to vault from shared content'**
  String get shareNoCollect;

  /// No description provided for @favoritedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Saved to vault'**
  String get favoritedSnackbar;

  /// No description provided for @unfavoritedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Removed from vault'**
  String get unfavoritedSnackbar;

  /// No description provided for @markedAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Marked as \$label'**
  String markedAsLabel(String label);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @vaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vaultTitle;

  /// No description provided for @vaultSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search saved cards…'**
  String get vaultSearchHint;

  /// No description provided for @vaultEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved cards yet'**
  String get vaultEmpty;

  /// No description provided for @vaultEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap ❤️ in Study to save content'**
  String get vaultEmptyHint;

  /// No description provided for @noteReviewReleasePrev.
  ///
  /// In en, this message translates to:
  /// **'Release to switch to previous'**
  String get noteReviewReleasePrev;

  /// No description provided for @noteReviewPullPrev.
  ///
  /// In en, this message translates to:
  /// **'Pull down to continue'**
  String get noteReviewPullPrev;

  /// No description provided for @noteReviewReleaseNext.
  ///
  /// In en, this message translates to:
  /// **'Release to switch to next'**
  String get noteReviewReleaseNext;

  /// No description provided for @noteReviewPullNext.
  ///
  /// In en, this message translates to:
  /// **'Pull up to continue'**
  String get noteReviewPullNext;

  /// No description provided for @moduleShareCopyBody.
  ///
  /// In en, this message translates to:
  /// **'Hey! I\'m learning this library with Reado. Check it out:\n\$url\n\nThis is my library \"\$title\". You can save it to yours.'**
  String moduleShareCopyBody(String url, String title);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
