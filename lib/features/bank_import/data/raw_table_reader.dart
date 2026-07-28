import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/data/statement_text_decoder.dart';
import 'package:cunehat/features/bank_import/data/xls/biff8_reader.dart';

/// Ham tablo: satır × hücre (hepsi String). Kolon eşleme bunun üstünde çalışır.
class RawTable {
  final List<List<String>> rows;
  const RawTable(this.rows);

  bool get isEmpty => rows.isEmpty;
  int get columnCount => rows.fold(0, (m, r) => r.length > m ? r.length : m);
}

/// `.xls` okumasının sonucu: tablo + bütünlük şüphesi.
class XlsReadResult {
  final RawTable table;
  final int unresolvedCells;
  final bool truncated;
  const XlsReadResult({
    required this.table,
    required this.unresolvedCells,
    required this.truncated,
  });

  bool get isSuspect => unresolvedCells > 0 || truncated;
}

/// Banka ekstresi dosyalarını ham tabloya çeviren okuyucu. CSV bu fazda;
/// Excel (.xlsx) Faz 2'de eklenir. PDF ayrı bir yol izler (satır-sezgisel).
///
/// Bilinmeyen banka biçimleri için toleranslı: ayraç ve kodlama sezilir;
/// preamble/başlık-dışı satırlar burada değil, kolon eşleme/ayrıştırma
/// katmanında (geçerli tarih/tutar yoksa) elenir.
@lazySingleton
class RawTableReader {
  /// .xlsx ekstresini ilk sayfadan ham tabloya çevirir. Hücre değerleri tipe
  /// göre düz metne indirgenir (tarih/tutar ayrıştırıcıya String gider).
  Future<RawTable> readExcel(String path) async {
    final bytes = await File(path).readAsBytes();
    final book = Excel.decodeBytes(bytes);
    if (book.tables.isEmpty) return const RawTable([]);
    final sheet = book.tables.values.first;

    final rows = <List<String>>[];
    for (final row in sheet.rows) {
      final cells = row.map(_cellString).toList();
      if (cells.any((c) => c.trim().isNotEmpty)) rows.add(cells);
    }
    return RawTable(rows);
  }

  /// Eski ikili `.xls` (OLE2/BIFF8) ekstresini ham tabloya çevirir. `excel`
  /// paketi bu biçimi okumaz; okuyucu `data/xls/` altında.
  ///
  /// Okunabildiği hâlde bütünlüğü şüpheliyse (çözülemeyen hücre / kırpık akış)
  /// tablo yine döner ama [XlsReadResult.warning] doldurulur — sessizce eksik
  /// veri sunmamak için.
  Future<XlsReadResult> readXls(String path) async {
    final bytes = await File(path).readAsBytes();
    final sheet = Biff8Reader().readFirstSheet(bytes);
    return XlsReadResult(
      table: RawTable(sheet.rows),
      unresolvedCells: sheet.unresolvedCells,
      truncated: sheet.truncated,
    );
  }

  String _cellString(Data? cell) {
    final v = cell?.value;
    return switch (v) {
      null => '',
      TextCellValue() => v.value.text ?? '',
      IntCellValue() => v.value.toString(),
      DoubleCellValue() => v.value.toString(),
      DateCellValue() => v.asDateTimeLocal().toIso8601String(),
      DateTimeCellValue() => v.asDateTimeLocal().toIso8601String(),
      _ => v.toString(),
    };
  }

  Future<RawTable> readCsv(String path) async {
    final bytes = await File(path).readAsBytes();
    // Satır sonlarını tek biçime indir; csv paketinin eol'ü aksi halde
    // '\n'-yalnız dosyalarda satırları bölmez (hepsini tek satır sanır).
    final text = decodeStatementBytes(bytes)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    if (text.trim().isEmpty) return const RawTable([]);

    final delimiter = _detectDelimiter(text);
    final rows = CsvToListConverter(
      fieldDelimiter: delimiter,
      eol: '\n',
      shouldParseNumbers:
          false, // hücreler String kalsın (tutarı biz ayrıştırırız)
      allowInvalid: true,
    ).convert(text);

    return RawTable(
      rows
          .map((r) => r.map((c) => (c ?? '').toString()).toList())
          .where((r) => r.any((c) => c.trim().isNotEmpty))
          .toList(),
    );
  }

  String _detectDelimiter(String text) {
    final sample = text.split('\n').take(15).join('\n');
    int count(String d) => sample.split(d).length - 1;
    final semicolon = count(';');
    final comma = count(',');
    final tab = count('\t');
    if (semicolon >= comma && semicolon >= tab && semicolon > 0) return ';';
    if (tab > comma && tab > 0) return '\t';
    return ',';
  }
}
