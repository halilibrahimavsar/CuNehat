import 'package:cunehat/features/bank_import/data/statement_date_parser.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseStatementDate', () {
    test('auto: gg.aa.yyyy (TR)', () {
      expect(parseStatementDate('15.06.2026', StatementDateFormat.auto),
          DateTime(2026, 6, 15));
    });

    test('ISO yyyy-MM-dd', () {
      expect(parseStatementDate('2026-06-15', StatementDateFormat.auto),
          DateTime(2026, 6, 15));
    });

    test('auto: ilk grup >12 ise gün kabul edilir', () {
      expect(parseStatementDate('28/02/2026', StatementDateFormat.auto),
          DateTime(2026, 2, 28));
    });

    test('auto: ikinci grup >12 ise ay-önce', () {
      expect(parseStatementDate('05/13/2026', StatementDateFormat.auto),
          DateTime(2026, 5, 13));
    });

    test('monthFirst zorlanır', () {
      expect(parseStatementDate('02/03/2026', StatementDateFormat.monthFirst),
          DateTime(2026, 2, 3));
    });

    test('dayFirst zorlanır', () {
      expect(parseStatementDate('02/03/2026', StatementDateFormat.dayFirst),
          DateTime(2026, 3, 2));
    });

    test('2 haneli yıl 2000+ olur', () {
      expect(parseStatementDate('15.06.26', StatementDateFormat.auto),
          DateTime(2026, 6, 15));
    });

    test('taşan tarih reddedilir', () {
      expect(
          parseStatementDate('31.02.2026', StatementDateFormat.auto), isNull);
    });

    test('başlık/boş null', () {
      expect(parseStatementDate('Tarih', StatementDateFormat.auto), isNull);
      expect(parseStatementDate('', StatementDateFormat.auto), isNull);
    });

    // --- Gerçek Akbank CSV örneğinden çıkarılan regresyonlar ---

    test('REGRESYON: DB2 zaman damgası ISO önekinden okunur', () {
      // Eski sabitlenmemiş regex dizenin ORTASINDAKİ "26-07-16"yı yakalayıp
      // 2016-07-26 üretiyordu (sessiz veri bozulması).
      expect(
        parseStatementDate(
            '2026-07-16-10.53.10.816925', StatementDateFormat.auto),
        DateTime(2026, 7, 16),
      );
      expect(
        parseStatementDate(
            '2026-04-30-19.56.39.971948', StatementDateFormat.auto),
        DateTime(2026, 4, 30),
      );
    });

    test('ISO önekine saat eklenmiş biçimler', () {
      expect(parseStatementDate('2026-07-16 10:53', StatementDateFormat.auto),
          DateTime(2026, 7, 16));
      expect(
          parseStatementDate('2026-07-16T10:53:10Z', StatementDateFormat.auto),
          DateTime(2026, 7, 16));
    });

    test('gg.aa.yyyy sonrası saat kuyruğu', () {
      expect(
          parseStatementDate('16.07.2026 10:53:10', StatementDateFormat.auto),
          DateTime(2026, 7, 16));
    });

    test('ISO öneki zorlanan biçimden bağımsızdır', () {
      expect(parseStatementDate('2026-07-16', StatementDateFormat.monthFirst),
          DateTime(2026, 7, 16));
    });

    test('rakam dizisinin içindeki sahte tarih reddedilir', () {
      // IBAN / hesap numarası / referans no gibi uzun rakam dizileri.
      expect(
          parseStatementDate(
              'TR320004600817888000097812', StatementDateFormat.auto),
          isNull);
      expect(parseStatementDate('000000003598401', StatementDateFormat.auto),
          isNull);
    });

    test('geçersiz ISO öneki sessizce gün-önceye düşmez', () {
      expect(
          parseStatementDate('2026-13-45', StatementDateFormat.auto), isNull);
    });
  });

  group('resolveStatementDateFormat — sütun başına TEK karar', () {
    /// `auto` hücre bazında çözülürse aynı dosya satır satır farklı
    /// yorumlanır: ay-önce bir kaynakta `01/15/2026` doğru okunur ama bir
    /// sonraki satırdaki `01/05/2026` belirsiz olduğu için TR varsayılanıyla
    /// gün-önce sayılır — **aynı sütunda 15 Ocak ile 1 Mayıs yan yana** çıkar
    /// ve hiçbir uyarı verilmez. Karar sütuna aittir.
    test('sütunda ay-önce kanıtı varsa TÜM sütun ay-önce okunur', () {
      const column = ['01/15/2026', '01/05/2026', '02/28/2026'];
      final fmt = resolveStatementDateFormat(column);
      expect(fmt, StatementDateFormat.monthFirst);

      // Belirsiz hücre de aynı kararı izler.
      expect(parseStatementDate('01/05/2026', fmt), DateTime(2026, 1, 5));
    });

    test('gün-önce kanıtı varsa gün-önce', () {
      final fmt = resolveStatementDateFormat(['25/07/2026', '05/03/2026']);
      expect(fmt, StatementDateFormat.dayFirst);
      expect(parseStatementDate('05/03/2026', fmt), DateTime(2026, 3, 5));
    });

    test('hiç kanıt yoksa TR varsayılanı gün-önce', () {
      expect(resolveStatementDateFormat(['05/03/2026', '01/02/2026']),
          StatementDateFormat.dayFirst);
      expect(
          resolveStatementDateFormat(const []), StatementDateFormat.dayFirst);
    });

    test('iki yönde de kanıt varsa tutarlı davranılır (gün-önce)', () {
      // Bozuk/karışık kaynak: satırların yarısını sessizce ters çevirmektense
      // tek bir yorumda kalmak yeğdir; kullanıcı eşleme ekranından değiştirir.
      expect(resolveStatementDateFormat(['25/07/2026', '01/15/2026']),
          StatementDateFormat.dayFirst);
    });

    test('ISO hücreleri karara katılmaz (zaten belirsiz değil)', () {
      expect(
          resolveStatementDateFormat(
              ['2026-07-16-10.53.10.816925', '2026-07-13']),
          StatementDateFormat.dayFirst);
    });
  });
}
