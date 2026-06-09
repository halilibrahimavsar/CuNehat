import 'package:flutter/foundation.dart';

@immutable
class LocalAuthTexts {
  final String logoutLabel;
  final String welcomeTitle;
  final String enterPinPrompt;
  final String lockedOutPromptPrefix;
  final String lockedOutPromptSuffix;
  final String invalidPinFallback;
  final String biometricReason;
  final String settingsTitle;
  final String createPinTitle;
  final String changePinTitle;
  final String deletePinTitle;
  final String verifyPinTitle;
  final String deletePinConfirmMessage;
  final String saveLabel;
  final String changeLabel;
  final String removeLabel;
  final String cancelLabel;
  final String pinMismatchMessage;
  final String pinValidationMessage;

  const LocalAuthTexts({
    this.logoutLabel = 'Logout',
    this.welcomeTitle = 'Welcome',
    this.enterPinPrompt = 'Enter PIN to continue',
    this.lockedOutPromptPrefix = 'Too many failed attempts. Wait',
    this.lockedOutPromptSuffix = 'seconds.',
    this.invalidPinFallback = 'Incorrect PIN, try again.',
    this.biometricReason = 'Authenticate to continue',
    this.settingsTitle = 'Security Settings',
    this.createPinTitle = 'Create PIN',
    this.changePinTitle = 'Change PIN',
    this.deletePinTitle = 'Remove PIN',
    this.verifyPinTitle = 'Verify PIN',
    this.deletePinConfirmMessage =
        'Removing PIN will also disable biometric login. Continue?',
    this.saveLabel = 'Save',
    this.changeLabel = 'Change',
    this.removeLabel = 'Remove',
    this.cancelLabel = 'Cancel',
    this.pinMismatchMessage = 'PINs do not match',
    this.pinValidationMessage = 'Enter a 6-digit PIN',
  });

  LocalAuthTexts copyWith({
    String? logoutLabel,
    String? welcomeTitle,
    String? enterPinPrompt,
    String? lockedOutPromptPrefix,
    String? lockedOutPromptSuffix,
    String? invalidPinFallback,
    String? biometricReason,
    String? settingsTitle,
    String? createPinTitle,
    String? changePinTitle,
    String? deletePinTitle,
    String? verifyPinTitle,
    String? deletePinConfirmMessage,
    String? saveLabel,
    String? changeLabel,
    String? removeLabel,
    String? cancelLabel,
    String? pinMismatchMessage,
    String? pinValidationMessage,
  }) {
    return LocalAuthTexts(
      logoutLabel: logoutLabel ?? this.logoutLabel,
      welcomeTitle: welcomeTitle ?? this.welcomeTitle,
      enterPinPrompt: enterPinPrompt ?? this.enterPinPrompt,
      lockedOutPromptPrefix:
          lockedOutPromptPrefix ?? this.lockedOutPromptPrefix,
      lockedOutPromptSuffix:
          lockedOutPromptSuffix ?? this.lockedOutPromptSuffix,
      invalidPinFallback: invalidPinFallback ?? this.invalidPinFallback,
      biometricReason: biometricReason ?? this.biometricReason,
      settingsTitle: settingsTitle ?? this.settingsTitle,
      createPinTitle: createPinTitle ?? this.createPinTitle,
      changePinTitle: changePinTitle ?? this.changePinTitle,
      deletePinTitle: deletePinTitle ?? this.deletePinTitle,
      verifyPinTitle: verifyPinTitle ?? this.verifyPinTitle,
      deletePinConfirmMessage:
          deletePinConfirmMessage ?? this.deletePinConfirmMessage,
      saveLabel: saveLabel ?? this.saveLabel,
      changeLabel: changeLabel ?? this.changeLabel,
      removeLabel: removeLabel ?? this.removeLabel,
      cancelLabel: cancelLabel ?? this.cancelLabel,
      pinMismatchMessage: pinMismatchMessage ?? this.pinMismatchMessage,
      pinValidationMessage: pinValidationMessage ?? this.pinValidationMessage,
    );
  }
}
