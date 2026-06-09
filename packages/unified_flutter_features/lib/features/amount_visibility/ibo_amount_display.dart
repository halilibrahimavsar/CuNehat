import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'amount_visibility_cubit.dart';

/// Obfuscation styles for hiding sensitive content when visibility is disabled.
/// Sayıyı binlik ayraçlı biçimlendirir (varsayılan: Türkçe — binlik `.`,
/// ondalık `,`). `intl` bağımlılığı olmadan manuel gruplama yapar.
String formatGroupedAmount(
  double amount,
  int decimalDigits, {
  String thousandSeparator = '.',
  String decimalSeparator = ',',
}) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(decimalDigits);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    if (i != 0 && (intPart.length - i) % 3 == 0) buf.write(thousandSeparator);
    buf.write(intPart[i]);
  }
  var out = buf.toString();
  if (decimalDigits > 0 && parts.length > 1) {
    out = '$out$decimalSeparator${parts[1]}';
  }
  return negative ? '-$out' : out;
}

enum AmountObscureMode {
  /// Replaces content with [hiddenChild] widget.
  ///
  /// Use this when you want to show placeholder text or icons instead of the actual content.
  replace,

  /// Blurs the content but keeps its layout and size intact.
  ///
  /// The content remains recognizable in shape but unreadable. Good for visual continuity.
  blur,

  /// Hides the content completely with option to maintain size.
  ///
  /// When [maintainSizeWhenHidden] is true, the space is preserved but content is invisible.
  /// When false, the widget collapses to zero size.
  hide,
}

/// A general-purpose visibility-aware widget with optional obfuscation animations.
///
/// This widget wraps any child content and automatically handles visibility state
/// based on the [AmountVisibilityCubit]. It provides multiple obfuscation modes
/// with smooth animations and transitions.
///
/// Example usage:
/// ```dart
/// AmountVisibilityObfuscator(
///   obscureMode: AmountObscureMode.blur,
///   blurSigma: 8,
///   child: Text('Sensitive content'),
///   hiddenChild: Text('****'),
/// )
/// ```
class AmountVisibilityObfuscator extends StatelessWidget {
  /// The content to show when visibility is enabled.
  final Widget child;

  /// How to obfuscate the content when visibility is disabled.
  final AmountObscureMode obscureMode;

  /// Optional widget to show when using [AmountObscureMode.replace].
  final Widget? hiddenChild;

  /// Blur intensity for [AmountObscureMode.blur] mode.
  final double blurSigma;

  /// Whether to maintain widget size when using [AmountObscureMode.hide].
  final bool maintainSizeWhenHidden;

  /// Duration of the show/hide animation.
  final Duration animationDuration;

  /// Animation curve for transitions.
  final Curve animationCurve;

  /// Alignment of the content within the widget.
  final AlignmentGeometry alignment;

  const AmountVisibilityObfuscator({
    super.key,
    required this.child,
    this.obscureMode = AmountObscureMode.replace,
    this.hiddenChild,
    this.blurSigma = 6,
    this.maintainSizeWhenHidden = true,
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeOut,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AmountVisibilityCubit, bool>(
      builder: (context, isVisible) {
        final Widget current = isVisible ? _buildVisible() : _buildHidden();

        return AnimatedSwitcher(
          duration: animationDuration,
          switchInCurve: animationCurve,
          switchOutCurve: animationCurve,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                child: child,
              ),
            );
          },
          child: Align(
            key: ValueKey<bool>(isVisible),
            alignment: alignment,
            child: current,
          ),
        );
      },
    );
  }

  Widget _buildVisible() => child;

  Widget _buildHidden() {
    switch (obscureMode) {
      case AmountObscureMode.blur:
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: IgnorePointer(child: child),
        );
      case AmountObscureMode.hide:
        if (maintainSizeWhenHidden) {
          return Opacity(
            opacity: 0,
            child: IgnorePointer(child: child),
          );
        }
        return const SizedBox.shrink();
      case AmountObscureMode.replace:
        return hiddenChild ?? const SizedBox.shrink();
    }
  }
}

/// A specialized amount display widget with visibility toggle support.
///
/// This widget displays monetary amounts with optional currency symbols and
/// automatically handles visibility state using [AmountVisibilityCubit].
/// When visibility is disabled, it obfuscates the amount using the specified mode.
///
/// Example usage:
/// ```dart
/// AmountDisplay(
///   amount: 1234.56,
///   currencySymbol: '\$',
///   showCurrency: true,
///   decimalDigits: 2,
///   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
///   hiddenText: '****',
///   obscureMode: AmountObscureMode.replace,
/// )
/// ```
class AmountDisplay extends StatelessWidget {
  /// The monetary amount to display.
  final double amount;

  /// Text style for the amount display.
  final TextStyle? style;

  /// Currency symbol to show (e.g., '\$', '€', '₺').
  final String currencySymbol;

  /// Whether to show the currency symbol.
  final bool showCurrency;

  /// Number of decimal places to display.
  final int decimalDigits;

  /// Text to show when amount is hidden.
  final String hiddenText;

  /// How to obfuscate the amount when hidden.
  final AmountObscureMode obscureMode;

  /// Blur intensity for [AmountObscureMode.blur] mode.
  final double blurSigma;

  /// Duration of show/hide animations.
  final Duration animationDuration;

  /// Animation curve for transitions.
  final Curve animationCurve;

  /// Alignment of the amount inside its bounds.
  final AlignmentGeometry alignment;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.style,
    this.currencySymbol = '₺',
    this.showCurrency = true,
    this.decimalDigits = 2,
    this.hiddenText = '****',
    this.obscureMode = AmountObscureMode.replace,
    this.blurSigma = 6,
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeOut,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    final visibleText =
        '${formatGroupedAmount(amount, decimalDigits)}${showCurrency ? ' $currencySymbol' : ''}';
    final hiddenTextValue =
        '$hiddenText${showCurrency ? ' $currencySymbol' : ''}';

    return AmountVisibilityObfuscator(
      obscureMode: obscureMode,
      blurSigma: blurSigma,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      alignment: alignment,
      hiddenChild: Text(
        hiddenTextValue,
        style: style,
      ),
      child: Text(
        visibleText,
        style: style,
      ),
    );
  }
}

/// A signed amount display widget that shows + or - signs with visibility toggle.
///
/// Similar to [AmountDisplay] but automatically prefixes the amount with a sign
/// based on whether it represents an expense (-) or income (+). Useful for
/// financial applications where you need to distinguish between debits and credits.
///
/// Example usage:
/// ```dart
/// SignedAmountDisplay(
///   amount: 500.00,
///   isExpense: true,  // Will show "-500.00 ₺"
///   currencySymbol: '₺',
///   style: TextStyle(
///     color: Colors.red, // Red for expenses
///     fontWeight: FontWeight.bold,
///   ),
/// )
///
/// SignedAmountDisplay(
///   amount: 1000.00,
///   isExpense: false,  // Will show "+1000.00 ₺"
///   currencySymbol: '\$',
///   style: TextStyle(
///     color: Colors.green, // Green for income
///     fontWeight: FontWeight.bold,
///   ),
/// )
/// ```
class SignedAmountDisplay extends StatelessWidget {
  /// The monetary amount to display (absolute value, sign is added automatically).
  final double amount;

  /// Text style for the amount display.
  final TextStyle? style;

  /// Currency symbol to show (e.g., '\$', '€', '₺').
  final String currencySymbol;

  /// Whether this amount represents an expense (true) or income (false).
  final bool isExpense;

  /// Number of decimal places to display.
  final int decimalDigits;

  /// Text to show when amount is hidden.
  final String hiddenText;

  /// How to obfuscate the amount when hidden.
  final AmountObscureMode obscureMode;

  /// Blur intensity for [AmountObscureMode.blur] mode.
  final double blurSigma;

  /// Duration of show/hide animations.
  final Duration animationDuration;

  /// Animation curve for transitions.
  final Curve animationCurve;

  const SignedAmountDisplay({
    super.key,
    required this.amount,
    required this.isExpense,
    this.style,
    this.currencySymbol = '₺',
    this.decimalDigits = 2,
    this.hiddenText = '****',
    this.obscureMode = AmountObscureMode.replace,
    this.blurSigma = 6,
    this.animationDuration = const Duration(milliseconds: 220),
    this.animationCurve = Curves.easeOut,
  });

  @override
  Widget build(BuildContext context) {
    final sign = isExpense ? '-' : '+';
    final visibleText =
        '$sign${formatGroupedAmount(amount.abs(), decimalDigits)} $currencySymbol';
    final hiddenTextValue = '$sign$hiddenText $currencySymbol';

    return AmountVisibilityObfuscator(
      obscureMode: obscureMode,
      blurSigma: blurSigma,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      hiddenChild: Text(
        hiddenTextValue,
        style: style,
      ),
      child: Text(
        visibleText,
        style: style,
      ),
    );
  }
}

/// A button widget that toggles the visibility state of sensitive information.
///
/// This button automatically synchronizes with [AmountVisibilityCubit] and
/// shows appropriate icons for visible/hidden states. When tapped, it toggles
/// the global visibility state, affecting all [AmountDisplay] widgets in the
/// [AmountVisibilityCubit]'s scope.
///
/// Example usage:
/// ```dart
/// Row(
///   children: [
///     Text('Balance: '),
///     AmountDisplay(amount: balance),
///     Spacer(),
///     AmountVisibilityButton(
///       activeColor: Colors.white,
///       inactiveColor: Colors.white.withValues(alpha:  0.7),
///       size: 20,
///     ),
///   ],
/// )
/// ```
class AmountVisibilityButton extends StatelessWidget {
  /// Color when visibility is enabled (visible state).
  final Color? activeColor;

  /// Color when visibility is disabled (hidden state).
  final Color? inactiveColor;

  /// Icon size for the visibility icons.
  final double size;

  const AmountVisibilityButton({
    super.key,
    this.activeColor,
    this.inactiveColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AmountVisibilityCubit, bool>(
      builder: (context, isVisible) {
        return IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            size: size,
            color: isVisible
                ? (activeColor ?? Colors.white)
                : (inactiveColor ?? Colors.white.withValues(alpha: 0.7)),
          ),
          onPressed: () {
            context.read<AmountVisibilityCubit>().toggleVisibility();
          },
          tooltip: isVisible ? 'Hide amounts' : 'Show amounts',
        );
      },
    );
  }
}
