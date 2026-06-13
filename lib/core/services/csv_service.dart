import 'dart:io';
import 'dart:convert';
import 'package:cunehat/core/utils/amount_parser.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Import sonucu: geçerli işlemler + tarih/tutar hatası nedeniyle atlanan
/// satır sayısı (kullanıcıya raporlanır; sessiz veri bozulması yerine).
class CsvImportResult {
  final List<TransactionEntity> transactions;
  final int skippedRows;

  const CsvImportResult(this.transactions, this.skippedRows);
}

@lazySingleton
class CsvService {
  final _uuid = const Uuid();

  Future<void> exportTransactionsToCSV(List<TransactionEntity> transactions,
      {String? shareText}) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add(["Title", "Tag", "Amount", "Date", "Type", "IsSystem"]);

    for (var t in transactions) {
      rows.add([
        t.title,
        t.tag,
        t.amount.toString(),
        t.date.toIso8601String(),
        t.type.name,
        t.isSystem.toString(),
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/transactions_export.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(path)],
      text: shareText ?? 'İşlem Geçmişi (CSV)',
    ));
  }

  Future<CsvImportResult?> importTransactionsFromCSV(String userId) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      try {
        final input = File(result.files.single.path!).openRead();
        final fields = await input
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const CsvToListConverter())
            .toList();

        if (fields.isEmpty) return null;

        // Skip header
        List<TransactionEntity> importedTransactions = [];
        int skippedRows = 0;
        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length < 6) {
            skippedRows++;
            continue;
          }

          try {
            final title = row[0].toString();
            final tag = row[1].toString();
            final amount = row[2] is num
                ? (row[2] as num).toDouble()
                : parseAmount(row[2].toString());
            final date = _parseDate(row[3].toString());
            final typeStr = row[4].toString();
            final isSystemStr = row[5].toString().toLowerCase();

            // Tutar/tarih çözülemiyorsa satırı sessizce bugünün tarihiyle
            // veya 0 tutarla eklemek veri bozar; atla ve say.
            if (amount == null || amount <= 0 || date == null) {
              skippedRows++;
              continue;
            }

            final type = typeStr == 'income'
                ? TransactionTypeModel.income
                : TransactionTypeModel.expense;
            final isSystem = isSystemStr == 'true';

            importedTransactions.add(
              TransactionEntity(
                id: _uuid.v4(),
                userId: userId,
                walletId: '', // Bu daha sonra Cüzdan ID ile güncellenecek
                title: title,
                tag: tag,
                amount: amount,
                date: date,
                type: type,
                isSystem: isSystem,
              ),
            );
          } catch (e) {
            skippedRows++;
          }
        }

        return CsvImportResult(importedTransactions, skippedRows);
      } catch (e) {
        throw Exception("Dosya okunamadı veya format hatalı: $e");
      }
    }
    return null;
  }

  /// ISO 8601 (kendi export'umuz) ve yaygın TR/Avrupa biçimleri
  /// (31.01.2024, 31/01/2024, 31-01-2024).
  static DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) return iso;

    final match =
        RegExp(r'^(\d{1,2})[./-](\d{1,2})[./-](\d{4})$').firstMatch(trimmed);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    final date = DateTime(year, month, day);
    // 31.02.2024 gibi taşan tarihleri normalize edip kabul etme
    if (date.month != month || date.day != day) return null;
    return date;
  }
}
