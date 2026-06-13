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

  // New fields for settings pages & bloc messages
  final String msgCreateAPinFirst;
  final String msgBiometricAuthenticationIsNot;
  final String msgBiometricAuthenticationFailed;
  final String msgBiometricLoginEnabled;
  final String msgBiometricLoginDisabled;
  final String msgPINAlreadyExistsUse;
  final String msgPINsDoNotMatch;
  final String msgPINSavedSuccessfully;
  final String msgNewPinValuesDo;
  final String msgCurrentPinIsIncorrect;
  final String msgPINUpdatedSuccessfully;
  final String msgCurrentPinIsIncorrect2;
  final String msgPINRemoved;
  final String msgBackgroundLockAndPrivacy;
  final String msgPINOrBiometricLogin;
  final String securitySettings;
  final String manageYourAppSecurity;
  final String createPin;
  final String changePin;
  final String removePin;
  final String msgBiometricAuthenticationCannotBe;
  final String msgCreateAPinFirst2;
  final String msgIncorrectPinRemainingTries;
  final String msgPINVerificationFailedE;

  final String pinLockTitle;
  final String pinEnabledSubtitle;
  final String pinNotSetSubtitle;
  final String biometricLoginTitle;
  final String biometricNotAvailableSubtitle;
  final String biometricEnabledSubtitle;
  final String biometricDisabledSubtitle;
  final String biometricAuthTileTitle;
  final String biometricAuthTileSubtitleOn;
  final String biometricAuthTileSubtitleOff;
  final String privacyGuardTitle;
  final String privacyGuardEnabledSubtitle;
  final String privacyGuardDisabledSubtitle;
  final String screenProtectionTileTitle;
  final String screenProtectionTileSubtitleOn;
  final String screenProtectionTileSubtitleOff;
  final String backgroundLockTitle;
  final String backgroundLockSubtitlePrefix;
  final String backgroundLockSubtitleOff;
  final String backgroundLockTileTitle;
  final String backgroundLockTileSubtitle;
  final String backgroundLockTileInfo;

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

    // Default English translations for new fields
    this.msgCreateAPinFirst = 'Create a PIN first',
    this.msgBiometricAuthenticationIsNot =
        'Biometric authentication is not supported',
    this.msgBiometricAuthenticationFailed = 'Biometric authentication failed',
    this.msgBiometricLoginEnabled = 'Biometric login enabled',
    this.msgBiometricLoginDisabled = 'Biometric login disabled',
    this.msgPINAlreadyExistsUse = 'PIN already exists, use change PIN instead',
    this.msgPINsDoNotMatch = 'PINs do not match',
    this.msgPINSavedSuccessfully = 'PIN saved successfully',
    this.msgNewPinValuesDo = 'New PIN values do not match',
    this.msgCurrentPinIsIncorrect = 'Current PIN is incorrect',
    this.msgPINUpdatedSuccessfully = 'PIN updated successfully',
    this.msgCurrentPinIsIncorrect2 = 'Current PIN is incorrect',
    this.msgPINRemoved = 'PIN removed',
    this.msgBackgroundLockAndPrivacy =
        'Background lock and Privacy Guard enabled',
    this.msgPINOrBiometricLogin =
        'PIN or biometric login is required for background lock',
    this.securitySettings = 'Security Settings',
    this.manageYourAppSecurity = 'Manage your app security',
    this.createPin = 'Create PIN',
    this.changePin = 'Change PIN',
    this.removePin = 'Remove PIN',
    this.msgBiometricAuthenticationCannotBe =
        'Biometric authentication cannot be used on this device.',
    this.msgCreateAPinFirst2 = 'Create a PIN first to enable biometric login.',
    this.msgIncorrectPinRemainingTries =
        'Incorrect PIN. Remaining tries: {tries}',
    this.msgPINVerificationFailedE = 'PIN verification failed: {error}',
    this.pinLockTitle = 'PIN Lock',
    this.pinEnabledSubtitle = 'PIN enabled',
    this.pinNotSetSubtitle = 'PIN not set',
    this.biometricLoginTitle = 'Biometric Login',
    this.biometricNotAvailableSubtitle =
        'Biometric authentication is not available on this device',
    this.biometricEnabledSubtitle = 'Biometric login enabled',
    this.biometricDisabledSubtitle = 'Biometric login disabled',
    this.biometricAuthTileTitle = 'Biometric Authentication',
    this.biometricAuthTileSubtitleOn =
        'On - Sign in with fingerprint or face recognition',
    this.biometricAuthTileSubtitleOff = 'Off',
    this.privacyGuardTitle = 'Privacy Guard',
    this.privacyGuardEnabledSubtitle = 'Screen protection enabled',
    this.privacyGuardDisabledSubtitle = 'Screen protection disabled',
    this.screenProtectionTileTitle = 'Screen Protection',
    this.screenProtectionTileSubtitleOn =
        'On - Hide content while app is in background',
    this.screenProtectionTileSubtitleOff = 'Off',
    this.backgroundLockTitle = 'Background Lock',
    this.backgroundLockSubtitlePrefix = 'Locks after: ',
    this.backgroundLockSubtitleOff = 'Off',
    this.backgroundLockTileTitle =
        'Require authentication when app stays in background',
    this.backgroundLockTileSubtitle =
        'To enable background lock, set a PIN or enable biometric login.',
    this.backgroundLockTileInfo =
        'Note: Authentication screen appears when returning to app.',
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
    String? msgCreateAPinFirst,
    String? msgBiometricAuthenticationIsNot,
    String? msgBiometricAuthenticationFailed,
    String? msgBiometricLoginEnabled,
    String? msgBiometricLoginDisabled,
    String? msgPINAlreadyExistsUse,
    String? msgPINsDoNotMatch,
    String? msgPINSavedSuccessfully,
    String? msgNewPinValuesDo,
    String? msgCurrentPinIsIncorrect,
    String? msgPINUpdatedSuccessfully,
    String? msgCurrentPinIsIncorrect2,
    String? msgPINRemoved,
    String? msgBackgroundLockAndPrivacy,
    String? msgPINOrBiometricLogin,
    String? securitySettings,
    String? manageYourAppSecurity,
    String? createPin,
    String? changePin,
    String? removePin,
    String? msgBiometricAuthenticationCannotBe,
    String? msgCreateAPinFirst2,
    String? msgIncorrectPinRemainingTries,
    String? msgPINVerificationFailedE,
    String? pinLockTitle,
    String? pinEnabledSubtitle,
    String? pinNotSetSubtitle,
    String? biometricLoginTitle,
    String? biometricNotAvailableSubtitle,
    String? biometricEnabledSubtitle,
    String? biometricDisabledSubtitle,
    String? biometricAuthTileTitle,
    String? biometricAuthTileSubtitleOn,
    String? biometricAuthTileSubtitleOff,
    String? privacyGuardTitle,
    String? privacyGuardEnabledSubtitle,
    String? privacyGuardDisabledSubtitle,
    String? screenProtectionTileTitle,
    String? screenProtectionTileSubtitleOn,
    String? screenProtectionTileSubtitleOff,
    String? backgroundLockTitle,
    String? backgroundLockSubtitlePrefix,
    String? backgroundLockSubtitleOff,
    String? backgroundLockTileTitle,
    String? backgroundLockTileSubtitle,
    String? backgroundLockTileInfo,
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
      msgCreateAPinFirst: msgCreateAPinFirst ?? this.msgCreateAPinFirst,
      msgBiometricAuthenticationIsNot: msgBiometricAuthenticationIsNot ??
          this.msgBiometricAuthenticationIsNot,
      msgBiometricAuthenticationFailed: msgBiometricAuthenticationFailed ??
          this.msgBiometricAuthenticationFailed,
      msgBiometricLoginEnabled:
          msgBiometricLoginEnabled ?? this.msgBiometricLoginEnabled,
      msgBiometricLoginDisabled:
          msgBiometricLoginDisabled ?? this.msgBiometricLoginDisabled,
      msgPINAlreadyExistsUse:
          msgPINAlreadyExistsUse ?? this.msgPINAlreadyExistsUse,
      msgPINsDoNotMatch: msgPINsDoNotMatch ?? this.msgPINsDoNotMatch,
      msgPINSavedSuccessfully:
          msgPINSavedSuccessfully ?? this.msgPINSavedSuccessfully,
      msgNewPinValuesDo: msgNewPinValuesDo ?? this.msgNewPinValuesDo,
      msgCurrentPinIsIncorrect:
          msgCurrentPinIsIncorrect ?? this.msgCurrentPinIsIncorrect,
      msgPINUpdatedSuccessfully:
          msgPINUpdatedSuccessfully ?? this.msgPINUpdatedSuccessfully,
      msgCurrentPinIsIncorrect2:
          msgCurrentPinIsIncorrect2 ?? this.msgCurrentPinIsIncorrect2,
      msgPINRemoved: msgPINRemoved ?? this.msgPINRemoved,
      msgBackgroundLockAndPrivacy:
          msgBackgroundLockAndPrivacy ?? this.msgBackgroundLockAndPrivacy,
      msgPINOrBiometricLogin:
          msgPINOrBiometricLogin ?? this.msgPINOrBiometricLogin,
      securitySettings: securitySettings ?? this.securitySettings,
      manageYourAppSecurity:
          manageYourAppSecurity ?? this.manageYourAppSecurity,
      createPin: createPin ?? this.createPin,
      changePin: changePin ?? this.changePin,
      removePin: removePin ?? this.removePin,
      msgBiometricAuthenticationCannotBe: msgBiometricAuthenticationCannotBe ??
          this.msgBiometricAuthenticationCannotBe,
      msgCreateAPinFirst2: msgCreateAPinFirst2 ?? this.msgCreateAPinFirst2,
      msgIncorrectPinRemainingTries:
          msgIncorrectPinRemainingTries ?? this.msgIncorrectPinRemainingTries,
      msgPINVerificationFailedE:
          msgPINVerificationFailedE ?? this.msgPINVerificationFailedE,
      pinLockTitle: pinLockTitle ?? this.pinLockTitle,
      pinEnabledSubtitle: pinEnabledSubtitle ?? this.pinEnabledSubtitle,
      pinNotSetSubtitle: pinNotSetSubtitle ?? this.pinNotSetSubtitle,
      biometricLoginTitle: biometricLoginTitle ?? this.biometricLoginTitle,
      biometricNotAvailableSubtitle:
          biometricNotAvailableSubtitle ?? this.biometricNotAvailableSubtitle,
      biometricEnabledSubtitle:
          biometricEnabledSubtitle ?? this.biometricEnabledSubtitle,
      biometricDisabledSubtitle:
          biometricDisabledSubtitle ?? this.biometricDisabledSubtitle,
      biometricAuthTileTitle:
          biometricAuthTileTitle ?? this.biometricAuthTileTitle,
      biometricAuthTileSubtitleOn:
          biometricAuthTileSubtitleOn ?? this.biometricAuthTileSubtitleOn,
      biometricAuthTileSubtitleOff:
          biometricAuthTileSubtitleOff ?? this.biometricAuthTileSubtitleOff,
      privacyGuardTitle: privacyGuardTitle ?? this.privacyGuardTitle,
      privacyGuardEnabledSubtitle:
          privacyGuardEnabledSubtitle ?? this.privacyGuardEnabledSubtitle,
      privacyGuardDisabledSubtitle:
          privacyGuardDisabledSubtitle ?? this.privacyGuardDisabledSubtitle,
      screenProtectionTileTitle:
          screenProtectionTileTitle ?? this.screenProtectionTileTitle,
      screenProtectionTileSubtitleOn:
          screenProtectionTileSubtitleOn ?? this.screenProtectionTileSubtitleOn,
      screenProtectionTileSubtitleOff: screenProtectionTileSubtitleOff ??
          this.screenProtectionTileSubtitleOff,
      backgroundLockTitle: backgroundLockTitle ?? this.backgroundLockTitle,
      backgroundLockSubtitlePrefix:
          backgroundLockSubtitlePrefix ?? this.backgroundLockSubtitlePrefix,
      backgroundLockSubtitleOff:
          backgroundLockSubtitleOff ?? this.backgroundLockSubtitleOff,
      backgroundLockTileTitle:
          backgroundLockTileTitle ?? this.backgroundLockTileTitle,
      backgroundLockTileSubtitle:
          backgroundLockTileSubtitle ?? this.backgroundLockTileSubtitle,
      backgroundLockTileInfo:
          backgroundLockTileInfo ?? this.backgroundLockTileInfo,
    );
  }
}
