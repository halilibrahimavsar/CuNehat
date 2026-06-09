import 'dart:ui';

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class IboGlassStyle {
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry padding;
  final bool useGlassEffect;
  final double blurSigma;
  final double backgroundOpacity;

  const IboGlassStyle({
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.shadows,
    this.padding = AppSpacing.mediumAll,
    this.useGlassEffect = true,
    this.blurSigma = 12,
    this.backgroundOpacity = 0.72,
  });

  IboGlassStyle copyWith({
    Gradient? gradient,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    EdgeInsetsGeometry? padding,
    bool? useGlassEffect,
    double? blurSigma,
    double? backgroundOpacity,
  }) {
    return IboGlassStyle(
      gradient: gradient ?? this.gradient,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
      padding: padding ?? this.padding,
      useGlassEffect: useGlassEffect ?? this.useGlassEffect,
      blurSigma: blurSigma ?? this.blurSigma,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }
}

class IboGlassSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final IboGlassStyle style;

  const IboGlassSurface({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.alignment,
    this.padding,
    this.style = const IboGlassStyle(),
  });

  @override
  Widget build(BuildContext context) {
    final baseBackground = style.backgroundColor ?? AppColors.surface;
    final resolvedGradient = style.gradient ??
        LinearGradient(
          colors: [
            baseBackground.withValues(alpha: 0.35),
            baseBackground.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final resolvedShadows = style.shadows ??
        [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: style.borderRadius,
        border: Border.all(
          color: style.borderColor ?? AppColors.primary.withValues(alpha: 0.45),
          width: style.borderWidth,
        ),
        boxShadow: resolvedShadows,
      ),
      child: ClipRRect(
        borderRadius: style.borderRadius,
        child: BackdropFilter(
          filter: style.useGlassEffect
              ? ImageFilter.blur(
                  sigmaX: style.blurSigma,
                  sigmaY: style.blurSigma,
                )
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Container(
            alignment: alignment,
            padding: padding ?? style.padding,
            decoration: BoxDecoration(
              gradient: resolvedGradient,
              color: style.gradient == null
                  ? baseBackground.withValues(alpha: style.backgroundOpacity)
                  : null,
              borderRadius: style.borderRadius,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
