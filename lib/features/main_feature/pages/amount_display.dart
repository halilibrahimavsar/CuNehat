// lib/core/shared/widgets/amount_display.dart

import 'package:cunehat/features/main_feature/blocs/amount_visibility_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tutar gösterme widget'ı - Görünürlük durumuna göre tutarı gösterir veya gizler
class AmountDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currencySymbol;
  final bool showCurrency;
  final int decimalDigits;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.style,
    this.currencySymbol = '₺',
    this.showCurrency = true,
    this.decimalDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AmountVisibilityCubit, bool>(
      builder: (context, isVisible) {
        if (isVisible) {
          return Text(
            '${amount.toStringAsFixed(decimalDigits)}${showCurrency ? ' $currencySymbol' : ''}',
            style: style,
          );
        } else {
          // Gizli mod - yıldızlar göster
          return Text(
            '****${showCurrency ? ' $currencySymbol' : ''}',
            style: style,
          );
        }
      },
    );
  }
}

/// İşaretli tutar gösterme (+ veya -)
class SignedAmountDisplay extends StatelessWidget {
  final double amount;
  final TextStyle? style;
  final String currencySymbol;
  final bool isExpense;
  final int decimalDigits;

  const SignedAmountDisplay({
    super.key,
    required this.amount,
    required this.isExpense,
    this.style,
    this.currencySymbol = '₺',
    this.decimalDigits = 2,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AmountVisibilityCubit, bool>(
      builder: (context, isVisible) {
        final sign = isExpense ? '-' : '+';

        if (isVisible) {
          return Text(
            '$sign${amount.toStringAsFixed(decimalDigits)} $currencySymbol',
            style: style,
          );
        } else {
          return Text(
            '$sign**** $currencySymbol',
            style: style,
          );
        }
      },
    );
  }
}

/// Visibility Toggle Button
class AmountVisibilityButton extends StatelessWidget {
  final Color? activeColor;
  final Color? inactiveColor;
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
          tooltip: isVisible ? 'Tutarları Gizle' : 'Tutarları Göster',
        );
      },
    );
  }
}

/// Compact Visibility Toggle (daha küçük, basit)
class CompactVisibilityToggle extends StatelessWidget {
  final Color? color;
  final double size;

  const CompactVisibilityToggle({
    super.key,
    this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AmountVisibilityCubit, bool>(
      builder: (context, isVisible) {
        return GestureDetector(
          onTap: () {
            context.read<AmountVisibilityCubit>().toggleVisibility();
          },
          child: Icon(
            isVisible
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: size,
            color: color ?? Colors.grey.shade600,
          ),
        );
      },
    );
  }
}
