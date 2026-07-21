import 'package:injectable/injectable.dart';

import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_amount_parser.dart';
import 'package:cunehat/features/bank_import/data/statement_date_parser.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';

class MappingResult {
  final List<ImportDraft> drafts;

  /// Tarih/tutar hücresi bozuk olduğu için atlanan (görünürde veri) satırlar.
  /// Preamble/boş satırlar bu sayıya DAHİL DEĞİL (sessizce yok sayılır).
  final int skippedRows;

  const MappingResult(this.drafts, this.skippedRows);
}

/// CSV/Excel ham tablosunu [ImportDraft]'lara çeviren eşleyici + otomatik
/// başlık/içerik sezgisiyle ilk [ColumnMapping] tahmini.
@lazySingleton
class ColumnMapper {
  static const _dateKw = ['tarih', 'date'];
  static const _descKw = [
    'aciklama',
    'description',
    'detay',
    'desc',
    'aciklamasi',
  ];
  static const _amountKw = ['tutar', 'amount', 'miktar'];
  static const _debitKw = ['borc', 'debit', 'cikan', 'harcama', 'gider'];
  static const _creditKw = ['alacak', 'credit', 'giren', 'yatan', 'gelir'];

  /// Başlık ve içerik sezgisiyle bir başlangıç eşlemesi üretir.
  ColumnMapping guess(RawTable table) {
    if (table.isEmpty) return const ColumnMapping(dateCol: -1, descCol: -1);

    final headerIdx = _findHeaderRow(table);
    final header = headerIdx >= 0 ? table.rows[headerIdx] : const <String>[];

    var dateCol = _findByKeywords(header, _dateKw);
    var descCol = _findByKeywords(header, _descKw);
    var amountCol = _findByKeywords(header, _amountKw);
    final debitCol = _findByKeywords(header, _debitKw);
    final creditCol = _findByKeywords(header, _creditKw);

    // İçerik tabanlı fallback (başlık yok ya da eksik).
    final dataRows = _dataRows(table, headerIdx);
    if (dateCol < 0) dateCol = _guessDateColumn(dataRows, table.columnCount);
    if (amountCol < 0 && debitCol < 0 && creditCol < 0) {
      amountCol = _guessMoneyColumn(dataRows, table.columnCount, dateCol);
    }
    if (descCol < 0) {
      descCol = _guessTextColumn(
          dataRows, table.columnCount, {dateCol, amountCol, debitCol, creditCol});
    }

    final useDebitCredit = debitCol >= 0 || creditCol >= 0;
    return ColumnMapping(
      dateCol: dateCol,
      descCol: descCol,
      amountCol: useDebitCredit ? null : (amountCol >= 0 ? amountCol : null),
      debitCol: useDebitCredit && debitCol >= 0 ? debitCol : null,
      creditCol: useDebitCredit && creditCol >= 0 ? creditCol : null,
      signMode:
          useDebitCredit ? SignMode.debitCreditColumns : SignMode.signedAmount,
      hasHeaderRow: headerIdx >= 0,
    );
  }

  /// Eşlemeyi uygular. Geçerli tarih+tutarı olan satırlar taslak olur; hiçbiri
  /// olmayan satırlar (preamble/boş) sessizce atlanır; biri geçerli diğeri
  /// bozuksa "atlanan" sayılır.
  MappingResult apply(RawTable table, ColumnMapping m) {
    final drafts = <ImportDraft>[];
    var skipped = 0;

    for (final row in table.rows) {
      String cell(int i) => (i >= 0 && i < row.length) ? row[i] : '';

      final date = parseStatementDate(cell(m.dateCol), m.dateFormat);
      final signed = _signedAmount(m, cell);
      final hasAmount = signed != null && signed != 0;

      if (date == null && !hasAmount) continue; // veri değil
      if (date == null || !hasAmount) {
        skipped++;
        continue;
      }

      drafts.add(ImportDraft(
        date: date,
        description: cell(m.descCol).trim(),
        amount: signed.abs(),
        type: signed < 0
            ? TransactionTypeModel.expense
            : TransactionTypeModel.income,
      ));
    }
    return MappingResult(drafts, skipped);
  }

  double? _signedAmount(ColumnMapping m, String Function(int) cell) {
    if (m.signMode == SignMode.signedAmount) {
      return parseSignedMoney(cell(m.amountCol ?? -1));
    }
    final debit =
        m.debitCol != null ? parseUnsignedMoney(cell(m.debitCol!)) : null;
    if (debit != null) return -debit;
    final credit =
        m.creditCol != null ? parseUnsignedMoney(cell(m.creditCol!)) : null;
    if (credit != null) return credit;
    return null;
  }

  // --- sezgi yardımcıları ---

  int _findHeaderRow(RawTable table) {
    final limit = table.rows.length < 15 ? table.rows.length : 15;
    for (var i = 0; i < limit; i++) {
      final row = table.rows[i];
      var hits = 0;
      for (final cell in row) {
        final n = _norm(cell);
        if (_dateKw.any(n.contains) ||
            _descKw.any(n.contains) ||
            _amountKw.any(n.contains) ||
            _debitKw.any(n.contains) ||
            _creditKw.any(n.contains)) {
          hits++;
        }
      }
      if (hits >= 2) return i;
    }
    return -1;
  }

  List<List<String>> _dataRows(RawTable table, int headerIdx) {
    return [
      for (var i = headerIdx + 1; i < table.rows.length; i++) table.rows[i],
    ];
  }

  int _findByKeywords(List<String> header, List<String> keywords) {
    for (var i = 0; i < header.length; i++) {
      final n = _norm(header[i]);
      if (keywords.any(n.contains)) return i;
    }
    return -1;
  }

  int _guessDateColumn(List<List<String>> rows, int cols) {
    var best = -1;
    var bestHits = 0;
    for (var c = 0; c < cols; c++) {
      var hits = 0;
      for (final r in rows) {
        if (c < r.length &&
            parseStatementDate(r[c], StatementDateFormat.auto) != null) {
          hits++;
        }
      }
      if (hits > bestHits) {
        bestHits = hits;
        best = c;
      }
    }
    return best;
  }

  int _guessMoneyColumn(List<List<String>> rows, int cols, int exclude) {
    var best = -1;
    var bestHits = 0;
    for (var c = 0; c < cols; c++) {
      if (c == exclude) continue;
      var hits = 0;
      for (final r in rows) {
        if (c < r.length && parseSignedMoney(r[c]) != null && _hasDigit(r[c])) {
          hits++;
        }
      }
      if (hits > bestHits) {
        bestHits = hits;
        best = c;
      }
    }
    return best;
  }

  int _guessTextColumn(List<List<String>> rows, int cols, Set<int> exclude) {
    var best = -1;
    var bestLen = 0.0;
    for (var c = 0; c < cols; c++) {
      if (exclude.contains(c)) continue;
      var total = 0;
      var n = 0;
      for (final r in rows) {
        if (c < r.length) {
          total += r[c].trim().length;
          n++;
        }
      }
      final avg = n == 0 ? 0.0 : total / n;
      if (avg > bestLen) {
        bestLen = avg;
        best = c;
      }
    }
    return best;
  }

  bool _hasDigit(String s) => RegExp(r'\d').hasMatch(s);

  /// Türkçe aksanları sadeleştirip küçük harfe çevirir (anahtar eşleşmesi için).
  String _norm(String s) => s
      .replaceAll('İ', 'I')
      .replaceAll('ı', 'i')
      .replaceAll('Ş', 'S')
      .replaceAll('ş', 's')
      .replaceAll('Ğ', 'G')
      .replaceAll('ğ', 'g')
      .replaceAll('Ü', 'U')
      .replaceAll('ü', 'u')
      .replaceAll('Ö', 'O')
      .replaceAll('ö', 'o')
      .replaceAll('Ç', 'C')
      .replaceAll('ç', 'c')
      .toLowerCase()
      .trim();
}
