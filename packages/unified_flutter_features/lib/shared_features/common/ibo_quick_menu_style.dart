import 'package:flutter/material.dart';
import 'ibo_glass_surface.dart';

class IboQuickMenuStyle {
  final IboGlassStyle glassStyle;
  final TextStyle? titleStyle;
  final TextStyle? optionStyle;
  final TextStyle? actionStyle;
  final IconData actionIcon;
  final Color? actionIconColor;
  final EdgeInsetsGeometry listPadding;
  final EdgeInsetsGeometry itemPadding;

  const IboQuickMenuStyle({
    this.glassStyle = const IboGlassStyle(
      borderRadius: BorderRadius.all(Radius.circular(22)),
      padding: EdgeInsets.zero,
    ),
    this.titleStyle,
    this.optionStyle,
    this.actionStyle,
    this.actionIcon = Icons.calendar_today,
    this.actionIconColor,
    this.listPadding = const EdgeInsets.symmetric(vertical: 6),
    this.itemPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  IboQuickMenuStyle copyWith({
    IboGlassStyle? glassStyle,
    TextStyle? titleStyle,
    TextStyle? optionStyle,
    TextStyle? actionStyle,
    IconData? actionIcon,
    Color? actionIconColor,
    EdgeInsetsGeometry? listPadding,
    EdgeInsetsGeometry? itemPadding,
  }) {
    return IboQuickMenuStyle(
      glassStyle: glassStyle ?? this.glassStyle,
      titleStyle: titleStyle ?? this.titleStyle,
      optionStyle: optionStyle ?? this.optionStyle,
      actionStyle: actionStyle ?? this.actionStyle,
      actionIcon: actionIcon ?? this.actionIcon,
      actionIconColor: actionIconColor ?? this.actionIconColor,
      listPadding: listPadding ?? this.listPadding,
      itemPadding: itemPadding ?? this.itemPadding,
    );
  }
}
