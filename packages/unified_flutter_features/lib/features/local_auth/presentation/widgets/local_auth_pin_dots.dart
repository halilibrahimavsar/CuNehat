import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/local_auth_constants.dart';

class LocalAuthPinDots extends StatelessWidget {
  final int length;
  final int filled;
  final bool isError;
  final Animation<double> shake;
  final Color activeColor;
  final Color inactiveColor;
  final Color errorColor;

  const LocalAuthPinDots({
    super.key,
    required this.length,
    required this.filled,
    required this.isError,
    required this.shake,
    required this.activeColor,
    required this.inactiveColor,
    required this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shake,
      builder: (context, child) {
        final offset =
            24 * math.sin(shake.value * math.pi * 4) * (1 - shake.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(length, (index) {
          final isFilled = index < filled;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(
                horizontal: LocalAuthConstants.pinDotSpacing),
            width: LocalAuthConstants.pinDotSize.toDouble(),
            height: LocalAuthConstants.pinDotSize.toDouble(),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isError
                  ? errorColor
                  : (isFilled ? activeColor : inactiveColor),
              boxShadow: isFilled && !isError
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: LocalAuthConstants.pinDotShadowBlurRadius
                            .toDouble(),
                        spreadRadius: LocalAuthConstants
                            .pinDotShadowSpreadRadius
                            .toDouble(),
                      )
                    ]
                  : [],
            ),
          );
        }),
      ),
    );
  }
}
