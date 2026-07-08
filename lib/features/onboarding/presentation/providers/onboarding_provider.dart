import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingTourState {
  final int step; // 0 = inactive, 1 = Dashboard, 2 = Tasks, 3 = Calendar, 4 = Notifications, 5 = Profile
  final bool hasSeen;

  OnboardingTourState({required this.step, required this.hasSeen});

  OnboardingTourState copyWith({int? step, bool? hasSeen}) {
    return OnboardingTourState(
      step: step ?? this.step,
      hasSeen: hasSeen ?? this.hasSeen,
    );
  }
}

class OnboardingTourNotifier extends StateNotifier<OnboardingTourState> {
  OnboardingTourNotifier() : super(OnboardingTourState(step: 0, hasSeen: true)) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenWalkthrough') ?? false;
    state = OnboardingTourState(step: hasSeen ? 0 : 1, hasSeen: hasSeen);
  }

  void startTour() {
    state = state.copyWith(step: 1);
  }

  void nextStep() {
    if (state.step < 5) {
      state = state.copyWith(step: state.step + 1);
    } else {
      finishTour();
    }
  }

  void prevStep() {
    if (state.step > 1) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  Future<void> finishTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenWalkthrough', true);
    state = OnboardingTourState(step: 0, hasSeen: true);
  }
}

final onboardingTourProvider =
    StateNotifierProvider<OnboardingTourNotifier, OnboardingTourState>((ref) {
  return OnboardingTourNotifier();
});
