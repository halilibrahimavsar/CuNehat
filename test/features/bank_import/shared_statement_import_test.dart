import 'dart:io';

import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/pdf_rasterizer.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/data/statement_ocr_service.dart';
import 'package:cunehat/features/bank_import/domain/column_mapping.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockReader extends Mock implements RawTableReader {}

class _MockMapper extends Mock implements ColumnMapper {}

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockRasterizer extends Mock implements PdfRasterizer {}

class _MockOcr extends Mock implements StatementOcrService {}

class _MockGuesser extends Mock implements CategoryGuesser {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

/// `reset` silmeyi bilerek beklemeden tetikler (akışı yavaşlatmasın); testte
/// sınırlı süre bekleyip sonucu ölçüyoruz.
Future<bool> _waitUntilGone(File file) async {
  for (var i = 0; i < 50; i++) {
    if (!file.existsSync()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late _MockReader reader;
  late _MockMapper mapper;
  late _MockCategoryRepo categoryRepo;

  setUpAll(() => registerFallbackValue(const RawTable([])));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('cunehat_share_test');
    reader = _MockReader();
    mapper = _MockMapper();
    categoryRepo = _MockCategoryRepo();
    when(() => categoryRepo.getExpenseCategories()).thenAnswer((_) async => []);
    when(() => categoryRepo.getIncomeCategories()).thenAnswer((_) async => []);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  BankImportCubit build() => BankImportCubit(
        reader,
        mapper,
        _MockPdf(),
        _MockRasterizer(),
        _MockOcr(),
        _MockGuesser(),
        categoryRepo,
        _MockTxRepo(),
        _MockMetrics(),
        _MockNotifier(),
      );

  File writeShared(String name, String content) {
    final file = File('${tempDir.path}/$name')..writeAsStringSync(content);
    return file;
  }

  test('paylaşılan dosya, dosya seçiciyle AYNI ayrıştırma yolundan geçer',
      () async {
    final file = writeShared(
      'Hesap Özeti.csv',
      'Tarih;Açıklama;Tutar\n01.07.2026;MARKET;-100,00\n',
    );
    const table = RawTable([
      ['Tarih', 'Açıklama', 'Tutar'],
      ['01.07.2026', 'MARKET', '-100,00'],
    ]);
    const mapping = ColumnMapping(
      dateCol: 0,
      descCol: 1,
      amountCol: 2,
      headerRowIndex: 0,
    );
    when(() => reader.readCsv(any())).thenAnswer((_) async => table);
    when(() => mapper.guess(any())).thenReturn(mapping);

    final cubit = build();
    await cubit.parseFile(
      userId: 'u1',
      walletId: 'w1',
      path: file.path,
    );

    // Biçim tespiti + okuyucu + kolon eşleme adımı: paylaşım için ayrı bir
    // boru hattı YOK.
    verify(() => reader.readCsv(file.path)).called(1);
    expect(cubit.state, isA<BankImportMapping>());
    await cubit.close();
  });

  test('tanınmayan içerik paylaşıldığında açıklayıcı ekrana düşer', () async {
    final file = File('${tempDir.path}/foto.bin')
      ..writeAsBytesSync([0x00, 0x01, 0x02, 0x03, 0x00, 0xFF, 0xFE, 0x7F]);

    final cubit = build();
    await cubit.parseFile(userId: 'u1', walletId: 'w1', path: file.path);

    expect(cubit.state, isA<BankImportUnsupportedFile>());
    await cubit.close();
  });

  group('geçici kopya temizliği', () {
    test('reset kopyayı siler ve akış dosya seçiciye döner', () async {
      final file = writeShared('ekstre.csv', 'a;b\n');
      final cubit = build()..attachSharedFile(file.path);
      expect(cubit.sharedFilePath, file.path);

      cubit.reset();

      expect(cubit.sharedFilePath, isNull);
      expect(await _waitUntilGone(file), isTrue,
          reason: 'finansal belge önbellekte kalmamalı');
      await cubit.close();
    });

    test('cubit kapanınca kopya silinir (kullanıcı akıştan çıktı)', () async {
      final file = writeShared('ekstre.csv', 'a;b\n');
      final cubit = build()..attachSharedFile(file.path);

      await cubit.close();

      expect(file.existsSync(), isFalse);
    });

    test('dosya çoktan silinmişse hata fırlatmaz', () async {
      final file = writeShared('ekstre.csv', 'a;b\n')..deleteSync();
      final cubit = build()..attachSharedFile(file.path);

      await expectLater(cubit.close(), completes);
    });
  });
}
