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
  String get geriAl => 'Undo';

  @override
  String get silmeGeriAlindi => 'Deletion undone';

  @override
  String get silmeGeriAlinamadi =>
      'Undo failed; the record could not be restored';

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
  String get henuzBorcKaydiYokAciklama =>
      'You have no active debt records. You can add a new debt using the action button below.';

  @override
  String get odemeYap => 'Make Payment';

  @override
  String get ode => 'Pay';

  @override
  String get henuzAlacakKaydiYok => 'No receivable record yet.';

  @override
  String get henuzAlacakKaydiYokAciklama =>
      'You have no active receivable records. You can add a new receivable using the action button below.';

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
  String get stateOnLabel => 'On';

  @override
  String get stateOffLabel => 'Off';

  @override
  String get stateUnsupportedLabel => 'Unsupported';

  @override
  String get methodBiometricLabel => 'biometric authentication';

  @override
  String get methodGenericLabel => 'authentication';

  @override
  String get unitSecondsLabel => 'seconds';

  @override
  String get unitMinutesLabel => 'minutes';

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
  String get dataRestoredSuccess => 'Data restored successfully.';

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
  String get fullBackupShareText => 'ÇuNehat full backup';

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
  String get asagidakiButondanEkleyebilirsiniz =>
      'You can add from the button below';

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
  String hedefCurrencyformatFormatInvestment(Object targetAmount) {
    return 'Target: $targetAmount';
  }

  @override
  String get grafikIcinYatirimBulunmuyor => 'No investments for chart';

  @override
  String get portfoyDagilimi => 'Portfolio Distribution';

  @override
  String get tOPLAMPortfoyDegeri => 'TOTAL PORTFOLIO VALUE';

  @override
  String get tOPLAMMaliyet => 'TOTAL COST';

  @override
  String get kAZANCZarar => 'PROFIT / LOSS';

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
  String get categoryErrorDuplicateName =>
      'A category with this name already exists';

  @override
  String get categoryErrorParentNotFound => 'Parent category not found';

  @override
  String get categoryErrorParentIsNotRoot =>
      'A subcategory cannot have subcategories';

  @override
  String get categoryErrorTypeMismatch =>
      'A subcategory must match its parent\'s type';

  @override
  String get categoryErrorSelfParent => 'A category cannot be its own parent';

  @override
  String get categoryErrorParentHasChildren =>
      'A category that has subcategories cannot be moved';

  @override
  String get kategorilerBaslik => 'Categories';

  @override
  String kategoriSayisiOzeti(Object rootCount, Object childCount) {
    return '$rootCount main, $childCount sub';
  }

  @override
  String get altKategoriEkle => 'Add subcategory';

  @override
  String get ustKategori => 'Parent category';

  @override
  String get ustKategoriYok => 'Main category (no parent)';

  @override
  String get anaKategoriEtiketi => 'top-level category';

  @override
  String get henuzKategoriYok => 'No categories yet';

  @override
  String get oneriSetindenBasla => 'Start from suggestions';

  @override
  String get kategoriSilTasiTitle => 'Move transactions';

  @override
  String kategoriSilTasiMessage(Object name, Object count) {
    return '\"$name\" has $count transactions. Which category should they move to before deleting?';
  }

  @override
  String kategoriSilAltKategorilerDe(Object count) {
    return 'Its $count subcategories will be deleted too; their transactions move to the same category.';
  }

  @override
  String get kategoriSilHedefYok =>
      'There is no other category to move to. Create one first.';

  @override
  String dogrudanKategoriSec(Object name) {
    return '\"$name\" itself';
  }

  @override
  String get altKategoriSec => 'Pick a subcategory';

  @override
  String get starterPackTitle => 'Set up your categories';

  @override
  String get starterPackSubtitle =>
      'Pick from a ready-made set, then edit, delete or add your own freely. You need at least one category to record a transaction.';

  @override
  String get starterPackSelectAll => 'Select all';

  @override
  String get starterPackClearAll => 'Clear selection';

  @override
  String get starterPackSkip => 'Skip for now';

  @override
  String starterPackCreate(Object count) {
    return 'Create $count categories';
  }

  @override
  String starterPackCreated(Object count) {
    return '$count categories created';
  }

  @override
  String starterPackChildCount(Object count) {
    return '$count subcategories';
  }

  @override
  String butceUstKategorideVar(Object name) {
    return 'Parent category \"$name\" already has a budget';
  }

  @override
  String get butceAltKategorideVar => 'A subcategory already has a budget';

  @override
  String get duzenleSubtitle => 'Amount, date, category and other details';

  @override
  String get islemiSil => 'Delete Transaction';

  @override
  String islemSilOnayMesaji(String baslik) {
    return 'Are you sure you want to delete the transaction $baslik? Its effect on the wallet balance will be reversed as well.';
  }

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
  String guncelFiyatFormat(Object price) {
    return 'Current Price: $price';
  }

  @override
  String guncelFiyatFormatCevrimli(Object price, Object converted) {
    return 'Current Price: $price (≈$converted)';
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
  String get odenenTutarHint => 'Amount paid · 0 if gift';

  @override
  String get tutarHint => 'Amount';

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
  String get infoTransferDesc =>
      'You can transfer money between your wallets. The transferred amount is deducted from the source wallet and added to the destination, considering exchange rates.';

  @override
  String get infoBankImportDesc =>
      'You can quickly import transactions by pasting account movements copied from your bank\'s mobile app.';

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
  String get systemTagDebt => 'Debt';

  @override
  String get systemTagDebtPayment => 'Debt Payment';

  @override
  String get systemTagReceivable => 'Receivable';

  @override
  String get systemTagReceivableCollection => 'Receivable Collection';

  @override
  String get systemTagInvestmentBuy => 'Investment Purchase';

  @override
  String get systemTagInvestmentSell => 'Investment Sale';

  @override
  String get systemTagInvestmentCorrection => 'Investment Adjustment';

  @override
  String get systemTagTransfer => 'Transfer';

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
  String get transferKurAliniyor => 'Fetching exchange rate…';

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
  String get uygulamaTuruTekrarGoster => 'Replay the App Tour';

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
      'ÇuNehat can remind you when debt and receivable due dates approach and when recurring transactions await approval. This requires notification permission. You can keep using the app without it; you just won\'t see reminders.';

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
      'Permission was denied earlier, so the system no longer asks. You can turn notifications on from system settings.';

  @override
  String get notificationPermissionOpenSettingsAction => 'Open Settings';

  @override
  String get notificationSendTest => 'Send a test notification';

  @override
  String get notificationTestSent => 'Test notification sent';

  @override
  String get notificationTestFailedNoPermission =>
      'Test notification could not be sent: notification permission is off';

  @override
  String get notificationTestFailed => 'Test notification could not be sent';

  @override
  String get notificationTestTitle => 'ÇuNehat test notification';

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
    return 'The next installment for $title is due soon.';
  }

  @override
  String get notifDebtDueTitle => 'Debt Due Today!';

  @override
  String notifDebtDueBody(Object title) {
    return 'The next installment for $title is due today.';
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
  String get notifBudgetFilledTitle => 'Budget Filled';

  @override
  String notifBudgetFilledBody(Object category) {
    return 'You have reached 100% of your $category budget limit.';
  }

  @override
  String get notifDailyReminderTitle => 'ÇuNehat';

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
  String recurringNudgeCount(Object count) {
    return '$count transactions awaiting approval';
  }

  @override
  String recurringNudgeOldest(Object days) {
    return 'Oldest is $days days overdue';
  }

  @override
  String get sonra => 'Later';

  @override
  String get incele => 'Review';

  @override
  String get onayBekleyenler => 'Awaiting Approval';

  @override
  String get sablonlar => 'Templates';

  @override
  String get yaklasanlar => 'Upcoming';

  @override
  String get duraklatilmislar => 'Paused';

  @override
  String get duraklatildi => 'Paused';

  @override
  String get onayBekleyenYok => 'Nothing is awaiting approval.';

  @override
  String get aylikDuzenliGider => 'Monthly recurring expense';

  @override
  String get aylikDuzenliGelir => 'Monthly recurring income';

  @override
  String aktifSablonSayisi(Object count) {
    return '$count active templates';
  }

  @override
  String get yarin => 'Tomorrow';

  @override
  String gunSonra(Object days) {
    return 'in $days days';
  }

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
      'Budgets, recurring transactions, bank statement import, and settings live in this menu.';

  @override
  String get onboardingAppBarWalletTitle => 'Your Active Wallet';

  @override
  String get onboardingAppBarWalletDesc =>
      'Every income, expense, debt, and investment record goes into the SELECTED wallet. Tap here to switch wallets or add a new one.';

  @override
  String get onboardingWalletListTitle => 'Your Wallets';

  @override
  String get onboardingWalletListDesc =>
      'Each wallet has its own currency and balance. Tap a card to make it active, or use the icons on it to edit or delete.';

  @override
  String get onboardingWalletManagementTitle => 'Add a New Wallet';

  @override
  String get onboardingWalletManagementDesc =>
      'Create separate wallets for cash, a bank account, or a foreign currency — reports, budgets, and debts are all wallet-scoped.';

  @override
  String get onboardingTransactionsAddTitle => 'Enter the Amount';

  @override
  String get onboardingTransactionsAddDesc =>
      'Type the amount. The income/expense choice above decides whether this raises or lowers your wallet balance.';

  @override
  String get onboardingTransactionsAddCategoryTitle => 'Pick a Category';

  @override
  String get onboardingTransactionsAddCategoryDesc =>
      'A category is required: reports and budget alerts are calculated from it.';

  @override
  String get onboardingTransactionsAddRecurringTitle => 'Repeat Frequency';

  @override
  String get onboardingTransactionsAddRecurringDesc =>
      'Define rent, salary, or subscriptions once; the app reminds you when they\'re due.';

  @override
  String get onboardingDebtAddTitle => 'Amount and Repayment';

  @override
  String get onboardingDebtAddDesc =>
      'Enter the amount. Depending on the debt type, installment, interest, and term fields appear below; the summary under the card computes total repayment live.';

  @override
  String get onboardingDebtAddDueDateTitle => 'Due Date';

  @override
  String get onboardingDebtAddDueDateDesc =>
      'The date you expect to collect. You get a reminder as it approaches.';

  @override
  String get onboardingInvestmentAddTitle => 'Today\'s Value';

  @override
  String get onboardingInvestmentAddDesc =>
      'The investment\'s current market value. Your profit/loss is the difference between this and total cost.';

  @override
  String get onboardingInvestmentAddCostTitle => 'Total Cost';

  @override
  String get onboardingInvestmentAddCostDesc =>
      'The principal you\'ve paid into this investment so far. Leave it empty and profit/loss can\'t be computed.';

  @override
  String get onboardingInvestmentAddQuantityTitle => 'Quantity and Live Price';

  @override
  String get onboardingInvestmentAddQuantityDesc =>
      'Enter grams/shares and fetch the live price; today\'s value is calculated for you.';

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
  String bankImportColumnN(int n) {
    return 'Column $n';
  }

  @override
  String get bankImportPreviewTitle => 'Preview (first transactions)';

  @override
  String get bankImportRoleDate => 'Date';

  @override
  String get bankImportRoleDesc => 'Description';

  @override
  String get bankImportRoleAmount => 'Amount';

  @override
  String get bankImportRoleDebit => 'Debit';

  @override
  String get bankImportRoleCredit => 'Credit';

  @override
  String get bankImportRoleBalance => 'Balance';

  @override
  String get bankImportEditDescTitle => 'Edit description';

  @override
  String get bankImportEditDescLabel => 'Description';

  @override
  String get bankImportEditAmountTitle => 'Edit amount';

  @override
  String get bankImportEditAmountLabel => 'Amount';

  @override
  String get bankImportFilterAll => 'All';

  @override
  String get bankImportFilterUncategorized => 'Uncategorized';

  @override
  String get bankImportFilterDuplicates => 'Possible duplicate';

  @override
  String get bankImportSearchHint => 'Search descriptions';

  @override
  String get bankImportNoMatch => 'No transaction matches the filter.';

  @override
  String bankImportShownOf(int shown, int total) {
    return 'Showing $shown / $total';
  }

  @override
  String bankImportWarnings(int count) {
    return 'Warnings ($count)';
  }

  @override
  String get bankImportStatRows => 'transactions';

  @override
  String get bankImportStatDuplicates => 'possible duplicates';

  @override
  String get bankImportStatSkipped => 'skipped rows';

  @override
  String get bankImportStatUncategorized => 'uncategorized';

  @override
  String bankImportSelectedOf(int selected, int total) {
    return '$selected / $total selected';
  }

  @override
  String get bankImportNoRows => 'No transactions to import.';

  @override
  String get bankImportSelectAll => 'All';

  @override
  String get bankImportDeselectAll => 'None';

  @override
  String get bankImportStepperMode => 'Review one by one';

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
  String get bankImportShowRaw => 'Show raw text';

  @override
  String get bankImportPdfRawTitle => 'Couldn\'t recognize the PDF text';

  @override
  String get bankImportPdfRawHint =>
      'We extracted the text but couldn\'t recognize the transaction rows. Copy the text below and share it; the parser will be tuned to your bank\'s layout.';

  @override
  String get bankImportScannedPdfTitle => 'This PDF is a scanned image';

  @override
  String get bankImportScannedPdfHint =>
      'The file contains no text — only a photo or scan. We tried reading it as an image but couldn\'t extract any transaction rows. Download the statement as Excel (.xls/.xlsx) or CSV from your bank\'s online banking for a much more accurate result.';

  @override
  String get bankImportOcrWarning =>
      'These transactions were read from an IMAGE. Image recognition often confuses digits (comma/dot, 1/7, 0/O) and there is usually no balance column to verify against — check every amount before adding.';

  @override
  String get bankImportPickAnother => 'Pick another file';

  @override
  String get bankImportSharedSetupHint =>
      'Got the statement you shared. Pick the target wallet and start the scan — you\'ll review every transaction before anything is added.';

  @override
  String get bankImportSharedFileTitle => 'Shared file';

  @override
  String get bankImportSharedImport => 'Scan this file';

  @override
  String get bankImportLegacyExcelTitle => 'Couldn\'t open the Excel file';

  @override
  String bankImportLegacyExcelHint(String reason) {
    return '$reason\n\nDownload the statement as .xlsx or CSV from your bank, or open the file in Excel/Google Sheets and save it as .xlsx.';
  }

  @override
  String get bankImportSourceTruncated =>
      'The Excel file doesn\'t end with the expected marker — it may have been downloaded incompletely. Some transactions may be missing; compare the row count with your bank\'s statement.';

  @override
  String bankImportSourceUnresolved(int count) {
    return 'Couldn\'t resolve the value of $count cells; fields that look empty on those rows may actually contain data.';
  }

  @override
  String get bankImportUnsupportedTitle => 'Unsupported file';

  @override
  String bankImportUnsupportedHint(String formats) {
    return 'We couldn\'t recognize this file\'s format. Supported formats: $formats';
  }

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
  String get bankImportVerified => 'Arithmetically verified';

  @override
  String get bankImportVerifiedHint =>
      'The amounts read match the statement\'s own balance and total figures exactly.';

  @override
  String get bankImportVerifyFailed => 'Could not be verified';

  @override
  String get bankImportVerifyFailedHint =>
      'Some checks disagree with the statement\'s own figures; review the amounts before importing.';

  @override
  String get bankImportCheckBalanceChain => 'Balance chain';

  @override
  String get bankImportCheckRecordCount => 'Record count';

  @override
  String get bankImportCheckOpeningBalance => 'Opening balance';

  @override
  String get bankImportCheckClosingBalance => 'Closing balance';

  @override
  String get bankImportCheckTotals => 'Debit/credit totals';

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
  String get bankImportFullscreen => 'Full screen';

  @override
  String get bankImportExitFullscreen => 'Exit full screen';

  @override
  String get bankImportSummarySheet => 'Summary and warnings';

  @override
  String get bankImportMoreActions => 'More actions';

  @override
  String bankImportAssignVisibleDone(int count, String category) {
    return '$count rows moved to “$category”.';
  }

  @override
  String bankImportAssignUncategorized(int count) {
    return 'Assign to the $count uncategorized rows';
  }

  @override
  String bankImportAssignOverwrite(int count) {
    return 'Replace on all $count shown rows (categorized included)';
  }

  @override
  String get bankImportAssignTypeMismatch =>
      'The picked category does not match these rows\' type; nothing changed.';

  @override
  String get bankImportGroupSimilar => 'Group similar rows';

  @override
  String get bankImportGroupSimilarTitle => 'Similar transactions';

  @override
  String get bankImportGroupSimilarHint =>
      'Rows with similar descriptions are collected into one group. Picking a category for a group applies it to ALL rows in it.';

  @override
  String get bankImportGroupScopeUncategorized => 'Uncategorized only';

  @override
  String get bankImportGroupScopeAll => 'All';

  @override
  String bankImportGroupRows(int count) {
    return '$count rows';
  }

  @override
  String get bankImportGroupMixed => 'Mixed categories';

  @override
  String get bankImportGroupNone => 'Uncategorized';

  @override
  String get bankImportGroupEmpty => 'No similar rows found.';

  @override
  String bankImportGroupFillRest(String category) {
    return 'Fill the rest with “$category”';
  }

  @override
  String bankImportApplyToSimilar(int count, String sample) {
    return '$count more uncategorized rows look like this: $sample';
  }

  @override
  String get bankImportApplyToSimilarAction => 'Apply to all';

  @override
  String bankImportUncategorizedBlocked(int count) {
    return '$count selected rows have no category. They can\'t be added without one: they would count towards no category in budgets and reports.';
  }

  @override
  String get bankImportShowUncategorized => 'Show';

  @override
  String get bankImportStepNeedsCategory =>
      'Pick a category for the uncategorized rows first.';

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
  String get borcSilBaslik => 'Delete Debt';

  @override
  String borcSilOnayMesaji(String baslik) {
    return 'Are you sure you want to delete the debt $baslik? Its effect on the wallet balance will be reversed as well.';
  }

  @override
  String get alacakSilBaslik => 'Delete Receivable';

  @override
  String alacakSilOnayMesaji(String isim) {
    return 'Are you sure you want to delete the receivable from $isim? Its effect on the wallet balance will be reversed as well.';
  }

  @override
  String get budgetStatusUnderControl => 'Under control';

  @override
  String budgetStatusFilledCount(int sayi) {
    return '$sayi budget(s) filled';
  }

  @override
  String budgetStatusExceededCount(int sayi) {
    return '$sayi budget(s) exceeded';
  }

  @override
  String get insightDailyLimitTitle => 'Daily Spending Limit (Target)';

  @override
  String insightDailyLimitDesc(int gun) {
    return 'Recommended daily limit to stay on budget for the remaining $gun day(s).';
  }

  @override
  String get insightSpikeTitle => 'Spending Spike Alert';

  @override
  String insightSpikeDesc(String tutar) {
    return 'A notable increase compared to the previous period ($tutar).';
  }

  @override
  String get drawerSectionFinancial => 'FINANCIAL MANAGEMENT';

  @override
  String get drawerSectionSystem => 'SYSTEM & APP';

  @override
  String get drawerBudgetSubtitle =>
      'Category-based budget tracking and spending limits';

  @override
  String get drawerRecurringSubtitle =>
      'Automatic income and expense templates';

  @override
  String get drawerBankImportSubtitle => 'Import PDF/Excel account statements';

  @override
  String get drawerBankImportTitle => 'Bank Statement';

  @override
  String get drawerSettingsSubtitle =>
      'Theme, currency and general preferences';

  @override
  String get drawerSecurityTitle => 'Security & Biometrics';

  @override
  String get drawerSecuritySubtitle => 'App lock and PIN settings';

  @override
  String get drawerActiveWalletLabel => 'ACTIVE WALLET';

  @override
  String get reportBalanceTrend => 'Balance Trend';

  @override
  String get reportExpensesTitle => 'Expenses';

  @override
  String get reportIncomesTitle => 'Incomes';

  @override
  String get reportNoDataTitle => 'No Data to Build a Report';

  @override
  String get reportNetLabel => 'Net';

  @override
  String get reportNoPreviousPeriod => 'No prior period';

  @override
  String reportCompareTopSlice(String ad, String tutar) {
    return 'Largest: $ad · $tutar';
  }

  @override
  String reportCompareOverspend(String oran) {
    return '$oran% over income';
  }

  @override
  String get reportCompareScaleHint => 'Both bars share one scale';

  @override
  String get debtHistoryEmptyTitle => 'No Closed Debts Yet';

  @override
  String get receivableHistoryEmptyTitle => 'No Collected Receivables Yet';

  @override
  String get badgeOdendi => 'Paid';

  @override
  String get badgeTahsilEdildi => 'Collected';

  @override
  String reportSavingsSubtitle(String oran) {
    return '$oran% Savings';
  }

  @override
  String vadeTarihLabel(String tarih) {
    return 'Due: $tarih';
  }

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyIntro =>
      'ÇuNehat is a personal finance app that helps you track your financial records. It is designed offline-first: your data stays on your device unless you explicitly enable cloud backup. We operate no server.';

  @override
  String get privacyLocalDataTitle => 'Data stored on your device';

  @override
  String get privacyLocalDataBody =>
      'Wallets, transactions, investments, debts, receivables, budgets, recurring templates and app preferences (theme, language, categories) are stored only on your device and are never sent to us.';

  @override
  String get privacyDriveTitle => 'Google Drive backup (optional)';

  @override
  String get privacyDriveBody =>
      'Cloud backup is OFF by default. If you turn it on, you sign in with Google and only your email address (so you can see which account is connected) and the restricted \"drive.appdata\" scope are used. A single backup file (cunehat_backup.json) is written to a private, app-specific folder in your own Google Drive that other apps cannot access. The app does not request full Drive access and cannot read your other files.';

  @override
  String get privacyMarketDataTitle => 'Market data';

  @override
  String get privacyMarketDataBody =>
      'To show live prices, only the asset symbol (e.g. a stock ticker) is sent to public endpoints (Yahoo Finance, Truncgil). No personal or financial-record data is included.';

  @override
  String get backupOfferTitle => 'Your data lives only on this device';

  @override
  String get backupOfferBody =>
      'ÇuNehat keeps your records on no server. If you lose your phone, reset it, or uninstall the app, this data is gone for good. Turning on automatic backup keeps a regular copy in a private folder inside your own Google Drive.';

  @override
  String get backupOfferSetup => 'Set Up Backup';

  @override
  String get backupOfferLater => 'Not Now';

  @override
  String get privacyReceiptsTitle => 'Receipt photos and text recognition';

  @override
  String get privacyReceiptsBody =>
      'Attaching a receipt photo to a transaction is optional. The photo comes from the system picker; the app requests no permanent camera or storage permission. Images are kept only in the app\'s private storage — they are never uploaded and are not included in the Drive backup. Reading the amount and date from a receipt uses Google ML Kit\'s offline model bundled inside the app, so the image is never sent to a server. Deleting the transaction also deletes the attached image.';

  @override
  String get privacyStatementTitle => 'Bank statement import';

  @override
  String get privacyStatementBody =>
      'You pick the statement (PDF, CSV, Excel) yourself or send it from a share menu; the app has no access to your bank and no permission to browse your files. The file is parsed entirely on your device and is never uploaded. Only the transactions you confirm on the review screen are saved; the statement file itself is not retained.';

  @override
  String get privacySharingTitle => 'Data sharing';

  @override
  String get privacySharingBody =>
      'We do not sell, rent, or share your data with third parties. The app contains no analytics, crash-reporting, advertising, or tracking SDKs. Our use of information received from Google APIs adheres to the Google API Services User Data Policy, including the Limited Use requirements.';

  @override
  String get privacySecurityTitle => 'Security';

  @override
  String get privacySecurityBody =>
      'Local data is stored in the app\'s private storage. Biometric / PIN lock is supported to prevent unauthorized access, and the app blurs its content when sent to the background. All network communication uses HTTPS.';

  @override
  String get privacyRetentionTitle => 'Data retention and deletion';

  @override
  String get privacyRetentionBody =>
      'You are in full control of your data. You can erase all local data from Settings → Privacy & Data → \"Delete all data\". You can delete the Drive backup from Settings → Backup, or disconnect your account.';

  @override
  String privacyContactLabel(String email) {
    return 'Contact: $email';
  }

  @override
  String get privacyLastUpdated => 'Last updated: 4 August 2026';

  @override
  String get privacyConsentTitle => 'Your privacy';

  @override
  String get privacyConsentBody =>
      'ÇuNehat stores your data only on your device; we operate no server. The optional Google Drive backup is written to a private folder in your own Drive, and only if you enable it. Your data is not shared with third parties; there is no advertising or tracking.';

  @override
  String get privacyConsentAcknowledge => 'Got it';

  @override
  String get secenekler => 'Options';

  @override
  String get tarihAraligiSecBaslik => 'Select date range';

  @override
  String get takvimdenSec => 'Choose from calendar';

  @override
  String get kategoriSecmeUyarisi => 'Select a category';

  @override
  String yatirimSatOnayBaslik(String name) {
    return 'Sell $name?';
  }

  @override
  String yatirimSilOnayBaslik(String name) {
    return 'Delete the $name record?';
  }

  @override
  String get walletQuickStartTitle => 'Wallet ready!';

  @override
  String walletQuickStartSubtitle(String name) {
    return '$name was created. How would you like to start?';
  }

  @override
  String get walletQuickStartImportTitle => 'Import bank statement';

  @override
  String get walletQuickStartImportSubtitle =>
      'Load your past transactions from a file — the fastest way';

  @override
  String get walletQuickStartManualTitle => 'Add the first transaction';

  @override
  String get walletQuickStartManualSubtitle =>
      'Start with a single income or expense';

  @override
  String get walletQuickStartSkip => 'Skip for now';

  @override
  String get driveErrNotSignedIn => 'You are not connected to Google Drive.';

  @override
  String get driveErrCancelled => 'Operation cancelled.';

  @override
  String get driveErrNoNetwork =>
      'No internet connection. Reconnect and try again.';

  @override
  String get driveErrTimeout =>
      'Google Drive did not respond in time. Check your connection and try again.';

  @override
  String get driveErrAuthExpired =>
      'Your Google session expired. Disconnect and connect again.';

  @override
  String get driveErrScopeDenied =>
      'Drive app-folder permission was not granted. Backup cannot work without it.';

  @override
  String get driveErrConfigError =>
      'Google Drive is not configured in this build (the OAuth client does not match the package name/signature). This is a setup error; backup is unavailable for now.';

  @override
  String get driveErrTokenFailed =>
      'Drive access could not be authorized with your Google account. Disconnect and reconnect in Settings; if it persists, check your Google account permissions.';

  @override
  String get driveErrQuotaExceeded =>
      'Your Google Drive storage is full. Free up space and try again.';

  @override
  String get driveErrServerError =>
      'Google Drive is not responding right now. Try again later.';

  @override
  String get driveErrEmptyLocalData =>
      'There is nothing on this device to back up. An empty backup would replace the full backup in your Drive.';

  @override
  String get driveErrVerificationFailed =>
      'The upload could not be verified; the backup may be incomplete. The new copy was rolled back and your previous backup is intact.';

  @override
  String get driveErrNotFound => 'No backup found in Google Drive.';

  @override
  String driveErrVersionMismatch(String found, int expected) {
    return 'This backup belongs to a different app version (backup schema $found, this version $expected). It cannot be restored.';
  }

  @override
  String get driveErrCorrupt =>
      'The backup file could not be read; it is corrupt or incompletely written.';

  @override
  String get driveErrWriteFailure =>
      'A write error occurred while restoring. Your previous data on this device was rolled back.';

  @override
  String get driveUnchanged =>
      'Data has not changed since the last backup; no new backup was made.';

  @override
  String get backupEmptyConfirmTitle => 'Create an empty backup?';

  @override
  String get backupEmptyConfirmDesc =>
      'There are no records on this device. If you continue, an empty backup will replace the newest backup in your Drive.';

  @override
  String get backupEmptyConfirmAction => 'Back up empty';

  @override
  String get viewBackups => 'View Backups';

  @override
  String get deleteAllBackups => 'Delete All Backups';

  @override
  String get deleteAllBackupsDesc =>
      'Every backup copy in Google Drive will be permanently deleted. Data on your device is not affected.';

  @override
  String backupGenerationsKept(int count) {
    return '$count copies kept';
  }

  @override
  String get backupSizeLabel => 'Size';

  @override
  String get autoBackup => 'Automatic backup';

  @override
  String get autoBackupDesc =>
      'When the app goes to the background, a backup is made silently if the data changed and the interval has elapsed.';

  @override
  String get autoBackupOff => 'Off';

  @override
  String get autoBackupDaily => 'Daily';

  @override
  String get autoBackupWeekly => 'Weekly';

  @override
  String get autoBackupLimitNote =>
      'Automatic backup does not run if you never open the app.';

  @override
  String autoBackupFailureWarning(int count) {
    return 'The last $count automatic backup attempts failed. Back up manually to see why.';
  }

  @override
  String get autoBackupNeedsConnection =>
      'Automatic backup requires a Google Drive connection.';

  @override
  String get backupPreviewTitle => 'Backups';

  @override
  String get backupPreviewDetailTitle => 'Backup preview';

  @override
  String get backupPreviewDriveSection => 'Copies in Google Drive';

  @override
  String get backupPreviewLocalButton => 'Preview a file from this device';

  @override
  String get backupPreviewEmpty => 'No backups in Google Drive yet.';

  @override
  String get backupPreviewLocalSource => 'Device file';

  @override
  String get backupPreviewOriginManual => 'Manual';

  @override
  String get backupPreviewOriginAuto => 'Automatic';

  @override
  String get backupPreviewLoading => 'Reading backup…';

  @override
  String get backupPreviewContents => 'Contents';

  @override
  String get backupPreviewWallets => 'Wallets';

  @override
  String get backupPreviewTransactions => 'Transactions';

  @override
  String get backupPreviewInvestments => 'Savings';

  @override
  String get backupPreviewDebts => 'Debts';

  @override
  String get backupPreviewReceivables => 'Receivables';

  @override
  String get backupPreviewBudgets => 'Budgets';

  @override
  String get backupPreviewRecurring => 'Recurring transactions';

  @override
  String get backupPreviewCategories => 'Category preferences';

  @override
  String get backupPreviewDateRange => 'Transaction date range';

  @override
  String get backupPreviewIncome => 'Total income';

  @override
  String get backupPreviewExpense => 'Total expense';

  @override
  String get backupPreviewTakenAt => 'Backup date';

  @override
  String get backupPreviewSchemaVersion => 'Schema version';

  @override
  String get backupPreviewDiffTitle => 'What changes if you restore';

  @override
  String get backupPreviewDiffOnDevice => 'On device';

  @override
  String get backupPreviewDiffInBackup => 'In backup';

  @override
  String backupPreviewReceiptWarning(int count) {
    return '$count transactions have receipt images. Images are not included in the backup; if you restore on another device they will not appear.';
  }

  @override
  String get backupPreviewEmptyWarning =>
      'This backup is empty. Restoring it deletes every record on your device.';

  @override
  String get backupPreviewRestoreButton => 'Restore this backup';

  @override
  String get backupPreviewDeleteButton => 'Delete this copy';

  @override
  String get backupPreviewDeleteConfirmDesc =>
      'This backup copy will be permanently deleted from Google Drive. Data on your device is not affected.';

  @override
  String get backupPreviewRestoreConfirmTitle => 'Restore this backup?';

  @override
  String get backupPreviewRestoreConfirmDesc =>
      'Every wallet, transaction, saving, debt, receivable, budget and recurring template on this device will be REPLACED by the ones in this backup. This cannot be undone.';

  @override
  String get backupPreviewNoTransactions => 'This backup has no transactions.';

  @override
  String get backupPreviewUnknownCount => '?';

  @override
  String get disconnectConfirmTitle => 'Disconnect?';

  @override
  String disconnectConfirmDesc(String email) {
    return 'You will be signed out of $email. Your backups in Google Drive are NOT deleted — reconnect with the same account to reach them. Automatic backup will stop.';
  }

  @override
  String deleteAllBackupsDangerDesc(int count) {
    return 'Once you confirm, all $count backup copies in Google Drive are permanently deleted. If the data on your device is corrupted or erased, no copy remains to restore from.';
  }

  @override
  String get driveErrApiNotEnabled =>
      'The Google Drive API is not enabled for this app. This is a setup gap; it cannot be fixed by granting permission.';

  @override
  String vadeAraligi(int max) {
    return 'Term must be between 1 and $max months';
  }

  @override
  String oranAraligi(int max) {
    return 'Rate must be between 0% and $max%';
  }

  @override
  String get gecikmeFaiziLabel => 'Late interest:';

  @override
  String get odenecekToplamLabel => 'Total payable:';

  @override
  String get odenecekTutardanFazlaOlamaz => 'Cannot exceed the total payable';

  @override
  String get gecikmeFaiziChip => 'Late interest';

  @override
  String gecikmeFaiziKisa(Object tutar) {
    return '+ $tutar late interest';
  }

  @override
  String odemeMahsupAciklama(Object faiz, Object anapara) {
    return '$faiz goes to late interest, $anapara to principal.';
  }

  @override
  String taksitGecikmeGun(Object tutar, int gun) {
    return '≈ $tutar · $gun days overdue';
  }

  @override
  String odemeIcindeGecikmeFaizi(Object tarih, Object faiz) {
    return '$tarih · includes $faiz late interest';
  }

  @override
  String get odemeSilBaslik => 'Delete Payment';

  @override
  String odemeSilOnayMesaji(Object tutar) {
    return 'The payment record of $tutar will be deleted. Its effect on the wallet balance is reverted too.';
  }

  @override
  String get odemeyiDuzenleBaslik => 'Edit Payment';

  @override
  String get onboardingDebtAddStartDateTitle => 'Start Date';

  @override
  String get onboardingDebtAddStartDateDesc =>
      'The date the debt starts; installments run monthly from here. The reminder arrives on the due date of the next unpaid installment.';

  @override
  String vadeTaksitIlerleme(int termMonths, int paid) {
    return 'Term: $termMonths months | $paid/$termMonths installments';
  }

  @override
  String get vadeOpsiyonelLabel => 'Due date (optional)';

  @override
  String get vadeSecilmedi => 'Not set';

  @override
  String get txSearchHint => 'Search transactions…';

  @override
  String get txSearchClear => 'Clear search';

  @override
  String txSearchNoResultTitle(Object query) {
    return 'No results for “$query”';
  }

  @override
  String get txPeriodPrev => 'Previous period';

  @override
  String get txPeriodNext => 'Next period';

  @override
  String get txPeriodPick => 'Choose period';

  @override
  String get txViewList => 'List view';

  @override
  String get txViewCalendar => 'Calendar view';

  @override
  String get txOpenFilters => 'Open filters';

  @override
  String get txChipRemove => 'Remove filter';

  @override
  String txChipSearch(Object query) {
    return '“$query”';
  }

  @override
  String get txEmptyFilteredTitle => 'No matching transactions';

  @override
  String get txEmptyFilteredBody =>
      'Nothing found for the selected period and filters.';

  @override
  String get txEmptyClearFilters => 'Clear filters';

  @override
  String txFilterShowCount(int count) {
    return 'Show $count transactions';
  }

  @override
  String get txFilterNoResult => 'No matching transactions';

  @override
  String get txFilterAmountRange => 'AMOUNT RANGE';

  @override
  String get txFilterMinMaxError => 'Minimum amount cannot exceed the maximum';

  @override
  String get txFilterCategorySearchHint => 'Search categories…';

  @override
  String get txFilterCategoryNoMatch => 'No matching categories';

  @override
  String txFilterSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String txFilterSubcategoryCount(int selected, int total) {
    return '$selected/$total';
  }

  @override
  String get txFilterExpandGroup => 'Show subcategories';

  @override
  String get txFilterCollapseGroup => 'Hide subcategories';

  @override
  String get txSummaryNet => 'NET';

  @override
  String get txSummaryNetFiltered => 'FILTERED NET';

  @override
  String get txSummaryIncomeTotal => 'TOTAL INCOME';

  @override
  String get txSummaryIncomeFiltered => 'FILTERED INCOME';

  @override
  String get txSummaryExpenseTotal => 'TOTAL EXPENSES';

  @override
  String get txSummaryExpenseFiltered => 'FILTERED EXPENSES';

  @override
  String get txSummaryIncome => 'INCOME';

  @override
  String get txSummaryExpense => 'EXPENSES';

  @override
  String get txSummaryCount => 'transactions';

  @override
  String get txSummaryCountFiltered => 'filtered';

  @override
  String get txModeIncome => 'Income';

  @override
  String get txModeExpense => 'Expenses';

  @override
  String get txModeCompare => 'Compare';

  @override
  String get txSwipeHintLocked =>
      'Auto-generated transactions cannot be edited';

  @override
  String get dateRangeLast7Days => 'Last 7 Days';

  @override
  String get dateRangeThisMonth => 'This Month';

  @override
  String get dateRangeLastMonth => 'Last Month';

  @override
  String get dateRangeLast3Months => 'Last 3 Months';

  @override
  String get dateRangeThisYear => 'This Year';

  @override
  String get txPeriodToday => 'Today';

  @override
  String get txPeriodYesterday => 'Yesterday';

  @override
  String get lot => 'lot';

  @override
  String get katkiKipiMiktar => 'By quantity';

  @override
  String get katkiKipiTutar => 'By amount';

  @override
  String katkiTakipBirimi(Object unit) {
    return 'This holding is tracked in $unit.';
  }

  @override
  String katkiFarkliTurBaslik(Object unit) {
    return '$unit can\'t be added to this record';
  }

  @override
  String katkiFarkliTurAciklama(Object recordUnit, Object selectedUnit) {
    return 'This record is tracked in $recordUnit; adding $selectedUnit would mix both quantity and value. Create a separate record for that type.';
  }

  @override
  String katkiFarkliTurButon(Object unit) {
    return 'Create a new $unit record';
  }

  @override
  String katkiMiktaraCevrilecek(Object qty, Object unit) {
    return '≈ $qty $unit will be added';
  }

  @override
  String get katkiFiyatGerekli =>
      'Fetch the live price first to convert the amount into quantity.';

  @override
  String get katkiOdenenBosUyari =>
      'Amount paid is empty: this purchase counts as a gift and nothing is deducted from your wallet.';

  @override
  String get katkiTutarKipiAciklama =>
      'Enter the amount you put in; it is converted into quantity at the live price.';

  @override
  String get katkiYatirilanTutarHint => 'Amount invested';

  @override
  String duzenlemeTurDegisikligiUyari(Object qty, Object newUnit) {
    return 'Type is changing: the recorded quantity of $qty will now count as $newUnit, and price refresh will value it accordingly. If you bought a different type, leave this record alone and create a new one.';
  }

  @override
  String alinanMiktarBirimHint(Object unit) {
    return 'Quantity bought ($unit)';
  }

  @override
  String get yeniAlimMiktarVeyaTutar =>
      'New purchase: by quantity or by amount';

  @override
  String kartBirimFiyat(Object price) {
    return 'Unit $price';
  }

  @override
  String kartMiktarBirim(Object qty, Object unit) {
    return '$qty $unit';
  }

  @override
  String get yatirimTuruHisse => 'Stock';

  @override
  String get yatirimTuruAltin => 'Gold';

  @override
  String get yatirimTuruOzel => 'Custom';

  @override
  String satisSheetBaslik(Object name) {
    return '$name · Sell';
  }

  @override
  String satilanMiktarBirimHint(Object unit) {
    return 'Quantity sold ($unit)';
  }

  @override
  String get satilanDegerHint => 'Amount sold (of current value)';

  @override
  String get alinanTutarHint => 'Proceeds (added to wallet)';

  @override
  String get satTumunuSec => 'All';

  @override
  String satElindeki(Object qty, Object unit) {
    return 'You hold: $qty $unit';
  }

  @override
  String satGuncelDegerBilgi(Object value) {
    return 'Current value: $value';
  }

  @override
  String get satTamSatisUyari =>
      'Selling the whole record: it will be deleted.';

  @override
  String satKismiKalanBilgi(Object qty, Object unit, Object value) {
    return 'Remaining: $qty $unit · $value';
  }

  @override
  String satKismiKalanTutar(Object value) {
    return 'Remaining record: $value';
  }

  @override
  String get gecerliSatisMiktariGirin => 'Enter a valid quantity to sell';

  @override
  String satisMiktariAsim(Object max) {
    return 'You can\'t sell more than you hold (max $max)';
  }

  @override
  String get gecerliAlinanTutarGirin => 'Enter a valid proceeds amount';

  @override
  String get satisFiyatTazeleIpucu =>
      'The recorded value may be stale; fetch the live price to refresh the proceeds.';

  @override
  String get kismiSatisBasarili => 'Part of the investment was sold';

  @override
  String get kismiSatisGeriAlindi => 'Partial sale undone';

  @override
  String get alimTarihi => 'Purchase date';

  @override
  String get zatenBendeBaslik => 'I already own this asset';

  @override
  String get zatenBendeAciklama =>
      'Bought before using the app; don\'t deduct its cost from the wallet';

  @override
  String alimCuzdandanDusulecek(Object amount, Object date) {
    return '$amount will be deducted from the wallet as an expense dated $date.';
  }

  @override
  String get alimCuzdandanDusulmeyecek =>
      'Nothing will be deducted from the wallet; the record is only added to the portfolio.';

  @override
  String get birikimBosBaslik => 'No savings yet';

  @override
  String get birikimBosAciklama =>
      'Build your portfolio by adding gold, a stock or your own asset. The purchase amount is deducted from your wallet as an expense.';

  @override
  String get yatirimEklendiMesaji => 'Investment added';

  @override
  String get yatirimGuncellendiMesaji => 'Investment updated';

  @override
  String get yatirimSatildiMesaji => 'Investment sold';

  @override
  String get yatirimKismenSatildiMesaji => 'Part of the investment was sold';

  @override
  String get yatirimSilindiDuzeltildiMesaji =>
      'Record deleted, purchase entry corrected';

  @override
  String fiyatlarGuncellendiMesaji(Object count) {
    return 'Refreshed the price of $count investments';
  }

  @override
  String fiyatlarKismenGuncellendiMesaji(Object updated, Object failed) {
    return '$updated refreshed, $failed failed';
  }

  @override
  String get yenilenebilirYatirimYokMesaji =>
      'No refreshable investment (symbol and quantity required)';

  @override
  String get fiyatlarAlinamadiMesaji =>
      'Prices could not be fetched; values were left unchanged';

  @override
  String get bakiyeGuncellenemediUyarisi =>
      ' (Warning: the balance could not be updated, refresh the wallet.)';

  @override
  String get yatirimGecmisiBuradaListelenecek =>
      'Your investment history will be listed here.';

  @override
  String get hedefKategoriEv => 'Home';

  @override
  String get hedefKategoriDugun => 'Wedding';

  @override
  String get hedefKategoriAraba => 'Car';

  @override
  String get hedefKategoriAcilFon => 'Emergency fund';

  @override
  String get hedefKategoriEgitim => 'Education';

  @override
  String get hedefKategoriDiger => 'Other';

  @override
  String get maliyetVeyaDegerSifirdanBuyuk =>
      'At least one of cost or current value must be greater than zero';

  @override
  String get hedeflerim => 'My goals';

  @override
  String get bagsizVarliklar => 'Unassigned assets';

  @override
  String get yeniHedefOlustur => 'Create a goal';

  @override
  String get hedefiDuzenle => 'Edit goal';

  @override
  String get hedefiSil => 'Delete goal';

  @override
  String hedefSilOnayBaslik(Object name) {
    return 'Delete the goal $name?';
  }

  @override
  String hedefSilOnayMesaj(Object count) {
    return 'The goal is deleted. Its $count assets are NOT deleted; they move to the unassigned list.';
  }

  @override
  String get hedefAdiHint => 'Goal name · e.g. House down payment';

  @override
  String get hedefTutariHint => 'Target amount';

  @override
  String get hedefAdiGirin => 'Enter a goal name';

  @override
  String get hedefAlaniEtiketi => 'Goal';

  @override
  String get hedefeBagliDegil => 'Not linked to a goal';

  @override
  String get hedefeVarlikEkle => 'Add an asset to this goal';

  @override
  String get hedefBosAciklama => 'No asset is linked to this goal yet.';

  @override
  String hedefIlerlemeSatiri(Object saved, Object target) {
    return '$saved / $target';
  }

  @override
  String hedefKalanTutar(Object amount) {
    return '$amount to go';
  }

  @override
  String get hedefeUlasildi => 'Goal reached';

  @override
  String hedefUyeSayisi(Object count) {
    return '$count assets';
  }

  @override
  String get hedefKaydedildiMesaji => 'Goal saved';

  @override
  String get hedefSilindiMesaji =>
      'Goal deleted; its assets moved to the unassigned list';

  @override
  String get varlikTuruSec => 'What would you like to add?';

  @override
  String gecmisAlimUyarisi(Object date) {
    return 'Purchase dated $date. \"Current Value\" is TODAY\'s value, not the value on that day; cost is what you paid back then.';
  }

  @override
  String get bugunkuDegeriHesapla => 'Calculate today\'s value';

  @override
  String get hedefYonetimi => 'Goals';

  @override
  String get hedefYokAciklama =>
      'No goals yet. Create one and gather gold, quarter coins and stocks under the same goal.';

  @override
  String get hedefEkleKisa => 'Add goal';

  @override
  String get reportFlowTitleDay => 'Daily Income–Expense';

  @override
  String get reportFlowTitleWeek => 'Weekly Income–Expense';

  @override
  String get reportFlowTitleMonth => 'Monthly Income–Expense';

  @override
  String get reportUnitDay => 'Day';

  @override
  String get reportUnitWeek => 'Week';

  @override
  String get reportUnitMonth => 'Month';

  @override
  String get reportUnitSelectorLabel => 'Resolution';

  @override
  String reportUnitTooDense(Object count) {
    return '$count columns won\'t fit';
  }

  @override
  String reportFlowChartSemantics(Object count, Object income, Object expense) {
    return 'Income–expense chart: $count periods, total income $income, total expense $expense. Tap the columns for values.';
  }

  @override
  String reportBalanceChartSemantics(Object start, Object end) {
    return 'Balance chart: $start at the start of the period, $end at the end. Tap the line for values in between.';
  }

  @override
  String get reportSystemMovementsTitle => 'Transfers & linked movements';

  @override
  String reportSystemMovementsOff(Object count) {
    return '$count movements kept out of income–expense';
  }

  @override
  String reportSystemMovementsOn(Object count) {
    return '$count movements counted in income–expense';
  }

  @override
  String get reportSystemMovementsHint =>
      'Transfers between wallets, debt payments and investment buys/sells are not spending — the money moves, it isn\'t spent. The balance line always includes them.';

  @override
  String get reportShareTooltip => 'Share the report';
}
