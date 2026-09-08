import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:cunehat/features/settings/presentation/bloc/pin_recovery/pin_recovery_cubit.dart';
import 'package:unified_flutter_features/features/local_auth/local_auth.dart';

/// Bloc'un tipli sonucunu kullanıcının diline çevirir.
///
/// Bloc metin yaymaz: eskiden İngilizce dize yayıyor, arayüz de
/// `if (msg == 'PIN removed')` diye eşleştiriyordu — sözlükte karşılığı
/// olmayan her mesaj (gizlilik perdesi, arka plan kilidi) İngilizce çıkıyordu.
String? localAuthNoticeText(
  AppLocalizations l10n,
  LocalAuthNotice? notice,
  String? detail,
) {
  switch (notice) {
    case null:
      return null;
    case LocalAuthNotice.pinCreated:
      return l10n.msgPINSavedSuccessfully;
    case LocalAuthNotice.pinUpdated:
      return l10n.msgPINUpdatedSuccessfully;
    case LocalAuthNotice.pinRemoved:
      return l10n.msgPINRemoved;
    case LocalAuthNotice.pinAlreadyExists:
      return l10n.msgPINAlreadyExistsUse;
    case LocalAuthNotice.pinsDoNotMatch:
      return l10n.msgPINsDoNotMatch;
    case LocalAuthNotice.newPinsDoNotMatch:
      return l10n.msgNewPinValuesDo;
    case LocalAuthNotice.currentPinIncorrect:
      return l10n.msgCurrentPinIsIncorrect;
    case LocalAuthNotice.createPinFirst:
      return l10n.msgCreateAPinFirst;
    case LocalAuthNotice.biometricNotSupported:
      return l10n.msgBiometricAuthenticationIsNot;
    case LocalAuthNotice.biometricFailed:
      return l10n.msgBiometricAuthenticationFailed;
    case LocalAuthNotice.biometricEnabled:
      return l10n.msgBiometricLoginEnabled;
    case LocalAuthNotice.biometricDisabled:
      return l10n.msgBiometricLoginDisabled;
    case LocalAuthNotice.privacyGuardEnabled:
      return l10n.msgPrivacyGuardEnabled;
    case LocalAuthNotice.privacyGuardDisabled:
      return l10n.msgPrivacyGuardDisabled;
    case LocalAuthNotice.backgroundLockNeedsAuth:
      return l10n.msgPINOrBiometricLogin;
    case LocalAuthNotice.backgroundLockWithPrivacyGuard:
      return l10n.msgBackgroundLockAndPrivacy;
    case LocalAuthNotice.backgroundLockUpdated:
      return l10n.msgBackgroundLockUpdated;
    case LocalAuthNotice.backgroundLockDisabled:
      return l10n.msgBackgroundLockDisabled;
    case LocalAuthNotice.unexpectedError:
      return detail ?? l10n.recoveryUnexpectedError;
  }
}

/// Kurtarma akışının tipli sonucunu çevirir.
String? pinRecoveryNoticeText(
  AppLocalizations l10n,
  PinRecoveryNotice? notice,
) {
  switch (notice) {
    case null:
      return null;
    case PinRecoveryNotice.deviceVerificationFailed:
      return l10n.recoveryDeviceFailed;
    case PinRecoveryNotice.deviceCredentialUnavailable:
      return l10n.recoveryDeviceUnavailable;
    case PinRecoveryNotice.timedResetStarted:
      return l10n.recoveryTimedStarted;
    case PinRecoveryNotice.timedResetCancelled:
      return l10n.recoveryTimedCancelled;
    case PinRecoveryNotice.pinReset:
      return l10n.recoveryResetDone;
    case PinRecoveryNotice.unexpectedError:
      return l10n.recoveryUnexpectedError;
  }
}

/// Saniye cinsinden süreyi kısa biçimde yazar ("30 sn", "1 dk").
String formatLockDuration(AppLocalizations l10n, int seconds) {
  if (seconds < 60) return l10n.durationSecondsShort(seconds);
  return l10n.durationMinutesShort(seconds ~/ 60);
}
