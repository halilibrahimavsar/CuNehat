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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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

  /// No description provided for @geriAl.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get geriAl;

  /// No description provided for @silmeGeriAlindi.
  ///
  /// In tr, this message translates to:
  /// **'Silme geri alındı'**
  String get silmeGeriAlindi;

  /// No description provided for @silmeGeriAlinamadi.
  ///
  /// In tr, this message translates to:
  /// **'Geri alma başarısız oldu; kayıt geri getirilemedi'**
  String get silmeGeriAlinamadi;

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

  /// No description provided for @henuzBorcKaydiYokAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaydedilmiş aktif bir borcunuz bulunmuyor. Yeni borç eklemek için ekleme butonunu kullanabilirsiniz.'**
  String get henuzBorcKaydiYokAciklama;

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

  /// No description provided for @henuzAlacakKaydiYokAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kaydedilmiş aktif bir alacağınız bulunmuyor. Yeni alacak eklemek için ekleme butonunu kullanabilirsiniz.'**
  String get henuzAlacakKaydiYokAciklama;

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

  /// No description provided for @raporuPaylas.
  ///
  /// In tr, this message translates to:
  /// **'Raporu Paylaş'**
  String get raporuPaylas;

  /// No description provided for @oncekiDonemeGorePercent.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} önceki döneme göre'**
  String oncekiDonemeGorePercent(Object percent);

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
  /// **'Yedekten İçe Aktar (CSV)'**
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
  String msgTextsCheckfailedprefixETostring(
      Object checkFailedPrefix, Object error);

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

  /// No description provided for @deleteBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedeği Sil'**
  String get deleteBackup;

  /// No description provided for @deleteBackupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'daki yedek dosyası kalıcı olarak silinecek. Yerel veriniz etkilenmez.'**
  String get deleteBackupDesc;

  /// No description provided for @backupDeleted.
  ///
  /// In tr, this message translates to:
  /// **'Yedek silindi.'**
  String get backupDeleted;

  /// No description provided for @deleteBackupFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yedek silinemedi.'**
  String get deleteBackupFailed;

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
  /// **'Veriler başarıyla geri yüklendi.'**
  String get dataRestoredSuccess;

  /// No description provided for @restoreFailedNoBackup.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.'**
  String get restoreFailedNoBackup;

  /// No description provided for @defaultUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı'**
  String get defaultUser;

  /// No description provided for @dataExportImport.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz Yedeği / CSV'**
  String get dataExportImport;

  /// No description provided for @dataExportImportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tam uygulama yedeği kaydedip geri yükleyin veya mevcut cüzdan işlemleri için CSV kullanın.'**
  String get dataExportImportDesc;

  /// No description provided for @fullBackup.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedek'**
  String get fullBackup;

  /// No description provided for @saveFullBackupToDevice.
  ///
  /// In tr, this message translates to:
  /// **'Tam Yedeği Cihaza Kaydet'**
  String get saveFullBackupToDevice;

  /// No description provided for @restoreFullBackupFromDevice.
  ///
  /// In tr, this message translates to:
  /// **'Tam Yedeği Cihazdan Geri Yükle'**
  String get restoreFullBackupFromDevice;

  /// No description provided for @shareFullBackup.
  ///
  /// In tr, this message translates to:
  /// **'Tam Yedeği Paylaş'**
  String get shareFullBackup;

  /// No description provided for @transactionCsv.
  ///
  /// In tr, this message translates to:
  /// **'İşlem CSV'**
  String get transactionCsv;

  /// No description provided for @restoreFullBackupTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedek geri yüklensin mi?'**
  String get restoreFullBackupTitle;

  /// No description provided for @restoreFullBackupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem bu cihazdaki cüzdanları, işlemleri, birikimleri, borçları, alacakları, bütçeleri, tekrar eden işlem şablonlarını, kullanıcıları ve kategorileri değiştirir.'**
  String get restoreFullBackupDesc;

  /// No description provided for @fullBackupSaved.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedek başarıyla kaydedildi.'**
  String get fullBackupSaved;

  /// No description provided for @fullBackupRestored.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedek başarıyla geri yüklendi.'**
  String get fullBackupRestored;

  /// No description provided for @fullBackupShared.
  ///
  /// In tr, this message translates to:
  /// **'Tam yedek başarıyla paylaşıldı.'**
  String get fullBackupShared;

  /// No description provided for @fullBackupCancelled.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleme işlemi iptal edildi.'**
  String get fullBackupCancelled;

  /// No description provided for @fullBackupShareText.
  ///
  /// In tr, this message translates to:
  /// **'CuNehat tam yedeği'**
  String get fullBackupShareText;

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

  /// No description provided for @cizgiGrafikIcinEnAzIkiGun.
  ///
  /// In tr, this message translates to:
  /// **'Çizgi grafik oluşturmak için en az iki farklı güne ait işlem olmalıdır'**
  String get cizgiGrafikIcinEnAzIkiGun;

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
  String formatMoneyItemTotalamountPercent(
      Object totalAmount, Object toStringAsFixed);

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
  String appFormattersDateshortFormatStartdate(
      Object startDate, Object endDate);

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

  /// No description provided for @gorunumListe.
  ///
  /// In tr, this message translates to:
  /// **'Liste'**
  String get gorunumListe;

  /// No description provided for @gorunumTakvim.
  ///
  /// In tr, this message translates to:
  /// **'Takvim'**
  String get gorunumTakvim;

  /// No description provided for @takvimAy.
  ///
  /// In tr, this message translates to:
  /// **'Ay'**
  String get takvimAy;

  /// No description provided for @takvimHafta.
  ///
  /// In tr, this message translates to:
  /// **'Hafta'**
  String get takvimHafta;

  /// No description provided for @buGuneAitIslemYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu güne ait işlem yok'**
  String get buGuneAitIslemYok;

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
  String isProfitTotalprofitpercentageTostringasfixed(
      Object isProfit, Object toStringAsFixed);

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

  /// No description provided for @sliderSavings.
  ///
  /// In tr, this message translates to:
  /// **'BİRİKİM'**
  String get sliderSavings;

  /// No description provided for @sliderTransactions.
  ///
  /// In tr, this message translates to:
  /// **'İŞLEMLER'**
  String get sliderTransactions;

  /// No description provided for @sliderDebt.
  ///
  /// In tr, this message translates to:
  /// **'BORÇ'**
  String get sliderDebt;

  /// No description provided for @recurringTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli İşlemler'**
  String get recurringTransactions;

  /// No description provided for @budgetPlanning.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Planlama'**
  String get budgetPlanning;

  /// No description provided for @drawerBalance.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye'**
  String get drawerBalance;

  /// No description provided for @drawerInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım'**
  String get drawerInvestment;

  /// No description provided for @drawerDebt.
  ///
  /// In tr, this message translates to:
  /// **'Borç'**
  String get drawerDebt;

  /// No description provided for @createWallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Oluştur'**
  String get createWallet;

  /// No description provided for @selectWallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Seçin'**
  String get selectWallet;

  /// No description provided for @wallet.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan'**
  String get wallet;

  /// No description provided for @menuGold.
  ///
  /// In tr, this message translates to:
  /// **'Altın'**
  String get menuGold;

  /// No description provided for @menuStock.
  ///
  /// In tr, this message translates to:
  /// **'Hisse'**
  String get menuStock;

  /// No description provided for @menuCustom.
  ///
  /// In tr, this message translates to:
  /// **'Özel'**
  String get menuCustom;

  /// No description provided for @menuDetails.
  ///
  /// In tr, this message translates to:
  /// **'Detay'**
  String get menuDetails;

  /// No description provided for @menuIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get menuIncome;

  /// No description provided for @menuExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get menuExpense;

  /// No description provided for @menuReport.
  ///
  /// In tr, this message translates to:
  /// **'Rapor'**
  String get menuReport;

  /// No description provided for @menuDebt.
  ///
  /// In tr, this message translates to:
  /// **'Borç'**
  String get menuDebt;

  /// No description provided for @menuReceivable.
  ///
  /// In tr, this message translates to:
  /// **'Alacak'**
  String get menuReceivable;

  /// No description provided for @menuHistory.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get menuHistory;

  /// No description provided for @themeSysLight.
  ///
  /// In tr, this message translates to:
  /// **'Sistem [Açık]'**
  String get themeSysLight;

  /// No description provided for @themeSysDark.
  ///
  /// In tr, this message translates to:
  /// **'Sistem [Kapalı]'**
  String get themeSysDark;

  /// No description provided for @cuzdanOlusturunuz.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan oluşturunuz'**
  String get cuzdanOlusturunuz;

  /// No description provided for @cuzdanSeciniz.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan seçiniz'**
  String get cuzdanSeciniz;

  /// No description provided for @yerelMod.
  ///
  /// In tr, this message translates to:
  /// **'Yerel Mod'**
  String get yerelMod;

  /// No description provided for @henuzCuzdanOlusturmadiniz.
  ///
  /// In tr, this message translates to:
  /// **'Henüz cüzdan oluşturmadınız'**
  String get henuzCuzdanOlusturmadiniz;

  /// No description provided for @cuzdanOlusturuldu.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan oluşturuldu!'**
  String get cuzdanOlusturuldu;

  /// No description provided for @cuzdanGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan güncellendi!'**
  String get cuzdanGuncellendi;

  /// No description provided for @cuzdanSilindi.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan silindi!'**
  String get cuzdanSilindi;

  /// No description provided for @cuzdanSecildi.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan seçildi'**
  String get cuzdanSecildi;

  /// No description provided for @disaAktarilacakIslemBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'Dışa aktarılacak işlem bulunamadı.'**
  String get disaAktarilacakIslemBulunamadi;

  /// No description provided for @islemlerDisaAktarildi.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler başarıyla dışa aktarıldı.'**
  String get islemlerDisaAktarildi;

  /// No description provided for @csvGecerliIslemBulunamadi.
  ///
  /// In tr, this message translates to:
  /// **'CSV dosyasında geçerli işlem bulunamadı.'**
  String get csvGecerliIslemBulunamadi;

  /// No description provided for @iceAktarilanCuzdanPrefix.
  ///
  /// In tr, this message translates to:
  /// **'İçe Aktarılan Cüzdan'**
  String get iceAktarilanCuzdanPrefix;

  /// No description provided for @verilerIceAktarildi.
  ///
  /// In tr, this message translates to:
  /// **'Veriler başarıyla içe aktarıldı. Yeni cüzdan oluşturuldu ve seçildi.'**
  String get verilerIceAktarildi;

  /// No description provided for @cuzdanOlusturulamadi.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan oluşturulamadı'**
  String get cuzdanOlusturulamadi;

  /// No description provided for @satirAtlandi.
  ///
  /// In tr, this message translates to:
  /// **'{count} satır tarih/tutar hatası nedeniyle atlandı.'**
  String satirAtlandi(int count);

  /// No description provided for @guncelle.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get guncelle;

  /// No description provided for @kaydet.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get kaydet;

  /// No description provided for @islem.
  ///
  /// In tr, this message translates to:
  /// **'İşlem'**
  String get islem;

  /// No description provided for @daily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In tr, this message translates to:
  /// **'Aylık'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In tr, this message translates to:
  /// **'Yıllık'**
  String get yearly;

  /// No description provided for @kategoriDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Düzenle'**
  String get kategoriDuzenle;

  /// No description provided for @yeniKategori.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Kategori'**
  String get yeniKategori;

  /// No description provided for @kategoriAdiBosOlamaz.
  ///
  /// In tr, this message translates to:
  /// **'Kategori adı boş olamaz'**
  String get kategoriAdiBosOlamaz;

  /// No description provided for @enAz2KarakterOlmali.
  ///
  /// In tr, this message translates to:
  /// **'En az 2 karakter olmalı'**
  String get enAz2KarakterOlmali;

  /// No description provided for @kategoriAdiRezerve.
  ///
  /// In tr, this message translates to:
  /// **'Bu ad otomatik sistem işlemleri için ayrılmış'**
  String get kategoriAdiRezerve;

  /// No description provided for @kategoriOlusturuldu.
  ///
  /// In tr, this message translates to:
  /// **'Kategori oluşturuldu!'**
  String get kategoriOlusturuldu;

  /// No description provided for @kategoriGuncellendi.
  ///
  /// In tr, this message translates to:
  /// **'Kategori güncellendi!'**
  String get kategoriGuncellendi;

  /// No description provided for @kategoriSilindi.
  ///
  /// In tr, this message translates to:
  /// **'Kategori silindi!'**
  String get kategoriSilindi;

  /// No description provided for @kategoriSilTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategori Sil'**
  String get kategoriSilTitle;

  /// No description provided for @kategoriSilConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'\"{id}\" kategorisini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.'**
  String kategoriSilConfirmMessage(Object id);

  /// No description provided for @kategorilerYuklenemedi.
  ///
  /// In tr, this message translates to:
  /// **'Kategoriler yüklenemedi: {error}'**
  String kategorilerYuklenemedi(Object error);

  /// No description provided for @giderKategorileri.
  ///
  /// In tr, this message translates to:
  /// **'Gider Kategorileri'**
  String get giderKategorileri;

  /// No description provided for @gelirKategorileri.
  ///
  /// In tr, this message translates to:
  /// **'Gelir Kategorileri'**
  String get gelirKategorileri;

  /// No description provided for @varsayilanKategoriYok.
  ///
  /// In tr, this message translates to:
  /// **'Varsayılan kategori yok'**
  String get varsayilanKategoriYok;

  /// No description provided for @henuzOzelKategoriYok.
  ///
  /// In tr, this message translates to:
  /// **'Henüz özel kategori yok'**
  String get henuzOzelKategoriYok;

  /// No description provided for @duzenleSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tutar, tarih, kategori ve diğer detaylar'**
  String get duzenleSubtitle;

  /// No description provided for @islemiSil.
  ///
  /// In tr, this message translates to:
  /// **'İşlemi Sil'**
  String get islemiSil;

  /// No description provided for @silSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye eski haline döner'**
  String get silSubtitle;

  /// No description provided for @gramAltin.
  ///
  /// In tr, this message translates to:
  /// **'Gram Altın'**
  String get gramAltin;

  /// No description provided for @ceyrekAltin.
  ///
  /// In tr, this message translates to:
  /// **'Çeyrek Altın'**
  String get ceyrekAltin;

  /// No description provided for @yarimAltin.
  ///
  /// In tr, this message translates to:
  /// **'Yarım Altın'**
  String get yarimAltin;

  /// No description provided for @tamAltin.
  ///
  /// In tr, this message translates to:
  /// **'Tam Altın'**
  String get tamAltin;

  /// No description provided for @cumhuriyetAltini.
  ///
  /// In tr, this message translates to:
  /// **'Cumhuriyet Altını'**
  String get cumhuriyetAltini;

  /// No description provided for @ataAltin.
  ///
  /// In tr, this message translates to:
  /// **'Ata Altın'**
  String get ataAltin;

  /// No description provided for @fiyatAliniyor.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alınıyor...'**
  String get fiyatAliniyor;

  /// No description provided for @fiyatAlinamadi.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat alınamadı.'**
  String get fiyatAlinamadi;

  /// No description provided for @guncelFiyatFormatTry.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Fiyat: {price}'**
  String guncelFiyatFormatTry(Object price);

  /// No description provided for @guncelFiyatFormatForeign.
  ///
  /// In tr, this message translates to:
  /// **'Güncel Fiyat: {price} (≈{priceTl})'**
  String guncelFiyatFormatForeign(Object price, Object priceTl);

  /// No description provided for @gecerliYatirimMiktariGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir yatırım miktarı girin'**
  String get gecerliYatirimMiktariGirin;

  /// No description provided for @gecerliMevcutDegerGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir mevcut değer girin'**
  String get gecerliMevcutDegerGirin;

  /// No description provided for @altinYatirimi.
  ///
  /// In tr, this message translates to:
  /// **'Altın Yatırımı'**
  String get altinYatirimi;

  /// No description provided for @altinTuruVeOtomatikFiyat.
  ///
  /// In tr, this message translates to:
  /// **'Altın Türü & Otomatik Fiyat'**
  String get altinTuruVeOtomatikFiyat;

  /// No description provided for @yatirimDetaylari.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım Detayları'**
  String get yatirimDetaylari;

  /// No description provided for @altinNotHint.
  ///
  /// In tr, this message translates to:
  /// **'Not (İsteğe bağlı) · örn. Düğün Altınları'**
  String get altinNotHint;

  /// No description provided for @maliyetYatirilanAnaPara.
  ///
  /// In tr, this message translates to:
  /// **'Maliyet (Yatırılan Ana Para)'**
  String get maliyetYatirilanAnaPara;

  /// No description provided for @hedefTutarIstegeBagli.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Tutar (İsteğe Bağlı)'**
  String get hedefTutarIstegeBagli;

  /// No description provided for @hedefKategorisi.
  ///
  /// In tr, this message translates to:
  /// **'Hedef Kategorisi'**
  String get hedefKategorisi;

  /// No description provided for @renkSecimi.
  ///
  /// In tr, this message translates to:
  /// **'Renk Seçimi'**
  String get renkSecimi;

  /// No description provided for @altinYatiriminiDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Altın Yatırımını Düzenle'**
  String get altinYatiriminiDuzenle;

  /// No description provided for @yeniAltinEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Altın Ekle'**
  String get yeniAltinEkle;

  /// No description provided for @adet.
  ///
  /// In tr, this message translates to:
  /// **'Adet'**
  String get adet;

  /// No description provided for @sembolGirin.
  ///
  /// In tr, this message translates to:
  /// **'Sembol girin!'**
  String get sembolGirin;

  /// No description provided for @hisseYatirimi.
  ///
  /// In tr, this message translates to:
  /// **'Hisse Yatırımı'**
  String get hisseYatirimi;

  /// No description provided for @hisseSenediBul.
  ///
  /// In tr, this message translates to:
  /// **'Hisse Senedi Bul'**
  String get hisseSenediBul;

  /// No description provided for @hisseNotHint.
  ///
  /// In tr, this message translates to:
  /// **'Not (İsteğe bağlı) · örn. Uzun vade alım'**
  String get hisseNotHint;

  /// No description provided for @hisseYatiriminiDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Hisse Yatırımını Düzenle'**
  String get hisseYatiriminiDuzenle;

  /// No description provided for @yeniHisseEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Hisse Ekle'**
  String get yeniHisseEkle;

  /// No description provided for @gecerliHedefTutarGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir hedef tutar girin'**
  String get gecerliHedefTutarGirin;

  /// No description provided for @ozelYatirimi.
  ///
  /// In tr, this message translates to:
  /// **'Özel Yatırım'**
  String get ozelYatirimi;

  /// No description provided for @customNotHint.
  ///
  /// In tr, this message translates to:
  /// **'Not (İsteğe bağlı) · örn. Arsa, Kripto, Döviz'**
  String get customNotHint;

  /// No description provided for @ozelYatiriminiDuzenle.
  ///
  /// In tr, this message translates to:
  /// **'Özel Yatırımını Düzenle'**
  String get ozelYatiriminiDuzenle;

  /// No description provided for @yeniOzelYatirimEkle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Özel Yatırım Ekle'**
  String get yeniOzelYatirimEkle;

  /// No description provided for @varlikEkle.
  ///
  /// In tr, this message translates to:
  /// **'Varlık Ekle'**
  String get varlikEkle;

  /// No description provided for @hedefeParaEkle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe Para Ekle'**
  String get hedefeParaEkle;

  /// No description provided for @paraEkle.
  ///
  /// In tr, this message translates to:
  /// **'Para Ekle'**
  String get paraEkle;

  /// No description provided for @yeniAlimMiktarVeOdenenTutar.
  ///
  /// In tr, this message translates to:
  /// **'Yeni alım: miktar ve ödenen tutar'**
  String get yeniAlimMiktarVeOdenenTutar;

  /// No description provided for @maliyeteVeDegereEklenir.
  ///
  /// In tr, this message translates to:
  /// **'Maliyete ve değere eklenir, cüzdandan düşer'**
  String get maliyeteVeDegereEklenir;

  /// No description provided for @fiyatiGuncelle.
  ///
  /// In tr, this message translates to:
  /// **'Fiyatı Güncelle'**
  String get fiyatiGuncelle;

  /// No description provided for @canliFiyatGuncellemeAciklamasi.
  ///
  /// In tr, this message translates to:
  /// **'Güncel değer = miktar × canlı fiyat; bakiyeyi etkilemez'**
  String get canliFiyatGuncellemeAciklamasi;

  /// No description provided for @duzenleYatirimSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'İsim, maliyet, hedef ve diğer detaylar'**
  String get duzenleYatirimSubtitle;

  /// No description provided for @satSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Güncel değer cüzdana gelir olarak işlenir'**
  String get satSubtitle;

  /// No description provided for @kaydiSilSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hatalı giriş düzeltme; alım gideri iade edilir'**
  String get kaydiSilSubtitle;

  /// No description provided for @varlikEkleTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} · Varlık Ekle'**
  String varlikEkleTitle(Object name);

  /// No description provided for @paraEkleTitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} · Para Ekle'**
  String paraEkleTitle(Object name);

  /// No description provided for @alinanMiktarAltinHint.
  ///
  /// In tr, this message translates to:
  /// **'Alınan miktar (örn. gram/adet)'**
  String get alinanMiktarAltinHint;

  /// No description provided for @alinanAdetHisseHint.
  ///
  /// In tr, this message translates to:
  /// **'Alınan adet (lot)'**
  String get alinanAdetHisseHint;

  /// No description provided for @odenenTutarHint.
  ///
  /// In tr, this message translates to:
  /// **'Ödenen tutar (₺) · hediye ise 0'**
  String get odenenTutarHint;

  /// No description provided for @tutarHint.
  ///
  /// In tr, this message translates to:
  /// **'Tutar (₺)'**
  String get tutarHint;

  /// No description provided for @gecerliMiktarGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir miktar girin'**
  String get gecerliMiktarGirin;

  /// No description provided for @gecerliOdenenTutarGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir ödenen tutar girin'**
  String get gecerliOdenenTutarGirin;

  /// No description provided for @gecerliTutarGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir tutar girin'**
  String get gecerliTutarGirin;

  /// No description provided for @baslikGirin.
  ///
  /// In tr, this message translates to:
  /// **'Başlık girin'**
  String get baslikGirin;

  /// No description provided for @borcluKisiAdiGirin.
  ///
  /// In tr, this message translates to:
  /// **'Borçlu kişi adını girin'**
  String get borcluKisiAdiGirin;

  /// No description provided for @kurumKisiGirin.
  ///
  /// In tr, this message translates to:
  /// **'Kurum/kişi girin'**
  String get kurumKisiGirin;

  /// No description provided for @vadeEnAz1Olmali.
  ///
  /// In tr, this message translates to:
  /// **'Vade (ay) en az 1 olmalı'**
  String get vadeEnAz1Olmali;

  /// No description provided for @aylikTaksitTutariniGirin.
  ///
  /// In tr, this message translates to:
  /// **'Aylık taksit tutarını girin'**
  String get aylikTaksitTutariniGirin;

  /// No description provided for @aylikTaksitKrediTutarindanKucuk.
  ///
  /// In tr, this message translates to:
  /// **'Aylık taksit × vade, kredi tutarından küçük olamaz'**
  String get aylikTaksitKrediTutarindanKucuk;

  /// No description provided for @krediHesaplamaInfoBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Banka kredisi hesaplaması'**
  String get krediHesaplamaInfoBaslik;

  /// No description provided for @krediHesaplamaInfoGovde.
  ///
  /// In tr, this message translates to:
  /// **'• Aylık taksiti biliyorum: Bankanın söylediği aylık taksiti yazın. Toplam geri ödeme = aylık taksit × vade. Kolaylık için alan, faizsiz bir başlangıç olarak kredi tutarı ÷ vade değerini önerir; kendi taksitinize göre değiştirin.\n\n• Faiz oranı ile: Bankanın aylık faiz oranını yazın. Taksit ve toplam, eşit taksitli kredi (amortisman) yöntemiyle hesaplanır.'**
  String get krediHesaplamaInfoGovde;

  /// No description provided for @borcTuruLabel.
  ///
  /// In tr, this message translates to:
  /// **'Borç türü'**
  String get borcTuruLabel;

  /// No description provided for @borcBaslikHint.
  ///
  /// In tr, this message translates to:
  /// **'Başlık · örn. Konut Kredisi'**
  String get borcBaslikHint;

  /// No description provided for @kurumKisiHint.
  ///
  /// In tr, this message translates to:
  /// **'Kurum / Kişi · örn. Ziraat Bankası'**
  String get kurumKisiHint;

  /// No description provided for @kisiAdiHint.
  ///
  /// In tr, this message translates to:
  /// **'Kişi Adı'**
  String get kisiAdiHint;

  /// No description provided for @vadeVeDetaylarLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vade & detaylar'**
  String get vadeVeDetaylarLabel;

  /// No description provided for @borcluKisiAdiHint.
  ///
  /// In tr, this message translates to:
  /// **'Borçlu kişi adı'**
  String get borcluKisiAdiHint;

  /// No description provided for @borcDuzenleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Borç Düzenle'**
  String get borcDuzenleTitle;

  /// No description provided for @alacakDuzenleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Alacak Düzenle'**
  String get alacakDuzenleTitle;

  /// No description provided for @yeniBorcTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Borç'**
  String get yeniBorcTitle;

  /// No description provided for @yeniAlacakTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Alacak'**
  String get yeniAlacakTitle;

  /// No description provided for @krediTutariAnaPara.
  ///
  /// In tr, this message translates to:
  /// **'Kredi tutarı (ana para)'**
  String get krediTutariAnaPara;

  /// No description provided for @borcTutariAnaPara.
  ///
  /// In tr, this message translates to:
  /// **'Borç tutarı (ana para)'**
  String get borcTutariAnaPara;

  /// No description provided for @alacakTutari.
  ///
  /// In tr, this message translates to:
  /// **'Alacak tutarı'**
  String get alacakTutari;

  /// No description provided for @toplamTutar.
  ///
  /// In tr, this message translates to:
  /// **'Toplam tutar'**
  String get toplamTutar;

  /// No description provided for @vadeFarkiLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vade farkı'**
  String get vadeFarkiLabel;

  /// No description provided for @toplamFaizLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam faiz'**
  String get toplamFaizLabel;

  /// No description provided for @aylikTaksitLabel.
  ///
  /// In tr, this message translates to:
  /// **'Aylık taksit (≈)'**
  String get aylikTaksitLabel;

  /// No description provided for @debtTypeBankLoan.
  ///
  /// In tr, this message translates to:
  /// **'Banka Kredisi'**
  String get debtTypeBankLoan;

  /// No description provided for @debtTypeInstallment.
  ///
  /// In tr, this message translates to:
  /// **'Taksitli'**
  String get debtTypeInstallment;

  /// No description provided for @debtTypePersonal.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel'**
  String get debtTypePersonal;

  /// No description provided for @debtTypeOther.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get debtTypeOther;

  /// No description provided for @vadeAyHint.
  ///
  /// In tr, this message translates to:
  /// **'Vade (ay)'**
  String get vadeAyHint;

  /// No description provided for @aylikTaksitHint.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Taksit'**
  String get aylikTaksitHint;

  /// No description provided for @vadeFarkiYuzdeHint.
  ///
  /// In tr, this message translates to:
  /// **'Vade Farkı %'**
  String get vadeFarkiYuzdeHint;

  /// No description provided for @aylikFaizYuzdeHint.
  ///
  /// In tr, this message translates to:
  /// **'Aylık Faiz %'**
  String get aylikFaizYuzdeHint;

  /// No description provided for @gecikmeFaiziYuzdeHint.
  ///
  /// In tr, this message translates to:
  /// **'Gecikme faizi (%)'**
  String get gecikmeFaiziYuzdeHint;

  /// No description provided for @baslangicLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç'**
  String get baslangicLabel;

  /// No description provided for @vadeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vade'**
  String get vadeLabel;

  /// No description provided for @toplamBorcLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Borç:'**
  String get toplamBorcLabel;

  /// No description provided for @odenenLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ödenen:'**
  String get odenenLabel;

  /// No description provided for @kalanLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kalan:'**
  String get kalanLabel;

  /// No description provided for @kalanTutardanFazlaOlamaz.
  ///
  /// In tr, this message translates to:
  /// **'Kalan tutardan fazla olamaz'**
  String get kalanTutardanFazlaOlamaz;

  /// No description provided for @taksitPlaniFormat.
  ///
  /// In tr, this message translates to:
  /// **'Taksit Planı ({months} ay)'**
  String taksitPlaniFormat(Object months);

  /// No description provided for @odemeGecmisiFormat.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Geçmişi ({count})'**
  String odemeGecmisiFormat(Object count);

  /// No description provided for @gecikmis.
  ///
  /// In tr, this message translates to:
  /// **'Gecikmiş'**
  String get gecikmis;

  /// No description provided for @bekleniyor.
  ///
  /// In tr, this message translates to:
  /// **'Bekleniyor'**
  String get bekleniyor;

  /// No description provided for @cuzdanDuzenleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanı Düzenle'**
  String get cuzdanDuzenleTitle;

  /// No description provided for @yeniCuzdanEkleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Cüzdan Ekle'**
  String get yeniCuzdanEkleTitle;

  /// No description provided for @cuzdanAdiBosOlamaz.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan adı boş olamaz'**
  String get cuzdanAdiBosOlamaz;

  /// No description provided for @cuzdanAdiEnAz2Karakter.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan adı en az 2 karakter olmalı'**
  String get cuzdanAdiEnAz2Karakter;

  /// No description provided for @bakiyeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye *'**
  String get bakiyeLabel;

  /// No description provided for @baslangicBakiyesiLabel.
  ///
  /// In tr, this message translates to:
  /// **'Başlangıç Bakiyesi *'**
  String get baslangicBakiyesiLabel;

  /// No description provided for @bakiyeBosOlamaz.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye boş olamaz'**
  String get bakiyeBosOlamaz;

  /// No description provided for @gecerliBirSayiGirin.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir sayı girin'**
  String get gecerliBirSayiGirin;

  /// No description provided for @tutarCokBuyuk.
  ///
  /// In tr, this message translates to:
  /// **'Tutar çok büyük'**
  String get tutarCokBuyuk;

  /// No description provided for @borcLabel.
  ///
  /// In tr, this message translates to:
  /// **'Borç'**
  String get borcLabel;

  /// No description provided for @alacakLabel.
  ///
  /// In tr, this message translates to:
  /// **'Alacak'**
  String get alacakLabel;

  /// No description provided for @birikimLabel.
  ///
  /// In tr, this message translates to:
  /// **'Birikim'**
  String get birikimLabel;

  /// No description provided for @olustur.
  ///
  /// In tr, this message translates to:
  /// **'Oluştur'**
  String get olustur;

  /// No description provided for @ozelRenkSecin.
  ///
  /// In tr, this message translates to:
  /// **'Özel Renk Seçin'**
  String get ozelRenkSecin;

  /// No description provided for @cuzdanYonetimiTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Yönetimi'**
  String get cuzdanYonetimiTitle;

  /// No description provided for @infoTransferDesc.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlarınız arasında para transferi yapabilirsiniz. Transfer edilen tutar kur farklılıkları gözetilerek kaynak cüzdandan düşülür ve hedefe eklenir.'**
  String get infoTransferDesc;

  /// No description provided for @infoBankImportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bankanızın mobil uygulamasından kopyaladığınız hesap hareketlerini hızlıca içe aktararak işlemlerinizi kolaylaştırabilirsiniz.'**
  String get infoBankImportDesc;

  /// No description provided for @dateBadgeToday.
  ///
  /// In tr, this message translates to:
  /// **'BUGÜN'**
  String get dateBadgeToday;

  /// No description provided for @dateBadgeYesterday.
  ///
  /// In tr, this message translates to:
  /// **'DÜN'**
  String get dateBadgeYesterday;

  /// No description provided for @dateBadgeThisWeek.
  ///
  /// In tr, this message translates to:
  /// **'BU HAFTA'**
  String get dateBadgeThisWeek;

  /// No description provided for @dateBadgeLastWeek.
  ///
  /// In tr, this message translates to:
  /// **'GEÇEN HAFTA'**
  String get dateBadgeLastWeek;

  /// No description provided for @dateBadgeThisMonth.
  ///
  /// In tr, this message translates to:
  /// **'BU AY'**
  String get dateBadgeThisMonth;

  /// No description provided for @dateBadgeLastMonth.
  ///
  /// In tr, this message translates to:
  /// **'GEÇEN AY'**
  String get dateBadgeLastMonth;

  /// No description provided for @categoryFinans.
  ///
  /// In tr, this message translates to:
  /// **'Finans'**
  String get categoryFinans;

  /// No description provided for @categoryGrafikler.
  ///
  /// In tr, this message translates to:
  /// **'Grafikler'**
  String get categoryGrafikler;

  /// No description provided for @categoryIsVeOfis.
  ///
  /// In tr, this message translates to:
  /// **'İş & Ofis'**
  String get categoryIsVeOfis;

  /// No description provided for @categoryAlisveris.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get categoryAlisveris;

  /// No description provided for @categoryYemekVeIcecek.
  ///
  /// In tr, this message translates to:
  /// **'Yemek & İçecek'**
  String get categoryYemekVeIcecek;

  /// No description provided for @categoryUlasim.
  ///
  /// In tr, this message translates to:
  /// **'Ulaşım'**
  String get categoryUlasim;

  /// No description provided for @categoryEvVeYasam.
  ///
  /// In tr, this message translates to:
  /// **'Ev & Yaşam'**
  String get categoryEvVeYasam;

  /// No description provided for @categoryEglence.
  ///
  /// In tr, this message translates to:
  /// **'Eğlence'**
  String get categoryEglence;

  /// No description provided for @categorySaglikVeSpor.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık & Spor'**
  String get categorySaglikVeSpor;

  /// No description provided for @categoryEgitim.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim'**
  String get categoryEgitim;

  /// No description provided for @categoryKisiselBakim.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bakım'**
  String get categoryKisiselBakim;

  /// No description provided for @categoryHayvanlar.
  ///
  /// In tr, this message translates to:
  /// **'Hayvanlar'**
  String get categoryHayvanlar;

  /// No description provided for @categorySeyahat.
  ///
  /// In tr, this message translates to:
  /// **'Seyahat'**
  String get categorySeyahat;

  /// No description provided for @categoryTeknoloji.
  ///
  /// In tr, this message translates to:
  /// **'Teknoloji'**
  String get categoryTeknoloji;

  /// No description provided for @categoryIletisim.
  ///
  /// In tr, this message translates to:
  /// **'İletişim'**
  String get categoryIletisim;

  /// No description provided for @categoryHediyeVeBagis.
  ///
  /// In tr, this message translates to:
  /// **'Hediye & Bağış'**
  String get categoryHediyeVeBagis;

  /// No description provided for @categoryHizmetler.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler'**
  String get categoryHizmetler;

  /// No description provided for @categoryDiger.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get categoryDiger;

  /// No description provided for @defaultCategoryGroceries.
  ///
  /// In tr, this message translates to:
  /// **'Market'**
  String get defaultCategoryGroceries;

  /// No description provided for @defaultCategoryFood.
  ///
  /// In tr, this message translates to:
  /// **'Yemek'**
  String get defaultCategoryFood;

  /// No description provided for @defaultCategoryTransport.
  ///
  /// In tr, this message translates to:
  /// **'Ulaşım'**
  String get defaultCategoryTransport;

  /// No description provided for @defaultCategoryBills.
  ///
  /// In tr, this message translates to:
  /// **'Fatura'**
  String get defaultCategoryBills;

  /// No description provided for @defaultCategoryRent.
  ///
  /// In tr, this message translates to:
  /// **'Kira'**
  String get defaultCategoryRent;

  /// No description provided for @defaultCategoryShopping.
  ///
  /// In tr, this message translates to:
  /// **'Alışveriş'**
  String get defaultCategoryShopping;

  /// No description provided for @defaultCategoryHealth.
  ///
  /// In tr, this message translates to:
  /// **'Sağlık'**
  String get defaultCategoryHealth;

  /// No description provided for @defaultCategoryEducation.
  ///
  /// In tr, this message translates to:
  /// **'Eğitim'**
  String get defaultCategoryEducation;

  /// No description provided for @defaultCategoryEntertainment.
  ///
  /// In tr, this message translates to:
  /// **'Eğlence'**
  String get defaultCategoryEntertainment;

  /// No description provided for @defaultCategorySalary.
  ///
  /// In tr, this message translates to:
  /// **'Maaş'**
  String get defaultCategorySalary;

  /// No description provided for @defaultCategorySideIncome.
  ///
  /// In tr, this message translates to:
  /// **'Ek Gelir'**
  String get defaultCategorySideIncome;

  /// No description provided for @defaultCategoryFreelance.
  ///
  /// In tr, this message translates to:
  /// **'Serbest'**
  String get defaultCategoryFreelance;

  /// No description provided for @defaultCategoryInvestment.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım'**
  String get defaultCategoryInvestment;

  /// No description provided for @kategorisiz.
  ///
  /// In tr, this message translates to:
  /// **'Kategorisiz'**
  String get kategorisiz;

  /// No description provided for @detailLabelTarih.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get detailLabelTarih;

  /// No description provided for @detailLabelSaat.
  ///
  /// In tr, this message translates to:
  /// **'Saat'**
  String get detailLabelSaat;

  /// No description provided for @detailLabelTur.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get detailLabelTur;

  /// No description provided for @detailLabelGelir.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get detailLabelGelir;

  /// No description provided for @detailLabelGider.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get detailLabelGider;

  /// No description provided for @detailLabelIslemSonrasiBakiye.
  ///
  /// In tr, this message translates to:
  /// **'İşlem sonrası bakiye'**
  String get detailLabelIslemSonrasiBakiye;

  /// No description provided for @akilliIcgoruler.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı İçgörüler'**
  String get akilliIcgoruler;

  /// No description provided for @gunlukOrtalamaHarcama.
  ///
  /// In tr, this message translates to:
  /// **'Günlük ortalama harcama'**
  String get gunlukOrtalamaHarcama;

  /// No description provided for @enCokHarcananGun.
  ///
  /// In tr, this message translates to:
  /// **'En çok harcadığınız gün'**
  String get enCokHarcananGun;

  /// No description provided for @enCokHarcananKategori.
  ///
  /// In tr, this message translates to:
  /// **'En çok harcanan kategori'**
  String get enCokHarcananKategori;

  /// No description provided for @enBuyukHarcama.
  ///
  /// In tr, this message translates to:
  /// **'En büyük harcama'**
  String get enBuyukHarcama;

  /// No description provided for @birikimOrani.
  ///
  /// In tr, this message translates to:
  /// **'Birikim oranı'**
  String get birikimOrani;

  /// No description provided for @buDonemdeIslemYok.
  ///
  /// In tr, this message translates to:
  /// **'Bu dönemde işlem yok'**
  String get buDonemdeIslemYok;

  /// No description provided for @tekrarlayanOdemeler.
  ///
  /// In tr, this message translates to:
  /// **'Tekrarlayan ödemeler'**
  String get tekrarlayanOdemeler;

  /// No description provided for @tekrarlayanTespitOzeti.
  ///
  /// In tr, this message translates to:
  /// **'{count} olası düzenli ödeme tespit ettik'**
  String tekrarlayanTespitOzeti(int count);

  /// No description provided for @kezTekrarlandi.
  ///
  /// In tr, this message translates to:
  /// **'{count} kez tekrarlandı'**
  String kezTekrarlandi(int count);

  /// No description provided for @duzenliOdemeOlarakEkle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli Ödeme olarak ekle'**
  String get duzenliOdemeOlarakEkle;

  /// No description provided for @duzenliOdemeEklendi.
  ///
  /// In tr, this message translates to:
  /// **'\'{title}\' düzenli ödemelere eklendi'**
  String duzenliOdemeEklendi(String title);

  /// No description provided for @duzenliOdemeEklenemedi.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli ödeme eklenemedi'**
  String get duzenliOdemeEklenemedi;

  /// No description provided for @borcNakitEtkiBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Bu borç karşılığında ne aldın?'**
  String get borcNakitEtkiBaslik;

  /// No description provided for @borcNakitEtkiAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Seçimine göre cüzdan bakiyen otomatik güncellenir; ayrıca elle işlem eklemen gerekmez.'**
  String get borcNakitEtkiAciklama;

  /// No description provided for @borcNakitSecenekBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Nakit aldım'**
  String get borcNakitSecenekBaslik;

  /// No description provided for @borcNakitSecenekGovde.
  ///
  /// In tr, this message translates to:
  /// **'{tutar} cüzdan bakiyene gelir olarak eklenir. Yaptığın geri ödemeler bakiyeden gider olarak düşülür.'**
  String borcNakitSecenekGovde(String tutar);

  /// No description provided for @borcUrunSecenekBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Ürün / hizmet aldım'**
  String get borcUrunSecenekBaslik;

  /// No description provided for @borcUrunSecenekGovde.
  ///
  /// In tr, this message translates to:
  /// **'Para eline geçmediği için bakiyen değişmez. Taksit ve geri ödemelerin bakiyeden gider olarak düşülür.'**
  String get borcUrunSecenekGovde;

  /// No description provided for @devamEt.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get devamEt;

  /// No description provided for @bugun.
  ///
  /// In tr, this message translates to:
  /// **'Bugün'**
  String get bugun;

  /// No description provided for @islemBuguneAyarliIpucu.
  ///
  /// In tr, this message translates to:
  /// **'Tarih bugüne ayarlı — başka bir güne eklemek için tarihe dokun.'**
  String get islemBuguneAyarliIpucu;

  /// No description provided for @mevcutDegerAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Yatırımın bugünkü piyasa değeri; \'Hesapla\' ile güncel fiyattan güncellenir.'**
  String get mevcutDegerAciklama;

  /// No description provided for @toplamMaliyetAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Bu yatırıma ödediğin toplam tutar (maliyetin). \'Hesapla\' bunu değiştirmez; kâr/zarar bununla hesaplanır.'**
  String get toplamMaliyetAciklama;

  /// No description provided for @paraBirimiLabel.
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get paraBirimiLabel;

  /// No description provided for @paraBirimiKilitliHint.
  ///
  /// In tr, this message translates to:
  /// **'İşlem geçmişi olan cüzdanın para birimi değiştirilemez'**
  String get paraBirimiKilitliHint;

  /// No description provided for @sadeceTlCuzdanBorc.
  ///
  /// In tr, this message translates to:
  /// **'Borç/alacak takibi şimdilik yalnız TL cüzdanlarda kullanılabilir'**
  String get sadeceTlCuzdanBorc;

  /// No description provided for @sadeceTlCuzdanYatirim.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım takibi şimdilik yalnız TL cüzdanlarda kullanılabilir'**
  String get sadeceTlCuzdanYatirim;

  /// No description provided for @yaklasikKarsilikFormat.
  ///
  /// In tr, this message translates to:
  /// **'≈ {tutar}'**
  String yaklasikKarsilikFormat(String tutar);

  /// No description provided for @toplamTlKarsilikFormat.
  ///
  /// In tr, this message translates to:
  /// **'Toplam ≈ {tutar}'**
  String toplamTlKarsilikFormat(String tutar);

  /// No description provided for @cuzdanlarArasiTransfer.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlar Arası Transfer'**
  String get cuzdanlarArasiTransfer;

  /// No description provided for @transferEt.
  ///
  /// In tr, this message translates to:
  /// **'Transfer Et'**
  String get transferEt;

  /// No description provided for @transferHedefCuzdan.
  ///
  /// In tr, this message translates to:
  /// **'Hedef cüzdan'**
  String get transferHedefCuzdan;

  /// No description provided for @transferOnizlemeFormat.
  ///
  /// In tr, this message translates to:
  /// **'Hedefe ≈ {tutar} geçecek'**
  String transferOnizlemeFormat(String tutar);

  /// No description provided for @transferKurYok.
  ///
  /// In tr, this message translates to:
  /// **'Kur bilgisi alınamadı — internete bağlanınca tekrar deneyin'**
  String get transferKurYok;

  /// No description provided for @transferBasarili.
  ///
  /// In tr, this message translates to:
  /// **'Transfer tamamlandı'**
  String get transferBasarili;

  /// No description provided for @transferBasarisiz.
  ///
  /// In tr, this message translates to:
  /// **'Transfer başarısız oldu'**
  String get transferBasarisiz;

  /// No description provided for @transferIcinIkiCuzdanGerekli.
  ///
  /// In tr, this message translates to:
  /// **'Transfer için en az iki cüzdan gerekli'**
  String get transferIcinIkiCuzdanGerekli;

  /// No description provided for @transferBakiyeAsimiMesaj.
  ///
  /// In tr, this message translates to:
  /// **'Tutar, cüzdan bakiyesinden ({bakiye}) fazla. Devam ederseniz bakiye eksiye düşer. Devam edilsin mi?'**
  String transferBakiyeAsimiMesaj(String bakiye);

  /// No description provided for @yardimVeTurlar.
  ///
  /// In tr, this message translates to:
  /// **'Yardım & Turlar'**
  String get yardimVeTurlar;

  /// No description provided for @genelTanitimiTekrarGoster.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ve Bildirim Tanıtımını Tekrar Göster'**
  String get genelTanitimiTekrarGoster;

  /// No description provided for @yatirimBirikimTuru.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım/Birikim Turu'**
  String get yatirimBirikimTuru;

  /// No description provided for @islemlerTuru.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler Turu'**
  String get islemlerTuru;

  /// No description provided for @borcAlacakTuru.
  ///
  /// In tr, this message translates to:
  /// **'Borç & Alacak Turu'**
  String get borcAlacakTuru;

  /// No description provided for @onboardingInvestmentSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Birikiminiz'**
  String get onboardingInvestmentSummaryTitle;

  /// No description provided for @onboardingInvestmentSummaryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Toplam yatırım, güncel değer ve kâr/zararınızı burada tek bakışta görürsünüz.'**
  String get onboardingInvestmentSummaryDesc;

  /// No description provided for @onboardingInvestmentPortfolioTitle.
  ///
  /// In tr, this message translates to:
  /// **'Portföyünüz'**
  String get onboardingInvestmentPortfolioTitle;

  /// No description provided for @onboardingInvestmentPortfolioDesc.
  ///
  /// In tr, this message translates to:
  /// **'Altın, hisse ve özel yatırımlarınızın listesi burada. Bir karta dokunarak katkı, satış, düzenleme ve silme işlemlerine ulaşabilirsiniz.'**
  String get onboardingInvestmentPortfolioDesc;

  /// No description provided for @onboardingTransactionsFilterTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mod ve Filtreler'**
  String get onboardingTransactionsFilterTitle;

  /// No description provided for @onboardingTransactionsFilterDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gelir/Gider modunu değiştirin ve kategoriye, tarihe veya tutara göre filtreleyin.'**
  String get onboardingTransactionsFilterDesc;

  /// No description provided for @onboardingTransactionsViewToggleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Liste / Takvim'**
  String get onboardingTransactionsViewToggleTitle;

  /// No description provided for @onboardingTransactionsViewToggleDesc.
  ///
  /// In tr, this message translates to:
  /// **'İşlemlerinizi liste veya takvim görünümünde inceleyebilirsiniz.'**
  String get onboardingTransactionsViewToggleDesc;

  /// No description provided for @onboardingDebtTabsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Borçlarım / Alacaklarım'**
  String get onboardingDebtTabsTitle;

  /// No description provided for @onboardingDebtTabsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Verdiğiniz ve aldığınız borçları buradan sekmeler halinde takip edersiniz.'**
  String get onboardingDebtTabsDesc;

  /// No description provided for @onboardingNavHintHeader.
  ///
  /// In tr, this message translates to:
  /// **'Nasıl Gezinilir?'**
  String get onboardingNavHintHeader;

  /// No description provided for @onboardingNavHintSwipeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sağa / Sola Kaydırın'**
  String get onboardingNavHintSwipeTitle;

  /// No description provided for @onboardingNavHintSwipeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yatırım, İşlemler ve Borç ekranları arasında geçiş yapın.'**
  String get onboardingNavHintSwipeDesc;

  /// No description provided for @onboardingNavHintDragTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yukarı Sürükleyin'**
  String get onboardingNavHintDragTitle;

  /// No description provided for @onboardingNavHintDragDesc.
  ///
  /// In tr, this message translates to:
  /// **'Detay, Rapor, Bekleyen ve Geçmiş gibi alt sayfalara ulaşın.'**
  String get onboardingNavHintDragDesc;

  /// No description provided for @onboardingNavHintAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Simgelere Dokunun'**
  String get onboardingNavHintAddTitle;

  /// No description provided for @onboardingNavHintAddDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yeni gelir, gider, yatırım, borç veya alacak ekleyin.'**
  String get onboardingNavHintAddDesc;

  /// No description provided for @onboardingInvestmentDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Birikim Detayı'**
  String get onboardingInvestmentDetailTitle;

  /// No description provided for @onboardingInvestmentDetailDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yatırımlarınızla ilgili tüm alım/satım hareketlerini burada kronolojik olarak görürsünüz.'**
  String get onboardingInvestmentDetailDesc;

  /// No description provided for @onboardingTransactionsInsightsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Akıllı İçgörüler'**
  String get onboardingTransactionsInsightsTitle;

  /// No description provided for @onboardingTransactionsInsightsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Harcama alışkanlıklarınızla ilgili otomatik tespitler ve olası tekrarlayan ödemeler burada gösterilir.'**
  String get onboardingTransactionsInsightsDesc;

  /// No description provided for @onboardingTransactionsReportTitle.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Raporu'**
  String get onboardingTransactionsReportTitle;

  /// No description provided for @onboardingTransactionsReportDesc.
  ///
  /// In tr, this message translates to:
  /// **'Seçtiğiniz tarih aralığı için gelir/gider dağılımını grafiklerle inceleyin, dışa aktarın.'**
  String get onboardingTransactionsReportDesc;

  /// No description provided for @onboardingDebtHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş'**
  String get onboardingDebtHistoryTitle;

  /// No description provided for @onboardingDebtHistoryDesc.
  ///
  /// In tr, this message translates to:
  /// **'Ödenmiş borç ve tahsil edilmiş alacaklarınızın tam geçmişi burada saklanır.'**
  String get onboardingDebtHistoryDesc;

  /// No description provided for @notificationSettings.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim Ayarları'**
  String get notificationSettings;

  /// No description provided for @notificationSettingsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kritik ve rastgele bildirim tercihlerinizi yönetin.'**
  String get notificationSettingsDesc;

  /// No description provided for @randomReminders.
  ///
  /// In tr, this message translates to:
  /// **'Motive Edici Hatırlatıcılar'**
  String get randomReminders;

  /// No description provided for @randomRemindersOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get randomRemindersOff;

  /// No description provided for @randomRemindersLow.
  ///
  /// In tr, this message translates to:
  /// **'Az (Günde 1)'**
  String get randomRemindersLow;

  /// No description provided for @randomRemindersMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta (Günde 2)'**
  String get randomRemindersMedium;

  /// No description provided for @randomRemindersHigh.
  ///
  /// In tr, this message translates to:
  /// **'Çok (Günde 3)'**
  String get randomRemindersHigh;

  /// No description provided for @criticalNotifications.
  ///
  /// In tr, this message translates to:
  /// **'Kritik Bildirimler'**
  String get criticalNotifications;

  /// No description provided for @debtReminders.
  ///
  /// In tr, this message translates to:
  /// **'Borç/Alacak Hatırlatıcıları'**
  String get debtReminders;

  /// No description provided for @recurringReminders.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli İşlem Hatırlatıcıları'**
  String get recurringReminders;

  /// No description provided for @budgetAlerts.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Uyarıları'**
  String get budgetAlerts;

  /// No description provided for @notificationRationaleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get notificationRationaleTitle;

  /// No description provided for @notificationRationaleBody.
  ///
  /// In tr, this message translates to:
  /// **'CuNehat; borç/alacak vade tarihleri yaklaştığında ve tekrarlayan işlemler onay beklediğinde size hatırlatma gönderebilir. Bunun için bildirim izni gerekir. İzin vermeseniz de uygulamayı kullanmaya devam edebilirsiniz; sadece hatırlatmalar gösterilmez.'**
  String get notificationRationaleBody;

  /// No description provided for @notificationRationaleLater.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi Değil'**
  String get notificationRationaleLater;

  /// No description provided for @notificationPermissionOffTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bildirim izni kapalı'**
  String get notificationPermissionOffTitle;

  /// No description provided for @notificationPermissionOffDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki hatırlatmalar ancak sistem izni verildiğinde ulaşabilir.'**
  String get notificationPermissionOffDesc;

  /// No description provided for @notificationPermissionGrant.
  ///
  /// In tr, this message translates to:
  /// **'İzin Ver'**
  String get notificationPermissionGrant;

  /// No description provided for @notificationPermissionOpenSettings.
  ///
  /// In tr, this message translates to:
  /// **'İzin daha önce reddedildiği için sistem bir daha sormuyor. Bildirimleri sistem ayarlarından açabilirsiniz.'**
  String get notificationPermissionOpenSettings;

  /// No description provided for @notificationPermissionOpenSettingsAction.
  ///
  /// In tr, this message translates to:
  /// **'Ayarları Aç'**
  String get notificationPermissionOpenSettingsAction;

  /// No description provided for @notificationSendTest.
  ///
  /// In tr, this message translates to:
  /// **'Test bildirimi gönder'**
  String get notificationSendTest;

  /// No description provided for @notificationTestSent.
  ///
  /// In tr, this message translates to:
  /// **'Test bildirimi gönderildi'**
  String get notificationTestSent;

  /// No description provided for @notificationTestFailedNoPermission.
  ///
  /// In tr, this message translates to:
  /// **'Test bildirimi gönderilemedi: bildirim izni kapalı'**
  String get notificationTestFailedNoPermission;

  /// No description provided for @notificationTestFailed.
  ///
  /// In tr, this message translates to:
  /// **'Test bildirimi gönderilemedi'**
  String get notificationTestFailed;

  /// No description provided for @notificationTestTitle.
  ///
  /// In tr, this message translates to:
  /// **'CuNehat test bildirimi'**
  String get notificationTestTitle;

  /// No description provided for @notificationTestBody.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler çalışıyor. Hatırlatmalarınız bu şekilde görünecek.'**
  String get notificationTestBody;

  /// No description provided for @notifChannelCriticalName.
  ///
  /// In tr, this message translates to:
  /// **'Kritik Hatırlatmalar'**
  String get notifChannelCriticalName;

  /// No description provided for @notifChannelCriticalDesc.
  ///
  /// In tr, this message translates to:
  /// **'Borç vadeleri ve bütçe aşımları'**
  String get notifChannelCriticalDesc;

  /// No description provided for @notifChannelRecurringName.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli İşlemler'**
  String get notifChannelRecurringName;

  /// No description provided for @notifChannelRecurringDesc.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen düzenli işlem hatırlatmaları'**
  String get notifChannelRecurringDesc;

  /// No description provided for @notifChannelMotivationalName.
  ///
  /// In tr, this message translates to:
  /// **'Motive Edici Hatırlatıcılar'**
  String get notifChannelMotivationalName;

  /// No description provided for @notifChannelMotivationalDesc.
  ///
  /// In tr, this message translates to:
  /// **'Harcama girmeyi hatırlatan günlük mesajlar'**
  String get notifChannelMotivationalDesc;

  /// No description provided for @notifRecurringDueTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli İşlem Vakti'**
  String get notifRecurringDueTitle;

  /// No description provided for @notifRecurringDueBody.
  ///
  /// In tr, this message translates to:
  /// **'{title} onayınızı bekliyor.'**
  String notifRecurringDueBody(Object title);

  /// No description provided for @notifDebtUpcomingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Borç Hatırlatması'**
  String get notifDebtUpcomingTitle;

  /// No description provided for @notifDebtUpcomingBody.
  ///
  /// In tr, this message translates to:
  /// **'{title} başlıklı borcunuzun son ödeme tarihi yaklaştı.'**
  String notifDebtUpcomingBody(Object title);

  /// No description provided for @notifDebtDueTitle.
  ///
  /// In tr, this message translates to:
  /// **'Borç Son Ödeme Tarihi!'**
  String get notifDebtDueTitle;

  /// No description provided for @notifDebtDueBody.
  ///
  /// In tr, this message translates to:
  /// **'{title} başlıklı borcunuzun son ödeme tarihi bugün.'**
  String notifDebtDueBody(Object title);

  /// No description provided for @notifBudgetWarningTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Uyarısı'**
  String get notifBudgetWarningTitle;

  /// No description provided for @notifBudgetWarningBody.
  ///
  /// In tr, this message translates to:
  /// **'{category} bütçenizin %80\'ine ulaştınız.'**
  String notifBudgetWarningBody(Object category);

  /// No description provided for @notifBudgetExceededTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Aşıldı!'**
  String get notifBudgetExceededTitle;

  /// No description provided for @notifBudgetExceededBody.
  ///
  /// In tr, this message translates to:
  /// **'{category} bütçenizi aştınız.'**
  String notifBudgetExceededBody(Object category);

  /// No description provided for @notifBudgetFilledTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bütçe Doldu'**
  String get notifBudgetFilledTitle;

  /// No description provided for @notifBudgetFilledBody.
  ///
  /// In tr, this message translates to:
  /// **'{category} bütçe limitinizin tamamına ulaştınız (%100).'**
  String notifBudgetFilledBody(Object category);

  /// No description provided for @notifDailyReminderTitle.
  ///
  /// In tr, this message translates to:
  /// **'CuNehat'**
  String get notifDailyReminderTitle;

  /// No description provided for @notifDailyReminder1.
  ///
  /// In tr, this message translates to:
  /// **'Bugün hiç harcama girdin mi? Bütçeni güncel tut!'**
  String get notifDailyReminder1;

  /// No description provided for @notifDailyReminder2.
  ///
  /// In tr, this message translates to:
  /// **'Finansal durumunu kontrol etme vakti!'**
  String get notifDailyReminder2;

  /// No description provided for @notifDailyReminder3.
  ///
  /// In tr, this message translates to:
  /// **'Gelir ve giderlerini takip etmek bütçeni korur.'**
  String get notifDailyReminder3;

  /// No description provided for @notifDailyReminder4.
  ///
  /// In tr, this message translates to:
  /// **'Küçük birikimler büyük hedeflere ulaştırır!'**
  String get notifDailyReminder4;

  /// No description provided for @notifDailyReminder5.
  ///
  /// In tr, this message translates to:
  /// **'Harcamalarını gözden geçirmeyi unutma.'**
  String get notifDailyReminder5;

  /// No description provided for @notifDailyReminder6.
  ///
  /// In tr, this message translates to:
  /// **'Bütçeni planla, rahat yaşa!'**
  String get notifDailyReminder6;

  /// No description provided for @recurringNudgeCount.
  ///
  /// In tr, this message translates to:
  /// **'{count} işlem onay bekliyor'**
  String recurringNudgeCount(Object count);

  /// No description provided for @recurringNudgeOldest.
  ///
  /// In tr, this message translates to:
  /// **'En eskisi {days} gün gecikmiş'**
  String recurringNudgeOldest(Object days);

  /// No description provided for @sonra.
  ///
  /// In tr, this message translates to:
  /// **'Sonra'**
  String get sonra;

  /// No description provided for @incele.
  ///
  /// In tr, this message translates to:
  /// **'İncele'**
  String get incele;

  /// No description provided for @onayBekleyenler.
  ///
  /// In tr, this message translates to:
  /// **'Onay Bekleyenler'**
  String get onayBekleyenler;

  /// No description provided for @sablonlar.
  ///
  /// In tr, this message translates to:
  /// **'Şablonlar'**
  String get sablonlar;

  /// No description provided for @yaklasanlar.
  ///
  /// In tr, this message translates to:
  /// **'Yaklaşanlar'**
  String get yaklasanlar;

  /// No description provided for @duraklatilmislar.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatılmış'**
  String get duraklatilmislar;

  /// No description provided for @duraklatildi.
  ///
  /// In tr, this message translates to:
  /// **'Duraklatıldı'**
  String get duraklatildi;

  /// No description provided for @onayBekleyenYok.
  ///
  /// In tr, this message translates to:
  /// **'Onay bekleyen işlem yok.'**
  String get onayBekleyenYok;

  /// No description provided for @aylikDuzenliGider.
  ///
  /// In tr, this message translates to:
  /// **'Aylık düzenli gider'**
  String get aylikDuzenliGider;

  /// No description provided for @aylikDuzenliGelir.
  ///
  /// In tr, this message translates to:
  /// **'Aylık düzenli gelir'**
  String get aylikDuzenliGelir;

  /// No description provided for @aktifSablonSayisi.
  ///
  /// In tr, this message translates to:
  /// **'{count} aktif şablon'**
  String aktifSablonSayisi(Object count);

  /// No description provided for @yarin.
  ///
  /// In tr, this message translates to:
  /// **'Yarın'**
  String get yarin;

  /// No description provided for @gunSonra.
  ///
  /// In tr, this message translates to:
  /// **'{days} gün sonra'**
  String gunSonra(Object days);

  /// No description provided for @bekleyenVadeSayisi.
  ///
  /// In tr, this message translates to:
  /// **'{count} vade birikmiş'**
  String bekleyenVadeSayisi(Object count);

  /// No description provided for @tumunuOnayla.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü Onayla'**
  String get tumunuOnayla;

  /// No description provided for @tumunuOnaylaBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Birikmiş vadeleri onayla'**
  String get tumunuOnaylaBaslik;

  /// No description provided for @tumunuOnaylaAciklama.
  ///
  /// In tr, this message translates to:
  /// **'\"{title}\" için birikmiş {count} vadenin tümü deftere işlenecek.'**
  String tumunuOnaylaAciklama(Object title, Object count);

  /// No description provided for @buVadeyiAtla.
  ///
  /// In tr, this message translates to:
  /// **'Bu vadeyi atla'**
  String get buVadeyiAtla;

  /// No description provided for @sablonuSilAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Şablonu sil (gelecek vadeler de dahil)'**
  String get sablonuSilAciklama;

  /// No description provided for @tumTurlariSifirla.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Turları Sıfırla'**
  String get tumTurlariSifirla;

  /// No description provided for @tumTurlariSifirlaAciklama.
  ///
  /// In tr, this message translates to:
  /// **'Alt sayfa turları da dahil, tüm ekranları ziyaret ettiğinizde tekrar gösterilir.'**
  String get tumTurlariSifirlaAciklama;

  /// No description provided for @tumTurlarSifirlandi.
  ///
  /// In tr, this message translates to:
  /// **'Turlar sıfırlandı'**
  String get tumTurlarSifirlandi;

  /// No description provided for @onboardingAppBarMenuTitle.
  ///
  /// In tr, this message translates to:
  /// **'Menü'**
  String get onboardingAppBarMenuTitle;

  /// No description provided for @onboardingAppBarMenuDesc.
  ///
  /// In tr, this message translates to:
  /// **'Buradan bütçe, düzenli işlemler, profil ve ayarlara ulaşabilirsiniz.'**
  String get onboardingAppBarMenuDesc;

  /// No description provided for @onboardingAppBarWalletTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanınız'**
  String get onboardingAppBarWalletTitle;

  /// No description provided for @onboardingAppBarWalletDesc.
  ///
  /// In tr, this message translates to:
  /// **'Aktif cüzdanın adı ve bakiyesi burada görünür. Dokunarak cüzdanlar arasında geçiş yapabilir veya yeni cüzdan ekleyebilirsiniz.'**
  String get onboardingAppBarWalletDesc;

  /// No description provided for @onboardingWalletManagementTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Cüzdan Ekle'**
  String get onboardingWalletManagementTitle;

  /// No description provided for @onboardingWalletManagementDesc.
  ///
  /// In tr, this message translates to:
  /// **'Farklı hesaplarınız veya döviz cüzdanlarınız için buradan yeni bir cüzdan oluşturabilirsiniz.'**
  String get onboardingWalletManagementDesc;

  /// No description provided for @onboardingTransactionsAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tutarı Girin'**
  String get onboardingTransactionsAddTitle;

  /// No description provided for @onboardingTransactionsAddDesc.
  ///
  /// In tr, this message translates to:
  /// **'Tutarı yazın, ardından kategori ve tarih seçip kaydedin. İsterseniz tekrar sıklığı da ayarlayabilirsiniz.'**
  String get onboardingTransactionsAddDesc;

  /// No description provided for @onboardingDebtAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tutarı Girin'**
  String get onboardingDebtAddTitle;

  /// No description provided for @onboardingDebtAddDesc.
  ///
  /// In tr, this message translates to:
  /// **'Borç/alacak tutarını ve türünü seçin; vade tarihi ve taksit gibi detayları aşağıda tamamlayın.'**
  String get onboardingDebtAddDesc;

  /// No description provided for @onboardingInvestmentAddTitle.
  ///
  /// In tr, this message translates to:
  /// **'Mevcut Değer'**
  String get onboardingInvestmentAddTitle;

  /// No description provided for @onboardingInvestmentAddDesc.
  ///
  /// In tr, this message translates to:
  /// **'Yatırımın güncel değerini girin. Aşağıda miktar, tür ve isteğe bağlı hedef tutar gibi detayları tamamlayabilirsiniz.'**
  String get onboardingInvestmentAddDesc;

  /// No description provided for @onboardingBudgetsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Bütçe Ekle'**
  String get onboardingBudgetsTitle;

  /// No description provided for @onboardingBudgetsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bir kategori seçip aylık harcama limiti belirleyin; limit aşıldığında bilgilendirilirsiniz.'**
  String get onboardingBudgetsDesc;

  /// No description provided for @onboardingRecurringTemplatesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli İşlemler'**
  String get onboardingRecurringTemplatesTitle;

  /// No description provided for @onboardingRecurringTemplatesDesc.
  ///
  /// In tr, this message translates to:
  /// **'Gelir/gider eklerken seçtiğiniz tekrar sıklığından oluşan şablonlar burada listelenir; duraklatabilir veya silebilirsiniz.'**
  String get onboardingRecurringTemplatesDesc;

  /// No description provided for @fisEkle.
  ///
  /// In tr, this message translates to:
  /// **'Fiş/fotoğraf ekle'**
  String get fisEkle;

  /// No description provided for @fisEkli.
  ///
  /// In tr, this message translates to:
  /// **'Fiş eklendi'**
  String get fisEkli;

  /// No description provided for @fisKamera.
  ///
  /// In tr, this message translates to:
  /// **'Kamera'**
  String get fisKamera;

  /// No description provided for @fisGaleri.
  ///
  /// In tr, this message translates to:
  /// **'Galeri'**
  String get fisGaleri;

  /// No description provided for @fisDegistir.
  ///
  /// In tr, this message translates to:
  /// **'Değiştir'**
  String get fisDegistir;

  /// No description provided for @fisKaldir.
  ///
  /// In tr, this message translates to:
  /// **'Kaldır'**
  String get fisKaldir;

  /// No description provided for @fisGoruntule.
  ///
  /// In tr, this message translates to:
  /// **'Fişi görüntüle'**
  String get fisGoruntule;

  /// No description provided for @fisOcrTaraniyor.
  ///
  /// In tr, this message translates to:
  /// **'Fiş taranıyor…'**
  String get fisOcrTaraniyor;

  /// No description provided for @fisOcrDolduruldu.
  ///
  /// In tr, this message translates to:
  /// **'Bilgiler fişten dolduruldu — lütfen kontrol edin'**
  String get fisOcrDolduruldu;

  /// No description provided for @fisCihazdaYok.
  ///
  /// In tr, this message translates to:
  /// **'Görsel bu cihazda yok'**
  String get fisCihazdaYok;

  /// No description provided for @bankImportSettingsEntry.
  ///
  /// In tr, this message translates to:
  /// **'Banka ekstresi içe aktar'**
  String get bankImportSettingsEntry;

  /// No description provided for @bankImportSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'CSV/Excel/PDF ekstresini işlemlere dönüştür'**
  String get bankImportSettingsSubtitle;

  /// No description provided for @bankImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Banka Ekstresi İçe Aktar'**
  String get bankImportTitle;

  /// No description provided for @bankImportParsing.
  ///
  /// In tr, this message translates to:
  /// **'Dosya taranıyor…'**
  String get bankImportParsing;

  /// No description provided for @bankImportNoWallet.
  ///
  /// In tr, this message translates to:
  /// **'Önce bir cüzdan oluşturun.'**
  String get bankImportNoWallet;

  /// No description provided for @bankImportSetupHint.
  ///
  /// In tr, this message translates to:
  /// **'Bankandan dışa aktardığın hesap hareketleri dosyasını (CSV, Excel ya da PDF) seç; biçimi otomatik algılarız. Hareketler tarih/tutar/kategori otomatik algılanmış olarak önce incelemene sunulur — bu algılama hatalı olabilir, onaylamadan önce mutlaka kontrol et.'**
  String get bankImportSetupHint;

  /// No description provided for @bankImportTargetWallet.
  ///
  /// In tr, this message translates to:
  /// **'Hedef cüzdan'**
  String get bankImportTargetWallet;

  /// No description provided for @bankImportPickFile.
  ///
  /// In tr, this message translates to:
  /// **'Dosya seç ve tara'**
  String get bankImportPickFile;

  /// No description provided for @bankImportCommitting.
  ///
  /// In tr, this message translates to:
  /// **'Ekleniyor…'**
  String get bankImportCommitting;

  /// No description provided for @bankImportClose.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get bankImportClose;

  /// No description provided for @bankImportRetry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get bankImportRetry;

  /// No description provided for @bankImportMappingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sütunları eşle'**
  String get bankImportMappingTitle;

  /// No description provided for @bankImportColDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih sütunu'**
  String get bankImportColDate;

  /// No description provided for @bankImportColDesc.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama sütunu'**
  String get bankImportColDesc;

  /// No description provided for @bankImportColAmount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar sütunu'**
  String get bankImportColAmount;

  /// No description provided for @bankImportColDebit.
  ///
  /// In tr, this message translates to:
  /// **'Borç (gider)'**
  String get bankImportColDebit;

  /// No description provided for @bankImportColCredit.
  ///
  /// In tr, this message translates to:
  /// **'Alacak (gelir)'**
  String get bankImportColCredit;

  /// No description provided for @bankImportSignMode.
  ///
  /// In tr, this message translates to:
  /// **'Tutar işareti'**
  String get bankImportSignMode;

  /// No description provided for @bankImportSignSingle.
  ///
  /// In tr, this message translates to:
  /// **'Tek sütun (− gider)'**
  String get bankImportSignSingle;

  /// No description provided for @bankImportSignDebitCredit.
  ///
  /// In tr, this message translates to:
  /// **'Borç / Alacak'**
  String get bankImportSignDebitCredit;

  /// No description provided for @bankImportDateFormat.
  ///
  /// In tr, this message translates to:
  /// **'Tarih biçimi'**
  String get bankImportDateFormat;

  /// No description provided for @bankImportDateAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get bankImportDateAuto;

  /// No description provided for @bankImportContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam'**
  String get bankImportContinue;

  /// No description provided for @bankImportColumnN.
  ///
  /// In tr, this message translates to:
  /// **'{n}. sütun'**
  String bankImportColumnN(int n);

  /// No description provided for @bankImportPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme (ilk hareketler)'**
  String get bankImportPreviewTitle;

  /// No description provided for @bankImportRoleDate.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get bankImportRoleDate;

  /// No description provided for @bankImportRoleDesc.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get bankImportRoleDesc;

  /// No description provided for @bankImportRoleAmount.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get bankImportRoleAmount;

  /// No description provided for @bankImportRoleDebit.
  ///
  /// In tr, this message translates to:
  /// **'Borç'**
  String get bankImportRoleDebit;

  /// No description provided for @bankImportRoleCredit.
  ///
  /// In tr, this message translates to:
  /// **'Alacak'**
  String get bankImportRoleCredit;

  /// No description provided for @bankImportRoleBalance.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye'**
  String get bankImportRoleBalance;

  /// No description provided for @bankImportEditDescTitle.
  ///
  /// In tr, this message translates to:
  /// **'Açıklamayı düzenle'**
  String get bankImportEditDescTitle;

  /// No description provided for @bankImportEditDescLabel.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get bankImportEditDescLabel;

  /// No description provided for @bankImportEditAmountTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tutarı düzenle'**
  String get bankImportEditAmountTitle;

  /// No description provided for @bankImportEditAmountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tutar'**
  String get bankImportEditAmountLabel;

  /// No description provided for @bankImportFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get bankImportFilterAll;

  /// No description provided for @bankImportFilterUncategorized.
  ///
  /// In tr, this message translates to:
  /// **'Kategorisiz'**
  String get bankImportFilterUncategorized;

  /// No description provided for @bankImportFilterDuplicates.
  ///
  /// In tr, this message translates to:
  /// **'Olası tekrar'**
  String get bankImportFilterDuplicates;

  /// No description provided for @bankImportSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Açıklamada ara'**
  String get bankImportSearchHint;

  /// No description provided for @bankImportNoMatch.
  ///
  /// In tr, this message translates to:
  /// **'Filtreye uyan hareket yok.'**
  String get bankImportNoMatch;

  /// No description provided for @bankImportShownOf.
  ///
  /// In tr, this message translates to:
  /// **'{shown} / {total} gösteriliyor'**
  String bankImportShownOf(int shown, int total);

  /// No description provided for @bankImportWarnings.
  ///
  /// In tr, this message translates to:
  /// **'Uyarılar ({count})'**
  String bankImportWarnings(int count);

  /// No description provided for @bankImportStatRows.
  ///
  /// In tr, this message translates to:
  /// **'hareket'**
  String get bankImportStatRows;

  /// No description provided for @bankImportStatDuplicates.
  ///
  /// In tr, this message translates to:
  /// **'olası tekrar'**
  String get bankImportStatDuplicates;

  /// No description provided for @bankImportStatSkipped.
  ///
  /// In tr, this message translates to:
  /// **'atlanan satır'**
  String get bankImportStatSkipped;

  /// No description provided for @bankImportStatUncategorized.
  ///
  /// In tr, this message translates to:
  /// **'kategorisiz'**
  String get bankImportStatUncategorized;

  /// No description provided for @bankImportSelectedOf.
  ///
  /// In tr, this message translates to:
  /// **'{selected} / {total} seçili'**
  String bankImportSelectedOf(int selected, int total);

  /// No description provided for @bankImportNoRows.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktarılacak hareket bulunamadı.'**
  String get bankImportNoRows;

  /// No description provided for @bankImportSelectAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get bankImportSelectAll;

  /// No description provided for @bankImportDeselectAll.
  ///
  /// In tr, this message translates to:
  /// **'Hiçbiri'**
  String get bankImportDeselectAll;

  /// No description provided for @bankImportStepperMode.
  ///
  /// In tr, this message translates to:
  /// **'Tek tek'**
  String get bankImportStepperMode;

  /// No description provided for @bankImportDuplicate.
  ///
  /// In tr, this message translates to:
  /// **'Olası tekrar'**
  String get bankImportDuplicate;

  /// No description provided for @bankImportStepSkip.
  ///
  /// In tr, this message translates to:
  /// **'Atla'**
  String get bankImportStepSkip;

  /// No description provided for @bankImportStepAdd.
  ///
  /// In tr, this message translates to:
  /// **'Ekle'**
  String get bankImportStepAdd;

  /// No description provided for @bankImportStepAddRest.
  ///
  /// In tr, this message translates to:
  /// **'Kalanları ekle'**
  String get bankImportStepAddRest;

  /// No description provided for @bankImportStepCancelAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü iptal'**
  String get bankImportStepCancelAll;

  /// No description provided for @bankImportDefaultExpenseCat.
  ///
  /// In tr, this message translates to:
  /// **'Gider:'**
  String get bankImportDefaultExpenseCat;

  /// No description provided for @bankImportDefaultIncomeCat.
  ///
  /// In tr, this message translates to:
  /// **'Gelir:'**
  String get bankImportDefaultIncomeCat;

  /// No description provided for @bankImportShowRaw.
  ///
  /// In tr, this message translates to:
  /// **'Ham metni göster'**
  String get bankImportShowRaw;

  /// No description provided for @bankImportPdfRawTitle.
  ///
  /// In tr, this message translates to:
  /// **'PDF metni tanınamadı'**
  String get bankImportPdfRawTitle;

  /// No description provided for @bankImportPdfRawHint.
  ///
  /// In tr, this message translates to:
  /// **'Metni çıkardık ama hareket satırlarını tanıyamadık. Aşağıdaki metni kopyalayıp paylaş; ayrıştırıcı bankanın düzenine göre ayarlanacak.'**
  String get bankImportPdfRawHint;

  /// No description provided for @bankImportScannedPdfTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu PDF taranmış bir görüntü'**
  String get bankImportScannedPdfTitle;

  /// No description provided for @bankImportScannedPdfHint.
  ///
  /// In tr, this message translates to:
  /// **'Dosyanın içinde metin yok, yalnızca fotoğraf/tarama var. Görüntüden okumayı denedik ama hareket satırı çıkaramadık. Bankanın internet şubesinden ekstreyi Excel (.xls/.xlsx) ya da CSV olarak indirirsen çok daha isabetli sonuç alırsın.'**
  String get bankImportScannedPdfHint;

  /// No description provided for @bankImportOcrWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu hareketler bir GÖRÜNTÜDEN okundu. Görüntü tanımada rakamlar sık karışır (virgül/nokta, 1/7, 0/O) ve doğrulayacak bakiye sütunu genelde yoktur — eklemeden önce her tutarı tek tek kontrol et.'**
  String get bankImportOcrWarning;

  /// No description provided for @bankImportPickAnother.
  ///
  /// In tr, this message translates to:
  /// **'Başka dosya seç'**
  String get bankImportPickAnother;

  /// No description provided for @bankImportLegacyExcelTitle.
  ///
  /// In tr, this message translates to:
  /// **'Excel dosyası açılamadı'**
  String get bankImportLegacyExcelTitle;

  /// No description provided for @bankImportLegacyExcelHint.
  ///
  /// In tr, this message translates to:
  /// **'{reason}\n\nBankandan ekstreyi .xlsx ya da CSV olarak indir; ya da dosyayı Excel/Google E-Tablolar\'da açıp .xlsx olarak kaydet.'**
  String bankImportLegacyExcelHint(String reason);

  /// No description provided for @bankImportSourceTruncated.
  ///
  /// In tr, this message translates to:
  /// **'Excel dosyası beklenen kapanışla bitmiyor; eksik indirilmiş olabilir. Bazı hareketler hiç okunmamış olabilir — satır sayısını bankadaki ekstreyle karşılaştır.'**
  String get bankImportSourceTruncated;

  /// No description provided for @bankImportSourceUnresolved.
  ///
  /// In tr, this message translates to:
  /// **'{count} hücrenin değeri okunamadı; o satırlarda boş görünen alanlar aslında dolu olabilir.'**
  String bankImportSourceUnresolved(int count);

  /// No description provided for @bankImportUnsupportedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Desteklenmeyen dosya'**
  String get bankImportUnsupportedTitle;

  /// No description provided for @bankImportUnsupportedHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu dosyanın biçimi tanınamadı. Desteklenen biçimler: {formats}'**
  String bankImportUnsupportedHint(String formats);

  /// No description provided for @bankImportCopy.
  ///
  /// In tr, this message translates to:
  /// **'Kopyala'**
  String get bankImportCopy;

  /// No description provided for @bankImportCopied.
  ///
  /// In tr, this message translates to:
  /// **'Kopyalandı'**
  String get bankImportCopied;

  /// No description provided for @bankImportSummary.
  ///
  /// In tr, this message translates to:
  /// **'{count} hareket · {dup} olası tekrar · {skipped} satır atlandı · {uncategorized} kategorisiz'**
  String bankImportSummary(int count, int dup, int skipped, int uncategorized);

  /// No description provided for @bankImportAdd.
  ///
  /// In tr, this message translates to:
  /// **'Seçilenleri ekle ({count})'**
  String bankImportAdd(int count);

  /// No description provided for @bankImportDoneMsg.
  ///
  /// In tr, this message translates to:
  /// **'{added} işlem eklendi, {skipped} atlandı.'**
  String bankImportDoneMsg(int added, int skipped);

  /// No description provided for @bankImportDonePastDatesHint.
  ///
  /// In tr, this message translates to:
  /// **'Bazı hareketler geçmiş aylara ait. İşlemler listesi varsayılan olarak içinde bulunduğun ayı gösterir; hepsini görmek için tarih filtresini genişlet.'**
  String get bankImportDonePastDatesHint;

  /// No description provided for @bankImportReconcileMatched.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye ile doğrulandı: işlemlerin gider/gelir yönü bankanın bakiye sütunuyla eşleşiyor.'**
  String get bankImportReconcileMatched;

  /// No description provided for @bankImportVerified.
  ///
  /// In tr, this message translates to:
  /// **'Aritmetik olarak doğrulandı'**
  String get bankImportVerified;

  /// No description provided for @bankImportVerifiedHint.
  ///
  /// In tr, this message translates to:
  /// **'Okunan tutarlar ekstrenin kendi bakiye/toplam bilgileriyle birebir tutuyor.'**
  String get bankImportVerifiedHint;

  /// No description provided for @bankImportVerifyFailed.
  ///
  /// In tr, this message translates to:
  /// **'Doğrulanamadı'**
  String get bankImportVerifyFailed;

  /// No description provided for @bankImportVerifyFailedHint.
  ///
  /// In tr, this message translates to:
  /// **'Ekstrenin kendi bilgileriyle tutmayan kontroller var; aktarmadan önce tutarları gözden geçir.'**
  String get bankImportVerifyFailedHint;

  /// No description provided for @bankImportCheckBalanceChain.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye zinciri'**
  String get bankImportCheckBalanceChain;

  /// No description provided for @bankImportCheckRecordCount.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt sayısı'**
  String get bankImportCheckRecordCount;

  /// No description provided for @bankImportCheckOpeningBalance.
  ///
  /// In tr, this message translates to:
  /// **'Devreden bakiye'**
  String get bankImportCheckOpeningBalance;

  /// No description provided for @bankImportCheckClosingBalance.
  ///
  /// In tr, this message translates to:
  /// **'Kapanış bakiyesi'**
  String get bankImportCheckClosingBalance;

  /// No description provided for @bankImportCheckTotals.
  ///
  /// In tr, this message translates to:
  /// **'Borç/Alacak toplamı'**
  String get bankImportCheckTotals;

  /// No description provided for @bankImportReconcileMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye uyuşmadı: {count} satırda bakiye ile tutar tutmuyor. Ekstre eksik/hatalı okunmuş olabilir; işaretleri kontrol et.'**
  String bankImportReconcileMismatch(int count);

  /// No description provided for @bankImportCurrencyMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Ekstre {statement} para biriminde görünüyor ama hedef cüzdan {wallet}. Tutarlar dönüştürülmez; doğru cüzdana aktardığından emin ol.'**
  String bankImportCurrencyMismatch(String statement, String wallet);

  /// No description provided for @bankImportUndo.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktarımı geri al'**
  String get bankImportUndo;

  /// No description provided for @bankImportUndoDone.
  ///
  /// In tr, this message translates to:
  /// **'İçe aktarım geri alındı.'**
  String get bankImportUndoDone;

  /// No description provided for @bankImportBatchTypeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tümünü çevir:'**
  String get bankImportBatchTypeLabel;

  /// No description provided for @bankImportSetAllExpense.
  ///
  /// In tr, this message translates to:
  /// **'Gider'**
  String get bankImportSetAllExpense;

  /// No description provided for @bankImportSetAllIncome.
  ///
  /// In tr, this message translates to:
  /// **'Gelir'**
  String get bankImportSetAllIncome;

  /// No description provided for @bankImportReviewWarning.
  ///
  /// In tr, this message translates to:
  /// **'Tarih, tutar ve kategoriler dosyadan otomatik algılandı; hatalı olabilir. Eklemeden önce her hareketi kontrol et.'**
  String get bankImportReviewWarning;

  /// No description provided for @bankImportDoneBalanceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güncel cüzdan bakiyesi'**
  String get bankImportDoneBalanceLabel;

  /// No description provided for @bankImportDoneBalanceHint.
  ///
  /// In tr, this message translates to:
  /// **'Bu bakiye, içe aktarılan hareketler dahil hesaplandı. Banka hesabındaki güncel bakiyeyle karşılaştır; farklıysa aşağıdan eşitleyebilirsin.'**
  String get bankImportDoneBalanceHint;

  /// No description provided for @bankImportSyncButton.
  ///
  /// In tr, this message translates to:
  /// **'Bakiyeyi eşitle'**
  String get bankImportSyncButton;

  /// No description provided for @bankImportSyncDialogTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bakiyeyi Eşitle'**
  String get bankImportSyncDialogTitle;

  /// No description provided for @bankImportSyncDialogHint.
  ///
  /// In tr, this message translates to:
  /// **'Bankandaki gerçek güncel bakiyeni gir; cüzdanın buna göre ayarlanır. Geçmiş hareketlerin değişmez, yalnızca başlangıç bakiyesi düzeltilir.'**
  String get bankImportSyncDialogHint;

  /// No description provided for @bankImportSyncDialogLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek bakiye'**
  String get bankImportSyncDialogLabel;

  /// No description provided for @bankImportSyncSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan bakiyesi eşitlendi.'**
  String get bankImportSyncSuccess;

  /// No description provided for @bankImportCategorySuggestionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kategori önerileri'**
  String get bankImportCategorySuggestionTitle;

  /// No description provided for @bankImportCategorySuggestionHint.
  ///
  /// In tr, this message translates to:
  /// **'Bazı hareketler mevcut kategorilerinden hiçbirine uymuyor. İşaretlediklerin oluşturulup otomatik atanır; işaretini kaldırdıkların oluşturulmaz ve o hareketler varsayılan kategoride kalır.'**
  String get bankImportCategorySuggestionHint;

  /// No description provided for @bankImportCategorySuggestionContinue.
  ///
  /// In tr, this message translates to:
  /// **'Devam et'**
  String get bankImportCategorySuggestionContinue;

  /// No description provided for @bankImportPickCategoryHint.
  ///
  /// In tr, this message translates to:
  /// **'Kategori seç'**
  String get bankImportPickCategoryHint;

  /// No description provided for @bankStatementSectionHeader.
  ///
  /// In tr, this message translates to:
  /// **'BANKA EKSTRESİ'**
  String get bankStatementSectionHeader;

  /// No description provided for @sifirla.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırla'**
  String get sifirla;

  /// No description provided for @tumTurlariSifirlaOnayMesaji.
  ///
  /// In tr, this message translates to:
  /// **'Tüm tanıtım turları sıfırlanacak ve tekrar gösterilecek. Devam edilsin mi?'**
  String get tumTurlariSifirlaOnayMesaji;

  /// No description provided for @deleteAllDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tüm veriyi sil'**
  String get deleteAllDataTitle;

  /// No description provided for @deleteAllDataMessage.
  ///
  /// In tr, this message translates to:
  /// **'Tüm cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler ve tekrarlayan şablonlar cihazdan kalıcı olarak silinecek. Bu işlem geri alınamaz. Drive yedeğiniz (varsa) etkilenmez.'**
  String get deleteAllDataMessage;

  /// No description provided for @irreversibleActionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu İşlem Geri Alınamaz'**
  String get irreversibleActionTitle;

  /// No description provided for @deleteAllDataDangerMessage.
  ///
  /// In tr, this message translates to:
  /// **'Onayladığınızda tüm yerel veriler kalıcı olarak silinir ve kurtarılamaz.'**
  String get deleteAllDataDangerMessage;

  /// No description provided for @dataDeletedSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Tüm yerel veri silindi.'**
  String get dataDeletedSuccess;

  /// No description provided for @dataDeleteError.
  ///
  /// In tr, this message translates to:
  /// **'Veri silinemedi. Lütfen tekrar deneyin.'**
  String get dataDeleteError;

  /// No description provided for @deleteWalletTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan Sil'**
  String get deleteWalletTitle;

  /// No description provided for @deleteWalletConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'{ad} cüzdanını silmek istediğinizden emin misiniz?'**
  String deleteWalletConfirmMessage(String ad);

  /// No description provided for @deleteWalletDangerMessage.
  ///
  /// In tr, this message translates to:
  /// **'{ad} cüzdanı ve tüm işlem geçmişi kalıcı olarak silinecek. Bu işlem geri alınamaz.'**
  String deleteWalletDangerMessage(String ad);

  /// No description provided for @transferOnayBasligi.
  ///
  /// In tr, this message translates to:
  /// **'Transferi Onayla'**
  String get transferOnayBasligi;

  /// No description provided for @transferOnayMesaji.
  ///
  /// In tr, this message translates to:
  /// **'{tutar} tutarını {kaynak} cüzdanından {hedef} cüzdanına transfer etmek istediğinizden emin misiniz?'**
  String transferOnayMesaji(String tutar, String kaynak, String hedef);

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bütçeyi Sil'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmMessage.
  ///
  /// In tr, this message translates to:
  /// **'{kategori} bütçesini silmek istediğinizden emin misiniz?'**
  String budgetDeleteConfirmMessage(String kategori);

  /// No description provided for @borcSilBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Borcu Sil'**
  String get borcSilBaslik;

  /// No description provided for @borcSilOnayMesaji.
  ///
  /// In tr, this message translates to:
  /// **'{baslik} borcunu silmek istediğinizden emin misiniz? Bu borcun cüzdan bakiyesine etkisi de geri alınır.'**
  String borcSilOnayMesaji(String baslik);

  /// No description provided for @alacakSilBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Alacağı Sil'**
  String get alacakSilBaslik;

  /// No description provided for @alacakSilOnayMesaji.
  ///
  /// In tr, this message translates to:
  /// **'{isim} alacağını silmek istediğinizden emin misiniz? Bu alacağın cüzdan bakiyesine etkisi de geri alınır.'**
  String alacakSilOnayMesaji(String isim);

  /// No description provided for @budgetStatusUnderControl.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol altında'**
  String get budgetStatusUnderControl;

  /// No description provided for @budgetStatusFilledCount.
  ///
  /// In tr, this message translates to:
  /// **'{sayi} bütçe doldu'**
  String budgetStatusFilledCount(int sayi);

  /// No description provided for @budgetStatusExceededCount.
  ///
  /// In tr, this message translates to:
  /// **'{sayi} bütçe aşıldı'**
  String budgetStatusExceededCount(int sayi);

  /// No description provided for @insightDailyLimitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük Harcama Limiti (Hedef)'**
  String get insightDailyLimitTitle;

  /// No description provided for @insightDailyLimitDesc.
  ///
  /// In tr, this message translates to:
  /// **'Kalan {gun} gün boyunca bütçenizi korumak için tavsiye edilen günlük limit.'**
  String insightDailyLimitDesc(int gun);

  /// No description provided for @insightSpikeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Harcama Sıçraması Uyarısı'**
  String get insightSpikeTitle;

  /// No description provided for @insightSpikeDesc.
  ///
  /// In tr, this message translates to:
  /// **'Geçen döneme göre ({tutar}) dikkate değer bir artış var.'**
  String insightSpikeDesc(String tutar);

  /// No description provided for @drawerSectionFinancial.
  ///
  /// In tr, this message translates to:
  /// **'FİNANSAL YÖNETİM'**
  String get drawerSectionFinancial;

  /// No description provided for @drawerSectionSystem.
  ///
  /// In tr, this message translates to:
  /// **'SİSTEM & UYGULAMA'**
  String get drawerSectionSystem;

  /// No description provided for @drawerBudgetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kategori bazlı bütçe takibi ve harcama limitleri'**
  String get drawerBudgetSubtitle;

  /// No description provided for @drawerRecurringSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik gelir ve gider şablonları'**
  String get drawerRecurringSubtitle;

  /// No description provided for @drawerBankImportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'PDF/Excel hesap ekstresi içe aktarma'**
  String get drawerBankImportSubtitle;

  /// No description provided for @drawerSettingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema, para birimi ve genel tercihler'**
  String get drawerSettingsSubtitle;

  /// No description provided for @drawerSecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik & Biyometrik'**
  String get drawerSecurityTitle;

  /// No description provided for @drawerSecuritySubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama kilidi ve PIN ayarları'**
  String get drawerSecuritySubtitle;

  /// No description provided for @drawerActiveWalletLabel.
  ///
  /// In tr, this message translates to:
  /// **'AKTİF CÜZDAN'**
  String get drawerActiveWalletLabel;

  /// No description provided for @reportBalanceTrend.
  ///
  /// In tr, this message translates to:
  /// **'Bakiye Trendi'**
  String get reportBalanceTrend;

  /// No description provided for @reportExpensesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giderler'**
  String get reportExpensesTitle;

  /// No description provided for @reportIncomesTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gelirler'**
  String get reportIncomesTitle;

  /// No description provided for @reportNoDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Rapor Oluşturmak İçin Veri Yok'**
  String get reportNoDataTitle;

  /// No description provided for @reportNetLabel.
  ///
  /// In tr, this message translates to:
  /// **'Net'**
  String get reportNetLabel;

  /// No description provided for @reportCompareTopSlice.
  ///
  /// In tr, this message translates to:
  /// **'En büyük: {ad} · {tutar}'**
  String reportCompareTopSlice(String ad, String tutar);

  /// No description provided for @reportCompareOverspend.
  ///
  /// In tr, this message translates to:
  /// **'Gelirin %{oran} üzerinde'**
  String reportCompareOverspend(String oran);

  /// No description provided for @reportCompareScaleHint.
  ///
  /// In tr, this message translates to:
  /// **'İki çubuk aynı ölçekte'**
  String get reportCompareScaleHint;

  /// No description provided for @debtHistoryEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Kapanan Borç Yok'**
  String get debtHistoryEmptyTitle;

  /// No description provided for @receivableHistoryEmptyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz Tahsil Edilen Alacak Yok'**
  String get receivableHistoryEmptyTitle;

  /// No description provided for @badgeOdendi.
  ///
  /// In tr, this message translates to:
  /// **'Ödendi'**
  String get badgeOdendi;

  /// No description provided for @badgeTahsilEdildi.
  ///
  /// In tr, this message translates to:
  /// **'Tahsil Edildi'**
  String get badgeTahsilEdildi;

  /// No description provided for @reportSavingsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'%{oran} Birikim'**
  String reportSavingsSubtitle(String oran);

  /// No description provided for @vadeTarihLabel.
  ///
  /// In tr, this message translates to:
  /// **'Vade: {tarih}'**
  String vadeTarihLabel(String tarih);

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyIntro.
  ///
  /// In tr, this message translates to:
  /// **'CuNehat, finansal kayıtlarınızı takip etmenize yardımcı olan bir kişisel finans uygulamasıdır. \"Önce-çevrimdışı\" tasarlandı: bulut yedeklemeyi açıkça etkinleştirmediğiniz sürece verileriniz cihazınızda kalır. Sunucumuz yoktur.'**
  String get privacyIntro;

  /// No description provided for @privacyLocalDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cihazınızda saklanan veriler'**
  String get privacyLocalDataTitle;

  /// No description provided for @privacyLocalDataBody.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler, tekrarlayan şablonlar ve uygulama tercihleri (tema, dil, kategoriler) yalnızca cihazınızda saklanır ve bize iletilmez.'**
  String get privacyLocalDataBody;

  /// No description provided for @privacyDriveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive yedeği (isteğe bağlı)'**
  String get privacyDriveTitle;

  /// No description provided for @privacyDriveBody.
  ///
  /// In tr, this message translates to:
  /// **'Bulut yedekleme varsayılan olarak KAPALIDIR. Açarsanız Google ile oturum açılır; yalnızca e-posta adresiniz (hangi hesabın bağlı olduğunu görmeniz için) ve kısıtlı \"drive.appdata\" kapsamı kullanılır. Tek bir yedek dosyası (cunehat_backup.json) kendi Drive\'ınızdaki, başka uygulamaların erişemediği özel bir klasöre yazılır. Tam Drive erişimi istenmez; diğer dosyalarınız okunamaz.'**
  String get privacyDriveBody;

  /// No description provided for @privacyMarketDataTitle.
  ///
  /// In tr, this message translates to:
  /// **'Piyasa verisi'**
  String get privacyMarketDataTitle;

  /// No description provided for @privacyMarketDataBody.
  ///
  /// In tr, this message translates to:
  /// **'Canlı fiyat göstermek için yalnızca varlık sembolü (örn. hisse kodu) herkese açık uç noktalara (Yahoo Finance, Truncgil) gönderilir. Hiçbir kişisel veya finansal kayıt paylaşılmaz.'**
  String get privacyMarketDataBody;

  /// No description provided for @privacySharingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Veri paylaşımı'**
  String get privacySharingTitle;

  /// No description provided for @privacySharingBody.
  ///
  /// In tr, this message translates to:
  /// **'Verilerinizi satmaz, kiralamaz veya üçüncü taraflarla paylaşmayız. Uygulamada analitik, çökme-raporlama, reklam veya izleme SDK\'sı yoktur. Google API\'lerinden alınan bilgilerin kullanımı Google API Hizmetleri Kullanıcı Verileri Politikası\'na (Sınırlı Kullanım dahil) uyar.'**
  String get privacySharingBody;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In tr, this message translates to:
  /// **'Güvenlik'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In tr, this message translates to:
  /// **'Yerel veri uygulamanın özel depolama alanında tutulur. Yetkisiz erişimi önlemek için biyometrik / PIN kilidi desteklenir ve uygulama arka plana alındığında içerik bulanıklaştırılır. Tüm ağ iletişimi HTTPS kullanır.'**
  String get privacySecurityBody;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Veri saklama ve silme'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionBody.
  ///
  /// In tr, this message translates to:
  /// **'Verileriniz üzerinde tam kontrol sizdedir. Tüm yerel veriyi Ayarlar → Gizlilik & Veri → \"Tüm veriyi sil\" ile silebilirsiniz. Drive yedeğini Ayarlar → Yedekleme bölümünden silebilir veya hesabınızın bağlantısını kesebilirsiniz.'**
  String get privacyRetentionBody;

  /// No description provided for @privacyContactLabel.
  ///
  /// In tr, this message translates to:
  /// **'İletişim: {email}'**
  String privacyContactLabel(String email);

  /// No description provided for @privacyLastUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Son güncelleme: 30 Haziran 2026'**
  String get privacyLastUpdated;

  /// No description provided for @privacyConsentTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gizliliğiniz'**
  String get privacyConsentTitle;

  /// No description provided for @privacyConsentBody.
  ///
  /// In tr, this message translates to:
  /// **'CuNehat verilerinizi yalnızca cihazınızda saklar; sunucumuz yoktur. İsteğe bağlı Google Drive yedeği yalnızca siz açarsanız, kendi Drive\'ınızdaki özel bir klasöre yazılır. Verileriniz üçüncü taraflarla paylaşılmaz; reklam veya izleme yoktur.'**
  String get privacyConsentBody;

  /// No description provided for @privacyConsentAcknowledge.
  ///
  /// In tr, this message translates to:
  /// **'Anladım'**
  String get privacyConsentAcknowledge;

  /// No description provided for @secenekler.
  ///
  /// In tr, this message translates to:
  /// **'Seçenekler'**
  String get secenekler;

  /// No description provided for @tarihAraligiSecBaslik.
  ///
  /// In tr, this message translates to:
  /// **'Tarih Aralığı Seç'**
  String get tarihAraligiSecBaslik;

  /// No description provided for @takvimdenSec.
  ///
  /// In tr, this message translates to:
  /// **'Takvimden seç'**
  String get takvimdenSec;

  /// No description provided for @kategoriSecmeUyarisi.
  ///
  /// In tr, this message translates to:
  /// **'Bir kategori seçin'**
  String get kategoriSecmeUyarisi;

  /// No description provided for @yatirimSatOnayBaslik.
  ///
  /// In tr, this message translates to:
  /// **'{name} satılsın mı?'**
  String yatirimSatOnayBaslik(String name);

  /// No description provided for @yatirimSilOnayBaslik.
  ///
  /// In tr, this message translates to:
  /// **'{name} kaydı silinsin mi?'**
  String yatirimSilOnayBaslik(String name);

  /// No description provided for @walletQuickStartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdan hazır!'**
  String get walletQuickStartTitle;

  /// No description provided for @walletQuickStartSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'{name} oluşturuldu. Nasıl başlamak istersin?'**
  String walletQuickStartSubtitle(String name);

  /// No description provided for @walletQuickStartImportTitle.
  ///
  /// In tr, this message translates to:
  /// **'Banka ekstresi içe aktar'**
  String get walletQuickStartImportTitle;

  /// No description provided for @walletQuickStartImportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş işlemlerini dosyadan yükle — en hızlı yol'**
  String get walletQuickStartImportSubtitle;

  /// No description provided for @walletQuickStartManualTitle.
  ///
  /// In tr, this message translates to:
  /// **'İlk işlemi elle ekle'**
  String get walletQuickStartManualTitle;

  /// No description provided for @walletQuickStartManualSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Tek bir gelir ya da giderle başla'**
  String get walletQuickStartManualSubtitle;

  /// No description provided for @walletQuickStartSkip.
  ///
  /// In tr, this message translates to:
  /// **'Şimdilik atla'**
  String get walletQuickStartSkip;

  /// No description provided for @driveErrNotSignedIn.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'a bağlı değilsiniz.'**
  String get driveErrNotSignedIn;

  /// No description provided for @driveErrCancelled.
  ///
  /// In tr, this message translates to:
  /// **'İşlem iptal edildi.'**
  String get driveErrCancelled;

  /// No description provided for @driveErrNoNetwork.
  ///
  /// In tr, this message translates to:
  /// **'İnternet bağlantısı yok. Bağlanıp tekrar deneyin.'**
  String get driveErrNoNetwork;

  /// No description provided for @driveErrTimeout.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive zamanında yanıt vermedi. Bağlantınızı kontrol edip tekrar deneyin.'**
  String get driveErrTimeout;

  /// No description provided for @driveErrAuthExpired.
  ///
  /// In tr, this message translates to:
  /// **'Google oturumunuzun süresi doldu. Bağlantıyı kesip yeniden bağlanın.'**
  String get driveErrAuthExpired;

  /// No description provided for @driveErrScopeDenied.
  ///
  /// In tr, this message translates to:
  /// **'Drive uygulama klasörü izni verilmedi. Yedekleme bu izin olmadan çalışamaz.'**
  String get driveErrScopeDenied;

  /// No description provided for @driveErrConfigError.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive bu uygulama sürümünde yapılandırılmamış (OAuth istemcisi paket adı/imza ile eşleşmiyor). Bu bir kurulum hatası; yedekleme şimdilik kullanılamıyor.'**
  String get driveErrConfigError;

  /// No description provided for @driveErrQuotaExceeded.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive depolama alanınız dolu. Yer açıp tekrar deneyin.'**
  String get driveErrQuotaExceeded;

  /// No description provided for @driveErrServerError.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive şu anda yanıt veremiyor. Daha sonra tekrar deneyin.'**
  String get driveErrServerError;

  /// No description provided for @driveErrEmptyLocalData.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda yedeklenecek kayıt yok. Boş bir yedek, Drive\'daki dolu yedeğinizin yerini alırdı.'**
  String get driveErrEmptyLocalData;

  /// No description provided for @driveErrVerificationFailed.
  ///
  /// In tr, this message translates to:
  /// **'Yükleme doğrulanamadı; yedek eksik yazılmış olabilir. Yeni kopya geri alındı, önceki yedeğiniz duruyor.'**
  String get driveErrVerificationFailed;

  /// No description provided for @driveErrNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'da yedek bulunamadı.'**
  String get driveErrNotFound;

  /// No description provided for @driveErrVersionMismatch.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedek farklı bir uygulama sürümüne ait (yedek şeması {found}, bu sürüm {expected}). Geri yüklenemez.'**
  String driveErrVersionMismatch(String found, int expected);

  /// No description provided for @driveErrCorrupt.
  ///
  /// In tr, this message translates to:
  /// **'Yedek dosyası okunamadı; bozuk ya da eksik yazılmış.'**
  String get driveErrCorrupt;

  /// No description provided for @driveErrWriteFailure.
  ///
  /// In tr, this message translates to:
  /// **'Geri yükleme sırasında yazma hatası oldu. Cihazdaki eski verileriniz geri alındı.'**
  String get driveErrWriteFailure;

  /// No description provided for @driveUnchanged.
  ///
  /// In tr, this message translates to:
  /// **'Veriler son yedekten beri değişmedi; yeni yedek alınmadı.'**
  String get driveUnchanged;

  /// No description provided for @backupEmptyConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Boş yedek alınsın mı?'**
  String get backupEmptyConfirmTitle;

  /// No description provided for @backupEmptyConfirmDesc.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda hiç kayıt yok. Devam ederseniz Drive\'daki en yeni yedeğin yerine boş bir yedek yazılır.'**
  String get backupEmptyConfirmDesc;

  /// No description provided for @backupEmptyConfirmAction.
  ///
  /// In tr, this message translates to:
  /// **'Boş yedek al'**
  String get backupEmptyConfirmAction;

  /// No description provided for @viewBackups.
  ///
  /// In tr, this message translates to:
  /// **'Yedekleri Görüntüle'**
  String get viewBackups;

  /// No description provided for @deleteAllBackups.
  ///
  /// In tr, this message translates to:
  /// **'Tüm Yedekleri Sil'**
  String get deleteAllBackups;

  /// No description provided for @deleteAllBackupsDesc.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'daki tüm yedek kopyaları kalıcı olarak silinecek. Cihazınızdaki veriler etkilenmez.'**
  String get deleteAllBackupsDesc;

  /// No description provided for @backupGenerationsKept.
  ///
  /// In tr, this message translates to:
  /// **'{count} kopya saklanıyor'**
  String backupGenerationsKept(int count);

  /// No description provided for @backupSizeLabel.
  ///
  /// In tr, this message translates to:
  /// **'Boyut'**
  String get backupSizeLabel;

  /// No description provided for @autoBackup.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik yedekleme'**
  String get autoBackup;

  /// No description provided for @autoBackupDesc.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama arka plana alındığında, veri değiştiyse ve aralık dolduysa sessizce yedek alınır.'**
  String get autoBackupDesc;

  /// No description provided for @autoBackupOff.
  ///
  /// In tr, this message translates to:
  /// **'Kapalı'**
  String get autoBackupOff;

  /// No description provided for @autoBackupDaily.
  ///
  /// In tr, this message translates to:
  /// **'Günlük'**
  String get autoBackupDaily;

  /// No description provided for @autoBackupWeekly.
  ///
  /// In tr, this message translates to:
  /// **'Haftalık'**
  String get autoBackupWeekly;

  /// No description provided for @autoBackupLimitNote.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamayı hiç açmazsanız otomatik yedek çalışmaz.'**
  String get autoBackupLimitNote;

  /// No description provided for @autoBackupFailureWarning.
  ///
  /// In tr, this message translates to:
  /// **'Son {count} otomatik yedekleme denemesi başarısız oldu. Elle yedekleyerek sebebini görebilirsiniz.'**
  String autoBackupFailureWarning(int count);

  /// No description provided for @autoBackupNeedsConnection.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik yedekleme için Google Drive bağlantısı gerekir.'**
  String get autoBackupNeedsConnection;

  /// No description provided for @backupPreviewTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedekler'**
  String get backupPreviewTitle;

  /// No description provided for @backupPreviewDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yedek önizleme'**
  String get backupPreviewDetailTitle;

  /// No description provided for @backupPreviewDriveSection.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'daki kopyalar'**
  String get backupPreviewDriveSection;

  /// No description provided for @backupPreviewLocalButton.
  ///
  /// In tr, this message translates to:
  /// **'Cihazdaki dosyadan önizle'**
  String get backupPreviewLocalButton;

  /// No description provided for @backupPreviewEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive\'da henüz yedek yok.'**
  String get backupPreviewEmpty;

  /// No description provided for @backupPreviewLocalSource.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz dosyası'**
  String get backupPreviewLocalSource;

  /// No description provided for @backupPreviewOriginManual.
  ///
  /// In tr, this message translates to:
  /// **'Elle'**
  String get backupPreviewOriginManual;

  /// No description provided for @backupPreviewOriginAuto.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik'**
  String get backupPreviewOriginAuto;

  /// No description provided for @backupPreviewLoading.
  ///
  /// In tr, this message translates to:
  /// **'Yedek okunuyor…'**
  String get backupPreviewLoading;

  /// No description provided for @backupPreviewContents.
  ///
  /// In tr, this message translates to:
  /// **'İçerik'**
  String get backupPreviewContents;

  /// No description provided for @backupPreviewWallets.
  ///
  /// In tr, this message translates to:
  /// **'Cüzdanlar'**
  String get backupPreviewWallets;

  /// No description provided for @backupPreviewTransactions.
  ///
  /// In tr, this message translates to:
  /// **'İşlemler'**
  String get backupPreviewTransactions;

  /// No description provided for @backupPreviewInvestments.
  ///
  /// In tr, this message translates to:
  /// **'Birikimler'**
  String get backupPreviewInvestments;

  /// No description provided for @backupPreviewDebts.
  ///
  /// In tr, this message translates to:
  /// **'Borçlar'**
  String get backupPreviewDebts;

  /// No description provided for @backupPreviewReceivables.
  ///
  /// In tr, this message translates to:
  /// **'Alacaklar'**
  String get backupPreviewReceivables;

  /// No description provided for @backupPreviewBudgets.
  ///
  /// In tr, this message translates to:
  /// **'Bütçeler'**
  String get backupPreviewBudgets;

  /// No description provided for @backupPreviewRecurring.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli işlemler'**
  String get backupPreviewRecurring;

  /// No description provided for @backupPreviewCategories.
  ///
  /// In tr, this message translates to:
  /// **'Kategori tercihleri'**
  String get backupPreviewCategories;

  /// No description provided for @backupPreviewDateRange.
  ///
  /// In tr, this message translates to:
  /// **'İşlem tarih aralığı'**
  String get backupPreviewDateRange;

  /// No description provided for @backupPreviewIncome.
  ///
  /// In tr, this message translates to:
  /// **'Toplam gelir'**
  String get backupPreviewIncome;

  /// No description provided for @backupPreviewExpense.
  ///
  /// In tr, this message translates to:
  /// **'Toplam gider'**
  String get backupPreviewExpense;

  /// No description provided for @backupPreviewTakenAt.
  ///
  /// In tr, this message translates to:
  /// **'Yedek tarihi'**
  String get backupPreviewTakenAt;

  /// No description provided for @backupPreviewSchemaVersion.
  ///
  /// In tr, this message translates to:
  /// **'Şema sürümü'**
  String get backupPreviewSchemaVersion;

  /// No description provided for @backupPreviewDiffTitle.
  ///
  /// In tr, this message translates to:
  /// **'Geri yüklerseniz ne değişir'**
  String get backupPreviewDiffTitle;

  /// No description provided for @backupPreviewDiffOnDevice.
  ///
  /// In tr, this message translates to:
  /// **'Cihazda'**
  String get backupPreviewDiffOnDevice;

  /// No description provided for @backupPreviewDiffInBackup.
  ///
  /// In tr, this message translates to:
  /// **'Yedekte'**
  String get backupPreviewDiffInBackup;

  /// No description provided for @backupPreviewReceiptWarning.
  ///
  /// In tr, this message translates to:
  /// **'{count} işlemin fiş görseli var. Görseller yedeğe dahil edilmez; başka bir cihaza geri yüklerseniz bu görseller görünmez.'**
  String backupPreviewReceiptWarning(int count);

  /// No description provided for @backupPreviewEmptyWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedek boş. Geri yüklerseniz cihazınızdaki tüm kayıtlar silinir.'**
  String get backupPreviewEmptyWarning;

  /// No description provided for @backupPreviewRestoreButton.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedeği geri yükle'**
  String get backupPreviewRestoreButton;

  /// No description provided for @backupPreviewDeleteButton.
  ///
  /// In tr, this message translates to:
  /// **'Bu kopyayı sil'**
  String get backupPreviewDeleteButton;

  /// No description provided for @backupPreviewDeleteConfirmDesc.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedek kopyası Google Drive\'dan kalıcı olarak silinecek. Cihazınızdaki veriler etkilenmez.'**
  String get backupPreviewDeleteConfirmDesc;

  /// No description provided for @backupPreviewRestoreConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedek geri yüklensin mi?'**
  String get backupPreviewRestoreConfirmTitle;

  /// No description provided for @backupPreviewRestoreConfirmDesc.
  ///
  /// In tr, this message translates to:
  /// **'Cihazdaki tüm cüzdanlar, işlemler, birikimler, borçlar, alacaklar, bütçeler ve düzenli işlem şablonları bu yedektekilerle DEĞİŞTİRİLİR. Bu işlem geri alınamaz.'**
  String get backupPreviewRestoreConfirmDesc;

  /// No description provided for @backupPreviewNoTransactions.
  ///
  /// In tr, this message translates to:
  /// **'Bu yedekte işlem yok.'**
  String get backupPreviewNoTransactions;

  /// No description provided for @backupPreviewUnknownCount.
  ///
  /// In tr, this message translates to:
  /// **'?'**
  String get backupPreviewUnknownCount;

  /// No description provided for @disconnectConfirmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı kesilsin mi?'**
  String get disconnectConfirmTitle;

  /// No description provided for @disconnectConfirmDesc.
  ///
  /// In tr, this message translates to:
  /// **'{email} hesabından çıkılacak. Google Drive\'daki yedekleriniz SİLİNMEZ — aynı hesapla tekrar bağlandığınızda erişebilirsiniz. Otomatik yedekleme duracak.'**
  String disconnectConfirmDesc(String email);

  /// No description provided for @deleteAllBackupsDangerDesc.
  ///
  /// In tr, this message translates to:
  /// **'Onayladığınızda Google Drive\'daki {count} yedek kopyasının tamamı kalıcı olarak silinir. Cihazınızdaki veriler bozulur ya da silinirse geri dönebileceğiniz hiçbir kopya kalmaz.'**
  String deleteAllBackupsDangerDesc(int count);

  /// No description provided for @driveErrApiNotEnabled.
  ///
  /// In tr, this message translates to:
  /// **'Google Drive API bu uygulama için etkinleştirilmemiş. Bu bir kurulum eksiği; kullanıcı izniyle çözülemez.'**
  String get driveErrApiNotEnabled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
