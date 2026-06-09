import 'package:flutter/foundation.dart';

@immutable
class DatePickerTexts {
  final String helpText;
  final String cancelText;
  final String confirmText;
  final String fieldLabelText;
  final String fieldHintText;
  final String quickMenuActionText;

  const DatePickerTexts({
    this.helpText = 'Select date',
    this.cancelText = 'Cancel',
    this.confirmText = 'OK',
    this.fieldLabelText = 'Selected date',
    this.fieldHintText = 'MM/DD/YYYY',
    this.quickMenuActionText = 'Choose from calendar',
  });

  DatePickerTexts copyWith({
    String? helpText,
    String? cancelText,
    String? confirmText,
    String? fieldLabelText,
    String? fieldHintText,
    String? quickMenuActionText,
  }) {
    return DatePickerTexts(
      helpText: helpText ?? this.helpText,
      cancelText: cancelText ?? this.cancelText,
      confirmText: confirmText ?? this.confirmText,
      fieldLabelText: fieldLabelText ?? this.fieldLabelText,
      fieldHintText: fieldHintText ?? this.fieldHintText,
      quickMenuActionText: quickMenuActionText ?? this.quickMenuActionText,
    );
  }
}
