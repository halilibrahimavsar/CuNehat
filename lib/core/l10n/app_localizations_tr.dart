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
  String get msgSecilenTarihAraligindaIslem =>
      'Seçilen tarih aralığında işlem yok';

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
  String get dataRestoredSuccess =>
      'Veriler başarıyla geri yüklendi. Değişikliklerin görünmesi için lütfen uygulamayı yeniden başlatın.';

  @override
  String get restoreFailedNoBackup =>
      'Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.';

  @override
  String get welcomeUser => 'Hoşgeldiniz';

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
  String valueTostringasfixedCurrencysymbol(
      Object toStringAsFixed, Object currencySymbol) {
    return '$toStringAsFixed $currencySymbol';
  }

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
  String vadeDebtTermmonthsAy(Object termMonths, Object length) {
    return 'Vade: $termMonths Ay | $length Ödeme';
  }

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
  String get tumIslemlerinizGuncel => 'Tüm İşlemleriniz Güncel';

  @override
  String get bekleyenCevrimdisiIslemBulunmuyor =>
      'Bekleyen çevrimdışı işlem bulunmuyor. Cihazınız internete bağlandığında veya yeni veriler girildiğinde senkronizasyon otomatik olarak tetiklenir.';

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
  String categoriesWhereCC(Object customLength, Object defaultLength) {
    return '$customLength özel, $defaultLength varsayılan';
  }

  @override
  String get asagidakiButondanEkleyebilirsiniz =>
      'Aşağıdaki butondan ekleyebilirsiniz';

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

  @override
  String get sliderSavings => 'BİRİKİM';

  @override
  String get sliderTransactions => 'İŞLEMLER';

  @override
  String get sliderDebt => 'BORÇ';

  @override
  String get myProfile => 'Profilim';

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
  String get menuPending => 'Bekleyen';

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
  String get varsayilanKategoriYok => 'Varsayılan kategori yok';

  @override
  String get henuzOzelKategoriYok => 'Henüz özel kategori yok';

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
  String guncelFiyatFormatTry(Object price) {
    return 'Güncel Fiyat: $price ₺';
  }

  @override
  String guncelFiyatFormatForeign(
      Object price, Object currency, Object priceTl) {
    return 'Güncel Fiyat: $price $currency (≈$priceTl ₺)';
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
  String get vadeEnAz1Olmali => 'Vade (ay) en az 1 olmalı';

  @override
  String get aylikTaksitTutariniGirin => 'Aylık taksit tutarını girin';

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
  String get defaultCategoryFood => 'Yemek';

  @override
  String get defaultCategoryTransport => 'Ulaşım';

  @override
  String get defaultCategoryShopping => 'Alışveriş';

  @override
  String get defaultCategoryBills => 'Fatura';

  @override
  String get defaultCategoryEntertainment => 'Eğlence';

  @override
  String get defaultCategorySalary => 'Maaş';

  @override
  String get defaultCategoryInvestment => 'Yatırım';

  @override
  String get defaultCategoryFreelance => 'Serbest';

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
  String get borcBakiyeyeEklenecekBaslik => 'Borç bakiyene eklenecek';

  @override
  String borcBakiyeyeEklenecekGovde(String tutar) {
    return 'Bu borcun ana parası ($tutar) cüzdan bakiyene gelir olarak eklenir. Geri ödemelerini ve harcamalarını manuel ekleyebilirsin.';
  }

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
}
