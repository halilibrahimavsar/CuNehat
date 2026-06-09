class LocalAuthConstants {
  LocalAuthConstants._();

  static const int pinLength = 6;
  static const int maxFailedAttempts = 3;
  static const int hapticDelayMs = 150;
  static const int shakeAnimationDuration = 500;
  static const int pinDotSize = 20;
  static const double pinDotSpacing = 12.0;
  static const double numpadButtonSize = 75.0;
  static const double numpadSpacing = 20.0;
  static const double pinDotShadowBlurRadius = 10.0;
  static const double pinDotShadowSpreadRadius = 2.0;
  static const double backgroundLockOpacity = 0.55;
  static const int backgroundLockMaxWidth = 320;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);

  static const String pinHashKey = 'local_auth_pin_hash';
  static const String pinSaltKey = 'local_auth_pin_salt';
  static const String biometricEnabledKey = 'local_auth_biometric_enabled';
  static const String privacyGuardEnabledKey =
      'local_auth_privacy_guard_enabled';
  static const String backgroundLockTimeoutKey =
      'local_auth_background_lock_timeout';
  static const String lastBackgroundAtKey = 'local_auth_last_background_at';
  static const String lockoutEndKey = 'local_auth_lockout_end';
  static const String lockoutLevelKey = 'local_auth_lockout_level';

  static const String defaultBiometricReason = 'Authenticate to continue';
  static const String enableBiometricReason = 'Enable biometric login';
  static const String pinLabelText = 'PIN';
  static const String verifyButtonText = 'Verify';
  static const String cancelButtonText = 'Cancel';
  static const String pinDialogTitle = 'PIN Verification';

  // Settings Widget Constants
  static const List<int> defaultTimeoutOptions = [0, 5, 10, 15, 30, 60];
  static const String settingsTitle = 'Security Settings';
  static const String settingsSubtitle = 'Manage your app security';
  static const String pinSectionTitle = 'PIN Lock';
  static const String biometricSectionTitle = 'Biometric Login';
  static const String privacyGuardSectionTitle = 'Privacy Guard';
  static const String backgroundLockSectionTitle = 'Background Lock';
  static const String pinNotSetWarning = 'You must create a PIN first';
  static const String biometricNotAvailable =
      'Biometric authentication is not supported on this device';
  static const String createPinButtonText = 'Create PIN';
  static const String changePinButtonText = 'Change PIN';
  static const String deletePinButtonText = 'Remove PIN';
  static const String createPinDialogTitle = 'Create PIN';
  static const String changePinDialogTitle = 'Change PIN';
  static const String deletePinConfirmTitle = 'Remove PIN';
  static const String deletePinConfirmMessage =
      'Removing PIN will also disable biometric login. Do you want to continue?';
  static const String currentPinLabel = 'Current PIN';
  static const String newPinLabel = 'New PIN';
  static const String confirmPinLabel = 'Confirm PIN';
  static const String pinHint = '******';
  static const String saveButtonText = 'Save';
  static const String changeButtonText = 'Change';
  static const String removeButtonText = 'Remove';
  static const String cancelButtonText2 = 'Cancel';
  static const String pinValidationError = 'Enter a 6-digit PIN';
  static const String pinMatchError = 'PINs do not match';
  static const String privacyGuardEnabledSubtitle = 'Screen protection enabled';
  static const String privacyGuardDisabledSubtitle =
      'Screen protection disabled';
  static const String biometricEnabledSubtitle = 'Biometric login enabled';
  static const String biometricDisabledSubtitle = 'Biometric login disabled';
  static const String biometricSwitchTitle = 'Biometric Authentication';
  static const String biometricEnabledDescription =
      'On - Sign in with fingerprint or face recognition';
  static const String biometricDisabledDescription = 'Off';
  static const String biometricPrerequisiteMessage =
      'Create a PIN first to enable biometric login.';
  static const String privacyGuardSwitchTitle = 'Screen Protection';
  static const String privacyGuardEnabledDescription =
      'On - Hides content while the app is in the background';
  static const String privacyGuardDisabledDescription = 'Off';
  static const String backgroundLockSubtitle =
      'Automatically lock when the app stays in background for a while';
  static const String backgroundLockDisabled = 'Off';
  static const String timeoutChipLabelSuffix = ' sec';

  static const Map<int, int> lockoutDurations = {
    0: 30,
    1: 120,
    2: 300,
    3: 1000,
  };
}
