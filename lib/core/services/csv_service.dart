import 'dart:io';
import 'dart:convert';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class CsvService {
  final _uuid = const Uuid();

  Future<void> exportTransactionsToCSV(
      List<TransactionEntity> transactions) async {
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
      text: 'İşlem Geçmişi (CSV)',
    ));
  }

  Future<List<TransactionEntity>?> importTransactionsFromCSV(
      String userId) async {
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
        for (int i = 1; i < fields.length; i++) {
          final row = fields[i];
          if (row.length < 6) continue;

          try {
            final title = row[0].toString();
            final tag = row[1].toString();
            final amount = double.tryParse(row[2].toString()) ?? 0.0;
            final date = DateTime.tryParse(row[3].toString()) ?? DateTime.now();
            final typeStr = row[4].toString();
            final isSystemStr = row[5].toString().toLowerCase();

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
            // ignore parsing error for a row
          }
        }

        return importedTransactions;
      } catch (e) {
        throw Exception("Dosya okunamadı veya format hatalı: $e");
      }
    }
    return null;
  }
}
