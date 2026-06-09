import 'package:flutter/material.dart';
import '../../../../shared_features/common/ibo_glass_surface.dart';

/// Customizable style for LocalAuthSettingsWidget
///
/// Example usage:
/// ```dart
/// LocalAuthSettingsWidget(
///   style: LocalAuthSettingsStyle(
///     sectionTitleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
///     cardStyle: IboGlassStyle(borderRadius: BorderRadius.circular(16)),
///   ),
/// )
/// ```
class LocalAuthSettingsStyle {
  // Section Styles
  final TextStyle? sectionTitleStyle;
  final TextStyle? sectionSubtitleStyle;
  final EdgeInsetsGeometry sectionPadding;
  final double sectionSpacing;

  // Card Styles
  final IboGlassStyle cardStyle;
  final EdgeInsetsGeometry cardPadding;
  final double cardSpacing;

  // List Tile Styles
  final TextStyle? tileTitleStyle;
  final TextStyle? tileSubtitleStyle;
  final TextStyle? tileTrailingStyle;
  final IconThemeData? tileIconTheme;
  final double tileSpacing;

  // Switch Styles
  final Color? switchActiveColor;
  final Color? switchInactiveColor;
  final Color? switchTrackColor;

  // Button Styles
  final TextStyle? buttonTextStyle;
  final EdgeInsetsGeometry buttonPadding;
  final double buttonSpacing;
  final double buttonHeight;

  // Divider Style
  final DividerStyle dividerStyle;

  // Header Styles
  final TextStyle? headerTitleStyle;
  final TextStyle? headerSubtitleStyle;
  final EdgeInsetsGeometry headerPadding;

  // PIN Dialog Styles
  final TextStyle? pinDialogTitleStyle;
  final TextStyle? pinDialogSubtitleStyle;
  final TextStyle? pinInputHintStyle;
  final InputDecorationTheme? pinInputDecoration;

  // Background Lock Styles
  final TextStyle? timeoutLabelStyle;
  final TextStyle? timeoutValueStyle;
  final List<int> timeoutOptions;

  // Animation
  final Duration animationDuration;
  final Curve animationCurve;

  const LocalAuthSettingsStyle({
    this.sectionTitleStyle,
    this.sectionSubtitleStyle,
    this.sectionPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.sectionSpacing = 24,
    this.cardStyle = const IboGlassStyle(),
    this.cardPadding = const EdgeInsets.all(16),
    this.cardSpacing = 12,
    this.tileTitleStyle,
    this.tileSubtitleStyle,
    this.tileTrailingStyle,
    this.tileIconTheme,
    this.tileSpacing = 16,
    this.switchActiveColor,
    this.switchInactiveColor,
    this.switchTrackColor,
    this.buttonTextStyle,
    this.buttonPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.buttonSpacing = 8,
    this.buttonHeight = 48,
    this.dividerStyle = const DividerStyle(),
    this.headerTitleStyle,
    this.headerSubtitleStyle,
    this.headerPadding = const EdgeInsets.all(16),
    this.pinDialogTitleStyle,
    this.pinDialogSubtitleStyle,
    this.pinInputHintStyle,
    this.pinInputDecoration,
    this.timeoutLabelStyle,
    this.timeoutValueStyle,
    this.timeoutOptions = const [0, 5, 10, 15, 30, 60],
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
  });

  LocalAuthSettingsStyle copyWith({
    TextStyle? sectionTitleStyle,
    TextStyle? sectionSubtitleStyle,
    EdgeInsetsGeometry? sectionPadding,
    double? sectionSpacing,
    IboGlassStyle? cardStyle,
    EdgeInsetsGeometry? cardPadding,
    double? cardSpacing,
    TextStyle? tileTitleStyle,
    TextStyle? tileSubtitleStyle,
    TextStyle? tileTrailingStyle,
    IconThemeData? tileIconTheme,
    double? tileSpacing,
    Color? switchActiveColor,
    Color? switchInactiveColor,
    Color? switchTrackColor,
    TextStyle? buttonTextStyle,
    EdgeInsetsGeometry? buttonPadding,
    double? buttonSpacing,
    double? buttonHeight,
    DividerStyle? dividerStyle,
    TextStyle? headerTitleStyle,
    TextStyle? headerSubtitleStyle,
    EdgeInsetsGeometry? headerPadding,
    TextStyle? pinDialogTitleStyle,
    TextStyle? pinDialogSubtitleStyle,
    TextStyle? pinInputHintStyle,
    InputDecorationTheme? pinInputDecoration,
    TextStyle? timeoutLabelStyle,
    TextStyle? timeoutValueStyle,
    List<int>? timeoutOptions,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return LocalAuthSettingsStyle(
      sectionTitleStyle: sectionTitleStyle ?? this.sectionTitleStyle,
      sectionSubtitleStyle: sectionSubtitleStyle ?? this.sectionSubtitleStyle,
      sectionPadding: sectionPadding ?? this.sectionPadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      cardStyle: cardStyle ?? this.cardStyle,
      cardPadding: cardPadding ?? this.cardPadding,
      cardSpacing: cardSpacing ?? this.cardSpacing,
      tileTitleStyle: tileTitleStyle ?? this.tileTitleStyle,
      tileSubtitleStyle: tileSubtitleStyle ?? this.tileSubtitleStyle,
      tileTrailingStyle: tileTrailingStyle ?? this.tileTrailingStyle,
      tileIconTheme: tileIconTheme ?? this.tileIconTheme,
      tileSpacing: tileSpacing ?? this.tileSpacing,
      switchActiveColor: switchActiveColor ?? this.switchActiveColor,
      switchInactiveColor: switchInactiveColor ?? this.switchInactiveColor,
      switchTrackColor: switchTrackColor ?? this.switchTrackColor,
      buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonSpacing: buttonSpacing ?? this.buttonSpacing,
      buttonHeight: buttonHeight ?? this.buttonHeight,
      dividerStyle: dividerStyle ?? this.dividerStyle,
      headerTitleStyle: headerTitleStyle ?? this.headerTitleStyle,
      headerSubtitleStyle: headerSubtitleStyle ?? this.headerSubtitleStyle,
      headerPadding: headerPadding ?? this.headerPadding,
      pinDialogTitleStyle: pinDialogTitleStyle ?? this.pinDialogTitleStyle,
      pinDialogSubtitleStyle:
          pinDialogSubtitleStyle ?? this.pinDialogSubtitleStyle,
      pinInputHintStyle: pinInputHintStyle ?? this.pinInputHintStyle,
      pinInputDecoration: pinInputDecoration ?? this.pinInputDecoration,
      timeoutLabelStyle: timeoutLabelStyle ?? this.timeoutLabelStyle,
      timeoutValueStyle: timeoutValueStyle ?? this.timeoutValueStyle,
      timeoutOptions: timeoutOptions ?? this.timeoutOptions,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}

/// Divider style configuration
class DividerStyle {
  final Color? color;
  final double thickness;
  final double indent;
  final double endIndent;
  final double spacing;

  const DividerStyle({
    this.color,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
    this.spacing = 16,
  });
}
