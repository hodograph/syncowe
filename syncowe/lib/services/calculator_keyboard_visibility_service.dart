import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// The additional padding between the bottom of the calculator keyboard
/// and the system navigation bar (or absolute bottom of the screen if no system bar).
const double keyboardOverlayInternalBottomOffset = 8.0;

final calculatorKeyboardVisibilityProvider = StateNotifierProvider<
    CalculatorKeyboardVisibilityNotifier,
    CalculatorKeyboardVisibilityState>((ref) {
  return CalculatorKeyboardVisibilityNotifier();
});

@immutable
class CalculatorKeyboardVisibilityState {
  final bool isKeyboardVisible;
  final double keyboardHeight;

  const CalculatorKeyboardVisibilityState({
    this.isKeyboardVisible = false,
    this.keyboardHeight = 0.0,
  });

  /// Calculates the total bottom inset needed by a view
  /// when the calculator keyboard is visible.
  /// This includes the keyboard's height and its internal bottom offset.
  double get bottomInset {
    if (!isKeyboardVisible) return 0.0;
    // This is the height of the keyboard itself plus the extra padding
    // CalculatorKeyboardWidget adds between itself and the system navigation bar.
    return keyboardHeight + keyboardOverlayInternalBottomOffset;
  }

  CalculatorKeyboardVisibilityState copyWith({
    bool? isKeyboardVisible,
    double? keyboardHeight,
  }) {
    return CalculatorKeyboardVisibilityState(
      isKeyboardVisible: isKeyboardVisible ?? this.isKeyboardVisible,
      keyboardHeight: keyboardHeight ?? this.keyboardHeight,
    );
  }
}

class CalculatorKeyboardVisibilityNotifier
    extends StateNotifier<CalculatorKeyboardVisibilityState> {
  CalculatorKeyboardVisibilityNotifier()
      : super(const CalculatorKeyboardVisibilityState());

  void showKeyboard(double height) {
    state = state.copyWith(isKeyboardVisible: true, keyboardHeight: height);
  }

  void hideKeyboard() {
    // We keep the last keyboardHeight even when hidden,
    // as it might be useful for quick transitions if needed,
    // but bottomInset will correctly return 0.
    state = state.copyWith(isKeyboardVisible: false);
  }
}
