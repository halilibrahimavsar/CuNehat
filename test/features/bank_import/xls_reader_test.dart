import 'dart:io';
import 'dart:typed_data';

import 'package:cunehat/features/bank_import/data/balance_reconciler.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/xls/biff8_reader.dart';
import 'package:cunehat/features/bank_import/data/xls/ole2_reader.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture BİLEREK LibreOffice tarafından üretildi, elle kurgulanmadı: kendi
/// yazıcımızı kullansaydık okuyucudaki bir yanlış anlama fixture'a da geçer ve
/// test yeşil kalırken gerçek dosyalar bozulurdu.
///
/// Bu dosya kullanıcının gerçek Garanti ekstresini TAMAMLAR (ikisi farklı
/// kod yollarını zorluyor):
///   gerçek dosya → normal FAT, `NUMBER` + `LABELSST`, metin tarihler
///   bu fixture   → mini-FAT (akış < 4096 B), `RK`, XF/FORMAT ile GERÇEK tarih
///                  hücresi (`yyyy\-mm\-dd`), kapta birden çok akış
const _fixture = 'test/fixtures/sample_statement_biff8.xls';

void main() {
  late Uint8List bytes;

  setUpAll(() async {
    bytes = await File(_fixture).readAsBytes();
  });

  group('Ole2File', () {
    test('mini-FAT üzerinden Workbook akışını çıkarır', () {
      final ole = Ole2File.parse(bytes);
      expect(ole.streamNames, contains('Workbook'));
      final wb = ole.readStream('Workbook');
      expect(wb, isNotNull);
      expect(wb!.length, greaterThan(500));
      // BIFF akışı BOF (0x0809) ile başlar.
      expect(wb[0] | (wb[1] << 8), 0x0809);
    });

    test('akış adı büyük/küçük harf duyarsız', () {
      expect(Ole2File.parse(bytes).readStream('workbook'), isNotNull);
    });

    test('olmayan akış null', () {
      expect(Ole2File.parse(bytes).readStream('Yok'), isNull);
    });

    test('OLE2 olmayan bayt dizisi reddedilir', () {
      expect(
        () => Ole2File.parse(Uint8List.fromList(List.filled(600, 0x41))),
        throwsA(isA<Ole2Exception>()),
      );
    });

    test('çok küçük dosya reddedilir', () {
      expect(
        () => Ole2File.parse(Uint8List.fromList([0xD0, 0xCF, 0x11, 0xE0])),
        throwsA(isA<Ole2Exception>()),
      );
    });
  });

  group('Biff8Reader', () {
    test('hücre ızgarası eksiksiz okunur', () {
      final sheet = Biff8Reader().readFirstSheet(bytes);
      expect(sheet.rows.length, 6);
      expect(sheet.unresolvedCells, 0);
      expect(sheet.truncated, isFalse);
      expect(sheet.isSuspect, isFalse);
    });

    test('SST Türkçe karakterleri bozmadan çözülür', () {
      final rows = Biff8Reader().readFirstSheet(bytes).rows;
      expect(rows[2], ['Tarih', 'Açıklama', 'Etiket', 'Tutar', 'Bakiye', 'Dekont No']);
      expect(rows[3][1], 'ATM PARA ÇEKME-ŞUBE');
      expect(rows[4][1], 'SATIŞ-BİM YUNUS EMRE');
      expect(rows[5][1], 'MAAŞ ÖDEMESİ');
    });

    test('GERÇEK tarih hücresi (XF→FORMAT) ISO metne çevrilir', () {
      // Bu sütun metin değil, tarih biçimli bir RK sayısı (Excel seri no).
      // Çözülmezse kullanıcı "45905" görürdü.
      final rows = Biff8Reader().readFirstSheet(bytes).rows;
      expect(rows[3][0], '2025-09-05');
      expect(rows[4][0], '2025-09-03');
      expect(rows[5][0], '2025-09-01');
    });

    test('sayılar kayan-nokta gürültüsü olmadan yazılır', () {
      final rows = Biff8Reader().readFirstSheet(bytes).rows;
      // 4412.28 ikili kayan noktada 4412.280000000001 olabilir; ham
      // `toString()` bunu yazsaydı parseMoneyToken değeri 1000 kat büyütürdü.
      expect(rows[4][4], '4412.28');
      expect(rows[3][3], '-4400'); // tam sayı: ".0" kuyruğu yok
      expect(rows[5][3], '23709.92');
    });

    test('BIFF olmayan içerik açık hata verir', () {
      expect(
        () => Biff8Reader()
            .readFirstSheet(Uint8List.fromList(List.filled(600, 0x41))),
        throwsA(isA<Ole2Exception>()),
      );
    });
  });

  group('boru hattı: .xls → RawTable → taslak', () {
    test('RawTableReader.readXls şüphesiz tablo döner', () async {
      final result = await RawTableReader().readXls(_fixture);
      expect(result.isSuspect, isFalse);
      expect(result.table.rows.length, 6);
      expect(result.table.columnCount, 6);
    });

    test('kolon eşleme künyeyi atlayıp başlığı bulur', () async {
      final result = await RawTableReader().readXls(_fixture);
      final m = ColumnMapper().guess(result.table);
      expect(m.headerRowIndex, 2);
      expect(m.dateCol, 0);
      expect(m.descCol, 1);
      expect(m.amountCol, 3);
      expect(m.balanceCol, 4);
    });

    test('taslaklar doğru tarih/tutar/yön ile çıkar, künye atlanmaz sayılmaz',
        () async {
      final result = await RawTableReader().readXls(_fixture);
      final mapper = ColumnMapper();
      final applied = mapper.apply(result.table, mapper.guess(result.table));

      expect(applied.drafts.length, 3);
      expect(applied.skippedRows, 0);

      expect(applied.drafts[0].date, DateTime(2025, 9, 5));
      expect(applied.drafts[0].amount, 4400.0);
      expect(applied.drafts[0].type, TransactionTypeModel.expense);

      expect(applied.drafts[2].date, DateTime(2025, 9, 1));
      expect(applied.drafts[2].amount, 23709.92);
      expect(applied.drafts[2].type, TransactionTypeModel.income);
    });

    test('Dekont No sütunu referans olarak yakalanır', () async {
      final result = await RawTableReader().readXls(_fixture);
      final mapper = ColumnMapper();
      final mapping = mapper.guess(result.table);
      expect(mapping.referenceCol, 5);

      final drafts = mapper.apply(result.table, mapping).drafts;
      expect(drafts.map((d) => d.reference), ['REF-001', 'REF-002', 'REF-003']);
    });

    test('bakiye sütunu mutabakatı tutar (işaretler bakiyeden doğrulanır)',
        () async {
      final result = await RawTableReader().readXls(_fixture);
      final mapper = ColumnMapper();
      final applied = mapper.apply(result.table, mapper.guess(result.table));
      expect(applied.reconciliation.status, ReconcileStatus.matched);
    });
  });
}
