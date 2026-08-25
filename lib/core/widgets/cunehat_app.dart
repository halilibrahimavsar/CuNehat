import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

/// Main application widget.
///
/// This widget wraps the MaterialApp with security features:
/// - LocalAuthSecurityLayer: Handles privacy guard and background lock
///
/// Kısa mesajlar [appMessengerKey] üzerinden gösterilir (bkz.
/// [AppMessenger]); çağıranların `BuildContext` taşımasına gerek yoktur.
class CuNehatApp extends StatelessWidget {
  final GoRouter router;
  final ThemeData theme;
  final Locale locale;

  const CuNehatApp({
    super.key,
    required this.router,
    required this.theme,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      scaffoldMessengerKey: appMessengerKey,
      themeMode: ThemeMode.light,
      theme: theme,
      locale: locale,
      title: "CuNehat",
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      builder: (context, child) {
        return Builder(
          builder: (childContext) {
            final l10n = AppLocalizations.of(childContext);
            final localAuthTexts = l10n != null
                ? LocalAuthTexts(
                    logoutLabel: l10n.logoutLabel,
                    welcomeTitle: l10n.welcomeTitle,
                    enterPinPrompt: l10n.enterPinPrompt,
                    lockedOutPromptPrefix: l10n.lockedOutPromptPrefix,
                    lockedOutPromptSuffix: l10n.lockedOutPromptSuffix,
                    invalidPinFallback: l10n.invalidPinFallback,
                    biometricReason: l10n.biometricReason,
                    settingsTitle: l10n.settingsTitle,
                    createPinTitle: l10n.createPinTitle,
                    changePinTitle: l10n.changePinTitle,
                    deletePinTitle: l10n.deletePinTitle,
                    verifyPinTitle: l10n.verifyPinTitle,
                    deletePinConfirmMessage: l10n.deletePinConfirmMessage,
                    saveLabel: l10n.saveLabel,
                    changeLabel: l10n.changeLabel,
                    removeLabel: l10n.removeLabel,
                    cancelLabel: l10n.cancelLabel,
                    pinMismatchMessage: l10n.pinMismatchMessage,
                    pinValidationMessage: l10n.pinValidationMessage,
                    msgCreateAPinFirst: l10n.msgCreateAPinFirst,
                    msgBiometricAuthenticationIsNot:
                        l10n.msgBiometricAuthenticationIsNot,
                    msgBiometricAuthenticationFailed:
                        l10n.msgBiometricAuthenticationFailed,
                    msgBiometricLoginEnabled: l10n.msgBiometricLoginEnabled,
                    msgBiometricLoginDisabled: l10n.msgBiometricLoginDisabled,
                    msgPINAlreadyExistsUse: l10n.msgPINAlreadyExistsUse,
                    msgPINsDoNotMatch: l10n.msgPINsDoNotMatch,
                    msgPINSavedSuccessfully: l10n.msgPINSavedSuccessfully,
                    msgNewPinValuesDo: l10n.msgNewPinValuesDo,
                    msgCurrentPinIsIncorrect: l10n.msgCurrentPinIsIncorrect,
                    msgPINUpdatedSuccessfully: l10n.msgPINUpdatedSuccessfully,
                    msgCurrentPinIsIncorrect2: l10n.msgCurrentPinIsIncorrect,
                    msgPINRemoved: l10n.msgPINRemoved,
                    msgBackgroundLockAndPrivacy:
                        l10n.msgBackgroundLockAndPrivacy,
                    securitySettings: l10n.securitySettings,
                    manageYourAppSecurity: l10n.manageYourAppSecurity,
                    createPin: l10n.createPin,
                    changePin: l10n.changePin,
                    removePin: l10n.removePin,
                    msgBiometricAuthenticationCannotBe:
                        l10n.msgBiometricAuthenticationCannotBe,
                    msgCreateAPinFirst2: l10n.msgCreateAPinFirst2,
                    msgIncorrectPinRemainingTries:
                        l10n.msgIncorrectPinRemainingTries('{tries}'),
                    msgPINVerificationFailedE:
                        l10n.msgPINVerificationFailedE('{error}'),
                    pinLockTitle: l10n.pinLockTitle,
                    pinEnabledSubtitle: l10n.pinEnabledSubtitle,
                    pinNotSetSubtitle: l10n.pinNotSetSubtitle,
                    biometricLoginTitle: l10n.biometricLoginTitle,
                    biometricNotAvailableSubtitle:
                        l10n.biometricNotAvailableSubtitle,
                    biometricEnabledSubtitle: l10n.biometricEnabledSubtitle,
                    biometricDisabledSubtitle: l10n.biometricDisabledSubtitle,
                    biometricAuthTileTitle: l10n.biometricAuthTileTitle,
                    biometricAuthTileSubtitleOn:
                        l10n.biometricAuthTileSubtitleOn,
                    biometricAuthTileSubtitleOff:
                        l10n.biometricAuthTileSubtitleOff,
                    stateOnLabel: l10n.stateOnLabel,
                    stateOffLabel: l10n.stateOffLabel,
                    stateUnsupportedLabel: l10n.stateUnsupportedLabel,
                    methodBiometricLabel: l10n.methodBiometricLabel,
                    methodGenericLabel: l10n.methodGenericLabel,
                    unitSecondsLabel: l10n.unitSecondsLabel,
                    unitMinutesLabel: l10n.unitMinutesLabel,
                    privacyGuardTitle: l10n.privacyGuardTitle,
                    privacyGuardEnabledSubtitle:
                        l10n.privacyGuardEnabledSubtitle,
                    privacyGuardDisabledSubtitle:
                        l10n.privacyGuardDisabledSubtitle,
                    screenProtectionTileTitle: l10n.screenProtectionTileTitle,
                    screenProtectionTileSubtitleOn:
                        l10n.screenProtectionTileSubtitleOn,
                    screenProtectionTileSubtitleOff:
                        l10n.screenProtectionTileSubtitleOff,
                    backgroundLockTitle: l10n.backgroundLockTitle,
                    backgroundLockSubtitlePrefix:
                        l10n.backgroundLockSubtitlePrefix,
                    backgroundLockSubtitleOff: l10n.backgroundLockSubtitleOff,
                    backgroundLockTileTitle: l10n.backgroundLockTileTitle,
                    backgroundLockTileSubtitle: l10n.backgroundLockTileSubtitle,
                    backgroundLockTileInfo: l10n.backgroundLockTileInfo,
                  )
                : const LocalAuthTexts();

            return LocalAuthSecurityLayer(
              repository: getIt<LocalAuthRepository>(),
              texts: localAuthTexts,
              child: child!,
            );
          },
        );
      },
    );
  }
}
