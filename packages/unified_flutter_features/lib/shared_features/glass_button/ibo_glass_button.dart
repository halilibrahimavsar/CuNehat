import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../common/ibo_glass_surface.dart';

class IboGlassButtonStyle {
  final IboGlassStyle glassStyle;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;
  final double pressedScale;
  final Duration animationDuration;
  final Curve animationCurve;
  final Color? disabledForegroundColor;
  final Color? disabledBackgroundColor;

  const IboGlassButtonStyle({
    this.glassStyle = const IboGlassStyle(),
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    this.pressedScale = 0.98,
    this.animationDuration = const Duration(milliseconds: 140),
    this.animationCurve = Curves.easeOutCubic,
    this.disabledForegroundColor,
    this.disabledBackgroundColor,
  });

  IboGlassButtonStyle copyWith({
    IboGlassStyle? glassStyle,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? pressedScale,
    Duration? animationDuration,
    Curve? animationCurve,
    Color? disabledForegroundColor,
    Color? disabledBackgroundColor,
  }) {
    return IboGlassButtonStyle(
      glassStyle: glassStyle ?? this.glassStyle,
      textStyle: textStyle ?? this.textStyle,
      padding: padding ?? this.padding,
      pressedScale: pressedScale ?? this.pressedScale,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      disabledForegroundColor:
          disabledForegroundColor ?? this.disabledForegroundColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
    );
  }
}

/// A customizable glass effect button with press animations and styling options.
///
/// Example usage:
/// ```dart
/// IboGlassButton(
///   text: 'Click',
///   onPressed: () {},
/// );
/// ```
class IboGlassButton extends StatefulWidget {
  /// The text to display on the button. Ignored if [child] is provided.
  final String text;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Text/icon color of the button.
  final Color? foregroundColor;

  /// Gradient background instead of solid color.
  final Gradient? gradient;

  /// Fixed width of the button.
  final double? width;

  /// Fixed height of the button.
  final double? height;

  /// Border radius of the button.
  final BorderRadius? borderRadius;

  /// Custom child widget instead of text.
  final Widget? child;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Custom border for the button.
  final BoxBorder? border;

  /// Custom box shadows.
  final List<BoxShadow>? boxShadow;

  /// Blur sigma for glass effect.
  final double? blurSigma;

  /// Whether to use glass effect.
  final bool useGlassEffect;

  /// Border color.
  final Color? borderColor;

  /// Border width.
  final double? borderWidth;

  /// Glow/shadow color.
  final Color? glowColor;

  /// Glow blur radius.
  final double? glowBlur;

  /// Glow spread radius.
  final double? glowSpread;

  /// Splash color for touch feedback.
  final Color? splashColor;

  /// Hover color.
  final Color? hoverColor;

  /// Focus color.
  final Color? focusColor;

  /// Highlight color.
  final Color? highlightColor;

  /// Additional styling options.
  final IboGlassButtonStyle? style;

  const IboGlassButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.width,
    this.height = 50,
    this.borderRadius,
    this.child,
    this.padding,
    this.border,
    this.boxShadow,
    this.blurSigma,
    this.useGlassEffect = true,
    this.borderColor,
    this.borderWidth,
    this.glowColor,
    this.glowBlur,
    this.glowSpread,
    this.splashColor,
    this.hoverColor,
    this.focusColor,
    this.highlightColor,
    this.style,
  });

  @override
  State<IboGlassButton> createState() => _IboGlassButtonState();
}

class _IboGlassButtonState extends State<IboGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = widget.style ?? const IboGlassButtonStyle();
    final resolvedRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final baseBackground = widget.backgroundColor ?? AppColors.surface;
    final resolvedGradient = widget.gradient ??
        LinearGradient(
          colors: [
            baseBackground.withValues(alpha: 0.35),
            baseBackground.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final resolvedBorder = widget.border ??
        Border.all(
          color:
              widget.borderColor ?? AppColors.primary.withValues(alpha: 0.45),
          width: widget.borderWidth ?? 1,
        );
    final resolvedGlowColor = widget.glowColor ?? AppColors.secondary;
    final resolvedShadows = widget.boxShadow ??
        [
          BoxShadow(
            color: resolvedGlowColor.withValues(alpha: 0.28),
            blurRadius: widget.glowBlur ?? 24,
            spreadRadius: widget.glowSpread ?? 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ];
    final isEnabled = widget.onPressed != null;
    final effectiveForeground = widget.foregroundColor ??
        resolvedStyle.textStyle?.color ??
        Colors.black87;
    final disabledForeground = resolvedStyle.disabledForegroundColor ??
        effectiveForeground.withValues(alpha: 0.55);
    final disabledBackground = resolvedStyle.disabledBackgroundColor ??
        baseBackground.withValues(alpha: 0.18);
    final resolvedGlassStyle = resolvedStyle.glassStyle.copyWith(
      gradient: resolvedGradient,
      backgroundColor: isEnabled ? baseBackground : disabledBackground,
      borderRadius: resolvedRadius,
      borderColor: resolvedBorder is Border
          ? resolvedBorder.top.color
          : widget.borderColor,
      borderWidth: resolvedBorder is Border
          ? resolvedBorder.top.width
          : widget.borderWidth,
      shadows: resolvedShadows,
      useGlassEffect: widget.useGlassEffect,
      blurSigma: widget.blurSigma,
      padding: EdgeInsets.zero,
    );

    return AnimatedScale(
      scale: _pressed ? resolvedStyle.pressedScale : 1,
      duration: resolvedStyle.animationDuration,
      curve: resolvedStyle.animationCurve,
      child: AnimatedOpacity(
        duration: resolvedStyle.animationDuration,
        curve: resolvedStyle.animationCurve,
        opacity: isEnabled ? 1 : 0.6,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: resolvedRadius,
              onTap: isEnabled ? widget.onPressed : null,
              onHighlightChanged: (value) {
                if (!isEnabled) return;
                setState(() => _pressed = value);
              },
              splashColor: widget.splashColor,
              hoverColor: widget.hoverColor,
              focusColor: widget.focusColor,
              highlightColor: widget.highlightColor,
              child: IboGlassSurface(
                width: widget.width,
                height: widget.height,
                style: resolvedGlassStyle,
                child: Center(
                  child: Padding(
                    padding: widget.padding ?? resolvedStyle.padding,
                    child: widget.child ??
                        Text(
                          widget.text,
                          textAlign: TextAlign.center,
                          style: (resolvedStyle.textStyle ??
                                  const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    letterSpacing: 0.2,
                                  ))
                              .copyWith(
                            color: isEnabled
                                ? effectiveForeground
                                : disabledForeground,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A glass effect button that shows a loading indicator during async operations.
///
/// Example usage:
/// ```dart
/// IboLoadingButton(
///   text: 'Save',
///   onPressed: () async {
///     // async operation
///   },
/// );
/// ```
class IboLoadingButton extends StatefulWidget {
  /// The text to display on the button. Ignored if [child] is provided.
  final String text;

  /// Async callback when the button is pressed.
  final Future<void> Function() onPressed;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Text/icon color of the button.
  final Color? foregroundColor;

  /// Gradient background instead of solid color.
  final Gradient? gradient;

  /// Fixed width of the button.
  final double? width;

  /// Fixed height of the button.
  final double? height;

  /// Border radius of the button.
  final BorderRadius? borderRadius;

  /// Custom child widget instead of text.
  final Widget? child;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Blur sigma for glass effect.
  final double? blurSigma;

  /// Whether to use glass effect.
  final bool useGlassEffect;

  /// Border color.
  final Color? borderColor;

  /// Border width.
  final double? borderWidth;

  /// Glow/shadow color.
  final Color? glowColor;

  /// Glow blur radius.
  final double? glowBlur;

  /// Glow spread radius.
  final double? glowSpread;

  /// Splash color for touch feedback.
  final Color? splashColor;

  /// Hover color.
  final Color? hoverColor;

  /// Focus color.
  final Color? focusColor;

  /// Highlight color.
  final Color? highlightColor;

  const IboLoadingButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.width,
    this.height = 50,
    this.borderRadius,
    this.child,
    this.padding,
    this.blurSigma,
    this.useGlassEffect = true,
    this.borderColor,
    this.borderWidth,
    this.glowColor,
    this.glowBlur,
    this.glowSpread,
    this.splashColor,
    this.hoverColor,
    this.focusColor,
    this.highlightColor,
  });

  @override
  State<IboLoadingButton> createState() => _IboLoadingButtonState();
}

class _IboLoadingButtonState extends State<IboLoadingButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return IboGlassButton(
      text: widget.text,
      backgroundColor: widget.backgroundColor,
      foregroundColor: widget.foregroundColor,
      gradient: widget.gradient,
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
      padding: widget.padding,
      blurSigma: widget.blurSigma,
      useGlassEffect: widget.useGlassEffect,
      borderColor: widget.borderColor,
      borderWidth: widget.borderWidth,
      glowColor: widget.glowColor,
      glowBlur: widget.glowBlur,
      glowSpread: widget.glowSpread,
      splashColor: widget.splashColor,
      hoverColor: widget.hoverColor,
      focusColor: widget.focusColor,
      highlightColor: widget.highlightColor,
      onPressed: _isLoading ? null : _handlePress,
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: widget.foregroundColor ?? Colors.black87,
                strokeWidth: 2,
              ),
            )
          : widget.child,
    );
  }

  Future<void> _handlePress() async {
    setState(() => _isLoading = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
