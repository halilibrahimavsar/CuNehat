import 'package:flutter/foundation.dart';

@immutable
class DateRangePickerTexts {
  final String helpText;
  final String saveText;
  final String cancelText;
  final String quickMenuActionText;

  const DateRangePickerTexts({
    this.helpText = 'Select date range',
    this.saveText = 'Save',
    this.cancelText = 'Cancel',
    this.quickMenuActionText = 'Choose from calendar',
  });

  DateRangePickerTexts copyWith({
    String? helpText,
    String? saveText,
    String? cancelText,
    String? quickMenuActionText,
  }) {
    return DateRangePickerTexts(
      helpText: helpText ?? this.helpText,
      saveText: saveText ?? this.saveText,
      cancelText: cancelText ?? this.cancelText,
      quickMenuActionText: quickMenuActionText ?? this.quickMenuActionText,
    );
  }
}
