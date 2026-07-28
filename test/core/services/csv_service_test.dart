import 'dart:convert';
import 'dart:io';
import 'package:cunehat/core/services/csv_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CsvService csvService;

  const MethodChannel pathChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel shareChannel =
      MethodChannel('dev.fluttercommunity.plus/share');
  const MethodChannel filePickerChannel =
      MethodChannel('miguelruivo.flutter.plugins.filepicker');

  final List<MethodCall> shareLog = [];
  final List<MethodCall> filePickerLog = [];
  dynamic filePickerResponse;

  setUp(() {
    csvService = CsvService();
    shareLog.clear();
    filePickerLog.clear();
    filePickerResponse = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
      if (methodCall.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (MethodCall methodCall) async {
      shareLog.add(methodCall);
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel,
            (MethodCall methodCall) async {
      filePickerLog.add(methodCall);
      return filePickerResponse;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel, null);
  });

  // REGRESYON: dışa aktarım BOM'suz UTF-8 yazıyordu; Windows Excel dosyayı
  // sistem kod sayfası sanıp Türkçe karakterleri bozuyordu (Şişli → Åžisli).
  group('CsvService.exportTransactionsToCSV — kodlama', () {
    final tx = TransactionEntity(
      id: 't1',
      userId: 'u1',
      walletId: 'w1',
      title: 'Şişli Bakkal — ÇĞİÖÜ',
      tag: 'Market',
      amount: 123.45,
      date: DateTime(2026, 7, 28),
      type: TransactionTypeModel.expense,
    );

    test('UTF-8 BOM ile yazılır ve Türkçe karakterler korunur', () async {
      await csvService.exportTransactionsToCSV([tx]);

      final file =
          File('${Directory.systemTemp.path}/transactions_export.csv');
      final bytes = await file.readAsBytes();

      expect(bytes.take(3).toList(), utf8Bom, reason: 'BOM eksik');
      // BOM'dan sonrası geçerli UTF-8 ve metin bozulmamış olmalı.
      expect(utf8.decode(bytes.skip(3).toList()), contains('Şişli Bakkal'));
      expect(utf8.decode(bytes.skip(3).toList()), contains('ÇĞİÖÜ'));
    });

    test('kendi içe aktarımımız BOM\'a takılmaz (round-trip)', () async {
      await csvService.exportTransactionsToCSV([tx]);
      final path = '${Directory.systemTemp.path}/transactions_export.csv';

      filePickerResponse = [
        {
          'path': path,
          'name': 'transactions_export.csv',
          'size': await File(path).length(),
          'bytes': null,
        }
      ];
      final result = await csvService.importTransactionsFromCSV('u1');

      expect(result, isNotNull);
      expect(result!.skippedRows, 0);
      expect(result.transactions.single.title, 'Şişli Bakkal — ÇĞİÖÜ');
      expect(result.transactions.single.amount, 123.45);
    });
  });

  group('CsvService.parseDate', () {
    test('parses ISO 8601 date', () {
      expect(CsvService.parseDate('2024-03-15'), equals(DateTime(2024, 3, 15)));
    });

    test('parses ISO 8601 with time', () {
      expect(CsvService.parseDate('2024-03-15T10:30:00.000'),
          equals(DateTime(2024, 3, 15, 10, 30)));
    });

    test('parses Turkish dot format (dd.MM.yyyy)', () {
      expect(CsvService.parseDate('31.01.2024'), equals(DateTime(2024, 1, 31)));
    });

    test('parses European slash format (dd/MM/yyyy)', () {
      expect(CsvService.parseDate('15/03/2024'), equals(DateTime(2024, 3, 15)));
    });

    test('parses dash format (dd-MM-yyyy)', () {
      expect(CsvService.parseDate('15-03-2024'), equals(DateTime(2024, 3, 15)));
    });

    test('returns null for invalid date string', () {
      expect(CsvService.parseDate('not-a-date'), isNull);
    });

    test('returns null for impossible date (31.02.2024)', () {
      expect(CsvService.parseDate('31.02.2024'), isNull);
    });

    test('returns null for empty string', () {
      expect(CsvService.parseDate(''), isNull);
    });

    test('returns null for invalid month', () {
      expect(CsvService.parseDate('01.13.2024'), isNull);
    });

    test('trims whitespace before parsing', () {
      expect(CsvService.parseDate('  15.03.2024  '),
          equals(DateTime(2024, 3, 15)));
    });

    test('parses single-digit day and month', () {
      expect(CsvService.parseDate('1.1.2024'), equals(DateTime(2024, 1, 1)));
    });

    test('parses single-digit day, leading-zero month', () {
      expect(CsvService.parseDate('1.01.2024'), equals(DateTime(2024, 1, 1)));
    });
  });

  group('CsvImportResult', () {
    test('creates result with transactions and skipped rows', () {
      final result = CsvImportResult([], 5);
      expect(result.transactions, isEmpty);
      expect(result.skippedRows, 5);
    });

    test('stores provided transactions', () {
      const result = CsvImportResult([], 0);
      expect(result.transactions, isEmpty);
      expect(result.skippedRows, 0);
    });
  });

  group('CsvService.exportTransactionsToCSV', () {
    test('exports transactions and triggers share', () async {
      final transactions = [
        TransactionEntity(
          id: 't1',
          userId: 'u1',
          walletId: 'w1',
          title: 'Salary',
          tag: 'Work',
          amount: 5000.0,
          date: DateTime(2024, 1, 1),
          type: TransactionTypeModel.income,
          isSystem: false,
        ),
        TransactionEntity(
          id: 't2',
          userId: 'u1',
          walletId: 'w1',
          title: 'Rent',
          tag: 'Home',
          amount: 1500.0,
          date: DateTime(2024, 1, 2),
          type: TransactionTypeModel.expense,
          isSystem: true,
        ),
      ];

      await csvService.exportTransactionsToCSV(transactions,
          shareText: 'My Transactions');

      // Verify that share method channel was called
      expect(shareLog, isNotEmpty);
      expect(shareLog.first.method, equals('share'));

      // Let's verify that the file was created and contains correct CSV content
      final tempDirPath = Directory.systemTemp.path;
      final file = File('$tempDirPath/transactions_export.csv');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      expect(content, contains('Title,Tag,Amount,Date,Type,IsSystem'));
      expect(content,
          contains('Salary,Work,5000.0,2024-01-01T00:00:00.000,income,false'));
      expect(content,
          contains('Rent,Home,1500.0,2024-01-02T00:00:00.000,expense,true'));

      // Clean up
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
  });

  group('CsvService.importTransactionsFromCSV', () {
    test('returns null if file picker is canceled', () async {
      filePickerResponse = null;

      final result = await csvService.importTransactionsFromCSV('u1');
      expect(result, isNull);
    });

    test('imports valid transactions and skips invalid rows', () async {
      final tempFile = File('${Directory.systemTemp.path}/test_import.csv');
      // "Rent" satırı IsSystem=true taşıyor: bu, kuplajlı bir işlemin geçmiş
      // export'undan gelmiş olabilir. İçe aktarım her zaman yeni bir cüzdana
      // yazdığından (borç/yatırım kaydı olmayan), bu sütuna güvenilmemeli.
      final csvContent = 'Title,Tag,Amount,Date,Type,IsSystem\r\n'
          'Salary,Work,5000,2024-01-01,income,false\r\n'
          'Rent,Home,1500,02/01/2024,expense,true\r\n'
          'InvalidAmt,Home,-500,2024-01-03,expense,false\r\n'
          'InvalidDate,Home,100,not-a-date,expense,false\r\n'
          'ShortRow,Home,100,2024-01-04\r\n';
      tempFile.writeAsStringSync(csvContent);

      filePickerResponse = [
        {
          'path': tempFile.path,
          'name': 'test_import.csv',
          'size': csvContent.length,
          'bytes': null,
        }
      ];

      final result = await csvService.importTransactionsFromCSV('u1');
      expect(result, isNotNull);
      expect(result!.transactions.length, 2);
      expect(result.skippedRows,
          3); // 1 negative amount, 1 invalid date, 1 short row

      final t1 = result.transactions[0];
      expect(t1.title, 'Salary');
      expect(t1.amount, 5000.0);
      expect(t1.type, TransactionTypeModel.income);
      expect(t1.isSystem, isFalse);

      final t2 = result.transactions[1];
      expect(t2.title, 'Rent');
      expect(t2.amount, 1500.0);
      expect(t2.type, TransactionTypeModel.expense);
      // CSV'de IsSystem=true yazsa bile içe aktarım bu değeri asla dikkate
      // almaz; aksi halde bu cüzdanda hiçbir kaynak kaydı olmayan kalıcı
      // kilitli hayalet bir işlem oluşurdu.
      expect(t2.isSystem, isFalse);

      // Clean up
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }
    });

    test('throws exception if reading file fails', () async {
      filePickerResponse = [
        {
          'path': '/invalid/path/nonexistent.csv',
          'name': 'nonexistent.csv',
          'size': 0,
          'bytes': null,
        }
      ];

      expect(
        () => csvService.importTransactionsFromCSV('u1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
