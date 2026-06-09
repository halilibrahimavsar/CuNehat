import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/texts/date_picker_texts.dart';
import '../common/ibo_glass_surface.dart';
import '../common/ibo_quick_menu_style.dart';

/// Represents a quick date selection option with label and date.
///
/// Used in date picker dialogs to provide pre-defined date options like "Today",
/// "Yesterday", etc.
class IboDateQuickOption {
  /// The display label for this quick option.
  final String label;

  /// The date value for this quick option.
  final DateTime date;

  const IboDateQuickOption({
    required this.label,
    required this.date,
  });
}

class _QuickDateAction {
  final DateTime? date;
  final bool openPicker;

  const _QuickDateAction.select(this.date) : openPicker = false;
  const _QuickDateAction.openPicker()
      : date = null,
        openPicker = true;
}

/// A customizable date picker with quick selection options and glass effect styling.
///
/// Example usage:
/// ```dart
/// final date = await IboDatePicker.pickDate(
///   context,
///   quickOptions: [
///     IboDateQuickOption(label: 'Today', date: DateTime.now()),
///   ],
///   normalizeToStartOfDay: true,
/// );
/// ```
class IboDatePicker {
  /// Shows a date picker dialog with optional quick selection options.
  ///
  /// [context] The build context to show the date picker in.
  /// [initialDate] The initially selected date.
  /// [firstDate] The earliest selectable date.
  /// [lastDate] The latest selectable date.
  /// [helpText] Help text displayed in the picker dialog.
  /// [cancelText] Text for the cancel button.
  /// [confirmText] Text for the confirm button.
  /// [quickOptions] List of quick date selection options.
  /// [normalizeToStartOfDay] Whether to normalize selected date to start of day.
  /// [pickerTheme] Custom theme for the date picker.
  /// [quickMenuStyle] Style for the quick options menu.
  /// [quickMenuActionText] Text for the "Open Picker" action.
  ///
  /// Returns the selected date or null if cancelled.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? cancelText,
    String? confirmText,
    List<IboDateQuickOption>? quickOptions,
    bool normalizeToStartOfDay = false,
    ThemeData? pickerTheme,
    IboQuickMenuStyle? quickMenuStyle,
    String? quickMenuActionText,
    DatePickerTexts texts = const DatePickerTexts(),
  }) async {
    if (quickOptions != null && quickOptions.isNotEmpty) {
      final action = await _showQuickMenu(
        context,
        quickOptions: quickOptions,
        title: helpText ?? texts.helpText,
        style: quickMenuStyle,
        actionText: quickMenuActionText ?? texts.quickMenuActionText,
      );
      if (action == null) {
        return null;
      }
      if (!action.openPicker) {
        final selected = action.date;
        if (selected == null) {
          return null;
        }
        return normalizeToStartOfDay ? _startOfDay(selected) : selected;
      }
    }

    if (!context.mounted) {
      return null;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: helpText ?? texts.helpText,
      cancelText: cancelText ?? texts.cancelText,
      confirmText: confirmText ?? texts.confirmText,
      fieldLabelText: texts.fieldLabelText,
      fieldHintText: texts.fieldHintText,
      builder: (context, child) {
        return Theme(
          data: pickerTheme ?? _defaultPickerTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null) {
      return null;
    }
    return normalizeToStartOfDay ? _startOfDay(selected) : selected;
  }

  /// Shows a date picker with advanced constraints and selectable day predicate.
  ///
  /// Similar to [pickDate] but with additional constraint options.
  ///
  /// [context] The build context to show the date picker in.
  /// [initialDate] The initially selected date.
  /// [minimumDate] The minimum selectable date.
  /// [maximumDate] The maximum selectable date.
  /// [initialEntryMode] The initial entry mode of the picker.
  /// [selectableDayPredicate] Function to determine if a day is selectable.
  /// [quickOptions] List of quick date selection options.
  /// [normalizeToStartOfDay] Whether to normalize selected date to start of day.
  /// [pickerTheme] Custom theme for the date picker.
  /// [quickMenuStyle] Style for the quick options menu.
  /// [quickMenuActionText] Text for the "Open Picker" action.
  ///
  /// Returns the selected date or null if cancelled.
  static Future<DateTime?> pickDateWithConstraints(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? minimumDate,
    DateTime? maximumDate,
    DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
    bool Function(DateTime)? selectableDayPredicate,
    List<IboDateQuickOption>? quickOptions,
    bool normalizeToStartOfDay = false,
    ThemeData? pickerTheme,
    IboQuickMenuStyle? quickMenuStyle,
    String? quickMenuActionText,
    DatePickerTexts texts = const DatePickerTexts(),
  }) async {
    if (quickOptions != null && quickOptions.isNotEmpty) {
      final action = await _showQuickMenu(
        context,
        quickOptions: quickOptions,
        title: texts.helpText,
        style: quickMenuStyle,
        actionText: quickMenuActionText ?? texts.quickMenuActionText,
      );
      if (action == null) {
        return null;
      }
      if (!action.openPicker) {
        final selected = action.date;
        if (selected == null) {
          return null;
        }
        return normalizeToStartOfDay ? _startOfDay(selected) : selected;
      }
    }

    if (!context.mounted) {
      return null;
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: minimumDate ?? DateTime(1900),
      lastDate: maximumDate ?? DateTime(2100),
      initialEntryMode: initialEntryMode,
      selectableDayPredicate: selectableDayPredicate,
      builder: (context, child) {
        return Theme(
          data: pickerTheme ?? _defaultPickerTheme(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected == null) {
      return null;
    }
    return normalizeToStartOfDay ? _startOfDay(selected) : selected;
  }

  static Future<_QuickDateAction?> _showQuickMenu(
    BuildContext context, {
    required List<IboDateQuickOption> quickOptions,
    required String title,
    IboQuickMenuStyle? style,
    required String actionText,
  }) async {
    final resolvedStyle = style ?? const IboQuickMenuStyle();
    return showModalBottomSheet<_QuickDateAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: IboGlassSurface(
              style: resolvedStyle.glassStyle,
              child: Material(
                color: Colors.transparent,
                child: ListView(
                  shrinkWrap: true,
                  padding: resolvedStyle.listPadding,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    ListTile(
                      title: Text(
                        title,
                        style: resolvedStyle.titleStyle ??
                            const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                    ),
                    for (final option in quickOptions)
                      ListTile(
                        contentPadding: resolvedStyle.itemPadding,
                        title: Text(
                          option.label,
                          style: resolvedStyle.optionStyle,
                        ),
                        onTap: () => Navigator.of(context).pop(
                          _QuickDateAction.select(option.date),
                        ),
                      ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: resolvedStyle.itemPadding,
                      leading: Icon(
                        resolvedStyle.actionIcon,
                        color:
                            resolvedStyle.actionIconColor ?? AppColors.primary,
                      ),
                      title: Text(
                        actionText,
                        style: resolvedStyle.actionStyle ??
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => Navigator.of(context).pop(
                        const _QuickDateAction.openPicker(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static ThemeData _defaultPickerTheme(BuildContext context) {
    final base = Theme.of(context);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: base.brightness,
    );
    return base.copyWith(
      colorScheme: scheme,
      dialogTheme: const DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
      ),
    );
  }
}
