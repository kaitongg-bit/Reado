import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingState {
  final bool hasSeenDeconstructionTutorial;
  final bool isAlwaysShowTutorial;
  final bool highlightTaskCenter;

  OnboardingState({
    required this.hasSeenDeconstructionTutorial,
    required this.isAlwaysShowTutorial,
    this.highlightTaskCenter = false,
  });

  OnboardingState copyWith({
    bool? hasSeenDeconstructionTutorial,
    bool? isAlwaysShowTutorial,
    bool? highlightTaskCenter,
  }) {
    return OnboardingState(
      hasSeenDeconstructionTutorial:
          hasSeenDeconstructionTutorial ?? this.hasSeenDeconstructionTutorial,
      isAlwaysShowTutorial: isAlwaysShowTutorial ?? this.isAlwaysShowTutorial,
      highlightTaskCenter: highlightTaskCenter ?? this.highlightTaskCenter,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier()
      : super(OnboardingState(
          hasSeenDeconstructionTutorial:
              true, // Default to true to avoid flicker
          isAlwaysShowTutorial: false,
          highlightTaskCenter: false,
        )) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenDeconstructionTutorial') ?? false;
    final alwaysShow = prefs.getBool('isAlwaysShowTutorial') ?? false;
    final highlight = prefs.getBool('highlightTaskCenter') ?? false;

    state = OnboardingState(
      hasSeenDeconstructionTutorial: hasSeen,
      isAlwaysShowTutorial: alwaysShow,
      highlightTaskCenter: highlight,
    );
  }

  Future<void> setHighlightTaskCenter(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highlightTaskCenter', value);
    state = state.copyWith(highlightTaskCenter: value);
  }

  Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenDeconstructionTutorial', true);
    state = state.copyWith(hasSeenDeconstructionTutorial: true);
  }

  Future<void> toggleAlwaysShowTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAlwaysShowTutorial', value);
    state = state.copyWith(isAlwaysShowTutorial: value);
  }

  Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('hasSeenDeconstructionTutorial');
    state = state.copyWith(hasSeenDeconstructionTutorial: false);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
