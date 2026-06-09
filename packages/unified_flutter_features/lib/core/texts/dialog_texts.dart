import 'package:flutter/foundation.dart';

@immutable
class DialogTexts {
  final String confirmText;
  final String cancelText;
  final String okText;
  final String loadingMessage;

  const DialogTexts({
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.okText = 'OK',
    this.loadingMessage = 'Loading...',
  });

  DialogTexts copyWith({
    String? confirmText,
    String? cancelText,
    String? okText,
    String? loadingMessage,
  }) {
    return DialogTexts(
      confirmText: confirmText ?? this.confirmText,
      cancelText: cancelText ?? this.cancelText,
      okText: okText ?? this.okText,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}
