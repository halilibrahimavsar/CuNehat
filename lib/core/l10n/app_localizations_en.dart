// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language => 'Language';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get hataDetayi => 'Error detail';

  @override
  String get tekrarDene => 'Try Again';

  @override
  String get islemGecmisiCsv => 'Transaction History (CSV)';

  @override
  String get duzenle => 'Edit';

  @override
  String get sil => 'Delete';

  @override
  String get hintIkonAra => 'Search icon...';

  @override
  String hataStateFailureMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get yeniButceEkle => 'Add New Budget';

  @override
  String get labelKategori => 'Category';

  @override
  String get labelAylikLimit => 'Monthly Limit';

  @override
  String get iptal => 'Cancel';

  @override
  String get borclarim => 'My Debts';

  @override
  String get alacaklarim => 'My Receivables';

  @override
  String get henuzBorcKaydiYok => 'No debt record yet.';

  @override
  String get odemeYap => 'Make Payment';

  @override
  String get ode => 'Pay';

  @override
  String get henuzAlacakKaydiYok => 'No receivable record yet.';

  @override
  String get odendiIsaretle => 'Mark as Paid';

  @override
  String get gecmis => 'History';

  @override
  String get borcGecmisi => 'Debt History';

  @override
  String get alacakGecmisi => 'Receivable History';

  @override
  String get aylikTaksitiBiliyorum => 'I know the monthly installment';

  @override
  String get faizOraniIle => 'With interest rate';

  @override
  String get esitTaksitAmortisman => 'Equal Installment (Amortization)';

  @override
  String get basitVadeFarki => 'Simple Maturity Difference';

  @override
  String get odemeyiKaydet => 'Save Payment';

  @override
  String get labelOdemeTutari => 'Payment Amount *';

  @override
  String maksimumFormatmoneyRemaining(Object remaining) {
    return 'Maximum: $remaining';
  }

  @override
  String get labelOdemeTarihi => 'Payment Date';

  @override
  String get labelNotOpsiyonel => 'Note (Optional)';

  @override
  String get hintOdemeIleIlgiliNotlar => 'Notes about payment...';

  @override
  String get islemDetayi => 'Transaction Detail';

  @override
  String get islemRaporu => 'Transaction Report';

  @override
  String get tooltipTarihAraligi => 'Date Range';

  @override
  String get raporuPaylas => 'Share Report';

  @override
  String oncekiDonemeGorePercent(Object percent) {
    return '$percent% vs previous period';
  }

  @override
  String get msgSecilenTarihAraligindaIslem =>
      'No transaction in selected date range';

  @override
  String get degistir => 'Change';

  @override
  String get labelKategoriAdi => 'Category Name';

  @override
  String get hintOrnMarketKiraMaas => 'e.g. Market, Rent, Salary';

  @override
  String get ozelKategoriler => 'Custom Categories';

  @override
  String get varsayilanKategoriler => 'Default Categories';

  @override
  String get yeniKategoriEkle => 'Add New Category';

  @override
  String get temizle => 'Clear';

  @override
  String get labelMin => 'Min';

  @override
  String get labelMax => 'Max';

  @override
  String get hintNotIstegeBagliOrn => 'Note (Optional) · e.g. Grocery shopping';

  @override
  String get tekrarlamaIstegeBagli => 'Recurring (Optional)';

  @override
  String get tekrarEtme => 'Do Not Repeat';

  @override
  String get birikimDetayi => 'Savings Detail';

  @override
  String get vazgec => 'Cancel';

  @override
  String get sat => 'Sell';

  @override
  String get kaydiSil => 'Delete Record';

  @override
  String get tooltipFiyatlariGuncelle => 'Update Prices';

  @override
  String get hintSembolOrnAaplThyao => 'Symbol (e.g. AAPL, THYAO.IS)';

  @override
  String get sablonuSil => 'Delete Template';

  @override
  String hataError(Object error) {
    return 'Error: $error';
  }

  @override
  String get tooltipBuVadeyiAtla => 'Skip this installment';

  @override
  String get onayla => 'Confirm';

  @override
  String get kapat => 'Close';

  @override
  String get islemiDuzenle => 'Edit Transaction';

  @override
  String get labelYeniTutar => 'New Amount';

  @override
  String get kaydetVeOnayla => 'Save and Confirm';

  @override
  String get guvenlikAyarlari => 'Security Settings';

  @override
  String get iceAktarCsv => 'Import from Backup (CSV)';

  @override
  String get disaAktarCsv => 'Export (CSV)';

  @override
  String get geriYukle => 'Restore';

  @override
  String get yedekle => 'Backup';

  @override
  String get labelUygulamaTemasi => 'App Theme';

  @override
  String get labelCuzdanAdi => 'Wallet Name *';

  @override
  String get hintOrnAnaCuzdanTatil => 'e.g. Main Wallet, Vacation Fund';

  @override
  String get tamam => 'OK';

  @override
  String get beklenmeyenDurum => 'Unexpected situation';

  @override
  String get aktifCuzdaniniziDegistirmekIcin =>
      '• Click on a wallet to change your active wallet.';

  @override
  String get cuzdanBakiyeleriOtomatikOlarak =>
      '• Wallet balances are updated automatically.';

  @override
  String get herCuzdaninKendiGelir =>
      '• Each wallet has its own income/expense records.';

  @override
  String msgTextsCheckfailedprefixETostring(
      Object checkFailedPrefix, Object error) {
    return '$checkFailedPrefix: $error';
  }

  @override
  String msgPINVerificationFailedE(Object error) {
    return 'PIN verification failed: $error';
  }

  @override
  String get msgCreateAPinFirst => 'Create a PIN first';

  @override
  String get msgBiometricAuthenticationIsNot =>
      'Biometric authentication is not supported';

  @override
  String get msgBiometricAuthenticationFailed =>
      'Biometric authentication failed';

  @override
  String get msgBiometricLoginEnabled => 'Biometric login enabled';

  @override
  String get msgBiometricLoginDisabled => 'Biometric login disabled';

  @override
  String get msgPINAlreadyExistsUse =>
      'PIN already exists, use change PIN instead';

  @override
  String get msgPINsDoNotMatch => 'PINs do not match';

  @override
  String get msgPINSavedSuccessfully => 'PIN saved successfully';

  @override
  String get msgNewPinValuesDo => 'New PIN values do not match';

  @override
  String get msgCurrentPinIsIncorrect => 'Current PIN is incorrect';

  @override
  String get msgPINUpdatedSuccessfully => 'PIN updated successfully';

  @override
  String get msgPINRemoved => 'PIN removed';

  @override
  String get msgBackgroundLockAndPrivacy =>
      'Background lock and Privacy Guard enabled';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get manageYourAppSecurity => 'Manage your app security';

  @override
  String get createPin => 'Create PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get removePin => 'Remove PIN';

  @override
  String get msgBiometricAuthenticationCannotBe =>
      'Biometric authentication cannot be used on this device.';

  @override
  String get msgCreateAPinFirst2 =>
      'Create a PIN first to enable biometric login.';

  @override
  String get unifiedFeaturesDemo => 'Unified Features Demo';

  @override
  String get tarihSec => 'Select Date';

  @override
  String get dialog => 'Dialog';

  @override
  String get metinGiris => 'Text Input';

  @override
  String get yukle => 'Load';

  @override
  String get basarili => 'Success';

  @override
  String get hata => 'Error';

  @override
  String get yuklemeButonu => 'Loading Button';

  @override
  String get onayDialog => 'Confirmation Dialog';

  @override
  String get logoutLabel => 'Logout';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get enterPinPrompt => 'Enter PIN to continue';

  @override
  String get lockedOutPromptPrefix => 'Too many failed attempts. Wait';

  @override
  String get lockedOutPromptSuffix => 'seconds.';

  @override
  String get invalidPinFallback => 'Incorrect PIN, try again.';

  @override
  String get biometricReason => 'Authenticate to continue';

  @override
  String get settingsTitle => 'Security Settings';

  @override
  String get createPinTitle => 'Create PIN';

  @override
  String get changePinTitle => 'Change PIN';

  @override
  String get deletePinTitle => 'Remove PIN';

  @override
  String get verifyPinTitle => 'Verify PIN';

  @override
  String get deletePinConfirmMessage =>
      'Removing PIN will also disable biometric login. Continue?';

  @override
  String get saveLabel => 'Save';

  @override
  String get changeLabel => 'Change';

  @override
  String get removeLabel => 'Remove';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get pinMismatchMessage => 'PINs do not match';

  @override
  String get pinValidationMessage => 'Enter a 6-digit PIN';

  @override
  String get pinLockTitle => 'PIN Lock';

  @override
  String get pinEnabledSubtitle => 'PIN enabled';

  @override
  String get pinNotSetSubtitle => 'PIN not set';

  @override
  String get biometricLoginTitle => 'Biometric Login';

  @override
  String get biometricNotAvailableSubtitle =>
      'Biometric authentication is not available on this device';

  @override
  String get biometricEnabledSubtitle => 'Biometric login enabled';

  @override
  String get biometricDisabledSubtitle => 'Biometric login disabled';

  @override
  String get biometricAuthTileTitle => 'Biometric Authentication';

  @override
  String get biometricAuthTileSubtitleOn =>
      'On - Sign in with fingerprint or face recognition';

  @override
  String get biometricAuthTileSubtitleOff => 'Off';

  @override
  String get privacyGuardTitle => 'Privacy Guard';

  @override
  String get privacyGuardEnabledSubtitle => 'Screen protection enabled';

  @override
  String get privacyGuardDisabledSubtitle => 'Screen protection disabled';

  @override
  String get screenProtectionTileTitle => 'Screen Protection';

  @override
  String get screenProtectionTileSubtitleOn =>
      'On - Hide content while app is in background';

  @override
  String get screenProtectionTileSubtitleOff => 'Off';

  @override
  String get backgroundLockTitle => 'Background Lock';

  @override
  String get backgroundLockSubtitlePrefix => 'Locks after: ';

  @override
  String get backgroundLockSubtitleOff => 'Off';

  @override
  String get backgroundLockTileTitle =>
      'Require authentication when app stays in background';

  @override
  String get backgroundLockTileSubtitle =>
      'To enable background lock, set a PIN or enable biometric login.';

  @override
  String get backgroundLockTileInfo =>
      'Note: Authentication screen appears when returning to app.';

  @override
  String msgIncorrectPinRemainingTries(Object newAttempts) {
    return 'Incorrect PIN. Remaining tries: $newAttempts';
  }

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'APPEARANCE';

  @override
  String get security => 'SECURITY';

  @override
  String get dataBackupTransfer => 'DATA BACKUP / TRANSFER';

  @override
  String get about => 'ABOUT';

  @override
  String get googleDriveBackup => 'Google Drive Backup';

  @override
  String get googleDriveBackupDesc =>
      'Back up your data to your personal Google Drive account for safety.';

  @override
  String get connectGoogleDrive => 'Connect to Google Drive';

  @override
  String get account => 'Account:';

  @override
  String get lastBackup => 'Last Backup:';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get deleteBackup => 'Delete Backup';

  @override
  String get deleteBackupDesc =>
      'The backup file on Google Drive will be permanently deleted. Your local data is not affected.';

  @override
  String get backupDeleted => 'Backup deleted.';

  @override
  String get deleteBackupFailed => 'Could not delete backup.';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get noBackupsYet => 'No backups yet';

  @override
  String get restoreDataTitle => 'Restore Data?';

  @override
  String get restoreDataDesc =>
      'Your cloud data will overwrite the existing data on your device. This operation cannot be undone.';

  @override
  String get googleDriveConnected => 'Successfully connected to Google Drive.';

  @override
  String get googleDriveConnectionFailed => 'Google Drive connection failed.';

  @override
  String get googleDriveDisconnected => 'Google Drive disconnected.';

  @override
  String get dataBackedUpSuccess =>
      'Data successfully backed up to Google Drive.';

  @override
  String get backupFailed => 'Backup failed.';

  @override
  String get dataRestoredSuccess =>
      'Data successfully restored. Please restart the app for changes to take effect.';

  @override
  String get restoreFailedNoBackup => 'Restore failed. No backup file found.';

  @override
  String get defaultUser => 'User';

  @override
  String get dataExportImport => 'Device Backup / CSV';

  @override
  String get dataExportImportDesc =>
      'Save or restore a full app backup, or use CSV for current-wallet transaction transfers.';

  @override
  String get fullBackup => 'Full backup';

  @override
  String get saveFullBackupToDevice => 'Save Full Backup to Device';

  @override
  String get restoreFullBackupFromDevice => 'Restore Full Backup from Device';

  @override
  String get shareFullBackup => 'Share Full Backup';

  @override
  String get transactionCsv => 'Transaction CSV';

  @override
  String get restoreFullBackupTitle => 'Restore full backup?';

  @override
  String get restoreFullBackupDesc =>
      'This will replace wallets, transactions, investments, debts, receivables, budgets, recurring templates, users, and categories on this device.';

  @override
  String get fullBackupSaved => 'Full backup saved successfully.';

  @override
  String get fullBackupRestored => 'Full backup restored successfully.';

  @override
  String get fullBackupShared => 'Full backup shared successfully.';

  @override
  String get fullBackupCancelled => 'Backup action cancelled.';

  @override
  String get fullBackupShareText => 'CuNehat full backup';

  @override
  String get activeWalletRequiredForExport =>
      'An active wallet is required for exporting.';

  @override
  String get uygulamaBaslatilamadi => 'App could not start';

  @override
  String get verilerinizSilinmediTekrarDeneyin =>
      'Your data was not deleted. Try again; if the problem persists ';

  @override
  String get ikonBulunamadi => 'Icon not found';

  @override
  String valueTostringasfixedCurrencysymbol(
      Object toStringAsFixed, Object currencySymbol) {
    return '$toStringAsFixed $currencySymbol';
  }

  @override
  String get butcePlanlama => 'Budget Planning';

  @override
  String get henuzButceYok => 'No budgets yet';

  @override
  String get kategorilerinizeAylikHarcamaLimiti =>
      'Set a monthly spending limit for your categories,\ntrack your spending here.';

  @override
  String get bUAyToplamHarcama => 'TOTAL SPENDING THIS MONTH';

  @override
  String toplamLimitAppformattersCurrency(Object totalLimit) {
    return 'Total limit: $totalLimit';
  }

  @override
  String percent(Object percent) {
    return '$percent%';
  }

  @override
  String harcananAppformattersCurrencyFormat(Object spentAmount) {
    return 'Spent: $spentAmount';
  }

  @override
  String limitAppformattersCurrencyFormat(Object limitAmount) {
    return 'Limit: $limitAmount';
  }

  @override
  String get buKategorininButcesiVar =>
      'This category has a budget; limit will be updated.';

  @override
  String get finansalTakip => 'Financial Tracking';

  @override
  String get vADESIGecmis => 'OVERDUE';

  @override
  String get oDENDI => 'PAID';

  @override
  String vadeDebtTermmonthsAy(Object termMonths, Object length) {
    return 'Maturity: $termMonths Months | $length Payments';
  }

  @override
  String vadeDateformatDdMmm(Object dueDate) {
    return 'Maturity: $dueDate';
  }

  @override
  String get msgOdemesiTamamlanipKapatilanBorclarinizin =>
      'The history of your paid and closed debts will be displayed here.';

  @override
  String paidDebtsLengthBorcKapandi(Object length) {
    return '$length debts closed';
  }

  @override
  String get msgOdendiOlarakIsaretlenenAlacaklarinizin =>
      'The history of your receivables marked as paid will be displayed here.';

  @override
  String paidReceivablesLengthAlacakTahsil(Object length) {
    return '$length receivables collected';
  }

  @override
  String get toplamGeriOdeme => 'Total repayment';

  @override
  String get kKDFVeBsmvVergilerini => 'Include KKDF and BSMV taxes (30%)';

  @override
  String get tuketiciKredilerindeFaizeYasal =>
      'In consumer loans, 15% KKDF and 15% BSMV are legally added to the interest. In housing etc. loans, these taxes can be 0%. Activate accordingly.';

  @override
  String iTaksitAppformattersDateshort(Object i, Object scheduledDate) {
    return '$i. Installment — $scheduledDate';
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
  String get otomatikIslem => 'Automatic transaction';

  @override
  String get buIslemOtomatikOlusturuldu =>
      'This transaction was created automatically. Edit or delete it from the corresponding debt/investment/receivable record.';

  @override
  String get nakitAkisi => 'Cash Flow';

  @override
  String get grafikIcinYeterliVeri => 'Not enough data for chart';

  @override
  String get cizgiGrafikIcinEnAzIkiGun =>
      'At least two different days of transactions are required for the line chart.';

  @override
  String get detayGosterilecekIslemYok => 'No Transaction to Show Detail';

  @override
  String get gelirVeyaGiderKaydettikten =>
      'Analysis details will be listed here after you save income or expense.';

  @override
  String get henuzIslemYok => 'No transactions yet';

  @override
  String get buDonemIcinKayit =>
      'No records for this period.\nUse the slider button to add a new transaction.';

  @override
  String get haftalikNetAkis => 'Weekly Net Flow';

  @override
  String get kategoriDagilimi => 'Category Distribution';

  @override
  String titleIcinVeriYok(Object title) {
    return 'No data for $title';
  }

  @override
  String get buKategoriyeAitIslem =>
      'There are no transactions belonging to this category.';

  @override
  String formatMoneyItemTotalamountPercent(
      Object totalAmount, Object toStringAsFixed) {
    return '$totalAmount ($toStringAsFixed%)';
  }

  @override
  String get buDonemIcinHenuz =>
      'No transaction data found for this period yet. Reports will be compiled after data is entered.';

  @override
  String get ikonSecin => 'Select Icon';

  @override
  String get ikonDegistirmekIcinDokun => 'Tap to change icon';

  @override
  String categoriesWhereCC(Object customLength, Object defaultLength) {
    return '$customLength custom, $defaultLength default';
  }

  @override
  String get asagidakiButondanEkleyebilirsiniz =>
      'You can add from the button below';

  @override
  String get varsayilan => 'Default';

  @override
  String get filtreler => 'Filters';

  @override
  String get uygula => 'Apply';

  @override
  String get tARIHAraligi => 'DATE RANGE';

  @override
  String get seciliAralik => 'Selected Range';

  @override
  String get kATEGORIFiltresi => 'CATEGORY FILTER';

  @override
  String get kategoriBulunamadi => 'Category not found';

  @override
  String get fIYATAraligi => 'PRICE RANGE';

  @override
  String get yeni => 'New';

  @override
  String appFormattersDateshortFormatStartdate(
      Object startDate, Object endDate) {
    return '$startDate - $endDate';
  }

  @override
  String filterSelectedcategoriesLengthKategori(Object length) {
    return '$length Categories';
  }

  @override
  String get gunSonu => 'End of day ';

  @override
  String netNetAppformattersCurrency(Object net) {
    return 'Net: $net';
  }

  @override
  String get gorunumListe => 'List';

  @override
  String get gorunumTakvim => 'Calendar';

  @override
  String get takvimAy => 'Month';

  @override
  String get takvimHafta => 'Week';

  @override
  String get buGuneAitIslemYok => 'No transactions on this day';

  @override
  String dataFilterSelectedcategoriesLengthKategori(Object length) {
    return '$length Categories';
  }

  @override
  String countCountlabel(Object count, Object countLabel) {
    return '$count $countLabel';
  }

  @override
  String get portfoyDetayi => 'Portfolio Detail';

  @override
  String get henuzYatirimKaydiYok => 'No Investment Record Yet';

  @override
  String get yatirimlariniziEklediktenSonraDetayli =>
      'Detailed analyses will appear here after you add your investments.';

  @override
  String guncelDegerFormatmoneyInvestment(Object currentValue) {
    return 'Current value ($currentValue) will be processed as income to the wallet and the record will be closed.';
  }

  @override
  String hataliGirislerIcinAlim(Object amount) {
    return 'For incorrect entries: purchase expense ($amount) will be refunded with a correction record, and the balance will revert to pre-investment.\n\nIf you actually sold it, use \"Sell\" instead.';
  }

  @override
  String get portfoyum => 'My Portfolio';

  @override
  String investmentsLengthYatirim(Object length) {
    return '$length investments';
  }

  @override
  String get mevcutDeger => 'Current Value';

  @override
  String get maliyetiDegistirirsenizFarkCuzdana =>
      'If you change the cost, the difference will be processed as a correction transaction to the wallet.';

  @override
  String get hesapla => 'Calculate';

  @override
  String birikmisFormatmoneyInvCurrentvalue(Object currentValue) {
    return 'Accumulated: $currentValue / ';
  }

  @override
  String get guncelFiyatiGetir => 'Get Current Price';

  @override
  String get ekle => 'Add';

  @override
  String get karZarar => 'Profit/Loss';

  @override
  String investmentProfitpercentageTostringasfixed(Object toStringAsFixed) {
    return '$toStringAsFixed%';
  }

  @override
  String hedefCurrencyformatFormatInvestment(Object targetAmount) {
    return 'Target: $targetAmount';
  }

  @override
  String investmentTargetprogressTostringasfixed(Object toStringAsFixed) {
    return '$toStringAsFixed%';
  }

  @override
  String get grafikIcinYatirimBulunmuyor => 'No investments for chart';

  @override
  String get portfoyDagilimi => 'Portfolio Distribution';

  @override
  String percentage(Object percentage) {
    return '$percentage%';
  }

  @override
  String get tOPLAMPortfoyDegeri => 'TOTAL PORTFOLIO VALUE';

  @override
  String get tOPLAMMaliyet => 'TOTAL COST';

  @override
  String get kAZANCZarar => 'PROFIT / LOSS';

  @override
  String isProfitTotalprofitpercentageTostringasfixed(
      Object isProfit, Object toStringAsFixed) {
    return '$isProfit$toStringAsFixed%';
  }

  @override
  String templateTitleDuzenliIslemi(Object title) {
    return 'Delete recurring transaction \"$title\"?\n\nPast transactions recorded in the ledger will not be deleted.';
  }

  @override
  String get duzenliIslemler => 'Recurring Transactions';

  @override
  String get henuzDuzenliIslemYok => 'No recurring transactions yet';

  @override
  String get islemEklerkenTekrarSikligi =>
      'If you select repeat frequency while adding a transaction\nthe template appears here.';

  @override
  String get bekleyenDuzenliIslemler => 'Pending Recurring Transactions';

  @override
  String get vadesiGelmisIslemlerinizVar =>
      'You have transactions whose maturity has arrived. You can approve them to be recorded in the ledger.';

  @override
  String titleTarihDatestrNtutarTx(Object dateStr, Object amount) {
    return 'Date: $dateStr\nAmount: $amount';
  }

  @override
  String get ibo => 'Ibo';

  @override
  String get uygulamaKilidi => 'App Lock';

  @override
  String get pINBiyometrikVeGizlilik => 'PIN, Biometric and Privacy Settings';

  @override
  String get otomatikHesaplananDegerler => 'Automatically calculated values:';

  @override
  String get borcAlacakYatirimKayitlarindan =>
      'Derived from debt/receivable/investment records; cannot be edited here.';

  @override
  String get renkSecin => 'Select Color:';

  @override
  String get ikonSecin2 => 'Select Icon:';

  @override
  String get ikonDegistir => 'Change Icon';

  @override
  String get cuzdanlarim => 'My Wallets';

  @override
  String get cuzdanlariniziYonetin => 'Manage your wallets';

  @override
  String get yeniCuzdanOlustur => 'Create New Wallet';

  @override
  String get finansalNyolculugunuzBasliyor => 'Your Financial\nJourney Begins';

  @override
  String get ilkCuzdaniOlustur => 'Create First Wallet';

  @override
  String olusturulmaAppformattersDateshortFormat(Object createdAt) {
    return 'Created: $createdAt';
  }

  @override
  String get aktif => 'Active';

  @override
  String get aktifOlanCuzdanSilinemez =>
      '• Active wallet cannot be deleted. To delete, first make another wallet active.';

  @override
  String get cuzdanlarinizaAitBorcAlacak =>
      '• You can manually manage Debt, Receivable, and Savings amounts of your wallets from the edit page.';

  @override
  String get msgPINOrBiometricLogin =>
      'PIN or biometric login is required for background lock';

  @override
  String get sharedFeatures => 'Shared Features';

  @override
  String get tarihAraligi => 'Date Range';

  @override
  String get butonGalerisi => 'Button Gallery';

  @override
  String get internetBaglantisiAktif => 'Internet connection is active';

  @override
  String get internetBaglantisiYok => 'No internet connection';

  @override
  String get baglantiKontrolEdiliyor => 'Checking connection...';

  @override
  String get taksit1 => '1 installment';

  @override
  String get taksit2 => '2 installments';

  @override
  String get tamaminiOde => 'Pay all';

  @override
  String get sliderSavings => 'SAVINGS';

  @override
  String get sliderTransactions => 'TRANSACTIONS';

  @override
  String get sliderDebt => 'DEBT';

  @override
  String get recurringTransactions => 'Recurring Transactions';

  @override
  String get budgetPlanning => 'Budget Planning';

  @override
  String get drawerBalance => 'Balance';

  @override
  String get drawerInvestment => 'Investment';

  @override
  String get drawerDebt => 'Debt';

  @override
  String get createWallet => 'Create Wallet';

  @override
  String get selectWallet => 'Select Wallet';

  @override
  String get wallet => 'Wallet';

  @override
  String get menuGold => 'Gold';

  @override
  String get menuStock => 'Stock';

  @override
  String get menuCustom => 'Custom';

  @override
  String get menuDetails => 'Details';

  @override
  String get menuIncome => 'Income';

  @override
  String get menuExpense => 'Expense';

  @override
  String get menuReport => 'Report';

  @override
  String get menuDebt => 'Debt';

  @override
  String get menuReceivable => 'Receivable';

  @override
  String get menuHistory => 'History';

  @override
  String get themeSysLight => 'System [Light]';

  @override
  String get themeSysDark => 'System [Dark]';

  @override
  String get cuzdanOlusturunuz => 'Create a wallet';

  @override
  String get cuzdanSeciniz => 'Select a wallet';

  @override
  String get yerelMod => 'Local Mode';

  @override
  String get henuzCuzdanOlusturmadiniz => 'No wallet created yet';

  @override
  String get cuzdanOlusturuldu => 'Wallet created!';

  @override
  String get cuzdanGuncellendi => 'Wallet updated!';

  @override
  String get cuzdanSilindi => 'Wallet deleted!';

  @override
  String get cuzdanSecildi => 'Wallet selected';

  @override
  String get disaAktarilacakIslemBulunamadi => 'No transactions to export.';

  @override
  String get islemlerDisaAktarildi => 'Transactions exported successfully.';

  @override
  String get csvGecerliIslemBulunamadi => 'No valid transactions found in CSV.';

  @override
  String get iceAktarilanCuzdanPrefix => 'Imported Wallet';

  @override
  String get verilerIceAktarildi =>
      'Data imported successfully. New wallet created and selected.';

  @override
  String get cuzdanOlusturulamadi => 'Failed to create wallet';

  @override
  String satirAtlandi(int count) {
    return '$count rows skipped due to date/amount errors.';
  }

  @override
  String get guncelle => 'Update';

  @override
  String get kaydet => 'Save';

  @override
  String get islem => 'Transaction';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearly => 'Yearly';

  @override
  String get kategoriDuzenle => 'Edit Category';

  @override
  String get yeniKategori => 'New Category';

  @override
  String get kategoriAdiBosOlamaz => 'Category name cannot be empty';

  @override
  String get enAz2KarakterOlmali => 'Must be at least 2 characters';

  @override
  String get kategoriAdiRezerve =>
      'This name is reserved for automatic system transactions';

  @override
  String get kategoriOlusturuldu => 'Category created!';

  @override
  String get kategoriGuncellendi => 'Category updated!';

  @override
  String get kategoriSilindi => 'Category deleted!';

  @override
  String get kategoriSilTitle => 'Delete Category';

  @override
  String kategoriSilConfirmMessage(Object id) {
    return 'Are you sure you want to delete the category \"$id\"?\n\nThis action cannot be undone.';
  }

  @override
  String kategorilerYuklenemedi(Object error) {
    return 'Failed to load categories: $error';
  }

  @override
  String get giderKategorileri => 'Expense Categories';

  @override
  String get gelirKategorileri => 'Income Categories';

  @override
  String get varsayilanKategoriYok => 'No default categories';

  @override
  String get henuzOzelKategoriYok => 'No custom categories yet';

  @override
  String get duzenleSubtitle => 'Amount, date, category and other details';

  @override
  String get islemiSil => 'Delete Transaction';

  @override
  String get silSubtitle => 'Balance reverts to previous state';

  @override
  String get gramAltin => 'Gram Gold';

  @override
  String get ceyrekAltin => 'Quarter Gold';

  @override
  String get yarimAltin => 'Half Gold';

  @override
  String get tamAltin => 'Full Gold';

  @override
  String get cumhuriyetAltini => 'Republic Gold';

  @override
  String get ataAltin => 'Ata Gold';

  @override
  String get fiyatAliniyor => 'Fetching price...';

  @override
  String get fiyatAlinamadi => 'Failed to fetch price.';

  @override
  String guncelFiyatFormatTry(Object price) {
    return 'Current Price: $price ₺';
  }

  @override
  String guncelFiyatFormatForeign(
      Object price, Object currency, Object priceTl) {
    return 'Current Price: $price $currency (≈$priceTl ₺)';
  }

  @override
  String get gecerliYatirimMiktariGirin => 'Enter a valid investment amount';

  @override
  String get gecerliMevcutDegerGirin => 'Enter a valid current value';

  @override
  String get altinYatirimi => 'Gold Investment';

  @override
  String get altinTuruVeOtomatikFiyat => 'Gold Type & Live Price';

  @override
  String get yatirimDetaylari => 'Investment Details';

  @override
  String get altinNotHint => 'Note (Optional) · e.g. Wedding Golds';

  @override
  String get maliyetYatirilanAnaPara => 'Cost (Invested Principal)';

  @override
  String get hedefTutarIstegeBagli => 'Target Amount (Optional)';

  @override
  String get hedefKategorisi => 'Target Category';

  @override
  String get renkSecimi => 'Color Selection';

  @override
  String get altinYatiriminiDuzenle => 'Edit Gold Investment';

  @override
  String get yeniAltinEkle => 'Add New Gold';

  @override
  String get adet => 'Qty';

  @override
  String get sembolGirin => 'Enter symbol!';

  @override
  String get hisseYatirimi => 'Stock Investment';

  @override
  String get hisseSenediBul => 'Find Stock';

  @override
  String get hisseNotHint => 'Note (Optional) · e.g. Long-term purchase';

  @override
  String get hisseYatiriminiDuzenle => 'Edit Stock Investment';

  @override
  String get yeniHisseEkle => 'Add New Stock';

  @override
  String get gecerliHedefTutarGirin => 'Enter a valid target amount';

  @override
  String get ozelYatirimi => 'Custom Investment';

  @override
  String get customNotHint => 'Note (Optional) · e.g. Land, Crypto, Forex';

  @override
  String get ozelYatiriminiDuzenle => 'Edit Custom Investment';

  @override
  String get yeniOzelYatirimEkle => 'Add New Custom Investment';

  @override
  String get varlikEkle => 'Add Asset';

  @override
  String get hedefeParaEkle => 'Add Money to Target';

  @override
  String get paraEkle => 'Add Money';

  @override
  String get yeniAlimMiktarVeOdenenTutar =>
      'New purchase: amount and paid value';

  @override
  String get maliyeteVeDegereEklenir =>
      'Added to cost and value, deducted from wallet';

  @override
  String get fiyatiGuncelle => 'Update Price';

  @override
  String get canliFiyatGuncellemeAciklamasi =>
      'Current value = quantity × live price; does not affect balance';

  @override
  String get duzenleYatirimSubtitle => 'Name, cost, target and other details';

  @override
  String get satSubtitle => 'Current value is processed as income to wallet';

  @override
  String get kaydiSilSubtitle =>
      'Incorrect entry correction; purchase expense is refunded';

  @override
  String varlikEkleTitle(Object name) {
    return '$name · Add Asset';
  }

  @override
  String paraEkleTitle(Object name) {
    return '$name · Add Money';
  }

  @override
  String get alinanMiktarAltinHint => 'Amount bought (e.g. gram/qty)';

  @override
  String get alinanAdetHisseHint => 'Shares bought (lot)';

  @override
  String get odenenTutarHint => 'Amount paid (₺) · 0 if gift';

  @override
  String get tutarHint => 'Amount (₺)';

  @override
  String get gecerliMiktarGirin => 'Enter a valid amount';

  @override
  String get gecerliOdenenTutarGirin => 'Enter a valid paid amount';

  @override
  String get gecerliTutarGirin => 'Enter a valid amount';

  @override
  String get baslikGirin => 'Enter title';

  @override
  String get borcluKisiAdiGirin => 'Enter debtor name';

  @override
  String get kurumKisiGirin => 'Enter institution/person';

  @override
  String get vadeEnAz1Olmali => 'Maturity must be at least 1 month';

  @override
  String get aylikTaksitTutariniGirin => 'Enter monthly installment amount';

  @override
  String get aylikTaksitKrediTutarindanKucuk =>
      'Monthly installment × term can\'t be less than the loan amount';

  @override
  String get krediHesaplamaInfoBaslik => 'Bank loan calculation';

  @override
  String get krediHesaplamaInfoGovde =>
      '• I know the monthly installment: Enter the installment your bank quoted. Total repayment = monthly installment × term. For convenience the field suggests loan amount ÷ term as an interest-free starting point; change it to your own installment.\n\n• With interest rate: Enter your bank\'s monthly interest rate. The installment and total are computed with the equal-installment (amortization) method.';

  @override
  String get borcTuruLabel => 'Debt type';

  @override
  String get borcBaslikHint => 'Title · e.g. Housing Loan';

  @override
  String get kurumKisiHint => 'Institution / Person · e.g. Ziraat Bank';

  @override
  String get kisiAdiHint => 'Person Name';

  @override
  String get vadeVeDetaylarLabel => 'Maturity & details';

  @override
  String get borcluKisiAdiHint => 'Debtor name';

  @override
  String get borcDuzenleTitle => 'Edit Debt';

  @override
  String get alacakDuzenleTitle => 'Edit Receivable';

  @override
  String get yeniBorcTitle => 'New Debt';

  @override
  String get yeniAlacakTitle => 'New Receivable';

  @override
  String get krediTutariAnaPara => 'Loan amount (principal)';

  @override
  String get borcTutariAnaPara => 'Debt amount (principal)';

  @override
  String get alacakTutari => 'Receivable amount';

  @override
  String get toplamTutar => 'Total amount';

  @override
  String get vadeFarkiLabel => 'Maturity difference';

  @override
  String get toplamFaizLabel => 'Total interest';

  @override
  String get aylikTaksitLabel => 'Monthly installment (≈)';

  @override
  String get debtTypeBankLoan => 'Bank Loan';

  @override
  String get debtTypeInstallment => 'Installment';

  @override
  String get debtTypePersonal => 'Personal';

  @override
  String get debtTypeOther => 'Other';

  @override
  String get vadeAyHint => 'Maturity (months)';

  @override
  String get aylikTaksitHint => 'Monthly Installment';

  @override
  String get vadeFarkiYuzdeHint => 'Maturity Difference %';

  @override
  String get aylikFaizYuzdeHint => 'Monthly Interest %';

  @override
  String get gecikmeFaiziYuzdeHint => 'Overdue interest (%)';

  @override
  String get baslangicLabel => 'Start';

  @override
  String get vadeLabel => 'Due Date';

  @override
  String get toplamBorcLabel => 'Total Debt:';

  @override
  String get odenenLabel => 'Paid:';

  @override
  String get kalanLabel => 'Remaining:';

  @override
  String get kalanTutardanFazlaOlamaz => 'Cannot exceed remaining amount';

  @override
  String taksitPlaniFormat(Object months) {
    return 'Installment Plan ($months months)';
  }

  @override
  String odemeGecmisiFormat(Object count) {
    return 'Payment History ($count)';
  }

  @override
  String get gecikmis => 'Overdue';

  @override
  String get bekleniyor => 'Pending';

  @override
  String get cuzdanDuzenleTitle => 'Edit Wallet';

  @override
  String get yeniCuzdanEkleTitle => 'Add New Wallet';

  @override
  String get cuzdanAdiBosOlamaz => 'Wallet name cannot be empty';

  @override
  String get cuzdanAdiEnAz2Karakter =>
      'Wallet name must be at least 2 characters';

  @override
  String get bakiyeLabel => 'Balance *';

  @override
  String get baslangicBakiyesiLabel => 'Initial Balance *';

  @override
  String get bakiyeBosOlamaz => 'Balance cannot be empty';

  @override
  String get gecerliBirSayiGirin => 'Enter a valid number';

  @override
  String get tutarCokBuyuk => 'Amount too large';

  @override
  String get borcLabel => 'Debt';

  @override
  String get alacakLabel => 'Receivable';

  @override
  String get birikimLabel => 'Savings';

  @override
  String get olustur => 'Create';

  @override
  String get ozelRenkSecin => 'Select Custom Color';

  @override
  String get cuzdanYonetimiTitle => 'Wallet Management';

  @override
  String get dateBadgeToday => 'TODAY';

  @override
  String get dateBadgeYesterday => 'YESTERDAY';

  @override
  String get dateBadgeThisWeek => 'THIS WEEK';

  @override
  String get dateBadgeLastWeek => 'LAST WEEK';

  @override
  String get dateBadgeThisMonth => 'THIS MONTH';

  @override
  String get dateBadgeLastMonth => 'LAST MONTH';

  @override
  String get categoryFinans => 'Finance';

  @override
  String get categoryGrafikler => 'Charts';

  @override
  String get categoryIsVeOfis => 'Work & Office';

  @override
  String get categoryAlisveris => 'Shopping';

  @override
  String get categoryYemekVeIcecek => 'Food & Drink';

  @override
  String get categoryUlasim => 'Transport';

  @override
  String get categoryEvVeYasam => 'Home & Life';

  @override
  String get categoryEglence => 'Entertainment';

  @override
  String get categorySaglikVeSpor => 'Health & Sports';

  @override
  String get categoryEgitim => 'Education';

  @override
  String get categoryKisiselBakim => 'Personal Care';

  @override
  String get categoryHayvanlar => 'Animals';

  @override
  String get categorySeyahat => 'Travel';

  @override
  String get categoryTeknoloji => 'Technology';

  @override
  String get categoryIletisim => 'Communication';

  @override
  String get categoryHediyeVeBagis => 'Gifts & Donation';

  @override
  String get categoryHizmetler => 'Services';

  @override
  String get categoryDiger => 'Other';

  @override
  String get defaultCategoryFood => 'Food';

  @override
  String get defaultCategoryTransport => 'Transport';

  @override
  String get defaultCategoryShopping => 'Shopping';

  @override
  String get defaultCategoryBills => 'Bills';

  @override
  String get defaultCategoryEntertainment => 'Entertainment';

  @override
  String get defaultCategorySalary => 'Salary';

  @override
  String get defaultCategoryInvestment => 'Investment';

  @override
  String get defaultCategoryFreelance => 'Freelance';

  @override
  String get kategorisiz => 'Uncategorized';

  @override
  String get detailLabelTarih => 'Date';

  @override
  String get detailLabelSaat => 'Time';

  @override
  String get detailLabelTur => 'Type';

  @override
  String get detailLabelGelir => 'Income';

  @override
  String get detailLabelGider => 'Expense';

  @override
  String get detailLabelIslemSonrasiBakiye => 'Balance after transaction';

  @override
  String get akilliIcgoruler => 'Smart Insights';

  @override
  String get gunlukOrtalamaHarcama => 'Daily average spending';

  @override
  String get enCokHarcananGun => 'Your top spending day';

  @override
  String get enCokHarcananKategori => 'Top spending category';

  @override
  String get enBuyukHarcama => 'Largest expense';

  @override
  String get birikimOrani => 'Savings rate';

  @override
  String get buDonemdeIslemYok => 'No transactions in this period';

  @override
  String get tekrarlayanOdemeler => 'Recurring payments';

  @override
  String tekrarlayanTespitOzeti(int count) {
    return 'We detected $count possible recurring payments';
  }

  @override
  String kezTekrarlandi(int count) {
    return 'Repeated $count times';
  }

  @override
  String get duzenliOdemeOlarakEkle => 'Add as recurring';

  @override
  String duzenliOdemeEklendi(String title) {
    return '\'$title\' added to recurring payments';
  }

  @override
  String get duzenliOdemeEklenemedi => 'Couldn\'t add recurring payment';

  @override
  String get borcNakitEtkiBaslik => 'What did you receive for this debt?';

  @override
  String get borcNakitEtkiAciklama =>
      'Your wallet balance is updated automatically based on your choice; no manual transaction needed.';

  @override
  String get borcNakitSecenekBaslik => 'I received cash';

  @override
  String borcNakitSecenekGovde(String tutar) {
    return '$tutar is added to your wallet balance as income. Your repayments are deducted from the balance as expenses.';
  }

  @override
  String get borcUrunSecenekBaslik => 'I bought a product / service';

  @override
  String get borcUrunSecenekGovde =>
      'Since no cash reached you, your balance doesn\'t change. Your installments and repayments are deducted as expenses.';

  @override
  String get devamEt => 'Continue';

  @override
  String get bugun => 'Today';

  @override
  String get islemBuguneAyarliIpucu =>
      'The date is set to today — tap the date to add it to another day.';

  @override
  String get mevcutDegerAciklama =>
      'The investment\'s current market value; updated from the live price with \'Calculate\'.';

  @override
  String get toplamMaliyetAciklama =>
      'The total you paid for this investment (your cost). \'Calculate\' doesn\'t change it; profit/loss is computed from it.';

  @override
  String get paraBirimiLabel => 'Currency';

  @override
  String get paraBirimiKilitliHint =>
      'The currency of a wallet with transaction history can\'t be changed';

  @override
  String get sadeceTlCuzdanBorc =>
      'Debt & receivable tracking is only available in TRY wallets for now';

  @override
  String get sadeceTlCuzdanYatirim =>
      'Investment tracking is only available in TRY wallets for now';

  @override
  String yaklasikKarsilikFormat(String tutar) {
    return '≈ $tutar';
  }

  @override
  String toplamTlKarsilikFormat(String tutar) {
    return 'Total ≈ $tutar';
  }

  @override
  String get cuzdanlarArasiTransfer => 'Transfer Between Wallets';

  @override
  String get transferEt => 'Transfer';

  @override
  String get transferHedefCuzdan => 'Target wallet';

  @override
  String transferOnizlemeFormat(String tutar) {
    return 'Target will receive ≈ $tutar';
  }

  @override
  String get transferKurYok =>
      'Couldn\'t get the exchange rate — try again when online';

  @override
  String get transferBasarili => 'Transfer completed';

  @override
  String get transferBasarisiz => 'Transfer failed';

  @override
  String get transferIcinIkiCuzdanGerekli =>
      'You need at least two wallets to transfer';

  @override
  String transferBakiyeAsimiMesaj(String bakiye) {
    return 'The amount exceeds the wallet balance ($bakiye). Continuing will push the balance below zero. Continue?';
  }

  @override
  String get yardimVeTurlar => 'Help & Tours';

  @override
  String get genelTanitimiTekrarGoster => 'Replay Privacy & Notification Intro';

  @override
  String get yatirimBirikimTuru => 'Investments/Savings Tour';

  @override
  String get islemlerTuru => 'Transactions Tour';

  @override
  String get borcAlacakTuru => 'Debts & Receivables Tour';

  @override
  String get onboardingInvestmentSummaryTitle => 'Your Total Savings';

  @override
  String get onboardingInvestmentSummaryDesc =>
      'See your total investment, current value, and profit/loss at a glance here.';

  @override
  String get onboardingInvestmentPortfolioTitle => 'Your Portfolio';

  @override
  String get onboardingInvestmentPortfolioDesc =>
      'Your gold, stock, and custom investments are listed here. Tap a card to contribute, sell, edit, or delete.';

  @override
  String get onboardingTransactionsFilterTitle => 'Mode & Filters';

  @override
  String get onboardingTransactionsFilterDesc =>
      'Switch between Income/Expense mode and filter by category, date, or amount.';

  @override
  String get onboardingTransactionsViewToggleTitle => 'List / Calendar';

  @override
  String get onboardingTransactionsViewToggleDesc =>
      'Browse your transactions in a list or calendar view.';

  @override
  String get onboardingDebtTabsTitle => 'My Debts / My Receivables';

  @override
  String get onboardingDebtTabsDesc =>
      'Track what you owe and what\'s owed to you in separate tabs here.';

  @override
  String get onboardingNavHintHeader => 'How to Navigate';

  @override
  String get onboardingNavHintSwipeTitle => 'Swipe Left / Right';

  @override
  String get onboardingNavHintSwipeDesc =>
      'Switch between the Investments, Transactions, and Debts screens.';

  @override
  String get onboardingNavHintDragTitle => 'Drag Upward';

  @override
  String get onboardingNavHintDragDesc =>
      'Reach sub-pages like Details, Report, Pending, and History.';

  @override
  String get onboardingNavHintAddTitle => 'Tap an Icon';

  @override
  String get onboardingNavHintAddDesc =>
      'Add a new income, expense, investment, debt, or receivable.';

  @override
  String get onboardingInvestmentDetailTitle => 'Savings Detail';

  @override
  String get onboardingInvestmentDetailDesc =>
      'See all buy/sell activity for your investments here, in chronological order.';

  @override
  String get onboardingTransactionsInsightsTitle => 'Smart Insights';

  @override
  String get onboardingTransactionsInsightsDesc =>
      'Automatic observations about your spending habits and possible recurring payments appear here.';

  @override
  String get onboardingTransactionsReportTitle => 'Transaction Report';

  @override
  String get onboardingTransactionsReportDesc =>
      'Explore income/expense breakdowns with charts for your selected date range, and export them.';

  @override
  String get onboardingDebtHistoryTitle => 'History';

  @override
  String get onboardingDebtHistoryDesc =>
      'The full history of paid-off debts and collected receivables is kept here.';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get notificationSettingsDesc =>
      'Manage your critical and random notification preferences.';

  @override
  String get randomReminders => 'Motivational Reminders';

  @override
  String get randomRemindersOff => 'Off';

  @override
  String get randomRemindersLow => 'Low (1/day)';

  @override
  String get randomRemindersMedium => 'Medium (2/day)';

  @override
  String get randomRemindersHigh => 'High (3/day)';

  @override
  String get criticalNotifications => 'Critical Notifications';

  @override
  String get debtReminders => 'Debt/Receivable Reminders';

  @override
  String get recurringReminders => 'Recurring Transaction Reminders';

  @override
  String get budgetAlerts => 'Budget Alerts';

  @override
  String get notificationRationaleTitle => 'Notifications';

  @override
  String get notificationRationaleBody =>
      'CuNehat can remind you when debt and receivable due dates approach and when recurring transactions await approval. This requires notification permission. You can keep using the app without it; you just won\'t see reminders.';

  @override
  String get notificationRationaleLater => 'Not Now';

  @override
  String get notificationPermissionOffTitle => 'Notification permission is off';

  @override
  String get notificationPermissionOffDesc =>
      'The reminders below can only reach you once system permission is granted.';

  @override
  String get notificationPermissionGrant => 'Allow';

  @override
  String get notificationPermissionOpenSettings =>
      'Permission was denied earlier. Enable it from System settings → Apps → CuNehat → Notifications.';

  @override
  String get notificationSendTest => 'Send a test notification';

  @override
  String get notificationTestSent => 'Test notification sent';

  @override
  String get notificationTestTitle => 'CuNehat test notification';

  @override
  String get notificationTestBody =>
      'Notifications are working. Your reminders will look like this.';

  @override
  String get notifChannelCriticalName => 'Critical Reminders';

  @override
  String get notifChannelCriticalDesc => 'Debt due dates and budget overruns';

  @override
  String get notifChannelRecurringName => 'Recurring Transactions';

  @override
  String get notifChannelRecurringDesc =>
      'Reminders for recurring transactions awaiting approval';

  @override
  String get notifChannelMotivationalName => 'Motivational Reminders';

  @override
  String get notifChannelMotivationalDesc =>
      'Daily nudges to log your spending';

  @override
  String get notifRecurringDueTitle => 'Recurring Transaction Due';

  @override
  String notifRecurringDueBody(Object title) {
    return '$title is waiting for your approval.';
  }

  @override
  String get notifDebtUpcomingTitle => 'Debt Reminder';

  @override
  String notifDebtUpcomingBody(Object title) {
    return 'The due date for $title is approaching.';
  }

  @override
  String get notifDebtDueTitle => 'Debt Due Today!';

  @override
  String notifDebtDueBody(Object title) {
    return 'The due date for $title is today.';
  }

  @override
  String get notifBudgetWarningTitle => 'Budget Warning';

  @override
  String notifBudgetWarningBody(Object category) {
    return 'You have reached 80% of your $category budget.';
  }

  @override
  String get notifBudgetExceededTitle => 'Budget Exceeded!';

  @override
  String notifBudgetExceededBody(Object category) {
    return 'You have exceeded your $category budget.';
  }

  @override
  String get notifDailyReminderTitle => 'CuNehat';

  @override
  String get notifDailyReminder1 =>
      'Logged any spending today? Keep your budget current!';

  @override
  String get notifDailyReminder2 => 'Time to check in on your finances!';

  @override
  String get notifDailyReminder3 =>
      'Tracking income and expenses protects your budget.';

  @override
  String get notifDailyReminder4 => 'Small savings lead to big goals!';

  @override
  String get notifDailyReminder5 => 'Don\'t forget to review your spending.';

  @override
  String get notifDailyReminder6 => 'Plan your budget, live at ease!';

  @override
  String bekleyenVadeSayisi(Object count) {
    return '$count occurrences due';
  }

  @override
  String get tumunuOnayla => 'Approve All';

  @override
  String get tumunuOnaylaBaslik => 'Approve backlog';

  @override
  String tumunuOnaylaAciklama(Object title, Object count) {
    return 'All $count outstanding occurrences of \"$title\" will be recorded in the ledger.';
  }

  @override
  String get buVadeyiAtla => 'Skip this occurrence';

  @override
  String get sablonuSilAciklama =>
      'Delete template (including future occurrences)';

  @override
  String get tumTurlariSifirla => 'Reset All Tours';

  @override
  String get tumTurlariSifirlaAciklama =>
      'Including sub-page tours — they\'ll show again as you revisit each screen.';

  @override
  String get tumTurlarSifirlandi => 'Tours reset';

  @override
  String get onboardingAppBarMenuTitle => 'Menu';

  @override
  String get onboardingAppBarMenuDesc =>
      'Access budgets, recurring transactions, profile, and settings from here.';

  @override
  String get onboardingAppBarWalletTitle => 'Your Wallet';

  @override
  String get onboardingAppBarWalletDesc =>
      'The active wallet\'s name and balance show here. Tap to switch between wallets or add a new one.';

  @override
  String get onboardingWalletManagementTitle => 'Add a New Wallet';

  @override
  String get onboardingWalletManagementDesc =>
      'Create a new wallet here for a different account or currency.';

  @override
  String get onboardingTransactionsAddTitle => 'Enter the Amount';

  @override
  String get onboardingTransactionsAddDesc =>
      'Type the amount, then pick a category and date, and save. You can also set a repeat frequency.';

  @override
  String get onboardingDebtAddTitle => 'Enter the Amount';

  @override
  String get onboardingDebtAddDesc =>
      'Choose the debt/receivable amount and type; fill in details like due date and installments below.';

  @override
  String get onboardingInvestmentAddTitle => 'Current Value';

  @override
  String get onboardingInvestmentAddDesc =>
      'Enter the investment\'s current value. Fill in details like quantity, type, and an optional target below.';

  @override
  String get onboardingBudgetsTitle => 'Add a New Budget';

  @override
  String get onboardingBudgetsDesc =>
      'Pick a category and set a monthly spending limit; you\'ll be notified if you exceed it.';

  @override
  String get onboardingRecurringTemplatesTitle => 'Recurring Transactions';

  @override
  String get onboardingRecurringTemplatesDesc =>
      'Templates created from the repeat option when adding income/expense are listed here; pause or delete them.';

  @override
  String get fisEkle => 'Add receipt/photo';

  @override
  String get fisEkli => 'Receipt attached';

  @override
  String get fisKamera => 'Camera';

  @override
  String get fisGaleri => 'Gallery';

  @override
  String get fisDegistir => 'Replace';

  @override
  String get fisKaldir => 'Remove';

  @override
  String get fisGoruntule => 'View receipt';

  @override
  String get fisOcrTaraniyor => 'Scanning receipt…';

  @override
  String get fisOcrDolduruldu =>
      'Filled from the receipt — please double-check';

  @override
  String get fisCihazdaYok => 'Image not on this device';

  @override
  String get bankImportSettingsEntry => 'Import bank statement';

  @override
  String get bankImportSettingsSubtitle =>
      'Turn a CSV/Excel/PDF statement into transactions';

  @override
  String get bankImportTitle => 'Import Bank Statement';

  @override
  String get bankImportParsing => 'Scanning file…';

  @override
  String get bankImportNoWallet => 'Create a wallet first.';

  @override
  String get bankImportSetupHint =>
      'Pick the account activity file you exported from your bank (CSV, Excel, or PDF) — we detect the format automatically. Transactions are shown for review with an auto-detected date/amount/category — this detection can be wrong, so double-check everything before approving.';

  @override
  String get bankImportTargetWallet => 'Target wallet';

  @override
  String get bankImportPickFile => 'Pick file & scan';

  @override
  String get bankImportCommitting => 'Adding…';

  @override
  String get bankImportClose => 'Close';

  @override
  String get bankImportRetry => 'Try again';

  @override
  String get bankImportMappingTitle => 'Map columns';

  @override
  String get bankImportColDate => 'Date column';

  @override
  String get bankImportColDesc => 'Description column';

  @override
  String get bankImportColAmount => 'Amount column';

  @override
  String get bankImportColDebit => 'Debit (expense)';

  @override
  String get bankImportColCredit => 'Credit (income)';

  @override
  String get bankImportSignMode => 'Amount sign';

  @override
  String get bankImportSignSingle => 'Single column (− expense)';

  @override
  String get bankImportSignDebitCredit => 'Debit / Credit';

  @override
  String get bankImportDateFormat => 'Date format';

  @override
  String get bankImportDateAuto => 'Auto';

  @override
  String get bankImportContinue => 'Continue';

  @override
  String get bankImportNoRows => 'No transactions to import.';

  @override
  String get bankImportSelectAll => 'All';

  @override
  String get bankImportDeselectAll => 'None';

  @override
  String get bankImportStepperMode => 'One by one';

  @override
  String get bankImportDuplicate => 'Possible duplicate';

  @override
  String get bankImportStepSkip => 'Skip';

  @override
  String get bankImportStepAdd => 'Add';

  @override
  String get bankImportStepAddRest => 'Add the rest';

  @override
  String get bankImportStepCancelAll => 'Cancel all';

  @override
  String get bankImportDefaultExpenseCat => 'Expense:';

  @override
  String get bankImportDefaultIncomeCat => 'Income:';

  @override
  String get bankImportShowRaw => 'Show raw text';

  @override
  String get bankImportPdfRawTitle => 'Couldn\'t recognize the PDF text';

  @override
  String get bankImportPdfRawHint =>
      'We extracted the text but couldn\'t recognize the transaction rows. Copy the text below and share it; the parser will be tuned to your bank\'s layout.';

  @override
  String get bankImportCopy => 'Copy';

  @override
  String get bankImportCopied => 'Copied';

  @override
  String bankImportSummary(int count, int dup, int skipped, int uncategorized) {
    return '$count transactions · $dup possible duplicates · $skipped rows skipped · $uncategorized uncategorized';
  }

  @override
  String bankImportAdd(int count) {
    return 'Add selected ($count)';
  }

  @override
  String bankImportDoneMsg(int added, int skipped) {
    return '$added added, $skipped skipped.';
  }

  @override
  String get bankImportDonePastDatesHint =>
      'Some transactions are dated in earlier months. The transactions list shows the current month by default; widen the date filter to see them all.';

  @override
  String get bankImportReconcileMatched =>
      'Verified against balance: the income/expense direction of transactions matches the bank\'s balance column.';

  @override
  String bankImportReconcileMismatch(int count) {
    return 'Balance mismatch: $count row(s) don\'t reconcile with the balance column. The statement may be misread; check the signs.';
  }

  @override
  String bankImportCurrencyMismatch(String statement, String wallet) {
    return 'The statement appears to be in $statement but the target wallet is $wallet. Amounts are not converted; make sure you\'re importing into the right wallet.';
  }

  @override
  String get bankImportUndo => 'Undo import';

  @override
  String get bankImportUndoDone => 'Import undone.';

  @override
  String get bankImportBatchTypeLabel => 'Set all to:';

  @override
  String get bankImportSetAllExpense => 'Expense';

  @override
  String get bankImportSetAllIncome => 'Income';

  @override
  String get bankImportReviewWarning =>
      'Dates, amounts, and categories were auto-detected from the file and may be wrong. Check every transaction before adding.';

  @override
  String get bankImportDoneBalanceLabel => 'Current wallet balance';

  @override
  String get bankImportDoneBalanceHint =>
      'This balance was calculated including the imported transactions. Compare it with your bank\'s current balance — you can sync it below if they differ.';

  @override
  String get bankImportSyncButton => 'Sync balance';

  @override
  String get bankImportSyncDialogTitle => 'Sync Balance';

  @override
  String get bankImportSyncDialogHint =>
      'Enter your bank\'s real current balance; the wallet will be adjusted to match. Past transactions stay unchanged — only the opening balance is corrected.';

  @override
  String get bankImportSyncDialogLabel => 'Real balance';

  @override
  String get bankImportSyncSuccess => 'Wallet balance synced.';

  @override
  String get bankImportCategorySuggestionTitle => 'New category suggestions';

  @override
  String get bankImportCategorySuggestionHint =>
      'Some transactions don\'t match any of your existing categories. Checked ones will be created and assigned automatically; unchecked ones won\'t be created and those transactions stay in the default category.';

  @override
  String get bankImportCategorySuggestionContinue => 'Continue';

  @override
  String get bankImportPickCategoryHint => 'Pick category';

  @override
  String get bankStatementSectionHeader => 'BANK STATEMENT';

  @override
  String get sifirla => 'Reset';

  @override
  String get tumTurlariSifirlaOnayMesaji =>
      'All intro tours will be reset and shown again. Do you want to continue?';

  @override
  String get deleteAllDataTitle => 'Delete all data';

  @override
  String get deleteAllDataMessage =>
      'All wallets, transactions, investments, debts, receivables, budgets, and recurring templates will be permanently deleted from this device. This action cannot be undone. Your Drive backup (if any) is not affected.';

  @override
  String get irreversibleActionTitle => 'This Action Cannot Be Undone';

  @override
  String get deleteAllDataDangerMessage =>
      'Once you confirm, all local data will be permanently deleted and cannot be recovered.';

  @override
  String get dataDeletedSuccess => 'All local data has been deleted.';

  @override
  String get dataDeleteError => 'Data could not be deleted. Please try again.';

  @override
  String get deleteWalletTitle => 'Delete Wallet';

  @override
  String deleteWalletConfirmMessage(String ad) {
    return 'Are you sure you want to delete the wallet $ad?';
  }

  @override
  String deleteWalletDangerMessage(String ad) {
    return 'Wallet $ad and its entire transaction history will be permanently deleted. This action cannot be undone.';
  }

  @override
  String get transferOnayBasligi => 'Confirm Transfer';

  @override
  String transferOnayMesaji(String tutar, String kaynak, String hedef) {
    return 'Are you sure you want to transfer $tutar from $kaynak to $hedef?';
  }

  @override
  String get budgetDeleteConfirmTitle => 'Delete Budget';

  @override
  String budgetDeleteConfirmMessage(String kategori) {
    return 'Are you sure you want to delete the budget for $kategori?';
  }

  @override
  String get islemSilBaslik => 'Delete Transaction';

  @override
  String islemSilOnayMesaji(String baslik) {
    return 'Are you sure you want to delete the transaction $baslik?';
  }
}
