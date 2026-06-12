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
  String get bekleyenIslemler => 'Pending Transactions';

  @override
  String get islemRaporu => 'Transaction Report';

  @override
  String get tooltipTarihAraligi => 'Date Range';

  @override
  String get msgSecilenTarihAraligindaIslem => 'No transaction in selected date range';

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
  String get iceAktarCsv => 'Import (CSV)';

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
  String get aktifCuzdaniniziDegistirmekIcin => '• Click on a wallet to change your active wallet.';

  @override
  String get cuzdanBakiyeleriOtomatikOlarak => '• Wallet balances are updated automatically.';

  @override
  String get herCuzdaninKendiGelir => '• Each wallet has its own income/expense records.';

  @override
  String msgTextsCheckfailedprefixETostring(Object checkFailedPrefix, Object error) {
    return '$checkFailedPrefix: $error';
  }

  @override
  String msgPINVerificationFailedE(Object error) {
    return 'PIN verification failed: $error';
  }

  @override
  String get msgCreateAPinFirst => 'Create a PIN first';

  @override
  String get msgBiometricAuthenticationIsNot => 'Biometric authentication is not supported';

  @override
  String get msgBiometricAuthenticationFailed => 'Biometric authentication failed';

  @override
  String get msgBiometricLoginEnabled => 'Biometric login enabled';

  @override
  String get msgBiometricLoginDisabled => 'Biometric login disabled';

  @override
  String get msgPINAlreadyExistsUse => 'PIN already exists, use change PIN instead';

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
  String get msgBackgroundLockAndPrivacy => 'Background lock and Privacy Guard enabled';

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
  String get msgBiometricAuthenticationCannotBe => 'Biometric authentication cannot be used on this device.';

  @override
  String get msgCreateAPinFirst2 => 'Create a PIN first to enable biometric login.';

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
  String get deletePinConfirmMessage => 'Removing PIN will also disable biometric login. Continue?';

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
  String get biometricNotAvailableSubtitle => 'Biometric authentication is not available on this device';

  @override
  String get biometricEnabledSubtitle => 'Biometric login enabled';

  @override
  String get biometricDisabledSubtitle => 'Biometric login disabled';

  @override
  String get biometricAuthTileTitle => 'Biometric Authentication';

  @override
  String get biometricAuthTileSubtitleOn => 'On - Sign in with fingerprint or face recognition';

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
  String get screenProtectionTileSubtitleOn => 'On - Hide content while app is in background';

  @override
  String get screenProtectionTileSubtitleOff => 'Off';

  @override
  String get backgroundLockTitle => 'Background Lock';

  @override
  String get backgroundLockSubtitlePrefix => 'Locks after: ';

  @override
  String get backgroundLockSubtitleOff => 'Off';

  @override
  String get backgroundLockTileTitle => 'Require authentication when app stays in background';

  @override
  String get backgroundLockTileSubtitle => 'To enable background lock, set a PIN or enable biometric login.';

  @override
  String get backgroundLockTileInfo => 'Note: Authentication screen appears when returning to app.';

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
  String get googleDriveBackupDesc => 'Back up your data to your personal Google Drive account for safety.';

  @override
  String get connectGoogleDrive => 'Connect to Google Drive';

  @override
  String get account => 'Account:';

  @override
  String get lastBackup => 'Last Backup:';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get version => 'Version';

  @override
  String get developer => 'Developer';

  @override
  String get noBackupsYet => 'No backups yet';

  @override
  String get restoreDataTitle => 'Restore Data?';

  @override
  String get restoreDataDesc => 'Your cloud data will overwrite the existing data on your device. This operation cannot be undone.';

  @override
  String get googleDriveConnected => 'Successfully connected to Google Drive.';

  @override
  String get googleDriveConnectionFailed => 'Google Drive connection failed.';

  @override
  String get googleDriveDisconnected => 'Google Drive disconnected.';

  @override
  String get dataBackedUpSuccess => 'Data successfully backed up to Google Drive.';

  @override
  String get backupFailed => 'Backup failed.';

  @override
  String get dataRestoredSuccess => 'Data successfully restored. Please restart the app for changes to take effect.';

  @override
  String get restoreFailedNoBackup => 'Restore failed. No backup file found.';

  @override
  String get welcomeUser => 'Welcome';

  @override
  String get defaultUser => 'User';

  @override
  String get dataExportImport => 'Export / Import Transactions';

  @override
  String get dataExportImportDesc => 'Export all your transactions in standard CSV format to use in other apps or back up.';

  @override
  String get activeWalletRequiredForExport => 'An active wallet is required for exporting.';

  @override
  String get uygulamaBaslatilamadi => 'App could not start';

  @override
  String get verilerinizSilinmediTekrarDeneyin => 'Your data was not deleted. Try again; if the problem persists ';

  @override
  String get ikonBulunamadi => 'Icon not found';

  @override
  String valueTostringasfixedCurrencysymbol(Object toStringAsFixed, Object currencySymbol) {
    return '$toStringAsFixed $currencySymbol';
  }

  @override
  String get butcePlanlama => 'Budget Planning';

  @override
  String get henuzButceYok => 'No budgets yet';

  @override
  String get kategorilerinizeAylikHarcamaLimiti => 'Set a monthly spending limit for your categories,\ntrack your spending here.';

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
  String get buKategorininButcesiVar => 'This category has a budget; limit will be updated.';

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
  String get msgOdemesiTamamlanipKapatilanBorclarinizin => 'The history of your paid and closed debts will be displayed here.';

  @override
  String paidDebtsLengthBorcKapandi(Object length) {
    return '$length debts closed';
  }

  @override
  String get msgOdendiOlarakIsaretlenenAlacaklarinizin => 'The history of your receivables marked as paid will be displayed here.';

  @override
  String paidReceivablesLengthAlacakTahsil(Object length) {
    return '$length receivables collected';
  }

  @override
  String get toplamGeriOdeme => 'Total repayment';

  @override
  String get kKDFVeBsmvVergilerini => 'Include KKDF and BSMV taxes (30%)';

  @override
  String get tuketiciKredilerindeFaizeYasal => 'In consumer loans, 15% KKDF and 15% BSMV are legally added to the interest. In housing etc. loans, these taxes can be 0%. Activate accordingly.';

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
  String get buIslemOtomatikOlusturuldu => 'This transaction was created automatically. Edit or delete it from the corresponding debt/investment/receivable record.';

  @override
  String get nakitAkisi => 'Cash Flow';

  @override
  String get grafikIcinYeterliVeri => 'Not enough data for chart';

  @override
  String get detayGosterilecekIslemYok => 'No Transaction to Show Detail';

  @override
  String get gelirVeyaGiderKaydettikten => 'Analysis details will be listed here after you save income or expense.';

  @override
  String get henuzIslemYok => 'No transactions yet';

  @override
  String get buDonemIcinKayit => 'No records for this period.\nUse the slider button to add a new transaction.';

  @override
  String get tumIslemlerinizGuncel => 'All Your Transactions Are Up To Date';

  @override
  String get bekleyenCevrimdisiIslemBulunmuyor => 'No pending offline transactions. Synchronization triggers automatically when your device connects to the internet or new data is entered.';

  @override
  String get haftalikNetAkis => 'Weekly Net Flow';

  @override
  String get kategoriDagilimi => 'Category Distribution';

  @override
  String titleIcinVeriYok(Object title) {
    return 'No data for $title';
  }

  @override
  String get buKategoriyeAitIslem => 'There are no transactions belonging to this category.';

  @override
  String formatMoneyItemTotalamountPercent(Object totalAmount, Object toStringAsFixed) {
    return '$totalAmount ($toStringAsFixed%)';
  }

  @override
  String get buDonemIcinHenuz => 'No transaction data found for this period yet. Reports will be compiled after data is entered.';

  @override
  String get ikonSecin => 'Select Icon';

  @override
  String get ikonDegistirmekIcinDokun => 'Tap to change icon';

  @override
  String categoriesWhereCC(Object customLength, Object defaultLength) {
    return '$customLength custom, $defaultLength default';
  }

  @override
  String get asagidakiButondanEkleyebilirsiniz => 'You can add from the button below';

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
  String appFormattersDateshortFormatStartdate(Object startDate, Object endDate) {
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
  String get yatirimlariniziEklediktenSonraDetayli => 'Detailed analyses will appear here after you add your investments.';

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
  String get maliyetiDegistirirsenizFarkCuzdana => 'If you change the cost, the difference will be processed as a correction transaction to the wallet.';

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
  String isProfitTotalprofitpercentageTostringasfixed(Object isProfit, Object toStringAsFixed) {
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
  String get islemEklerkenTekrarSikligi => 'If you select repeat frequency while adding a transaction\nthe template appears here.';

  @override
  String get bekleyenDuzenliIslemler => 'Pending Recurring Transactions';

  @override
  String get vadesiGelmisIslemlerinizVar => 'You have transactions whose maturity has arrived. You can approve them to be recorded in the ledger.';

  @override
  String titleTarihDatestrNtutarTx(Object dateStr, Object amount) {
    return 'Date: $dateStr\nAmount: $amount';
  }

  @override
  String get profilAyarlari => 'Profile Settings';

  @override
  String get bilgileriGuncelle => 'Update Info';

  @override
  String get ibo => 'Ibo';

  @override
  String get uygulamaKilidi => 'App Lock';

  @override
  String get pINBiyometrikVeGizlilik => 'PIN, Biometric and Privacy Settings';

  @override
  String get otomatikHesaplananDegerler => 'Automatically calculated values:';

  @override
  String get borcAlacakYatirimKayitlarindan => 'Derived from debt/receivable/investment records; cannot be edited here.';

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
  String get aktifOlanCuzdanSilinemez => '• Active wallet cannot be deleted. To delete, first make another wallet active.';

  @override
  String get cuzdanlarinizaAitBorcAlacak => '• You can manually manage Debt, Receivable, and Savings amounts of your wallets from the edit page.';

  @override
  String get msgPINOrBiometricLogin => 'PIN or biometric login is required for background lock';

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
}
