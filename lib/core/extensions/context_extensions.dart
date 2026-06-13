import 'package:flutter/widgets.dart';
import 'package:cunehat/core/l10n/app_localizations.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// Extension to provide easy access to localized strings via context.l10n.
extension LocalizationX on BuildContext {
  /// Resolves the nearest AppLocalizations instance in the widget tree.
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Builds a localized LocalAuthTexts model.
  LocalAuthTexts get localAuthTexts {
    final l = l10n;
    return LocalAuthTexts(
      logoutLabel: l.logoutLabel,
      welcomeTitle: l.welcomeTitle,
      enterPinPrompt: l.enterPinPrompt,
      lockedOutPromptPrefix: l.lockedOutPromptPrefix,
      lockedOutPromptSuffix: l.lockedOutPromptSuffix,
      invalidPinFallback: l.invalidPinFallback,
      biometricReason: l.biometricReason,
      settingsTitle: l.settingsTitle,
      createPinTitle: l.createPinTitle,
      changePinTitle: l.changePinTitle,
      deletePinTitle: l.deletePinTitle,
      verifyPinTitle: l.verifyPinTitle,
      deletePinConfirmMessage: l.deletePinConfirmMessage,
      saveLabel: l.saveLabel,
      changeLabel: l.changeLabel,
      removeLabel: l.removeLabel,
      cancelLabel: l.cancelLabel,
      pinMismatchMessage: l.pinMismatchMessage,
      pinValidationMessage: l.pinValidationMessage,
      msgCreateAPinFirst: l.msgCreateAPinFirst,
      msgBiometricAuthenticationIsNot: l.msgBiometricAuthenticationIsNot,
      msgBiometricAuthenticationFailed: l.msgBiometricAuthenticationFailed,
      msgBiometricLoginEnabled: l.msgBiometricLoginEnabled,
      msgBiometricLoginDisabled: l.msgBiometricLoginDisabled,
      msgPINAlreadyExistsUse: l.msgPINAlreadyExistsUse,
      msgPINsDoNotMatch: l.msgPINsDoNotMatch,
      msgPINSavedSuccessfully: l.msgPINSavedSuccessfully,
      msgNewPinValuesDo: l.msgNewPinValuesDo,
      msgCurrentPinIsIncorrect: l.msgCurrentPinIsIncorrect,
      msgPINUpdatedSuccessfully: l.msgPINUpdatedSuccessfully,
      msgPINRemoved: l.msgPINRemoved,
      msgBackgroundLockAndPrivacy: l.msgBackgroundLockAndPrivacy,
      securitySettings: l.securitySettings,
      manageYourAppSecurity: l.manageYourAppSecurity,
      createPin: l.createPin,
      changePin: l.changePin,
      removePin: l.removePin,
      msgBiometricAuthenticationCannotBe: l.msgBiometricAuthenticationCannotBe,
      msgCreateAPinFirst2: l.msgCreateAPinFirst2,
      msgIncorrectPinRemainingTries: l.msgIncorrectPinRemainingTries('{tries}'),
      msgPINVerificationFailedE: l.msgPINVerificationFailedE('{error}'),
      pinLockTitle: l.pinLockTitle,
      pinEnabledSubtitle: l.pinEnabledSubtitle,
      pinNotSetSubtitle: l.pinNotSetSubtitle,
      biometricLoginTitle: l.biometricLoginTitle,
      biometricNotAvailableSubtitle: l.biometricNotAvailableSubtitle,
      biometricEnabledSubtitle: l.biometricEnabledSubtitle,
      biometricDisabledSubtitle: l.biometricDisabledSubtitle,
      biometricAuthTileTitle: l.biometricAuthTileTitle,
      biometricAuthTileSubtitleOn: l.biometricAuthTileSubtitleOn,
      biometricAuthTileSubtitleOff: l.biometricAuthTileSubtitleOff,
      privacyGuardTitle: l.privacyGuardTitle,
      privacyGuardEnabledSubtitle: l.privacyGuardEnabledSubtitle,
      privacyGuardDisabledSubtitle: l.privacyGuardDisabledSubtitle,
      screenProtectionTileTitle: l.screenProtectionTileTitle,
      screenProtectionTileSubtitleOn: l.screenProtectionTileSubtitleOn,
      screenProtectionTileSubtitleOff: l.screenProtectionTileSubtitleOff,
      backgroundLockTitle: l.backgroundLockTitle,
      backgroundLockSubtitlePrefix: l.backgroundLockSubtitlePrefix,
      backgroundLockSubtitleOff: l.backgroundLockSubtitleOff,
      backgroundLockTileTitle: l.backgroundLockTileTitle,
      backgroundLockTileSubtitle: l.backgroundLockTileSubtitle,
      backgroundLockTileInfo: l.backgroundLockTileInfo,
    );
  }

  /// Builds a localized SliderTexts model.
  SliderTexts get sliderTexts {
    final l = l10n;
    return SliderTexts(
      savings: l.sliderSavings,
      transactions: l.sliderTransactions,
      debt: l.sliderDebt,
    );
  }

  /// Translates icon categories
  String translateIconCategory(String categoryName) {
    switch (categoryName) {
      case 'Finans':
        return l10n.categoryFinans;
      case 'Grafikler':
        return l10n.categoryGrafikler;
      case 'İş & Ofis':
        return l10n.categoryIsVeOfis;
      case 'Alışveriş':
        return l10n.categoryAlisveris;
      case 'Yemek & İçecek':
        return l10n.categoryYemekVeIcecek;
      case 'Ulaşım':
        return l10n.categoryUlasim;
      case 'Ev & Yaşam':
        return l10n.categoryEvVeYasam;
      case 'Eğlence':
        return l10n.categoryEglence;
      case 'Sağlık & Spor':
        return l10n.categorySaglikVeSpor;
      case 'Eğitim':
        return l10n.categoryEgitim;
      case 'Kişisel Bakım':
        return l10n.categoryKisiselBakim;
      case 'Hayvanlar':
        return l10n.categoryHayvanlar;
      case 'Seyahat':
        return l10n.categorySeyahat;
      case 'Teknoloji':
        return l10n.categoryTeknoloji;
      case 'İletişim':
        return l10n.categoryIletisim;
      case 'Hediye & Bağış':
        return l10n.categoryHediyeVeBagis;
      case 'Hizmetler':
        return l10n.categoryHizmetler;
      case 'Diğer':
        return l10n.categoryDiger;
      default:
        return categoryName;
    }
  }

  /// Translates default transaction categories
  String translateCategory(String categoryName) {
    switch (categoryName) {
      case 'Yemek':
        return l10n.defaultCategoryFood;
      case 'Ulaşım':
        return l10n.defaultCategoryTransport;
      case 'Alışveriş':
        return l10n.defaultCategoryShopping;
      case 'Fatura':
        return l10n.defaultCategoryBills;
      case 'Eğlence':
        return l10n.defaultCategoryEntertainment;
      case 'Maaş':
        return l10n.defaultCategorySalary;
      case 'Yatırım':
        return l10n.defaultCategoryInvestment;
      case 'Serbest':
        return l10n.defaultCategoryFreelance;
      default:
        return categoryName;
    }
  }
}
