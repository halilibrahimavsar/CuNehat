import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/statement_verification.dart';
import 'package:flutter_test/flutter_test.dart';

BalanceReconciliation _rec(List<double> signed, List<double?> balances) =>
    reconcileBalances(
      magnitudes: [for (final s in signed) s.abs()],
      balances: balances,
    );

StatementVerification _verify(
  List<double> signed,
  List<double?> balances, {
  String text = '',
  bool english = false,
}) =>
    verifyStatement(
      signedAmounts: signed,
      balances: balances,
      reconciliation: _rec(signed, balances),
      sourceText: text,
      englishGrouping: english,
    );

StatementCheck? _check(StatementVerification v, StatementCheckKind kind) {
  for (final c in v.checks) {
    if (c.kind == kind) return c;
  }
  return null;
}

void main() {
  group('bakiye zinciri', () {
    test('her satır tutarsa doğrulandı', () {
      final v = _verify([100, -40, -10], [1100, 1060, 1050]);
      expect(v.status, StatementVerificationStatus.verified);
      expect(_check(v, StatementCheckKind.balanceChain)?.detail, '2 / 2');
    });

    test('tek satır bile tutmazsa DOĞRULANAMADI', () {
      // 2. hareket bakiyeye göre -40 olmalı; 999 okunmuş.
      final v = _verify([100, -999, -10], [1100, 1060, 1050]);
      expect(v.status, StatementVerificationStatus.failed);
      expect(_check(v, StatementCheckKind.balanceChain)?.passed, isFalse);
    });

    test('bakiye sütunu yoksa bu kontrol hiç çalışmaz', () {
      final v = _verify([100, -40], [null, null]);
      expect(_check(v, StatementCheckKind.balanceChain), isNull);
      expect(v.status, StatementVerificationStatus.unavailable);
    });
  });

  group('beyan edilen kayıt sayısı', () {
    test('"85 kayıt bulunmuştur" ile satır sayısı karşılaştırılır', () {
      final v = _verify(
        [100, -40, -10],
        [1100, 1060, 1050],
        text: '25/07/2024 - 25/07/2026 aralığında 3 kayıt bulunmuştur.',
      );
      expect(_check(v, StatementCheckKind.recordCount)?.passed, isTrue);

      final bad = _verify(
        [100, -40, -10],
        [1100, 1060, 1050],
        text: 'aralığında 85 kayıt bulunmuştur.',
      );
      expect(_check(bad, StatementCheckKind.recordCount)?.passed, isFalse);
      expect(bad.status, StatementVerificationStatus.failed);
    });

    /// GERÇEK YANLIŞ-POZİTİF: gevşek bir `\s+` satır sonunu geçtiği için
    /// QNB ekstresindeki "…21/07/2026" ile bir sonraki satırın "Hareket
    /// Tipi"si birleşiyor, beyan **2026** okunuyor ve doğrulama sahte biçimde
    /// "TUTMADI" diyordu. Sahte bir başarısızlık, doğrulamanın tamamına olan
    /// güveni yok eder.
    test('tarih yılı sonraki satırın "Hareket" kelimesiyle birleşmez', () {
      final v = _verify(
        [100, -40, -10],
        [1100, 1060, 1050],
        text: 'Tarih Aralığı : 21/01/2026 - 21/07/2026\nHareket Tipi : Tümü',
      );
      expect(_check(v, StatementCheckKind.recordCount), isNull);
      expect(v.status, StatementVerificationStatus.verified);
    });
  });

  group('beyan edilen bakiyeler', () {
    /// GERÇEK TUZAK: `caseSensitive: false` tek başına yetmez — 'İ' (U+0130)
    /// küçük harfe çevrilince 'i' + birleşen nokta olur ve 'i' ile EŞLEŞMEZ.
    /// Bu yüzden gerçek QNB ekstresindeki "DEVREDEN BAKİYE" beyanı hiç
    /// bulunamıyordu.
    test('BÜYÜK HARFLİ "DEVREDEN BAKİYE" bulunur (Türkçe İ)', () {
      // İlk satır +100 ve bakiyesi 100 → devreden 0 olmalı.
      final v = _verify(
        [100, -40],
        [100, 60],
        text: 'DEVREDEN BAKİYE 0,00',
      );
      final c = _check(v, StatementCheckKind.openingBalance);
      expect(c, isNotNull);
      expect(c!.passed, isTrue);
      expect(c.detail, '0.00 / 0.00');
    });

    test('devreden bakiye tutmazsa doğrulanamadı', () {
      final v = _verify(
        [100, -40],
        [100, 60],
        text: 'DEVREDEN BAKİYE 500,00',
      );
      expect(_check(v, StatementCheckKind.openingBalance)?.passed, isFalse);
      expect(v.status, StatementVerificationStatus.failed);
    });

    test('kapanış bakiyesi azalan sıralı ekstrede İLK satırdan okunur', () {
      // Garanti düzeni: en yeni hareket en üstte.
      final v = _verify(
        [-40, 100],
        [60, 100],
        text: 'Kullanılabilir Bakiye   :   60,00 TL',
      );
      final c = _check(v, StatementCheckKind.closingBalance);
      expect(c?.passed, isTrue);
      expect(c?.detail, '60.00 / 60.00');
    });

    /// "Bakiye" aynı zamanda bir SÜTUN BAŞLIĞIDIR; iki nokta şartı olmadan
    /// başlığın ardındaki ilk hareketin bakiyesi "beyan" sanılırdı.
    test('iki noktasız "Bakiye" sütun başlığı beyan sayılmaz', () {
      final v = _verify(
        [100, -40],
        [1100, 1060],
        text: 'Tarih Açıklama Tutar Bakiye\n05.09.2025 SATIŞ -40,00 1.060,00',
      );
      expect(_check(v, StatementCheckKind.closingBalance), isNull);
    });
  });

  group('Borç/Alacak toplamları', () {
    test('sayfa altındaki toplamlar hesaplananla karşılaştırılır', () {
      // Ziraat ekstresi düzeni.
      final v = _verify(
        [-100, -50, 200],
        [900, 850, 1050],
        text: 'Borç:  -150,00\nAlacak:  200,00',
      );
      final c = _check(v, StatementCheckKind.totals);
      expect(c?.passed, isTrue);
      expect(v.status, StatementVerificationStatus.verified);
    });

    test('toplam tutmazsa doğrulanamadı', () {
      final v = _verify(
        [-100, -50, 200],
        [900, 850, 1050],
        text: 'Borç:  -999,00\nAlacak:  200,00',
      );
      expect(_check(v, StatementCheckKind.totals)?.passed, isFalse);
      expect(v.status, StatementVerificationStatus.failed);
    });
  });

  test('İngilizce biçimli belgede beyan da o biçimde okunur', () {
    final v = _verify(
      [10000, -9451],
      [10000, 549],
      text: 'DEVREDEN BAKİYE 0.00',
      english: true,
    );
    expect(_check(v, StatementCheckKind.openingBalance)?.passed, isTrue);
  });

  test('hiçbir kontrol çalıştırılamazsa sessiz kalınır', () {
    final v = _verify([100], [null], text: 'serbest metin');
    expect(v.status, StatementVerificationStatus.unavailable);
    expect(v.checks, isEmpty);
  });
}
