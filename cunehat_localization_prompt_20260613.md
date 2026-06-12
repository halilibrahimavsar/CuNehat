# Flutter Localization AI Prompt

> **Proje:** `cunehat` | **Tarih:** 2026-06-13 | **Occurrence:** 31 | **Benzersiz string:** 30 | **Etkilenen dosya:** 5

## 1. Proje Durumu

- **Localization kurulumu:** **Mevcut** — .arb dosyaları bulundu
- **l10n dizini / .arb:** ✅ Mevcut
- **main.dart localizationsDelegates:** ✅ Var
- **⚠️ Parametreli string (Dart interpolation):** 4 adet — ARB placeholder gerektirir
- **⚠️ BuildContext olmayan dosya:** 3 adet — özel yaklaşım gerektirir

## 2. Mevcut ARB Dosyaları

### app_en.arb

```json
{
  "@@locale": "en",
  "language": "Language",
  "turkish": "Turkish",
  "english": "English",
  "hataDetayi": "Error detail",
  "tekrarDene": "Try Again",
  "islemGecmisiCsv": "Transaction History (CSV)",
  "duzenle": "Edit",
  "sil": "Delete",
  "hintIkonAra": "Search icon...",
  "hataStateFailureMessage": "Error: {message}",
  "@hataStateFailureMessage": {
    "placeholders": {
      "message": {}
    }
  },
  "yeniButceEkle": "Add New Budget",
  "labelKategori": "Category",
  "labelAylikLimit": "Monthly Limit",
  "iptal": "Cancel",
  "borclarim": "My Debts",
  "alacaklarim": "My Receivables",
  "henuzBorcKaydiYok": "No debt record yet.",
  "odemeYap": "Make Payment",
  "ode": "Pay",
  "henuzAlacakKaydiYok": "No receivable record yet.",
  "odendiIsaretle": "Mark as Paid",
  "gecmis": "History",
  "borcGecmisi": "Debt History",
  "alacakGecmisi": "Receivable History",
  "aylikTaksitiBiliyorum": "I know the monthly installment",
  "faizOraniIle": "With interest rate",
  "esitTaksitAmortisman": "Equal Installment (Amortization)",
  "basitVadeFarki": "Simple Maturity Difference",
  "odemeyiKaydet": "Save Payment",
  "labelOdemeTutari": "Payment Amount *",
  "maksimumFormatmoneyRemaining": "Maximum: {remaining}",
  "@maksimumFormatmoneyRemaining": {
    "placeholders": {
      "remaining": {}
    }
  },
  "labelOdemeTarihi": "Payment Date",
  "labelNotOpsiyonel": "Note (Optional)",
  "hintOdemeIleIlgiliNotlar": "Notes about payment...",
  "islemDetayi": "Transaction Detail",
  "bekleyenIslemler": "Pending Transactions",
  "islemRaporu": "Transaction Report",
  "tooltipTarihAraligi": "Date Range",
  "msgSecilenTarihAraligindaIslem": "No transaction in selected date range",
  "degistir": "Change",
  "labelKategoriAdi": "Category Name",
  "hintOrnMarketKiraMaas": "e.g. Market, Rent, Salary",
  "ozelKategoriler": "Custom Categories",
  "varsayilanKategoriler": "Default Categories",
  "yeniKategoriEkle": "Add New Category",
  "temizle": "Clear",
  "labelMin": "Min",
  "labelMax": "Max",
  "hintNotIstegeBagliOrn": "Note (Optional) · e.g. Grocery shopping",
  "tekrarlamaIstegeBagli": "Recurring (Optional)",
  "tekrarEtme": "Do Not Repeat",
  "birikimDetayi": "Savings Detail",
  "vazgec": "Cancel",
  "sat": "Sell",
  "kaydiSil": "Delete Record",
  "tooltipFiyatlariGuncelle": "Update Prices",
  "hintSembolOrnAaplThyao": "Symbol (e.g. AAPL, THYAO.IS)",
  "sablonuSil": "Delete Template",
  "hataError": "Error: {error}",
  "@hataError": {
    "placeholders": {
      "error": {}
    }
  },
  "tooltipBuVadeyiAtla": "Skip this installment",
  "onayla": "Confirm",
  "kapat": "Close",
  "islemiDuzenle": "Edit Transaction",
  "labelYeniTutar": "New Amount",
  "kaydetVeOnayla": "Save and Confirm",
  "guvenlikAyarlari": "Security Settings",
  "iceAktarCsv": "Import (CSV)",
  "disaAktarCsv": "Export (CSV)",
  "geriYukle": "Restore",
  "yedekle": "Backup",
  "labelUygulamaTemasi": "App Theme",
  "labelCuzdanAdi": "Wallet Name *",
  "hintOrnAnaCuzdanTatil": "e.g. Main Wallet, Vacation Fund",
  "tamam": "OK",
  "beklenmeyenDurum": "Unexpected situation",
  "aktifCuzdaniniziDegistirmekIcin": "• Click on a wallet to change your active wallet.",
  "cuzdanBakiyeleriOtomatikOlarak": "• Wallet balances are updated automatically.",
  "herCuzdaninKendiGelir": "• Each wallet has its own income/expense records.",
  "msgTextsCheckfailedprefixETostring": "{checkFailedPrefix}: {error}",
  "@msgTextsCheckfailedprefixETostring": {
    "placeholders": {
      "checkFailedPrefix": {},
      "error": {}
    }
  },
  "msgPINVerificationFailedE": "PIN verification failed: {error}",
  "@msgPINVerificationFailedE": {
    "placeholders": {
      "error": {}
    }
  },
  "msgCreateAPinFirst": "Create a PIN first",
  "msgBiometricAuthenticationIsNot": "Biometric authentication is not supported",
  "msgBiometricAuthenticationFailed": "Biometric authentication failed",
  "msgBiometricLoginEnabled": "Biometric login enabled",
  "msgBiometricLoginDisabled": "Biometric login disabled",
  "msgPINAlreadyExistsUse": "PIN already exists, use change PIN instead",
  "msgPINsDoNotMatch": "PINs do not match",
  "msgPINSavedSuccessfully": "PIN saved successfully",
  "msgNewPinValuesDo": "New PIN values do not match",
  "msgCurrentPinIsIncorrect": "Current PIN is incorrect",
  "msgPINUpdatedSuccessfully": "PIN updated successfully",
  "msgPINRemoved": "PIN removed",
  "msgBackgroundLockAndPrivacy": "Background lock and Privacy Guard enabled",
  "securitySettings": "Security Settings",
  "manageYourAppSecurity": "Manage your app security",
  "createPin": "Create PIN",
  "changePin": "Change PIN",
  "removePin": "Remove PIN",
  "msgBiometricAuthenticationCannotBe": "Biometric authentication cannot be used on this device.",
  "msgCreateAPinFirst2": "Create a PIN first to enable biometric login.",
  "unifiedFeaturesDemo": "Unified Features Demo",
  "tarihSec": "Select Date",
  "dialog": "Dialog",
  "metinGiris": "Text Input",
  "yukle": "Load",
  "basarili": "Success",
  "hata": "Error",
  "yuklemeButonu": "Loading Button",
  "onayDialog": "Confirmation Dialog",
  "logoutLabel": "Logout",
  "welcomeTitle": "Welcome",
  "enterPinPrompt": "Enter PIN to continue",
  "lockedOutPromptPrefix": "Too many failed attempts. Wait",
  "lockedOutPromptSuffix": "seconds.",
  "invalidPinFallback": "Incorrect PIN, try again.",
  "biometricReason": "Authenticate to continue",
  "settingsTitle": "Security Settings",
  "createPinTitle": "Create PIN",
  "changePinTitle": "Change PIN",
  "deletePinTitle": "Remove PIN",
  "verifyPinTitle": "Verify PIN",
  "deletePinConfirmMessage": "Removing PIN will also disable biometric login. Continue?",
  "saveLabel": "Save",
  "changeLabel": "Change",
  "removeLabel": "Remove",
  "cancelLabel": "Cancel",
  "pinMismatchMessage": "PINs do not match",
  "pinValidationMessage": "Enter a 6-digit PIN",
  "pinLockTitle": "PIN Lock",
  "pinEnabledSubtitle": "PIN enabled",
  "pinNotSetSubtitle": "PIN not set",
  "biometricLoginTitle": "Biometric Login",
  "biometricNotAvailableSubtitle": "Biometric authentication is not available on this device",
  "biometricEnabledSubtitle": "Biometric login enabled",
  "biometricDisabledSubtitle": "Biometric login disabled",
  "biometricAuthTileTitle": "Biometric Authentication",
  "biometricAuthTileSubtitleOn": "On - Sign in with fingerprint or face recognition",
  "biometricAuthTileSubtitleOff": "Off",
  "privacyGuardTitle": "Privacy Guard",
  "privacyGuardEnabledSubtitle": "Screen protection enabled",
  "privacyGuardDisabledSubtitle": "Screen protection disabled",
  "screenProtectionTileTitle": "Screen Protection",
  "screenProtectionTileSubtitleOn": "On - Hide content while app is in background",
  "screenProtectionTileSubtitleOff": "Off",
  "backgroundLockTitle": "Background Lock",
  "backgroundLockSubtitlePrefix": "Locks after: ",
  "backgroundLockSubtitleOff": "Off",
  "backgroundLockTileTitle": "Require authentication when app stays in background",
  "backgroundLockTileSubtitle": "To enable background lock, set a PIN or enable biometric login.",
  "backgroundLockTileInfo": "Note: Authentication screen appears when returning to app.",
  "msgIncorrectPinRemainingTries": "Incorrect PIN. Remaining tries: {tries}",
  "@msgIncorrectPinRemainingTries": {
    "placeholders": {
      "tries": {}
    }
  },
  "settings": "Settings",
  "appearance": "APPEARANCE",
  "security": "SECURITY",
  "dataBackupTransfer": "DATA BACKUP / TRANSFER",
  "about": "ABOUT",
  "googleDriveBackup": "Google Drive Backup",
  "googleDriveBackupDesc": "Back up your data to your personal Google Drive account for safety.",
  "connectGoogleDrive": "Connect to Google Drive",
  "account": "Account:",
  "lastBackup": "Last Backup:",
  "disconnect": "Disconnect",
  "version": "Version",
  "developer": "Developer",
  "noBackupsYet": "No backups yet",
  "restoreDataTitle": "Restore Data?",
  "restoreDataDesc": "Your cloud data will overwrite the existing data on your device. This operation cannot be undone.",
  "googleDriveConnected": "Successfully connected to Google Drive.",
  "googleDriveConnectionFailed": "Google Drive connection failed.",
  "googleDriveDisconnected": "Google Drive disconnected.",
  "dataBackedUpSuccess": "Data successfully backed up to Google Drive.",
  "backupFailed": "Backup failed.",
  "dataRestoredSuccess": "Data successfully restored. Please restart the app for changes to take effect.",
  "restoreFailedNoBackup": "Restore failed. No backup file found.",
  "welcomeUser": "Welcome",
  "defaultUser": "User",
  "dataExportImport": "Export / Import Transactions",
  "dataExportImportDesc": "Export all your transactions in standard CSV format to use in other apps or back up.",
  "activeWalletRequiredForExport": "An active wallet is required for exporting.",
  "uygulamaBaslatilamadi": "App could not start",
  "verilerinizSilinmediTekrarDeneyin": "Your data was not deleted. Try again; if the problem persists ",
  "ikonBulunamadi": "Icon not found",
  "valueTostringasfixedCurrencysymbol": "{toStringAsFixed} {currencySymbol}",
  "@valueTostringasfixedCurrencysymbol": { "placeholders": { "toStringAsFixed": {}, "currencySymbol": {} } },
  "butcePlanlama": "Budget Planning",
  "henuzButceYok": "No budgets yet",
  "kategorilerinizeAylikHarcamaLimiti": "Set a monthly spending limit for your categories,\ntrack your spending here.",
  "bUAyToplamHarcama": "TOTAL SPENDING THIS MONTH",
  "toplamLimitAppformattersCurrency": "Total limit: {totalLimit}",
  "@toplamLimitAppformattersCurrency": { "placeholders": { "totalLimit": {} } },
  "percent": "{percent}%",
  "@percent": { "placeholders": { "percent": {} } },
  "harcananAppformattersCurrencyFormat": "Spent: {spentAmount}",
  "@harcananAppformattersCurrencyFormat": { "placeholders": { "spentAmount": {} } },
  "limitAppformattersCurrencyFormat": "Limit: {limitAmount}",
  "@limitAppformattersCurrencyFormat": { "placeholders": { "limitAmount": {} } },
  "buKategorininButcesiVar": "This category has a budget; limit will be updated.",
  "finansalTakip": "Financial Tracking",
  "vADESIGecmis": "OVERDUE",
  "oDENDI": "PAID",
  "vadeDebtTermmonthsAy": "Maturity: {termMonths} Months | {length} Payments",
  "@vadeDebtTermmonthsAy": { "placeholders": { "termMonths": {}, "length": {} } },
  "vadeDateformatDdMmm": "Maturity: {dueDate}",
  "@vadeDateformatDdMmm": { "placeholders": { "dueDate": {} } },
  "msgOdemesiTamamlanipKapatilanBorclarinizin": "The history of your paid and closed debts will be displayed here.",
  "paidDebtsLengthBorcKapandi": "{length} debts closed",
  "@paidDebtsLengthBorcKapandi": { "placeholders": { "length": {} } },
  "msgOdendiOlarakIsaretlenenAlacaklarinizin": "The history of your receivables marked as paid will be displayed here.",
  "paidReceivablesLengthAlacakTahsil": "{length} receivables collected",
  "@paidReceivablesLengthAlacakTahsil": { "placeholders": { "length": {} } },
  "toplamGeriOdeme": "Total repayment",
  "kKDFVeBsmvVergilerini": "Include KKDF and BSMV taxes (30%)",
  "tuketiciKredilerindeFaizeYasal": "In consumer loans, 15% KKDF and 15% BSMV are legally added to the interest. In housing etc. loans, these taxes can be 0%. Activate accordingly.",
  "iTaksitAppformattersDateshort": "{i}. Installment — {scheduledDate}",
  "@iTaksitAppformattersDateshort": { "placeholders": { "i": {}, "scheduledDate": {} } },
  "formatMoneyMonthlyamount": "≈ {monthlyAmount}",
  "@formatMoneyMonthlyamount": { "placeholders": { "monthlyAmount": {} } },
  "index": "{index}",
  "@index": { "placeholders": { "index": {} } },
  "optLabelFormatmoneyOpt": "{label}  {amount}",
  "@optLabelFormatmoneyOpt": { "placeholders": { "label": {}, "amount": {} } },
  "otomatikIslem": "Automatic transaction",
  "buIslemOtomatikOlusturuldu": "This transaction was created automatically. Edit or delete it from the corresponding debt/investment/receivable record.",
  "nakitAkisi": "Cash Flow",
  "grafikIcinYeterliVeri": "Not enough data for chart",
  "detayGosterilecekIslemYok": "No Transaction to Show Detail",
  "gelirVeyaGiderKaydettikten": "Analysis details will be listed here after you save income or expense.",
  "henuzIslemYok": "No transactions yet",
  "buDonemIcinKayit": "No records for this period.\nUse the slider button to add a new transaction.",
  "tumIslemlerinizGuncel": "All Your Transactions Are Up To Date",
  "bekleyenCevrimdisiIslemBulunmuyor": "No pending offline transactions. Synchronization triggers automatically when your device connects to the internet or new data is entered.",
  "haftalikNetAkis": "Weekly Net Flow",
  "kategoriDagilimi": "Category Distribution",
  "titleIcinVeriYok": "No data for {title}",
  "@titleIcinVeriYok": { "placeholders": { "title": {} } },
  "buKategoriyeAitIslem": "There are no transactions belonging to this category.",
  "formatMoneyItemTotalamountPercent": "{totalAmount} ({toStringAsFixed}%)",
  "@formatMoneyItemTotalamountPercent": { "placeholders": { "totalAmount": {}, "toStringAsFixed": {} } },
  "buDonemIcinHenuz": "No transaction data found for this period yet. Reports will be compiled after data is entered.",
  "ikonSecin": "Select Icon",
  "ikonDegistirmekIcinDokun": "Tap to change icon",
  "categoriesWhereCC": "{customLength} custom, {defaultLength} default",
  "@categoriesWhereCC": { "placeholders": { "customLength": {}, "defaultLength": {} } },
  "asagidakiButondanEkleyebilirsiniz": "You can add from the button below",
  "varsayilan": "Default",
  "filtreler": "Filters",
  "uygula": "Apply",
  "tARIHAraligi": "DATE RANGE",
  "seciliAralik": "Selected Range",
  "kATEGORIFiltresi": "CATEGORY FILTER",
  "kategoriBulunamadi": "Category not found",
  "fIYATAraligi": "PRICE RANGE",
  "yeni": "New",
  "appFormattersDateshortFormatStartdate": "{startDate} - {endDate}",
  "@appFormattersDateshortFormatStartdate": { "placeholders": { "startDate": {}, "endDate": {} } },
  "filterSelectedcategoriesLengthKategori": "{length} Categories",
  "@filterSelectedcategoriesLengthKategori": { "placeholders": { "length": {} } },
  "gunSonu": "End of day ",
  "netNetAppformattersCurrency": "Net: {net}",
  "@netNetAppformattersCurrency": { "placeholders": { "net": {} } },
  "dataFilterSelectedcategoriesLengthKategori": "{length} Categories",
  "@dataFilterSelectedcategoriesLengthKategori": { "placeholders": { "length": {} } },
  "countCountlabel": "{count} {countLabel}",
  "@countCountlabel": { "placeholders": { "count": {}, "countLabel": {} } },
  "portfoyDetayi": "Portfolio Detail",
  "henuzYatirimKaydiYok": "No Investment Record Yet",
  "yatirimlariniziEklediktenSonraDetayli": "Detailed analyses will appear here after you add your investments.",
  "guncelDegerFormatmoneyInvestment": "Current value ({currentValue}) will be processed as income to the wallet and the record will be closed.",
  "@guncelDegerFormatmoneyInvestment": { "placeholders": { "currentValue": {} } },
  "hataliGirislerIcinAlim": "For incorrect entries: purchase expense ({amount}) will be refunded with a correction record, and the balance will revert to pre-investment.\n\nIf you actually sold it, use \"Sell\" instead.",
  "@hataliGirislerIcinAlim": { "placeholders": { "amount": {} } },
  "portfoyum": "My Portfolio",
  "investmentsLengthYatirim": "{length} investments",
  "@investmentsLengthYatirim": { "placeholders": { "length": {} } },
  "mevcutDeger": "Current Value",
  "maliyetiDegistirirsenizFarkCuzdana": "If you change the cost, the difference will be processed as a correction transaction to the wallet.",
  "hesapla": "Calculate",
  "birikmisFormatmoneyInvCurrentvalue": "Accumulated: {currentValue} / ",
  "@birikmisFormatmoneyInvCurrentvalue": { "placeholders": { "currentValue": {} } },
  "guncelFiyatiGetir": "Get Current Price",
  "ekle": "Add",
  "karZarar": "Profit/Loss",
  "investmentProfitpercentageTostringasfixed": "{toStringAsFixed}%",
  "@investmentProfitpercentageTostringasfixed": { "placeholders": { "toStringAsFixed": {} } },
  "hedefCurrencyformatFormatInvestment": "Target: {targetAmount}",
  "@hedefCurrencyformatFormatInvestment": { "placeholders": { "targetAmount": {} } },
  "investmentTargetprogressTostringasfixed": "{toStringAsFixed}%",
  "@investmentTargetprogressTostringasfixed": { "placeholders": { "toStringAsFixed": {} } },
  "grafikIcinYatirimBulunmuyor": "No investments for chart",
  "portfoyDagilimi": "Portfolio Distribution",
  "percentage": "{percentage}%",
  "@percentage": { "placeholders": { "percentage": {} } },
  "tOPLAMPortfoyDegeri": "TOTAL PORTFOLIO VALUE",
  "tOPLAMMaliyet": "TOTAL COST",
  "kAZANCZarar": "PROFIT / LOSS",
  "isProfitTotalprofitpercentageTostringasfixed": "{isProfit}{toStringAsFixed}%",
  "@isProfitTotalprofitpercentageTostringasfixed": { "placeholders": { "isProfit": {}, "toStringAsFixed": {} } },
  "templateTitleDuzenliIslemi": "Delete recurring transaction \"{title}\"?\n\nPast transactions recorded in the ledger will not be deleted.",
  "@templateTitleDuzenliIslemi": { "placeholders": { "title": {} } },
  "duzenliIslemler": "Recurring Transactions",
  "henuzDuzenliIslemYok": "No recurring transactions yet",
  "islemEklerkenTekrarSikligi": "If you select repeat frequency while adding a transaction\nthe template appears here.",
  "bekleyenDuzenliIslemler": "Pending Recurring Transactions",
  "vadesiGelmisIslemlerinizVar": "You have transactions whose maturity has arrived. You can approve them to be recorded in the ledger.",
  "titleTarihDatestrNtutarTx": "Date: {dateStr}\nAmount: {amount}",
  "@titleTarihDatestrNtutarTx": { "placeholders": { "dateStr": {}, "amount": {} } },
  "profilAyarlari": "Profile Settings",
  "bilgileriGuncelle": "Update Info",
  "ibo": "Ibo",
  "uygulamaKilidi": "App Lock",
  "pINBiyometrikVeGizlilik": "PIN, Biometric and Privacy Settings",
  "otomatikHesaplananDegerler": "Automatically calculated values:",
  "borcAlacakYatirimKayitlarindan": "Derived from debt/receivable/investment records; cannot be edited here.",
  "renkSecin": "Select Color:",
  "ikonSecin2": "Select Icon:",
  "ikonDegistir": "Change Icon",
  "cuzdanlarim": "My Wallets",
  "cuzdanlariniziYonetin": "Manage your wallets",
  "yeniCuzdanOlustur": "Create New Wallet",
  "finansalNyolculugunuzBasliyor": "Your Financial\nJourney Begins",
  "ilkCuzdaniOlustur": "Create First Wallet",
  "olusturulmaAppformattersDateshortFormat": "Created: {createdAt}",
  "@olusturulmaAppformattersDateshortFormat": { "placeholders": { "createdAt": {} } },
  "aktif": "Active",
  "aktifOlanCuzdanSilinemez": "• Active wallet cannot be deleted. To delete, first make another wallet active.",
  "cuzdanlarinizaAitBorcAlacak": "• You can manually manage Debt, Receivable, and Savings amounts of your wallets from the edit page.",
  "msgIncorrectPinRemainingTries": "Incorrect PIN. Remaining tries: {newAttempts}",
  "@msgIncorrectPinRemainingTries": { "placeholders": { "newAttempts": {} } },
  "msgPINVerificationFailedE": "PIN verification failed: {error}",
  "@msgPINVerificationFailedE": { "placeholders": { "error": {} } },
  "msgCreateAPinFirst": "Create a PIN first",
  "msgBiometricAuthenticationIsNot": "Biometric authentication is not supported",
  "msgBiometricAuthenticationFailed": "Biometric authentication failed",
  "msgBiometricLoginEnabled": "Biometric login enabled",
  "msgBiometricLoginDisabled": "Biometric login disabled",
  "msgPINAlreadyExistsUse": "PIN already exists, use change PIN instead",
  "msgPINsDoNotMatch": "PINs do not match",
  "msgPINSavedSuccessfully": "PIN saved successfully",
  "msgNewPinValuesDo": "New PIN values do not match",
  "msgCurrentPinIsIncorrect": "Current PIN is incorrect",
  "msgPINUpdatedSuccessfully": "PIN updated successfully",
  "msgPINRemoved": "PIN removed",
  "msgPINOrBiometricLogin": "PIN or biometric login is required for background lock",
  "msgBackgroundLockAndPrivacy": "Background lock and Privacy Guard enabled",
  "unifiedFeaturesDemo": "Unified Features Demo",
  "sharedFeatures": "Shared Features",
  "tarihSec": "Select Date",
  "tarihAraligi": "Date Range",
  "dialog": "Dialog",
  "metinGiris": "Text Input",
  "yukle": "Load",
  "butonGalerisi": "Button Gallery",
  "basarili": "Success",
  "hata": "Error",
  "yuklemeButonu": "Loading Button",
  "onayDialog": "Confirmation Dialog",
  "internetBaglantisiAktif": "Internet connection is active",
  "internetBaglantisiYok": "No internet connection",
  "baglantiKontrolEdiliyor": "Checking connection...",
  "taksit1": "1 installment",
  "taksit2": "2 installments",
  "tamaminiOde": "Pay all"
}
```

### app_tr.arb

```json
{
  "@@locale": "tr",
  "language": "Dil",
  "turkish": "Türkçe",
  "english": "İngilizce",
  "hataDetayi": "Hata detayı",
  "tekrarDene": "Tekrar Dene",
  "islemGecmisiCsv": "İşlem Geçmişi (CSV)",
  "duzenle": "Düzenle",
  "sil": "Sil",
  "hintIkonAra": "İkon ara...",
  "hataStateFailureMessage": "Hata: {message}",
  "@hataStateFailureMessage": {
    "placeholders": {
      "message": {}
    }
  },
  "yeniButceEkle": "Yeni Bütçe Ekle",
  "labelKategori": "Kategori",
  "labelAylikLimit": "Aylık Limit",
  "iptal": "İptal",
  "borclarim": "Borçlarım",
  "alacaklarim": "Alacaklarım",
  "henuzBorcKaydiYok": "Henüz borç kaydı yok.",
  "odemeYap": "Ödeme Yap",
  "ode": "Öde",
  "henuzAlacakKaydiYok": "Henüz alacak kaydı yok.",
  "odendiIsaretle": "Ödendi İşaretle",
  "gecmis": "Geçmiş",
  "borcGecmisi": "Borç Geçmişi",
  "alacakGecmisi": "Alacak Geçmişi",
  "aylikTaksitiBiliyorum": "Aylık taksiti biliyorum",
  "faizOraniIle": "Faiz oranı ile",
  "esitTaksitAmortisman": "Eşit Taksit (Amortisman)",
  "basitVadeFarki": "Basit Vade Farkı",
  "odemeyiKaydet": "Ödemeyi Kaydet",
  "labelOdemeTutari": "Ödeme Tutarı *",
  "maksimumFormatmoneyRemaining": "Maksimum: {remaining}",
  "@maksimumFormatmoneyRemaining": {
    "placeholders": {
      "remaining": {}
    }
  },
  "labelOdemeTarihi": "Ödeme Tarihi",
  "labelNotOpsiyonel": "Not (Opsiyonel)",
  "hintOdemeIleIlgiliNotlar": "Ödeme ile ilgili notlar...",
  "islemDetayi": "İşlem Detayı",
  "bekleyenIslemler": "Bekleyen İşlemler",
  "islemRaporu": "İşlem Raporu",
  "tooltipTarihAraligi": "Tarih Aralığı",
  "msgSecilenTarihAraligindaIslem": "Seçilen tarih aralığında işlem yok",
  "degistir": "Değiştir",
  "labelKategoriAdi": "Kategori Adı",
  "hintOrnMarketKiraMaas": "Örn: Market, Kira, Maaş",
  "ozelKategoriler": "Özel Kategoriler",
  "varsayilanKategoriler": "Varsayılan Kategoriler",
  "yeniKategoriEkle": "Yeni Kategori Ekle",
  "temizle": "Temizle",
  "labelMin": "Min",
  "labelMax": "Max",
  "hintNotIstegeBagliOrn": "Not (İsteğe bağlı) · örn. Market alışverişi",
  "tekrarlamaIstegeBagli": "Tekrarlama (İsteğe Bağlı)",
  "tekrarEtme": "Tekrar Etme",
  "birikimDetayi": "Birikim Detayı",
  "vazgec": "Vazgeç",
  "sat": "Sat",
  "kaydiSil": "Kaydı Sil",
  "tooltipFiyatlariGuncelle": "Fiyatları Güncelle",
  "hintSembolOrnAaplThyao": "Sembol (Örn: AAPL, THYAO.IS)",
  "sablonuSil": "Şablonu Sil",
  "hataError": "Hata: {error}",
  "@hataError": {
    "placeholders": {
      "error": {}
    }
  },
  "tooltipBuVadeyiAtla": "Bu vadeyi atla",
  "onayla": "Onayla",
  "kapat": "Kapat",
  "islemiDuzenle": "İşlemi Düzenle",
  "labelYeniTutar": "Yeni Tutar",
  "kaydetVeOnayla": "Kaydet ve Onayla",
  "guvenlikAyarlari": "Güvenlik Ayarları",
  "iceAktarCsv": "İçe Aktar (CSV)",
  "disaAktarCsv": "Dışa Aktar (CSV)",
  "geriYukle": "Geri Yükle",
  "yedekle": "Yedekle",
  "labelUygulamaTemasi": "Uygulama Teması",
  "labelCuzdanAdi": "Cüzdan Adı *",
  "hintOrnAnaCuzdanTatil": "Örn: Ana Cüzdan, Tatil Fonu",
  "tamam": "Tamam",
  "beklenmeyenDurum": "Beklenmeyen durum",
  "aktifCuzdaniniziDegistirmekIcin": "• Aktif cüzdanınızı değiştirmek için bir cüzdana tıklayın.",
  "cuzdanBakiyeleriOtomatikOlarak": "• Cüzdan bakiyeleri otomatik olarak güncellenir.",
  "herCuzdaninKendiGelir": "• Her cüzdanın kendi gelir/gider kayıtları vardır.",
  "msgTextsCheckfailedprefixETostring": "{checkFailedPrefix}: {error}",
  "@msgTextsCheckfailedprefixETostring": {
    "placeholders": {
      "checkFailedPrefix": {},
      "error": {}
    }
  },
  "msgPINVerificationFailedE": "PIN doğrulama başarısız: {error}",
  "@msgPINVerificationFailedE": {
    "placeholders": {
      "error": {}
    }
  },
  "msgCreateAPinFirst": "Önce bir PIN oluşturun",
  "msgBiometricAuthenticationIsNot": "Biyometrik kimlik doğrulama desteklenmiyor",
  "msgBiometricAuthenticationFailed": "Biyometrik kimlik doğrulama başarısız",
  "msgBiometricLoginEnabled": "Biyometrik giriş etkinleştirildi",
  "msgBiometricLoginDisabled": "Biyometrik giriş devre dışı bırakıldı",
  "msgPINAlreadyExistsUse": "PIN zaten mevcut, bunun yerine PIN değiştirmeyi kullanın",
  "msgPINsDoNotMatch": "PIN'ler eşleşmiyor",
  "msgPINSavedSuccessfully": "PIN başarıyla kaydedildi",
  "msgNewPinValuesDo": "Yeni PIN değerleri eşleşmiyor",
  "msgCurrentPinIsIncorrect": "Mevcut PIN hatalı",
  "msgPINUpdatedSuccessfully": "PIN başarıyla güncellendi",
  "msgPINRemoved": "PIN kaldırıldı",
  "msgBackgroundLockAndPrivacy": "Arka plan kilidi ve Gizlilik Koruması etkinleştirildi",
  "securitySettings": "Güvenlik Ayarları",
  "manageYourAppSecurity": "Uygulama güvenliğinizi yönetin",
  "createPin": "PIN Oluştur",
  "changePin": "PIN Değiştir",
  "removePin": "PIN Kaldır",
  "msgBiometricAuthenticationCannotBe": "Biyometrik kimlik doğrulama bu cihazda kullanılamaz.",
  "msgCreateAPinFirst2": "Biyometrik girişi etkinleştirmek için önce bir PIN oluşturun.",
  "unifiedFeaturesDemo": "Birleşik Özellikler Demosu",
  "tarihSec": "Tarih Seç",
  "dialog": "Dialog",
  "metinGiris": "Metin Giriş",
  "yukle": "Yükle",
  "basarili": "Başarılı",
  "hata": "Hata",
  "yuklemeButonu": "Yükleme Butonu",
  "onayDialog": "Onay Dialog",
  "logoutLabel": "Çıkış Yap",
  "welcomeTitle": "Hoş Geldiniz",
  "enterPinPrompt": "Devam etmek için PIN girin",
  "lockedOutPromptPrefix": "Çok fazla başarısız deneme. Lütfen",
  "lockedOutPromptSuffix": "saniye bekleyin.",
  "invalidPinFallback": "Hatalı PIN, tekrar deneyin.",
  "biometricReason": "Devam etmek için kimliğinizi doğrulayın",
  "settingsTitle": "Güvenlik Ayarları",
  "createPinTitle": "PIN Oluştur",
  "changePinTitle": "PIN Değiştir",
  "deletePinTitle": "PIN Kaldır",
  "verifyPinTitle": "PIN Doğrula",
  "deletePinConfirmMessage": "PIN kaldırma biyometrik girişi de devre dışı bırakır. Devam edilsin mi?",
  "saveLabel": "Kaydet",
  "changeLabel": "Değiştir",
  "removeLabel": "Kaldır",
  "cancelLabel": "İptal",
  "pinMismatchMessage": "PIN'ler eşleşmiyor",
  "pinValidationMessage": "6 haneli bir PIN girin",
  "pinLockTitle": "PIN Kilidi",
  "pinEnabledSubtitle": "PIN etkin",
  "pinNotSetSubtitle": "PIN ayarlanmamış",
  "biometricLoginTitle": "Biyometrik Giriş",
  "biometricNotAvailableSubtitle": "Biyometrik kimlik doğrulama bu cihazda kullanılamaz",
  "biometricEnabledSubtitle": "Biyometrik giriş etkin",
  "biometricDisabledSubtitle": "Biyometrik giriş devre dışı",
  "biometricAuthTileTitle": "Biyometrik Kimlik Doğrulama",
  "biometricAuthTileSubtitleOn": "Açık - Parmak izi veya yüz tanıma ile giriş yapın",
  "biometricAuthTileSubtitleOff": "Kapalı",
  "privacyGuardTitle": "Gizlilik Koruması",
  "privacyGuardEnabledSubtitle": "Ekran koruması etkin",
  "privacyGuardDisabledSubtitle": "Ekran koruması devre dışı",
  "screenProtectionTileTitle": "Ekran Koruması",
  "screenProtectionTileSubtitleOn": "Açık - Uygulama arka plandayken içeriği gizle",
  "screenProtectionTileSubtitleOff": "Kapalı",
  "backgroundLockTitle": "Arka Plan Kilidi",
  "backgroundLockSubtitlePrefix": "Şu süre sonunda kilitler: ",
  "backgroundLockSubtitleOff": "Kapalı",
  "backgroundLockTileTitle": "Uygulama arka planda kaldığında kimlik doğrulama gerektir",
  "backgroundLockTileSubtitle": "Arka plan kilidini etkinleştirmek için bir PIN ayarlayın veya biyometrik girişi açın.",
  "backgroundLockTileInfo": "Not: Uygulamaya dönerken kimlik doğrulama ekranı görünür.",
  "msgIncorrectPinRemainingTries": "Hatalı PIN. Kalan deneme: {tries}",
  "@msgIncorrectPinRemainingTries": {
    "placeholders": {
      "tries": {}
    }
  },
  "settings": "Ayarlar",
  "appearance": "GÖRÜNÜM",
  "security": "GÜVENLİK",
  "dataBackupTransfer": "VERİ YEDEKLEME / AKTARIM",
  "about": "HAKKINDA",
  "googleDriveBackup": "Google Drive Yedekleme",
  "googleDriveBackupDesc": "Verilerinizin güvenliği için kendi kişisel Google Drive hesabınıza yedekleme yapın.",
  "connectGoogleDrive": "Google Drive'a Bağlan",
  "account": "Hesap:",
  "lastBackup": "Son Yedekleme:",
  "disconnect": "Bağlantıyı Kes",
  "version": "Sürüm",
  "developer": "Geliştirici",
  "noBackupsYet": "Hiç yedekleme yapılmadı",
  "restoreDataTitle": "Verileri Geri Yükle?",
  "restoreDataDesc": "Buluttaki verileriniz cihazınızdaki mevcut verilerin üzerine yazılacaktır. Bu işlem geri alınamaz.",
  "googleDriveConnected": "Google Drive başarıyla bağlandı.",
  "googleDriveConnectionFailed": "Google Drive bağlantısı başarısız oldu.",
  "googleDriveDisconnected": "Google Drive bağlantısı kesildi.",
  "dataBackedUpSuccess": "Veriler Google Drive'a başarıyla yedeklendi.",
  "backupFailed": "Yedekleme başarısız oldu.",
  "dataRestoredSuccess": "Veriler başarıyla geri yüklendi. Değişikliklerin görünmesi için lütfen uygulamayı yeniden başlatın.",
  "restoreFailedNoBackup": "Geri yükleme başarısız oldu. Yedek dosyası bulunamadı.",
  "welcomeUser": "Hoşgeldiniz",
  "defaultUser": "Kullanıcı",
  "dataExportImport": "İşlem Dışa / İçe Aktar",
  "dataExportImportDesc": "Tüm işlemlerinizi standart CSV formatında dışa aktararak diğer uygulamalarda kullanabilir veya yedekleyebilirsiniz.",
  "activeWalletRequiredForExport": "Dışa aktarım için aktif bir cüzdan gereklidir.",
  "uygulamaBaslatilamadi": "Uygulama başlatılamadı",
  "verilerinizSilinmediTekrarDeneyin": "Verileriniz silinmedi. Tekrar deneyin; sorun sürerse ",
  "ikonBulunamadi": "İkon bulunamadı",
  "valueTostringasfixedCurrencysymbol": "{toStringAsFixed} {currencySymbol}",
  "@valueTostringasfixedCurrencysymbol": { "placeholders": { "toStringAsFixed": {}, "currencySymbol": {} } },
  "butcePlanlama": "Bütçe Planlama",
  "henuzButceYok": "Henüz bütçe yok",
  "kategorilerinizeAylikHarcamaLimiti": "Kategorilerinize aylık harcama limiti koyun,\nharcamalarınızı buradan takip edin.",
  "bUAyToplamHarcama": "BU AY TOPLAM HARCAMA",
  "toplamLimitAppformattersCurrency": "Toplam limit: {totalLimit}",
  "@toplamLimitAppformattersCurrency": { "placeholders": { "totalLimit": {} } },
  "percent": "%{percent}",
  "@percent": { "placeholders": { "percent": {} } },
  "harcananAppformattersCurrencyFormat": "Harcanan: {spentAmount}",
  "@harcananAppformattersCurrencyFormat": { "placeholders": { "spentAmount": {} } },
  "limitAppformattersCurrencyFormat": "Limit: {limitAmount}",
  "@limitAppformattersCurrencyFormat": { "placeholders": { "limitAmount": {} } },
  "buKategorininButcesiVar": "Bu kategorinin bütçesi var; limit güncellenecek.",
  "finansalTakip": "Finansal Takip",
  "vADESIGecmis": "VADESİ GEÇMİŞ",
  "oDENDI": "ÖDENDİ",
  "vadeDebtTermmonthsAy": "Vade: {termMonths} Ay | {length} Ödeme",
  "@vadeDebtTermmonthsAy": { "placeholders": { "termMonths": {}, "length": {} } },
  "vadeDateformatDdMmm": "Vade: {dueDate}",
  "@vadeDateformatDdMmm": { "placeholders": { "dueDate": {} } },
  "msgOdemesiTamamlanipKapatilanBorclarinizin": "Ödemesi tamamlanıp kapatılan borçlarınızın geçmişi burada görüntülenecektir.",
  "paidDebtsLengthBorcKapandi": "{length} borç kapandı",
  "@paidDebtsLengthBorcKapandi": { "placeholders": { "length": {} } },
  "msgOdendiOlarakIsaretlenenAlacaklarinizin": "Ödendi olarak işaretlenen alacaklarınızın geçmişi burada görüntülenecektir.",
  "paidReceivablesLengthAlacakTahsil": "{length} alacak tahsil edildi",
  "@paidReceivablesLengthAlacakTahsil": { "placeholders": { "length": {} } },
  "toplamGeriOdeme": "Toplam geri ödeme",
  "kKDFVeBsmvVergilerini": "KKDF ve BSMV vergilerini (%30) dahil et",
  "tuketiciKredilerindeFaizeYasal": "Tüketici kredilerinde faize yasal olarak %15 KKDF ve %15 BSMV eklenir. Konut vb. kredilerde bu vergiler %0 olabilir. Duruma göre aktifleştirin.",
  "iTaksitAppformattersDateshort": "{i}. Taksit — {scheduledDate}",
  "@iTaksitAppformattersDateshort": { "placeholders": { "i": {}, "scheduledDate": {} } },
  "formatMoneyMonthlyamount": "≈ {monthlyAmount}",
  "@formatMoneyMonthlyamount": { "placeholders": { "monthlyAmount": {} } },
  "index": "{index}",
  "@index": { "placeholders": { "index": {} } },
  "optLabelFormatmoneyOpt": "{label}  {amount}",
  "@optLabelFormatmoneyOpt": { "placeholders": { "label": {}, "amount": {} } },
  "otomatikIslem": "Otomatik işlem",
  "buIslemOtomatikOlusturuldu": "Bu işlem otomatik oluşturuldu. İlgili borç/yatırım/alacak kaydından düzenleyin veya silin.",
  "nakitAkisi": "Nakit Akışı",
  "grafikIcinYeterliVeri": "Grafik için yeterli veri yok",
  "detayGosterilecekIslemYok": "Detay Gösterilecek İşlem Yok",
  "gelirVeyaGiderKaydettikten": "Gelir veya gider kaydettikten sonra analiz detayları burada listelenecektir.",
  "henuzIslemYok": "Henüz işlem yok",
  "buDonemIcinKayit": "Bu dönem için kayıt bulunmuyor.\nYeni bir işlem eklemek için sürgü butonunu kullanın.",
  "tumIslemlerinizGuncel": "Tüm İşlemleriniz Güncel",
  "bekleyenCevrimdisiIslemBulunmuyor": "Bekleyen çevrimdışı işlem bulunmuyor. Cihazınız internete bağlandığında veya yeni veriler girildiğinde senkronizasyon otomatik olarak tetiklenir.",
  "haftalikNetAkis": "Haftalık Net Akış",
  "kategoriDagilimi": "Kategori Dağılımı",
  "titleIcinVeriYok": "{title} için veri yok",
  "@titleIcinVeriYok": { "placeholders": { "title": {} } },
  "buKategoriyeAitIslem": "Bu kategoriye ait işlem bulunmuyor.",
  "formatMoneyItemTotalamountPercent": "{totalAmount} (%{toStringAsFixed})",
  "@formatMoneyItemTotalamountPercent": { "placeholders": { "totalAmount": {}, "toStringAsFixed": {} } },
  "buDonemIcinHenuz": "Bu dönem için henüz işlem verisi bulunamadı. Raporlar veri girildikten sonra derlenecektir.",
  "ikonSecin": "İkon Seçin",
  "ikonDegistirmekIcinDokun": "İkon değiştirmek için dokun",
  "categoriesWhereCC": "{customLength} özel, {defaultLength} varsayılan",
  "@categoriesWhereCC": { "placeholders": { "customLength": {}, "defaultLength": {} } },
  "asagidakiButondanEkleyebilirsiniz": "Aşağıdaki butondan ekleyebilirsiniz",
  "varsayilan": "Varsayılan",
  "filtreler": "Filtreler",
  "uygula": "Uygula",
  "tARIHAraligi": "TARİH ARALIĞI",
  "seciliAralik": "Seçili Aralık",
  "kATEGORIFiltresi": "KATEGORİ FİLTRESİ",
  "kategoriBulunamadi": "Kategori bulunamadı",
  "fIYATAraligi": "FİYAT ARALIĞI",
  "yeni": "Yeni",
  "appFormattersDateshortFormatStartdate": "{startDate} - {endDate}",
  "@appFormattersDateshortFormatStartdate": { "placeholders": { "startDate": {}, "endDate": {} } },
  "filterSelectedcategoriesLengthKategori": "{length} Kategori",
  "@filterSelectedcategoriesLengthKategori": { "placeholders": { "length": {} } },
  "gunSonu": "Gün sonu ",
  "netNetAppformattersCurrency": "Net: {net}",
  "@netNetAppformattersCurrency": { "placeholders": { "net": {} } },
  "dataFilterSelectedcategoriesLengthKategori": "{length} Kategori",
  "@dataFilterSelectedcategoriesLengthKategori": { "placeholders": { "length": {} } },
  "countCountlabel": "{count} {countLabel}",
  "@countCountlabel": { "placeholders": { "count": {}, "countLabel": {} } },
  "portfoyDetayi": "Portföy Detayı",
  "henuzYatirimKaydiYok": "Henüz Yatırım Kaydı Yok",
  "yatirimlariniziEklediktenSonraDetayli": "Yatırımlarınızı ekledikten sonra detaylı analizler burada görünecektir.",
  "guncelDegerFormatmoneyInvestment": "Güncel değer ({currentValue}) cüzdana gelir olarak işlenir ve kayıt kapatılır.",
  "@guncelDegerFormatmoneyInvestment": { "placeholders": { "currentValue": {} } },
  "hataliGirislerIcinAlim": "Hatalı girişler için: alım gideri ({amount}) düzeltme kaydıyla iade edilir, bakiye yatırım öncesine döner.\n\nGerçekten sattıysanız bunun yerine \"Sat\" kullanın.",
  "@hataliGirislerIcinAlim": { "placeholders": { "amount": {} } },
  "portfoyum": "Portföyüm",
  "investmentsLengthYatirim": "{length} yatırım",
  "@investmentsLengthYatirim": { "placeholders": { "length": {} } },
  "mevcutDeger": "Mevcut Değer",
  "maliyetiDegistirirsenizFarkCuzdana": "Maliyeti değiştirirseniz fark, cüzdana düzeltme hareketi olarak işlenir.",
  "hesapla": "Hesapla",
  "birikmisFormatmoneyInvCurrentvalue": "Birikmiş: {currentValue} / ",
  "@birikmisFormatmoneyInvCurrentvalue": { "placeholders": { "currentValue": {} } },
  "guncelFiyatiGetir": "Güncel Fiyatı Getir",
  "ekle": "Ekle",
  "karZarar": "Kar/Zarar",
  "investmentProfitpercentageTostringasfixed": "{toStringAsFixed}%",
  "@investmentProfitpercentageTostringasfixed": { "placeholders": { "toStringAsFixed": {} } },
  "hedefCurrencyformatFormatInvestment": "Hedef: {targetAmount}",
  "@hedefCurrencyformatFormatInvestment": { "placeholders": { "targetAmount": {} } },
  "investmentTargetprogressTostringasfixed": "{toStringAsFixed}%",
  "@investmentTargetprogressTostringasfixed": { "placeholders": { "toStringAsFixed": {} } },
  "grafikIcinYatirimBulunmuyor": "Grafik için yatırım bulunmuyor",
  "portfoyDagilimi": "Portföy Dağılımı",
  "percentage": "%{percentage}",
  "@percentage": { "placeholders": { "percentage": {} } },
  "tOPLAMPortfoyDegeri": "TOPLAM PORTFÖY DEĞERİ",
  "tOPLAMMaliyet": "TOPLAM MALİYET",
  "kAZANCZarar": "KAZANÇ / ZARAR",
  "isProfitTotalprofitpercentageTostringasfixed": "{isProfit}{toStringAsFixed}%",
  "@isProfitTotalprofitpercentageTostringasfixed": { "placeholders": { "isProfit": {}, "toStringAsFixed": {} } },
  "templateTitleDuzenliIslemi": "\"{title}\" düzenli işlemi silinsin mi?\n\nDeftere işlenmiş geçmiş işlemler silinmez.",
  "@templateTitleDuzenliIslemi": { "placeholders": { "title": {} } },
  "duzenliIslemler": "Düzenli İşlemler",
  "henuzDuzenliIslemYok": "Henüz düzenli işlem yok",
  "islemEklerkenTekrarSikligi": "İşlem eklerken tekrar sıklığı seçerseniz\nşablon burada görünür.",
  "bekleyenDuzenliIslemler": "Bekleyen Düzenli İşlemler",
  "vadesiGelmisIslemlerinizVar": "Vadesi gelmiş işlemleriniz var. Onaylayarak deftere işlenmesini sağlayabilirsiniz.",
  "titleTarihDatestrNtutarTx": "Tarih: {dateStr}\nTutar: {amount}",
  "@titleTarihDatestrNtutarTx": { "placeholders": { "dateStr": {}, "amount": {} } },
  "profilAyarlari": "Profil Ayarları",
  "bilgileriGuncelle": "Bilgileri Güncelle",
  "ibo": "İbo",
  "uygulamaKilidi": "Uygulama Kilidi",
  "pINBiyometrikVeGizlilik": "PIN, Biyometrik ve Gizlilik Ayarları",
  "otomatikHesaplananDegerler": "Otomatik hesaplanan değerler:",
  "borcAlacakYatirimKayitlarindan": "Borç/alacak/yatırım kayıtlarından türetilir; buradan düzenlenemez.",
  "renkSecin": "Renk Seçin:",
  "ikonSecin2": "İkon Seçin:",
  "ikonDegistir": "İkon Değiştir",
  "cuzdanlarim": "Cüzdanlarım",
  "cuzdanlariniziYonetin": "Cüzdanlarınızı yönetin",
  "yeniCuzdanOlustur": "Yeni Cüzdan Oluştur",
  "finansalNyolculugunuzBasliyor": "Finansal\nYolculuğunuz Başlıyor",
  "ilkCuzdaniOlustur": "İlk Cüzdanı Oluştur",
  "olusturulmaAppformattersDateshortFormat": "Oluşturulma: {createdAt}",
  "@olusturulmaAppformattersDateshortFormat": { "placeholders": { "createdAt": {} } },
  "aktif": "Aktif",
  "aktifOlanCuzdanSilinemez": "• Aktif olan cüzdan silinemez. Silmek için önce başka bir cüzdanı aktif yapmalısınız.",
  "cuzdanlarinizaAitBorcAlacak": "• Cüzdanlarınıza ait Borç, Alacak ve Birikim tutarlarını düzenle sayfasından manuel olarak yönetebilirsiniz.",
  "msgIncorrectPinRemainingTries": "Hatalı PIN. Kalan deneme: {newAttempts}",
  "@msgIncorrectPinRemainingTries": { "placeholders": { "newAttempts": {} } },
  "msgPINVerificationFailedE": "PIN doğrulama başarısız: {error}",
  "@msgPINVerificationFailedE": { "placeholders": { "error": {} } },
  "msgCreateAPinFirst": "Önce bir PIN oluşturun",
  "msgBiometricAuthenticationIsNot": "Biyometrik kimlik doğrulama desteklenmiyor",
  "msgBiometricAuthenticationFailed": "Biyometrik kimlik doğrulama başarısız",
  "msgBiometricLoginEnabled": "Biyometrik giriş etkinleştirildi",
  "msgBiometricLoginDisabled": "Biyometrik giriş devre dışı bırakıldı",
  "msgPINAlreadyExistsUse": "PIN zaten mevcut, bunun yerine PIN değiştirmeyi kullanın",
  "msgPINsDoNotMatch": "PIN'ler eşleşmiyor",
  "msgPINSavedSuccessfully": "PIN başarıyla kaydedildi",
  "msgNewPinValuesDo": "Yeni PIN değerleri eşleşmiyor",
  "msgCurrentPinIsIncorrect": "Mevcut PIN hatalı",
  "msgPINUpdatedSuccessfully": "PIN başarıyla güncellendi",
  "msgPINRemoved": "PIN kaldırıldı",
  "msgPINOrBiometricLogin": "PIN veya biyometrik giriş arka plan kilidi için gereklidir",
  "msgBackgroundLockAndPrivacy": "Arka plan kilidi ve Ekran Koruması etkinleştirildi",
  "unifiedFeaturesDemo": "Birleşik Özellikler Demosu",
  "sharedFeatures": "Paylaşılan Özellikler",
  "tarihSec": "Tarih Seç",
  "tarihAraligi": "Tarih Aralığı",
  "dialog": "Dialog",
  "metinGiris": "Metin Giriş",
  "yukle": "Yükle",
  "butonGalerisi": "Buton Galerisi",
  "basarili": "Başarılı",
  "hata": "Hata",
  "yuklemeButonu": "Yükleme Butonu",
  "onayDialog": "Onay Dialog",
  "internetBaglantisiAktif": "İnternet bağlantısı aktif",
  "internetBaglantisiYok": "İnternet bağlantısı yok",
  "baglantiKontrolEdiliyor": "Bağlantı kontrol ediliyor...",
  "taksit1": "1 taksit",
  "taksit2": "2 taksit",
  "tamaminiOde": "Tamamını öde"
}
```

## 3. Hardcoded Stringler — Dosya Dosya

> Sütun açıklamaları: **Ş** = aynı string başka dosyada da kullanıldığı için key paylaşılıyor | **⚠️P** = Dart interpolation içeriyor (parametreli ARB) | **🇬🇧** = İngilizce string

### `lib/features/investments/presentation/widgets/contribute_sheet.dart`

| Satır | Widget | String | ARB Key | Not |
|------|--------|--------|---------|-----|
| 207 | `Text` | "${context.l10n.birikmisFormatmoneyInvCurrentvalue(formatMoney(inv.currentValue))}" | `contextLNBirikmisformatmoneyinvcurrentvalue` | ⚠️P |

### `packages/unified_flutter_features/lib/features/connection_monitor/connection_cubit.dart` ⚠️ *(BuildContext yok — özel yaklaşım)*

| Satır | Widget | String | ARB Key | Not |
|------|--------|--------|---------|-----|
| 54 | `message/content` | "${texts.checkFailedPrefix}: ${e.toString()}" | `msgTextsCheckfailedprefixETostring` | ⚠️P |

### `packages/unified_flutter_features/lib/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart` ⚠️ *(BuildContext yok — özel yaklaşım)*

| Satır | Widget | String | ARB Key | Not |
|------|--------|--------|---------|-----|
| 130 | `message/content` | "Incorrect PIN. Remaining tries: ${LocalAuthConstants.maxFailedAttempts - newAttempts}" | `msgIncorrectPinRemainingTries` | ⚠️P 🇬🇧 |
| 138 | `message/content` | "PIN verification failed: ${e.toString()}" | `msgPINVerificationFailedE` | ⚠️P 🇬🇧 |

### `packages/unified_flutter_features/lib/features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart` ⚠️ *(BuildContext yok — özel yaklaşım)*

| Satır | Widget | String | ARB Key | Not |
|------|--------|--------|---------|-----|
| 64 | `message/content` | "Create a PIN first" | `msgCreateAPinFirst` | 🇬🇧 |
| 72 | `message/content` | "Biometric authentication is not supported" | `msgBiometricAuthenticationIsNot` | 🇬🇧 |
| 83 | `message/content` | "Biometric authentication failed" | `msgBiometricAuthenticationFailed` | 🇬🇧 |
| 90 | `message/content` | "Biometric login enabled" | `msgBiometricLoginEnabled` | 🇬🇧 |
| 96 | `message/content` | "Biometric login disabled" | `msgBiometricLoginDisabled` | 🇬🇧 |
| 112 | `message/content` | "PIN already exists, use change PIN instead" | `msgPINAlreadyExistsUse` | 🇬🇧 |
| 117 | `message/content` | "PINs do not match" | `msgPINsDoNotMatch` | 🇬🇧 |
| 124 | `message/content` | "PIN saved successfully" | `msgPINSavedSuccessfully` | 🇬🇧 |
| 138 | `message/content` | "New PIN values do not match" | `msgNewPinValuesDo` | 🇬🇧 |
| 145 | `message/content` | "Current PIN is incorrect" | `msgCurrentPinIsIncorrect` | 🇬🇧 |
| 153 | `message/content` | "PIN updated successfully" | `msgPINUpdatedSuccessfully` | 🇬🇧 |
| 167 | `message/content` | "Current PIN is incorrect" | `msgCurrentPinIsIncorrect` | 🇬🇧 |
| 176 | `message/content` | "PIN removed" | `msgPINRemoved` | 🇬🇧 |
| 218 | `message/content` | "PIN or biometric login is required for background lock" | `msgPINOrBiometricLogin` | 🇬🇧 |
| 231 | `message/content` | "Background lock and Privacy Guard enabled" | `msgBackgroundLockAndPrivacy` | 🇬🇧 |

### `packages/unified_flutter_features/lib/main.dart`

| Satır | Widget | String | ARB Key | Not |
|------|--------|--------|---------|-----|
| 60 | `Text` | "Unified Features Demo" | `unifiedFeaturesDemo` | 🇬🇧 |
| 94 | `Text` | "Shared Features" | `sharedFeatures` | 🇬🇧 |
| 104 | `text:` | "Tarih Seç" | `tarihSec` |  |
| 109 | `text:` | "Tarih Aralığı" | `tarihAraligi` |  |
| 114 | `text:` | "Dialog" | `dialog` |  |
| 119 | `text:` | "Metin Giriş" | `metinGiris` |  |
| 124 | `text:` | "Yükle" | `yukle` |  |
| 143 | `Text` | "Buton Galerisi" | `butonGalerisi` |  |
| 154 | `text:` | "Başarılı" | `basarili` |  |
| 165 | `text:` | "Hata" | `hata` |  |
| 180 | `text:` | "Yükleme Butonu" | `yuklemeButonu` |  |
| 197 | `text:` | "Onay Dialog" | `onayDialog` |  |

## 4. AI Görevi

> **Hedef:** `flutter gen-l10n` (.arb dosyaları)  
> **Ana dil:** Türkçe (`tr`) → **Hedef dil:** İngilizce (`en`)

### Adım 1 — `lib/l10n/app_tr.arb` oluştur

Her key **bir kez** yer alıyor. Aynı string birden fazla dosyada geçse de ARB'de tekrar etmez.

> **Not:** `⚠️P` işaretli entry'ler Dart interpolation içeriyor — ARB'de `{paramName}` formatına dönüştürüldü. `@key` metadata bloğunu **silme**.

> **Not:** `🇬🇧` işaretli entry değerleri şu an İngilizce. **Bu değerleri Türkçeye çevir** (örn: `"PIN saved successfully"` → `"PIN başarıyla kaydedildi"`).

```json
{
  "@@locale": "tr",
  "contextLNBirikmisformatmoneyinvcurrentvalue": "{currentValue}",
  "@contextLNBirikmisformatmoneyinvcurrentvalue": { "placeholders": { "currentValue": {} } },
  "msgTextsCheckfailedprefixETostring": "{checkFailedPrefix}: {error}",
  "@msgTextsCheckfailedprefixETostring": { "placeholders": { "checkFailedPrefix": {}, "error": {} } },
  "msgIncorrectPinRemainingTries": "<TÜRKÇEYE ÇEVİR: Incorrect PIN. Remaining tries: {newAttempts}>",
  "@msgIncorrectPinRemainingTries": { "placeholders": { "newAttempts": {} } },
  "msgPINVerificationFailedE": "<TÜRKÇEYE ÇEVİR: PIN verification failed: {error}>",
  "@msgPINVerificationFailedE": { "placeholders": { "error": {} } },
  "msgCreateAPinFirst": "<TÜRKÇEYE ÇEVİR: Create a PIN first>",
  "msgBiometricAuthenticationIsNot": "<TÜRKÇEYE ÇEVİR: Biometric authentication is not supported>",
  "msgBiometricAuthenticationFailed": "<TÜRKÇEYE ÇEVİR: Biometric authentication failed>",
  "msgBiometricLoginEnabled": "<TÜRKÇEYE ÇEVİR: Biometric login enabled>",
  "msgBiometricLoginDisabled": "<TÜRKÇEYE ÇEVİR: Biometric login disabled>",
  "msgPINAlreadyExistsUse": "<TÜRKÇEYE ÇEVİR: PIN already exists, use change PIN instead>",
  "msgPINsDoNotMatch": "<TÜRKÇEYE ÇEVİR: PINs do not match>",
  "msgPINSavedSuccessfully": "<TÜRKÇEYE ÇEVİR: PIN saved successfully>",
  "msgNewPinValuesDo": "<TÜRKÇEYE ÇEVİR: New PIN values do not match>",
  "msgCurrentPinIsIncorrect": "<TÜRKÇEYE ÇEVİR: Current PIN is incorrect>",
  "msgPINUpdatedSuccessfully": "<TÜRKÇEYE ÇEVİR: PIN updated successfully>",
  "msgPINRemoved": "<TÜRKÇEYE ÇEVİR: PIN removed>",
  "msgPINOrBiometricLogin": "<TÜRKÇEYE ÇEVİR: PIN or biometric login is required for background lock>",
  "msgBackgroundLockAndPrivacy": "<TÜRKÇEYE ÇEVİR: Background lock and Privacy Guard enabled>",
  "unifiedFeaturesDemo": "<TÜRKÇEYE ÇEVİR: Unified Features Demo>",
  "sharedFeatures": "<TÜRKÇEYE ÇEVİR: Shared Features>",
  "tarihSec": "Tarih Seç",
  "tarihAraligi": "Tarih Aralığı",
  "dialog": "Dialog",
  "metinGiris": "Metin Giriş",
  "yukle": "Yükle",
  "butonGalerisi": "Buton Galerisi",
  "basarili": "Başarılı",
  "hata": "Hata",
  "yuklemeButonu": "Yükleme Butonu",
  "onayDialog": "Onay Dialog",
}
```

### Adım 2 — `lib/l10n/app_en.arb` oluştur

Aynı key'lerle İngilizce değerleri yaz.  
- 🇬🇧 işaretli entry'lerin değeri zaten İngilizce; **orijinal değeri** koy (`<TÜRKÇEYE ÇEVİR:...>` olmadan).  
- Diğer (Türkçe) entry'leri İngilizce'ye çevir.  
- `{param}` placeholder'larını **koru**, sadece etrafındaki metni çevir.

```json
{
  "@@locale": "en",
  "contextLNBirikmisformatmoneyinvcurrentvalue": "<ÇEVİR: {currentValue}>",
  "@contextLNBirikmisformatmoneyinvcurrentvalue": { "placeholders": { "currentValue": {} } },
  "msgTextsCheckfailedprefixETostring": "<ÇEVİR: {checkFailedPrefix}: {error}>",
  "@msgTextsCheckfailedprefixETostring": { "placeholders": { "checkFailedPrefix": {}, "error": {} } },
  "msgIncorrectPinRemainingTries": "Incorrect PIN. Remaining tries: {newAttempts}",
  "@msgIncorrectPinRemainingTries": { "placeholders": { "newAttempts": {} } },
  "msgPINVerificationFailedE": "PIN verification failed: {error}",
  "@msgPINVerificationFailedE": { "placeholders": { "error": {} } },
  "msgCreateAPinFirst": "Create a PIN first",
  "msgBiometricAuthenticationIsNot": "Biometric authentication is not supported",
  "msgBiometricAuthenticationFailed": "Biometric authentication failed",
  "msgBiometricLoginEnabled": "Biometric login enabled",
  "msgBiometricLoginDisabled": "Biometric login disabled",
  "msgPINAlreadyExistsUse": "PIN already exists, use change PIN instead",
  "msgPINsDoNotMatch": "PINs do not match",
  "msgPINSavedSuccessfully": "PIN saved successfully",
  "msgNewPinValuesDo": "New PIN values do not match",
  "msgCurrentPinIsIncorrect": "Current PIN is incorrect",
  "msgPINUpdatedSuccessfully": "PIN updated successfully",
  "msgPINRemoved": "PIN removed",
  "msgPINOrBiometricLogin": "PIN or biometric login is required for background lock",
  "msgBackgroundLockAndPrivacy": "Background lock and Privacy Guard enabled",
  "unifiedFeaturesDemo": "Unified Features Demo",
  "sharedFeatures": "Shared Features",
  "tarihSec": "<ÇEVİR>",
  "tarihAraligi": "<ÇEVİR>",
  "dialog": "<ÇEVİR>",
  "metinGiris": "<ÇEVİR>",
  "yukle": "<ÇEVİR>",
  "butonGalerisi": "<ÇEVİR>",
  "basarili": "<ÇEVİR>",
  "hata": "<ÇEVİR>",
  "yuklemeButonu": "<ÇEVİR>",
  "onayDialog": "<ÇEVİR>",
}
```

### Adım 3 — Dart Dosyalarındaki String'leri Değiştir

Her widget dosyasının başına gerekirse şu import'u ekle:

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

**`lib/features/investments/presentation/widgets/contribute_sheet.dart`**

- Satır 207: `"${context.l10n.birikmisFormatmoneyInvCurrentvalue(formatMoney(inv.currentValue))}"` → `AppLocalizations.of(context)!.contextLNBirikmisformatmoneyinvcurrentvalue(currentValue: currentValue)`

**`packages/unified_flutter_features/lib/features/connection_monitor/connection_cubit.dart`** ⚠️ **(BuildContext olmayan dosya — aşağıdaki notu oku)**

- Satır 54: `"${texts.checkFailedPrefix}: ${e.toString()}"` → `AppLocalizations.of(context)!.msgTextsCheckfailedprefixETostring(checkFailedPrefix: checkFailedPrefix, error: error)`

**`packages/unified_flutter_features/lib/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart`** ⚠️ **(BuildContext olmayan dosya — aşağıdaki notu oku)**

- Satır 130: `"Incorrect PIN. Remaining tries: ${LocalAuthConstants.maxFailedAttempts - newAttempts}"` → `AppLocalizations.of(context)!.msgIncorrectPinRemainingTries(newAttempts: newAttempts)`
- Satır 138: `"PIN verification failed: ${e.toString()}"` → `AppLocalizations.of(context)!.msgPINVerificationFailedE(error: error)`

**`packages/unified_flutter_features/lib/features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart`** ⚠️ **(BuildContext olmayan dosya — aşağıdaki notu oku)**

- Satır 64: `"Create a PIN first"` → `AppLocalizations.of(context)!.msgCreateAPinFirst`
- Satır 72: `"Biometric authentication is not supported"` → `AppLocalizations.of(context)!.msgBiometricAuthenticationIsNot`
- Satır 83: `"Biometric authentication failed"` → `AppLocalizations.of(context)!.msgBiometricAuthenticationFailed`
- Satır 90: `"Biometric login enabled"` → `AppLocalizations.of(context)!.msgBiometricLoginEnabled`
- Satır 96: `"Biometric login disabled"` → `AppLocalizations.of(context)!.msgBiometricLoginDisabled`
- Satır 112: `"PIN already exists, use change PIN instead"` → `AppLocalizations.of(context)!.msgPINAlreadyExistsUse`
- Satır 117: `"PINs do not match"` → `AppLocalizations.of(context)!.msgPINsDoNotMatch`
- Satır 124: `"PIN saved successfully"` → `AppLocalizations.of(context)!.msgPINSavedSuccessfully`
- Satır 138: `"New PIN values do not match"` → `AppLocalizations.of(context)!.msgNewPinValuesDo`
- Satır 145: `"Current PIN is incorrect"` → `AppLocalizations.of(context)!.msgCurrentPinIsIncorrect`
- Satır 153: `"PIN updated successfully"` → `AppLocalizations.of(context)!.msgPINUpdatedSuccessfully`
- Satır 167: `"Current PIN is incorrect"` → `AppLocalizations.of(context)!.msgCurrentPinIsIncorrect`
- Satır 176: `"PIN removed"` → `AppLocalizations.of(context)!.msgPINRemoved`
- Satır 218: `"PIN or biometric login is required for background lock"` → `AppLocalizations.of(context)!.msgPINOrBiometricLogin`
- Satır 231: `"Background lock and Privacy Guard enabled"` → `AppLocalizations.of(context)!.msgBackgroundLockAndPrivacy`

**`packages/unified_flutter_features/lib/main.dart`**

- Satır 60: `"Unified Features Demo"` → `AppLocalizations.of(context)!.unifiedFeaturesDemo`
- Satır 94: `"Shared Features"` → `AppLocalizations.of(context)!.sharedFeatures`
- Satır 104: `"Tarih Seç"` → `AppLocalizations.of(context)!.tarihSec`
- Satır 109: `"Tarih Aralığı"` → `AppLocalizations.of(context)!.tarihAraligi`
- Satır 114: `"Dialog"` → `AppLocalizations.of(context)!.dialog`
- Satır 119: `"Metin Giriş"` → `AppLocalizations.of(context)!.metinGiris`
- Satır 124: `"Yükle"` → `AppLocalizations.of(context)!.yukle`
- Satır 143: `"Buton Galerisi"` → `AppLocalizations.of(context)!.butonGalerisi`
- Satır 154: `"Başarılı"` → `AppLocalizations.of(context)!.basarili`
- Satır 165: `"Hata"` → `AppLocalizations.of(context)!.hata`
- Satır 180: `"Yükleme Butonu"` → `AppLocalizations.of(context)!.yuklemeButonu`
- Satır 197: `"Onay Dialog"` → `AppLocalizations.of(context)!.onayDialog`

#### ⚠️ BuildContext Olmayan Dosyalar İçin Yaklaşım

Aşağıdaki dosyalar BLoC/Service gibi katmanlarda olduğu için doğrudan `AppLocalizations.of(context)` kullanamaz:

- `packages/unified_flutter_features/lib/features/connection_monitor/connection_cubit.dart`
- `packages/unified_flutter_features/lib/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart`
- `packages/unified_flutter_features/lib/features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart`

**Önerilen çözüm:** Bu dosyalardaki string'leri doğrudan ARB'ye ekleme. Bunun yerine:
1. UI katmanında (widget/page) string'i çevir: `AppLocalizations.of(context)!.msgXxx`
2. Çevrilmiş string'i BLoC event/state'ine parametre olarak geç.
3. BLoC içindeki sabit string'i kaldır, UI'dan gelen parametreyi kullan.

### Adım 4 — `pubspec.yaml` Güncelle

Eğer eksikse aşağıdaki bağımlılıkları ekle:

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

Proje kök dizinine `l10n.yaml` oluştur:

```yaml
arb-dir: lib/l10n
template-arb-file: app_tr.arb
output-localization-file: app_localizations.dart
```

### Adım 5 — `main.dart` Güncelle

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('tr'),
    Locale('en'),
  ],
);
```

### Adım 6 — Localization Kodunu Üret

```bash
flutter pub get && flutter gen-l10n
```

## 5. Kontrol Listesi

- [ ] `lib/l10n/app_tr.arb` oluşturuldu (30 benzersiz key)
- [ ] `lib/l10n/app_en.arb` oluşturuldu (30 benzersiz key)
- [ ] 5 dosyadaki tüm occurrence'lar değiştirildi (31 adet)
- [ ] 4 parametreli string ARB placeholder'larıyla eklendi
- [ ] 3 non-widget dosya için UI→BLoC parametre geçişi yapıldı
- [ ] `pubspec.yaml` güncellendi
- [ ] `l10n.yaml` oluşturuldu
- [ ] `main.dart` güncellendi
- [ ] `flutter gen-l10n` başarıyla çalıştırıldı
- [ ] Uygulama Türkçe ve İngilizce'de test edildi

---
_Bu dosya `Flutter Localizasyon Tarayici.py` tarafından 2026-06-13 tarihinde otomatik üretilmiştir._