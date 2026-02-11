import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final bool isTutorialActive;
  final bool hasSeenTextDeconstruction;
  final bool hasSeenTaskCenter;
  final bool hasSeenMultimodalDeconstruction;
  final bool hasSeenAllCardsPhase1;
  final bool hasSeenAllCardsPhase2;
  final bool isChecklistVisible;
  final bool isAlwaysShowTutorial;
  final bool highlightTaskCenter;

  OnboardingState({
    required this.isTutorialActive,
    required this.hasSeenTextDeconstruction,
    required this.hasSeenTaskCenter,
    required this.hasSeenMultimodalDeconstruction,
    required this.hasSeenAllCardsPhase1,
    required this.hasSeenAllCardsPhase2,
    required this.isChecklistVisible,
    required this.isAlwaysShowTutorial,
    this.highlightTaskCenter = false,
  });

  bool get isAllCompleted =>
      hasSeenTextDeconstruction &&
      hasSeenTaskCenter &&
      hasSeenMultimodalDeconstruction &&
      hasSeenAllCardsPhase2;

  bool get hasSeenAllCards => hasSeenAllCardsPhase2;

  int get completedStepsCount {
    int count = 0;
    if (hasSeenTextDeconstruction) count++;
    if (hasSeenTaskCenter) count++;
    if (hasSeenMultimodalDeconstruction) count++;
    if (hasSeenAllCardsPhase2) count++;
    return count;
  }

  OnboardingState copyWith({
    bool? isTutorialActive,
    bool? hasSeenTextDeconstruction,
    bool? hasSeenTaskCenter,
    bool? hasSeenMultimodalDeconstruction,
    bool? hasSeenAllCardsPhase1,
    bool? hasSeenAllCardsPhase2,
    bool? isChecklistVisible,
    bool? isAlwaysShowTutorial,
    bool? highlightTaskCenter,
  }) {
    return OnboardingState(
      isTutorialActive: isTutorialActive ?? this.isTutorialActive,
      hasSeenTextDeconstruction:
          hasSeenTextDeconstruction ?? this.hasSeenTextDeconstruction,
      hasSeenTaskCenter: hasSeenTaskCenter ?? this.hasSeenTaskCenter,
      hasSeenMultimodalDeconstruction: hasSeenMultimodalDeconstruction ??
          this.hasSeenMultimodalDeconstruction,
      hasSeenAllCardsPhase1:
          hasSeenAllCardsPhase1 ?? this.hasSeenAllCardsPhase1,
      hasSeenAllCardsPhase2:
          hasSeenAllCardsPhase2 ?? this.hasSeenAllCardsPhase2,
      isChecklistVisible: isChecklistVisible ?? this.isChecklistVisible,
      isAlwaysShowTutorial: isAlwaysShowTutorial ?? this.isAlwaysShowTutorial,
      highlightTaskCenter: highlightTaskCenter ?? this.highlightTaskCenter,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier()
      : super(OnboardingState(
          isTutorialActive: false,
          hasSeenTextDeconstruction: false,
          hasSeenTaskCenter: false,
          hasSeenMultimodalDeconstruction: false,
          hasSeenAllCardsPhase1: false,
          hasSeenAllCardsPhase2: false,
          isChecklistVisible: false,
          isAlwaysShowTutorial: false,
          highlightTaskCenter: false,
        )) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();

    // Default to active for new users if they haven't seen deconstruction tutorial yet
    final deconstructionOld =
        prefs.getBool('hasSeenDeconstructionTutorial') ?? false;

    final isTutorialActive =
        prefs.getBool('isTutorialActive') ?? !deconstructionOld;
    final hasSeenText = prefs.getBool('hasSeenTextDeconstruction') ?? false;
    final hasSeenTask = prefs.getBool('hasSeenTaskCenter') ?? false;
    final hasSeenMulti =
        prefs.getBool('hasSeenMultimodalDeconstruction') ?? false;
    final hasSeenAllP1 = prefs.getBool('hasSeenAllCardsPhase1') ?? false;
    final hasSeenAllP2 = prefs.getBool('hasSeenAllCardsPhase2') ?? false;
    final alwaysShow = prefs.getBool('isAlwaysShowTutorial') ?? false;
    final highlight = prefs.getBool('highlightTaskCenter') ?? false;

    state = OnboardingState(
      isTutorialActive: isTutorialActive,
      hasSeenTextDeconstruction: hasSeenText,
      hasSeenTaskCenter: hasSeenTask,
      hasSeenMultimodalDeconstruction: hasSeenMulti,
      hasSeenAllCardsPhase1: hasSeenAllP1,
      hasSeenAllCardsPhase2: hasSeenAllP2,
      isChecklistVisible: false,
      isAlwaysShowTutorial: alwaysShow,
      highlightTaskCenter: highlight,
    );
  }

  Future<void> completeStep(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    if (stepId == 'text') {
      await prefs.setBool('hasSeenTextDeconstruction', true);
      state = state.copyWith(hasSeenTextDeconstruction: true);
    } else if (stepId == 'task_center') {
      await prefs.setBool('hasSeenTaskCenter', true);
      state = state.copyWith(hasSeenTaskCenter: true);
    } else if (stepId == 'multimodal') {
      await prefs.setBool('hasSeenMultimodalDeconstruction', true);
      state = state.copyWith(hasSeenMultimodalDeconstruction: true);
    } else if (stepId == 'all_cards_p1') {
      await prefs.setBool('hasSeenAllCardsPhase1', true);
      state = state.copyWith(hasSeenAllCardsPhase1: true);
    } else if (stepId == 'all_cards_p2') {
      await prefs.setBool('hasSeenAllCardsPhase2', true);
      state = state.copyWith(hasSeenAllCardsPhase2: true);
    }

    if (state.isAllCompleted) {
      // Also mark legacy flag just in case
      await prefs.setBool('hasSeenDeconstructionTutorial', true);
    }
  }

  void setChecklistVisible(bool value) {
    state = state.copyWith(isChecklistVisible: value);
  }

  Future<void> setHighlightTaskCenter(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highlightTaskCenter', value);
    state = state.copyWith(highlightTaskCenter: value);
  }

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTutorialActive', false);
    await prefs.setBool('hasSeenTextDeconstruction', true);
    await prefs.setBool('hasSeenTaskCenter', true);
    await prefs.setBool('hasSeenMultimodalDeconstruction', true);
    await prefs.setBool('hasSeenAllCardsPhase1', true);
    await prefs.setBool('hasSeenAllCardsPhase2', true);
    await prefs.setBool('hasSeenDeconstructionTutorial', true);

    state = state.copyWith(
      isTutorialActive: false,
      hasSeenTextDeconstruction: true,
      hasSeenTaskCenter: true,
      hasSeenMultimodalDeconstruction: true,
      hasSeenAllCardsPhase1: true,
      hasSeenAllCardsPhase2: true,
    );
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isTutorialActive');
    await prefs.remove('hasSeenTextDeconstruction');
    await prefs.remove('hasSeenTaskCenter');
    await prefs.remove('hasSeenMultimodalDeconstruction');
    await prefs.remove('hasSeenAllCardsPhase1');
    await prefs.remove('hasSeenAllCardsPhase2');
    await prefs.remove('hasSeenDeconstructionTutorial');

    state = OnboardingState(
      isTutorialActive: true,
      hasSeenTextDeconstruction: false,
      hasSeenTaskCenter: false,
      hasSeenMultimodalDeconstruction: false,
      hasSeenAllCardsPhase1: false,
      hasSeenAllCardsPhase2: false,
      isChecklistVisible: false,
      isAlwaysShowTutorial: state.isAlwaysShowTutorial,
      highlightTaskCenter: false,
    );
  }

  Future<void> toggleAlwaysShowTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAlwaysShowTutorial', value);
    state = state.copyWith(isAlwaysShowTutorial: value);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
