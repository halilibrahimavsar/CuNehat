import 'dart:io';

import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  final reader = RawTableReader();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('bank_csv_test_');
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Future<String> write(String name, String content) async {
    final f = File('${dir.path}/$name');
    await f.writeAsString(content);
    return f.path;
  }

  test('noktalı virgül ayraçlı CSV okunur (TR yerel export)', () async {
    final path = await write('a.csv',
        'Tarih;Açıklama;Tutar\n15.06.2026;MARKET;-150,00\n16.06.2026;MAAŞ;5.000,00\n');
    final table = await reader.readCsv(path);
    expect(table.columnCount, 3);
    expect(table.rows.first, ['Tarih', 'Açıklama', 'Tutar']);

    // Uçtan uca: guess + apply
    final mapper = ColumnMapper();
    final r = mapper.apply(table, mapper.guess(table));
    expect(r.drafts.length, 2);
    expect(r.drafts[0].amount, 150.0);
    expect(r.drafts[1].amount, 5000.0);
  });

  test('virgül ayraçlı CSV okunur', () async {
    final path =
        await write('b.csv', 'Date,Description,Amount\n2026-06-15,COFFEE,-45.50\n');
    final table = await reader.readCsv(path);
    expect(table.columnCount, 3);
    expect(table.rows.last, ['2026-06-15', 'COFFEE', '-45.50']);
  });

  test('boş dosya boş tablo', () async {
    final path = await write('c.csv', '');
    final table = await reader.readCsv(path);
    expect(table.isEmpty, isTrue);
  });
}
