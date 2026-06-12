// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get language => 'Dil';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String get hataDetayi => 'Hata detayı';

  @override
  String get tekrarDene => 'Tekrar Dene';

  @override
  String get islemGecmisiCsv => 'İşlem Geçmişi (CSV)';

  @override
  String get duzenle => 'Düzenle';

  @override
  String get sil => 'Sil';

  @override
  String get hintIkonAra => 'İkon ara...';

  @override
  String hataStateFailureMessage(Object message) {
    return 'Hata: $message';
  }

  @override
  String get yeniButceEkle => 'Yeni Bütçe Ekle';

  @override
  String get labelKategori => 'Kategori';

  @override
  String get labelAylikLimit => 'Aylık Limit';

  @override
  String get iptal => 'İptal';

  @override
  String get borclarim => 'Borçlarım';

  @override
  String get alacaklarim => 'Alacaklarım';

  @override
  String get henuzBorcKaydiYok => 'Henüz borç kaydı yok.';

  @override
  String get odemeYap => 'Ödeme Yap';

  @override
  String get ode => 'Öde';

  @override
  String get henuzAlacakKaydiYok => 'Henüz alacak kaydı yok.';

  @override
  String get odendiIsaretle => 'Ödendi İşaretle';

  @override
  String get gecmis => 'Geçmiş';

  @override
  String get borcGecmisi => 'Borç Geçmişi';

  @override
  String get alacakGecmisi => 'Alacak Geçmişi';

  @override
  String get aylikTaksitiBiliyorum => 'Aylık taksiti biliyorum';

  @override
  String get faizOraniIle => 'Faiz oranı ile';

  @override
  String get esitTaksitAmortisman => 'Eşit Taksit (Amortisman)';

  @override
  String get basitVadeFarki => 'Basit Vade Farkı';

  @override
  String get odemeyiKaydet => 'Ödemeyi Kaydet';

  @override
  String get labelOdemeTutari => 'Ödeme Tutarı *';

  @override
  String maksimumFormatmoneyRemaining(Object remaining) {
    return 'Maksimum: $remaining';
  }

  @override
  String get labelOdemeTarihi => 'Ödeme Tarihi';

  @override
  String get labelNotOpsiyonel => 'Not (Opsiyonel)';

  @override
  String get hintOdemeIleIlgiliNotlar => 'Ödeme ile ilgili notlar...';

  @override
  String get islemDetayi => 'İşlem Detayı';

  @override
  String get bekleyenIslemler => 'Bekleyen İşlemler';

  @override
  String get islemRaporu => 'İşlem Raporu';

  @override
  String get tooltipTarihAraligi => 'Tarih Aralığı';

  @override
  String get msgSecilenTarihAraligindaIslem => 'Seçilen tarih aralığında işlem yok';

  @override
  String get degistir => 'Değiştir';

  @override
  String get labelKategoriAdi => 'Kategori Adı';

  @override
  String get hintOrnMarketKiraMaas => 'Örn: Market, Kira, Maaş';

  @override
  String get ozelKategoriler => 'Özel Kategoriler';

  @override
  String get varsayilanKategoriler => 'Varsayılan Kategoriler';

  @override
  String get yeniKategoriEkle => 'Yeni Kategori Ekle';

  @override
  String get temizle => 'Temizle';

  @override
  String get labelMin => 'Min';

  @override
  String get labelMax => 'Max';

  @override
  String get hintNotIstegeBagliOrn => 'Not (İsteğe bağlı) · örn. Market alışverişi';

  @override
  String get tekrarlamaIstegeBagli => 'Tekrarlama (İsteğe Bağlı)';

  @override
  String get tekrarEtme => 'Tekrar Etme';

  @override
  String get birikimDetayi => 'Birikim Detayı';

  @override
  String get vazgec => 'Vazgeç';

  @override
  String get sat => 'Sat';

  @override
  String get kaydiSil => 'Kaydı Sil';

  @override
  String get tooltipFiyatlariGuncelle => 'Fiyatları Güncelle';

  @override
  String get hintSembolOrnAaplThyao => 'Sembol (Örn: AAPL, THYAO.IS)';

  @override
  String get sablonuSil => 'Şablonu Sil';

  @override
  String hataError(Object error) {
    return 'Hata: $error';
  }

  @override
  String get tooltipBuVadeyiAtla => 'Bu vadeyi atla';

  @override
  String get onayla => 'Onayla';

  @override
  String get kapat => 'Kapat';

  @override
  String get islemiDuzenle => 'İşlemi Düzenle';

  @override
  String get labelYeniTutar => 'Yeni Tutar';

  @override
  String get kaydetVeOnayla => 'Kaydet ve Onayla';

  @override
  String get guvenlikAyarlari => 'Güvenlik Ayarları';

  @override
  String get iceAktarCsv => 'İçe Aktar (CSV)';

  @override
  String get disaAktarCsv => 'Dışa Aktar (CSV)';

  @override
  String get geriYukle => 'Geri Yükle';

  @override
  String get yedekle => 'Yedekle';

  @override
  String get labelUygulamaTemasi => 'Uygulama Teması';

  @override
  String get labelCuzdanAdi => 'Cüzdan Adı *';

  @override
  String get hintOrnAnaCuzdanTatil => 'Örn: Ana Cüzdan, Tatil Fonu';

  @override
  String get tamam => 'Tamam';

  @override
  String get beklenmeyenDurum => 'Beklenmeyen durum';

  @override
  String get aktifCuzdaniniziDegistirmekIcin => '• Aktif cüzdanınızı değiştirmek için bir cüzdana tıklayın.';

  @override
  String get cuzdanBakiyeleriOtomatikOlarak => '• Cüzdan bakiyeleri otomatik olarak güncellenir.';

  @override
  String get herCuzdaninKendiGelir => '• Her cüzdanın kendi gelir/gider kayıtları vardır.';

  @override
  String msgTextsCheckfailedprefixETostring(Object checkFailedPrefix, Object error) {
    return '$checkFailedPrefix: $error';
  }

  @override
  String msgPINVerificationFailedE(Object error) {
    return 'PIN doğrulama başarısız: $error';
  }

  @override
  String get msgCreateAPinFirst => 'Önce bir PIN oluşturun';

  @override
  String get msgBiometricAuthenticationIsNot => 'Biyometrik kimlik doğrulama desteklenmiyor';

  @override
  String get msgBiometricAuthenticationFailed => 'Biyometrik kimlik doğrulama başarısız';

  @override
  String get msgBiometricLoginEnabled => 'Biyometrik giriş etkinleştirildi';

  @override
  String get msgBiometricLoginDisabled => 'Biyometrik giriş devre dışı bırakıldı';

  @override
  String get msgPINAlreadyExistsUse => 'PIN zaten mevcut, bunun yerine PIN değiştirmeyi kullanın';

  @override
  String get msgPINsDoNotMatch => 'PIN\'ler eşleşmiyor';

  @override
  String get msgPINSavedSuccessfully => 'PIN başarıyla kaydedildi';

  @override
  String get msgNewPinValuesDo => 'Yeni PIN değerleri eşleşmiyor';

  @override
  String get msgCurrentPinIsIncorrect => 'Mevcut PIN hatalı';

  @override
  String get msgPINUpdatedSuccessfully => 'PIN başarıyla güncellendi';

  @override
  String get msgPINRemoved => 'PIN kaldırıldı';

  @override
  String get msgBackgroundLockAndPrivacy => 'Arka plan kilidi ve Ekran Koruması etkinleştirildi';

  @override
  String get securitySettings => 'Güvenlik Ayarları';

  @override
  String get manageYourAppSecurity => 'Uygulama güvenliğinizi yönetin';

  @override
  String get createPin => 'PIN Oluştur';

  @override
  String get changePin => 'PIN Değiştir';

  @override
  String get removePin => 'PIN Kaldır';

  @override
  String get msgBiometricAuthenticationCannotBe => 'Biyometrik kimlik doğrulama bu cihazda kullanılamaz.';

  @override
  String get msgCreateAPinFirst2 => 'Biyometrik girişi etkinleştirmek için önce bir PIN oluşturun.';

  @override
  String get unifiedFeaturesDemo => 'Birleşik Özellikler Demosu';

  @override
  String get tarihSec => 'Tarih Seç';

  @override
  String get dialog => 'Dialog';

  @override
  String get metinGiris => 'Metin Giriş';

  @override
  String get yukle => 'Yükle';

  @override
  String get basarili => 'Başarılı';

  @override
  String get hata => 'Hata';

  @override
  String get yuklemeButonu => 'Yükleme Butonu';

  @override
  String get onayDialog => 'Onay Dialog';

  @override
  String get logoutLabel => 'Çıkış Yap';

  @override
  String get welcomeTitle => 'Hoş Geldiniz';

  @override
  String get enterPinPrompt => 'Devam etmek için PIN girin';

  @override
  String get lockedOutPromptPrefix => 'Çok fazla başarısız deneme. Lütfen';

  @override
  String get lockedOutPromptSuffix => 'saniye bekleyin.';

  @override
  String get invalidPinFallback => 'Hatalı PIN, tekrar deneyin.';

  @override
  String get biometricReason => 'Devam etmek için kimliğinizi doğrulayın';

  @override
  String get settingsTitle => 'Güvenlik Ayarları';

  @override
  String get createPinTitle => 'PIN Oluştur';

  @override
  String get changePinTitle => 'PIN Değiştir';

  @override
  String get deletePinTitle => 'PIN Kaldır';

  @override
  String get verifyPinTitle => 'PIN Doğrula';

  @override
  String get deletePinConfirmMessage => 'PIN kaldırma biyometrik girişi de devre dışı bırakır. Devam edilsin mi?';

  @override
  String get saveLabel => 'Kaydet';

  @override
  String get changeLabel => 'Değiştir';

  @override
  String get removeLabel => 'Kaldır';

  @override
  String get cancelLabel => 'İptal';

  @override
  String get pinMismatchMessage => 'PIN\'ler eşleşmiyor';

  @override
  String get pinValidationMessage => '6 haneli bir PIN girin';

  @override
  String get pinLockTitle => 'PIN Kilidi';

  @override
  String get pinEnabledSubtitle => 'PIN etkin';

  @override
  String get pinNotSetSubtitle => 'PIN ayarlanmamış';

  @override
  String get biometricLoginTitle => 'Biyometrik Giriş';

  @override
  String get biometricNotAvailableSubtitle => 'Biyometrik kimlik doğrulama bu cihazda kullanılamaz';

  @override
  String get biometricEnabledSubtitle => 'Biyometrik giriş etkin';

  @override
  String get biometricDisabledSubtitle => 'Biyometrik giriş devre dışı';

  @override
  String get biometricAuthTileTitle => 'Biyometrik Kimlik Doğrulama';

  @override
  String get biometricAuthTileSubtitleOn => 'Açık - Parmak izi veya yüz tanıma ile giriş yapın';

  @override
  String get biometricAuthTileSubtitleOff => 'Kapalı';

  @override
  String get privacyGuardTitle => 'Gizlilik Koruması';

  @override
  String get privacyGuardEnabledSubtitle => 'Ekran koruması etkin';

  @override
  String get privacyGuardDisabledSubtitle => 'Ekran koruması devre dışı';

  @override
  String get screenProtectionTileTitle => 'Ekran Koruması';

  @override
  String get screenProtectionTileSubtitleOn => 'Açık - Uygulama arka plandayken içeriği gizle';

  @override
  String get screenProtectionTileSubtitleOff => 'Kapalı';

  @override
  String get backgroundLockTitle => 'Arka Plan Kilidi';

  @override
  String get backgroundLockSubtitlePrefix => 'Şu süre sonunda kilitler: ';

  @override
  String get backgroundLockSubtitleOff => 'Kapalı';

  @override
  String get backgroundLockTileTitle => 'Uygulama arka planda kaldığında kimlik doğrulama gerektir';

  @override
  String get backgroundLockTileSubtitle => 'Arka plan kilidini etkinleştirmek için bir PIN ayarlayın veya biyometrik girişi açın.';

  @override
  String get backgroundLockTileInfo => 'Not: Uygulamaya dönerken kimlik doğrulama ekranı görünür.';

  @override
  String msgIncorrectPinRemainingTries(Object newAttempts) {
    return 'Hatalı PIN. Kalan deneme: $newAttempts';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get appearance => 'GÖRÜNÜM';

  @override
  String get security => 'GÜVENLİK';

  @override
  String get dataBackupTransfer => 'VERİ YEDEKLEME / AKTARIM';

  @override
  String get about => 'HAKKINDA';

  @override
  String get googleDriveBackup => 'Google Drive Yedekleme';

  @override
  String get googleDriveBackupDesc => 'Verilerinizin güvenliği için kendi kişisel Google Drive hesabınıza yedekleme yapın.';

  @override
  String get connectGoogleDrive => 'Google Drive\'a Bağlan';

  @override
  String get account => 'Hesap:';

  @override
  String get lastBackup => 'Son Yedekleme:';

  @override
  String get disconnect => 'Bağlantıyı Kes';

  @override
  String get version => 'Sürüm';

  @override
  String get developer => 'Geliştirici';

  @override
  String get noBackupsYet => 'Hiç yedekleme yapılmadı';

  @override
  String get restoreDataTitle => 'Verileri Geri Yükle?';

  @override
  String get restoreDataDesc => 'Buluttaki verileriniz cihazınızdaki mevcut verilerin üzerine yazılacaktır. Bu işlem geri alınamaz.';

  @override
  String get googleDriveConnected => 'Google Drive başarıyla bağlandı.';

  @override
  String get googleDriveConnectionFailed => 'Google Drive bağlantısı başarısız oldu.';

  @override
  String get googleDriveDisconnected => 'Google Drive bağlantısı kesildi.';

  @override
  String get dataBackedUpSuccess => 'Veriler Google Drive\'a başarıyla yedeklendi.';

  @override
  String get backupFailed => 'Yedekleme başarısız oldu.';

  @override
  String get dataRestoredSuccess => 'Veriler başarıyla geri yüklendi. Değişikliklerin görünmesi için lütfen uygulamayı yeniden başlatın.';

  @override
  String get restoreFailedNoBackup => 'Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.';

  @override
  String get welcomeUser => 'Hoşgeldiniz';

  @override
  String get defaultUser => 'Kullanıcı';

  @override
  String get dataExportImport => 'İşlem Dışa / İçe Aktar';

  @override
  String get dataExportImportDesc => 'Tüm işlemlerinizi standart CSV formatında dışa aktararak diğer uygulamalarda kullanabilir veya yedekleyebilirsiniz.';

  @override
  String get activeWalletRequiredForExport => 'Dışa aktarım için aktif bir cüzdan gereklidir.';

  @override
  String get uygulamaBaslatilamadi => 'Uygulama başlatılamadı';

  @override
  String get verilerinizSilinmediTekrarDeneyin => 'Verileriniz silinmedi. Tekrar deneyin; sorun sürerse ';

  @override
  String get ikonBulunamadi => 'İkon bulunamadı';

  @override
  String valueTostringasfixedCurrencysymbol(Object toStringAsFixed, Object currencySymbol) {
    return '$toStringAsFixed $currencySymbol';
  }

  @override
  String get butcePlanlama => 'Bütçe Planlama';

  @override
  String get henuzButceYok => 'Henüz bütçe yok';

  @override
  String get kategorilerinizeAylikHarcamaLimiti => 'Kategorilerinize aylık harcama limiti koyun,\nharcamalarınızı buradan takip edin.';

  @override
  String get bUAyToplamHarcama => 'BU AY TOPLAM HARCAMA';

  @override
  String toplamLimitAppformattersCurrency(Object totalLimit) {
    return 'Toplam limit: $totalLimit';
  }

  @override
  String percent(Object percent) {
    return '%$percent';
  }

  @override
  String harcananAppformattersCurrencyFormat(Object spentAmount) {
    return 'Harcanan: $spentAmount';
  }

  @override
  String limitAppformattersCurrencyFormat(Object limitAmount) {
    return 'Limit: $limitAmount';
  }

  @override
  String get buKategorininButcesiVar => 'Bu kategorinin bütçesi var; limit güncellenecek.';

  @override
  String get finansalTakip => 'Finansal Takip';

  @override
  String get vADESIGecmis => 'VADESİ GEÇMİŞ';

  @override
  String get oDENDI => 'ÖDENDİ';

  @override
  String vadeDebtTermmonthsAy(Object termMonths, Object length) {
    return 'Vade: $termMonths Ay | $length Ödeme';
  }

  @override
  String vadeDateformatDdMmm(Object dueDate) {
    return 'Vade: $dueDate';
  }

  @override
  String get msgOdemesiTamamlanipKapatilanBorclarinizin => 'Ödemesi tamamlanıp kapatılan borçlarınızın geçmişi burada görüntülenecektir.';

  @override
  String paidDebtsLengthBorcKapandi(Object length) {
    return '$length borç kapandı';
  }

  @override
  String get msgOdendiOlarakIsaretlenenAlacaklarinizin => 'Ödendi olarak işaretlenen alacaklarınızın geçmişi burada görüntülenecektir.';

  @override
  String paidReceivablesLengthAlacakTahsil(Object length) {
    return '$length alacak tahsil edildi';
  }

  @override
  String get toplamGeriOdeme => 'Toplam geri ödeme';

  @override
  String get kKDFVeBsmvVergilerini => 'KKDF ve BSMV vergilerini (%30) dahil et';

  @override
  String get tuketiciKredilerindeFaizeYasal => 'Tüketici kredilerinde faize yasal olarak %15 KKDF ve %15 BSMV eklenir. Konut vb. kredilerde bu vergiler %0 olabilir. Duruma göre aktifleştirin.';

  @override
  String iTaksitAppformattersDateshort(Object i, Object scheduledDate) {
    return '$i. Taksit — $scheduledDate';
  }

  @override
  String formatMoneyMonthlyamount(Object monthlyAmount) {
    return '≈ $monthlyAmount';
  }

  @override
  String index(Object index) {
    return '$index';
  }

  @override
  String optLabelFormatmoneyOpt(Object label, Object amount) {
    return '$label  $amount';
  }

  @override
  String get otomatikIslem => 'Otomatik işlem';

  @override
  String get buIslemOtomatikOlusturuldu => 'Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından düzenleyin veya silin.';

  @override
  String get nakitAkisi => 'Nakit Akışı';

  @override
  String get grafikIcinYeterliVeri => 'Grafik için yeterli veri yok';

  @override
  String get detayGosterilecekIslemYok => 'Detay Gösterilecek İşlem Yok';

  @override
  String get gelirVeyaGiderKaydettikten => 'Gelir veya gider kaydettikten sonra analiz detayları burada listelenecektir.';

  @override
  String get henuzIslemYok => 'Henüz işlem yok';

  @override
  String get buDonemIcinKayit => 'Bu dönem için kayıt bulunmuyor.\nYeni bir işlem eklemek için sürgü butonunu kullanın.';

  @override
  String get tumIslemlerinizGuncel => 'Tüm İşlemleriniz Güncel';

  @override
  String get bekleyenCevrimdisiIslemBulunmuyor => 'Bekleyen çevrimdışı işlem bulunmuyor. Cihazınız internete bağlandığında veya yeni veriler girildiğinde senkronizasyon otomatik olarak tetiklenir.';

  @override
  String get haftalikNetAkis => 'Haftalık Net Akış';

  @override
  String get kategoriDagilimi => 'Kategori Dağılımı';

  @override
  String titleIcinVeriYok(Object title) {
    return '$title için veri yok';
  }

  @override
  String get buKategoriyeAitIslem => 'Bu kategoriye ait işlem bulunmuyor.';

  @override
  String formatMoneyItemTotalamountPercent(Object totalAmount, Object toStringAsFixed) {
    return '$totalAmount (%$toStringAsFixed)';
  }

  @override
  String get buDonemIcinHenuz => 'Bu dönem için henüz işlem verisi bulunamadı. Raporlar veri girildikten sonra derlenecektir.';

  @override
  String get ikonSecin => 'İkon Seçin';

  @override
  String get ikonDegistirmekIcinDokun => 'İkon değiştirmek için dokun';

  @override
  String categoriesWhereCC(Object customLength, Object defaultLength) {
    return '$customLength özel, $defaultLength varsayılan';
  }

  @override
  String get asagidakiButondanEkleyebilirsiniz => 'Aşağıdaki butondan ekleyebilirsiniz';

  @override
  String get varsayilan => 'Varsayılan';

  @override
  String get filtreler => 'Filtreler';

  @override
  String get uygula => 'Uygula';

  @override
  String get tARIHAraligi => 'TARİH ARALIĞI';

  @override
  String get seciliAralik => 'Seçili Aralık';

  @override
  String get kATEGORIFiltresi => 'KATEGORİ FİLTRESİ';

  @override
  String get kategoriBulunamadi => 'Kategori bulunamadı';

  @override
  String get fIYATAraligi => 'FİYAT ARALIĞI';

  @override
  String get yeni => 'Yeni';

  @override
  String appFormattersDateshortFormatStartdate(Object startDate, Object endDate) {
    return '$startDate - $endDate';
  }

  @override
  String filterSelectedcategoriesLengthKategori(Object length) {
    return '$length Kategori';
  }

  @override
  String get gunSonu => 'Gün sonu ';

  @override
  String netNetAppformattersCurrency(Object net) {
    return 'Net: $net';
  }

  @override
  String dataFilterSelectedcategoriesLengthKategori(Object length) {
    return '$length Kategori';
  }

  @override
  String countCountlabel(Object count, Object countLabel) {
    return '$count $countLabel';
  }

  @override
  String get portfoyDetayi => 'Portföy Detayı';

  @override
  String get henuzYatirimKaydiYok => 'Henüz Yatırım Kaydı Yok';

  @override
  String get yatirimlariniziEklediktenSonraDetayli => 'Yatırımlarınızı ekledikten sonra detaylı analizler burada görünecektir.';

  @override
  String guncelDegerFormatmoneyInvestment(Object currentValue) {
    return 'Güncel değer ($currentValue) cüzdana gelir olarak işlenir ve kayıt kapatılır.';
  }

  @override
  String hataliGirislerIcinAlim(Object amount) {
    return 'Hatalı girişler için: alım gideri ($amount) düzeltme kaydıyla iade edilir, bakiye yatırım öncesine döner.\n\nGerçekten sattıysanız bunun yerine \"Sat\" kullanın.';
  }

  @override
  String get portfoyum => 'Portföyüm';

  @override
  String investmentsLengthYatirim(Object length) {
    return '$length yatırım';
  }

  @override
  String get mevcutDeger => 'Mevcut Değer';

  @override
  String get maliyetiDegistirirsenizFarkCuzdana => 'Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.';

  @override
  String get hesapla => 'Hesapla';

  @override
  String birikmisFormatmoneyInvCurrentvalue(Object currentValue) {
    return 'Birikmiş: $currentValue / ';
  }

  @override
  String get guncelFiyatiGetir => 'Güncel Fiyatı Getir';

  @override
  String get ekle => 'Ekle';

  @override
  String get karZarar => 'Kar/Zarar';

  @override
  String investmentProfitpercentageTostringasfixed(Object toStringAsFixed) {
    return '$toStringAsFixed%';
  }

  @override
  String hedefCurrencyformatFormatInvestment(Object targetAmount) {
    return 'Hedef: $targetAmount';
  }

  @override
  String investmentTargetprogressTostringasfixed(Object toStringAsFixed) {
    return '$toStringAsFixed%';
  }

  @override
  String get grafikIcinYatirimBulunmuyor => 'Grafik için yatırım bulunmuyor';

  @override
  String get portfoyDagilimi => 'Portföy Dağılımı';

  @override
  String percentage(Object percentage) {
    return '%$percentage';
  }

  @override
  String get tOPLAMPortfoyDegeri => 'TOPLAM PORTFÖY DEĞERİ';

  @override
  String get tOPLAMMaliyet => 'TOPLAM MALİYET';

  @override
  String get kAZANCZarar => 'KAZANÇ / ZARAR';

  @override
  String isProfitTotalprofitpercentageTostringasfixed(Object isProfit, Object toStringAsFixed) {
    return '$isProfit$toStringAsFixed%';
  }

  @override
  String templateTitleDuzenliIslemi(Object title) {
    return '\"$title\" düzenli işlemi silinsin mi?\n\nDeftere işlenmiş geçmiş işlemler silinmez.';
  }

  @override
  String get duzenliIslemler => 'Düzenli İşlemler';

  @override
  String get henuzDuzenliIslemYok => 'Henüz düzenli işlem yok';

  @override
  String get islemEklerkenTekrarSikligi => 'İşlem eklerken tekrar sıklığı seçerseniz\nşablon burada görünür.';

  @override
  String get bekleyenDuzenliIslemler => 'Bekleyen Düzenli İşlemler';

  @override
  String get vadesiGelmisIslemlerinizVar => 'Vadesi gelmiş işlemleriniz var. Onaylayarak deftere işlenmesini sağlayabilirsiniz.';

  @override
  String titleTarihDatestrNtutarTx(Object dateStr, Object amount) {
    return 'Tarih: $dateStr\nTutar: $amount';
  }

  @override
  String get profilAyarlari => 'Profil Ayarları';

  @override
  String get bilgileriGuncelle => 'Bilgileri Güncelle';

  @override
  String get ibo => 'İbo';

  @override
  String get uygulamaKilidi => 'Uygulama Kilidi';

  @override
  String get pINBiyometrikVeGizlilik => 'PIN, Biyometrik ve Gizlilik Ayarları';

  @override
  String get otomatikHesaplananDegerler => 'Otomatik hesaplanan değerler:';

  @override
  String get borcAlacakYatirimKayitlarindan => 'Borç/alacak/yatırım kayıtlarından türetilir; buradan düzenlenemez.';

  @override
  String get renkSecin => 'Renk Seçin:';

  @override
  String get ikonSecin2 => 'İkon Seçin:';

  @override
  String get ikonDegistir => 'İkon Değiştir';

  @override
  String get cuzdanlarim => 'Cüzdanlarım';

  @override
  String get cuzdanlariniziYonetin => 'Cüzdanlarınızı yönetin';

  @override
  String get yeniCuzdanOlustur => 'Yeni Cüzdan Oluştur';

  @override
  String get finansalNyolculugunuzBasliyor => 'Finansal\nYolculuğunuz Başlıyor';

  @override
  String get ilkCuzdaniOlustur => 'İlk Cüzdanı Oluştur';

  @override
  String olusturulmaAppformattersDateshortFormat(Object createdAt) {
    return 'Oluşturulma: $createdAt';
  }

  @override
  String get aktif => 'Aktif';

  @override
  String get aktifOlanCuzdanSilinemez => '• Aktif olan cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yapmalısınız.';

  @override
  String get cuzdanlarinizaAitBorcAlacak => '• Cüzdanlarınıza ait Borç, Alacak ve Birikim tutarlarını düzenle sayfasından manuel olarak yönetebilirsiniz.';

  @override
  String get msgPINOrBiometricLogin => 'PIN veya biyometrik giriş arka plan kilidi için gereklidir';

  @override
  String get sharedFeatures => 'Paylaşılan Özellikler';

  @override
  String get tarihAraligi => 'Tarih Aralığı';

  @override
  String get butonGalerisi => 'Buton Galerisi';

  @override
  String get internetBaglantisiAktif => 'İnternet bağlantısı aktif';

  @override
  String get internetBaglantisiYok => 'İnternet bağlantısı yok';

  @override
  String get baglantiKontrolEdiliyor => 'Bağlantı kontrol ediliyor...';

  @override
  String get taksit1 => '1 taksit';

  @override
  String get taksit2 => '2 taksit';

  @override
  String get tamaminiOde => 'Tamamını öde';
}
