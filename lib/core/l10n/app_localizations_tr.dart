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
  String get tekrarDene => 'Tekrar dene';

  @override
  String get islemGecmisiCsv => 'İşlem geçmişi (CSV)';

  @override
  String get duzenle => 'Düzenle';

  @override
  String get sil => 'Sil';

  @override
  String get geriAl => 'Geri al';

  @override
  String get silmeGeriAlindi => 'Silme geri alındı';

  @override
  String get silmeGeriAlinamadi =>
      'Geri alma başarısız oldu; kayıt geri getirilemedi';

  @override
  String get hintIkonAra => 'İkon ara...';

  @override
  String hataStateFailureMessage(Object message) {
    return 'Hata: $message';
  }

  @override
  String get yeniButceEkle => 'Yeni bütçe ekle';

  @override
  String get labelKategori => 'Kategori';

  @override
  String get labelAylikLimit => 'Aylık limit';

  @override
  String get iptal => 'İptal';

  @override
  String get borclarim => 'Borçlarım';

  @override
  String get alacaklarim => 'Alacaklarım';

  @override
  String get henuzBorcKaydiYok => 'Henüz borcun yok';

  @override
  String get henuzBorcKaydiYokAciklama =>
      'Kredi ya da borcun olunca buraya yaz; ödemelerini buradan takip edersin.';

  @override
  String get odemeYap => 'Ödeme yap';

  @override
  String get ode => 'Öde';

  @override
  String get henuzAlacakKaydiYok => 'Henüz alacağın yok';

  @override
  String get henuzAlacakKaydiYokAciklama =>
      'Birine verdiğin parayı buraya yaz; geri aldığında işaretlersin.';

  @override
  String get odendiIsaretle => 'Ödendi işaretle';

  @override
  String get gecmis => 'Geçmiş';

  @override
  String get borcGecmisi => 'Borç geçmişi';

  @override
  String get alacakGecmisi => 'Alacak geçmişi';

  @override
  String get aylikTaksitiBiliyorum => 'Aylık taksiti biliyorum';

  @override
  String get faizOraniIle => 'Faiz oranı ile';

  @override
  String get esitTaksitAmortisman => 'Eşit taksit (amortisman)';

  @override
  String get basitVadeFarki => 'Basit vade farkı';

  @override
  String get odemeyiKaydet => 'Ödemeyi kaydet';

  @override
  String get labelOdemeTutari => 'Ödeme tutarı *';

  @override
  String maksimumFormatmoneyRemaining(Object remaining) {
    return 'Maksimum: $remaining';
  }

  @override
  String get labelOdemeTarihi => 'Ödeme tarihi';

  @override
  String get labelNotOpsiyonel => 'Not (isteğe bağlı)';

  @override
  String get hintOdemeIleIlgiliNotlar => 'Ödeme ile ilgili notlar...';

  @override
  String get islemDetayi => 'İşlem detayı';

  @override
  String get islemRaporu => 'İşlem raporu';

  @override
  String oncekiDonemeGorePercent(Object percent) {
    return '%$percent önceki döneme göre';
  }

  @override
  String get msgSecilenTarihAraligindaIslem =>
      'Seçilen tarih aralığında işlem yok';

  @override
  String get degistir => 'Değiştir';

  @override
  String get labelKategoriAdi => 'Kategori adı';

  @override
  String get hintOrnMarketKiraMaas => 'Örn: Market, Kira, Maaş';

  @override
  String get yeniKategoriEkle => 'Yeni kategori ekle';

  @override
  String get temizle => 'Temizle';

  @override
  String get labelMin => 'Min';

  @override
  String get labelMax => 'Max';

  @override
  String get hintNotIstegeBagliOrn =>
      'Not (isteğe bağlı) · örn. market alışverişi';

  @override
  String get hintNotIstegeBagliOrnGelir =>
      'Not (isteğe bağlı) · örn. ekim maaşı';

  @override
  String get tekrarlamaIstegeBagli => 'Tekrar (isteğe bağlı)';

  @override
  String get tekrarEtme => 'Tek seferlik';

  @override
  String get vazgec => 'Vazgeç';

  @override
  String get sat => 'Sat';

  @override
  String get kaydiSil => 'Kaydı sil';

  @override
  String get tooltipFiyatlariGuncelle => 'Fiyatları güncelle';

  @override
  String get hintSembolOrnAaplThyao => 'Sembol (Örn: AAPL, THYAO.IS)';

  @override
  String get sablonuSil => 'Şablonu sil';

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
  String get islemiDuzenle => 'İşlemi düzenle';

  @override
  String get labelYeniTutar => 'Yeni tutar';

  @override
  String get kaydetVeOnayla => 'Kaydet ve onayla';

  @override
  String get guvenlikAyarlari => 'Güvenlik ayarları';

  @override
  String get iceAktarCsv => 'Yedekten içe aktar (CSV)';

  @override
  String get disaAktarCsv => 'Dışa aktar (CSV)';

  @override
  String get geriYukle => 'Geri yükle';

  @override
  String get yedekle => 'Yedekle';

  @override
  String get labelUygulamaTemasi => 'Uygulama teması';

  @override
  String get labelCuzdanAdi => 'Cüzdan adı *';

  @override
  String get hintOrnAnaCuzdanTatil => 'Örn: Ana Cüzdan, Tatil Fonu';

  @override
  String get tamam => 'Tamam';

  @override
  String get beklenmeyenDurum => 'Beklenmeyen durum';

  @override
  String get aktifCuzdaniniziDegistirmekIcin =>
      '• Aktif cüzdanını değiştirmek için bir cüzdana dokun.';

  @override
  String get cuzdanBakiyeleriOtomatikOlarak =>
      '• Cüzdan bakiyeleri otomatik olarak güncellenir.';

  @override
  String get herCuzdaninKendiGelir =>
      '• Her cüzdanın kendi gelir/gider kayıtları vardır.';

  @override
  String msgTextsCheckfailedprefixETostring(
      Object checkFailedPrefix, Object error) {
    return '$checkFailedPrefix: $error';
  }

  @override
  String msgPINVerificationFailedE(Object error) {
    return 'PIN doğrulama başarısız: $error';
  }

  @override
  String get msgCreateAPinFirst => 'Önce bir PIN oluştur';

  @override
  String get msgBiometricAuthenticationIsNot =>
      'Biyometrik kimlik doğrulama desteklenmiyor';

  @override
  String get msgBiometricAuthenticationFailed =>
      'Biyometrik kimlik doğrulama başarısız';

  @override
  String get msgBiometricLoginEnabled => 'Biyometrik giriş etkinleştirildi';

  @override
  String get msgBiometricLoginDisabled =>
      'Biyometrik giriş devre dışı bırakıldı';

  @override
  String get msgPINAlreadyExistsUse => 'PIN zaten var; PIN değiştirmeyi kullan';

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
  String get msgBackgroundLockAndPrivacy =>
      'Arka plan kilidi ve ekran koruması etkinleştirildi';

  @override
  String get securitySettings => 'Güvenlik ayarları';

  @override
  String get manageYourAppSecurity => 'Uygulama güvenliğini yönet';

  @override
  String get createPin => 'PIN oluştur';

  @override
  String get changePin => 'PIN değiştir';

  @override
  String get removePin => 'PIN kaldır';

  @override
  String get msgBiometricAuthenticationCannotBe =>
      'Biyometrik kimlik doğrulama bu cihazda kullanılamaz.';

  @override
  String get msgCreateAPinFirst2 =>
      'Biyometrik girişi açmak için önce bir PIN oluştur.';

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
  String get yuklemeButonu => 'Yükleme Butonu';

  @override
  String get onayDialog => 'Onay Dialog';

  @override
  String get logoutLabel => 'Çıkış yap';

  @override
  String get welcomeTitle => 'Hoş geldin';

  @override
  String get enterPinPrompt => 'Devam etmek için PIN\'ini gir';

  @override
  String get lockedOutPromptPrefix => 'Çok fazla hatalı deneme.';

  @override
  String get lockedOutPromptSuffix => 'saniye bekle.';

  @override
  String get invalidPinFallback => 'Hatalı PIN, tekrar dene.';

  @override
  String get biometricReason => 'Devam etmek için kimliğini doğrula';

  @override
  String get settingsTitle => 'Güvenlik ayarları';

  @override
  String get createPinTitle => 'PIN oluştur';

  @override
  String get changePinTitle => 'PIN değiştir';

  @override
  String get deletePinTitle => 'PIN kaldır';

  @override
  String get verifyPinTitle => 'PIN doğrula';

  @override
  String get deletePinConfirmMessage =>
      'PIN kaldırma biyometrik girişi de devre dışı bırakır. Devam edilsin mi?';

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
  String get pinValidationMessage => '6 haneli bir PIN gir';

  @override
  String get pinFieldLabel => 'PIN (6 hane)';

  @override
  String get confirmPinFieldLabel => 'PIN\'i doğrula';

  @override
  String get currentPinFieldLabel => 'Mevcut PIN';

  @override
  String get newPinFieldLabel => 'Yeni PIN';

  @override
  String get confirmNewPinFieldLabel => 'Yeni PIN\'i doğrula';

  @override
  String get verifyLabel => 'Doğrula';

  @override
  String get pinLockTitle => 'PIN kilidi';

  @override
  String get pinEnabledSubtitle => 'PIN etkin';

  @override
  String get pinNotSetSubtitle => 'PIN ayarlanmamış';

  @override
  String get biometricLoginTitle => 'Biyometrik giriş';

  @override
  String get biometricNotAvailableSubtitle =>
      'Biyometrik kimlik doğrulama bu cihazda kullanılamaz';

  @override
  String get biometricEnabledSubtitle => 'Biyometrik giriş etkin';

  @override
  String get biometricDisabledSubtitle => 'Biyometrik giriş devre dışı';

  @override
  String get biometricAuthTileTitle => 'Biyometrik kimlik doğrulama';

  @override
  String get biometricAuthTileSubtitleOn =>
      'Açık · Parmak izi ya da yüz tanımayla gir';

  @override
  String get biometricAuthTileSubtitleOff => 'Kapalı';

  @override
  String get privacyGuardTitle => 'Gizlilik koruması';

  @override
  String get stateOnLabel => 'Açık';

  @override
  String get stateOffLabel => 'Kapalı';

  @override
  String get stateUnsupportedLabel => 'Desteklenmiyor';

  @override
  String get methodBiometricLabel => 'biyometrik kimlik doğrulama';

  @override
  String get methodGenericLabel => 'kimlik doğrulama';

  @override
  String get unitSecondsLabel => 'saniye';

  @override
  String get unitMinutesLabel => 'dakika';

  @override
  String get privacyGuardEnabledSubtitle => 'Ekran koruması etkin';

  @override
  String get privacyGuardDisabledSubtitle => 'Ekran koruması devre dışı';

  @override
  String get screenProtectionTileTitle => 'Ekran koruması';

  @override
  String get screenProtectionTileSubtitleOn =>
      'Açık · Uygulama arka plandayken içerik gizlenir';

  @override
  String get screenProtectionTileSubtitleOff => 'Kapalı';

  @override
  String get backgroundLockTitle => 'Arka plan kilidi';

  @override
  String get backgroundLockSubtitlePrefix => 'Şu süre sonunda kilitler: ';

  @override
  String get backgroundLockSubtitleOff => 'Kapalı';

  @override
  String get backgroundLockTileTitle =>
      'Uygulama arka planda kaldığında kimlik doğrulama gerektir';

  @override
  String get backgroundLockTileSubtitle =>
      'Arka plan kilidi için bir PIN ayarla ya da biyometrik girişi aç.';

  @override
  String get backgroundLockTileInfo =>
      'Not: Uygulamaya dönerken kimlik doğrulama ekranı görünür.';

  @override
  String msgIncorrectPinRemainingTries(Object newAttempts) {
    return 'Hatalı PIN. Kalan deneme: $newAttempts';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get appearance => 'Görünüm';

  @override
  String get security => 'Güvenlik';

  @override
  String get dataBackupTransfer => 'Yedekleme ve aktarım';

  @override
  String get about => 'Hakkında';

  @override
  String get googleDriveBackup => 'Google Drive yedekleme';

  @override
  String get googleDriveBackupDesc =>
      'Kayıtlarını kendi Google Drive hesabına yedekle.';

  @override
  String get connectGoogleDrive => 'Google Drive\'a bağlan';

  @override
  String get account => 'Hesap:';

  @override
  String get lastBackup => 'Son yedekleme:';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get deleteBackup => 'Yedeği sil';

  @override
  String get deleteBackupDesc =>
      'Google Drive\'daki yedek dosyası kalıcı olarak silinecek. Telefonundaki kayıtlar etkilenmez.';

  @override
  String get backupDeleted => 'Yedek silindi.';

  @override
  String get deleteBackupFailed => 'Yedek silinemedi.';

  @override
  String get version => 'Sürüm';

  @override
  String get developer => 'Geliştirici';

  @override
  String get noBackupsYet => 'Hiç yedekleme yapılmadı';

  @override
  String get restoreDataTitle => 'Verileri geri yükle?';

  @override
  String get restoreDataDesc =>
      'Buluttaki kayıtlar telefonundaki kayıtların üzerine yazılacak. Bu işlem geri alınamaz.';

  @override
  String get googleDriveConnected => 'Google Drive başarıyla bağlandı.';

  @override
  String get googleDriveConnectionFailed =>
      'Google Drive bağlantısı başarısız oldu.';

  @override
  String get googleDriveDisconnected => 'Google Drive bağlantısı kesildi.';

  @override
  String get dataBackedUpSuccess =>
      'Veriler Google Drive\'a başarıyla yedeklendi.';

  @override
  String get backupFailed => 'Yedekleme başarısız oldu.';

  @override
  String get dataRestoredSuccess => 'Veriler başarıyla geri yüklendi.';

  @override
  String get restoreFailedNoBackup =>
      'Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.';

  @override
  String get defaultUser => 'Kullanıcı';

  @override
  String get dataExportImport => 'Cihaz yedeği / CSV';

  @override
  String get dataExportImportDesc =>
      'Tam yedeği kaydet ya da geri yükle; tek cüzdanın işlemleri için CSV kullan.';

  @override
  String get fullBackup => 'Tam yedek';

  @override
  String get saveFullBackupToDevice => 'Tam yedeği cihaza kaydet';

  @override
  String get restoreFullBackupFromDevice => 'Tam yedeği cihazdan geri yükle';

  @override
  String get shareFullBackup => 'Tam yedeği paylaş';

  @override
  String get transactionCsv => 'İşlem CSV';

  @override
  String get restoreFullBackupTitle => 'Tam yedek geri yüklensin mi?';

  @override
  String get restoreFullBackupDesc =>
      'Bu işlem bu cihazdaki cüzdanları, işlemleri, birikimleri, borçları, alacakları, bütçeleri, tekrar eden işlem şablonlarını, kullanıcıları ve kategorileri değiştirir.';

  @override
  String get fullBackupSaved => 'Tam yedek başarıyla kaydedildi.';

  @override
  String get fullBackupRestored => 'Tam yedek başarıyla geri yüklendi.';

  @override
  String get fullBackupShared => 'Tam yedek başarıyla paylaşıldı.';

  @override
  String get fullBackupCancelled => 'Yedekleme işlemi iptal edildi.';

  @override
  String get fullBackupShareText => 'ÇuHat tam yedeği';

  @override
  String get activeWalletRequiredForExport =>
      'Dışa aktarım için aktif bir cüzdan gereklidir.';

  @override
  String get uygulamaBaslatilamadi => 'Uygulama başlatılamadı';

  @override
  String get verilerinizSilinmediTekrarDeneyin =>
      'Kayıtların silinmedi. Tekrar dene; sorun sürerse ';

  @override
  String get ikonBulunamadi => 'İkon bulunamadı';

  @override
  String get butcePlanlama => 'Bütçe';

  @override
  String get henuzButceYok => 'Henüz bütçe yok';

  @override
  String get kategorilerinizeAylikHarcamaLimiti =>
      'Kategorilerine aylık harcama sınırı koy,\nharcamalarını buradan takip et.';

  @override
  String get bUAyToplamHarcama => 'Bu ay toplam harcama';

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
  String get buKategorininButcesiVar =>
      'Bu kategorinin bütçesi var; limit güncellenecek.';

  @override
  String get finansalTakip => 'Borç ve alacak';

  @override
  String get vADESIGecmis => 'Vadesi geçmiş';

  @override
  String get oDENDI => 'Ödendi';

  @override
  String vadeDateformatDdMmm(Object dueDate) {
    return 'Vade: $dueDate';
  }

  @override
  String get msgOdemesiTamamlanipKapatilanBorclarinizin =>
      'Ödemesi biten borçların burada görünür.';

  @override
  String paidDebtsLengthBorcKapandi(Object length) {
    return '$length borç kapandı';
  }

  @override
  String get msgOdendiOlarakIsaretlenenAlacaklarinizin =>
      'Geri aldığın alacaklar burada görünür.';

  @override
  String paidReceivablesLengthAlacakTahsil(Object length) {
    return '$length alacak tahsil edildi';
  }

  @override
  String get toplamGeriOdeme => 'Toplam geri ödeme';

  @override
  String get kKDFVeBsmvVergilerini => 'KKDF ve BSMV vergilerini (%30) dahil et';

  @override
  String get tuketiciKredilerindeFaizeYasal =>
      'Tüketici kredilerinde faize yasal olarak %15 KKDF ve %15 BSMV eklenir. Konut vb. kredilerde bu vergiler %0 olabilir. Duruma göre aktifleştirin.';

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
  String get buIslemOtomatikOlusturuldu =>
      'Bu işlem otomatik oluşturuldu. İlgili borç, birikim ya da alacak kaydından düzenle ya da sil.';

  @override
  String get nakitAkisi => 'Nakit akışı';

  @override
  String get grafikIcinYeterliVeri => 'Grafik için yeterli veri yok';

  @override
  String get cizgiGrafikIcinEnAzIkiGun =>
      'Çizgi grafik oluşturmak için en az iki farklı güne ait işlem olmalıdır';

  @override
  String get detayGosterilecekIslemYok => 'Henüz içgörü yok';

  @override
  String get gelirVeyaGiderKaydettikten =>
      'Gelir veya gider kaydettikten sonra analiz detayları burada listelenecektir.';

  @override
  String get henuzIslemYok => 'Henüz kayıt yok';

  @override
  String get buDonemIcinKayit => 'İlk gelirini ya da giderini yaz.';

  @override
  String get kategoriDagilimi => 'Kategori dağılımı';

  @override
  String titleIcinVeriYok(Object title) {
    return '$title için veri yok';
  }

  @override
  String get buKategoriyeAitIslem => 'Bu kategoriye ait işlem bulunmuyor.';

  @override
  String formatMoneyItemTotalamountPercent(
      Object totalAmount, Object toStringAsFixed) {
    return '$totalAmount (%$toStringAsFixed)';
  }

  @override
  String get buDonemIcinHenuz =>
      'Bu dönemde kayıt yok. Kayıt girdikçe rapor burada oluşur.';

  @override
  String get ikonSecin => 'İkon seç';

  @override
  String get ikonDegistirmekIcinDokun => 'İkon değiştirmek için dokun';

  @override
  String get asagidakiButondanEkleyebilirsiniz =>
      'Aşağıdaki düğmeden ekleyebilirsin';

  @override
  String get filtreler => 'Filtreler';

  @override
  String get uygula => 'Uygula';

  @override
  String get tARIHAraligi => 'Tarih aralığı';

  @override
  String get seciliAralik => 'Seçili aralık';

  @override
  String get kATEGORIFiltresi => 'Kategori filtresi';

  @override
  String get kategoriBulunamadi => 'Kategori bulunamadı';

  @override
  String get fIYATAraligi => 'Fiyat aralığı';

  @override
  String get yeni => 'Yeni';

  @override
  String appFormattersDateshortFormatStartdate(
      Object startDate, Object endDate) {
    return '$startDate - $endDate';
  }

  @override
  String filterSelectedcategoriesLengthKategori(Object length) {
    return '$length kategori';
  }

  @override
  String get gunSonu => 'Gün sonu ';

  @override
  String netNetAppformattersCurrency(Object net) {
    return 'Net: $net';
  }

  @override
  String get gorunumListe => 'Liste';

  @override
  String get gorunumTakvim => 'Takvim';

  @override
  String get takvimAy => 'Ay';

  @override
  String get takvimHafta => 'Hafta';

  @override
  String get buGuneAitIslemYok => 'Bu güne ait işlem yok';

  @override
  String dataFilterSelectedcategoriesLengthKategori(Object length) {
    return '$length kategori';
  }

  @override
  String countCountlabel(Object count, Object countLabel) {
    return '$count $countLabel';
  }

  @override
  String get portfoyDetayi => 'Birikim ayrıntısı';

  @override
  String get henuzYatirimKaydiYok => 'Henüz birikim kaydı yok';

  @override
  String get yatirimlariniziEklediktenSonraDetayli =>
      'Birikimlerini ekledikçe ayrıntılı analiz burada görünür.';

  @override
  String guncelDegerFormatmoneyInvestment(Object currentValue) {
    return 'Güncel değer ($currentValue) cüzdana gelir olarak işlenir ve kayıt kapatılır.';
  }

  @override
  String hataliGirislerIcinAlim(Object amount) {
    return 'Hatalı girişler için: alım gideri ($amount) düzeltme kaydıyla iade edilir, bakiye alım öncesine döner.\n\nGerçekten sattıysan bunun yerine \"Sat\"ı kullan.';
  }

  @override
  String get portfoyum => 'Portföyüm';

  @override
  String investmentsLengthYatirim(Object length) {
    return '$length varlık';
  }

  @override
  String get mevcutDeger => 'Mevcut değer';

  @override
  String get maliyetiDegistirirsenizFarkCuzdana =>
      'Maliyeti değiştirirsen fark, cüzdana düzeltme hareketi olarak işlenir.';

  @override
  String get hesapla => 'Hesapla';

  @override
  String birikmisFormatmoneyInvCurrentvalue(Object currentValue) {
    return 'Birikmiş: $currentValue / ';
  }

  @override
  String get guncelFiyatiGetir => 'Güncel fiyatı getir';

  @override
  String get ekle => 'Ekle';

  @override
  String get karZarar => 'Kâr/zarar';

  @override
  String hedefCurrencyformatFormatInvestment(Object targetAmount) {
    return 'Hedef: $targetAmount';
  }

  @override
  String get grafikIcinYatirimBulunmuyor => 'Grafik için varlık yok';

  @override
  String get portfoyDagilimi => 'Birikim dağılımı';

  @override
  String get tOPLAMPortfoyDegeri => 'Toplam birikim';

  @override
  String get tOPLAMMaliyet => 'Toplam maliyet';

  @override
  String get kAZANCZarar => 'Kazanç / zarar';

  @override
  String templateTitleDuzenliIslemi(Object title) {
    return '\"$title\" düzenli işlemi silinsin mi?\n\nDeftere işlenmiş geçmiş işlemler silinmez.';
  }

  @override
  String get duzenliIslemler => 'Düzenli işlemler';

  @override
  String get henuzDuzenliIslemYok => 'Henüz düzenli işlem yok';

  @override
  String get islemEklerkenTekrarSikligi =>
      '+ ile doğrudan şablon oluştur\nya da işlem eklerken tekrar sıklığı seç.';

  @override
  String get bekleyenDuzenliIslemler => 'Bekleyen düzenli işlemler';

  @override
  String get vadesiGelmisIslemlerinizVar =>
      'Zamanı gelmiş işlemlerin var. Onaylarsan deftere yazılır.';

  @override
  String titleTarihDatestrNtutarTx(Object dateStr, Object amount) {
    return 'Tarih: $dateStr\nTutar: $amount';
  }

  @override
  String get ibo => 'İbo';

  @override
  String get uygulamaKilidi => 'Uygulama kilidi';

  @override
  String get pINBiyometrikVeGizlilik => 'PIN, biyometrik ve gizlilik ayarları';

  @override
  String get otomatikHesaplananDegerler => 'Otomatik hesaplanan değerler:';

  @override
  String get borcAlacakYatirimKayitlarindan =>
      'Borç, alacak ve birikim kayıtlarından türetilir; buradan düzenlenemez.';

  @override
  String get renkSecin => 'Renk seç:';

  @override
  String get ikonSecin2 => 'İkon seç:';

  @override
  String get ikonDegistir => 'İkon değiştir';

  @override
  String get cuzdanlarim => 'Cüzdanlarım';

  @override
  String get cuzdanlariniziYonetin => 'Cüzdanlarını yönet';

  @override
  String get yeniCuzdanOlustur => 'Yeni cüzdan oluştur';

  @override
  String get finansalNyolculugunuzBasliyor => 'Finansal\nyolculuğun başlıyor';

  @override
  String get ilkCuzdaniOlustur => 'İlk cüzdanı oluştur';

  @override
  String olusturulmaAppformattersDateshortFormat(Object createdAt) {
    return 'Oluşturulma: $createdAt';
  }

  @override
  String get aktif => 'Aktif';

  @override
  String get aktifOlanCuzdanSilinemez =>
      '• Aktif cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yap.';

  @override
  String get cuzdanlarinizaAitBorcAlacak =>
      '• Cüzdanlarının borç, alacak ve birikim tutarlarını düzenleme sayfasından elle yönetebilirsin.';

  @override
  String get msgPINOrBiometricLogin =>
      'PIN veya biyometrik giriş arka plan kilidi için gereklidir';

  @override
  String get sharedFeatures => 'Paylaşılan Özellikler';

  @override
  String get tarihAraligi => 'Tarih aralığı';

  @override
  String get butonGalerisi => 'Buton Galerisi';

  @override
  String get taksit1 => '1 taksit';

  @override
  String get taksit2 => '2 taksit';

  @override
  String get tamaminiOde => 'Tamamını öde';

  @override
  String get sliderSavings => 'Birikim';

  @override
  String get sliderTransactions => 'İşlemler';

  @override
  String get sliderDebt => 'Borç';

  @override
  String get recurringTransactions => 'Düzenli işlemler';

  @override
  String get budgetPlanning => 'Bütçe';

  @override
  String get drawerBalance => 'Bakiye';

  @override
  String get drawerInvestment => 'Birikim';

  @override
  String get drawerDebt => 'Borç';

  @override
  String get createWallet => 'Cüzdan oluştur';

  @override
  String get selectWallet => 'Cüzdan seç';

  @override
  String get wallet => 'Cüzdan';

  @override
  String get menuGold => 'Altın';

  @override
  String get menuStock => 'Hisse';

  @override
  String get menuCustom => 'Özel';

  @override
  String get menuDetails => 'İçgörü';

  @override
  String get menuIncome => 'Gelir';

  @override
  String get menuExpense => 'Gider';

  @override
  String get menuReport => 'Rapor';

  @override
  String get menuDebt => 'Borç';

  @override
  String get menuReceivable => 'Alacak';

  @override
  String get menuHistory => 'Geçmiş';

  @override
  String get themeSysLight => 'Açık';

  @override
  String get themeSysDark => 'Koyu';

  @override
  String get cuzdanOlusturunuz => 'Bir cüzdan oluştur';

  @override
  String get cuzdanSeciniz => 'Bir cüzdan seç';

  @override
  String get yerelMod => 'Yerel mod';

  @override
  String get henuzCuzdanOlusturmadiniz => 'Henüz cüzdanın yok';

  @override
  String get cuzdanOlusturuldu => 'Cüzdan oluşturuldu';

  @override
  String get cuzdanGuncellendi => 'Cüzdan güncellendi!';

  @override
  String get cuzdanSilindi => 'Cüzdan silindi!';

  @override
  String get cuzdanSecildi => 'Cüzdan seçildi';

  @override
  String get disaAktarilacakIslemBulunamadi =>
      'Dışa aktarılacak işlem bulunamadı.';

  @override
  String get islemlerDisaAktarildi => 'İşlemler başarıyla dışa aktarıldı.';

  @override
  String get csvGecerliIslemBulunamadi =>
      'CSV dosyasında geçerli işlem bulunamadı.';

  @override
  String get iceAktarilanCuzdanPrefix => 'İçe Aktarılan Cüzdan';

  @override
  String get verilerIceAktarildi =>
      'Veriler başarıyla içe aktarıldı. Yeni cüzdan oluşturuldu ve seçildi.';

  @override
  String get cuzdanOlusturulamadi => 'Cüzdan oluşturulamadı';

  @override
  String satirAtlandi(int count) {
    return '$count satır tarih/tutar hatası nedeniyle atlandı.';
  }

  @override
  String get guncelle => 'Güncelle';

  @override
  String get kaydet => 'Kaydet';

  @override
  String get islem => 'İşlem';

  @override
  String get daily => 'Günlük';

  @override
  String get weekly => 'Haftalık';

  @override
  String get monthly => 'Aylık';

  @override
  String get yearly => 'Yıllık';

  @override
  String get kategoriDuzenle => 'Kategori düzenle';

  @override
  String get yeniKategori => 'Yeni kategori';

  @override
  String get kategoriAdiBosOlamaz => 'Kategori adı boş olamaz';

  @override
  String get enAz2KarakterOlmali => 'En az 2 karakter olmalı';

  @override
  String get kategoriOlusturuldu => 'Kategori oluşturuldu!';

  @override
  String get kategoriGuncellendi => 'Kategori güncellendi!';

  @override
  String get kategoriSilindi => 'Kategori silindi!';

  @override
  String get kategoriSilTitle => 'Kategori sil';

  @override
  String kategoriSilConfirmMessage(Object id) {
    return '\"$id\" kategorisini silmek istediğine emin misin?\n\nBu işlem geri alınamaz.';
  }

  @override
  String kategorilerYuklenemedi(Object error) {
    return 'Kategoriler yüklenemedi: $error';
  }

  @override
  String get giderKategorileri => 'Gider kategorileri';

  @override
  String get gelirKategorileri => 'Gelir kategorileri';

  @override
  String get categoryErrorDuplicateName => 'Bu isimde bir kategori zaten var';

  @override
  String get categoryErrorParentNotFound => 'Üst kategori bulunamadı';

  @override
  String get categoryErrorParentIsNotRoot =>
      'Alt kategorinin altına kategori eklenemez';

  @override
  String get categoryErrorTypeMismatch =>
      'Alt kategori, üst kategoriyle aynı türde olmalı';

  @override
  String get categoryErrorSelfParent => 'Kategori kendi üst kategorisi olamaz';

  @override
  String get categoryErrorParentHasChildren =>
      'Alt kategorisi olan bir kategori taşınamaz';

  @override
  String get kategorilerBaslik => 'Kategoriler';

  @override
  String get altKategoriEkle => 'Alt kategori ekle';

  @override
  String get ustKategori => 'Üst kategori';

  @override
  String get ustKategoriYok => 'Ana kategori (üst yok)';

  @override
  String get anaKategoriEtiketi => 'ana kategori';

  @override
  String get henuzKategoriYok => 'Henüz kategori yok';

  @override
  String get oneriSetindenBasla => 'Öneri setinden başla';

  @override
  String get kategoriSilTasiTitle => 'İşlemleri taşı';

  @override
  String kategoriSilTasiMessage(Object name, Object count) {
    return '\"$name\" kategorisinde $count işlem var. Silmeden önce bu işlemler hangi kategoriye taşınsın?';
  }

  @override
  String kategoriSilAltKategorilerDe(Object count) {
    return '$count alt kategorisi de silinecek; onların işlemleri de aynı kategoriye taşınır.';
  }

  @override
  String get kategoriSilHedefYok =>
      'Taşınacak başka kategori yok. Önce yeni bir kategori oluştur.';

  @override
  String dogrudanKategoriSec(Object name) {
    return 'Doğrudan \"$name\"';
  }

  @override
  String get altKategoriSec => 'Alt kategori seç';

  @override
  String get starterPackTitle => 'Kategorilerini kur';

  @override
  String get starterPackSubtitle =>
      'Hazır setten seç; sonra dilediğin gibi düzenle, sil, yenisini ekle. İşlem girebilmek için en az bir kategori gerekir.';

  @override
  String get starterPackSelectAll => 'Tümünü seç';

  @override
  String get starterPackClearAll => 'Seçimi temizle';

  @override
  String get starterPackSkip => 'Şimdilik atla';

  @override
  String starterPackCreate(Object count) {
    return '$count kategori oluştur';
  }

  @override
  String starterPackCreated(Object count) {
    return '$count kategori oluşturuldu';
  }

  @override
  String starterPackChildCount(Object count) {
    return '$count alt kategori';
  }

  @override
  String butceUstKategorideVar(Object name) {
    return '\"$name\" üst kategorisinde bütçe var';
  }

  @override
  String get butceAltKategorideVar => 'Alt kategorilerinde bütçe var';

  @override
  String get duzenleSubtitle => 'Tutar, tarih, kategori ve diğer detaylar';

  @override
  String get islemiSil => 'İşlemi sil';

  @override
  String islemSilOnayMesaji(String baslik) {
    return '$baslik işlemini silmek istediğine emin misin? Cüzdan bakiyesine etkisi de geri alınır.';
  }

  @override
  String get silSubtitle => 'Bakiye eski haline döner';

  @override
  String get gramAltin => 'Gram Altın';

  @override
  String get ceyrekAltin => 'Çeyrek Altın';

  @override
  String get yarimAltin => 'Yarım Altın';

  @override
  String get tamAltin => 'Tam Altın';

  @override
  String get cumhuriyetAltini => 'Cumhuriyet Altını';

  @override
  String get ataAltin => 'Ata Altın';

  @override
  String get fiyatAliniyor => 'Fiyat alınıyor...';

  @override
  String get fiyatAlinamadi => 'Fiyat alınamadı.';

  @override
  String guncelFiyatFormat(Object price) {
    return 'Güncel Fiyat: $price';
  }

  @override
  String guncelFiyatFormatCevrimli(Object price, Object converted) {
    return 'Güncel Fiyat: $price (≈$converted)';
  }

  @override
  String get gecerliYatirimMiktariGirin => 'Geçerli bir miktar gir';

  @override
  String get gecerliMevcutDegerGirin => 'Geçerli bir mevcut değer gir';

  @override
  String get altinYatirimi => 'Altın';

  @override
  String get altinTuruVeOtomatikFiyat => 'Altın türü ve güncel fiyat';

  @override
  String get yatirimDetaylari => 'Ayrıntılar';

  @override
  String get altinNotHint => 'Not (İsteğe bağlı) · örn. Düğün Altınları';

  @override
  String get maliyetYatirilanAnaPara => 'Maliyet (ödediğin tutar)';

  @override
  String get hedefTutarIstegeBagli => 'Hedef tutar (isteğe bağlı)';

  @override
  String get hedefKategorisi => 'Hedef kategorisi';

  @override
  String get renkSecimi => 'Renk seçimi';

  @override
  String get altinYatiriminiDuzenle => 'Altını düzenle';

  @override
  String get yeniAltinEkle => 'Yeni altın ekle';

  @override
  String get adet => 'Adet';

  @override
  String get sembolGirin => 'Sembol gir';

  @override
  String get hisseYatirimi => 'Hisse';

  @override
  String get hisseSenediBul => 'Hisse senedi bul';

  @override
  String get hisseNotHint => 'Not (İsteğe bağlı) · örn. Uzun vade alım';

  @override
  String get hisseYatiriminiDuzenle => 'Hisseyi düzenle';

  @override
  String get yeniHisseEkle => 'Yeni hisse ekle';

  @override
  String get gecerliHedefTutarGirin => 'Geçerli bir hedef tutar gir';

  @override
  String get ozelYatirimi => 'Özel varlık';

  @override
  String get customNotHint => 'Not (İsteğe bağlı) · örn. Arsa, Kripto, Döviz';

  @override
  String get ozelYatiriminiDuzenle => 'Özel varlığı düzenle';

  @override
  String get yeniOzelYatirimEkle => 'Yeni özel varlık';

  @override
  String get varlikEkle => 'Varlık ekle';

  @override
  String get hedefeParaEkle => 'Hedefe para ekle';

  @override
  String get paraEkle => 'Para ekle';

  @override
  String get yeniAlimMiktarVeOdenenTutar => 'Yeni alım: miktar ve ödenen tutar';

  @override
  String get maliyeteVeDegereEklenir =>
      'Maliyete ve değere eklenir, cüzdandan düşer';

  @override
  String get fiyatiGuncelle => 'Fiyatı güncelle';

  @override
  String get canliFiyatGuncellemeAciklamasi =>
      'Güncel değer = miktar × canlı fiyat; bakiyeyi etkilemez';

  @override
  String get duzenleYatirimSubtitle => 'İsim, maliyet, hedef ve diğer detaylar';

  @override
  String get satSubtitle => 'Güncel değer cüzdana gelir olarak işlenir';

  @override
  String get kaydiSilSubtitle =>
      'Hatalı giriş düzeltme; alım gideri iade edilir';

  @override
  String varlikEkleTitle(Object name) {
    return '$name · Varlık ekle';
  }

  @override
  String paraEkleTitle(Object name) {
    return '$name · Para ekle';
  }

  @override
  String get alinanMiktarAltinHint => 'Alınan miktar (örn. gram/adet)';

  @override
  String get alinanAdetHisseHint => 'Alınan adet (lot)';

  @override
  String get odenenTutarHint => 'Ödenen tutar · hediye ise 0';

  @override
  String get tutarHint => 'Tutar';

  @override
  String get gecerliMiktarGirin => 'Geçerli bir miktar gir';

  @override
  String get gecerliOdenenTutarGirin => 'Geçerli bir ödenen tutar gir';

  @override
  String get gecerliTutarGirin => 'Geçerli bir tutar gir';

  @override
  String get baslikGirin => 'Başlık gir';

  @override
  String get borcluKisiAdiGirin => 'Borçlu kişinin adını gir';

  @override
  String get kurumKisiGirin => 'Kurum ya da kişi gir';

  @override
  String get aylikTaksitTutariniGirin => 'Aylık taksit tutarını gir';

  @override
  String get aylikTaksitKrediTutarindanKucuk =>
      'Aylık taksit × vade, kredi tutarından küçük olamaz';

  @override
  String get krediHesaplamaInfoBaslik => 'Banka kredisi hesaplaması';

  @override
  String get krediHesaplamaInfoGovde =>
      '• Aylık taksiti biliyorum: Bankanın söylediği aylık taksiti yaz. Toplam geri ödeme = aylık taksit × vade. Kolaylık için alan, faizsiz bir başlangıç olarak kredi tutarı ÷ vade değerini önerir; kendi taksitine göre değiştir.\n\n• Faiz oranı ile: Bankanın aylık faiz oranını yaz. Taksit ve toplam, eşit taksitli kredi (amortisman) yöntemiyle hesaplanır.';

  @override
  String get borcTuruLabel => 'Borç türü';

  @override
  String get borcBaslikHint => 'Başlık (isteğe bağlı)';

  @override
  String get kurumKisiHint => 'Kurum / Kişi · örn. Ziraat Bankası';

  @override
  String get kisiAdiHint => 'Kişi adı';

  @override
  String get vadeVeDetaylarLabel => 'Vade & detaylar';

  @override
  String get borcluKisiAdiHint => 'Borçlu kişi adı';

  @override
  String get borcDuzenleTitle => 'Borç düzenle';

  @override
  String get alacakDuzenleTitle => 'Alacak düzenle';

  @override
  String get yeniBorcTitle => 'Yeni borç';

  @override
  String get yeniAlacakTitle => 'Yeni alacak';

  @override
  String get krediTutariAnaPara => 'Kredi tutarı (ana para)';

  @override
  String get borcTutariAnaPara => 'Borç tutarı (ana para)';

  @override
  String get alacakTutari => 'Alacak tutarı';

  @override
  String get toplamTutar => 'Toplam tutar';

  @override
  String get vadeFarkiLabel => 'Vade farkı';

  @override
  String get toplamFaizLabel => 'Toplam faiz';

  @override
  String get aylikTaksitLabel => 'Aylık taksit (≈)';

  @override
  String get debtTypeBankLoan => 'Banka kredisi';

  @override
  String get debtTypeInstallment => 'Taksitli';

  @override
  String get debtTypePersonal => 'Kişisel';

  @override
  String get debtTypeOther => 'Diğer';

  @override
  String get vadeAyHint => 'Vade (ay)';

  @override
  String get aylikTaksitHint => 'Aylık taksit';

  @override
  String get vadeFarkiYuzdeHint => 'Vade farkı %';

  @override
  String get aylikFaizYuzdeHint => 'Aylık faiz %';

  @override
  String get gecikmeFaiziYuzdeHint => 'Gecikme faizi (%)';

  @override
  String get baslangicLabel => 'Başlangıç';

  @override
  String get vadeLabel => 'Vade';

  @override
  String get toplamBorcLabel => 'Toplam borç:';

  @override
  String get odenenLabel => 'Ödenen:';

  @override
  String get kalanLabel => 'Kalan:';

  @override
  String get kalanTutardanFazlaOlamaz => 'Kalan tutardan fazla olamaz';

  @override
  String taksitPlaniFormat(Object months) {
    return 'Taksit planı ($months ay)';
  }

  @override
  String odemeGecmisiFormat(Object count) {
    return 'Ödeme geçmişi ($count)';
  }

  @override
  String get gecikmis => 'Gecikmiş';

  @override
  String get bekleniyor => 'Bekleniyor';

  @override
  String get cuzdanDuzenleTitle => 'Cüzdanı düzenle';

  @override
  String get yeniCuzdanEkleTitle => 'Yeni cüzdan ekle';

  @override
  String get cuzdanAdiBosOlamaz => 'Cüzdan adı boş olamaz';

  @override
  String get cuzdanAdiEnAz2Karakter => 'Cüzdan adı en az 2 karakter olmalı';

  @override
  String get bakiyeLabel => 'Bakiye *';

  @override
  String get baslangicBakiyesiLabel => 'Başlangıç bakiyesi *';

  @override
  String get bakiyeBosOlamaz => 'Bakiye boş olamaz';

  @override
  String get gecerliBirSayiGirin => 'Geçerli bir sayı gir';

  @override
  String get tutarCokBuyuk => 'Tutar çok büyük';

  @override
  String get borcLabel => 'Borç';

  @override
  String get alacakLabel => 'Alacak';

  @override
  String get birikimLabel => 'Birikim';

  @override
  String get olustur => 'Oluştur';

  @override
  String get ozelRenkSecin => 'Özel renk seç';

  @override
  String get cuzdanYonetimiTitle => 'Cüzdan yönetimi';

  @override
  String get infoTransferDesc =>
      'Cüzdanların arasında para taşıyabilirsin. Tutar, kur farkı gözetilerek kaynak cüzdandan düşülür ve hedefe eklenir.';

  @override
  String get infoBankImportDesc =>
      'Bankanın uygulamasından aldığın hesap hareketlerini içe aktararak kayıtlarını hızlıca doldurabilirsin.';

  @override
  String get categoryFinans => 'Finans';

  @override
  String get categoryGrafikler => 'Grafikler';

  @override
  String get categoryIsVeOfis => 'İş ve ofis';

  @override
  String get categoryAlisveris => 'Alışveriş';

  @override
  String get categoryYemekVeIcecek => 'Yemek ve içecek';

  @override
  String get categoryUlasim => 'Ulaşım';

  @override
  String get categoryEvVeYasam => 'Ev ve yaşam';

  @override
  String get categoryEglence => 'Eğlence';

  @override
  String get categorySaglikVeSpor => 'Sağlık ve spor';

  @override
  String get categoryEgitim => 'Eğitim';

  @override
  String get categoryKisiselBakim => 'Kişisel bakım';

  @override
  String get categoryHayvanlar => 'Hayvanlar';

  @override
  String get categorySeyahat => 'Seyahat';

  @override
  String get categoryTeknoloji => 'Teknoloji';

  @override
  String get categoryIletisim => 'İletişim';

  @override
  String get categoryHediyeVeBagis => 'Hediye ve bağış';

  @override
  String get categoryHizmetler => 'Hizmetler';

  @override
  String get categoryDiger => 'Diğer';

  @override
  String get systemTagDebt => 'Borç';

  @override
  String get systemTagDebtPayment => 'Borç ödemesi';

  @override
  String get systemTagReceivable => 'Alacak';

  @override
  String get systemTagReceivableCollection => 'Alacak tahsilatı';

  @override
  String get systemTagInvestmentBuy => 'Birikim alımı';

  @override
  String get systemTagInvestmentSell => 'Birikim satışı';

  @override
  String get systemTagInvestmentCorrection => 'Birikim düzeltmesi';

  @override
  String get systemTagTransfer => 'Transfer';

  @override
  String get kategorisiz => 'Kategorisiz';

  @override
  String get detailLabelTarih => 'Tarih';

  @override
  String get detailLabelSaat => 'Saat';

  @override
  String get detailLabelTur => 'Tür';

  @override
  String get detailLabelGelir => 'Gelir';

  @override
  String get detailLabelGider => 'Gider';

  @override
  String get detailLabelIslemSonrasiBakiye => 'İşlem sonrası bakiye';

  @override
  String get akilliIcgoruler => 'Akıllı içgörüler';

  @override
  String get gunlukOrtalamaHarcama => 'Günlük ortalama harcama';

  @override
  String get enCokHarcananGun => 'En çok harcadığın gün';

  @override
  String get enCokHarcananKategori => 'En çok harcanan kategori';

  @override
  String get enBuyukHarcama => 'En büyük harcama';

  @override
  String get birikimOrani => 'Birikim oranı';

  @override
  String get buDonemdeIslemYok => 'Bu dönemde işlem yok';

  @override
  String get tekrarlayanOdemeler => 'Tekrarlayan ödemeler';

  @override
  String tekrarlayanTespitOzeti(int count) {
    return '$count olası düzenli ödeme tespit ettik';
  }

  @override
  String kezTekrarlandi(int count) {
    return '$count kez tekrarlandı';
  }

  @override
  String get duzenliOdemeOlarakEkle => 'Düzenli ödeme olarak ekle';

  @override
  String duzenliOdemeEklendi(String title) {
    return '\'$title\' düzenli ödemelere eklendi';
  }

  @override
  String get duzenliOdemeEklenemedi => 'Düzenli ödeme eklenemedi';

  @override
  String get borcNakitEtkiBaslik => 'Bu borç karşılığında ne aldın?';

  @override
  String get borcNakitEtkiAciklama =>
      'Seçimine göre cüzdan bakiyen otomatik güncellenir; ayrıca elle işlem eklemen gerekmez.';

  @override
  String get borcNakitSecenekBaslik => 'Nakit aldım';

  @override
  String borcNakitSecenekGovde(String tutar) {
    return '$tutar cüzdan bakiyene gelir olarak eklenir. Yaptığın geri ödemeler bakiyeden gider olarak düşülür.';
  }

  @override
  String get borcUrunSecenekBaslik => 'Ürün / hizmet aldım';

  @override
  String get borcUrunSecenekGovde =>
      'Para eline geçmediği için bakiyen değişmez. Taksit ve geri ödemelerin bakiyeden gider olarak düşülür.';

  @override
  String get devamEt => 'Devam et';

  @override
  String get bugun => 'Bugün';

  @override
  String get islemBuguneAyarliIpucu =>
      'Tarih bugüne ayarlı — başka bir güne eklemek için tarihe dokun.';

  @override
  String get mevcutDegerAciklama =>
      'Varlığın bugünkü piyasa değeri; \'Hesapla\' ile güncel fiyattan güncellenir.';

  @override
  String get toplamMaliyetAciklama =>
      'Bu varlığa ödediğin toplam tutar. \'Hesapla\' bunu değiştirmez; kâr/zarar bununla hesaplanır.';

  @override
  String get paraBirimiLabel => 'Para birimi';

  @override
  String get paraBirimiKilitliHint =>
      'İşlem geçmişi olan cüzdanın para birimi değiştirilemez';

  @override
  String yaklasikKarsilikFormat(String tutar) {
    return '≈ $tutar';
  }

  @override
  String toplamTlKarsilikFormat(String tutar) {
    return 'Toplam ≈ $tutar';
  }

  @override
  String get cuzdanlarArasiTransfer => 'Cüzdanlar arası transfer';

  @override
  String get transferEt => 'Transfer et';

  @override
  String get transferHedefCuzdan => 'Hedef cüzdan';

  @override
  String transferOnizlemeFormat(String tutar) {
    return 'Hedefe ≈ $tutar geçecek';
  }

  @override
  String get transferKurAliniyor => 'Kur alınıyor…';

  @override
  String get transferKurYok =>
      'Kur bilgisi alınamadı — internete bağlanınca tekrar dene';

  @override
  String get transferBasarili => 'Transfer tamamlandı';

  @override
  String get transferBasarisiz => 'Transfer başarısız oldu';

  @override
  String get transferIadeBasarisiz =>
      'Transfer tamamlanamadı ve iade de yazılamadı. Cüzdan defterini kontrol et.';

  @override
  String get transferGeriAlindi => 'Transfer geri alındı';

  @override
  String get transferGeriAlinamadi => 'Transfer geri alınamadı';

  @override
  String get transferTarih => 'Transfer tarihi';

  @override
  String get transferIcinIkiCuzdanGerekli =>
      'Transfer için en az iki cüzdan gerekli';

  @override
  String transferBakiyeAsimiMesaj(String bakiye) {
    return 'Tutar, cüzdan bakiyesinden ($bakiye) fazla. Devam edersen bakiye eksiye düşer. Devam edilsin mi?';
  }

  @override
  String get yardimVeTurlar => 'Yardım';

  @override
  String get genelTanitimiTekrarGoster => 'Gizlilik ve bildirim notunu göster';

  @override
  String get uygulamaTuruTekrarGoster => 'Tanıtımları tekrar göster';

  @override
  String get onboardingNavHintHeader => 'Nasıl gezinilir?';

  @override
  String get onboardingNavHintSwipeTitle => 'Sağa ya da sola kaydır';

  @override
  String get onboardingNavHintSwipeDesc => 'Bölümler arasında geç.';

  @override
  String get onboardingNavHintDragTitle => 'Yukarı sürükle';

  @override
  String get onboardingNavHintDragDesc =>
      'İçgörü, Rapor ve Geçmiş sayfalarına geç.';

  @override
  String get onboardingNavHintAddTitle => 'Düğmeye dokun';

  @override
  String get onboardingNavHintAddDesc =>
      'Yeni kayıt ekle: gelir, gider, birikim, borç ya da alacak.';

  @override
  String get notificationSettings => 'Bildirimler';

  @override
  String get notificationSettingsDesc =>
      'Hatırlatmaları ve günlük bildirim sıklığını yönet.';

  @override
  String get randomReminders => 'Motive edici hatırlatıcılar';

  @override
  String get randomRemindersOff => 'Kapalı';

  @override
  String get randomRemindersLow => 'Az (günde 1)';

  @override
  String get randomRemindersMedium => 'Orta (günde 2)';

  @override
  String get randomRemindersHigh => 'Çok (günde 3)';

  @override
  String get criticalNotifications => 'Kritik bildirimler';

  @override
  String get debtReminders => 'Borç/alacak hatırlatıcıları';

  @override
  String get recurringReminders => 'Düzenli işlem hatırlatıcıları';

  @override
  String get budgetAlerts => 'Bütçe uyarıları';

  @override
  String get notificationRationaleTitle => 'Bildirimler';

  @override
  String get notificationRationaleBody =>
      'ÇuHat, borcunun ya da alacağının vadesi yaklaşınca ve düzenli işlemlerin onay beklerken sana hatırlatma gönderebilir. Bunun için bildirim izni gerekir. İzin vermesen de uygulamayı kullanabilirsin; yalnız hatırlatma gelmez.';

  @override
  String get notificationRationaleLater => 'Şimdi değil';

  @override
  String get notificationPermissionOffTitle => 'Bildirim izni kapalı';

  @override
  String get notificationPermissionOffDesc =>
      'Aşağıdaki hatırlatmalar ancak sistem izni verildiğinde ulaşabilir.';

  @override
  String get notificationPermissionGrant => 'İzin ver';

  @override
  String get notificationPermissionOpenSettings =>
      'İzin daha önce reddedildiği için sistem bir daha sormuyor. Bildirimleri sistem ayarlarından açabilirsin.';

  @override
  String get notificationPermissionOpenSettingsAction => 'Ayarları aç';

  @override
  String get notificationSendTest => 'Test bildirimi gönder';

  @override
  String get notificationTestSent => 'Test bildirimi gönderildi';

  @override
  String get notificationTestFailedNoPermission =>
      'Test bildirimi gönderilemedi: bildirim izni kapalı';

  @override
  String get notificationTestFailed => 'Test bildirimi gönderilemedi';

  @override
  String notificationTestFailedChannelBlocked(Object channel) {
    return '\"$channel\" bildirimleri sistem ayarlarından kapatılmış. Uygulama izni açık ama bu tür bildirim gösterilmiyor.';
  }

  @override
  String get notificationTestFailedNotDelivered =>
      'Bildirim sisteme iletildi ama gösterilmedi. Pil optimizasyonu ya da üretici kısıtlaması engelliyor olabilir.';

  @override
  String notificationTestFailedPlatform(Object detail) {
    return 'Bildirim gönderilemedi: $detail';
  }

  @override
  String get notificationDiagnosticsTitle => 'Bildirim tanılama';

  @override
  String get notificationDiagnosticsSubtitle =>
      'Bildirim gelmiyorsa nedenini burada gör';

  @override
  String get notificationDiagnosticsIntro =>
      'Aşağıdaki satırlar bildirimlerin şu anki durumunu gösterir. Bir şey kapalıysa bildirimler o yüzden ulaşmıyor demektir.';

  @override
  String get notificationDiagnosticsAppPermission => 'Uygulama bildirim izni';

  @override
  String get notificationDiagnosticsChannelsTitle => 'Bildirim türleri';

  @override
  String get notificationDiagnosticsExactAlarms => 'Tam zamanlı alarm izni';

  @override
  String get notificationDiagnosticsExactAlarmsHint =>
      'Bu izin olmadan hatırlatmalar dakikasında değil, sistemin uygun gördüğü ilk anda gelir. Bilinçli bir tercih.';

  @override
  String get notificationDiagnosticsTimeZone => 'Saat dilimi';

  @override
  String get notificationDiagnosticsTimeZoneHint =>
      'Saat dilimi okunamadı; tekrarlayan hatırlatmalar bir saat kayabilir.';

  @override
  String get notificationDiagnosticsPending => 'Planlanmış hatırlatma';

  @override
  String notificationDiagnosticsPendingCount(Object count) {
    return '$count adet';
  }

  @override
  String get notificationDiagnosticsPendingNone =>
      'Yok — hiçbir hatırlatma kurulu değil';

  @override
  String get notificationDiagnosticsNext => 'Sıradaki hatırlatma';

  @override
  String get notificationDiagnosticsNextUnknown => 'Bu oturumda kurulan yok';

  @override
  String get notificationDiagnosticsLastError => 'Son hata';

  @override
  String get notificationDiagnosticsNoError => 'Yok';

  @override
  String get notificationDiagnosticsRefresh => 'Yenile';

  @override
  String get notificationDiagnosticsBatteryTitle =>
      'Bildirimler yine de gelmiyorsa';

  @override
  String get notificationDiagnosticsBatteryBody =>
      'Telefonun pil ayarlarından ÇuHat\'ı kısıtlamadan çıkarın. Bazı üreticiler (Xiaomi, Samsung, Huawei, Oppo) arka plandaki uygulamaların alarmlarını varsayılan olarak durdurur.';

  @override
  String get notificationDiagnosticsOn => 'Açık';

  @override
  String get notificationDiagnosticsOff => 'Kapalı';

  @override
  String notificationScheduleHint(Object times) {
    return 'Hatırlatmalar her gün aynı saatlerde gelir: $times';
  }

  @override
  String get notificationTestTitle => 'ÇuHat test bildirimi';

  @override
  String get notificationTestBody =>
      'Bildirimler çalışıyor. Hatırlatmaların böyle görünecek.';

  @override
  String get notifChannelCriticalName => 'Kritik hatırlatmalar';

  @override
  String get notifChannelCriticalDesc => 'Borç vadeleri ve bütçe aşımları';

  @override
  String get notifChannelRecurringName => 'Düzenli işlemler';

  @override
  String get notifChannelRecurringDesc =>
      'Onay bekleyen düzenli işlem hatırlatmaları';

  @override
  String get notifChannelMotivationalName => 'Motive edici hatırlatıcılar';

  @override
  String get notifChannelMotivationalDesc =>
      'Harcama girmeyi hatırlatan günlük mesajlar';

  @override
  String get notifRecurringDueTitle => 'Düzenli işlem vakti';

  @override
  String notifRecurringDueBody(Object title) {
    return '$title onayını bekliyor.';
  }

  @override
  String get notifDebtUpcomingTitle => 'Borç hatırlatması';

  @override
  String notifDebtUpcomingBody(Object title) {
    return '$title borcunun sıradaki taksit günü yaklaştı.';
  }

  @override
  String get notifDebtDueTitle => 'Borcun son ödeme günü';

  @override
  String notifDebtDueBody(Object title) {
    return '$title borcunun sıradaki taksiti bugün.';
  }

  @override
  String get notifBudgetWarningTitle => 'Bütçe uyarısı';

  @override
  String notifBudgetWarningBody(Object category) {
    return '$category bütçenin %80\'ine ulaştın.';
  }

  @override
  String get notifBudgetExceededTitle => 'Bütçe aşıldı';

  @override
  String notifBudgetExceededBody(Object category) {
    return '$category bütçeni aştın.';
  }

  @override
  String get notifBudgetFilledTitle => 'Bütçe doldu';

  @override
  String notifBudgetFilledBody(Object category) {
    return '$category bütçenin tamamını kullandın (%100).';
  }

  @override
  String get notifDailyReminderTitle => 'ÇuHat';

  @override
  String get notifDailyReminder1 =>
      'Bugün hiç harcama girdin mi? Bütçeni güncel tut!';

  @override
  String get notifDailyReminder2 => 'Finansal durumunu kontrol etme vakti!';

  @override
  String get notifDailyReminder3 =>
      'Gelir ve giderlerini takip etmek bütçeni korur.';

  @override
  String get notifDailyReminder4 =>
      'Küçük birikimler büyük hedeflere ulaştırır!';

  @override
  String get notifDailyReminder5 => 'Harcamalarını gözden geçirmeyi unutma.';

  @override
  String get notifDailyReminder6 => 'Bütçeni planla, rahat yaşa!';

  @override
  String recurringNudgeCount(Object count) {
    return '$count işlem onay bekliyor';
  }

  @override
  String recurringNudgeOldest(Object days) {
    return 'En eskisi $days gün gecikmiş';
  }

  @override
  String get sonra => 'Sonra';

  @override
  String get incele => 'İncele';

  @override
  String get onayBekleyenler => 'Onay bekleyenler';

  @override
  String get sablonlar => 'Şablonlar';

  @override
  String get yaklasanlar => 'Yaklaşanlar';

  @override
  String get duraklatilmislar => 'Duraklatılmış';

  @override
  String get duraklatildi => 'Duraklatıldı';

  @override
  String get onayBekleyenYok => 'Onay bekleyen işlem yok.';

  @override
  String get aylikDuzenliGider => 'Aylık düzenli gider';

  @override
  String get aylikDuzenliGelir => 'Aylık düzenli gelir';

  @override
  String aktifSablonSayisi(Object count) {
    return '$count aktif şablon';
  }

  @override
  String get yarin => 'Yarın';

  @override
  String gunSonra(Object days) {
    return '$days gün sonra';
  }

  @override
  String bekleyenVadeSayisi(Object count) {
    return '$count vade birikmiş';
  }

  @override
  String get tumunuOnayla => 'Tümünü onayla';

  @override
  String get tumunuOnaylaBaslik => 'Birikmiş vadeleri onayla';

  @override
  String tumunuOnaylaAciklama(Object title, Object count) {
    return '\"$title\" için birikmiş $count vadenin tümü deftere işlenecek.';
  }

  @override
  String get buVadeyiAtla => 'Bu vadeyi atla';

  @override
  String get sablonuSilAciklama => 'Şablonu sil (gelecek vadeler de dahil)';

  @override
  String get fisEkle => 'Fiş/fotoğraf ekle';

  @override
  String get fisEkli => 'Fiş eklendi';

  @override
  String get fisKamera => 'Kamera';

  @override
  String get fisGaleri => 'Galeri';

  @override
  String get fisDegistir => 'Değiştir';

  @override
  String get fisKaldir => 'Kaldır';

  @override
  String get fisGoruntule => 'Fişi görüntüle';

  @override
  String get fisOcrTaraniyor => 'Fiş taranıyor…';

  @override
  String get fisOcrDolduruldu => 'Bilgiler fişten dolduruldu — kontrol et';

  @override
  String get fisCihazdaYok => 'Görsel bu cihazda yok';

  @override
  String get bankImportSettingsEntry => 'Banka ekstresi içe aktar';

  @override
  String get bankImportSettingsSubtitle =>
      'CSV/Excel/PDF ekstresini işlemlere dönüştür';

  @override
  String get bankImportTitle => 'Banka ekstresi içe aktar';

  @override
  String get bankImportParsing => 'Dosya taranıyor…';

  @override
  String get bankImportNoWallet => 'Önce bir cüzdan oluştur.';

  @override
  String get bankImportSetupHint =>
      'Bankandan dışa aktardığın hesap hareketleri dosyasını (CSV, Excel ya da PDF) seç; biçimi otomatik algılarız. Hareketler tarih/tutar/kategori otomatik algılanmış olarak önce incelemene sunulur — bu algılama hatalı olabilir, onaylamadan önce mutlaka kontrol et.';

  @override
  String get bankImportTargetWallet => 'Hedef cüzdan';

  @override
  String get bankImportPickFile => 'Dosya seç ve tara';

  @override
  String get bankImportCommitting => 'Ekleniyor…';

  @override
  String get bankImportClose => 'Kapat';

  @override
  String get bankImportRetry => 'Tekrar dene';

  @override
  String get bankImportContinue => 'Devam';

  @override
  String bankImportColumnN(int n) {
    return '$n. sütun';
  }

  @override
  String get bankImportRoleDate => 'Tarih';

  @override
  String get bankImportRoleDesc => 'Açıklama';

  @override
  String get bankImportRoleBalance => 'Bakiye';

  @override
  String get bankImportEditDescTitle => 'Açıklamayı düzenle';

  @override
  String get bankImportEditDescLabel => 'Açıklama';

  @override
  String get bankImportEditAmountTitle => 'Tutarı düzenle';

  @override
  String get bankImportEditAmountLabel => 'Tutar';

  @override
  String get bankImportFilterAll => 'Tümü';

  @override
  String get bankImportFilterUncategorized => 'Kategorisiz';

  @override
  String get bankImportFilterDuplicates => 'Olası tekrar';

  @override
  String get bankImportSearchHint => 'Açıklamada ara';

  @override
  String get bankImportNoMatch => 'Filtreye uyan hareket yok.';

  @override
  String bankImportShownOf(int shown, int total) {
    return '$shown / $total gösteriliyor';
  }

  @override
  String bankImportWarnings(int count) {
    return 'Uyarılar ($count)';
  }

  @override
  String get bankImportStatRows => 'hareket';

  @override
  String get bankImportStatDuplicates => 'olası tekrar';

  @override
  String get bankImportStatSkipped => 'atlanan satır';

  @override
  String get bankImportStatUncategorized => 'kategorisiz';

  @override
  String bankImportSelectedOf(int selected, int total) {
    return '$selected / $total seçili';
  }

  @override
  String get bankImportNoRows => 'İçe aktarılacak hareket bulunamadı.';

  @override
  String get bankImportSelectAll => 'Tümü';

  @override
  String get bankImportDeselectAll => 'Hiçbiri';

  @override
  String get bankImportStepperMode => 'Tek tek incele';

  @override
  String get bankImportStepSkip => 'Atla';

  @override
  String get bankImportStepAdd => 'Ekle';

  @override
  String get bankImportStepAddRest => 'Kalanları ekle';

  @override
  String get bankImportStepCancelAll => 'Tümünü iptal';

  @override
  String get bankImportShowRaw => 'Ham metni göster';

  @override
  String get bankImportPdfRawTitle => 'PDF metni tanınamadı';

  @override
  String get bankImportPdfRawHint =>
      'Metni çıkardık ama hareket satırlarını tanıyamadık. Aşağıdaki metni kopyalayıp paylaş; ayrıştırıcı bankanın düzenine göre ayarlanacak.';

  @override
  String get bankImportScannedPdfTitle => 'Bu PDF taranmış bir görüntü';

  @override
  String get bankImportScannedPdfHint =>
      'Dosyanın içinde metin yok, yalnızca fotoğraf/tarama var. Görüntüden okumayı denedik ama hareket satırı çıkaramadık. Bankanın internet şubesinden ekstreyi Excel (.xls/.xlsx) ya da CSV olarak indirirsen çok daha isabetli sonuç alırsın.';

  @override
  String get bankImportOcrWarning =>
      'Bu hareketler bir görüntüden okundu. Görüntü tanımada rakamlar sık karışır (virgül/nokta, 1/7, 0/O) ve doğrulayacak bakiye sütunu genelde yoktur — eklemeden önce her tutarı tek tek kontrol et.';

  @override
  String get bankImportPickAnother => 'Başka dosya seç';

  @override
  String get bankImportSharedSetupHint =>
      'Paylaştığın ekstre alındı. Hedef cüzdanı seçip taramayı başlat — hiçbir hareket eklenmeden önce hepsini incelemene sunacağız.';

  @override
  String get bankImportSharedFileTitle => 'Paylaşılan dosya';

  @override
  String get bankImportSharedImport => 'Bu dosyayı tara';

  @override
  String get bankImportLegacyExcelTitle => 'Excel dosyası açılamadı';

  @override
  String bankImportLegacyExcelHint(String reason) {
    return '$reason\n\nBankandan ekstreyi .xlsx ya da CSV olarak indir; ya da dosyayı Excel/Google E-Tablolar\'da açıp .xlsx olarak kaydet.';
  }

  @override
  String get bankImportSourceTruncated =>
      'Excel dosyası beklenen kapanışla bitmiyor; eksik indirilmiş olabilir. Bazı hareketler hiç okunmamış olabilir — satır sayısını bankadaki ekstreyle karşılaştır.';

  @override
  String bankImportSourceUnresolved(int count) {
    return '$count hücrenin değeri okunamadı; o satırlarda boş görünen alanlar aslında dolu olabilir.';
  }

  @override
  String get bankImportUnsupportedTitle => 'Desteklenmeyen dosya';

  @override
  String bankImportUnsupportedHint(String formats) {
    return 'Bu dosyanın biçimi tanınamadı. Desteklenen biçimler: $formats';
  }

  @override
  String get bankImportCopy => 'Kopyala';

  @override
  String get bankImportCopied => 'Kopyalandı';

  @override
  String bankImportSummary(int count, int dup, int skipped, int uncategorized) {
    return '$count hareket · $dup olası tekrar · $skipped satır atlandı · $uncategorized kategorisiz';
  }

  @override
  String bankImportAdd(int count) {
    return 'Seçilenleri ekle ($count)';
  }

  @override
  String bankImportDoneMsg(int added, int skipped) {
    return '$added işlem eklendi, $skipped atlandı.';
  }

  @override
  String get bankImportReconcileMatched =>
      'Bakiye ile doğrulandı: işlemlerin gider/gelir yönü bankanın bakiye sütunuyla eşleşiyor.';

  @override
  String get bankImportVerified => 'Aritmetik olarak doğrulandı';

  @override
  String get bankImportVerifiedHint =>
      'Okunan tutarlar ekstrenin kendi bakiye/toplam bilgileriyle birebir tutuyor.';

  @override
  String get bankImportVerifyFailed => 'Doğrulanamadı';

  @override
  String get bankImportVerifyFailedHint =>
      'Ekstrenin kendi bilgileriyle tutmayan kontroller var; aktarmadan önce tutarları gözden geçir.';

  @override
  String get bankImportCheckBalanceChain => 'Bakiye zinciri';

  @override
  String get bankImportCheckRecordCount => 'Kayıt sayısı';

  @override
  String get bankImportCheckOpeningBalance => 'Devreden bakiye';

  @override
  String get bankImportCheckClosingBalance => 'Kapanış bakiyesi';

  @override
  String get bankImportCheckTotals => 'Borç/Alacak toplamı';

  @override
  String bankImportReconcileMismatch(int count) {
    return 'Bakiye uyuşmadı: $count satırda bakiye ile tutar tutmuyor. Ekstre eksik/hatalı okunmuş olabilir; işaretleri kontrol et.';
  }

  @override
  String bankImportCurrencyMismatch(String statement, String wallet) {
    return 'Ekstre $statement para biriminde görünüyor ama hedef cüzdan $wallet. Tutarlar dönüştürülmez; doğru cüzdana aktardığından emin ol.';
  }

  @override
  String get bankImportUndo => 'İçe aktarımı geri al';

  @override
  String get bankImportBatchTypeLabel => 'Tümünü çevir:';

  @override
  String get bankImportSetAllExpense => 'Gider';

  @override
  String get bankImportSetAllIncome => 'Gelir';

  @override
  String get bankImportReviewWarning =>
      'Tarih, tutar ve kategoriler dosyadan otomatik algılandı; hatalı olabilir. Eklemeden önce her hareketi kontrol et.';

  @override
  String get bankImportDoneBalanceLabel => 'Güncel cüzdan bakiyesi';

  @override
  String get bankImportDoneBalanceHint =>
      'Bu bakiye, içe aktarılan hareketler dahil hesaplandı. Banka hesabındaki güncel bakiyeyle karşılaştır; farklıysa aşağıdan eşitleyebilirsin.';

  @override
  String get bankImportSyncButton => 'Bakiyeyi eşitle';

  @override
  String get bankImportSyncDialogTitle => 'Bakiyeyi eşitle';

  @override
  String get bankImportSyncDialogHint =>
      'Bankandaki gerçek güncel bakiyeni gir; cüzdanın buna göre ayarlanır. Geçmiş hareketlerin değişmez, yalnızca başlangıç bakiyesi düzeltilir.';

  @override
  String get bankImportSyncDialogLabel => 'Gerçek bakiye';

  @override
  String get bankImportCategorySuggestionTitle => 'Yeni kategori önerileri';

  @override
  String get bankImportCategorySuggestionHint =>
      'Bazı hareketler mevcut kategorilerinden hiçbirine uymuyor. İşaretlediklerin oluşturulup otomatik atanır; işaretini kaldırdıkların oluşturulmaz ve o hareketler varsayılan kategoride kalır.';

  @override
  String get bankImportCategorySuggestionContinue => 'Devam et';

  @override
  String get bankImportPickCategoryHint => 'Kategori seç';

  @override
  String get bankImportFullscreen => 'Tam ekran';

  @override
  String get bankImportExitFullscreen => 'Tam ekrandan çık';

  @override
  String get bankImportSummarySheet => 'Özet ve uyarılar';

  @override
  String get bankImportMoreActions => 'Diğer işlemler';

  @override
  String bankImportAssignUncategorized(int count) {
    return 'Kategorisiz $count satıra ata';
  }

  @override
  String bankImportAssignOverwrite(int count) {
    return 'Görünen $count satırı değiştir (kategorili olanlar dahil)';
  }

  @override
  String get bankImportAssignTypeMismatch =>
      'Seçilen kategori bu satırların türüne uymuyor; hiçbir satır değişmedi.';

  @override
  String get bankImportGroupSimilar => 'Benzerleri grupla';

  @override
  String get bankImportGroupSimilarTitle => 'Benzer hareketler';

  @override
  String get bankImportGroupSimilarHint =>
      'Açıklaması birbirine benzeyen satırlar tek grupta toplandı. Bir gruba kategori seçmek gruptaki bütün satırlara uygulanır.';

  @override
  String get bankImportGroupScopeUncategorized => 'Yalnız kategorisiz';

  @override
  String get bankImportGroupScopeAll => 'Tümü';

  @override
  String bankImportGroupRows(int count) {
    return '$count satır';
  }

  @override
  String get bankImportGroupMixed => 'Karışık kategori';

  @override
  String get bankImportGroupNone => 'Kategorisiz';

  @override
  String get bankImportGroupEmpty => 'Birbirine benzeyen satır bulunamadı.';

  @override
  String bankImportGroupFillRest(String category) {
    return 'Kalanını “$category” yap';
  }

  @override
  String bankImportUncategorizedBlocked(int count) {
    return 'Seçili $count satırın kategorisi yok. Kategori seçilmeden eklenemez: bütçe ve raporlarda hiçbir kategoriye sayılmazlar.';
  }

  @override
  String get bankImportShowUncategorized => 'Göster';

  @override
  String get bankImportMapTitle => 'Dosyayı nasıl okuyalım?';

  @override
  String get bankImportMapHint =>
      'Sütunları kendimiz tanımaya çalıştık ama emin olamadık. Aşağıdaki hareketler doğru görünüyorsa devam et; yanlışsa ilgili sütuna dokunup ne olduğunu seç.';

  @override
  String get bankImportMapResultTitle => 'Böyle okunacak';

  @override
  String bankImportMapRowsRead(int count, int income, int expense) {
    return '$count hareket okunacak · $income gelir, $expense gider';
  }

  @override
  String bankImportMapSkipped(int count) {
    return '$count satır okunamadı (tarihi ya da tutarı yok)';
  }

  @override
  String get bankImportMapBalanceOk => 'Bakiye sütunuyla doğrulandı';

  @override
  String get bankImportMapBalanceBad =>
      'Bakiye tutmuyor: tutar sütunu ya da işareti yanlış olabilir';

  @override
  String get bankImportMapAllIncome =>
      'Hareketlerin hepsi gelir görünüyor. Tutarlar işaretsizse Giden para / Gelen para sütunlarını seç ya da incelemede «Tümünü çevir: Gider»i kullan.';

  @override
  String get bankImportMapNeedDate => 'Tarih sütununu seç';

  @override
  String get bankImportMapNeedDesc => 'Açıklama sütununu seç';

  @override
  String get bankImportMapNeedAmount =>
      'Tutar sütununu (ya da Giden para / Gelen para sütunlarını) seç';

  @override
  String get bankImportMapNoRows => 'Bu seçimle hiç hareket okunamıyor.';

  @override
  String get bankImportMapColumnsTitle => 'Sütunlar';

  @override
  String get bankImportMapColumnsHint =>
      'Bir sütunun ne olduğunu değiştirmek için ona dokun.';

  @override
  String bankImportMapRoleSheetTitle(String column) {
    return '“$column” sütunu ne?';
  }

  @override
  String bankImportMapDateQuestion(String sample) {
    return 'Tarihler “$sample” biçiminde. Bu hangisi?';
  }

  @override
  String get bankImportRoleDateDesc => 'İşlemin tarihi';

  @override
  String get bankImportRoleDescDesc => 'İşlemin açıklaması ya da karşı taraf';

  @override
  String get bankImportRoleAmountLabel => 'Tutar (+ / −)';

  @override
  String get bankImportRoleAmountDesc =>
      'Tek sütunda tutar; eksi olanlar harcamadır';

  @override
  String get bankImportRoleDebitLabel => 'Giden para';

  @override
  String get bankImportRoleDebitDesc =>
      'Yalnız çıkan paralar (bankada «Borç» yazar)';

  @override
  String get bankImportRoleCreditLabel => 'Gelen para';

  @override
  String get bankImportRoleCreditDesc =>
      'Yalnız giren paralar (bankada «Alacak» yazar)';

  @override
  String get bankImportRoleBalanceDesc =>
      'İşlemden sonraki bakiye; okunanları doğrulamaya yarar';

  @override
  String get bankImportRoleTag => 'Banka kategorisi';

  @override
  String get bankImportRoleTagDesc =>
      'Bankanın verdiği kategori/etiket; tahmine yardım eder';

  @override
  String get bankImportRoleReference => 'İşlem numarası';

  @override
  String get bankImportRoleReferenceDesc =>
      'Dekont/referans no; tekrarları kesin bulmaya yarar';

  @override
  String get bankImportRoleIgnore => 'Kullanma';

  @override
  String get bankImportRoleIgnoreDesc => 'Bu sütunu yok say';

  @override
  String get bankImportRemap => 'Sütunları yeniden eşle';

  @override
  String get bankImportDupExact => 'Zaten kayıtlı';

  @override
  String get bankImportDupWithinFile => 'Bu dosyada ikinci kez geçiyor';

  @override
  String get bankImportDupApproxStrong =>
      'Büyük olasılıkla elle girdiğin kayıt';

  @override
  String get bankImportDupApproxPossible => 'Elle girdiğin bir kayda benziyor';

  @override
  String get bankImportDupSystem => 'Borç ya da birikim kaydınla eşleşiyor';

  @override
  String get bankImportDupReasonSameAmount => 'tutar aynı';

  @override
  String bankImportDupReasonCents(String delta) {
    return '$delta fark · kuruşsuz yazılmış';
  }

  @override
  String bankImportDupReasonRounded(String delta) {
    return '$delta fark · yuvarlanmış';
  }

  @override
  String get bankImportDupReasonSameDay => 'aynı gün';

  @override
  String bankImportDupReasonDays(int days) {
    return '$days gün arayla';
  }

  @override
  String bankImportDupReasonWord(String word) {
    return '“$word” ikisinde de geçiyor';
  }

  @override
  String get bankImportDupReasonCategory => 'kategori aynı';

  @override
  String get bankImportDupWillSkip => 'Eklenmeyecek.';

  @override
  String get bankImportDupWillAdd => 'Yine de eklenecek.';

  @override
  String bankImportDupWillCorrect(String amount) {
    return 'Eklenmeyecek; kaydın tutarı $amount olacak.';
  }

  @override
  String get bankImportDupAddAnywayExact => 'Yine de ekle';

  @override
  String get bankImportDupAddAnyway => 'Farklı işlem, ekle';

  @override
  String get bankImportDupSkip => 'Aynı işlem, ekleme';

  @override
  String bankImportDupCorrect(String amount) {
    return 'Tutarı $amount yap';
  }

  @override
  String get bankImportDupCorrectUndo => 'Düzeltmeden vazgeç';

  @override
  String bankImportApproxWarning(int count) {
    return '$count satır elle girdiğin kayıtlara benzediği için eklenmeyecek. Bu bir tahmin; her satırda nedenini görebilirsin.';
  }

  @override
  String bankImportCorrectAll(int count) {
    return 'Benzeyen $count kaydın tutarını ekstredekiyle düzelt';
  }

  @override
  String bankImportCorrectionsPending(int count) {
    return '$count kaydın tutarı ekstredekiyle düzeltilecek.';
  }

  @override
  String bankImportApplyCorrections(int count) {
    return 'Düzeltmeleri uygula ($count)';
  }

  @override
  String bankImportDoneCorrected(int count) {
    return '$count kaydın tutarı ekstredekiyle düzeltildi.';
  }

  @override
  String get bankStatementSectionHeader => 'Banka ekstresi';

  @override
  String get sifirla => 'Sıfırla';

  @override
  String get deleteAllDataTitle => 'Tüm veriyi sil';

  @override
  String get deleteAllDataMessage =>
      'Tüm cüzdanlar, işlemler, birikimler, borçlar, alacaklar, bütçeler ve düzenli işlem şablonları telefondan kalıcı olarak silinecek. Bu işlem geri alınamaz. Drive yedeğin (varsa) etkilenmez.';

  @override
  String get irreversibleActionTitle => 'Bu işlem geri alınamaz';

  @override
  String get deleteAllDataDangerMessage =>
      'Onaylarsan telefondaki bütün kayıtlar kalıcı olarak silinir ve kurtarılamaz.';

  @override
  String get dataDeletedSuccess => 'Tüm yerel veri silindi.';

  @override
  String get dataDeleteError => 'Kayıtlar silinemedi. Tekrar dene.';

  @override
  String get deleteWalletTitle => 'Cüzdan sil';

  @override
  String deleteWalletConfirmMessage(String ad) {
    return '$ad cüzdanını silmek istediğine emin misin?';
  }

  @override
  String deleteWalletDangerMessage(String ad) {
    return '$ad cüzdanı ve tüm işlem geçmişi kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get transferOnayBasligi => 'Transferi onayla';

  @override
  String transferOnayMesaji(String tutar, String kaynak, String hedef) {
    return '$tutar tutarını $kaynak cüzdanından $hedef cüzdanına taşımak istediğine emin misin?';
  }

  @override
  String get budgetDeleteConfirmTitle => 'Bütçeyi sil';

  @override
  String budgetDeleteConfirmMessage(String kategori) {
    return '$kategori bütçesini silmek istediğine emin misin?';
  }

  @override
  String get borcSilBaslik => 'Borcu sil';

  @override
  String borcSilOnayMesaji(String baslik) {
    return '$baslik borcunu silmek istediğine emin misin? Bu borcun cüzdan bakiyesine etkisi de geri alınır.';
  }

  @override
  String get alacakSilBaslik => 'Alacağı sil';

  @override
  String alacakSilOnayMesaji(String isim) {
    return '$isim alacağını silmek istediğine emin misin? Bu alacağın cüzdan bakiyesine etkisi de geri alınır.';
  }

  @override
  String get budgetStatusUnderControl => 'Kontrol altında';

  @override
  String budgetStatusFilledCount(int sayi) {
    return '$sayi bütçe doldu';
  }

  @override
  String budgetStatusExceededCount(int sayi) {
    return '$sayi bütçe aşıldı';
  }

  @override
  String get insightDailyLimitTitle => 'Günde harcayabileceğin';

  @override
  String insightDailyLimitDesc(int gun) {
    return 'Bu dönemin gelirinden kalanı, kalan $gun güne bölünce.';
  }

  @override
  String get insightSpikeTitle => 'Harcama sıçraması uyarısı';

  @override
  String insightSpikeDesc(int gun, String tutar) {
    return 'Önceki $gun günde $tutar harcamıştın.';
  }

  @override
  String get drawerSectionFinancial => 'Para yönetimi';

  @override
  String get drawerSectionSystem => 'Uygulama';

  @override
  String get drawerBudgetSubtitle => 'Kategorilere aylık harcama sınırı koy';

  @override
  String get drawerRecurringSubtitle =>
      'Kira, maaş gibi yinelenen gelir ve giderler';

  @override
  String get drawerBankImportSubtitle =>
      'PDF ya da Excel hesap ekstresini içe aktar';

  @override
  String get drawerBankImportTitle => 'Banka ekstresi';

  @override
  String get drawerSettingsSubtitle => 'Tema, para birimi ve genel tercihler';

  @override
  String get drawerSecurityTitle => 'Güvenlik';

  @override
  String get drawerSecuritySubtitle => 'Uygulama kilidi ve PIN';

  @override
  String get drawerActiveWalletLabel => 'Aktif cüzdan';

  @override
  String get reportExpensesTitle => 'Giderler';

  @override
  String get reportIncomesTitle => 'Gelirler';

  @override
  String get reportNoDataTitle => 'Rapor için kayıt yok';

  @override
  String get reportNetLabel => 'Net';

  @override
  String get reportNoPreviousPeriod => 'Önceki dönem yok';

  @override
  String reportCompareOverspend(String oran) {
    return 'Gelirin %$oran üzerinde';
  }

  @override
  String get debtHistoryEmptyTitle => 'Henüz kapanan borç yok';

  @override
  String get receivableHistoryEmptyTitle => 'Henüz geri alınan alacak yok';

  @override
  String get badgeOdendi => 'Ödendi';

  @override
  String get badgeTahsilEdildi => 'Tahsil edildi';

  @override
  String reportSavingsSubtitle(String oran) {
    return '%$oran birikim';
  }

  @override
  String vadeTarihLabel(String tarih) {
    return 'Vade: $tarih';
  }

  @override
  String get privacyPolicyTitle => 'Gizlilik politikası';

  @override
  String get privacyIntro =>
      'ÇuHat, finansal kayıtlarınızı takip etmenize yardımcı olan bir kişisel finans uygulamasıdır. \"Önce-çevrimdışı\" tasarlandı: bulut yedeklemeyi açıkça etkinleştirmediğiniz sürece verileriniz cihazınızda kalır. Sunucumuz yoktur.';

  @override
  String get privacyLocalDataTitle => 'Cihazınızda saklanan veriler';

  @override
  String get privacyLocalDataBody =>
      'Cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler, tekrarlayan şablonlar ve uygulama tercihleri (tema, dil, kategoriler) yalnızca cihazınızda saklanır ve bize iletilmez.';

  @override
  String get privacyDriveTitle => 'Google Drive yedeği (isteğe bağlı)';

  @override
  String get privacyDriveBody =>
      'Bulut yedekleme varsayılan olarak KAPALIDIR. Açarsanız Google ile oturum açılır; yalnızca e-posta adresiniz (hangi hesabın bağlı olduğunu görmeniz için) ve yalnızca bu uygulamaya ayrılmış \"drive.appdata\" kapsamı kullanılır. Yedekler kendi Drive\'ınızdaki, başka uygulamaların erişemediği gizli bir uygulama klasörüne yazılır; en fazla son 5 kopya tutulur. Tam Drive erişimi istenmez; diğer dosyalarınız okunamaz.';

  @override
  String get privacyMarketDataTitle => 'Piyasa verisi';

  @override
  String get privacyMarketDataBody =>
      'Canlı fiyat göstermek için yalnızca varlık sembolü (örn. hisse kodu) herkese açık uç noktalara (Yahoo Finance, Truncgil) gönderilir. Hiçbir kişisel veya finansal kayıt paylaşılmaz.';

  @override
  String get backupOfferTitle => 'Verilerin yalnızca bu cihazda';

  @override
  String get backupOfferBody =>
      'ÇuHat kayıtlarını bir sunucuda tutmaz. Telefonunu kaybeder, sıfırlar ya da uygulamayı kaldırırsan bu veriler geri gelmez. Otomatik yedeklemeyi açarsan kayıtlarının kopyası düzenli olarak kendi Google Drive\'ındaki özel bir klasöre alınır.';

  @override
  String get backupOfferSetup => 'Yedeklemeyi kur';

  @override
  String get backupOfferLater => 'Şimdi değil';

  @override
  String get privacyReceiptsTitle => 'Fiş fotoğrafları ve metin tanıma';

  @override
  String get privacyReceiptsBody =>
      'İşleme fiş fotoğrafı eklemek isteğe bağlıdır. Fotoğraf sistem seçicisiyle alınır; uygulama kalıcı kamera veya depolama izni istemez. Görseller yalnızca cihazınızın özel depolama alanında tutulur; hiçbir yere yüklenmez ve Drive yedeğine girmez. Fişten tutar/tarih okuma, uygulamanın içine gömülü çevrimdışı Google ML Kit modeliyle yapılır — görsel hiçbir sunucuya gönderilmez. İşlemi silmek ekli görseli de siler.';

  @override
  String get privacyStatementTitle => 'Banka ekstresi içe aktarma';

  @override
  String get privacyStatementBody =>
      'Ekstreyi (PDF, CSV, Excel) siz seçersiniz ya da paylaş menüsünden gönderirsiniz; uygulamanın bankanıza erişimi ve dosyalarınızı tarama izni yoktur. Dosya tamamen cihazınızda ayrıştırılır ve hiçbir yere yüklenmez. Yalnızca inceleme ekranında onayladığınız hareketler kaydedilir; ekstre dosyasının kendisi saklanmaz.';

  @override
  String get privacySharingTitle => 'Veri paylaşımı';

  @override
  String get privacySharingBody =>
      'Verilerinizi satmaz, kiralamaz veya üçüncü taraflarla paylaşmayız. Uygulamada analitik, çökme-raporlama, reklam veya izleme SDK\'sı yoktur. Google API\'lerinden alınan bilgilerin kullanımı Google API Hizmetleri Kullanıcı Verileri Politikası\'na (Sınırlı Kullanım dahil) uyar.';

  @override
  String get privacySecurityTitle => 'Güvenlik';

  @override
  String get privacySecurityBody =>
      'Yerel veri uygulamanın özel depolama alanında tutulur. Yetkisiz erişimi önlemek için biyometrik / PIN kilidi desteklenir ve uygulama arka plana alındığında içerik bulanıklaştırılır. Tüm ağ iletişimi HTTPS kullanır.';

  @override
  String get privacyRetentionTitle => 'Veri saklama ve silme';

  @override
  String get privacyRetentionBody =>
      'Verileriniz üzerinde tam kontrol sizdedir. Tüm yerel veriyi Ayarlar → Gizlilik & Veri → \"Tüm veriyi sil\" ile silebilirsiniz. Drive yedeğini Ayarlar → Yedekleme bölümünden silebilir veya hesabınızın bağlantısını kesebilirsiniz.';

  @override
  String privacyContactLabel(String email) {
    return 'İletişim: $email';
  }

  @override
  String get privacyLastUpdated => 'Son güncelleme: 4 Ağustos 2026';

  @override
  String get privacyConsentTitle => 'Gizliliğin';

  @override
  String get privacyConsentBody =>
      'ÇuHat kayıtlarını yalnız telefonunda saklar; sunucumuz yok. Google Drive yedeği isteğe bağlıdır ve yalnız sen açarsan, kendi Drive\'ındaki özel bir klasöre yazılır. Kayıtların kimseyle paylaşılmaz; reklam ya da izleme yok.';

  @override
  String get privacyConsentAcknowledge => 'Anladım';

  @override
  String get secenekler => 'Seçenekler';

  @override
  String get tarihAraligiSecBaslik => 'Tarih aralığı seç';

  @override
  String get takvimdenSec => 'Takvimden seç';

  @override
  String get kategoriSecmeUyarisi => 'Bir kategori seç';

  @override
  String yatirimSatOnayBaslik(String name) {
    return '$name satılsın mı?';
  }

  @override
  String yatirimSilOnayBaslik(String name) {
    return '$name kaydı silinsin mi?';
  }

  @override
  String get walletQuickStartTitle => 'Cüzdan hazır!';

  @override
  String walletQuickStartSubtitle(String name) {
    return '$name oluşturuldu. Nasıl başlamak istersin?';
  }

  @override
  String get walletQuickStartImportTitle => 'Banka ekstresi içe aktar';

  @override
  String get walletQuickStartImportSubtitle =>
      'Geçmiş işlemlerini dosyadan yükle — en hızlı yol';

  @override
  String get walletQuickStartManualTitle => 'İlk işlemi elle ekle';

  @override
  String get walletQuickStartManualSubtitle =>
      'Tek bir gelir ya da giderle başla';

  @override
  String get walletQuickStartSkip => 'Şimdilik atla';

  @override
  String get driveErrNotSignedIn => 'Google Drive\'a bağlı değilsin.';

  @override
  String get driveErrCancelled => 'İşlem iptal edildi.';

  @override
  String get driveErrNoNetwork =>
      'İnternet bağlantısı yok. Bağlanıp tekrar dene.';

  @override
  String get driveErrTimeout =>
      'Google Drive zamanında yanıt vermedi. Bağlantını kontrol edip tekrar dene.';

  @override
  String get driveErrAuthExpired =>
      'Google oturumunun süresi doldu. Bağlantıyı kesip yeniden bağlan.';

  @override
  String get driveErrScopeDenied =>
      'Drive uygulama klasörü izni verilmedi. Yedekleme bu izin olmadan çalışamaz.';

  @override
  String get driveErrConfigError =>
      'Google Drive bu uygulama sürümünde yapılandırılmamış (OAuth istemcisi paket adı/imza ile eşleşmiyor). Bu bir kurulum hatası; yedekleme şimdilik kullanılamıyor.';

  @override
  String get driveErrTokenFailed =>
      'Google hesabından Drive erişim izni alınamadı. Ayarlar’dan bağlantıyı kesip yeniden bağlan; sorun sürerse Google hesabının izinlerini kontrol et.';

  @override
  String get driveErrQuotaExceeded =>
      'Google Drive depolama alanın dolu. Yer açıp tekrar dene.';

  @override
  String get driveErrServerError =>
      'Google Drive şu anda yanıt veremiyor. Daha sonra tekrar dene.';

  @override
  String get driveErrEmptyLocalData =>
      'Telefonda yedeklenecek kayıt yok. Boş bir yedek, Drive\'daki dolu yedeğinin yerini alırdı.';

  @override
  String get driveErrVerificationFailed =>
      'Yükleme doğrulanamadı; yedek eksik yazılmış olabilir. Yeni kopya geri alındı, önceki yedeğin duruyor.';

  @override
  String get driveErrNotFound => 'Google Drive\'da yedek bulunamadı.';

  @override
  String driveErrVersionMismatch(String found, int expected) {
    return 'Bu yedek farklı bir uygulama sürümüne ait (yedek şeması $found, bu sürüm $expected). Geri yüklenemez.';
  }

  @override
  String get driveErrCorrupt =>
      'Yedek dosyası okunamadı; bozuk ya da eksik yazılmış.';

  @override
  String get driveErrWriteFailure =>
      'Geri yükleme sırasında yazma hatası oldu. Telefondaki eski kayıtların geri alındı.';

  @override
  String get driveUnchanged =>
      'Veriler son yedekten beri değişmedi; yeni yedek alınmadı.';

  @override
  String get backupEmptyConfirmTitle => 'Boş yedek alınsın mı?';

  @override
  String get backupEmptyConfirmDesc =>
      'Cihazda hiç kayıt yok. Devam edersen Drive\'daki en yeni yedeğin yerine boş bir yedek yazılır.';

  @override
  String get backupEmptyConfirmAction => 'Boş yedek al';

  @override
  String get viewBackups => 'Yedekleri görüntüle';

  @override
  String get deleteAllBackups => 'Tüm yedekleri sil';

  @override
  String get deleteAllBackupsDesc =>
      'Google Drive\'daki tüm yedek kopyaları kalıcı olarak silinecek. Telefonundaki kayıtlar etkilenmez.';

  @override
  String backupGenerationsKept(int count) {
    return '$count kopya saklanıyor';
  }

  @override
  String get backupSizeLabel => 'Boyut';

  @override
  String get autoBackup => 'Otomatik yedekleme';

  @override
  String get autoBackupDesc =>
      'Uygulama arka plana alındığında, veri değiştiyse ve aralık dolduysa sessizce yedek alınır.';

  @override
  String get autoBackupOff => 'Kapalı';

  @override
  String get autoBackupDaily => 'Günlük';

  @override
  String get autoBackupWeekly => 'Haftalık';

  @override
  String get autoBackupLimitNote =>
      'Uygulamayı hiç açmazsan otomatik yedek çalışmaz.';

  @override
  String autoBackupFailureWarning(int count) {
    return 'Son $count otomatik yedekleme denemesi başarısız oldu. Elle yedekleyerek nedenini görebilirsin.';
  }

  @override
  String get autoBackupNeedsConnection =>
      'Otomatik yedekleme için Google Drive bağlantısı gerekir.';

  @override
  String get backupPreviewTitle => 'Yedekler';

  @override
  String get backupPreviewDetailTitle => 'Yedek önizleme';

  @override
  String get backupPreviewDriveSection => 'Google Drive\'daki kopyalar';

  @override
  String get backupPreviewLocalButton => 'Cihazdaki dosyadan önizle';

  @override
  String get backupPreviewEmpty => 'Google Drive\'da henüz yedek yok.';

  @override
  String get backupPreviewLocalSource => 'Cihaz dosyası';

  @override
  String get backupPreviewOriginManual => 'Elle';

  @override
  String get backupPreviewOriginAuto => 'Otomatik';

  @override
  String get backupPreviewLoading => 'Yedek okunuyor…';

  @override
  String get backupPreviewContents => 'İçerik';

  @override
  String get backupPreviewWallets => 'Cüzdanlar';

  @override
  String get backupPreviewTransactions => 'İşlemler';

  @override
  String get backupPreviewInvestments => 'Birikimler';

  @override
  String get backupPreviewDebts => 'Borçlar';

  @override
  String get backupPreviewReceivables => 'Alacaklar';

  @override
  String get backupPreviewBudgets => 'Bütçeler';

  @override
  String get backupPreviewRecurring => 'Düzenli işlemler';

  @override
  String get backupPreviewCategories => 'Kategori tercihleri';

  @override
  String get backupPreviewDateRange => 'İşlem tarih aralığı';

  @override
  String get backupPreviewIncome => 'Toplam gelir';

  @override
  String get backupPreviewExpense => 'Toplam gider';

  @override
  String get backupPreviewTakenAt => 'Yedek tarihi';

  @override
  String get backupPreviewSchemaVersion => 'Şema sürümü';

  @override
  String get backupPreviewDiffTitle => 'Geri yüklersen ne değişir';

  @override
  String get backupPreviewDiffOnDevice => 'Cihazda';

  @override
  String get backupPreviewDiffInBackup => 'Yedekte';

  @override
  String backupPreviewReceiptWarning(int count) {
    return '$count işlemin fiş görseli var. Görseller yedeğe dahil edilmez; başka bir cihaza geri yüklersen bu görseller görünmez.';
  }

  @override
  String get backupPreviewEmptyWarning =>
      'Bu yedek boş. Geri yüklersen telefonundaki tüm kayıtlar silinir.';

  @override
  String get backupPreviewRestoreButton => 'Bu yedeği geri yükle';

  @override
  String get backupPreviewDeleteButton => 'Bu kopyayı sil';

  @override
  String get backupPreviewDeleteConfirmDesc =>
      'Bu yedek kopyası Google Drive\'dan kalıcı olarak silinecek. Telefonundaki kayıtlar etkilenmez.';

  @override
  String get backupPreviewRestoreConfirmTitle => 'Bu yedek geri yüklensin mi?';

  @override
  String get backupPreviewRestoreConfirmDesc =>
      'Telefondaki tüm cüzdanlar, işlemler, birikimler, borçlar, alacaklar, bütçeler ve düzenli işlem şablonları bu yedektekilerle değiştirilir. Bu işlem geri alınamaz.';

  @override
  String get backupPreviewNoTransactions => 'Bu yedekte işlem yok.';

  @override
  String get backupPreviewUnknownCount => '?';

  @override
  String get disconnectConfirmTitle => 'Bağlantı kesilsin mi?';

  @override
  String disconnectConfirmDesc(String email) {
    return '$email hesabından çıkılacak. Google Drive\'daki yedeklerin silinmez — aynı hesapla yeniden bağlandığında onlara erişirsin. Otomatik yedekleme duracak.';
  }

  @override
  String deleteAllBackupsDangerDesc(int count) {
    return 'Onaylarsan Google Drive\'daki $count yedek kopyasının tamamı kalıcı olarak silinir. Telefonundaki kayıtlar bozulur ya da silinirse geri dönebileceğin hiçbir kopya kalmaz.';
  }

  @override
  String get driveErrApiNotEnabled =>
      'Google Drive API bu uygulama için etkinleştirilmemiş. Bu bir kurulum eksiği; kullanıcı izniyle çözülemez.';

  @override
  String vadeAraligi(int max) {
    return 'Vade 1 ile $max ay arasında olmalı';
  }

  @override
  String oranAraligi(int max) {
    return 'Oran %0 ile %$max arasında olmalı';
  }

  @override
  String get gecikmeFaiziLabel => 'Gecikme faizi:';

  @override
  String get odenecekToplamLabel => 'Ödenecek toplam:';

  @override
  String get odenecekTutardanFazlaOlamaz => 'Ödenecek toplamdan fazla olamaz';

  @override
  String get gecikmeFaiziChip => 'Gecikme faizi';

  @override
  String gecikmeFaiziKisa(Object tutar) {
    return '+ $tutar gecikme faizi';
  }

  @override
  String odemeMahsupAciklama(Object faiz, Object anapara) {
    return '$faiz gecikme faizine, $anapara ana paraya sayılacak.';
  }

  @override
  String taksitGecikmeGun(Object tutar, int gun) {
    return '≈ $tutar · $gun gün gecikti';
  }

  @override
  String odemeIcindeGecikmeFaizi(Object tarih, Object faiz) {
    return '$tarih · içinde $faiz gecikme faizi';
  }

  @override
  String get odemeSilBaslik => 'Ödemeyi sil';

  @override
  String odemeSilOnayMesaji(Object tutar) {
    return '$tutar tutarındaki ödeme kaydı silinecek. Bu ödemenin cüzdan bakiyesine etkisi de geri alınır.';
  }

  @override
  String get odemeyiDuzenleBaslik => 'Ödemeyi düzenle';

  @override
  String vadeTaksitIlerleme(int termMonths, int paid) {
    return 'Vade: $termMonths Ay | $paid/$termMonths taksit';
  }

  @override
  String get vadeOpsiyonelLabel => 'Vade (opsiyonel)';

  @override
  String get vadeSecilmedi => 'Seçilmedi';

  @override
  String get txSearchHint => 'İşlem ara…';

  @override
  String get txSearchClear => 'Aramayı temizle';

  @override
  String txSearchNoResultTitle(Object query) {
    return '“$query” için sonuç yok';
  }

  @override
  String get txPeriodPrev => 'Önceki dönem';

  @override
  String get txPeriodNext => 'Sonraki dönem';

  @override
  String get txPeriodPick => 'Dönem seç';

  @override
  String get txViewList => 'Liste görünümü';

  @override
  String get txViewCalendar => 'Takvim görünümü';

  @override
  String get txOpenFilters => 'Filtreleri aç';

  @override
  String get txChipRemove => 'Filtreyi kaldır';

  @override
  String txChipSearch(Object query) {
    return '“$query”';
  }

  @override
  String get txEmptyFilteredTitle => 'Eşleşen işlem yok';

  @override
  String get txEmptyFilteredBody =>
      'Seçtiğin dönem ve filtrelerle kayıt bulunamadı.';

  @override
  String get txEmptyClearFilters => 'Filtreleri temizle';

  @override
  String txFilterShowCount(int count) {
    return '$count işlemi göster';
  }

  @override
  String get txFilterNoResult => 'Eşleşen işlem yok';

  @override
  String get txFilterAmountRange => 'Tutar aralığı';

  @override
  String get txFilterMinMaxError =>
      'En düşük tutar, en yüksek tutardan büyük olamaz';

  @override
  String get txFilterCategorySearchHint => 'Kategori ara…';

  @override
  String get txFilterCategoryNoMatch => 'Eşleşen kategori yok';

  @override
  String txFilterSelectedCount(int count) {
    return '$count seçili';
  }

  @override
  String txFilterSubcategoryCount(int selected, int total) {
    return '$selected/$total';
  }

  @override
  String get txFilterExpandGroup => 'Alt kategorileri göster';

  @override
  String get txFilterCollapseGroup => 'Alt kategorileri gizle';

  @override
  String get txSummaryNet => 'Gelir − gider';

  @override
  String get txSummaryNetFiltered => 'Süzülen gelir − gider';

  @override
  String get txSummaryIncomeTotal => 'Toplam gelir';

  @override
  String get txSummaryIncomeFiltered => 'Süzülen gelir';

  @override
  String get txSummaryExpenseTotal => 'Toplam gider';

  @override
  String get txSummaryExpenseFiltered => 'Süzülen gider';

  @override
  String get txSummaryIncome => 'Gelir';

  @override
  String get txSummaryExpense => 'Gider';

  @override
  String get txSummaryCount => 'İşlem';

  @override
  String get txSummaryCountFiltered => 'Süzülen işlem';

  @override
  String get txModeIncome => 'Gelirler';

  @override
  String get txModeExpense => 'Giderler';

  @override
  String get txModeCompare => 'Karşılaştırma';

  @override
  String get txSwipeHintLocked => 'Otomatik oluşturulan işlem düzenlenemez';

  @override
  String get dateRangeLast7Days => 'Son 7 gün';

  @override
  String get dateRangeThisMonth => 'Bu ay';

  @override
  String get dateRangeLastMonth => 'Geçen ay';

  @override
  String get dateRangeLast3Months => 'Son 3 ay';

  @override
  String get dateRangeThisYear => 'Bu yıl';

  @override
  String get txPeriodToday => 'Bugün';

  @override
  String get txPeriodYesterday => 'Dün';

  @override
  String get lot => 'lot';

  @override
  String get katkiKipiMiktar => 'Miktar ile';

  @override
  String get katkiKipiTutar => 'Tutar ile';

  @override
  String katkiTakipBirimi(Object unit) {
    return 'Bu birikim $unit cinsinden takip ediliyor.';
  }

  @override
  String katkiFarkliTurBaslik(Object unit) {
    return '$unit bu kayda eklenemez';
  }

  @override
  String katkiFarkliTurAciklama(Object recordUnit, Object selectedUnit) {
    return 'Bu kayıt $recordUnit cinsinden takip ediliyor; araya $selectedUnit eklenirse miktar da değer de karışır. Bu tür için ayrı bir kayıt aç.';
  }

  @override
  String katkiFarkliTurButon(Object unit) {
    return '$unit için yeni kayıt aç';
  }

  @override
  String katkiMiktaraCevrilecek(Object qty, Object unit) {
    return '≈ $qty $unit eklenecek';
  }

  @override
  String get katkiFiyatGerekli =>
      'Tutarı miktara çevirmek için önce güncel fiyatı getir.';

  @override
  String get katkiOdenenBosUyari =>
      'Ödenen tutar boş: bu alım bedelsiz (hediye) sayılacak, cüzdandan para düşülmeyecek.';

  @override
  String get katkiTutarKipiAciklama =>
      'Yatırdığın tutarı yaz; güncel fiyattan miktara çevrilir.';

  @override
  String get katkiYatirilanTutarHint => 'Yatırılan tutar';

  @override
  String duzenlemeTurDegisikligiUyari(Object qty, Object newUnit) {
    return 'Tür değişiyor: kayıttaki $qty miktarı bundan sonra $newUnit sayılacak ve fiyat güncellemesinde değer buna göre hesaplanacak. Farklı bir tür aldıysan bu kaydı olduğu gibi bırakıp yeni bir kayıt aç.';
  }

  @override
  String alinanMiktarBirimHint(Object unit) {
    return 'Alınan miktar ($unit)';
  }

  @override
  String get yeniAlimMiktarVeyaTutar =>
      'Yeni alım: miktar ya da yatırılan tutar';

  @override
  String kartBirimFiyat(Object price) {
    return 'Birim $price';
  }

  @override
  String kartMiktarBirim(Object qty, Object unit) {
    return '$qty $unit';
  }

  @override
  String get yatirimTuruHisse => 'Hisse senedi';

  @override
  String get yatirimTuruAltin => 'Altın';

  @override
  String get yatirimTuruOzel => 'Özel';

  @override
  String satisSheetBaslik(Object name) {
    return '$name · Sat';
  }

  @override
  String satilanMiktarBirimHint(Object unit) {
    return 'Satılan miktar ($unit)';
  }

  @override
  String get satilanDegerHint => 'Satılan tutar (güncel değerinden)';

  @override
  String get alinanTutarHint => 'Alınan tutar (cüzdana girecek)';

  @override
  String get satTumunuSec => 'Tümü';

  @override
  String satElindeki(Object qty, Object unit) {
    return 'Elindeki: $qty $unit';
  }

  @override
  String satGuncelDegerBilgi(Object value) {
    return 'Güncel değer: $value';
  }

  @override
  String get satTamSatisUyari => 'Kaydın tamamı satılıyor: kayıt silinecek.';

  @override
  String satKismiKalanBilgi(Object qty, Object unit, Object value) {
    return 'Kalan: $qty $unit · $value';
  }

  @override
  String satKismiKalanTutar(Object value) {
    return 'Kalan kayıt: $value';
  }

  @override
  String get gecerliSatisMiktariGirin => 'Geçerli bir satış miktarı gir';

  @override
  String satisMiktariAsim(Object max) {
    return 'Elindekinden fazlasını satamazsın (en çok $max)';
  }

  @override
  String get gecerliAlinanTutarGirin => 'Geçerli bir alınan tutar gir';

  @override
  String get satisFiyatTazeleIpucu =>
      'Kayıttaki değer eskimiş olabilir; güncel fiyatı getirip alınan tutarı tazeleyebilirsin.';

  @override
  String get kismiSatisBasarili => 'Varlığın bir kısmı satıldı';

  @override
  String get kismiSatisGeriAlindi => 'Kısmi satış geri alındı';

  @override
  String get alimTarihi => 'Alım tarihi';

  @override
  String get zatenBendeBaslik => 'Bu varlık zaten bende';

  @override
  String get zatenBendeAciklama =>
      'Uygulamadan önce alındı; maliyeti cüzdandan düşülmesin';

  @override
  String alimCuzdandanDusulecek(Object amount, Object date) {
    return '$amount, $date tarihli gider olarak cüzdandan düşülecek.';
  }

  @override
  String get alimCuzdandanDusulmeyecek =>
      'Cüzdandan para düşülmeyecek; kayıt yalnız portföye eklenir.';

  @override
  String get birikimBosBaslik => 'Henüz birikimin yok';

  @override
  String get birikimBosAciklama =>
      'Altın, hisse ya da kendi tanımladığın bir varlığı ekle. Alım tutarı cüzdanından düşülür.';

  @override
  String get yatirimEklendiMesaji => 'Varlık eklendi';

  @override
  String get yatirimGuncellendiMesaji => 'Varlık güncellendi';

  @override
  String get yatirimSatildiMesaji => 'Varlık satıldı';

  @override
  String get yatirimKismenSatildiMesaji => 'Varlığın bir kısmı satıldı';

  @override
  String get yatirimSilindiDuzeltildiMesaji =>
      'Kayıt silindi, alım kaydı düzeltildi';

  @override
  String fiyatlarGuncellendiMesaji(Object count) {
    return '$count varlığın fiyatı güncellendi';
  }

  @override
  String fiyatlarKismenGuncellendiMesaji(Object updated, Object failed) {
    return '$updated güncellendi, $failed alınamadı';
  }

  @override
  String get yenilenebilirYatirimYokMesaji =>
      'Fiyatı güncellenebilecek varlık yok (sembol ve miktar gerekli)';

  @override
  String get fiyatlarAlinamadiMesaji =>
      'Fiyatlar alınamadı, değerler değiştirilmedi';

  @override
  String get bakiyeGuncellenemediUyarisi =>
      ' (Uyarı: bakiye güncellenemedi, cüzdanı yenile.)';

  @override
  String get yatirimGecmisiBuradaListelenecek =>
      'Birikim geçmişin burada listelenir.';

  @override
  String get hedefKategoriEv => 'Ev';

  @override
  String get hedefKategoriDugun => 'Düğün';

  @override
  String get hedefKategoriAraba => 'Araba';

  @override
  String get hedefKategoriAcilFon => 'Acil Fon';

  @override
  String get hedefKategoriEgitim => 'Eğitim';

  @override
  String get hedefKategoriDiger => 'Diğer';

  @override
  String get hedefKategoriOzel => 'Özel';

  @override
  String get miktarGirinDegerHesaplanmadi => 'miktar gir, değer hesaplansın';

  @override
  String get hedefKategoriOzelHint => 'Kendi kategorin (ör. Tekne)';

  @override
  String get hedefKategoriOzelBos => 'Özel kategori adı boş olamaz';

  @override
  String kartMaliyet(Object amount) {
    return 'Maliyet $amount';
  }

  @override
  String get maliyetVeyaDegerSifirdanBuyuk =>
      'Maliyet ya da mevcut değerden en az biri sıfırdan büyük olmalı';

  @override
  String get hedeflerim => 'Hedeflerim';

  @override
  String get bagsizVarliklar => 'Bağsız varlıklar';

  @override
  String get yeniHedefOlustur => 'Yeni hedef oluştur';

  @override
  String get hedefiDuzenle => 'Hedefi düzenle';

  @override
  String get hedefiSil => 'Hedefi sil';

  @override
  String hedefSilOnayBaslik(Object name) {
    return '$name hedefi silinsin mi?';
  }

  @override
  String hedefSilOnayMesaj(Object count) {
    return 'Hedef silinir. İçindeki $count varlık silinmez; bağsız listeye düşer.';
  }

  @override
  String get hedefAdiHint => 'Hedef adı · örn. Ev peşinatı';

  @override
  String get hedefTutariHint => 'Hedef tutar';

  @override
  String get hedefAdiGirin => 'Hedef adı gir';

  @override
  String get hedefAlaniEtiketi => 'Hedef';

  @override
  String get hedefeBagliDegil => 'Hedefe bağlı değil';

  @override
  String get hedefeVarlikEkle => 'Bu hedefe varlık ekle';

  @override
  String get hedefBosAciklama => 'Bu hedefe henüz varlık bağlanmadı.';

  @override
  String hedefIlerlemeSatiri(Object saved, Object target) {
    return '$saved / $target';
  }

  @override
  String hedefKalanTutar(Object amount) {
    return 'Kalan $amount';
  }

  @override
  String get hedefeUlasildi => 'Hedefe ulaşıldı';

  @override
  String hedefUyeSayisi(Object count) {
    return '$count varlık';
  }

  @override
  String get hedefKaydedildiMesaji => 'Hedef kaydedildi';

  @override
  String get hedefSilindiMesaji =>
      'Hedef silindi, varlıklar bağsız listeye taşındı';

  @override
  String get varlikTuruSec => 'Ne eklemek istersin?';

  @override
  String gecmisAlimUyarisi(Object date) {
    return '$date tarihli alım. \"Mevcut değer\" bugünkü değerdir, alım günündeki değil; maliyet ise o gün ödediğin tutardır.';
  }

  @override
  String get bugunkuDegeriHesapla => 'Bugünkü değeri hesapla';

  @override
  String get hedefYonetimi => 'Hedefler';

  @override
  String get hedefYokAciklama =>
      'Henüz hedefin yok. Hedef aç, gram altını, çeyreği ve hisseyi aynı hedefin altında topla.';

  @override
  String get hedefEkleKisa => 'Hedef ekle';

  @override
  String get reportUnitDay => 'Gün';

  @override
  String get reportUnitWeek => 'Hafta';

  @override
  String get reportUnitMonth => 'Ay';

  @override
  String get reportUnitSelectorLabel => 'Çözünürlük';

  @override
  String reportUnitTooDense(Object count) {
    return 'Bu aralıkta $count sütun olur, okunmaz';
  }

  @override
  String reportFlowChartSemantics(Object count, Object income, Object expense) {
    return 'Gelir–gider grafiği: $count dönem, toplam gelir $income, toplam gider $expense. Değerler için sütunlara dokun.';
  }

  @override
  String reportBalanceChartSemantics(Object start, Object end) {
    return 'Bakiye grafiği: dönem başı $start, dönem sonu $end. Ara değerler için çizgiye dokun.';
  }

  @override
  String get reportSystemMovementsTitle => 'Para taşıma hareketleri';

  @override
  String reportSystemMovementsOff(int count) {
    return '$count hareket gelir–giderin dışında';
  }

  @override
  String reportSystemMovementsOn(int count) {
    return '$count hareket gelir–gidere dahil';
  }

  @override
  String get reportSystemMovementsHint =>
      'Cüzdanlar arası transfer, borç ödemesi ve birikim alım/satımı harcama değildir: para harcanmaz, yalnızca yer değiştirir. Bakiye çizgisi bunları her zaman içerir.';

  @override
  String get reportShareTooltip => 'İşlemleri CSV olarak paylaş';

  @override
  String get reportNoIncomeForRate => 'Bu dönemde gelir yok';

  @override
  String get reportViewBars => 'Çubuk görünümü';

  @override
  String get reportTotalLabel => 'Toplam';

  @override
  String get reportTopPayeesTitle => 'En çok harcanan yerler';

  @override
  String get reportTopPayeesHint =>
      'Benzer başlıklar birleştirildi (ör. aynı mağazanın şubeleri)';

  @override
  String reportTopPayeesCoverage(Object yuzde) {
    return 'Bu liste dönem giderinin %$yuzde kadarını kapsıyor';
  }

  @override
  String reportPayeeCount(Object count) {
    return '$count işlem';
  }

  @override
  String get reportBudgetSummaryTitle => 'Bütçe durumu';

  @override
  String reportBudgetExceededCount(Object count, Object total) {
    return '$count bütçeden $total tanesi aşıldı';
  }

  @override
  String reportBudgetAllWithinLimit(Object count) {
    return '$count bütçenin hepsi limit içinde';
  }

  @override
  String reportBudgetMoreCount(Object count) {
    return '+$count bütçe daha';
  }

  @override
  String get reportCategoryChange => 'önceki döneme göre';

  @override
  String get reportLensBalance => 'Bakiye';

  @override
  String reportFlowClippedBar(Object tutar) {
    return 'Büyük çubuklar kısaltıldı (en yüksek: $tutar); diğerleri okunabilsin';
  }

  @override
  String get reportOtherSmallItems => 'Küçük kalemler';

  @override
  String get insightSectionStatus => 'Durum';

  @override
  String get insightSectionPeriod => 'Dönem özeti';

  @override
  String get insightSectionHabits => 'Harcama alışkanlığı';

  @override
  String insightDailyLimitObligations(String tutar) {
    return '$tutar düzenli ödeme düşüldü';
  }

  @override
  String get insightOverspentTitle => 'Bu dönem açıktasın';

  @override
  String insightOverspentDesc(int gun, String tutar) {
    return 'Kalan $gun gün için harcanacak tutar kalmadı; $tutar açıktasın.';
  }

  @override
  String insightWeekdayHint(int kez) {
    return 'Dönemdeki $kez günün ortalaması';
  }

  @override
  String insightDailyAverageHint(int gun) {
    return '$gun günün ortalaması';
  }

  @override
  String get insightTapForTransactions => 'İşlemleri görmek için dokun';

  @override
  String get insightTopExpensesTitle => 'En büyük harcamalar';

  @override
  String insightSystemMovementsNote(int sayi) {
    return '$sayi para taşıma hareketi (transfer, borç, birikim) sayılmadı';
  }

  @override
  String get insightDismissSuggestion => 'Yoksay';

  @override
  String get insightNoSuggestionsLeft =>
      'Şimdilik yeni bir düzenli ödeme yakalanmadı';

  @override
  String get txTodayJump => 'Bugüne dön';

  @override
  String txRailDaySemantics(Object date, Object net, int count) {
    return '$date: net $net, $count işlem';
  }

  @override
  String txRailDayEmptySemantics(Object date) {
    return '$date: işlem yok';
  }

  @override
  String get txSearchWidenTitle => 'Bu dönemde sonuç yok';

  @override
  String txSearchWidenBody(int count) {
    return 'Tüm geçmişte $count eşleşme var.';
  }

  @override
  String get txSearchWidenAction => 'Tüm geçmişte ara';

  @override
  String get txRowActions => 'İşlem menüsü';

  @override
  String get txDayCollapse => 'Günü gizle';

  @override
  String get txDayExpand => 'Günü göster';

  @override
  String get txRailTitle => 'Gün şeridi';

  @override
  String get catSeedGroceries => 'Market';

  @override
  String get catSeedGroceriesProduce => 'Manav';

  @override
  String get catSeedGroceriesButcher => 'Kasap';

  @override
  String get catSeedGroceriesDrinks => 'Su & İçecek';

  @override
  String get catSeedDining => 'Yemek';

  @override
  String get catSeedDiningRestaurant => 'Restoran';

  @override
  String get catSeedDiningCafe => 'Kafe';

  @override
  String get catSeedDiningTakeaway => 'Paket Servis';

  @override
  String get catSeedTransport => 'Ulaşım';

  @override
  String get catSeedTransportFuel => 'Yakıt';

  @override
  String get catSeedTransportPublic => 'Toplu Taşıma';

  @override
  String get catSeedTransportTaxi => 'Taksi';

  @override
  String get catSeedTransportParking => 'Otopark';

  @override
  String get catSeedBills => 'Fatura';

  @override
  String get catSeedBillsElectricity => 'Elektrik';

  @override
  String get catSeedBillsWater => 'Su';

  @override
  String get catSeedBillsGas => 'Doğalgaz';

  @override
  String get catSeedBillsInternet => 'İnternet';

  @override
  String get catSeedBillsPhone => 'Telefon';

  @override
  String get catSeedHousing => 'Konut';

  @override
  String get catSeedHousingRent => 'Kira';

  @override
  String get catSeedHousingDues => 'Aidat';

  @override
  String get catSeedHousingMaintenance => 'Bakım & Onarım';

  @override
  String get catSeedShopping => 'Alışveriş';

  @override
  String get catSeedShoppingClothing => 'Giyim';

  @override
  String get catSeedShoppingElectronics => 'Elektronik';

  @override
  String get catSeedShoppingHomeGoods => 'Ev Eşyası';

  @override
  String get catSeedHealth => 'Sağlık';

  @override
  String get catSeedHealthPharmacy => 'İlaç';

  @override
  String get catSeedHealthDoctor => 'Doktor';

  @override
  String get catSeedHealthFitness => 'Spor';

  @override
  String get catSeedEducation => 'Eğitim';

  @override
  String get catSeedEducationSchool => 'Okul & Kurs';

  @override
  String get catSeedEducationBooks => 'Kitap';

  @override
  String get catSeedEntertainment => 'Eğlence';

  @override
  String get catSeedEntertainmentCinema => 'Sinema & Konser';

  @override
  String get catSeedEntertainmentSubscriptions => 'Abonelikler';

  @override
  String get catSeedEntertainmentGames => 'Oyun';

  @override
  String get catSeedPersonal => 'Kişisel';

  @override
  String get catSeedPersonalHairdresser => 'Kuaför';

  @override
  String get catSeedPersonalCosmetics => 'Kozmetik';

  @override
  String get catSeedInvestment => 'Yatırım';

  @override
  String get catSeedFees => 'Banka Masrafları';

  @override
  String get catSeedOther => 'Diğer';

  @override
  String get catSeedSalary => 'Maaş';

  @override
  String get catSeedSideIncome => 'Ek Gelir';

  @override
  String get catSeedSideIncomeBonus => 'Prim & İkramiye';

  @override
  String get catSeedSideIncomeFreelance => 'Serbest Çalışma';

  @override
  String get catSeedRentalIncome => 'Kira Geliri';

  @override
  String get catSeedInvestmentIncome => 'Yatırım';

  @override
  String get catSeedOtherIncome => 'Diğer Gelir';

  @override
  String starterPackAddedToWallet(Object count) {
    return '$count kategori bu cüzdana eklendi';
  }

  @override
  String get drawerCategoriesTitle => 'Kategoriler';

  @override
  String get drawerCategoriesSubtitle => 'Gelir ve gider kalemlerini düzenle';

  @override
  String kategoriCuzdanKapsamiAciklama(Object wallet) {
    return 'Kategoriler tüm cüzdanlarda ortaktır. Buradaki anahtar yalnız $wallet cüzdanında hangilerinin görüneceğini belirler; kategori silinmez.';
  }

  @override
  String get kategoriBuCuzdandaGoster => 'Bu cüzdanda göster';

  @override
  String get kategoriBuCuzdandaGizle => 'Bu cüzdanda gizle';

  @override
  String kategoriGorunurSayisi(Object visible, Object total) {
    return '$visible/$total kategori bu cüzdanda görünür';
  }

  @override
  String get kategoriBuCuzdandaHicYok =>
      'Bu cüzdanda henüz kategori seçilmedi. Hazır setten kur ya da aşağıdan tek tek aç.';

  @override
  String get kategoriCuzdanKapsamiAciklamaBu =>
      'Kategoriler tüm cüzdanlarda ortaktır. Buradaki anahtar yalnız bu cüzdanda hangilerinin görüneceğini belirler; kategori silinmez.';

  @override
  String get securityTitle => 'Güvenlik';

  @override
  String get securityLockSection => 'Kilit';

  @override
  String get securityPrivacySection => 'Gizlilik';

  @override
  String get securityRecoverySection => 'Kurtarma';

  @override
  String get securityStatusOnTitle => 'Uygulama kilidi açık';

  @override
  String get securityStatusOffTitle => 'Uygulama kilidi kapalı';

  @override
  String get securityStatusOnSubtitle =>
      'Uygulama açıldığında kimlik doğrulaması istenir.';

  @override
  String get securityStatusOffSubtitle =>
      'Kayıtlarını korumak için bir PIN oluştur.';

  @override
  String get pinCardTitle => 'PIN kodu';

  @override
  String get pinCardOnSubtitle => '6 haneli PIN tanımlı';

  @override
  String get pinCardOffSubtitle => 'Tanımlı değil';

  @override
  String get biometricCardSubtitleUnavailable => 'Bu cihazda kullanılamıyor';

  @override
  String get privacyGuardCardTitle => 'Gizlilik perdesi';

  @override
  String get privacyGuardCardSubtitle =>
      'Uygulama değiştiricide içerik bulanıklaşır';

  @override
  String get backgroundLockCardSubtitle =>
      'Uygulamadan bu kadar uzak kalınca yeniden kilitlenir';

  @override
  String durationSecondsShort(Object seconds) {
    return '$seconds sn';
  }

  @override
  String durationMinutesShort(Object minutes) {
    return '$minutes dk';
  }

  @override
  String get pinEntryNewTitle => 'Yeni PIN';

  @override
  String get pinEntryNewSubtitle => '6 haneli bir PIN belirle';

  @override
  String get pinEntryRepeatTitle => 'PIN\'i tekrar gir';

  @override
  String get pinEntryRepeatSubtitle => 'Aynı PIN\'i bir kez daha gir';

  @override
  String get pinEntryCurrentTitle => 'Mevcut PIN';

  @override
  String get pinEntryCurrentSubtitle => 'Devam etmek için mevcut PIN\'ini gir';

  @override
  String get pinEntryMismatch => 'PIN\'ler eşleşmedi, tekrar dene';

  @override
  String get msgPrivacyGuardEnabled => 'Gizlilik perdesi açıldı';

  @override
  String get msgPrivacyGuardDisabled => 'Gizlilik perdesi kapatıldı';

  @override
  String get msgBackgroundLockUpdated => 'Arka plan kilidi güncellendi';

  @override
  String get msgBackgroundLockDisabled => 'Arka plan kilidi kapatıldı';

  @override
  String get forgotPinAction => 'PIN\'imi unuttum';

  @override
  String get pinRecoveryTitle => 'PIN kurtarma';

  @override
  String get pinRecoveryIntro =>
      'PIN\'ini hatırlamıyorsan aşağıdaki yollardan biriyle yeni bir PIN belirleyebilirsin. Hiçbir veri silinmez.';

  @override
  String get recoveryCardTitle => 'PIN\'imi unutursam';

  @override
  String get recoveryCardSubtitle =>
      'Telefon kilidinle doğrula ya da gecikmeli sıfırlama başlat';

  @override
  String get recoveryDeviceTitle => 'Telefon kilidiyle doğrula';

  @override
  String get recoveryDeviceBody =>
      'Telefonunun kendi PIN/desen/parolasıyla doğrula, hemen yeni bir PIN belirle.';

  @override
  String get recoveryDeviceAction => 'Doğrula';

  @override
  String get recoveryDeviceReason =>
      'PIN\'ini sıfırlamak için kimliğini doğrula';

  @override
  String get recoveryDeviceUnavailable =>
      'Telefonunda ekran kilidi tanımlı olmadığı için bu yöntem kullanılamıyor.';

  @override
  String get recoveryDeviceFailed => 'Doğrulama tamamlanmadı';

  @override
  String get recoveryTimedTitle => 'Gecikmeli sıfırlama';

  @override
  String recoveryTimedBody(Object hours) {
    return 'Hiçbir şifre istemez. İsteği başlattıktan $hours saat sonra yeni PIN belirleyebilirsin; verilerin yerinde kalır.';
  }

  @override
  String get recoveryTimedStart => 'Sıfırlama isteği başlat';

  @override
  String recoveryTimedPending(Object remaining) {
    return 'Kalan süre: $remaining';
  }

  @override
  String get recoveryTimedCancel => 'İsteği iptal et';

  @override
  String get recoveryTimedReady =>
      'Bekleme tamamlandı, yeni PIN belirleyebilirsin.';

  @override
  String get recoveryTimedStarted => 'Sıfırlama isteği başlatıldı';

  @override
  String get recoveryTimedCancelled => 'Sıfırlama isteği iptal edildi';

  @override
  String get recoveryTimedWarning =>
      'Bu isteği sen başlatmadıysan iptal et: bekleme dolduğunda telefonu eline geçiren biri PIN\'i değiştirebilir.';

  @override
  String get recoveryResetAction => 'Yeni PIN belirle';

  @override
  String get recoveryResetDone => 'PIN sıfırlandı';

  @override
  String get recoveryUnexpectedError => 'İşlem tamamlanamadı';

  @override
  String remainingHoursMinutes(Object hours, Object minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get errorLogTitle => 'Hata günlüğü';

  @override
  String get errorLogSubtitle =>
      'Sorun bildirirken paylaşabileceğin tanı kaydı';

  @override
  String get errorLogEmpty => 'Kayıtlı hata yok.';

  @override
  String get errorLogPrivacyNote =>
      'Bu günlük yalnız bu cihazda tutulur ve siz paylaşmadıkça hiçbir yere gönderilmez. Uygulama beklenmedik davrandığında geliştiriciye iletmek sorunu bulmayı hızlandırır.';

  @override
  String get errorLogCopy => 'Kopyala';

  @override
  String get errorLogShare => 'Paylaş';

  @override
  String get errorLogCopied => 'Hata günlüğü panoya kopyalandı';

  @override
  String get errorLogClearConfirmTitle => 'Hata günlüğü temizlensin mi?';

  @override
  String get errorLogClearConfirmDesc =>
      'Kayıtlı tüm hatalar bu cihazdan silinir.';

  @override
  String get driveErrLocalReadFailure =>
      'Telefondaki kayıtlar okunamadı. Uygulamayı yeniden başlatıp tekrar dene.';

  @override
  String get fisGorselAlinamadi =>
      'Görsel alınamadı. Kamera ve fotoğraf izinlerini kontrol et.';

  @override
  String get bankImportDupLinkedByUser => 'Senin eşleştirdiğin kayıt';

  @override
  String bankImportDupReasonNear(String delta) {
    return '$delta fark · kategori aynı';
  }

  @override
  String get bankImportStepAddAnyway => 'Yine de ekle';

  @override
  String bankImportLeftoverBanner(int count) {
    return '$count kaydın bu ekstrede olası eşi var ama otomatik eşleşmedi. Aynı hareketse eşleştir, satır ikinci kez eklenmesin.';
  }

  @override
  String get bankImportLeftoverReview => 'İncele';

  @override
  String get bankImportLeftoverSheetTitle => 'Karşılığı bulunamayan kayıtlar';

  @override
  String get bankImportLeftoverSheetHint =>
      'Bu kayıtlar ekstre döneminde defterinde duruyor ama hiçbir satırla otomatik eşleşmedi. Aynı hareketse eşleştir: satır eklenmez. Hiçbir satır sen onaylamadan atlanmaz.';

  @override
  String get bankImportLeftoverSame => 'Bu satırla aynı';

  @override
  String get bankImportLeftoverNone => 'Hiçbiri';

  @override
  String get bankImportLeftoverCoupling => 'Borç/birikim kaydı';

  @override
  String get bankImportFilterLeftover => 'Olası eş';

  @override
  String bankImportDoneLeftoverWarning(int count) {
    return 'Ekstrede karşılığı bulunamayan $count kaydın kaldı. Bakiyeyi eşitlemeden önce tekrar olup olmadığına bak: eşitleme tekrarları gizler.';
  }

  @override
  String bankImportDupAlternative(String row) {
    return 'Şu satıra da benziyor: $row';
  }

  @override
  String get bankImportDupMoveMatch => 'Diğer satırla eşleştir';

  @override
  String get benimsemeYapilamadiMesaji =>
      'Seçilen işlem bağlanamadı: bu arada değişmiş, silinmiş ya da başka bir kayda bağlanmış olabilir. Kayıt eklenmedi.';

  @override
  String get defterSatiriSecBaslik => 'Ödemenin satırını seç';

  @override
  String get defterSatiriSecAciklama =>
      'Bu cüzdandaki düz işlemler; tutarı ve tarihi en yakın olanlar üstte. Seçilen satır bu kaydın ödemesi sayılır, para ikinci kez düşülmez.';

  @override
  String get defterSatiriYok =>
      'Uygun işlem yok. Ödeme ekstreden henüz gelmediyse önce ekstreyi içe aktar.';

  @override
  String get ekstredenRozeti => 'Ekstreden';

  @override
  String get odemeKaynagiBaslik => 'Ödeme';

  @override
  String get odemeCuzdandanBaslik => 'Cüzdandan düşülsün';

  @override
  String get odemeCuzdandanAciklama =>
      'Alım, seçilen tarihte gider olarak yazılır.';

  @override
  String get odemeDefterdeBaslik => 'Ödemesi defterde zaten var';

  @override
  String get odemeDefterdeAciklama =>
      'Ekstreden gelen ya da elle girdiğin satırı seç; para ikinci kez düşülmez.';

  @override
  String get defterSatiriSecDugme => 'Satır seç';

  @override
  String get defterSatiriDegistir => 'Değiştir';

  @override
  String get defterSatiriSecilmedi => 'Önce ödemenin defterdeki satırını seç.';

  @override
  String alimDefterdenKarsilanacak(String amount) {
    return 'Seçilen satır ($amount) bu kaydın ödemesi sayılır; yeni gider yazılmaz. Tutar ve tarih o satırdan gelir.';
  }

  @override
  String get katkiDefterdeVarDugme => 'Ödemesi defterde zaten var — satırı seç';

  @override
  String get katkiDefterSatiriKaldir => 'Kaldır';

  @override
  String get katkiDefterdenKarsilanacak =>
      'Bu katkının ödemesi seçilen satır; yeni gider yazılmaz.';

  @override
  String get borcDefterdeSecenekBaslik => 'Anapara defterde zaten var';

  @override
  String get borcDefterdeSecenekGovde =>
      'Ekstreden gelen giriş satırını (ör. KREDI KULLANDIRIM) seç; ikinci kez gelir yazılmaz.';

  @override
  String borcDefterTutarUyusmuyor(String row, String principal) {
    return 'Seçilen satırın tutarı ($row) anaparayla ($principal) aynı değil. Anaparayı düzelt ya da doğru satırı seç.';
  }

  @override
  String get borcOdemesiDefterdenKarsilanacak =>
      'Bu ödeme seçilen satırdır; yeni gider yazılmaz. Tutar ve tarih o satırdan gelir.';

  @override
  String get odemeDefterSatirinaBagli =>
      'Ekstre satırına bağlı: tutar ve tarih o satırdan gelir. Yanlış satırsa ödemeyi silip yeniden ekle.';

  @override
  String get baglaEylemi => 'Bağla…';

  @override
  String get baglaEylemiAciklama =>
      'Birikim alımı, kasaya aktarım, borç ödemesi ya da transfer olarak işaretle';

  @override
  String get baglaBaslik => 'Bu satırı bağla';

  @override
  String get baglaAciklama =>
      'Satır ikinci kez yazılmaz: seçtiğin kaydın ödemesi olur ve harcama/gelir raporlarından çıkar. Kaydı silersen satır eski hâline döner.';

  @override
  String get baglaYeniBirikim => 'Yeni birikim alımı';

  @override
  String get baglaYeniBirikimAciklama => 'Altın, hisse, fon… aldın';

  @override
  String get baglaBirikimeKatki => 'Var olan birikime ekleme';

  @override
  String get baglaBirikimeKatkiAciklama =>
      'Takip ettiğin bir birikime yapılan ödeme';

  @override
  String get baglaBorcOdemesi => 'Borç ödemesi';

  @override
  String get baglaBorcOdemesiAciklama =>
      'Kredi taksidi ya da bir borca yapılan ödeme';

  @override
  String get baglaBorcAnaparasi => 'Kredi / borç girişi';

  @override
  String get baglaBorcAnaparasiAciklama =>
      'Çektiğin kredi ya da aldığın borç hesabına yattı';

  @override
  String get baglaTransferCikis => 'Kendi hesabıma transfer';

  @override
  String get baglaTransferCikisAciklama =>
      'Başka bir cüzdanına (ör. kredi kartına) taşıdığın para';

  @override
  String get baglaTransferGiris => 'Kendi hesabımdan transfer';

  @override
  String get baglaTransferGirisAciklama => 'Başka bir cüzdanından gelen para';

  @override
  String get baglaBirikimTuruSec => 'Ne aldın?';

  @override
  String get baglaBirikimSec => 'Hangi birikime?';

  @override
  String get baglaBirikimYok =>
      'Bu cüzdanda birikim yok. Önce \"Yeni birikim alımı\"nı seç.';

  @override
  String get baglaBorcSec => 'Hangi borca?';

  @override
  String get baglaBorcYok => 'Bu cüzdanda açık borç yok.';

  @override
  String get baglaCuzdanSec => 'Hangi cüzdanın?';

  @override
  String get baglaCuzdanYok =>
      'Başka cüzdanın yok. Transfer için önce bir cüzdan daha oluştur.';

  @override
  String get baglaKarsiSatirBaslik => 'Karşı cüzdanda bu hareket zaten var mı?';

  @override
  String get baglaKarsiSatirAciklama =>
      'O cüzdanın ekstresini de aktardıysan aynı para taşıması orada da duruyordur; seç ki iki kez sayılmasın.';

  @override
  String get baglaKarsiSatirOlustur => 'Yok, karşı cüzdana eklensin';

  @override
  String get baglaKarsiSatirAdayYok =>
      'Karşı cüzdanda eşleşebilecek bir satır bulunamadı.';

  @override
  String get transferBaglandi => 'Transfer olarak bağlandı';

  @override
  String get transferiKaldir => 'Transferi kaldır';

  @override
  String get transferiKaldirOnay =>
      'Transferin iki bacağı da kaldırılır: ekstreden gelen satırlar eski kategorilerine döner, uygulamanın yazdığı bacaklar silinir.';

  @override
  String get transferKaldirildi => 'Transfer kaldırıldı';

  @override
  String get transferKaldirilamadi =>
      'Transfer tam kaldırılamadı; cüzdan defterini kontrol et.';

  @override
  String bagliSatirNotu(String category) {
    return 'Bu satır bir kaydın ödemesi olarak bağlandı; özgün kategorisi “$category”. Bağlı kaydı silersen satır eski hâline döner.';
  }

  @override
  String get bagliTransferNotu =>
      'Bu satır kendi cüzdanların arasındaki bir transferin bacağı; harcama ya da gelir sayılmaz.';

  @override
  String get bagliSatirKisaNotu =>
      'Bu satır bir kaydın (birikim, borç…) ödemesi olarak bağlandı; o kayıttan yönetilir. Kaydı silersen satır eski hâline döner.';

  @override
  String get transferiKaldirAciklama =>
      'İki bacağı da kaldırır; ekstreden gelen satır eski hâline döner';

  @override
  String get bankImportLinkTitle => 'Bir kayda bağlanabilecek satırlar';

  @override
  String get bankImportLinkBody =>
      'Bunlar birikim alımı, borç ödemesi ya da kredi girişi gibi görünüyor. Aynı hareketi ilgili bölüme de gireceksen önce buradan bağla; yoksa iki kez sayılır.';

  @override
  String get linkHintInvestment => 'Birikim alımı olabilir';

  @override
  String get linkHintDebtPayment => 'Borç ödemesi olabilir';

  @override
  String get linkHintLoan => 'Kredi girişi olabilir';

  @override
  String get bankImportLinkButton => 'Bağla';

  @override
  String get bankImportLinked => 'Bağlandı';

  @override
  String get kkSekme => 'Kredi kartları';

  @override
  String get kkKartEkle => 'Kart ekle';

  @override
  String get kkMevcutCevir =>
      'Kartını şimdiye kadar ayrı bir cüzdanda mı tuttun? O cüzdanı kart yap';

  @override
  String get kkKurulumBaslik => 'Kredi kartı ekle';

  @override
  String get kkCevirBaslik => 'Kredi kartına çevir';

  @override
  String get kkAyarlarBaslik => 'Kart ayarları';

  @override
  String get kkKurulumAciklama =>
      'Kart, bağlı olduğu cüzdanın içinde durur: harcamaları kartın kendi hesabında toplanır, karta yaptığın ödeme transfer sayılır. Böylece hiçbir tutar iki kez sayılmaz.';

  @override
  String get kkKartAdi => 'Kart adı';

  @override
  String get kkKartAdiIpucu => 'ör. Bonus Kart';

  @override
  String get kkKartAdiGerekli => 'Kart adı gerekli.';

  @override
  String get kkBanka => 'Banka (isteğe bağlı)';

  @override
  String get kkSon4 => 'Son 4 hane (isteğe bağlı)';

  @override
  String get kkSon4Aciklama =>
      'Banka ekstresindeki kart ödemesini bu karta bağlamak için.';

  @override
  String get kkSon4Hatasi => 'Son 4 hane 4 rakam olmalı.';

  @override
  String get kkLimit => 'Kart limiti (isteğe bağlı)';

  @override
  String get kkKesimGunu => 'Hesap kesim günü';

  @override
  String get kkSonOdemeGunu => 'Son ödeme günü';

  @override
  String get kkGuncelBorc => 'Şu anki toplam borç';

  @override
  String get kkGuncelBorcAciklama =>
      'Kart uygulamasındaki güncel borç (taksitler dahil). Kartın açılış bakiyesi bu olur.';

  @override
  String get kkOdemeCuzdani => 'Bağlı olduğu cüzdan';

  @override
  String get kkSonEkstre => 'Son ekstre (isteğe bağlı)';

  @override
  String kkSonEkstreAciklama(String date) {
    return '$date tarihli kesimin ekstresinden: dönem borcu ve asgari ödeme.';
  }

  @override
  String get kkDonemBorcu => 'Dönem borcu';

  @override
  String get kkAsgariOdeme => 'Asgari ödeme';

  @override
  String get kkKalanDonemBorcu => 'Kalan dönem borcu';

  @override
  String get kkKalanAsgari => 'Kalan asgari';

  @override
  String kkGunKaldi(int days) {
    return '$days gün kaldı';
  }

  @override
  String get kkBugunSonGun => 'Son gün bugün';

  @override
  String kkGecikti(int days) {
    return '$days gün gecikti';
  }

  @override
  String get kkToplamBorc => 'Toplam borç';

  @override
  String get kkKullanilabilirLimit => 'Kullanılabilir limit';

  @override
  String get kkKalanTaksit => 'Kalan taksitler';

  @override
  String kkSonrakiKesim(String date) {
    return 'Sonraki kesim: $date';
  }

  @override
  String get kkOde => 'Öde';

  @override
  String get kkEkstreBilgisi => 'Ekstre bilgisi';

  @override
  String get kkAyarlar => 'Ayarlar';

  @override
  String get kkEkstreGirilmedi =>
      'Bu dönemin ekstresini girersen dönem borcu ve asgari bankanınkiyle birebir olur.';

  @override
  String get kkDefterGuvenilmez =>
      'Kart bu kesimden sonra eklendi; dönem borcunu ekstreden gir.';

  @override
  String kkFarkUyarisi(String amount) {
    return 'Ekstre ile kayıtlar arasında $amount fark var: eksik ya da fazla işlem olabilir.';
  }

  @override
  String get kkOdemeIcinCuzdanYok => 'Ödemek için başka bir cüzdanın olmalı.';

  @override
  String get kkKesimTarihi => 'Hesap kesim tarihi';

  @override
  String get kkSonOdemeTarihi => 'Son ödeme tarihi';

  @override
  String get kkEkstreSayfaAciklama =>
      'Bankanın gönderdiği ekstredeki rakamlar. Kayıtlardan hesaplananla önceden doldurduk.';

  @override
  String get kkKaydedildi => 'Kart bilgisi kaydedildi';

  @override
  String get kkSonrakiKesimEtiket => 'Sonraki kesim';

  @override
  String get notifCardUpcomingTitle => 'Kart son ödemesi yarın';

  @override
  String notifCardUpcomingBody(String name, String amount) {
    return '$name kartının dönem borcundan $amount kaldı; son ödeme yarın.';
  }

  @override
  String get notifCardDueTitle => 'Kart son ödeme günü!';

  @override
  String notifCardDueBody(String name, String amount) {
    return '$name kartının dönem borcundan $amount kaldı; son ödeme bugün.';
  }

  @override
  String get linkHintCardPayment => 'Kart ödemesi olabilir';

  @override
  String get tekCekim => 'Tek çekim';

  @override
  String taksitSecenek(int count) {
    return '$count taksit';
  }

  @override
  String taksitOzeti(String amount) {
    return 'Her ay $amount; ilk taksit bu tarihte, sonrakiler her ay aynı gün.';
  }

  @override
  String get bankImportCardStatement => 'Kredi kartı ekstresi';

  @override
  String get bankImportCardPeriod => 'Kredi kartı dönem içi hareketleri';

  @override
  String get bankImportCardSign =>
      'Kart kuralı uygulandı: artı tutarlar harcama, eksiler ödeme/iade.';

  @override
  String get bankImportCardSavesToWallet =>
      'Aktarınca bu bilgiler kartın son ekstresi olarak kaydedilir.';

  @override
  String get bankImportCardTargetNotCard =>
      'Bu bir kredi kartı ekstresi ama hedef bir kart değil: harcamalar yine gider yazılır, ancak kesim/son ödeme bilgisi saklanmaz. Kartı Cüzdanlar\'da ilgili cüzdanın altına ekleyip ona aktarabilirsin.';

  @override
  String get bankImportDoneCardSaved =>
      'Kartın ekstre bilgisi güncellendi (dönem borcu, asgari, son ödeme).';

  @override
  String get kkOdemeYontemi => 'Nereden ödendi?';

  @override
  String get kkKartiSil => 'Kartı sil';

  @override
  String get kkDesteyiAc => 'Kartları göster';

  @override
  String get kkDesteyiKapat => 'Kartları topla';

  @override
  String get kkCevirAciklama =>
      'Geçmişi ve bakiyesiyle birlikte kart olur; seçtiğin cüzdanın içine taşınır.';

  @override
  String get kkBagliCuzdanGerekli => 'Kartın bağlı olacağı cüzdanı seç.';

  @override
  String get kkBagliCuzdanAciklama =>
      'Kart bu cüzdanın içinde görünür; \"Öde\" de varsayılan olarak buradan öder.';

  @override
  String kkCuzdanKartliSilinemez(String name, int count) {
    return '$name cüzdanına bağlı $count kredi kartı var. Önce kartları sil ya da başka bir cüzdana bağla.';
  }

  @override
  String get kkCuzdanaBagla => 'Bir cüzdana bağla';

  @override
  String get kkKartEklendi => 'Kredi kartı eklendi';

  @override
  String get kkEkstreyiGir => 'Ekstreyi gir';

  @override
  String get kkKartiOde => 'Kartı öde';

  @override
  String get kkBaskaTutar => 'Başka tutar';

  @override
  String get kkOdemeKaynagi => 'Hangi hesaptan?';

  @override
  String kkOdemeSonrasi(String name, String amount) {
    return 'Ödemeden sonra $name: $amount';
  }

  @override
  String kkTutariOde(String amount) {
    return '$amount öde';
  }

  @override
  String get kkOdemeKaydedildi => 'Kart ödemesi kaydedildi';

  @override
  String kkKartlarDusulunce(String amount) {
    return 'Kart ödemeleri düşülünce: $amount';
  }

  @override
  String kkKullanilabilirLimitSatiri(String amount) {
    return 'Kullanılabilir limit: $amount';
  }

  @override
  String kkEkstreDonemEtiketi(String range) {
    return 'Ekstre · $range';
  }

  @override
  String get kkBuEkstre => 'Bu ekstre';

  @override
  String get kkOncekiEkstre => 'Önceki ekstre';

  @override
  String get kkDahaFazlaAyrinti =>
      'Daha fazla ayrıntı (banka, son 4 hane, limit, son ekstre)';

  @override
  String get kkKartRengi => 'Kart rengi';

  @override
  String get onboardingCardRailTitle => 'Kartın bu cüzdanın içinde';

  @override
  String get onboardingCardRailDesc =>
      'Hesap ile kartları arasında bu düğmeyle geç. Kart harcaması eklemek için karta geçmen de gerekmez: gider formunda \"Nereden ödendi?\" ile kartı seç.';

  @override
  String get kkRaporKartlarDahil => 'Kart harcamalarını dahil et';

  @override
  String kkRaporKartlarAcik(int count) {
    return '$count kartın harcamaları analizde; bakiye çizgisi yalnız hesabın.';
  }

  @override
  String kkRaporKartlarKapali(int count) {
    return '$count bağlı kartın harcamaları ayrı tutuluyor.';
  }

  @override
  String bankImportSimilarTitle(String category) {
    return '“$category” benzerlerine de uygulansın mı?';
  }

  @override
  String bankImportSimilarBody(int count) {
    return 'Bu satıra benzeyen $count kategorisiz satır var. Aynı türden harcama olmayanların işaretini kaldır.';
  }

  @override
  String get bankImportSimilarOnlyThis => 'Yalnız bu satır';

  @override
  String bankImportBulkTitle(String category) {
    return '“$category” kategorisini uygula';
  }

  @override
  String get bankImportBulkBody =>
      'Kategori işaretli satırlara uygulanır. Dışarıda kalmasını istediklerinin işaretini kaldır.';

  @override
  String bankImportBulkOverwriteNote(int count) {
    return 'İşaretli $count satırın mevcut kategorisi değişecek.';
  }

  @override
  String bankImportBulkApply(int count) {
    return '$count satıra uygula';
  }

  @override
  String get bankImportBulkNothingTitle => 'Uygulanacak satır yok';

  @override
  String get bankImportExitTitle => 'İçe aktarımdan çıkılsın mı?';

  @override
  String get bankImportExitBody =>
      'Henüz hiçbir şey kaydedilmedi. Çıkarsan bu ekstre için yaptığın seçimler ve kategoriler kaybolur.';

  @override
  String get bankImportExitConfirm => 'Çık';

  @override
  String get bankImportSelectVisible => 'Görünenleri seç (tekrarlar hariç)';

  @override
  String get bankImportDeselectVisible => 'Görünenlerin seçimini kaldır';

  @override
  String get bankImportSetTypeExpenseTitle => 'Tümü gider yapılsın mı?';

  @override
  String get bankImportSetTypeIncomeTitle => 'Tümü gelir yapılsın mı?';

  @override
  String bankImportSetTypeBody(int count) {
    return '$count satırın türü değişecek. Bu satırların kategorisi yeniden tahmin edilir; onlarda elle seçtiğin kategoriler kaybolur.';
  }

  @override
  String get bankImportSetTypeConfirm => 'Çevir';

  @override
  String get bankImportStepMissingTitle => 'Kategorisiz satırlar var';

  @override
  String get bankImportStepMissingShow => 'Kategorisizleri göster';

  @override
  String get bankImportUndoTitle => 'İçe aktarım geri alınsın mı?';

  @override
  String bankImportUndoWillRemove(int count) {
    return 'Az önce eklenen $count işlem silinir.';
  }

  @override
  String bankImportUndoWillRevert(int count) {
    return 'Tutarı düzeltilen $count kayıt eski tutarına döner.';
  }

  @override
  String get bankImportUndoWillCard =>
      'Kartın son ekstre bilgisi içe aktarım öncesine döner.';

  @override
  String get bankImportUndoWillKeepLinked =>
      'Bu arada bir kayda bağladığın satırlar silinmez, yerinde kalır.';

  @override
  String get bankImportUndoRunning => 'Geri alınıyor…';

  @override
  String get bankImportUndoDoneTitle => 'İçe aktarım geri alındı';

  @override
  String bankImportUndoRemoved(int count) {
    return '$count işlem silindi.';
  }

  @override
  String bankImportUndoReverted(int count) {
    return '$count kayıt eski tutarına döndü.';
  }

  @override
  String get bankImportUndoCardReverted =>
      'Kartın son ekstre bilgisi geri alındı.';

  @override
  String bankImportUndoKept(int count) {
    return 'Bir kayda bağladığın $count satır yerinde bırakıldı; onları bağlı kaydı silerek kaldırabilirsin.';
  }

  @override
  String get bankImportUndoNothing => 'Geri alınacak bir şey kalmamıştı.';

  @override
  String get bankImportSynced => 'Bankayla eşitlendi';

  @override
  String get bankImportRawEmpty => '(boş)';

  @override
  String get bankImportAccountOnCard =>
      'Bu bir hesap ekstresi (satır satır bakiye var) ama hedef bir kredi kartı. Hesap hareketleri kartın defterine yazılırsa kart borcu yanlış görünür.';

  @override
  String get bankImportAllKnownTitle => 'Bu ekstrede yeni hareket yok';

  @override
  String bankImportAllKnownBody(int count) {
    return '$count hareketin hepsi bu cüzdanda zaten kayıtlı. Ekstre büyük olasılıkla daha önce aktarıldı.';
  }

  @override
  String get bankImportAllKnownShowRows => 'Satırları yine de göster';

  @override
  String bankImportClosingTitle(String date) {
    return 'Ekstreye göre $date bakiyesi';
  }

  @override
  String get bankImportClosingMatched =>
      'Cüzdan o gün bankayla birebir tutuyor.';

  @override
  String bankImportClosingLedger(String ledger, String diff) {
    return 'Cüzdanın o günkü bakiyesi $ledger — bankayla $diff fark var.';
  }

  @override
  String get bankImportClosingSync => 'Bankayla eşitle';

  @override
  String bankImportClosingSyncBody(String diff) {
    return 'Cüzdanın açılış bakiyesi $diff kaydırılır; böylece ekstrenin son gününde bankayla tutar. Hareketlerin hiçbiri değişmez.';
  }

  @override
  String get bankImportFilterToCheck => 'Kontrol et';

  @override
  String bankImportKnownHidden(int count) {
    return '$count satır zaten kayıtlı olduğu için gizlendi';
  }

  @override
  String bankImportKnownShown(int count) {
    return 'Zaten kayıtlı $count satır gösteriliyor';
  }

  @override
  String get bankImportKnownHide => 'Gizle';

  @override
  String get bankImportRecentTitle => 'Son içe aktarımlar';

  @override
  String bankImportRecentRow(String wallet, int count) {
    return '$wallet · $count işlem';
  }

  @override
  String get bankImportShowAdded => 'Eklenenleri işlemlerde göster';

  @override
  String get bankImportSourceBankTag =>
      'Yalnız bankanın etiketinden tahmin edildi — kontrol et';

  @override
  String get bankImportSourceHistory => 'Geçmişinden öğrenildi';

  @override
  String bankImportSuggestionRows(int count) {
    return '$count satır';
  }

  @override
  String get bankImportSummaryMore => 'Ayrıntıları göster';

  @override
  String get bankImportSummaryLess => 'Ayrıntıları gizle';

  @override
  String bankImportTargetElsewhere(int count, String wallet) {
    return 'Bu ekstredeki $count hareket “$wallet” cüzdanında zaten kayıtlı. Yanlış cüzdanı mı seçtin?';
  }

  @override
  String bankImportTargetCard(String last4, String wallet) {
    return 'Bu ekstre •••• $last4 kartına ait: “$wallet”.';
  }

  @override
  String bankImportTargetAccount(String wallet) {
    return 'Bu bir hesap ekstresi (satır satır bakiye var) ama hedef bir kredi kartı. Kartın ödendiği hesap: “$wallet”.';
  }

  @override
  String bankImportTargetUsedBefore(String wallet) {
    return 'Bu biçimdeki ekstreyi geçen sefer “$wallet” cüzdanına aktarmıştın.';
  }

  @override
  String bankImportTargetSwitch(String wallet) {
    return 'Hedefi “$wallet” yap';
  }

  @override
  String bankImportTotals(String expense, String income) {
    return 'Eklenecek: gider $expense · gelir $income';
  }

  @override
  String get bankImportUndoLaterNote =>
      'Yalnız bu içe aktarımın eklediği işlemler silinir; o sırada tutarı düzeltilen kayıtlar ve kart ekstresi bilgisi olduğu gibi kalır.';

  @override
  String get bankImportVerifiedChip => 'Doğrulandı';

  @override
  String bankImportUndoWillRemoveBatch(int count) {
    return 'Bu içe aktarımın eklediği $count işlem silinir.';
  }

  @override
  String get analysisNoFlowTitle => 'Bu dönemde gelir ya da gider yok';

  @override
  String analysisNoFlowMoved(int count) {
    return '$count para taşıma hareketi var (transfer, borç, birikim). Bunlar gelir–gidere sayılmaz.';
  }

  @override
  String get analysisNoFlowCards => 'Kart harcamaları ayrı tutuluyor.';

  @override
  String get analysisIncludeMoved => 'Para taşımayı dahil et';

  @override
  String get analysisIncludeCards => 'Kartları dahil et';

  @override
  String analysisJumpToPeriod(String period) {
    return '$period dönemine git';
  }

  @override
  String get analysisPeriodEmptyBody =>
      'Bu aralıkta kayıt yok. Başka bir döneme geçebilirsin.';

  @override
  String get reportModeExpense => 'Gider';

  @override
  String get reportModeIncome => 'Gelir';

  @override
  String get filterTypeSection => 'Tür';

  @override
  String get filterTypeAll => 'Tümü';

  @override
  String insightPeriodLinkTitle(String period) {
    return '$period özeti';
  }

  @override
  String insightPeriodLinkValue(String expense, String net) {
    return 'Gider $expense · Net $net';
  }

  @override
  String get insightPeriodLinkHint => 'Kategoriler, grafik ve yerler Rapor\'da';

  @override
  String get insightBudgetAlertTitle => 'Bütçe uyarısı';

  @override
  String insightBudgetExceeded(String label) {
    return '$label aşıldı';
  }

  @override
  String insightBudgetNear(String label, String percent) {
    return '$label $percent';
  }

  @override
  String get insightBudgetAlertHint => 'Bütçelerin tamamı Rapor\'da';

  @override
  String get insightRecurringIndependent =>
      'Dönemden bağımsız: tüm geçmişine bakılarak bulundu.';

  @override
  String get reportScopeLead => 'Dahil:';

  @override
  String reportScopeCards(int count) {
    return 'Kart harcamaları · $count';
  }

  @override
  String reportScopeMoved(int count) {
    return 'Para taşıma · $count';
  }

  @override
  String get txSearchOpen => 'İşlem ara';

  @override
  String get txSearchClose => 'Aramayı kapat';

  @override
  String get filterMovedSection => 'Para taşıma hareketleri';

  @override
  String get filterMovedHint =>
      'Transfer, kart ödemesi, borç ve birikim hareketleri. Harcama sayılmazlar ama bakiyeyi değiştirirler.';

  @override
  String get filterMovedShow => 'Göster';

  @override
  String get filterMovedHide => 'Gizle';

  @override
  String get filterMovedOnly => 'Yalnız bunlar';

  @override
  String get filterMovedHiddenChip => 'Para taşıma gizli';

  @override
  String get filterMovedOnlyChip => 'Yalnız para taşıma';

  @override
  String get filterMoreSection => 'Diğer';

  @override
  String get filterReceiptToggle => 'Yalnız fişi olanlar';

  @override
  String get filterImportedToggle => 'Yalnız ekstreden gelenler';

  @override
  String get filterImportedHint => 'Banka ekstresinden içe aktarılan kayıtlar.';

  @override
  String get filterReceiptChip => 'Fişli';

  @override
  String get filterImportedChip => 'Ekstreden';

  @override
  String get txCollapseAllDays => 'Tümünü daralt';

  @override
  String get txExpandAllDays => 'Tümünü genişlet';

  @override
  String get periodSheetTitle => 'Dönem';

  @override
  String get periodUnitDay => 'Gün';

  @override
  String get periodUnitWeek => 'Hafta';

  @override
  String get periodUnitBiweek => '2 Hafta';

  @override
  String get periodUnitMonth => 'Ay';

  @override
  String get periodWeekStartLabel => 'Hafta hangi gün başlasın?';

  @override
  String get periodBiweekAnchorLabel => 'Ödeme günü';

  @override
  String get periodBiweekHint =>
      'İki haftalık dönemler bu tarihten itibaren sayılır.';

  @override
  String get periodMonthStartLabel => 'Ay, ayın kaçında başlasın?';

  @override
  String get periodMonthStartHint =>
      'Maaşın 15\'inde yatıyorsa 15 seç: dönem 15\'i ile ertesi ayın 14\'ü olur.';

  @override
  String periodCurrentPreview(String label) {
    return 'Bu dönem: $label';
  }

  @override
  String get periodQuickSection => 'Hazır aralıklar';

  @override
  String get periodChooseDate => 'Seç';

  @override
  String get settingsPeriodHeader => 'Dönem';

  @override
  String reportBudgetProrated(int days) {
    return 'Aylık limitler bu $days günlük döneme orantılandı.';
  }

  @override
  String reportBudgetMonths(int months) {
    return 'Aylık limitler $months aya göre hesaplandı.';
  }

  @override
  String get systemTagSavingsDeposit => 'Birikime aktarım';

  @override
  String get systemTagSavingsWithdraw => 'Birikimden aktarım';

  @override
  String get potUnavailableMessage =>
      'Kasanın bakiyesi bu işlem için yetmiyor; hiçbir şey kaydedilmedi.';

  @override
  String odemeKasadanBaslik(String name) {
    return 'Kasadan: $name';
  }

  @override
  String kasaBakiyesi(String amount) {
    return 'Bakiye $amount · cüzdana dokunulmaz';
  }

  @override
  String alimKasadanDusulecek(String name, String amount) {
    return 'Tutar “$name” kasasından düşülecek (bakiye $amount); cüzdan ve defter değişmez.';
  }

  @override
  String kasaYetersizUyari(String amount) {
    return 'Kasada yalnız $amount var. Tutarı düşür ya da başka bir kaynak seç.';
  }

  @override
  String get satisHedefiBaslik => 'Para nereye?';

  @override
  String get satisHedefiCuzdan => 'Cüzdana';

  @override
  String kasaBakiyeSade(String amount) {
    return 'Bakiye $amount';
  }

  @override
  String get kasaTutar => 'Tutar';

  @override
  String get kasaParaEkle => 'Para ekle';

  @override
  String get kasaParaCek => 'Para çek';

  @override
  String get kasaParaEkleAciklama =>
      'Cüzdandan kasaya aktarılır; gider sayılmaz.';

  @override
  String get kasaParaCekAciklama =>
      'Kasadan cüzdana aktarılır; gelir sayılmaz.';

  @override
  String kasalarArasiAciklama(String name) {
    return '“$name” kasasına aktarılır; cüzdan değişmez.';
  }

  @override
  String get kasaDuzenle => 'Kasayı düzenle';

  @override
  String get kasayiKapat => 'Kasayı kapat';

  @override
  String kasayiKapatAciklama(String amount) {
    return 'Kalan $amount cüzdana döner';
  }

  @override
  String kasayiKapatOnayBaslik(String name) {
    return '“$name” kapatılsın mı?';
  }

  @override
  String kasayiKapatOnayMesaj(String amount) {
    return 'Kasadaki $amount cüzdana aktarılır. Hemen ardından geri alabilirsin.';
  }

  @override
  String get yeniKasa => 'Yeni nakit kasası';

  @override
  String get kasaOlustur => 'Kasayı oluştur';

  @override
  String get kasaAciklama =>
      'Birikimini nakit olarak ayrı tut: acil durum fonu, tatil parası… Varlık alırken bu kasadan ödeyebilir, satışta parayı buraya koyabilirsin.';

  @override
  String get kasaAdi => 'Kasa adı';

  @override
  String get kasaAdiOrnek => 'ör. Acil durum fonu';

  @override
  String get kasaAdiGerekli => 'Kasaya bir ad ver';

  @override
  String get kasaAcilisTutari => 'Başlangıç tutarı (isteğe bağlı)';

  @override
  String get kasaAcilisTutariYardim => 'Cüzdandan kasaya aktarılır';

  @override
  String get kasaHedefi => 'Hedef (isteğe bağlı)';

  @override
  String get kasaHedefYok => 'Hedefe bağlama';

  @override
  String kasayaParaEkleBaslik(String name) {
    return '$name · para ekle';
  }

  @override
  String kasadanParaCekBaslik(String name) {
    return '$name · para çek';
  }

  @override
  String get nakitKasalari => 'Nakit kasaları';

  @override
  String get kasaEkleKisa => 'Kasa';

  @override
  String get kasaYokAciklama =>
      'Birikimin hepsi varlık olmak zorunda değil. Bir kasa aç, parayı nakit tut; alımları oradan yap.';

  @override
  String get yeniNakitKasasiEkle => 'Nakit kasası';

  @override
  String get yatirimTuruNakit => 'Nakit';

  @override
  String get menuCash => 'Kasa';

  @override
  String get kasaBaslat => 'Nakit kasası aç';

  @override
  String get baglaKasaya => 'Nakit kasasına aktarım';

  @override
  String get baglaKasayaAciklama =>
      'Bu para birikim kasana gitti; gider sayılmaz.';

  @override
  String get baglaKasaSec => 'Hangi kasaya?';

  @override
  String get baglaYeniKasa => 'Yeni kasa aç';

  @override
  String get baglaYeniKasaAciklama => 'Satırın tutarıyla açılır';

  @override
  String kasaAcilisSatirdan(String amount) {
    return 'Başlangıç: $amount (defterdeki satırdan)';
  }

  @override
  String get reportViewLine => 'Çizgi görünümü';

  @override
  String get reportTrendVsPrevious => 'önceki dönemin aynı noktasına göre';

  @override
  String reportTrendBalanceStart(Object amount) {
    return 'Dönem başı $amount';
  }

  @override
  String reportFocusShareExpense(Object percent) {
    return 'Giderlerdeki payı $percent';
  }

  @override
  String reportFocusShareIncome(Object percent) {
    return 'Gelirlerdeki payı $percent';
  }

  @override
  String reportPreviousAmount(Object amount) {
    return 'Önceki dönem $amount';
  }

  @override
  String get reportFocusClear => 'Kategori odağını kaldır';

  @override
  String reportTrendSemantics(Object metric, Object period, Object amount) {
    return '$metric çizgisi, $period: $amount. Ara değerler için çizgiye dokun.';
  }

  @override
  String reportTrendTooltipPrevious(Object amount) {
    return 'Önceki: $amount';
  }

  @override
  String reportSeeTransactions(Object count) {
    return 'İşlemleri gör ($count)';
  }

  @override
  String get reportDrillHint => 'Kategoriye dokun, içine in';

  @override
  String get reportBreadcrumbUp => 'Bir üst seviyeye çık';

  @override
  String reportDonutSemantics(Object count, Object total) {
    return 'Kategori halkası: $count kalem, toplam $total';
  }

  @override
  String reportDrillInto(Object name) {
    return '$name kırılımına in';
  }

  @override
  String get reportTrendThisPeriod => 'Bu dönem';

  @override
  String netWorthHead(Object amount) {
    return 'Net $amount';
  }

  @override
  String netPartAccounts(Object amount) {
    return 'hesaplar $amount';
  }

  @override
  String netPartCards(Object amount) {
    return 'kart borcu $amount';
  }

  @override
  String netPartLoans(Object amount) {
    return 'krediler $amount';
  }

  @override
  String netPartReceivables(Object amount) {
    return 'alacaklar $amount';
  }

  @override
  String debtBreakdownLine(Object loans, Object cards) {
    return 'krediler $loans · kartlar $cards';
  }

  @override
  String get debtCardsSectionHint =>
      'Kart borcu kartın kendi kayıtlarından gelir. Harcamalar ve ayarlar kartın içinde.';

  @override
  String get debtLoansSectionTitle => 'Krediler ve kişisel borçlar';

  @override
  String get debtLoansEmptyCompact => 'Kayıtlı kredi ya da kişisel borç yok.';

  @override
  String get kkGuncelBorcKisa => 'Güncel borç';

  @override
  String get kkEkstreOdendi => 'Ekstre ödendi';

  @override
  String get kkBuDonemHarcanan => 'Bu dönem harcanan';

  @override
  String kkKalanDonemSatiri(Object amount) {
    return 'Kalan dönem borcu $amount';
  }

  @override
  String get debtCardInstallmentWarn =>
      'Kartla taksitli bir alışveriş mi? Onu kartın harcaması olarak gir: borç olarak da girilirse aynı para iki kez sayılır.';

  @override
  String get debtCardInstallmentAction => 'Kart harcaması olarak gir';

  @override
  String installmentSectionTitle(Object no, Object count) {
    return 'Taksitler · $no/$count';
  }

  @override
  String installmentDeleteAll(Object count) {
    return 'Tüm taksitleri sil ($count)';
  }

  @override
  String get installmentThisOne => 'bu taksit';

  @override
  String installmentMissingHint(Object missing) {
    return 'Bu alışverişin $missing taksiti silinmiş.';
  }

  @override
  String get kkTaksitliAlisverisler => 'Süren taksitli alışverişler';

  @override
  String kkTaksitPlanSatiri(Object left, Object amount) {
    return '$left taksit kaldı · $amount';
  }

  @override
  String get kkBilinmiyor => 'bilinmiyor';

  @override
  String get kkDonemBorcuBilinmiyor => 'Dönem borcu bilinmiyor · ekstreyi gir';

  @override
  String kkOdemeNotu(Object date) {
    return 'ödeme $date';
  }

  @override
  String get kkOdemeGunu => 'Ödeme günü';

  @override
  String get dun => 'Dün';

  @override
  String get kaydetVeYeni => 'Kaydet ve yeni';

  @override
  String kaydedildiOzet(String baslik, String tutar) {
    return 'Kaydedildi: $baslik · $tutar';
  }

  @override
  String get sonKullanilanlar => 'Son kullanılanlar';

  @override
  String get yenidenEkle => 'Yeniden ekle';

  @override
  String get yenidenEkleAciklama =>
      'Aynı içerikle, bugünün tarihiyle yeni kayıt';

  @override
  String get giderEkle => 'Gider ekle';

  @override
  String get gelirEkle => 'Gelir ekle';

  @override
  String get gelismisLabel => 'Gelişmiş';

  @override
  String get borcGelismisOzetBanka =>
      'Faiz oranıyla hesapla · KKDF/BSMV · gecikme faizi';

  @override
  String get borcGelismisOzetTaksitli => 'Vade farkı yöntemi · gecikme faizi';

  @override
  String get borcGelismisOzetDiger => 'Gecikme faizi';

  @override
  String get borcEtkiDefterKisa => 'Defterde var';

  @override
  String get borcEtkiUrunKisa => 'Ürün / hizmet';

  @override
  String get borcEtkiSecin => 'Bu borç karşılığında ne aldığını seç';

  @override
  String get bankImportReviewWarningShort =>
      'Veriler otomatik algılandı; eklemeden önce kontrol et.';

  @override
  String bankImportUncategorizedBlockedShort(int count) {
    return 'Seçili $count satırın kategorisi yok; kategori seçilmeden eklenemez.';
  }

  @override
  String get bankImportAssignBlocked => 'Kategori ata';

  @override
  String bankImportGroupTile(int count) {
    return 'Benzer $count grubu tek seferde kategorile';
  }

  @override
  String get bankImportEditRowTitle => 'Satırı düzenle';

  @override
  String get bankImportEditTypeNote =>
      'Tür değişince kategori yeniden tahmin edilir.';

  @override
  String get cuzdanaGec => 'Bu cüzdana geç';

  @override
  String get kartaGec => 'Bu karta geç';

  @override
  String get aktifCuzdan => 'Aktif cüzdan';

  @override
  String get aktifCuzdanSilinemez =>
      'Aktif cüzdan silinemez — önce başka bir cüzdana geç';

  @override
  String get transferKisa => 'Transfer';

  @override
  String get ekstreAktarKisa => 'Ekstre aktar';

  @override
  String get yeniCuzdanKisa => 'Yeni cüzdan';

  @override
  String get butceyiDuzenle => 'Bütçeyi düzenle';

  @override
  String get sablonuDuzenle => 'Şablonu düzenle';

  @override
  String get yeniDuzenliIslem => 'Yeni düzenli işlem';

  @override
  String get sablonBaslikLabel => 'Başlık';

  @override
  String get tekrarSikligiLabel => 'Tekrar sıklığı';

  @override
  String get sonrakiVadeLabel => 'Sonraki vade';

  @override
  String get ilkVadeLabel => 'İlk vade';

  @override
  String get birdenCokSec => 'Birden çok seç';

  @override
  String get birdenCokSecAciklama =>
      'Seçtiklerinin kategorisini topluca değiştir';

  @override
  String nIslemSecili(int count) {
    return '$count seçili';
  }

  @override
  String get kategoriDegistir => 'Kategori değiştir';

  @override
  String get topluKategoriOnayBaslik => 'Kategori değiştirilsin mi?';

  @override
  String topluKategoriOnayMesaj(int count, String kategori) {
    return '$count işlemin kategorisi “$kategori” olacak.';
  }

  @override
  String topluKategoriAtlanan(int count) {
    return '$count işlem türü uymadığı için değişmeyecek.';
  }

  @override
  String get secimiKapat => 'Seçimi kapat';

  @override
  String blocMsgTxLoadFailed(String hata) {
    return 'İşlemler yüklenirken hata oluştu: $hata';
  }

  @override
  String blocMsgTxAddFailed(String hata) {
    return 'İşlem eklenirken hata oluştu: $hata';
  }

  @override
  String blocMsgTxAdded(String baslik) {
    return '$baslik başarıyla eklendi';
  }

  @override
  String get blocMsgTxSystemLocked =>
      'Sistem işlemi; ilgili kayıttan yönetilir';

  @override
  String get blocMsgTxMoveBlocked =>
      'Bu kayıt başka bir kayda bağlı; cüzdanı değiştirilemez';

  @override
  String blocMsgTxUpdateFailed(String hata) {
    return 'İşlem güncellenirken hata oluştu: $hata';
  }

  @override
  String blocMsgTxMoved(String baslik) {
    return '$baslik diğer cüzdana taşındı';
  }

  @override
  String blocMsgTxUpdated(String baslik) {
    return '$baslik başarıyla güncellendi';
  }

  @override
  String blocMsgTxCategoryChanged(int count) {
    return '$count işlemin kategorisi değiştirildi';
  }

  @override
  String blocMsgTxCategoryChangePartial(String hata) {
    return 'Bazı işlemlerin kategorisi değiştirilemedi: $hata';
  }

  @override
  String blocMsgTxNotFound(String hata) {
    return 'İşlem bulunamadı: $hata';
  }

  @override
  String blocMsgTxDeleteFailed(String hata) {
    return 'İşlem silinirken hata oluştu: $hata';
  }

  @override
  String blocMsgTxDeleted(String baslik) {
    return '$baslik silindi';
  }

  @override
  String get blocMsgTxBulkDeleteFailed => 'İşlemler silinemedi';

  @override
  String blocMsgTxBulkDeleteFailedDetail(String hata) {
    return 'İşlemler silinemedi: $hata';
  }

  @override
  String blocMsgTxBulkDeleted(String etiket, int count) {
    return '$etiket: $count işlem silindi';
  }

  @override
  String blocMsgTxBulkDeletePartial(String hata) {
    return 'Bazı işlemler silinemedi: $hata';
  }

  @override
  String get blocMsgTxSyncWarning =>
      'Bakiye eşitlenemedi; cüzdan ekranına dönüp tekrar dene.';

  @override
  String blocMsgWalletCreateFailed(String hata) {
    return 'Cüzdan oluşturulamadı: $hata';
  }

  @override
  String blocMsgWalletSetActiveFailed(String hata) {
    return 'Aktif cüzdan ayarlanamadı: $hata';
  }

  @override
  String blocMsgWalletUpdateFailed(String hata) {
    return 'Cüzdan güncellenemedi: $hata';
  }

  @override
  String get blocMsgWalletCleanupFailed =>
      'Cüzdan verileri temizlenemedi, silme iptal edildi';

  @override
  String blocMsgWalletDeleteFailed(String hata) {
    return 'Cüzdan silinemedi: $hata';
  }

  @override
  String blocMsgWalletSwitchFailed(String hata) {
    return 'Aktif cüzdan değiştirilemedi: $hata';
  }

  @override
  String get blocMsgCashWarningSuffix =>
      ' (Uyarı: bakiye güncellenemedi, cüzdanı yenile.)';

  @override
  String get blocMsgDebtAdded => 'Borç başarıyla eklendi.';

  @override
  String get blocMsgDebtPaymentSaved => 'Ödeme kaydedildi.';

  @override
  String get blocMsgDebtPaymentUpdated => 'Ödeme güncellendi.';

  @override
  String get blocMsgDebtPaymentDeleted => 'Ödeme silindi.';

  @override
  String get blocMsgDebtUpdated => 'Borç güncellendi.';

  @override
  String get blocMsgDebtDeleted => 'Borç silindi.';

  @override
  String get blocMsgDebtAdoptFailed =>
      'Seçilen işlem bağlanamadı: bu arada değişmiş, silinmiş ya da başka bir kayda bağlanmış olabilir. Kayıt eklenmedi.';

  @override
  String get blocMsgDebtAdoptedPaymentLocked =>
      'Bu ödeme ekstredeki bir satıra bağlı: tutarı ve tarihi o satırdan gelir. Yanlış satırsa ödemeyi silip doğru satırla yeniden ekle.';

  @override
  String get blocMsgDebtAdoptedPrincipalLocked =>
      'Bu borcun anaparası ekstredeki bir satıra bağlı: tutarı ve başlangıç tarihi o satırdan gelir. Diğer bilgiler kaydedilmedi; yanlış satırsa borcu silip doğru satırla yeniden ekle.';

  @override
  String get blocMsgReceivableAdded => 'Alacak başarıyla eklendi.';

  @override
  String get blocMsgReceivableUpdated => 'Alacak güncellendi.';

  @override
  String get blocMsgReceivableDeleted => 'Alacak silindi.';

  @override
  String get blocMsgReceivableMarkedPaid => 'Alacak ödendi olarak işaretlendi.';

  @override
  String blocMsgImportPickFailed(String hata) {
    return 'Dosya seçilemedi: $hata';
  }

  @override
  String blocMsgImportReadFailed(String hata) {
    return 'Dosya okunamadı: $hata';
  }

  @override
  String get blocMsgImportEmptyFile => 'Dosya boş veya okunamadı.';

  @override
  String blocMsgImportMappingFailed(String hata) {
    return 'Eşleme uygulanamadı: $hata';
  }

  @override
  String blocMsgImportCategoriesFailed(String hata) {
    return 'Kategoriler okunamadı: $hata';
  }

  @override
  String blocMsgImportWalletSwitchFailed(String hata) {
    return 'Cüzdan değiştirilemedi: $hata';
  }

  @override
  String get blocMsgBackupFailed => 'Yedekleme işlemi tamamlanamadı.';

  @override
  String get borcEkle => 'Borç ekle';

  @override
  String get alacakEkle => 'Alacak ekle';

  @override
  String bankImportInstallmentNote(int count, String son) {
    return 'Kalan $count taksit de ileri tarihe yazılacak (son: $son)';
  }

  @override
  String bankImportDoneFutureInstallments(int count) {
    return '$count kalan taksit ileri tarihe yazıldı.';
  }

  @override
  String get linkHintCardPaymentIn => 'Kendi hesabından ödeme olabilir';

  @override
  String get linkHintOwnTransfer =>
      'Kendi hesabına aktarım mı? Değilse gider kalır';

  @override
  String get bankImportTransferAskCard => 'Kart ödemesi mi?';

  @override
  String get bankImportTransferAskOwnPayment => 'Kendi hesabından ödeme mi?';

  @override
  String get bankImportTransferAskOwnTransfer => 'Kendi hesabına aktarım mı?';

  @override
  String bankImportTransferLinkTo(String cuzdan) {
    return '$cuzdan ile bağla';
  }

  @override
  String bankImportTransferChip(String cuzdan) {
    return 'Transfer · $cuzdan';
  }

  @override
  String get bankImportTransferUnmark => 'Bağlamayı kaldır';

  @override
  String bankImportDoneLinkedTransfers(int count) {
    return '$count satır transfer olarak bağlandı.';
  }

  @override
  String get hedefVarlikEkleKisa => 'Varlık';

  @override
  String periodUnitCurrent(String unit) {
    return 'Dönem birimi: $unit';
  }

  @override
  String get periodUnitChangeInSettings => 'Ayarlar\'dan değiştir';

  @override
  String bankImportRecentRange(String range) {
    return 'İşlem tarihleri: $range';
  }

  @override
  String bankImportRecentImportedAt(String when) {
    return 'Aktarıldı: $when';
  }

  @override
  String get txDayAdd => 'Bu güne işlem ekle';

  @override
  String txDayEmptyRow(String date) {
    return '$date · kayıt yok';
  }

  @override
  String get kategoriSirala => 'Sırala';

  @override
  String get kategoriSiralaAciklama =>
      'Tutamaçtan sürükleyerek sırala. Sıra bütün cüzdanlarda aynıdır.';

  @override
  String kategoriSiralaTutamac(String name) {
    return '$name: sürükleyerek taşı';
  }

  @override
  String get portfoyVarligaGore => 'Varlığa göre';

  @override
  String get portfoyTureGore => 'Türe göre';

  @override
  String get portfoyToplam => 'Toplam';

  @override
  String get portfoyDiger => 'Diğer';

  @override
  String get portfoyTurAltin => 'Altın';

  @override
  String get portfoyTurHisse => 'Hisse';

  @override
  String get portfoyTurOzel => 'Özel';

  @override
  String get portfoyTurNakit => 'Nakit';

  @override
  String portfoyTumunuGoster(int count) {
    return 'Tümünü göster ($count)';
  }

  @override
  String get portfoyDahaAzGoster => 'Daha az göster';

  @override
  String get birikimSirala => 'Sırala';

  @override
  String get birikimSiralaDeger => 'Değer';

  @override
  String get birikimSiralaTarih => 'Tarih';

  @override
  String get birikimSiralaAd => 'Ad';

  @override
  String get kasaBakiyeDuzelt => 'Bakiye';

  @override
  String get kasaBakiyeDuzeltYardim =>
      'Yalnız rakamı düzeltir; cüzdana ve deftere yansımaz. Para taşımak için Para ekle / Para çek.';

  @override
  String get lotFiyatiAlis => 'Lot fiyatı (alış)';

  @override
  String get lotFiyatiAciklama =>
      'Lot × lot fiyatı toplam maliyeti doldurur. Toplamı yazarsan lot fiyatı ondan hesaplanır.';

  @override
  String katkiBirimFiyatHint(String unit) {
    return 'Alış fiyatı (1 $unit)';
  }

  @override
  String get katkiBirimFiyatGenel => 'Birim alış fiyatı';

  @override
  String get anaKasa => 'Ana kasa';

  @override
  String get anaKasaYap => 'Ana kasa yap';

  @override
  String get anaKasaYapAciklama =>
      'Alımlarda varsayılan kaynak, satışta varsayılan hedef olur.';

  @override
  String get anaKasaKaldir => 'Ana kasa işaretini kaldır';

  @override
  String anaKasaYapildiMesaji(String name) {
    return '“$name” ana kasa oldu';
  }

  @override
  String anaKasaKaldirildiMesaji(String name) {
    return '“$name” artık ana kasa değil';
  }

  @override
  String get kkSonOdemeKipiGun => 'Ayın günü';

  @override
  String get kkSonOdemeKipiFark => 'Kesimden N gün sonra';

  @override
  String get kkKesimdenKacGun => 'Kesimden kaç gün sonra';

  @override
  String kkSonOdemeOnizleme(String closing, String due) {
    return '$closing kesiminin son ödemesi: $due';
  }

  @override
  String get kkBolumTutarlar => 'Tutarlar';

  @override
  String get kkBolumFaiz => 'Faiz oranları (isteğe bağlı)';

  @override
  String get kkBolumEkstre => 'Son ekstre';

  @override
  String get kkGuncelBorcDuzeltAciklama =>
      'Kartın bugünkü toplam borcu. Değiştirirsen fark açılış bakiyesine yansır; deftere işlem yazılmaz.';

  @override
  String get kkAylikFaiz => 'Aylık akdi faiz';

  @override
  String get kkGecikmeFaizi => 'Aylık gecikme faizi';

  @override
  String get kkFaizAciklama =>
      'Yalnız tahmin için: oranlar ekstrende yazar. Deftere faiz yazılmaz, gerçek faiz ekstreden gelir.';

  @override
  String get kkFaizOraniHatasi => '0–100 arası bir oran gir';

  @override
  String get kkEkstreHenuzYok => 'Henüz ekstre girilmedi.';

  @override
  String kkEkstreOzetSatiri(String debt, String minimum) {
    return 'Dönem borcu $debt · asgari $minimum';
  }

  @override
  String kkEkstreOzetAsgarisiz(String debt) {
    return 'Dönem borcu $debt';
  }

  @override
  String kkFaizTahminiAsgari(String carried, String interest) {
    return 'Yalnız asgariyi ödersen kalan $carried için bir ayda ≈ $interest faiz işler (vergiler hariç, tahmin).';
  }

  @override
  String kkFaizTahminiOdenmezse(String carried, String interest) {
    return 'Bu dönem ödenmezse $carried için bir ayda ≈ $interest faiz işler (vergiler hariç, tahmin).';
  }

  @override
  String kkGecikmeFaiziTahmini(String minimum, String interest) {
    return 'Gecikmiş asgari $minimum için bir ayda ≈ $interest gecikme faizi (tahmin).';
  }

  @override
  String kkFaizTahminiOdemeSonrasi(String carried, String interest) {
    return 'Dönem borcundan kalan $carried için bir ayda ≈ $interest faiz işler (vergiler hariç, tahmin).';
  }

  @override
  String blocMsgTxGroupUpdated(String baslik, int count) {
    return '$baslik güncellendi ($count taksit)';
  }

  @override
  String get installmentEditAll => 'Alışverişi düzenle';

  @override
  String get installmentEditTitle => 'Taksitli alışverişi düzenle';

  @override
  String get installmentEditHint =>
      'Toplam, ad ve kategori bütün taksitlere uygulanır; tarihler değişmez.';

  @override
  String get installmentEditName => 'Alışverişin adı';

  @override
  String get installmentEditTotal => 'Toplam tutar';

  @override
  String get installmentEditCategory => 'Kategori';

  @override
  String installmentEditPreview(int count, String amount) {
    return '$count taksit × $amount';
  }

  @override
  String installmentEditPreviewUneven(int count, String amount, String last) {
    return '$count taksit: $amount, sonuncusu $last';
  }

  @override
  String get installmentEditNameRequired => 'Alışverişe bir ad ver';

  @override
  String get tutarlariGizle => 'Tutarları gizle';

  @override
  String get tutarlariGoster => 'Tutarları göster';

  @override
  String kkGecisKartaGec(String name) {
    return 'Karta geç: $name';
  }

  @override
  String kkGecisHesabaDon(String name) {
    return 'Hesaba dön: $name';
  }

  @override
  String kkGecisKartSec(int count) {
    return 'Kart seç ($count)';
  }

  @override
  String get kkGecisBaslik => 'Hesap ve kartları';

  @override
  String get kkGecisAciklama =>
      'Baktığın bağlamı seç: hesabın kendisi ya da kartlarından biri.';

  @override
  String get kkGecisHesap => 'Hesap';

  @override
  String get kkGecisAyrintilar => 'Ayrıntılar';

  @override
  String get txKategoriSec => 'Kategori seç';

  @override
  String get transferKaldirildiKategorisiz =>
      'Satır kategorisiz kaldı. İşlemi düzenleyerek kategorisini seçebilirsin.';

  @override
  String bankImportDupWillRelocate(String date, int count) {
    return 'Eklenmeyecek: eski içe aktarım bu taksiti yanlış aya yazmış. Kayıt $date tarihine taşınacak, kalan $count taksit yazılacak.';
  }

  @override
  String get bankImportDupRelocate => 'Doğru aya taşı';

  @override
  String get bankImportDupRelocateUndo => 'Taşımadan vazgeç';

  @override
  String bankImportDoneRelocated(int count) {
    return '$count eski taksit satırı doğru aya taşındı.';
  }

  @override
  String failTxAdd(String hata) {
    return 'İşlem eklenemedi: $hata';
  }

  @override
  String failTxAddMany(String hata) {
    return 'İşlemler eklenemedi: $hata';
  }

  @override
  String failTxUpdate(String hata) {
    return 'İşlem güncellenemedi: $hata';
  }

  @override
  String failTxDelete(String hata) {
    return 'İşlem silinemedi: $hata';
  }

  @override
  String failTxCount(String hata) {
    return 'İşlemler sayılamadı: $hata';
  }

  @override
  String failTxLinked(String hata) {
    return 'Bağlı işlemler alınamadı: $hata';
  }

  @override
  String failTxMove(String hata) {
    return 'İşlemler taşınamadı: $hata';
  }

  @override
  String failTxGet(String hata) {
    return 'İşlem getirilemedi: $hata';
  }

  @override
  String failTxGetMany(String hata) {
    return 'İşlemler getirilemedi: $hata';
  }

  @override
  String failTxGetGrouped(String hata) {
    return 'Gruplanmış işlemler getirilemedi: $hata';
  }

  @override
  String failReceivableAdd(String hata) {
    return 'Alacak eklenemedi: $hata';
  }

  @override
  String failReceivableDelete(String hata) {
    return 'Alacak silinemedi: $hata';
  }

  @override
  String failReceivableGetMany(String hata) {
    return 'Alacaklar getirilemedi: $hata';
  }

  @override
  String failReceivableUpdate(String hata) {
    return 'Alacak güncellenemedi: $hata';
  }

  @override
  String failDebtAdd(String hata) {
    return 'Borç eklenemedi: $hata';
  }

  @override
  String failDebtUpdate(String hata) {
    return 'Borç güncellenemedi: $hata';
  }

  @override
  String failDebtDelete(String hata) {
    return 'Borç silinemedi: $hata';
  }

  @override
  String failDebtGetMany(String hata) {
    return 'Borçlar getirilemedi: $hata';
  }

  @override
  String failWalletCreate(String hata) {
    return 'Cüzdan oluşturulamadı: $hata';
  }

  @override
  String failWalletDelete(String hata) {
    return 'Cüzdan silinemedi: $hata';
  }

  @override
  String failWalletGetMany(String hata) {
    return 'Cüzdanlar getirilemedi: $hata';
  }

  @override
  String failWalletWatch(String hata) {
    return 'Cüzdanlar dinlenemedi: $hata';
  }

  @override
  String failWalletSetActive(String hata) {
    return 'Aktif cüzdan ayarlanamadı: $hata';
  }

  @override
  String failWalletGetActive(String hata) {
    return 'Aktif cüzdan getirilemedi: $hata';
  }

  @override
  String failWalletGet(String hata) {
    return 'Cüzdan getirilemedi: $hata';
  }

  @override
  String failWalletUpdate(String hata) {
    return 'Cüzdan güncellenemedi: $hata';
  }

  @override
  String failCategoriesRead(String hata) {
    return 'Kategoriler okunamadı: $hata';
  }

  @override
  String get failBudgetLoad => 'Bütçeler yüklenemedi.';

  @override
  String get failBudgetSave => 'Bütçe kaydedilemedi.';

  @override
  String get failBudgetDelete => 'Bütçe silinemedi.';

  @override
  String get failRecurringSave => 'Düzenli işlem şablonu kaydedilemedi.';

  @override
  String get failRecurringDelete => 'Düzenli işlem şablonu silinemedi.';

  @override
  String get failRecurringGetMany => 'Düzenli işlem şablonları getirilemedi.';

  @override
  String get failRecurringMove => 'Düzenli işlem şablonları taşınamadı.';

  @override
  String get failRecurringGetPending =>
      'Bekleyen düzenli işlemler getirilemedi.';

  @override
  String get failCategoryMoveIntoSubtree =>
      'Kategori kendi alt ağacına taşınamaz';

  @override
  String get failCategoryDeleteNeedsTarget =>
      'Taşınacak kategori seçilmeden silinemez';

  @override
  String get failSymbolEmpty => 'Sembol boş olamaz';

  @override
  String get reminderNoteTemplatesUnreadable => 'şablonlar okunamadı';

  @override
  String get reminderNoteDebtsUnreadable => 'borçlar okunamadı';

  @override
  String get reminderNoteCardFailed => 'kart hatırlatması kurulamadı';

  @override
  String get reminderNoteWalletsUnreadable => 'cüzdanlar okunamadı';

  @override
  String get kkAsgariOdendi => 'Asgari ödendi';

  @override
  String unlinkPickCategoryExpense(String title, String amount) {
    return 'Bağı kalkan “$title” ($amount) artık bir gider. Kategorisini seç.';
  }

  @override
  String unlinkPickCategoryIncome(String title, String amount) {
    return 'Bağı kalkan “$title” ($amount) artık bir gelir. Kategorisini seç.';
  }

  @override
  String get firstRunTitle => 'ÇuHat\'a hoş geldin';

  @override
  String get firstRunBody =>
      'Gelirini ve giderini yaz, paranın nereye gittiğini gör.';

  @override
  String get firstRunBalanceLabel => 'Şu an ne kadar paran var?';

  @override
  String get firstRunBalanceHint => 'Bilmiyorsan boş bırak; sonra düzeltirsin.';

  @override
  String get firstRunStart => 'Başla';

  @override
  String get firstRunRestore => 'Yedeğim var';

  @override
  String get firstRunPrivacyNote =>
      'Kayıtların yalnız bu telefonda durur; sunucumuz yok.';

  @override
  String get firstRunDefaultWalletName => 'Cüzdanım';

  @override
  String get firstRunFailed => 'Cüzdan kurulamadı. Yeniden dene.';

  @override
  String get restoreBackupTitle => 'Yedekten geri yükle';

  @override
  String get restoreBackupBody =>
      'Google Drive\'daki ya da telefonundaki yedeği seç. Kayıtların olduğu gibi geri gelir.';

  @override
  String get firstRecordSaved =>
      'İlk kaydın tamam. Yazdıkça paranın nereye gittiğini göreceksin.';

  @override
  String get backupSetupTitle => 'Yedekleme';

  @override
  String get backupSetupBody =>
      'Yedeklemeyi açarsan kayıtlarının kopyası düzenli olarak kendi Google Drive\'ına alınır. İstersen dosya olarak telefonuna da kaydedebilirsin.';

  @override
  String get feedbackTitle => 'Görüş gönder';

  @override
  String get feedbackSubtitle =>
      'Sorun, istek ya da fikir — doğrudan geliştiriciye gider.';

  @override
  String feedbackMailSubject(String app, String version) {
    return '$app görüş · v$version';
  }

  @override
  String feedbackNoMailApp(String email) {
    return 'E-posta uygulaması bulunamadı. Adres kopyalandı: $email';
  }

  @override
  String get txTopCategoriesLead => 'En çok:';

  @override
  String percentValue(String sayi) {
    return '%$sayi';
  }

  @override
  String txTopCategoriesSemantics(String liste) {
    return 'En çok harcanan kategoriler: $liste. Kategori dağılımı için dokun.';
  }

  @override
  String get logReminderOfferTitle => 'Yazmayı hatırlatalım mı?';

  @override
  String logReminderOfferBody(String saat) {
    return 'Harcamayı yazmak en kolay unutulan şey. Günde bir kez, saat $saat için kısa bir hatırlatma kurabiliriz. İstediğin zaman Ayarlar > Bildirimler\'den kapatırsın.';
  }

  @override
  String get logReminderOfferAccept => 'Hatırlat';

  @override
  String get logReminderOfferLater => 'Şimdi değil';

  @override
  String logReminderEnabled(String saat) {
    return 'Tamam. Hatırlatma her gün saat $saat için kuruldu.';
  }

  @override
  String get logReminderPermissionDenied =>
      'Bildirim izni verilmedi. Ayarlar > Bildirimler\'den açabilirsin.';

  @override
  String get restoreFromDeviceTitle => 'Telefondaki yedek dosyası';

  @override
  String get restoreFromDeviceDesc =>
      'Daha önce kaydettiğin yedek dosyasını seç.';

  @override
  String get restoreFromDevicePick => 'Yedek dosyasını seç';

  @override
  String get simpleBarMore => 'İçgörü ve rapor';

  @override
  String get simpleBarSheetTitle => 'Nereye bakmak istersin?';

  @override
  String get simpleBarLedger => 'Defter';

  @override
  String get simpleBarLedgerSubtitle => 'Kayıtlarının listesi';

  @override
  String get simpleBarInsightsSubtitle => 'Bu dönemde öne çıkanlar';

  @override
  String get simpleBarReportSubtitle => 'Kategoriler ve grafikler';

  @override
  String get simpleBarTransferSubtitle => 'Cüzdanların arasında para taşı';

  @override
  String get sectionsHeader => 'Bölümler';

  @override
  String get sectionsIntro =>
      'Kullanmadığın bölümü kapalı tut; ana ekran sade kalır.';

  @override
  String get sectionSavingsTitle => 'Birikim';

  @override
  String get sectionSavingsDesc => 'Altın, hisse, nakit kasası ve hedefler';

  @override
  String get sectionDebtTitle => 'Borç ve alacak';

  @override
  String get sectionDebtDesc => 'Krediler, borçlar, alacaklar ve kartlar';

  @override
  String get sectionLockedHasRecords => 'Kaydı olduğu için kapatılamaz';

  @override
  String get drawerEnableSavingsTitle => 'Birikim tutmaya başla';

  @override
  String get drawerEnableSavingsSubtitle => 'Altın, hisse, nakit kasası, hedef';

  @override
  String get drawerEnableDebtTitle => 'Borç ve alacak takibi';

  @override
  String get drawerEnableDebtSubtitle => 'Kredi, borç ve alacaklarını yaz';

  @override
  String get debtStartDateHint =>
      'Taksitler bu tarihten başlayarak her ay ilerler.';

  @override
  String get receivableDueDateHint =>
      'Paranı geri almayı beklediğin tarih; yaklaşınca hatırlatırız.';

  @override
  String get recurringRowHint =>
      'Kira, maaş, abonelik gibi düzenli işlemler için sıklık seç; zamanı gelince hatırlatırız.';

  @override
  String get ozelDegerAciklama =>
      'Varlığın bugünkü değeri; değiştikçe buradan güncellersin.';

  @override
  String get ozelMaliyetAciklama =>
      'Bu varlığa ödediğin toplam tutar; kâr/zarar bununla hesaplanır.';

  @override
  String get txEmptyPeriodTitle => 'Bu dönemde kayıt yok';

  @override
  String get txEmptyPeriodBody => 'Bu aralıkta gelir ya da gider yazmadın.';

  @override
  String get txEmptyShowAll => 'Tüm kayıtları göster';

  @override
  String get privacyDataHeader => 'Gizlilik ve veri';
}
