import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfStatementParser (strateji seçimi)', () {
    final parser = PdfStatementParser();

    test('Akbank başlığı → AkbankPdfParser seçilir (boş açıklama yedeği doğrular)', () {
      const text = 'AKBANK T.A.Ş. HESAP ÖZETİ\n25/03/2026 100.00 200.00\n';
      final result = parser.parseText(text);
      expect(result.drafts.single.description, 'Akbank İşlemi');
    });

    test('Garanti başlığı → GarantiPdfParser seçilir', () {
      const text = 'GARANTİ BBVA HESAP ÖZETİ\n25/03/2026 100.00 200.00\n';
      final result = parser.parseText(text);
      expect(result.drafts.single.description, 'Garanti İşlemi');
    });

    test('Ziraat başlığı → ZiraatPdfParser seçilir', () {
      const text = 'ZİRAAT BANKASI HESAP ÖZETİ\n25/03/2026 100.00 200.00\n';
      final result = parser.parseText(text);
      expect(result.drafts.single.description, 'Ziraat İşlemi');
    });

    test('bilinmeyen banka → DefaultHeuristicPdfParser yedeğine düşer', () {
      const text = 'BİLİNMEYEN BANKA A.Ş. HESAP ÖZETİ\n25/03/2026 100.00 200.00\n';
      final result = parser.parseText(text);
      expect(result.drafts.single.description, 'İşlem');
    });

    test(
        'REGRESYON: Garanti ekstresinde gövdede geçen "Akbank" (karşı taraf '
        'bankası) yanlış stratejiyi tetiklemez', () {
      // Gerçek senaryo: ekstre GARANTİ'ye ait ama bir EFT açıklamasında karşı
      // tarafın bankası "Akbank" olarak geçiyor. Tüm-belge alt-dize arasaydı
      // bu satır Akbank stratejisini (yanlışlıkla) tetiklerdi çünkü Akbank
      // stratejiler listesinde Garanti'den önce denenir. canParse artık
      // yalnız başlığa baktığı için gövdedeki banka adı etkisiz olmalı.
      final buffer = StringBuffer('GARANTİ BBVA HESAP ÖZETİ\n');
      for (var i = 0; i < 25; i++) {
        buffer.writeln('dolgu satırı $i');
      }
      buffer.writeln(
          '25/03/2026 FEFT Transfer - Alıcı Akbank T.A.Ş. Şubesi 100.00 200.00');

      final result = parser.parseText(buffer.toString());
      expect(result.drafts.single.description, contains('Alıcı Akbank T.A.Ş.'));
      // Akbank stratejisi seçilseydi (yanlış), boş-açıklama yedeği hiç
      // tetiklenmezdi zaten (açıklama dolu) — asıl kanıt: aynı satırı doğrudan
      // AkbankPdfParser'a değil GarantiPdfParser'a özgü davranışla işlemiş
      // olması. Boş açıklamalı ikinci satırla bunu netleştiriyoruz:
      final buffer2 = StringBuffer('GARANTİ BBVA HESAP ÖZETİ\n');
      for (var i = 0; i < 25; i++) {
        buffer2.writeln('dolgu satırı $i');
      }
      buffer2
        ..writeln('25/03/2026 FEFT Transfer - Alıcı Akbank T.A.Ş. 100.00 200.00')
        ..writeln('26/03/2026 50.00 250.00'); // açıklaması boş kalacak satır

      final result2 = parser.parseText(buffer2.toString());
      expect(result2.drafts[1].description, 'Garanti İşlemi'); // Akbank İşlemi DEĞİL
    });

    test('boş metinde (DefaultHeuristic her zaman eşleşir ama satır yok) boş taslak listesi döner', () {
      final result = parser.parseText('');
      expect(result.drafts, isEmpty);
    });
  });
}
