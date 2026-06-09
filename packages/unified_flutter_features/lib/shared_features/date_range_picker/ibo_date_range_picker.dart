import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/texts/date_range_picker_texts.dart';
import '../common/ibo_glass_surface.dart';
import '../common/ibo_quick_menu_style.dart';

class IboDateRangeQuickOption {
  final String label;
  final DateTimeRange range;

  const IboDateRangeQuickOption({
    required this.label,
    required this.range,
  });
}

class _QuickRangeAction {
  final DateTimeRange? range;
  final bool openPicker;

  const _QuickRangeAction.select(this.range) : openPicker = false;
  const _QuickRangeAction.openPicker()
      : range = null,
        openPicker = true;
}

class IboDateRangePicker {
  static Future<DateTimeRange?> pickDateRange(
    BuildContext context, {
    DateTimeRange? initialDateRange,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? saveText,
    String? cancelText,
    List<IboDateRangeQuickOption>? quickOptions,
    bool includeFullDays = false,
    ThemeData? pickerTheme,
    IboQuickMenuStyle? quickMenuStyle,
    String? quickMenuActionText,
    DateRangePickerTexts texts = const DateRangePickerTexts(),
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
        final selected = action.range;
        if (selected == null) {
          return null;
        }
        return includeFullDays ? _normalizeToFullDays(selected) : selected;
      }
    }

    if (!context.mounted) {
      return null;
    }

    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange ??
          DateTimeRange(
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(days: 7)),
          ),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: helpText ?? texts.helpText,
      saveText: saveText ?? texts.saveText,
      cancelText: cancelText ?? texts.cancelText,
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
    return includeFullDays ? _normalizeToFullDays(selected) : selected;
  }

  static Future<_QuickRangeAction?> _showQuickMenu(
    BuildContext context, {
    required List<IboDateRangeQuickOption> quickOptions,
    required String title,
    IboQuickMenuStyle? style,
    required String actionText,
  }) async {
    final resolvedStyle = style ?? const IboQuickMenuStyle();
    return showModalBottomSheet<_QuickRangeAction>(
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
                          _QuickRangeAction.select(option.range),
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
                        const _QuickRangeAction.openPicker(),
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

  static DateTimeRange _normalizeToFullDays(DateTimeRange range) {
    final start =
        DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return DateTimeRange(start: start, end: end);
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
