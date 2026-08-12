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
  String get henuzBorcKaydiYokAciklama =>
      'Henüz kaydedilmiş aktif bir borcunuz bulunmuyor. Yeni borç eklemek için ekleme butonunu kullanabilirsiniz.';

  @override
  String get odemeYap => 'Ödeme Yap';

  @override
  String get ode => 'Öde';

  @override
  String get henuzAlacakKaydiYok => 'Henüz alacak kaydı yok.';

  @override
  String get henuzAlacakKaydiYokAciklama =>
      'Henüz kaydedilmiş aktif bir alacağınız bulunmuyor. Yeni alacak eklemek için ekleme butonunu kullanabilirsiniz.';

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
  String get islemRaporu => 'İşlem Raporu';

  @override
  String get tooltipTarihAraligi => 'Tarih Aralığı';

  @override
  String get raporuPaylas => 'Raporu Paylaş';

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
  String get labelKategoriAdi => 'Kategori Adı';

  @override
  String get hintOrnMarketKiraMaas => 'Örn: Market, Kira, Maaş';

  @override
  String get yeniKategoriEkle => 'Yeni Kategori Ekle';

  @override
  String get temizle => 'Temizle';

  @override
  String get labelMin => 'Min';

  @override
  String get labelMax => 'Max';

  @override
  String get hintNotIstegeBagliOrn =>
      'Not (İsteğe bağlı) · örn. Market alışverişi';

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
  String get iceAktarCsv => 'Yedekten İçe Aktar (CSV)';

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
  String get aktifCuzdaniniziDegistirmekIcin =>
      '• Aktif cüzdanınızı değiştirmek için bir cüzdana tıklayın.';

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
  String get msgCreateAPinFirst => 'Önce bir PIN oluşturun';

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
  String get msgPINAlreadyExistsUse =>
      'PIN zaten mevcut, bunun yerine PIN değiştirmeyi kullanın';

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
      'Arka plan kilidi ve Ekran Koruması etkinleştirildi';

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
  String get msgBiometricAuthenticationCannotBe =>
      'Biyometrik kimlik doğrulama bu cihazda kullanılamaz.';

  @override
  String get msgCreateAPinFirst2 =>
      'Biyometrik girişi etkinleştirmek için önce bir PIN oluşturun.';

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
  String get biometricNotAvailableSubtitle =>
      'Biyometrik kimlik doğrulama bu cihazda kullanılamaz';

  @override
  String get biometricEnabledSubtitle => 'Biyometrik giriş etkin';

  @override
  String get biometricDisabledSubtitle => 'Biyometrik giriş devre dışı';

  @override
  String get biometricAuthTileTitle => 'Biyometrik Kimlik Doğrulama';

  @override
  String get biometricAuthTileSubtitleOn =>
      'Açık - Parmak izi veya yüz tanıma ile giriş yapın';

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
  String get screenProtectionTileSubtitleOn =>
      'Açık - Uygulama arka plandayken içeriği gizle';

  @override
  String get screenProtectionTileSubtitleOff => 'Kapalı';

  @override
  String get backgroundLockTitle => 'Arka Plan Kilidi';

  @override
  String get backgroundLockSubtitlePrefix => 'Şu süre sonunda kilitler: ';

  @override
  String get backgroundLockSubtitleOff => 'Kapalı';

  @override
  String get backgroundLockTileTitle =>
      'Uygulama arka planda kaldığında kimlik doğrulama gerektir';

  @override
  String get backgroundLockTileSubtitle =>
      'Arka plan kilidini etkinleştirmek için bir PIN ayarlayın veya biyometrik girişi açın.';

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
  String get googleDriveBackupDesc =>
      'Verilerinizin güvenliği için kendi kişisel Google Drive hesabınıza yedekleme yapın.';

  @override
  String get connectGoogleDrive => 'Google Drive\'a Bağlan';

  @override
  String get account => 'Hesap:';

  @override
  String get lastBackup => 'Son Yedekleme:';

  @override
  String get disconnect => 'Bağlantıyı Kes';

  @override
  String get deleteBackup => 'Yedeği Sil';

  @override
  String get deleteBackupDesc =>
      'Google Drive\'daki yedek dosyası kalıcı olarak silinecek. Yerel veriniz etkilenmez.';

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
  String get restoreDataTitle => 'Verileri Geri Yükle?';

  @override
  String get restoreDataDesc =>
      'Buluttaki verileriniz cihazınızdaki mevcut verilerin üzerine yazılacaktır. Bu işlem geri alınamaz.';

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
  String get dataExportImport => 'Cihaz Yedeği / CSV';

  @override
  String get dataExportImportDesc =>
      'Tam uygulama yedeği kaydedip geri yükleyin veya mevcut cüzdan işlemleri için CSV kullanın.';

  @override
  String get fullBackup => 'Tam yedek';

  @override
  String get saveFullBackupToDevice => 'Tam Yedeği Cihaza Kaydet';

  @override
  String get restoreFullBackupFromDevice => 'Tam Yedeği Cihazdan Geri Yükle';

  @override
  String get shareFullBackup => 'Tam Yedeği Paylaş';

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
  String get fullBackupShareText => 'CuNehat tam yedeği';

  @override
  String get activeWalletRequiredForExport =>
      'Dışa aktarım için aktif bir cüzdan gereklidir.';

  @override
  String get uygulamaBaslatilamadi => 'Uygulama başlatılamadı';

  @override
  String get verilerinizSilinmediTekrarDeneyin =>
      'Verileriniz silinmedi. Tekrar deneyin; sorun sürerse ';

  @override
  String get ikonBulunamadi => 'İkon bulunamadı';

  @override
  String get butcePlanlama => 'Bütçe Planlama';

  @override
  String get henuzButceYok => 'Henüz bütçe yok';

  @override
  String get kategorilerinizeAylikHarcamaLimiti =>
      'Kategorilerinize aylık harcama limiti koyun,\nharcamalarınızı buradan takip edin.';

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
  String get buKategorininButcesiVar =>
      'Bu kategorinin bütçesi var; limit güncellenecek.';

  @override
  String get finansalTakip => 'Finansal Takip';

  @override
  String get vADESIGecmis => 'VADESİ GEÇMİŞ';

  @override
  String get oDENDI => 'ÖDENDİ';

  @override
  String vadeDateformatDdMmm(Object dueDate) {
    return 'Vade: $dueDate';
  }

  @override
  String get msgOdemesiTamamlanipKapatilanBorclarinizin =>
      'Ödemesi tamamlanıp kapatılan borçlarınızın geçmişi burada görüntülenecektir.';

  @override
  String paidDebtsLengthBorcKapandi(Object length) {
    return '$length borç kapandı';
  }

  @override
  String get msgOdendiOlarakIsaretlenenAlacaklarinizin =>
      'Ödendi olarak işaretlenen alacaklarınızın geçmişi burada görüntülenecektir.';

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
      'Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından düzenleyin veya silin.';

  @override
  String get nakitAkisi => 'Nakit Akışı';

  @override
  String get grafikIcinYeterliVeri => 'Grafik için yeterli veri yok';

  @override
  String get cizgiGrafikIcinEnAzIkiGun =>
      'Çizgi grafik oluşturmak için en az iki farklı güne ait işlem olmalıdır';

  @override
  String get detayGosterilecekIslemYok => 'Detay Gösterilecek İşlem Yok';

  @override
  String get gelirVeyaGiderKaydettikten =>
      'Gelir veya gider kaydettikten sonra analiz detayları burada listelenecektir.';

  @override
  String get henuzIslemYok => 'Henüz işlem yok';

  @override
  String get buDonemIcinKayit =>
      'Bu dönem için kayıt bulunmuyor.\nYeni bir işlem eklemek için sürgü butonunu kullanın.';

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
  String formatMoneyItemTotalamountPercent(
      Object totalAmount, Object toStringAsFixed) {
    return '$totalAmount (%$toStringAsFixed)';
  }

  @override
  String get buDonemIcinHenuz =>
      'Bu dönem için henüz işlem verisi bulunamadı. Raporlar veri girildikten sonra derlenecektir.';

  @override
  String get ikonSecin => 'İkon Seçin';

  @override
  String get ikonDegistirmekIcinDokun => 'İkon değiştirmek için dokun';

  @override
  String get asagidakiButondanEkleyebilirsiniz =>
      'Aşağıdaki butondan ekleyebilirsiniz';

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
  String appFormattersDateshortFormatStartdate(
      Object startDate, Object endDate) {
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
  String get yatirimlariniziEklediktenSonraDetayli =>
      'Yatırımlarınızı ekledikten sonra detaylı analizler burada görünecektir.';

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
  String get maliyetiDegistirirsenizFarkCuzdana =>
      'Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.';

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
  String isProfitTotalprofitpercentageTostringasfixed(
      Object isProfit, Object toStringAsFixed) {
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
  String get islemEklerkenTekrarSikligi =>
      'İşlem eklerken tekrar sıklığı seçerseniz\nşablon burada görünür.';

  @override
  String get bekleyenDuzenliIslemler => 'Bekleyen Düzenli İşlemler';

  @override
  String get vadesiGelmisIslemlerinizVar =>
      'Vadesi gelmiş işlemleriniz var. Onaylayarak deftere işlenmesini sağlayabilirsiniz.';

  @override
  String titleTarihDatestrNtutarTx(Object dateStr, Object amount) {
    return 'Tarih: $dateStr\nTutar: $amount';
  }

  @override
  String get ibo => 'İbo';

  @override
  String get uygulamaKilidi => 'Uygulama Kilidi';

  @override
  String get pINBiyometrikVeGizlilik => 'PIN, Biyometrik ve Gizlilik Ayarları';

  @override
  String get otomatikHesaplananDegerler => 'Otomatik hesaplanan değerler:';

  @override
  String get borcAlacakYatirimKayitlarindan =>
      'Borç/alacak/yatırım kayıtlarından türetilir; buradan düzenlenemez.';

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
  String get aktifOlanCuzdanSilinemez =>
      '• Aktif olan cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yapmalısınız.';

  @override
  String get cuzdanlarinizaAitBorcAlacak =>
      '• Cüzdanlarınıza ait Borç, Alacak ve Birikim tutarlarını düzenle sayfasından manuel olarak yönetebilirsiniz.';

  @override
  String get msgPINOrBiometricLogin =>
      'PIN veya biyometrik giriş arka plan kilidi için gereklidir';

  @override
  String get sharedFeatures => 'Paylaşılan Özellikler';

  @override
  String get tarihAraligi => 'Tarih Aralığı';

  @override
  String get butonGalerisi => 'Buton Galerisi';

  @override
  String get taksit1 => '1 taksit';

  @override
  String get taksit2 => '2 taksit';

  @override
  String get tamaminiOde => 'Tamamını öde';

  @override
  String get sliderSavings => 'BİRİKİM';

  @override
  String get sliderTransactions => 'İŞLEMLER';

  @override
  String get sliderDebt => 'BORÇ';

  @override
  String get recurringTransactions => 'Düzenli İşlemler';

  @override
  String get budgetPlanning => 'Bütçe Planlama';

  @override
  String get drawerBalance => 'Bakiye';

  @override
  String get drawerInvestment => 'Yatırım';

  @override
  String get drawerDebt => 'Borç';

  @override
  String get createWallet => 'Cüzdan Oluştur';

  @override
  String get selectWallet => 'Cüzdan Seçin';

  @override
  String get wallet => 'Cüzdan';

  @override
  String get menuGold => 'Altın';

  @override
  String get menuStock => 'Hisse';

  @override
  String get menuCustom => 'Özel';

  @override
  String get menuDetails => 'Detay';

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
  String get themeSysLight => 'Sistem [Açık]';

  @override
  String get themeSysDark => 'Sistem [Kapalı]';

  @override
  String get cuzdanOlusturunuz => 'Cüzdan oluşturunuz';

  @override
  String get cuzdanSeciniz => 'Cüzdan seçiniz';

  @override
  String get yerelMod => 'Yerel Mod';

  @override
  String get henuzCuzdanOlusturmadiniz => 'Henüz cüzdan oluşturmadınız';

  @override
  String get cuzdanOlusturuldu => 'Cüzdan oluşturuldu!';

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
  String get kategoriDuzenle => 'Kategori Düzenle';

  @override
  String get yeniKategori => 'Yeni Kategori';

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
  String get kategoriSilTitle => 'Kategori Sil';

  @override
  String kategoriSilConfirmMessage(Object id) {
    return '\"$id\" kategorisini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.';
  }

  @override
  String kategorilerYuklenemedi(Object error) {
    return 'Kategoriler yüklenemedi: $error';
  }

  @override
  String get giderKategorileri => 'Gider Kategorileri';

  @override
  String get gelirKategorileri => 'Gelir Kategorileri';

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
  String kategoriSayisiOzeti(Object rootCount, Object childCount) {
    return '$rootCount ana, $childCount alt kategori';
  }

  @override
  String get altKategoriEkle => 'Alt kategori ekle';

  @override
  String get ustKategori => 'Üst kategori';

  @override
  String get ustKategoriYok => 'Ana kategori (üst yok)';

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
      'Taşınacak başka kategori yok. Önce yeni bir kategori oluşturun.';

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
  String get islemiSil => 'İşlemi Sil';

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
  String get gecerliYatirimMiktariGirin => 'Geçerli bir yatırım miktarı girin';

  @override
  String get gecerliMevcutDegerGirin => 'Geçerli bir mevcut değer girin';

  @override
  String get altinYatirimi => 'Altın Yatırımı';

  @override
  String get altinTuruVeOtomatikFiyat => 'Altın Türü & Otomatik Fiyat';

  @override
  String get yatirimDetaylari => 'Yatırım Detayları';

  @override
  String get altinNotHint => 'Not (İsteğe bağlı) · örn. Düğün Altınları';

  @override
  String get maliyetYatirilanAnaPara => 'Maliyet (Yatırılan Ana Para)';

  @override
  String get hedefTutarIstegeBagli => 'Hedef Tutar (İsteğe Bağlı)';

  @override
  String get hedefKategorisi => 'Hedef Kategorisi';

  @override
  String get renkSecimi => 'Renk Seçimi';

  @override
  String get altinYatiriminiDuzenle => 'Altın Yatırımını Düzenle';

  @override
  String get yeniAltinEkle => 'Yeni Altın Ekle';

  @override
  String get adet => 'Adet';

  @override
  String get sembolGirin => 'Sembol girin!';

  @override
  String get hisseYatirimi => 'Hisse Yatırımı';

  @override
  String get hisseSenediBul => 'Hisse Senedi Bul';

  @override
  String get hisseNotHint => 'Not (İsteğe bağlı) · örn. Uzun vade alım';

  @override
  String get hisseYatiriminiDuzenle => 'Hisse Yatırımını Düzenle';

  @override
  String get yeniHisseEkle => 'Yeni Hisse Ekle';

  @override
  String get gecerliHedefTutarGirin => 'Geçerli bir hedef tutar girin';

  @override
  String get ozelYatirimi => 'Özel Yatırım';

  @override
  String get customNotHint => 'Not (İsteğe bağlı) · örn. Arsa, Kripto, Döviz';

  @override
  String get ozelYatiriminiDuzenle => 'Özel Yatırımını Düzenle';

  @override
  String get yeniOzelYatirimEkle => 'Yeni Özel Yatırım Ekle';

  @override
  String get varlikEkle => 'Varlık Ekle';

  @override
  String get hedefeParaEkle => 'Hedefe Para Ekle';

  @override
  String get paraEkle => 'Para Ekle';

  @override
  String get yeniAlimMiktarVeOdenenTutar => 'Yeni alım: miktar ve ödenen tutar';

  @override
  String get maliyeteVeDegereEklenir =>
      'Maliyete ve değere eklenir, cüzdandan düşer';

  @override
  String get fiyatiGuncelle => 'Fiyatı Güncelle';

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
    return '$name · Varlık Ekle';
  }

  @override
  String paraEkleTitle(Object name) {
    return '$name · Para Ekle';
  }

  @override
  String get alinanMiktarAltinHint => 'Alınan miktar (örn. gram/adet)';

  @override
  String get alinanAdetHisseHint => 'Alınan adet (lot)';

  @override
  String get odenenTutarHint => 'Ödenen tutar (₺) · hediye ise 0';

  @override
  String get tutarHint => 'Tutar (₺)';

  @override
  String get gecerliMiktarGirin => 'Geçerli bir miktar girin';

  @override
  String get gecerliOdenenTutarGirin => 'Geçerli bir ödenen tutar girin';

  @override
  String get gecerliTutarGirin => 'Geçerli bir tutar girin';

  @override
  String get baslikGirin => 'Başlık girin';

  @override
  String get borcluKisiAdiGirin => 'Borçlu kişi adını girin';

  @override
  String get kurumKisiGirin => 'Kurum/kişi girin';

  @override
  String get aylikTaksitTutariniGirin => 'Aylık taksit tutarını girin';

  @override
  String get aylikTaksitKrediTutarindanKucuk =>
      'Aylık taksit × vade, kredi tutarından küçük olamaz';

  @override
  String get krediHesaplamaInfoBaslik => 'Banka kredisi hesaplaması';

  @override
  String get krediHesaplamaInfoGovde =>
      '• Aylık taksiti biliyorum: Bankanın söylediği aylık taksiti yazın. Toplam geri ödeme = aylık taksit × vade. Kolaylık için alan, faizsiz bir başlangıç olarak kredi tutarı ÷ vade değerini önerir; kendi taksitinize göre değiştirin.\n\n• Faiz oranı ile: Bankanın aylık faiz oranını yazın. Taksit ve toplam, eşit taksitli kredi (amortisman) yöntemiyle hesaplanır.';

  @override
  String get borcTuruLabel => 'Borç türü';

  @override
  String get borcBaslikHint => 'Başlık · örn. Konut Kredisi';

  @override
  String get kurumKisiHint => 'Kurum / Kişi · örn. Ziraat Bankası';

  @override
  String get kisiAdiHint => 'Kişi Adı';

  @override
  String get vadeVeDetaylarLabel => 'Vade & detaylar';

  @override
  String get borcluKisiAdiHint => 'Borçlu kişi adı';

  @override
  String get borcDuzenleTitle => 'Borç Düzenle';

  @override
  String get alacakDuzenleTitle => 'Alacak Düzenle';

  @override
  String get yeniBorcTitle => 'Yeni Borç';

  @override
  String get yeniAlacakTitle => 'Yeni Alacak';

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
  String get debtTypeBankLoan => 'Banka Kredisi';

  @override
  String get debtTypeInstallment => 'Taksitli';

  @override
  String get debtTypePersonal => 'Kişisel';

  @override
  String get debtTypeOther => 'Diğer';

  @override
  String get vadeAyHint => 'Vade (ay)';

  @override
  String get aylikTaksitHint => 'Aylık Taksit';

  @override
  String get vadeFarkiYuzdeHint => 'Vade Farkı %';

  @override
  String get aylikFaizYuzdeHint => 'Aylık Faiz %';

  @override
  String get gecikmeFaiziYuzdeHint => 'Gecikme faizi (%)';

  @override
  String get baslangicLabel => 'Başlangıç';

  @override
  String get vadeLabel => 'Vade';

  @override
  String get toplamBorcLabel => 'Toplam Borç:';

  @override
  String get odenenLabel => 'Ödenen:';

  @override
  String get kalanLabel => 'Kalan:';

  @override
  String get kalanTutardanFazlaOlamaz => 'Kalan tutardan fazla olamaz';

  @override
  String taksitPlaniFormat(Object months) {
    return 'Taksit Planı ($months ay)';
  }

  @override
  String odemeGecmisiFormat(Object count) {
    return 'Ödeme Geçmişi ($count)';
  }

  @override
  String get gecikmis => 'Gecikmiş';

  @override
  String get bekleniyor => 'Bekleniyor';

  @override
  String get cuzdanDuzenleTitle => 'Cüzdanı Düzenle';

  @override
  String get yeniCuzdanEkleTitle => 'Yeni Cüzdan Ekle';

  @override
  String get cuzdanAdiBosOlamaz => 'Cüzdan adı boş olamaz';

  @override
  String get cuzdanAdiEnAz2Karakter => 'Cüzdan adı en az 2 karakter olmalı';

  @override
  String get bakiyeLabel => 'Bakiye *';

  @override
  String get baslangicBakiyesiLabel => 'Başlangıç Bakiyesi *';

  @override
  String get bakiyeBosOlamaz => 'Bakiye boş olamaz';

  @override
  String get gecerliBirSayiGirin => 'Geçerli bir sayı girin';

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
  String get ozelRenkSecin => 'Özel Renk Seçin';

  @override
  String get cuzdanYonetimiTitle => 'Cüzdan Yönetimi';

  @override
  String get infoTransferDesc =>
      'Cüzdanlarınız arasında para transferi yapabilirsiniz. Transfer edilen tutar kur farklılıkları gözetilerek kaynak cüzdandan düşülür ve hedefe eklenir.';

  @override
  String get infoBankImportDesc =>
      'Bankanızın mobil uygulamasından kopyaladığınız hesap hareketlerini hızlıca içe aktararak işlemlerinizi kolaylaştırabilirsiniz.';

  @override
  String get dateBadgeToday => 'BUGÜN';

  @override
  String get dateBadgeYesterday => 'DÜN';

  @override
  String get dateBadgeThisWeek => 'BU HAFTA';

  @override
  String get dateBadgeLastWeek => 'GEÇEN HAFTA';

  @override
  String get dateBadgeThisMonth => 'BU AY';

  @override
  String get dateBadgeLastMonth => 'GEÇEN AY';

  @override
  String get categoryFinans => 'Finans';

  @override
  String get categoryGrafikler => 'Grafikler';

  @override
  String get categoryIsVeOfis => 'İş & Ofis';

  @override
  String get categoryAlisveris => 'Alışveriş';

  @override
  String get categoryYemekVeIcecek => 'Yemek & İçecek';

  @override
  String get categoryUlasim => 'Ulaşım';

  @override
  String get categoryEvVeYasam => 'Ev & Yaşam';

  @override
  String get categoryEglence => 'Eğlence';

  @override
  String get categorySaglikVeSpor => 'Sağlık & Spor';

  @override
  String get categoryEgitim => 'Eğitim';

  @override
  String get categoryKisiselBakim => 'Kişisel Bakım';

  @override
  String get categoryHayvanlar => 'Hayvanlar';

  @override
  String get categorySeyahat => 'Seyahat';

  @override
  String get categoryTeknoloji => 'Teknoloji';

  @override
  String get categoryIletisim => 'İletişim';

  @override
  String get categoryHediyeVeBagis => 'Hediye & Bağış';

  @override
  String get categoryHizmetler => 'Hizmetler';

  @override
  String get categoryDiger => 'Diğer';

  @override
  String get systemTagDebt => 'Borç';

  @override
  String get systemTagDebtPayment => 'Borç Ödemesi';

  @override
  String get systemTagReceivable => 'Alacak';

  @override
  String get systemTagReceivableCollection => 'Alacak Tahsilatı';

  @override
  String get systemTagInvestmentBuy => 'Yatırım Alımı';

  @override
  String get systemTagInvestmentSell => 'Yatırım Satışı';

  @override
  String get systemTagInvestmentCorrection => 'Yatırım Düzeltmesi';

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
  String get akilliIcgoruler => 'Akıllı İçgörüler';

  @override
  String get gunlukOrtalamaHarcama => 'Günlük ortalama harcama';

  @override
  String get enCokHarcananGun => 'En çok harcadığınız gün';

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
  String get duzenliOdemeOlarakEkle => 'Düzenli Ödeme olarak ekle';

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
      'Yatırımın bugünkü piyasa değeri; \'Hesapla\' ile güncel fiyattan güncellenir.';

  @override
  String get toplamMaliyetAciklama =>
      'Bu yatırıma ödediğin toplam tutar (maliyetin). \'Hesapla\' bunu değiştirmez; kâr/zarar bununla hesaplanır.';

  @override
  String get paraBirimiLabel => 'Para Birimi';

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
  String get cuzdanlarArasiTransfer => 'Cüzdanlar Arası Transfer';

  @override
  String get transferEt => 'Transfer Et';

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
      'Kur bilgisi alınamadı — internete bağlanınca tekrar deneyin';

  @override
  String get transferBasarili => 'Transfer tamamlandı';

  @override
  String get transferBasarisiz => 'Transfer başarısız oldu';

  @override
  String get transferIcinIkiCuzdanGerekli =>
      'Transfer için en az iki cüzdan gerekli';

  @override
  String transferBakiyeAsimiMesaj(String bakiye) {
    return 'Tutar, cüzdan bakiyesinden ($bakiye) fazla. Devam ederseniz bakiye eksiye düşer. Devam edilsin mi?';
  }

  @override
  String get yardimVeTurlar => 'Yardım & Turlar';

  @override
  String get genelTanitimiTekrarGoster =>
      'Gizlilik ve Bildirim Tanıtımını Tekrar Göster';

  @override
  String get uygulamaTuruTekrarGoster => 'Uygulama Turunu Tekrar Göster';

  @override
  String get onboardingNavHintHeader => 'Nasıl Gezinilir?';

  @override
  String get onboardingNavHintSwipeTitle => 'Sağa / Sola Kaydırın';

  @override
  String get onboardingNavHintSwipeDesc =>
      'Yatırım, İşlemler ve Borç ekranları arasında geçiş yapın.';

  @override
  String get onboardingNavHintDragTitle => 'Yukarı Sürükleyin';

  @override
  String get onboardingNavHintDragDesc =>
      'Detay, Rapor, Bekleyen ve Geçmiş gibi alt sayfalara ulaşın.';

  @override
  String get onboardingNavHintAddTitle => 'Simgelere Dokunun';

  @override
  String get onboardingNavHintAddDesc =>
      'Yeni gelir, gider, yatırım, borç veya alacak ekleyin.';

  @override
  String get notificationSettings => 'Bildirim Ayarları';

  @override
  String get notificationSettingsDesc =>
      'Kritik ve rastgele bildirim tercihlerinizi yönetin.';

  @override
  String get randomReminders => 'Motive Edici Hatırlatıcılar';

  @override
  String get randomRemindersOff => 'Kapalı';

  @override
  String get randomRemindersLow => 'Az (Günde 1)';

  @override
  String get randomRemindersMedium => 'Orta (Günde 2)';

  @override
  String get randomRemindersHigh => 'Çok (Günde 3)';

  @override
  String get criticalNotifications => 'Kritik Bildirimler';

  @override
  String get debtReminders => 'Borç/Alacak Hatırlatıcıları';

  @override
  String get recurringReminders => 'Düzenli İşlem Hatırlatıcıları';

  @override
  String get budgetAlerts => 'Bütçe Uyarıları';

  @override
  String get notificationRationaleTitle => 'Bildirimler';

  @override
  String get notificationRationaleBody =>
      'CuNehat; borç/alacak vade tarihleri yaklaştığında ve tekrarlayan işlemler onay beklediğinde size hatırlatma gönderebilir. Bunun için bildirim izni gerekir. İzin vermeseniz de uygulamayı kullanmaya devam edebilirsiniz; sadece hatırlatmalar gösterilmez.';

  @override
  String get notificationRationaleLater => 'Şimdi Değil';

  @override
  String get notificationPermissionOffTitle => 'Bildirim izni kapalı';

  @override
  String get notificationPermissionOffDesc =>
      'Aşağıdaki hatırlatmalar ancak sistem izni verildiğinde ulaşabilir.';

  @override
  String get notificationPermissionGrant => 'İzin Ver';

  @override
  String get notificationPermissionOpenSettings =>
      'İzin daha önce reddedildiği için sistem bir daha sormuyor. Bildirimleri sistem ayarlarından açabilirsiniz.';

  @override
  String get notificationPermissionOpenSettingsAction => 'Ayarları Aç';

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
  String get notificationTestTitle => 'CuNehat test bildirimi';

  @override
  String get notificationTestBody =>
      'Bildirimler çalışıyor. Hatırlatmalarınız bu şekilde görünecek.';

  @override
  String get notifChannelCriticalName => 'Kritik Hatırlatmalar';

  @override
  String get notifChannelCriticalDesc => 'Borç vadeleri ve bütçe aşımları';

  @override
  String get notifChannelRecurringName => 'Düzenli İşlemler';

  @override
  String get notifChannelRecurringDesc =>
      'Onay bekleyen düzenli işlem hatırlatmaları';

  @override
  String get notifChannelMotivationalName => 'Motive Edici Hatırlatıcılar';

  @override
  String get notifChannelMotivationalDesc =>
      'Harcama girmeyi hatırlatan günlük mesajlar';

  @override
  String get notifRecurringDueTitle => 'Düzenli İşlem Vakti';

  @override
  String notifRecurringDueBody(Object title) {
    return '$title onayınızı bekliyor.';
  }

  @override
  String get notifDebtUpcomingTitle => 'Borç Hatırlatması';

  @override
  String notifDebtUpcomingBody(Object title) {
    return '$title borcunuzun sıradaki taksit ödeme tarihi yaklaştı.';
  }

  @override
  String get notifDebtDueTitle => 'Borç Son Ödeme Tarihi!';

  @override
  String notifDebtDueBody(Object title) {
    return '$title borcunuzun sıradaki taksit ödeme tarihi bugün.';
  }

  @override
  String get notifBudgetWarningTitle => 'Bütçe Uyarısı';

  @override
  String notifBudgetWarningBody(Object category) {
    return '$category bütçenizin %80\'ine ulaştınız.';
  }

  @override
  String get notifBudgetExceededTitle => 'Bütçe Aşıldı!';

  @override
  String notifBudgetExceededBody(Object category) {
    return '$category bütçenizi aştınız.';
  }

  @override
  String get notifBudgetFilledTitle => 'Bütçe Doldu';

  @override
  String notifBudgetFilledBody(Object category) {
    return '$category bütçe limitinizin tamamına ulaştınız (%100).';
  }

  @override
  String get notifDailyReminderTitle => 'CuNehat';

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
  String get onayBekleyenler => 'Onay Bekleyenler';

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
  String get tumunuOnayla => 'Tümünü Onayla';

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
  String get tumTurlariSifirla => 'Tüm Turları Sıfırla';

  @override
  String get tumTurlariSifirlaAciklama =>
      'Alt sayfa turları da dahil, tüm ekranları ziyaret ettiğinizde tekrar gösterilir.';

  @override
  String get tumTurlarSifirlandi => 'Turlar sıfırlandı';

  @override
  String get onboardingAppBarMenuTitle => 'Menü';

  @override
  String get onboardingAppBarMenuDesc =>
      'Bütçeler, düzenli işlemler, banka ekstresi içe aktarma ve ayarlar bu menüde.';

  @override
  String get onboardingAppBarWalletTitle => 'Aktif Cüzdanınız';

  @override
  String get onboardingAppBarWalletDesc =>
      'Her gelir, gider, borç ve yatırım kaydı SEÇİLİ cüzdana işlenir. Buraya dokunarak cüzdan değiştirebilir veya yeni cüzdan ekleyebilirsiniz.';

  @override
  String get onboardingWalletListTitle => 'Cüzdanlarınız';

  @override
  String get onboardingWalletListDesc =>
      'Her cüzdanın kendi para birimi ve bakiyesi vardır. Bir karta dokunarak aktif cüzdanı değiştirir, karttaki simgelerle düzenler veya silersiniz.';

  @override
  String get onboardingWalletManagementTitle => 'Yeni Cüzdan Ekle';

  @override
  String get onboardingWalletManagementDesc =>
      'Nakit, banka hesabı ya da döviz için ayrı cüzdan açın — raporlar, bütçeler ve borçlar cüzdan bazlı çalışır.';

  @override
  String get onboardingTransactionsAddTitle => 'Tutarı Girin';

  @override
  String get onboardingTransactionsAddDesc =>
      'Tutarı yazın. Üstteki gelir/gider seçimi işlemin cüzdan bakiyesini artıracağını mı azaltacağını mı belirler.';

  @override
  String get onboardingTransactionsAddCategoryTitle => 'Kategori Seçin';

  @override
  String get onboardingTransactionsAddCategoryDesc =>
      'Kategori zorunludur: raporlar ve bütçe uyarıları bu kategoriye göre hesaplanır.';

  @override
  String get onboardingTransactionsAddRecurringTitle => 'Tekrar Sıklığı';

  @override
  String get onboardingTransactionsAddRecurringDesc =>
      'Kira, maaş, abonelik gibi düzenli işlemleri bir kez tanımlayın; uygulama zamanı gelince hatırlatır.';

  @override
  String get onboardingDebtAddTitle => 'Tutar ve Geri Ödeme';

  @override
  String get onboardingDebtAddDesc =>
      'Tutarı girin. Borç türüne göre taksit, faiz ve vade alanları aşağıda açılır; kartın altındaki özet toplam geri ödemeyi anında hesaplar.';

  @override
  String get onboardingDebtAddDueDateTitle => 'Vade Tarihi';

  @override
  String get onboardingDebtAddDueDateDesc =>
      'Alacağını beklediğin tarih. O gün yaklaştığında hatırlatma bildirimi alırsın.';

  @override
  String get onboardingInvestmentAddTitle => 'Bugünkü Değer';

  @override
  String get onboardingInvestmentAddDesc =>
      'Yatırımın şu anki piyasa değeri. Kâr/zararınız bu değerle toplam maliyet arasındaki farktır.';

  @override
  String get onboardingInvestmentAddCostTitle => 'Toplam Maliyet';

  @override
  String get onboardingInvestmentAddCostDesc =>
      'Bu yatırıma bugüne kadar ödediğiniz ana para. Boş bırakırsanız kâr/zarar hesaplanamaz.';

  @override
  String get onboardingInvestmentAddQuantityTitle => 'Miktar ve Güncel Fiyat';

  @override
  String get onboardingInvestmentAddQuantityDesc =>
      'Gram/adet girip güncel fiyatı çekin; bugünkü değer sizin yerinize hesaplanır.';

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
  String get fisOcrDolduruldu =>
      'Bilgiler fişten dolduruldu — lütfen kontrol edin';

  @override
  String get fisCihazdaYok => 'Görsel bu cihazda yok';

  @override
  String get bankImportSettingsEntry => 'Banka ekstresi içe aktar';

  @override
  String get bankImportSettingsSubtitle =>
      'CSV/Excel/PDF ekstresini işlemlere dönüştür';

  @override
  String get bankImportTitle => 'Banka Ekstresi İçe Aktar';

  @override
  String get bankImportParsing => 'Dosya taranıyor…';

  @override
  String get bankImportNoWallet => 'Önce bir cüzdan oluşturun.';

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
  String get bankImportMappingTitle => 'Sütunları eşle';

  @override
  String get bankImportColDate => 'Tarih sütunu';

  @override
  String get bankImportColDesc => 'Açıklama sütunu';

  @override
  String get bankImportColAmount => 'Tutar sütunu';

  @override
  String get bankImportColDebit => 'Borç (gider)';

  @override
  String get bankImportColCredit => 'Alacak (gelir)';

  @override
  String get bankImportSignMode => 'Tutar işareti';

  @override
  String get bankImportSignSingle => 'Tek sütun (− gider)';

  @override
  String get bankImportSignDebitCredit => 'Borç / Alacak';

  @override
  String get bankImportDateFormat => 'Tarih biçimi';

  @override
  String get bankImportDateAuto => 'Otomatik';

  @override
  String get bankImportContinue => 'Devam';

  @override
  String bankImportColumnN(int n) {
    return '$n. sütun';
  }

  @override
  String get bankImportPreviewTitle => 'Önizleme (ilk hareketler)';

  @override
  String get bankImportRoleDate => 'Tarih';

  @override
  String get bankImportRoleDesc => 'Açıklama';

  @override
  String get bankImportRoleAmount => 'Tutar';

  @override
  String get bankImportRoleDebit => 'Borç';

  @override
  String get bankImportRoleCredit => 'Alacak';

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
  String get bankImportDuplicate => 'Olası tekrar';

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
      'Bu hareketler bir GÖRÜNTÜDEN okundu. Görüntü tanımada rakamlar sık karışır (virgül/nokta, 1/7, 0/O) ve doğrulayacak bakiye sütunu genelde yoktur — eklemeden önce her tutarı tek tek kontrol et.';

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
  String get bankImportDonePastDatesHint =>
      'Bazı hareketler geçmiş aylara ait. İşlemler listesi varsayılan olarak içinde bulunduğun ayı gösterir; hepsini görmek için tarih filtresini genişlet.';

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
  String get bankImportUndoDone => 'İçe aktarım geri alındı.';

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
  String get bankImportSyncDialogTitle => 'Bakiyeyi Eşitle';

  @override
  String get bankImportSyncDialogHint =>
      'Bankandaki gerçek güncel bakiyeni gir; cüzdanın buna göre ayarlanır. Geçmiş hareketlerin değişmez, yalnızca başlangıç bakiyesi düzeltilir.';

  @override
  String get bankImportSyncDialogLabel => 'Gerçek bakiye';

  @override
  String get bankImportSyncSuccess => 'Cüzdan bakiyesi eşitlendi.';

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
  String bankImportAssignVisible(int count) {
    return 'Görünen $count satıra kategori ata';
  }

  @override
  String bankImportAssignVisibleDone(int count, String category) {
    return '$count satır “$category” kategorisine alındı.';
  }

  @override
  String bankImportUncategorizedBlocked(int count) {
    return 'Seçili $count satırın kategorisi yok. Kategori seçilmeden eklenemez: bütçe ve raporlarda hiçbir kategoriye sayılmazlar.';
  }

  @override
  String get bankImportShowUncategorized => 'Göster';

  @override
  String get bankImportStepNeedsCategory =>
      'Önce kategorisiz satırlara kategori seç.';

  @override
  String get bankStatementSectionHeader => 'BANKA EKSTRESİ';

  @override
  String get sifirla => 'Sıfırla';

  @override
  String get tumTurlariSifirlaOnayMesaji =>
      'Tüm tanıtım turları sıfırlanacak ve tekrar gösterilecek. Devam edilsin mi?';

  @override
  String get deleteAllDataTitle => 'Tüm veriyi sil';

  @override
  String get deleteAllDataMessage =>
      'Tüm cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler ve tekrarlayan şablonlar cihazdan kalıcı olarak silinecek. Bu işlem geri alınamaz. Drive yedeğiniz (varsa) etkilenmez.';

  @override
  String get irreversibleActionTitle => 'Bu İşlem Geri Alınamaz';

  @override
  String get deleteAllDataDangerMessage =>
      'Onayladığınızda tüm yerel veriler kalıcı olarak silinir ve kurtarılamaz.';

  @override
  String get dataDeletedSuccess => 'Tüm yerel veri silindi.';

  @override
  String get dataDeleteError => 'Veri silinemedi. Lütfen tekrar deneyin.';

  @override
  String get deleteWalletTitle => 'Cüzdan Sil';

  @override
  String deleteWalletConfirmMessage(String ad) {
    return '$ad cüzdanını silmek istediğinizden emin misiniz?';
  }

  @override
  String deleteWalletDangerMessage(String ad) {
    return '$ad cüzdanı ve tüm işlem geçmişi kalıcı olarak silinecek. Bu işlem geri alınamaz.';
  }

  @override
  String get transferOnayBasligi => 'Transferi Onayla';

  @override
  String transferOnayMesaji(String tutar, String kaynak, String hedef) {
    return '$tutar tutarını $kaynak cüzdanından $hedef cüzdanına transfer etmek istediğinizden emin misiniz?';
  }

  @override
  String get budgetDeleteConfirmTitle => 'Bütçeyi Sil';

  @override
  String budgetDeleteConfirmMessage(String kategori) {
    return '$kategori bütçesini silmek istediğinizden emin misiniz?';
  }

  @override
  String get borcSilBaslik => 'Borcu Sil';

  @override
  String borcSilOnayMesaji(String baslik) {
    return '$baslik borcunu silmek istediğinizden emin misiniz? Bu borcun cüzdan bakiyesine etkisi de geri alınır.';
  }

  @override
  String get alacakSilBaslik => 'Alacağı Sil';

  @override
  String alacakSilOnayMesaji(String isim) {
    return '$isim alacağını silmek istediğinizden emin misiniz? Bu alacağın cüzdan bakiyesine etkisi de geri alınır.';
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
  String get insightDailyLimitTitle => 'Günlük Harcama Limiti (Hedef)';

  @override
  String insightDailyLimitDesc(int gun) {
    return 'Kalan $gun gün boyunca bütçenizi korumak için tavsiye edilen günlük limit.';
  }

  @override
  String get insightSpikeTitle => 'Harcama Sıçraması Uyarısı';

  @override
  String insightSpikeDesc(String tutar) {
    return 'Geçen döneme göre ($tutar) dikkate değer bir artış var.';
  }

  @override
  String get drawerSectionFinancial => 'FİNANSAL YÖNETİM';

  @override
  String get drawerSectionSystem => 'SİSTEM & UYGULAMA';

  @override
  String get drawerBudgetSubtitle =>
      'Kategori bazlı bütçe takibi ve harcama limitleri';

  @override
  String get drawerRecurringSubtitle => 'Otomatik gelir ve gider şablonları';

  @override
  String get drawerBankImportSubtitle => 'PDF/Excel hesap ekstresi içe aktarma';

  @override
  String get drawerSettingsSubtitle => 'Tema, para birimi ve genel tercihler';

  @override
  String get drawerSecurityTitle => 'Güvenlik & Biyometrik';

  @override
  String get drawerSecuritySubtitle => 'Uygulama kilidi ve PIN ayarları';

  @override
  String get drawerActiveWalletLabel => 'AKTİF CÜZDAN';

  @override
  String get reportBalanceTrend => 'Bakiye Trendi';

  @override
  String get reportExpensesTitle => 'Giderler';

  @override
  String get reportIncomesTitle => 'Gelirler';

  @override
  String get reportNoDataTitle => 'Rapor Oluşturmak İçin Veri Yok';

  @override
  String get reportNetLabel => 'Net';

  @override
  String reportCompareTopSlice(String ad, String tutar) {
    return 'En büyük: $ad · $tutar';
  }

  @override
  String reportCompareOverspend(String oran) {
    return 'Gelirin %$oran üzerinde';
  }

  @override
  String get reportCompareScaleHint => 'İki çubuk aynı ölçekte';

  @override
  String get debtHistoryEmptyTitle => 'Henüz Kapanan Borç Yok';

  @override
  String get receivableHistoryEmptyTitle => 'Henüz Tahsil Edilen Alacak Yok';

  @override
  String get badgeOdendi => 'Ödendi';

  @override
  String get badgeTahsilEdildi => 'Tahsil Edildi';

  @override
  String reportSavingsSubtitle(String oran) {
    return '%$oran Birikim';
  }

  @override
  String vadeTarihLabel(String tarih) {
    return 'Vade: $tarih';
  }

  @override
  String get privacyPolicyTitle => 'Gizlilik Politikası';

  @override
  String get privacyIntro =>
      'CuNehat, finansal kayıtlarınızı takip etmenize yardımcı olan bir kişisel finans uygulamasıdır. \"Önce-çevrimdışı\" tasarlandı: bulut yedeklemeyi açıkça etkinleştirmediğiniz sürece verileriniz cihazınızda kalır. Sunucumuz yoktur.';

  @override
  String get privacyLocalDataTitle => 'Cihazınızda saklanan veriler';

  @override
  String get privacyLocalDataBody =>
      'Cüzdanlar, işlemler, yatırımlar, borçlar, alacaklar, bütçeler, tekrarlayan şablonlar ve uygulama tercihleri (tema, dil, kategoriler) yalnızca cihazınızda saklanır ve bize iletilmez.';

  @override
  String get privacyDriveTitle => 'Google Drive yedeği (isteğe bağlı)';

  @override
  String get privacyDriveBody =>
      'Bulut yedekleme varsayılan olarak KAPALIDIR. Açarsanız Google ile oturum açılır; yalnızca e-posta adresiniz (hangi hesabın bağlı olduğunu görmeniz için) ve kısıtlı \"drive.appdata\" kapsamı kullanılır. Tek bir yedek dosyası (cunehat_backup.json) kendi Drive\'ınızdaki, başka uygulamaların erişemediği özel bir klasöre yazılır. Tam Drive erişimi istenmez; diğer dosyalarınız okunamaz.';

  @override
  String get privacyMarketDataTitle => 'Piyasa verisi';

  @override
  String get privacyMarketDataBody =>
      'Canlı fiyat göstermek için yalnızca varlık sembolü (örn. hisse kodu) herkese açık uç noktalara (Yahoo Finance, Truncgil) gönderilir. Hiçbir kişisel veya finansal kayıt paylaşılmaz.';

  @override
  String get backupOfferTitle => 'Verilerin yalnızca bu cihazda';

  @override
  String get backupOfferBody =>
      'CuNehat kayıtlarını bir sunucuda tutmaz. Telefonunu kaybeder, sıfırlar ya da uygulamayı kaldırırsan bu veriler geri gelmez. Otomatik yedeklemeyi açarsan kayıtlarının kopyası düzenli olarak kendi Google Drive\'ındaki özel bir klasöre alınır.';

  @override
  String get backupOfferSetup => 'Yedeklemeyi Kur';

  @override
  String get backupOfferLater => 'Şimdi Değil';

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
  String get privacyConsentTitle => 'Gizliliğiniz';

  @override
  String get privacyConsentBody =>
      'CuNehat verilerinizi yalnızca cihazınızda saklar; sunucumuz yoktur. İsteğe bağlı Google Drive yedeği yalnızca siz açarsanız, kendi Drive\'ınızdaki özel bir klasöre yazılır. Verileriniz üçüncü taraflarla paylaşılmaz; reklam veya izleme yoktur.';

  @override
  String get privacyConsentAcknowledge => 'Anladım';

  @override
  String get secenekler => 'Seçenekler';

  @override
  String get tarihAraligiSecBaslik => 'Tarih Aralığı Seç';

  @override
  String get takvimdenSec => 'Takvimden seç';

  @override
  String get kategoriSecmeUyarisi => 'Bir kategori seçin';

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
  String get driveErrNotSignedIn => 'Google Drive\'a bağlı değilsiniz.';

  @override
  String get driveErrCancelled => 'İşlem iptal edildi.';

  @override
  String get driveErrNoNetwork =>
      'İnternet bağlantısı yok. Bağlanıp tekrar deneyin.';

  @override
  String get driveErrTimeout =>
      'Google Drive zamanında yanıt vermedi. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get driveErrAuthExpired =>
      'Google oturumunuzun süresi doldu. Bağlantıyı kesip yeniden bağlanın.';

  @override
  String get driveErrScopeDenied =>
      'Drive uygulama klasörü izni verilmedi. Yedekleme bu izin olmadan çalışamaz.';

  @override
  String get driveErrConfigError =>
      'Google Drive bu uygulama sürümünde yapılandırılmamış (OAuth istemcisi paket adı/imza ile eşleşmiyor). Bu bir kurulum hatası; yedekleme şimdilik kullanılamıyor.';

  @override
  String get driveErrQuotaExceeded =>
      'Google Drive depolama alanınız dolu. Yer açıp tekrar deneyin.';

  @override
  String get driveErrServerError =>
      'Google Drive şu anda yanıt veremiyor. Daha sonra tekrar deneyin.';

  @override
  String get driveErrEmptyLocalData =>
      'Cihazda yedeklenecek kayıt yok. Boş bir yedek, Drive\'daki dolu yedeğinizin yerini alırdı.';

  @override
  String get driveErrVerificationFailed =>
      'Yükleme doğrulanamadı; yedek eksik yazılmış olabilir. Yeni kopya geri alındı, önceki yedeğiniz duruyor.';

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
      'Geri yükleme sırasında yazma hatası oldu. Cihazdaki eski verileriniz geri alındı.';

  @override
  String get driveUnchanged =>
      'Veriler son yedekten beri değişmedi; yeni yedek alınmadı.';

  @override
  String get backupEmptyConfirmTitle => 'Boş yedek alınsın mı?';

  @override
  String get backupEmptyConfirmDesc =>
      'Cihazda hiç kayıt yok. Devam ederseniz Drive\'daki en yeni yedeğin yerine boş bir yedek yazılır.';

  @override
  String get backupEmptyConfirmAction => 'Boş yedek al';

  @override
  String get viewBackups => 'Yedekleri Görüntüle';

  @override
  String get deleteAllBackups => 'Tüm Yedekleri Sil';

  @override
  String get deleteAllBackupsDesc =>
      'Google Drive\'daki tüm yedek kopyaları kalıcı olarak silinecek. Cihazınızdaki veriler etkilenmez.';

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
      'Uygulamayı hiç açmazsanız otomatik yedek çalışmaz.';

  @override
  String autoBackupFailureWarning(int count) {
    return 'Son $count otomatik yedekleme denemesi başarısız oldu. Elle yedekleyerek sebebini görebilirsiniz.';
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
  String get backupPreviewDiffTitle => 'Geri yüklerseniz ne değişir';

  @override
  String get backupPreviewDiffOnDevice => 'Cihazda';

  @override
  String get backupPreviewDiffInBackup => 'Yedekte';

  @override
  String backupPreviewReceiptWarning(int count) {
    return '$count işlemin fiş görseli var. Görseller yedeğe dahil edilmez; başka bir cihaza geri yüklerseniz bu görseller görünmez.';
  }

  @override
  String get backupPreviewEmptyWarning =>
      'Bu yedek boş. Geri yüklerseniz cihazınızdaki tüm kayıtlar silinir.';

  @override
  String get backupPreviewRestoreButton => 'Bu yedeği geri yükle';

  @override
  String get backupPreviewDeleteButton => 'Bu kopyayı sil';

  @override
  String get backupPreviewDeleteConfirmDesc =>
      'Bu yedek kopyası Google Drive\'dan kalıcı olarak silinecek. Cihazınızdaki veriler etkilenmez.';

  @override
  String get backupPreviewRestoreConfirmTitle => 'Bu yedek geri yüklensin mi?';

  @override
  String get backupPreviewRestoreConfirmDesc =>
      'Cihazdaki tüm cüzdanlar, işlemler, birikimler, borçlar, alacaklar, bütçeler ve düzenli işlem şablonları bu yedektekilerle DEĞİŞTİRİLİR. Bu işlem geri alınamaz.';

  @override
  String get backupPreviewNoTransactions => 'Bu yedekte işlem yok.';

  @override
  String get backupPreviewUnknownCount => '?';

  @override
  String get disconnectConfirmTitle => 'Bağlantı kesilsin mi?';

  @override
  String disconnectConfirmDesc(String email) {
    return '$email hesabından çıkılacak. Google Drive\'daki yedekleriniz SİLİNMEZ — aynı hesapla tekrar bağlandığınızda erişebilirsiniz. Otomatik yedekleme duracak.';
  }

  @override
  String deleteAllBackupsDangerDesc(int count) {
    return 'Onayladığınızda Google Drive\'daki $count yedek kopyasının tamamı kalıcı olarak silinir. Cihazınızdaki veriler bozulur ya da silinirse geri dönebileceğiniz hiçbir kopya kalmaz.';
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
  String get odemeSilBaslik => 'Ödemeyi Sil';

  @override
  String odemeSilOnayMesaji(Object tutar) {
    return '$tutar tutarındaki ödeme kaydı silinecek. Bu ödemenin cüzdan bakiyesine etkisi de geri alınır.';
  }

  @override
  String get odemeyiDuzenleBaslik => 'Ödemeyi Düzenle';

  @override
  String get onboardingDebtAddStartDateTitle => 'Başlangıç Tarihi';

  @override
  String get onboardingDebtAddStartDateDesc =>
      'Borcun başladığı tarih; taksitler buradan itibaren aylık ilerler. Hatırlatma bildirimi, sıradaki ödenmemiş taksitin vadesinde gelir.';

  @override
  String vadeTaksitIlerleme(int termMonths, int paid) {
    return 'Vade: $termMonths Ay | $paid/$termMonths taksit';
  }

  @override
  String get vadeOpsiyonelLabel => 'Vade (opsiyonel)';

  @override
  String get vadeSecilmedi => 'Seçilmedi';
}
