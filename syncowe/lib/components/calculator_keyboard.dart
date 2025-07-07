import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The main Calculator Keyboard Widget
import 'package:math_expressions/math_expressions.dart';
import 'package:syncowe/services/calculator_keyboard_visibility_service.dart';

class CalculatorKeyboardWidget extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final Function(String)? onCalculationResult;
  final InputDecoration? decoration;
  final TextStyle? textStyle;
  final int? decimalPrecision;
  final double keyboardHeight;

  const CalculatorKeyboardWidget(
      {super.key,
      this.controller,
      this.onCalculationResult,
      this.decoration,
      this.textStyle,
      this.keyboardHeight = 300,
      this.decimalPrecision});

  @override
  ConsumerState<CalculatorKeyboardWidget> createState() =>
      _CalculatorKeyboardWidgetState();
}

class _CalculatorKeyboardWidgetState
    extends ConsumerState<CalculatorKeyboardWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    // Set text to empty if initial value is zero, after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_isEffectivelyZero(_controller.text)) {
          _controller.text = "";
        } else {
          final result = _evaluateExpression(_controller.text);
          if (widget.decimalPrecision != null) {
            _controller.text = result.toStringAsFixed(widget.decimalPrecision!);
          } else {
            _controller.text = result.toString(); // Default double to string
          }
        }
      }
    });
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CalculatorKeyboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
      // Set text to empty if new controller's value is zero, after the frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isEffectivelyZero(_controller.text)) {
          _controller.text = "";
        }
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showKeyboard();
    } else {
      _hideKeyboard();
    }
  }

  void _showKeyboard() {
    if (_overlayEntry != null) {
      return;
    }

    // Capture the theme at the time of showing the keyboard
    // and notify the visibility service.
    ref
        .read(calculatorKeyboardVisibilityProvider.notifier)
        .showKeyboard(widget.keyboardHeight);
    final capturedTheme = Theme.of(context);

    _overlayEntry = _createOverlayEntry(capturedTheme);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideKeyboard() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      ref.read(calculatorKeyboardVisibilityProvider.notifier).hideKeyboard();
    }
  }

  OverlayEntry _createOverlayEntry(ThemeData theme) {
    return OverlayEntry(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final keyboardHeight = widget.keyboardHeight;
        // Get bottom system padding (for home bar, gesture navigation, etc.)
        final systemBottomPadding = MediaQuery.of(context).padding.bottom;

        // Use Theme to apply the captured theme to the overlay
        return Theme(
          data: theme,
          child: Positioned(
            width: screenSize.width,
            // Adjust bottom position to account for system padding and add some extra space
            bottom: systemBottomPadding + keyboardOverlayInternalBottomOffset,
            child: Material(
              elevation: 8.0,
              color: theme.colorScheme.surface,
              child: StatefulBuilder(builder: (context, setState) {
                return SizedBox(
                  height: keyboardHeight,
                  child: CalculatorKeyboard(
                    onKeyPressed: _addToExpression,
                    onDelete: _deleteLastCharacter,
                    onClear: _clearExpression,
                    onEquals: _calculate,
                    onDone: () {
                      _calculate();
                      _focusNode.unfocus();
                    },
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  bool _isEffectivelyZero(String text) {
    if (text.isEmpty) return false; // Already effectively showing placeholder
    try {
      final val = double.tryParse(text);
      return val != null && val == 0.0;
    } catch (e) {
      return false;
    }
  }

  void _addToExpression(String value) {
    final String currentText = _controller.text;
    final TextSelection currentSelection = _controller.selection;

    if (currentText.isEmpty) {
      // If current text is empty (was zero), handle special cases
      String newTextValue;
      if (RegExp(r'[0-9]').hasMatch(value)) {
        newTextValue = value; // Digit replaces the conceptual "0"
      } else if (value == '.') {
        newTextValue = "0."; // Decimal point implies "0."
      } else if (value == '-') {
        newTextValue = "-"; // Allow starting with a negative sign
      } else if (['+', '×', '÷', '^'].contains(value)) {
        newTextValue = "0$value"; // Other operators prepend "0"
      } else {
        // For '(', ')', and any other characters, just insert
        newTextValue = value;
      }
      _controller.text = newTextValue;
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    } else {
      // Standard insertion logic for non-empty text
      final int insertPosition = currentSelection.baseOffset >= 0
          ? currentSelection.baseOffset
          : currentText.length;
      final textBefore = currentText.substring(0, insertPosition);
      final textAfter = currentText.substring(insertPosition);

      _controller.text = textBefore + value + textAfter;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: insertPosition + value.length),
      );
    }
  }

  void _deleteLastCharacter() {
    if (_controller.text.isNotEmpty) {
      final int currentPosition = _controller.selection.baseOffset >= 0
          ? _controller.selection.baseOffset
          : _controller.text.length;
      if (currentPosition > 0) {
        final textBefore = _controller.text.substring(0, currentPosition - 1);
        final textAfter = _controller.text.substring(currentPosition);
        final newText = textBefore + textAfter;

        if (_isEffectivelyZero(newText)) {
          _controller.text = "";
          _controller.selection = const TextSelection.collapsed(offset: 0);
        } else {
          _controller.text = newText;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: currentPosition - 1),
          );
        }
      }
    }
  }

  void _clearExpression() {
    _controller.clear();
    _controller.selection = const TextSelection.collapsed(offset: 0);
  }

  void _calculate() {
    try {
      String expressionText = _controller.text;
      expressionText = expressionText
          .replaceAll('×', '*')
          .replaceAll('÷', '/'); // Replace display operators with standard ones

      final result = _evaluateExpression(expressionText);

      String resultStringForDisplay;
      String resultStringForCallback;

      // Determine the string representation for the callback (actual numeric value)
      if (widget.decimalPrecision != null) {
        resultStringForCallback =
            result.toStringAsFixed(widget.decimalPrecision!);
      } else {
        resultStringForCallback = result.toString(); // Default double to string
      }

      // Determine the string for display (empty if zero)
      if (result == 0.0) {
        resultStringForDisplay = "";
      } else {
        // For non-zero, display is same as callback (formatted)
        resultStringForDisplay = resultStringForCallback;
      }

      _controller.text = resultStringForDisplay;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );

      if (widget.onCalculationResult != null) {
        widget.onCalculationResult!(resultStringForCallback);
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid expression')),
      );
    }
  }

  // Enhanced expression evaluator with parentheses support
  double _evaluateExpression(String expressionText) {
    if (expressionText.isEmpty) {
      return 0.0; // Treat empty string (from zero display) as 0
    }
    try {
      // Create a parser
      ShuntingYardParser p = ShuntingYardParser();

      // Parse the expression
      Expression exp = p.parse(expressionText);

      // Evaluate the expression
      ContextModel cm = ContextModel();
      double result = exp.evaluate(EvaluationType.REAL, cm);

      return result;
    } catch (e) {
      // Rethrow the exception to be caught in _calculate
      rethrow;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    _hideKeyboard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration =
        widget.decoration ?? InputDecoration(hintText: "0.00");
    if (decoration.hintText?.isEmpty ?? true) {
      decoration = decoration.copyWith(hintText: "0.00");
    }
    if (decoration.floatingLabelBehavior == null) {
      decoration = decoration.copyWith(
          floatingLabelBehavior: FloatingLabelBehavior.always);
    }
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: decoration,
        style: widget.textStyle ?? Theme.of(context).textTheme.titleLarge,
        showCursor: true,
        readOnly: true, // Prevents system keyboard from showing
      ),
    );
  }
}

class CalculatorKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onDelete;
  final VoidCallback onClear;
  final VoidCallback onEquals;
  final VoidCallback onDone;

  const CalculatorKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onDelete,
    required this.onClear,
    required this.onEquals,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Header with done button and function toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          height: 40,
          color: colorScheme.surfaceVariant,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDone,
                child:
                    Text('Done', style: TextStyle(color: colorScheme.primary)),
              ),
            ],
          ),
        ),
        Expanded(child: buildKeyRow(['7', '8', '9', '÷'], context)),
        Expanded(child: buildKeyRow(['4', '5', '6', '×'], context)),
        Expanded(child: buildKeyRow(['1', '2', '3', '-'], context)),
        Expanded(child: buildKeyRow(['0', '.', '+', '='], context)),
        Expanded(child: buildFunctionRow(context)),
      ],
    );
  }

  Widget buildKeyRow(List<String> keys, BuildContext context) {
    return Row(
      children: keys.map((key) {
        bool isOperator = ['+', '-', '×', '÷', '=', '^'].contains(key);
        bool isFunction = ['C', '⌫', '(', ')'].contains(key);

        return Expanded(
          child: CalculatorKey(
            label: key,
            onPressed: () {
              if (key == '=') {
                onEquals();
              } else if (key == 'C') {
                onClear();
              } else if (key == '⌫') {
                onDelete();
              } else {
                onKeyPressed(key);
              }
            },
            isOperator: isOperator,
            isFunction: isFunction,
          ),
        );
      }).toList(),
    );
  }

  Widget buildFunctionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CalculatorKey(
            label: '(',
            onPressed: () => onKeyPressed('('),
            isFunction: true,
          ),
        ),
        Expanded(
          child: CalculatorKey(
            label: ')',
            onPressed: () => onKeyPressed(')'),
            isFunction: true,
          ),
        ),
        Expanded(
          child: CalculatorKey(
            label: 'C',
            onPressed: onClear,
            isFunction: true,
          ),
        ),
        Expanded(
          child: CalculatorKey(
            label: '⌫',
            onPressed: onDelete,
            isFunction: true,
          ),
        ),
      ],
    );
  }
}

class CalculatorKey extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOperator;
  final bool isFunction;

  const CalculatorKey({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isOperator = false,
    this.isFunction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get theme colors to style the keys
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color textColor;

    if (isOperator) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else if (isFunction) {
      backgroundColor = colorScheme.secondary;
      textColor = colorScheme.onSecondary;
    } else {
      backgroundColor = colorScheme.surface;
      textColor = colorScheme.onSurface;
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      child: Material(
        color: backgroundColor,
        elevation: 2.0,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8.0),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
