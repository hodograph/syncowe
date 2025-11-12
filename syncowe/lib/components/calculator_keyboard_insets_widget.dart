import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/services/calculator_keyboard_visibility_service.dart'; // Adjust path as needed

class CalculatorKeyboardInsetsWidget extends ConsumerWidget {
  final Widget child;

  const CalculatorKeyboardInsetsWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyboardState = ref.watch(calculatorKeyboardVisibilityProvider);
    final double bottomPaddingToApply = keyboardState.bottomInset;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPaddingToApply),
      child: child,
    );
  }
}
