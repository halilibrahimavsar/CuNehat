import 'package:flutter/foundation.dart';

@immutable
class SnackbarTexts {
  final String successDefaultMessage;
  final String errorDefaultMessage;
  final String warningDefaultMessage;
  final String infoDefaultMessage;

  const SnackbarTexts({
    this.successDefaultMessage = 'Operation completed successfully.',
    this.errorDefaultMessage = 'An error occurred.',
    this.warningDefaultMessage = 'Please check this warning.',
    this.infoDefaultMessage = 'FYI.',
  });

  SnackbarTexts copyWith({
    String? successDefaultMessage,
    String? errorDefaultMessage,
    String? warningDefaultMessage,
    String? infoDefaultMessage,
  }) {
    return SnackbarTexts(
      successDefaultMessage:
          successDefaultMessage ?? this.successDefaultMessage,
      errorDefaultMessage: errorDefaultMessage ?? this.errorDefaultMessage,
      warningDefaultMessage:
          warningDefaultMessage ?? this.warningDefaultMessage,
      infoDefaultMessage: infoDefaultMessage ?? this.infoDefaultMessage,
    );
  }
}
