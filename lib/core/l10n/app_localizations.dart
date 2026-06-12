import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get english;

  /// No description provided for @hataDetayi.
  ///
  /// In tr, this message translates to:
  /// **'Hata detayı'**
  String get hataDetayi;

  /// No description provided for @tekrarDene.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get tekrarDene;

  /// No description provided for @islemGecmisiCsv.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Geçmişi (CSV)'**
  String get islemGecmisiCsv;

  /// No description provided for @duzenle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get duzenle;

  /// No description provided for @sil.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get sil;

  /// No description provided for @hintIkonAra.
  ///
  /// In tr, this message translates to:
  /// **'İkon ara...'**
  String get hintIkonAra;

  /// No description provided for @hataStateFailureMessage.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {message}'**
  String hataStateFailureMessage(Object message);

  /// No description provided for @yeniButceEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bütçe Ekle'**
  String get yeniButceEkle;

  /// No description provided for @labelKategori.
  ///
  /// In tr, this message translates to:
  /// **'Kategori'**
  String get labelKategori;

  /// No description provided for @labelAylikLimit.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Limit'**
  String get labelAylikLimit;

  /// No description provided for @iptal.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get iptal;

  /// No description provided for @borclarim.
  ///
  /// In tr, this message translates to:
  /// **'Borçlarım'**
  String get borclarim;

  /// No description provided for @alacaklarim.
  ///
  /// In tr, this message translates to:
  /// **'Alacaklarım'**
  String get alacaklarim;

  /// No description provided for @henuzBorcKaydiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz borç kaydı yok.'**
  String get henuzBorcKaydiYok;

  /// No description provided for @odemeYap.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Yap'**
  String get odemeYap;

  /// No description provided for @ode.
  ///
  /// In tr, this message translates to:
  /// **'Öde'**
  String get ode;

  /// No description provided for @henuzAlacakKaydiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz alacak kaydı yok.'**
  String get henuzAlacakKaydiYok;

  /// No description provided for @odendiIsaretle.
  ///
  /// In tr, this message translates to:
  /// **'Ödendi İşaretle'**
  String get odendiIsaretle;

  /// No description provided for @gecmis.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get gecmis;

  /// No description provided for @borcGecmisi.
  ///
  /// In tr, this message translates to:
  /// **'Borç Geçmişi'**
  String get borcGecmisi;

  /// No description provided for @alacakGecmisi.
  ///
  /// In tr, this message translates to:
  /// **'Alacak Geçmişi'**
  String get alacakGecmisi;

  /// No description provided for @aylikTaksitiBiliyorum.
  ///
  /// In tr, this message translates to:
  /// **'Aylık taksiti biliyorum'**
  String get aylikTaksitiBiliyorum;

  /// No description provided for @faizOraniIle.
  ///
  /// In tr, this message translates to:
  /// **'Faiz oranı ile'**
  String get faizOraniIle;

  /// No description provided for @esitTaksitAmortisman.
  ///
  /// In tr, this message translates to:
  /// **'Eşit Taksit (Amortisman)'**
  String get esitTaksitAmortisman;

  /// No description provided for @basitVadeFarki.
  ///
  /// In tr, this message translates to:
  /// **'Basit Vade Farkı'**
  String get basitVadeFarki;

  /// No description provided for @odemeyiKaydet.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeyi Kaydet'**
  String get odemeyiKaydet;

  /// No description provided for @labelOdemeTutari.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Tutarı *'**
  String get labelOdemeTutari;

  /// No description provided for @maksimumFormatmoneyRemaining.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum: {remaining}'**
  String maksimumFormatmoneyRemaining(Object remaining);

  /// No description provided for @labelOdemeTarihi.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Tarihi'**
  String get labelOdemeTarihi;

  /// No description provided for @labelNotOpsiyonel.
  ///
  /// In tr, this message translates to:
  /// **'Not (Opsiyonel)'**
  String get labelNotOpsiyonel;

  /// No description provided for @hintOdemeIleIlgiliNotlar.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme ile ilgili notlar...'**
  String get hintOdemeIleIlgiliNotlar;

  /// No description provided for @islemDetayi.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Detayı'**
  String get islemDetayi;

  /// No description provided for @bekleyenIslemler.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen İşlemler'**
  String get bekleyenIslemler;

  /// No description provided for @islemRaporu.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Raporu'**
  String get islemRaporu;

  /// No description provided for @tooltipTarihAraligi.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Aralığı'**
  String get tooltipTarihAraligi;

  /// No description provided for @msgSecilenTarihAraligindaIslem.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen tarih aralığında işlem yok'**
  String get msgSecilenTarihAraligindaIslem;

  /// No description provided for @degistir.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get degistir;

  /// No description provided for @labelKategoriAdi.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Adı'**
  String get labelKategoriAdi;

  /// No description provided for @hintOrnMarketKiraMaas.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Market, Kira, Maaş'**
  String get hintOrnMarketKiraMaas;

  /// No description provided for @ozelKategoriler.
  ///
  /// In tr, this message translates to:
  /// **'Özel Kategoriler'**
  String get ozelKategoriler;

  /// No description provided for @varsayilanKategoriler.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan Kategoriler'**
  String get varsayilanKategoriler;

  /// No description provided for @yeniKategoriEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kategori Ekle'**
  String get yeniKategoriEkle;

  /// No description provided for @temizle.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get temizle;

  /// No description provided for @labelMin.
  ///
  /// In tr, this message translates to:
  /// **'Min'**
  String get labelMin;

  /// No description provided for @labelMax.
  ///
  /// In tr, this message translates to:
  /// **'Max'**
  String get labelMax;

  /// No description provided for @hintNotIstegeBagliOrn.
  ///
  /// In tr, this message translates to:
  /// **'Not (İsteğe bağlı) · örn. Market alışverişi'**
  String get hintNotIstegeBagliOrn;

  /// No description provided for @tekrarlamaIstegeBagli.
  ///
  /// In tr, this message translates to:
  /// **'Tekrarlama (İsteğe Bağlı)'**
  String get tekrarlamaIstegeBagli;

  /// No description provided for @tekrarEtme.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Etme'**
  String get tekrarEtme;

  /// No description provided for @birikimDetayi.
  ///
  /// In tr, this message translates to:
  /// **'Birikim Detayı'**
  String get birikimDetayi;

  /// No description provided for @vazgec.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get vazgec;

  /// No description provided for @sat.
  ///
  /// In tr, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @kaydiSil.
  ///
  /// In tr, this message translates to:
  /// **'Kaydı Sil'**
  String get kaydiSil;

  /// No description provided for @tooltipFiyatlariGuncelle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatları Güncelle'**
  String get tooltipFiyatlariGuncelle;

  /// No description provided for @hintSembolOrnAaplThyao.
  ///
  /// In tr, this message translates to:
  /// **'Sembol (Örn: AAPL, THYAO.IS)'**
  String get hintSembolOrnAaplThyao;

  /// No description provided for @sablonuSil.
  ///
  /// In tr, this message translates to:
  /// **'Şablonu Sil'**
  String get sablonuSil;

  /// No description provided for @hataError.
  ///
  /// In tr, this message translates to:
  /// **'Hata: {error}'**
  String hataError(Object error);

  /// No description provided for @tooltipBuVadeyiAtla.
  ///
  /// In tr, this message translates to:
  /// **'Bu vadeyi atla'**
  String get tooltipBuVadeyiAtla;

  /// No description provided for @onayla.
  ///
  /// In tr, this message translates to:
  /// **'Onayla'**
  String get onayla;

  /// No description provided for @kapat.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get kapat;

  /// No description provided for @islemiDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'İşlemi Düzenle'**
  String get islemiDuzenle;

  /// No description provided for @labelYeniTutar.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Tutar'**
  String get labelYeniTutar;

  /// No description provided for @kaydetVeOnayla.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet ve Onayla'**
  String get kaydetVeOnayla;

  /// No description provided for @guvenlikAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Ayarları'**
  String get guvenlikAyarlari;

  /// No description provided for @iceAktarCsv.
  ///
  /// In tr, this message translates to:
  /// **'İçe Aktar (CSV)'**
  String get iceAktarCsv;

  /// No description provided for @disaAktarCsv.
  ///
  /// In tr, this message translates to:
  /// **'Dışa Aktar (CSV)'**
  String get disaAktarCsv;

  /// No description provided for @geriYukle.
  ///
  /// In tr, this message translates to:
  /// **'Geri Yükle'**
  String get geriYukle;

  /// No description provided for @yedekle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekle'**
  String get yedekle;

  /// No description provided for @labelUygulamaTemasi.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Teması'**
  String get labelUygulamaTemasi;

  /// No description provided for @labelCuzdanAdi.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Adı *'**
  String get labelCuzdanAdi;

  /// No description provided for @hintOrnAnaCuzdanTatil.
  ///
  /// In tr, this message translates to:
  /// **'Örn: Ana Cüzdan, Tatil Fonu'**
  String get hintOrnAnaCuzdanTatil;

  /// No description provided for @tamam.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get tamam;

  /// No description provided for @beklenmeyenDurum.
  ///
  /// In tr, this message translates to:
  /// **'Beklenmeyen durum'**
  String get beklenmeyenDurum;

  /// No description provided for @aktifCuzdaniniziDegistirmekIcin.
  ///
  /// In tr, this message translates to:
  /// **'• Aktif cüzdanınızı değiştirmek için bir cüzdana tıklayın.'**
  String get aktifCuzdaniniziDegistirmekIcin;

  /// No description provided for @cuzdanBakiyeleriOtomatikOlarak.
  ///
  /// In tr, this message translates to:
  /// **'• Cüzdan bakiyeleri otomatik olarak güncellenir.'**
  String get cuzdanBakiyeleriOtomatikOlarak;

  /// No description provided for @herCuzdaninKendiGelir.
  ///
  /// In tr, this message translates to:
  /// **'• Her cüzdanın kendi gelir/gider kayıtları vardır.'**
  String get herCuzdaninKendiGelir;

  /// No description provided for @msgTextsCheckfailedprefixETostring.
  ///
  /// In tr, this message translates to:
  /// **'{checkFailedPrefix}: {error}'**
  String msgTextsCheckfailedprefixETostring(Object checkFailedPrefix, Object error);

  /// No description provided for @msgPINVerificationFailedE.
  ///
  /// In tr, this message translates to:
  /// **'PIN doğrulama başarısız: {error}'**
  String msgPINVerificationFailedE(Object error);

  /// No description provided for @msgCreateAPinFirst.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir PIN oluşturun'**
  String get msgCreateAPinFirst;

  /// No description provided for @msgBiometricAuthenticationIsNot.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik kimlik doğrulama desteklenmiyor'**
  String get msgBiometricAuthenticationIsNot;

  /// No description provided for @msgBiometricAuthenticationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik kimlik doğrulama başarısız'**
  String get msgBiometricAuthenticationFailed;

  /// No description provided for @msgBiometricLoginEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş etkinleştirildi'**
  String get msgBiometricLoginEnabled;

  /// No description provided for @msgBiometricLoginDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş devre dışı bırakıldı'**
  String get msgBiometricLoginDisabled;

  /// No description provided for @msgPINAlreadyExistsUse.
  ///
  /// In tr, this message translates to:
  /// **'PIN zaten mevcut, bunun yerine PIN değiştirmeyi kullanın'**
  String get msgPINAlreadyExistsUse;

  /// No description provided for @msgPINsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'ler eşleşmiyor'**
  String get msgPINsDoNotMatch;

  /// No description provided for @msgPINSavedSuccessfully.
  ///
  /// In tr, this message translates to:
  /// **'PIN başarıyla kaydedildi'**
  String get msgPINSavedSuccessfully;

  /// No description provided for @msgNewPinValuesDo.
  ///
  /// In tr, this message translates to:
  /// **'Yeni PIN değerleri eşleşmiyor'**
  String get msgNewPinValuesDo;

  /// No description provided for @msgCurrentPinIsIncorrect.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut PIN hatalı'**
  String get msgCurrentPinIsIncorrect;

  /// No description provided for @msgPINUpdatedSuccessfully.
  ///
  /// In tr, this message translates to:
  /// **'PIN başarıyla güncellendi'**
  String get msgPINUpdatedSuccessfully;

  /// No description provided for @msgPINRemoved.
  ///
  /// In tr, this message translates to:
  /// **'PIN kaldırıldı'**
  String get msgPINRemoved;

  /// No description provided for @msgBackgroundLockAndPrivacy.
  ///
  /// In tr, this message translates to:
  /// **'Arka plan kilidi ve Ekran Koruması etkinleştirildi'**
  String get msgBackgroundLockAndPrivacy;

  /// No description provided for @securitySettings.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Ayarları'**
  String get securitySettings;

  /// No description provided for @manageYourAppSecurity.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama güvenliğinizi yönetin'**
  String get manageYourAppSecurity;

  /// No description provided for @createPin.
  ///
  /// In tr, this message translates to:
  /// **'PIN Oluştur'**
  String get createPin;

  /// No description provided for @changePin.
  ///
  /// In tr, this message translates to:
  /// **'PIN Değiştir'**
  String get changePin;

  /// No description provided for @removePin.
  ///
  /// In tr, this message translates to:
  /// **'PIN Kaldır'**
  String get removePin;

  /// No description provided for @msgBiometricAuthenticationCannotBe.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik kimlik doğrulama bu cihazda kullanılamaz.'**
  String get msgBiometricAuthenticationCannotBe;

  /// No description provided for @msgCreateAPinFirst2.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik girişi etkinleştirmek için önce bir PIN oluşturun.'**
  String get msgCreateAPinFirst2;

  /// No description provided for @unifiedFeaturesDemo.
  ///
  /// In tr, this message translates to:
  /// **'Birleşik Özellikler Demosu'**
  String get unifiedFeaturesDemo;

  /// No description provided for @tarihSec.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Seç'**
  String get tarihSec;

  /// No description provided for @dialog.
  ///
  /// In tr, this message translates to:
  /// **'Dialog'**
  String get dialog;

  /// No description provided for @metinGiris.
  ///
  /// In tr, this message translates to:
  /// **'Metin Giriş'**
  String get metinGiris;

  /// No description provided for @yukle.
  ///
  /// In tr, this message translates to:
  /// **'Yükle'**
  String get yukle;

  /// No description provided for @basarili.
  ///
  /// In tr, this message translates to:
  /// **'Başarılı'**
  String get basarili;

  /// No description provided for @hata.
  ///
  /// In tr, this message translates to:
  /// **'Hata'**
  String get hata;

  /// No description provided for @yuklemeButonu.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme Butonu'**
  String get yuklemeButonu;

  /// No description provided for @onayDialog.
  ///
  /// In tr, this message translates to:
  /// **'Onay Dialog'**
  String get onayDialog;

  /// No description provided for @logoutLabel.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logoutLabel;

  /// No description provided for @welcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hoş Geldiniz'**
  String get welcomeTitle;

  /// No description provided for @enterPinPrompt.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için PIN girin'**
  String get enterPinPrompt;

  /// No description provided for @lockedOutPromptPrefix.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla başarısız deneme. Lütfen'**
  String get lockedOutPromptPrefix;

  /// No description provided for @lockedOutPromptSuffix.
  ///
  /// In tr, this message translates to:
  /// **'saniye bekleyin.'**
  String get lockedOutPromptSuffix;

  /// No description provided for @invalidPinFallback.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı PIN, tekrar deneyin.'**
  String get invalidPinFallback;

  /// No description provided for @biometricReason.
  ///
  /// In tr, this message translates to:
  /// **'Devam etmek için kimliğinizi doğrulayın'**
  String get biometricReason;

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik Ayarları'**
  String get settingsTitle;

  /// No description provided for @createPinTitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN Oluştur'**
  String get createPinTitle;

  /// No description provided for @changePinTitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN Değiştir'**
  String get changePinTitle;

  /// No description provided for @deletePinTitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN Kaldır'**
  String get deletePinTitle;

  /// No description provided for @verifyPinTitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN Doğrula'**
  String get verifyPinTitle;

  /// No description provided for @deletePinConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'PIN kaldırma biyometrik girişi de devre dışı bırakır. Devam edilsin mi?'**
  String get deletePinConfirmMessage;

  /// No description provided for @saveLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get saveLabel;

  /// No description provided for @changeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get changeLabel;

  /// No description provided for @removeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get removeLabel;

  /// No description provided for @cancelLabel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancelLabel;

  /// No description provided for @pinMismatchMessage.
  ///
  /// In tr, this message translates to:
  /// **'PIN\'ler eşleşmiyor'**
  String get pinMismatchMessage;

  /// No description provided for @pinValidationMessage.
  ///
  /// In tr, this message translates to:
  /// **'6 haneli bir PIN girin'**
  String get pinValidationMessage;

  /// No description provided for @pinLockTitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN Kilidi'**
  String get pinLockTitle;

  /// No description provided for @pinEnabledSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN etkin'**
  String get pinEnabledSubtitle;

  /// No description provided for @pinNotSetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PIN ayarlanmamış'**
  String get pinNotSetSubtitle;

  /// No description provided for @biometricLoginTitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik Giriş'**
  String get biometricLoginTitle;

  /// No description provided for @biometricNotAvailableSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik kimlik doğrulama bu cihazda kullanılamaz'**
  String get biometricNotAvailableSubtitle;

  /// No description provided for @biometricEnabledSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş etkin'**
  String get biometricEnabledSubtitle;

  /// No description provided for @biometricDisabledSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik giriş devre dışı'**
  String get biometricDisabledSubtitle;

  /// No description provided for @biometricAuthTileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Biyometrik Kimlik Doğrulama'**
  String get biometricAuthTileTitle;

  /// No description provided for @biometricAuthTileSubtitleOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık - Parmak izi veya yüz tanıma ile giriş yapın'**
  String get biometricAuthTileSubtitleOn;

  /// No description provided for @biometricAuthTileSubtitleOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get biometricAuthTileSubtitleOff;

  /// No description provided for @privacyGuardTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Koruması'**
  String get privacyGuardTitle;

  /// No description provided for @privacyGuardEnabledSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekran koruması etkin'**
  String get privacyGuardEnabledSubtitle;

  /// No description provided for @privacyGuardDisabledSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekran koruması devre dışı'**
  String get privacyGuardDisabledSubtitle;

  /// No description provided for @screenProtectionTileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ekran Koruması'**
  String get screenProtectionTileTitle;

  /// No description provided for @screenProtectionTileSubtitleOn.
  ///
  /// In tr, this message translates to:
  /// **'Açık - Uygulama arka plandayken içeriği gizle'**
  String get screenProtectionTileSubtitleOn;

  /// No description provided for @screenProtectionTileSubtitleOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get screenProtectionTileSubtitleOff;

  /// No description provided for @backgroundLockTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka Plan Kilidi'**
  String get backgroundLockTitle;

  /// No description provided for @backgroundLockSubtitlePrefix.
  ///
  /// In tr, this message translates to:
  /// **'Şu süre sonunda kilitler: '**
  String get backgroundLockSubtitlePrefix;

  /// No description provided for @backgroundLockSubtitleOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get backgroundLockSubtitleOff;

  /// No description provided for @backgroundLockTileTitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama arka planda kaldığında kimlik doğrulama gerektir'**
  String get backgroundLockTileTitle;

  /// No description provided for @backgroundLockTileSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Arka plan kilidini etkinleştirmek için bir PIN ayarlayın veya biyometrik girişi açın.'**
  String get backgroundLockTileSubtitle;

  /// No description provided for @backgroundLockTileInfo.
  ///
  /// In tr, this message translates to:
  /// **'Not: Uygulamaya dönerken kimlik doğrulama ekranı görünür.'**
  String get backgroundLockTileInfo;

  /// No description provided for @msgIncorrectPinRemainingTries.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı PIN. Kalan deneme: {newAttempts}'**
  String msgIncorrectPinRemainingTries(Object newAttempts);

  /// No description provided for @settings.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In tr, this message translates to:
  /// **'GÖRÜNÜM'**
  String get appearance;

  /// No description provided for @security.
  ///
  /// In tr, this message translates to:
  /// **'GÜVENLİK'**
  String get security;

  /// No description provided for @dataBackupTransfer.
  ///
  /// In tr, this message translates to:
  /// **'VERİ YEDEKLEME / AKTARIM'**
  String get dataBackupTransfer;

  /// No description provided for @about.
  ///
  /// In tr, this message translates to:
  /// **'HAKKINDA'**
  String get about;

  /// No description provided for @googleDriveBackup.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive Yedekleme'**
  String get googleDriveBackup;

  /// No description provided for @googleDriveBackupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizin güvenliği için kendi kişisel Google Drive hesabınıza yedekleme yapın.'**
  String get googleDriveBackupDesc;

  /// No description provided for @connectGoogleDrive.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'a Bağlan'**
  String get connectGoogleDrive;

  /// No description provided for @account.
  ///
  /// In tr, this message translates to:
  /// **'Hesap:'**
  String get account;

  /// No description provided for @lastBackup.
  ///
  /// In tr, this message translates to:
  /// **'Son Yedekleme:'**
  String get lastBackup;

  /// No description provided for @disconnect.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı Kes'**
  String get disconnect;

  /// No description provided for @version.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm'**
  String get version;

  /// No description provided for @developer.
  ///
  /// In tr, this message translates to:
  /// **'Geliştirici'**
  String get developer;

  /// No description provided for @noBackupsYet.
  ///
  /// In tr, this message translates to:
  /// **'Hiç yedekleme yapılmadı'**
  String get noBackupsYet;

  /// No description provided for @restoreDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Verileri Geri Yükle?'**
  String get restoreDataTitle;

  /// No description provided for @restoreDataDesc.
  ///
  /// In tr, this message translates to:
  /// **'Buluttaki verileriniz cihazınızdaki mevcut verilerin üzerine yazılacaktır. Bu işlem geri alınamaz.'**
  String get restoreDataDesc;

  /// No description provided for @googleDriveConnected.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive başarıyla bağlandı.'**
  String get googleDriveConnected;

  /// No description provided for @googleDriveConnectionFailed.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive bağlantısı başarısız oldu.'**
  String get googleDriveConnectionFailed;

  /// No description provided for @googleDriveDisconnected.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive bağlantısı kesildi.'**
  String get googleDriveDisconnected;

  /// No description provided for @dataBackedUpSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Veriler Google Drive\'a başarıyla yedeklendi.'**
  String get dataBackedUpSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme başarısız oldu.'**
  String get backupFailed;

  /// No description provided for @dataRestoredSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Veriler başarıyla geri yüklendi. Değişikliklerin görünmesi için lütfen uygulamayı yeniden başlatın.'**
  String get dataRestoredSuccess;

  /// No description provided for @restoreFailedNoBackup.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.'**
  String get restoreFailedNoBackup;

  /// No description provided for @welcomeUser.
  ///
  /// In tr, this message translates to:
  /// **'Hoşgeldiniz'**
  String get welcomeUser;

  /// No description provided for @defaultUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get defaultUser;

  /// No description provided for @dataExportImport.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Dışa / İçe Aktar'**
  String get dataExportImport;

  /// No description provided for @dataExportImportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tüm işlemlerinizi standart CSV formatında dışa aktararak diğer uygulamalarda kullanabilir veya yedekleyebilirsiniz.'**
  String get dataExportImportDesc;

  /// No description provided for @activeWalletRequiredForExport.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarım için aktif bir cüzdan gereklidir.'**
  String get activeWalletRequiredForExport;

  /// No description provided for @uygulamaBaslatilamadi.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama başlatılamadı'**
  String get uygulamaBaslatilamadi;

  /// No description provided for @verilerinizSilinmediTekrarDeneyin.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz silinmedi. Tekrar deneyin; sorun sürerse '**
  String get verilerinizSilinmediTekrarDeneyin;

  /// No description provided for @ikonBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'İkon bulunamadı'**
  String get ikonBulunamadi;

  /// No description provided for @valueTostringasfixedCurrencysymbol.
  ///
  /// In tr, this message translates to:
  /// **'{toStringAsFixed} {currencySymbol}'**
  String valueTostringasfixedCurrencysymbol(Object toStringAsFixed, Object currencySymbol);

  /// No description provided for @butcePlanlama.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Planlama'**
  String get butcePlanlama;

  /// No description provided for @henuzButceYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bütçe yok'**
  String get henuzButceYok;

  /// No description provided for @kategorilerinizeAylikHarcamaLimiti.
  ///
  /// In tr, this message translates to:
  /// **'Kategorilerinize aylık harcama limiti koyun,\nharcamalarınızı buradan takip edin.'**
  String get kategorilerinizeAylikHarcamaLimiti;

  /// No description provided for @bUAyToplamHarcama.
  ///
  /// In tr, this message translates to:
  /// **'BU AY TOPLAM HARCAMA'**
  String get bUAyToplamHarcama;

  /// No description provided for @toplamLimitAppformattersCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Toplam limit: {totalLimit}'**
  String toplamLimitAppformattersCurrency(Object totalLimit);

  /// No description provided for @percent.
  ///
  /// In tr, this message translates to:
  /// **'%{percent}'**
  String percent(Object percent);

  /// No description provided for @harcananAppformattersCurrencyFormat.
  ///
  /// In tr, this message translates to:
  /// **'Harcanan: {spentAmount}'**
  String harcananAppformattersCurrencyFormat(Object spentAmount);

  /// No description provided for @limitAppformattersCurrencyFormat.
  ///
  /// In tr, this message translates to:
  /// **'Limit: {limitAmount}'**
  String limitAppformattersCurrencyFormat(Object limitAmount);

  /// No description provided for @buKategorininButcesiVar.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategorinin bütçesi var; limit güncellenecek.'**
  String get buKategorininButcesiVar;

  /// No description provided for @finansalTakip.
  ///
  /// In tr, this message translates to:
  /// **'Finansal Takip'**
  String get finansalTakip;

  /// No description provided for @vADESIGecmis.
  ///
  /// In tr, this message translates to:
  /// **'VADESİ GEÇMİŞ'**
  String get vADESIGecmis;

  /// No description provided for @oDENDI.
  ///
  /// In tr, this message translates to:
  /// **'ÖDENDİ'**
  String get oDENDI;

  /// No description provided for @vadeDebtTermmonthsAy.
  ///
  /// In tr, this message translates to:
  /// **'Vade: {termMonths} Ay | {length} Ödeme'**
  String vadeDebtTermmonthsAy(Object termMonths, Object length);

  /// No description provided for @vadeDateformatDdMmm.
  ///
  /// In tr, this message translates to:
  /// **'Vade: {dueDate}'**
  String vadeDateformatDdMmm(Object dueDate);

  /// No description provided for @msgOdemesiTamamlanipKapatilanBorclarinizin.
  ///
  /// In tr, this message translates to:
  /// **'Ödemesi tamamlanıp kapatılan borçlarınızın geçmişi burada görüntülenecektir.'**
  String get msgOdemesiTamamlanipKapatilanBorclarinizin;

  /// No description provided for @paidDebtsLengthBorcKapandi.
  ///
  /// In tr, this message translates to:
  /// **'{length} borç kapandı'**
  String paidDebtsLengthBorcKapandi(Object length);

  /// No description provided for @msgOdendiOlarakIsaretlenenAlacaklarinizin.
  ///
  /// In tr, this message translates to:
  /// **'Ödendi olarak işaretlenen alacaklarınızın geçmişi burada görüntülenecektir.'**
  String get msgOdendiOlarakIsaretlenenAlacaklarinizin;

  /// No description provided for @paidReceivablesLengthAlacakTahsil.
  ///
  /// In tr, this message translates to:
  /// **'{length} alacak tahsil edildi'**
  String paidReceivablesLengthAlacakTahsil(Object length);

  /// No description provided for @toplamGeriOdeme.
  ///
  /// In tr, this message translates to:
  /// **'Toplam geri ödeme'**
  String get toplamGeriOdeme;

  /// No description provided for @kKDFVeBsmvVergilerini.
  ///
  /// In tr, this message translates to:
  /// **'KKDF ve BSMV vergilerini (%30) dahil et'**
  String get kKDFVeBsmvVergilerini;

  /// No description provided for @tuketiciKredilerindeFaizeYasal.
  ///
  /// In tr, this message translates to:
  /// **'Tüketici kredilerinde faize yasal olarak %15 KKDF ve %15 BSMV eklenir. Konut vb. kredilerde bu vergiler %0 olabilir. Duruma göre aktifleştirin.'**
  String get tuketiciKredilerindeFaizeYasal;

  /// No description provided for @iTaksitAppformattersDateshort.
  ///
  /// In tr, this message translates to:
  /// **'{i}. Taksit — {scheduledDate}'**
  String iTaksitAppformattersDateshort(Object i, Object scheduledDate);

  /// No description provided for @formatMoneyMonthlyamount.
  ///
  /// In tr, this message translates to:
  /// **'≈ {monthlyAmount}'**
  String formatMoneyMonthlyamount(Object monthlyAmount);

  /// No description provided for @index.
  ///
  /// In tr, this message translates to:
  /// **'{index}'**
  String index(Object index);

  /// No description provided for @optLabelFormatmoneyOpt.
  ///
  /// In tr, this message translates to:
  /// **'{label}  {amount}'**
  String optLabelFormatmoneyOpt(Object label, Object amount);

  /// No description provided for @otomatikIslem.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik işlem'**
  String get otomatikIslem;

  /// No description provided for @buIslemOtomatikOlusturuldu.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından düzenleyin veya silin.'**
  String get buIslemOtomatikOlusturuldu;

  /// No description provided for @nakitAkisi.
  ///
  /// In tr, this message translates to:
  /// **'Nakit Akışı'**
  String get nakitAkisi;

  /// No description provided for @grafikIcinYeterliVeri.
  ///
  /// In tr, this message translates to:
  /// **'Grafik için yeterli veri yok'**
  String get grafikIcinYeterliVeri;

  /// No description provided for @detayGosterilecekIslemYok.
  ///
  /// In tr, this message translates to:
  /// **'Detay Gösterilecek İşlem Yok'**
  String get detayGosterilecekIslemYok;

  /// No description provided for @gelirVeyaGiderKaydettikten.
  ///
  /// In tr, this message translates to:
  /// **'Gelir veya gider kaydettikten sonra analiz detayları burada listelenecektir.'**
  String get gelirVeyaGiderKaydettikten;

  /// No description provided for @henuzIslemYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz işlem yok'**
  String get henuzIslemYok;

  /// No description provided for @buDonemIcinKayit.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönem için kayıt bulunmuyor.\nYeni bir işlem eklemek için sürgü butonunu kullanın.'**
  String get buDonemIcinKayit;

  /// No description provided for @tumIslemlerinizGuncel.
  ///
  /// In tr, this message translates to:
  /// **'Tüm İşlemleriniz Güncel'**
  String get tumIslemlerinizGuncel;

  /// No description provided for @bekleyenCevrimdisiIslemBulunmuyor.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen çevrimdışı işlem bulunmuyor. Cihazınız internete bağlandığında veya yeni veriler girildiğinde senkronizasyon otomatik olarak tetiklenir.'**
  String get bekleyenCevrimdisiIslemBulunmuyor;

  /// No description provided for @haftalikNetAkis.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık Net Akış'**
  String get haftalikNetAkis;

  /// No description provided for @kategoriDagilimi.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Dağılımı'**
  String get kategoriDagilimi;

  /// No description provided for @titleIcinVeriYok.
  ///
  /// In tr, this message translates to:
  /// **'{title} için veri yok'**
  String titleIcinVeriYok(Object title);

  /// No description provided for @buKategoriyeAitIslem.
  ///
  /// In tr, this message translates to:
  /// **'Bu kategoriye ait işlem bulunmuyor.'**
  String get buKategoriyeAitIslem;

  /// No description provided for @formatMoneyItemTotalamountPercent.
  ///
  /// In tr, this message translates to:
  /// **'{totalAmount} (%{toStringAsFixed})'**
  String formatMoneyItemTotalamountPercent(Object totalAmount, Object toStringAsFixed);

  /// No description provided for @buDonemIcinHenuz.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönem için henüz işlem verisi bulunamadı. Raporlar veri girildikten sonra derlenecektir.'**
  String get buDonemIcinHenuz;

  /// No description provided for @ikonSecin.
  ///
  /// In tr, this message translates to:
  /// **'İkon Seçin'**
  String get ikonSecin;

  /// No description provided for @ikonDegistirmekIcinDokun.
  ///
  /// In tr, this message translates to:
  /// **'İkon değiştirmek için dokun'**
  String get ikonDegistirmekIcinDokun;

  /// No description provided for @categoriesWhereCC.
  ///
  /// In tr, this message translates to:
  /// **'{customLength} özel, {defaultLength} varsayılan'**
  String categoriesWhereCC(Object customLength, Object defaultLength);

  /// No description provided for @asagidakiButondanEkleyebilirsiniz.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki butondan ekleyebilirsiniz'**
  String get asagidakiButondanEkleyebilirsiniz;

  /// No description provided for @varsayilan.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan'**
  String get varsayilan;

  /// No description provided for @filtreler.
  ///
  /// In tr, this message translates to:
  /// **'Filtreler'**
  String get filtreler;

  /// No description provided for @uygula.
  ///
  /// In tr, this message translates to:
  /// **'Uygula'**
  String get uygula;

  /// No description provided for @tARIHAraligi.
  ///
  /// In tr, this message translates to:
  /// **'TARİH ARALIĞI'**
  String get tARIHAraligi;

  /// No description provided for @seciliAralik.
  ///
  /// In tr, this message translates to:
  /// **'Seçili Aralık'**
  String get seciliAralik;

  /// No description provided for @kATEGORIFiltresi.
  ///
  /// In tr, this message translates to:
  /// **'KATEGORİ FİLTRESİ'**
  String get kATEGORIFiltresi;

  /// No description provided for @kategoriBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Kategori bulunamadı'**
  String get kategoriBulunamadi;

  /// No description provided for @fIYATAraligi.
  ///
  /// In tr, this message translates to:
  /// **'FİYAT ARALIĞI'**
  String get fIYATAraligi;

  /// No description provided for @yeni.
  ///
  /// In tr, this message translates to:
  /// **'Yeni'**
  String get yeni;

  /// No description provided for @appFormattersDateshortFormatStartdate.
  ///
  /// In tr, this message translates to:
  /// **'{startDate} - {endDate}'**
  String appFormattersDateshortFormatStartdate(Object startDate, Object endDate);

  /// No description provided for @filterSelectedcategoriesLengthKategori.
  ///
  /// In tr, this message translates to:
  /// **'{length} Kategori'**
  String filterSelectedcategoriesLengthKategori(Object length);

  /// No description provided for @gunSonu.
  ///
  /// In tr, this message translates to:
  /// **'Gün sonu '**
  String get gunSonu;

  /// No description provided for @netNetAppformattersCurrency.
  ///
  /// In tr, this message translates to:
  /// **'Net: {net}'**
  String netNetAppformattersCurrency(Object net);

  /// No description provided for @dataFilterSelectedcategoriesLengthKategori.
  ///
  /// In tr, this message translates to:
  /// **'{length} Kategori'**
  String dataFilterSelectedcategoriesLengthKategori(Object length);

  /// No description provided for @countCountlabel.
  ///
  /// In tr, this message translates to:
  /// **'{count} {countLabel}'**
  String countCountlabel(Object count, Object countLabel);

  /// No description provided for @portfoyDetayi.
  ///
  /// In tr, this message translates to:
  /// **'Portföy Detayı'**
  String get portfoyDetayi;

  /// No description provided for @henuzYatirimKaydiYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Yatırım Kaydı Yok'**
  String get henuzYatirimKaydiYok;

  /// No description provided for @yatirimlariniziEklediktenSonraDetayli.
  ///
  /// In tr, this message translates to:
  /// **'Yatırımlarınızı ekledikten sonra detaylı analizler burada görünecektir.'**
  String get yatirimlariniziEklediktenSonraDetayli;

  /// No description provided for @guncelDegerFormatmoneyInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Güncel değer ({currentValue}) cüzdana gelir olarak işlenir ve kayıt kapatılır.'**
  String guncelDegerFormatmoneyInvestment(Object currentValue);

  /// No description provided for @hataliGirislerIcinAlim.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı girişler için: alım gideri ({amount}) düzeltme kaydıyla iade edilir, bakiye yatırım öncesine döner.\n\nGerçekten sattıysanız bunun yerine \"Sat\" kullanın.'**
  String hataliGirislerIcinAlim(Object amount);

  /// No description provided for @portfoyum.
  ///
  /// In tr, this message translates to:
  /// **'Portföyüm'**
  String get portfoyum;

  /// No description provided for @investmentsLengthYatirim.
  ///
  /// In tr, this message translates to:
  /// **'{length} yatırım'**
  String investmentsLengthYatirim(Object length);

  /// No description provided for @mevcutDeger.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Değer'**
  String get mevcutDeger;

  /// No description provided for @maliyetiDegistirirsenizFarkCuzdana.
  ///
  /// In tr, this message translates to:
  /// **'Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.'**
  String get maliyetiDegistirirsenizFarkCuzdana;

  /// No description provided for @hesapla.
  ///
  /// In tr, this message translates to:
  /// **'Hesapla'**
  String get hesapla;

  /// No description provided for @birikmisFormatmoneyInvCurrentvalue.
  ///
  /// In tr, this message translates to:
  /// **'Birikmiş: {currentValue} / '**
  String birikmisFormatmoneyInvCurrentvalue(Object currentValue);

  /// No description provided for @guncelFiyatiGetir.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Fiyatı Getir'**
  String get guncelFiyatiGetir;

  /// No description provided for @ekle.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get ekle;

  /// No description provided for @karZarar.
  ///
  /// In tr, this message translates to:
  /// **'Kar/Zarar'**
  String get karZarar;

  /// No description provided for @investmentProfitpercentageTostringasfixed.
  ///
  /// In tr, this message translates to:
  /// **'{toStringAsFixed}%'**
  String investmentProfitpercentageTostringasfixed(Object toStringAsFixed);

  /// No description provided for @hedefCurrencyformatFormatInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Hedef: {targetAmount}'**
  String hedefCurrencyformatFormatInvestment(Object targetAmount);

  /// No description provided for @investmentTargetprogressTostringasfixed.
  ///
  /// In tr, this message translates to:
  /// **'{toStringAsFixed}%'**
  String investmentTargetprogressTostringasfixed(Object toStringAsFixed);

  /// No description provided for @grafikIcinYatirimBulunmuyor.
  ///
  /// In tr, this message translates to:
  /// **'Grafik için yatırım bulunmuyor'**
  String get grafikIcinYatirimBulunmuyor;

  /// No description provided for @portfoyDagilimi.
  ///
  /// In tr, this message translates to:
  /// **'Portföy Dağılımı'**
  String get portfoyDagilimi;

  /// No description provided for @percentage.
  ///
  /// In tr, this message translates to:
  /// **'%{percentage}'**
  String percentage(Object percentage);

  /// No description provided for @tOPLAMPortfoyDegeri.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM PORTFÖY DEĞERİ'**
  String get tOPLAMPortfoyDegeri;

  /// No description provided for @tOPLAMMaliyet.
  ///
  /// In tr, this message translates to:
  /// **'TOPLAM MALİYET'**
  String get tOPLAMMaliyet;

  /// No description provided for @kAZANCZarar.
  ///
  /// In tr, this message translates to:
  /// **'KAZANÇ / ZARAR'**
  String get kAZANCZarar;

  /// No description provided for @isProfitTotalprofitpercentageTostringasfixed.
  ///
  /// In tr, this message translates to:
  /// **'{isProfit}{toStringAsFixed}%'**
  String isProfitTotalprofitpercentageTostringasfixed(Object isProfit, Object toStringAsFixed);

  /// No description provided for @templateTitleDuzenliIslemi.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" düzenli işlemi silinsin mi?\n\nDeftere işlenmiş geçmiş işlemler silinmez.'**
  String templateTitleDuzenliIslemi(Object title);

  /// No description provided for @duzenliIslemler.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli İşlemler'**
  String get duzenliIslemler;

  /// No description provided for @henuzDuzenliIslemYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz düzenli işlem yok'**
  String get henuzDuzenliIslemYok;

  /// No description provided for @islemEklerkenTekrarSikligi.
  ///
  /// In tr, this message translates to:
  /// **'İşlem eklerken tekrar sıklığı seçerseniz\nşablon burada görünür.'**
  String get islemEklerkenTekrarSikligi;

  /// No description provided for @bekleyenDuzenliIslemler.
  ///
  /// In tr, this message translates to:
  /// **'Bekleyen Düzenli İşlemler'**
  String get bekleyenDuzenliIslemler;

  /// No description provided for @vadesiGelmisIslemlerinizVar.
  ///
  /// In tr, this message translates to:
  /// **'Vadesi gelmiş işlemleriniz var. Onaylayarak deftere işlenmesini sağlayabilirsiniz.'**
  String get vadesiGelmisIslemlerinizVar;

  /// No description provided for @titleTarihDatestrNtutarTx.
  ///
  /// In tr, this message translates to:
  /// **'Tarih: {dateStr}\nTutar: {amount}'**
  String titleTarihDatestrNtutarTx(Object dateStr, Object amount);

  /// No description provided for @profilAyarlari.
  ///
  /// In tr, this message translates to:
  /// **'Profil Ayarları'**
  String get profilAyarlari;

  /// No description provided for @bilgileriGuncelle.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri Güncelle'**
  String get bilgileriGuncelle;

  /// No description provided for @ibo.
  ///
  /// In tr, this message translates to:
  /// **'İbo'**
  String get ibo;

  /// No description provided for @uygulamaKilidi.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama Kilidi'**
  String get uygulamaKilidi;

  /// No description provided for @pINBiyometrikVeGizlilik.
  ///
  /// In tr, this message translates to:
  /// **'PIN, Biyometrik ve Gizlilik Ayarları'**
  String get pINBiyometrikVeGizlilik;

  /// No description provided for @otomatikHesaplananDegerler.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik hesaplanan değerler:'**
  String get otomatikHesaplananDegerler;

  /// No description provided for @borcAlacakYatirimKayitlarindan.
  ///
  /// In tr, this message translates to:
  /// **'Borç/alacak/yatırım kayıtlarından türetilir; buradan düzenlenemez.'**
  String get borcAlacakYatirimKayitlarindan;

  /// No description provided for @renkSecin.
  ///
  /// In tr, this message translates to:
  /// **'Renk Seçin:'**
  String get renkSecin;

  /// No description provided for @ikonSecin2.
  ///
  /// In tr, this message translates to:
  /// **'İkon Seçin:'**
  String get ikonSecin2;

  /// No description provided for @ikonDegistir.
  ///
  /// In tr, this message translates to:
  /// **'İkon Değiştir'**
  String get ikonDegistir;

  /// No description provided for @cuzdanlarim.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarım'**
  String get cuzdanlarim;

  /// No description provided for @cuzdanlariniziYonetin.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarınızı yönetin'**
  String get cuzdanlariniziYonetin;

  /// No description provided for @yeniCuzdanOlustur.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Cüzdan Oluştur'**
  String get yeniCuzdanOlustur;

  /// No description provided for @finansalNyolculugunuzBasliyor.
  ///
  /// In tr, this message translates to:
  /// **'Finansal\nYolculuğunuz Başlıyor'**
  String get finansalNyolculugunuzBasliyor;

  /// No description provided for @ilkCuzdaniOlustur.
  ///
  /// In tr, this message translates to:
  /// **'İlk Cüzdanı Oluştur'**
  String get ilkCuzdaniOlustur;

  /// No description provided for @olusturulmaAppformattersDateshortFormat.
  ///
  /// In tr, this message translates to:
  /// **'Oluşturulma: {createdAt}'**
  String olusturulmaAppformattersDateshortFormat(Object createdAt);

  /// No description provided for @aktif.
  ///
  /// In tr, this message translates to:
  /// **'Aktif'**
  String get aktif;

  /// No description provided for @aktifOlanCuzdanSilinemez.
  ///
  /// In tr, this message translates to:
  /// **'• Aktif olan cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yapmalısınız.'**
  String get aktifOlanCuzdanSilinemez;

  /// No description provided for @cuzdanlarinizaAitBorcAlacak.
  ///
  /// In tr, this message translates to:
  /// **'• Cüzdanlarınıza ait Borç, Alacak ve Birikim tutarlarını düzenle sayfasından manuel olarak yönetebilirsiniz.'**
  String get cuzdanlarinizaAitBorcAlacak;

  /// No description provided for @msgPINOrBiometricLogin.
  ///
  /// In tr, this message translates to:
  /// **'PIN veya biyometrik giriş arka plan kilidi için gereklidir'**
  String get msgPINOrBiometricLogin;

  /// No description provided for @sharedFeatures.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşılan Özellikler'**
  String get sharedFeatures;

  /// No description provided for @tarihAraligi.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Aralığı'**
  String get tarihAraligi;

  /// No description provided for @butonGalerisi.
  ///
  /// In tr, this message translates to:
  /// **'Buton Galerisi'**
  String get butonGalerisi;

  /// No description provided for @internetBaglantisiAktif.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı aktif'**
  String get internetBaglantisiAktif;

  /// No description provided for @internetBaglantisiYok.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok'**
  String get internetBaglantisiYok;

  /// No description provided for @baglantiKontrolEdiliyor.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı kontrol ediliyor...'**
  String get baglantiKontrolEdiliyor;

  /// No description provided for @taksit1.
  ///
  /// In tr, this message translates to:
  /// **'1 taksit'**
  String get taksit1;

  /// No description provided for @taksit2.
  ///
  /// In tr, this message translates to:
  /// **'2 taksit'**
  String get taksit2;

  /// No description provided for @tamaminiOde.
  ///
  /// In tr, this message translates to:
  /// **'Tamamını öde'**
  String get tamaminiOde;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
