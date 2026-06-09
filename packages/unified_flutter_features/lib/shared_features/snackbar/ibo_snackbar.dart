import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/texts/snackbar_texts.dart';
import '../common/ibo_glass_surface.dart';

class IboSnackbarStyle {
  final IboGlassStyle? glassStyle;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow>? shadows;
  final TextStyle? textStyle;
  final TextStyle? titleStyle;
  final TextStyle? messageStyle;
  final IconData? icon;
  final Color? iconColor;
  final double iconSize;
  final double iconGap;
  final double? maxWidth;
  final double? minHeight;
  final Widget? leading;
  final Widget? trailing;
  final bool useGlassEffect;
  final double blurSigma;
  final bool showCloseIcon;
  final Color? closeIconColor;

  const IboSnackbarStyle({
    this.glassStyle,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.shadows,
    this.textStyle,
    this.titleStyle,
    this.messageStyle,
    this.icon,
    this.iconColor,
    this.iconSize = 20,
    this.iconGap = 10,
    this.maxWidth,
    this.minHeight,
    this.leading,
    this.trailing,
    this.useGlassEffect = true,
    this.blurSigma = 12,
    this.showCloseIcon = true,
    this.closeIconColor,
  });

  IboSnackbarStyle copyWith({
    IboGlassStyle? glassStyle,
    Gradient? gradient,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? shadows,
    TextStyle? textStyle,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
    double? iconGap,
    double? maxWidth,
    double? minHeight,
    Widget? leading,
    Widget? trailing,
    bool? useGlassEffect,
    double? blurSigma,
    bool? showCloseIcon,
    Color? closeIconColor,
  }) {
    return IboSnackbarStyle(
      glassStyle: glassStyle ?? this.glassStyle,
      gradient: gradient ?? this.gradient,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      shadows: shadows ?? this.shadows,
      textStyle: textStyle ?? this.textStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      messageStyle: messageStyle ?? this.messageStyle,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconSize: iconSize ?? this.iconSize,
      iconGap: iconGap ?? this.iconGap,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      useGlassEffect: useGlassEffect ?? this.useGlassEffect,
      blurSigma: blurSigma ?? this.blurSigma,
      showCloseIcon: showCloseIcon ?? this.showCloseIcon,
      closeIconColor: closeIconColor ?? this.closeIconColor,
    );
  }
}

/// A customizable snackbar widget with glass effect and predefined styles.
///
/// Example usage:
/// ```dart
/// IboSnackbar.showSuccess(context, 'Operation successful!');
/// IboSnackbar.showError(context, 'An error occurred');
/// IboSnackbar.showWarning(context, 'Warning');
/// IboSnackbar.showInfo(context, 'Info');
///
/// IboSnackbar.show(
///   context,
///   'Detailed message',
///   title: 'Title',
///   subtitle: 'Subtitle',
///   style: const IboSnackbarStyle(icon: Icons.info),
/// );
/// ```
class IboSnackbar {
  /// Shows a customizable snackbar with glass effect styling.
  ///
  /// [context] The build context to show the snackbar in.
  /// [message] The main message to display.
  /// [title] Optional title text.
  /// [subtitle] Optional subtitle text.
  /// [content] Optional custom content widget instead of text.
  /// [backgroundColor] Background color override.
  /// [behavior] SnackBar behavior (floating or fixed).
  /// [duration] How long to display the snackbar.
  /// [action] Optional action button.
  /// [style] Custom styling options.
  static void show(
    BuildContext context,
    String message, {
    String? title,
    String? subtitle,
    Widget? content,
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    IboSnackbarStyle? style,
  }) {
    final resolvedStyle = style ?? const IboSnackbarStyle();
    final baseBackground =
        backgroundColor ?? resolvedStyle.backgroundColor ?? AppColors.primary;
    final resolvedGradient = resolvedStyle.gradient ??
        LinearGradient(
          colors: [
            baseBackground.withValues(alpha: 0.85),
            baseBackground.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final resolvedShadows = resolvedStyle.shadows ??
        [
          BoxShadow(
            color: baseBackground.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ];
    final resolvedGlassStyle =
        (resolvedStyle.glassStyle ?? const IboGlassStyle()).copyWith(
      gradient: resolvedGradient,
      backgroundColor: baseBackground,
      borderRadius: resolvedStyle.borderRadius,
      borderColor:
          resolvedStyle.borderColor ?? baseBackground.withValues(alpha: 0.5),
      borderWidth: resolvedStyle.borderWidth,
      shadows: resolvedShadows,
      padding: resolvedStyle.padding,
      useGlassEffect: resolvedStyle.useGlassEffect,
      blurSigma: resolvedStyle.blurSigma,
      backgroundOpacity: 0.82,
    );

    final contentWidget = content ??
        _buildTextContent(
          message: message,
          title: title,
          subtitle: subtitle,
          resolvedStyle: resolvedStyle,
        );
    final leadingWidget = resolvedStyle.leading ??
        (resolvedStyle.icon != null
            ? Icon(
                resolvedStyle.icon,
                color: resolvedStyle.iconColor ?? AppColors.onPrimary,
                size: resolvedStyle.iconSize,
              )
            : null);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: resolvedStyle.maxWidth ?? 520,
            minHeight: resolvedStyle.minHeight ?? 0,
          ),
          child: IboGlassSurface(
            style: resolvedGlassStyle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingWidget != null)
                  Padding(
                    padding: EdgeInsets.only(right: resolvedStyle.iconGap),
                    child: leadingWidget,
                  ),
                Expanded(child: contentWidget),
                if (resolvedStyle.trailing != null)
                  Padding(
                    padding: EdgeInsets.only(left: resolvedStyle.iconGap),
                    child: resolvedStyle.trailing!,
                  ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: behavior,
        margin: resolvedStyle.margin,
        elevation: 0,
        action: action,
        showCloseIcon: resolvedStyle.showCloseIcon,
        closeIconColor: resolvedStyle.closeIconColor ?? AppColors.onPrimary,
      ),
    );
  }

  static Widget _buildTextContent({
    required String message,
    String? title,
    String? subtitle,
    required IboSnackbarStyle resolvedStyle,
  }) {
    final baseTextStyle = resolvedStyle.textStyle ??
        const TextStyle(
          color: AppColors.onPrimary,
          fontWeight: FontWeight.w600,
        );
    final titleStyle = resolvedStyle.titleStyle ??
        baseTextStyle.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        );
    final messageStyle = resolvedStyle.messageStyle ??
        baseTextStyle.copyWith(
          fontWeight: FontWeight.w500,
        );
    final subtitleStyle = resolvedStyle.messageStyle ??
        baseTextStyle.copyWith(
          fontSize: 12,
          color: baseTextStyle.color?.withValues(alpha: 0.82),
        );

    if (title == null && subtitle == null) {
      return DefaultTextStyle(style: baseTextStyle, child: Text(message));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) Text(title, style: titleStyle),
        if (title != null) const SizedBox(height: 2),
        Text(message, style: messageStyle),
        if (subtitle != null) const SizedBox(height: 4),
        if (subtitle != null) Text(subtitle, style: subtitleStyle),
      ],
    );
  }

  /// Shows a success snackbar with green background and check icon.
  ///
  /// [context] The build context to show the snackbar in.
  /// [message] The success message to display.
  /// [style] Optional custom styling.
  static void showSuccess(
    BuildContext context,
    String message, {
    IboSnackbarStyle? style,
    SnackbarTexts texts = const SnackbarTexts(),
  }) {
    show(
      context,
      message.isEmpty ? texts.successDefaultMessage : message,
      backgroundColor: AppColors.success,
      style: style ?? const IboSnackbarStyle(icon: Icons.check_circle),
    );
  }

  /// Shows an error snackbar with red background and error icon.
  ///
  /// [context] The build context to show the snackbar in.
  /// [message] The error message to display.
  /// [style] Optional custom styling.
  static void showError(
    BuildContext context,
    String message, {
    IboSnackbarStyle? style,
    SnackbarTexts texts = const SnackbarTexts(),
  }) {
    show(
      context,
      message.isEmpty ? texts.errorDefaultMessage : message,
      backgroundColor: AppColors.error,
      style: style ?? const IboSnackbarStyle(icon: Icons.error_rounded),
    );
  }

  /// Shows a warning snackbar with yellow background and warning icon.
  ///
  /// [context] The build context to show the snackbar in.
  /// [message] The warning message to display.
  /// [style] Optional custom styling.
  static void showWarning(
    BuildContext context,
    String message, {
    IboSnackbarStyle? style,
    SnackbarTexts texts = const SnackbarTexts(),
  }) {
    show(
      context,
      message.isEmpty ? texts.warningDefaultMessage : message,
      backgroundColor: AppColors.warning,
      style: style ?? const IboSnackbarStyle(icon: Icons.warning_amber_rounded),
    );
  }

  /// Shows an info snackbar with blue background and info icon.
  ///
  /// [context] The build context to show the snackbar in.
  /// [message] The info message to display.
  /// [style] Optional custom styling.
  static void showInfo(
    BuildContext context,
    String message, {
    IboSnackbarStyle? style,
    SnackbarTexts texts = const SnackbarTexts(),
  }) {
    show(
      context,
      message.isEmpty ? texts.infoDefaultMessage : message,
      backgroundColor: AppColors.sliderInfo,
      style: style ?? const IboSnackbarStyle(icon: Icons.info_rounded),
    );
  }
}
