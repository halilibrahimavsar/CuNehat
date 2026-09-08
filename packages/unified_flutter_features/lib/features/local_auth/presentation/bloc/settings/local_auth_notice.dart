/// Ayar bloc'unun yaydığı SONUÇ.
///
/// Bloc metin yaymaz: metin çağıran katmanın dilinde çözülür. Önceden
/// mesajlar İngilizce dize olarak yayılıyor ve tüketici tarafta
/// `if (msg == 'PIN removed')` gibi kırılgan bir eşleştirmeyle
/// yerelleştiriliyordu — eşleşmeyen her dize (ör. "Privacy Guard enabled")
/// kullanıcıya İngilizce çıkıyordu.
enum LocalAuthNotice {
  pinCreated,
  pinUpdated,
  pinRemoved,
  pinAlreadyExists,
  pinsDoNotMatch,
  newPinsDoNotMatch,
  currentPinIncorrect,
  createPinFirst,
  biometricNotSupported,
  biometricFailed,
  biometricEnabled,
  biometricDisabled,
  privacyGuardEnabled,
  privacyGuardDisabled,

  /// Arka plan kilidi için önce PIN ya da biyometrik gerekiyor.
  backgroundLockNeedsAuth,

  /// Arka plan kilidi açıldı ve gizlilik perdesi de birlikte açıldı.
  backgroundLockWithPrivacyGuard,
  backgroundLockUpdated,
  backgroundLockDisabled,

  /// Beklenmeyen hata; ayrıntısı `state.message` içinde.
  unexpectedError,
}
