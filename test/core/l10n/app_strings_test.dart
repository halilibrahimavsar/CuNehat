import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:cunehat/core/l10n/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// Bloc'ların widget ağacı dışından çözdüğü metinler (UX Tur 5 · T4).
///
/// ÖNCE: başarı/hata cümleleri koda gömülü Türkçeydi; uygulamayı İngilizce
/// kullanan kişi her kayıttan sonra Türkçe bildirim görüyordu.
void main() {
  final saved = Intl.defaultLocale;
  tearDown(() => Intl.defaultLocale = saved);

  test('dil atanmamışsa Türkçe (uygulamanın varsayılanı)', () {
    Intl.defaultLocale = null;
    expect(appStrings.blocMsgDebtAdded, 'Borç başarıyla eklendi.');
  });

  test('bölge ekli Türkçe (tr_TR) Türkçeye çözülür', () {
    Intl.defaultLocale = 'tr_TR';
    expect(appStrings.blocMsgTxAdded('Market'), 'Market başarıyla eklendi');
  });

  test('uygulama dili İngilizceyse mesaj da İngilizce', () {
    Intl.defaultLocale = 'en';
    expect(appStrings.blocMsgTxAdded('Groceries'), 'Groceries added');
    expect(appStrings.blocMsgDebtAdded, 'Debt added.');
  });

  test('bölge ekli İngilizce (en_US, en-GB) İngilizceye çözülür', () {
    Intl.defaultLocale = 'en_US';
    expect(appStrings.blocMsgDebtDeleted, 'Debt deleted.');
    Intl.defaultLocale = 'en-GB';
    expect(appStrings.blocMsgDebtDeleted, 'Debt deleted.');
  });

  test('desteklenmeyen dil Türkçeye düşer', () {
    Intl.defaultLocale = 'de_DE';
    expect(appStrings.blocMsgDebtDeleted, 'Borç silindi.');
  });

  test('dil değişince sonraki mesaj yeni dilde gelir (önbellek dil başına)',
      () {
    Intl.defaultLocale = 'tr';
    expect(appStrings.blocMsgReceivableAdded, 'Alacak başarıyla eklendi.');
    Intl.defaultLocale = 'en';
    expect(appStrings.blocMsgReceivableAdded, 'Receivable added.');
    Intl.defaultLocale = 'tr';
    expect(appStrings.blocMsgReceivableAdded, 'Alacak başarıyla eklendi.');
  });

  test('nakit uyarı kuyruğu baştaki boşluğu korur ve dile uyar', () {
    Intl.defaultLocale = 'tr';
    expect(CashCouplingMixin.cashWarning,
        ' (Uyarı: bakiye güncellenemedi, cüzdanı yenileyin.)');
    Intl.defaultLocale = 'en';
    expect(CashCouplingMixin.cashWarning, startsWith(' (Warning:'));
  });

  test('depo hata metinleri iki dilde de çözülür; Türkçe metin eskisiyle aynı',
      () {
    // UX Tur 2 · 9: depo/use case katmanındaki sabit Türkçe cümleler.
    Intl.defaultLocale = 'tr';
    expect(appStrings.failTxAdd('x'), 'İşlem eklenemedi: x');
    expect(appStrings.failBudgetDelete, 'Bütçe silinemedi.');
    expect(appStrings.failRecurringGetPending,
        'Bekleyen düzenli işlemler getirilemedi.');
    expect(appStrings.failCategoryDeleteNeedsTarget,
        'Taşınacak kategori seçilmeden silinemez');
    Intl.defaultLocale = 'en';
    expect(appStrings.failTxAdd('x'), 'Could not add the transaction: x');
    expect(appStrings.failBudgetDelete, 'Could not delete the budget.');
    expect(appStrings.failSymbolEmpty, 'The symbol cannot be empty');
  });
}
