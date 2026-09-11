import 'dart:io';

import 'package:cunehat/core/services/system_activity_guard.dart';
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
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/wallet_category_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockRasterizer extends Mock implements PdfRasterizer {}

class _MockOcr extends Mock implements StatementOcrService {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockWalletCategories extends Mock implements WalletCategoryService {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

/// "Sütunları eşle" adımının ne zaman gösterildiğini GERÇEK okuyucu ve
/// eşleyiciyle, gerçek dosyalar üzerinden ölçer. Kategori/tekrar adımları bu
/// dosyanın konusu değil: açıklamalar sözlükte karşılığı olmayan kelimeler,
/// defter boş.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('cunehat_mapping_flow');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  BankImportCubit build() {
    final categoryRepo = _MockCategoryRepo();
    when(() => categoryRepo.getCategories(any())).thenAnswer((_) async => []);
    final walletCategories = _MockWalletCategories();
    when(() => walletCategories.categoriesFor(
          walletId: any(named: 'walletId'),
          isExpense: any(named: 'isExpense'),
          alwaysInclude: any(named: 'alwaysInclude'),
        )).thenAnswer((_) async => []);
    final txRepo = _MockTxRepo();
    when(() => txRepo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
        )).thenAnswer((_) async => const Right(<TransactionEntity>[]));
    final walletRepo = _MockWalletRepo();
    when(() => walletRepo.getWalletById(any())).thenAnswer((_) async => Right(
          WalletEntity(
            id: 'w1',
            userId: 'u1',
            name: 'Banka',
            balance: 0,
            debt: 0,
            credit: 0,
            investment: 0,
            colorHex: '0xFF000000',
            iconName: 'money',
            createdAt: DateTime(2026, 1, 1),
            openingBalance: 0,
          ),
        ));
    final metrics = _MockMetrics();
    when(() => metrics.walletRepository).thenReturn(walletRepo);

    return BankImportCubit(
      RawTableReader(),
      ColumnMapper(),
      _MockPdf(),
      _MockRasterizer(),
      _MockOcr(),
      CategoryGuesser(),
      categoryRepo,
      walletCategories,
      txRepo,
      metrics,
      _MockNotifier(),
      SystemActivityGuard(),
    );
  }

  Future<BankImportCubit> parse(String name, String content,
      {BankImportCubit? cubit}) async {
    final file = File('${dir.path}/$name')..writeAsStringSync(content);
    final c = cubit ?? build();
    await c.parseFile(userId: 'u1', walletId: 'w1', path: file.path);
    return c;
  }

  test('başlıkları tanınan, bakiyesi tutan dosya eşleme ekranını ATLAR',
      () async {
    final cubit = await parse(
      'akbank.csv',
      'Tarih;Açıklama;Tutar;Bakiye\n'
          '01.07.2026;ABC;-100,00;900,00\n'
          '02.07.2026;DEF;1.000,00;1.900,00\n'
          '03.07.2026;GHI;-500,00;1.400,00\n',
    );

    final state = cubit.state;
    expect(state, isA<BankImportReview>(),
        reason: 'soru sormaya gerek yok: sonuç zaten kanıtlı');
    final review = state as BankImportReview;
    expect(review.drafts, hasLength(3));
    expect(review.canRemap, isTrue);
    await cubit.close();
  });

  test(
      'REGRESYON: bakiye zinciri tutan dosyada aynı gün/tutar/açıklamalı iki '
      'satır İKİSİ DE eklenir', () async {
    // Gerçek Garanti ekstresindeki "KARACA OTOMAT 40,00" çiftinin kalıbı:
    // bakiye her satırda değiştiği için ikisi de gerçek harekettir.
    final cubit = await parse(
      'otomat.csv',
      'Tarih;Açıklama;Tutar;Bakiye\n'
          '01.07.2026;OTOMAT;-40,00;960,00\n'
          '01.07.2026;OTOMAT;-40,00;920,00\n'
          '02.07.2026;ABC;-10,00;910,00\n',
    );

    final drafts = (cubit.state as BankImportReview).drafts;
    expect(drafts.where((d) => d.isDuplicate), isEmpty);
    expect(drafts.every((d) => d.selected), isTrue);
    await cubit.close();
  });

  test('başlıksız dosyada eşleme ekranı açılır (canlı sonuçla)', () async {
    final cubit = await parse(
      'basliksiz.csv',
      '01.07.2026;ABC;-100,00\n'
          '02.07.2026;DEF;-200,00\n',
    );

    final state = cubit.state;
    expect(state, isA<BankImportMapping>());
    final a = (state as BankImportMapping).assessment;
    expect(a.result.drafts, hasLength(2), reason: 'tahmin yine de önizlenir');
    await cubit.close();
  });

  test('incelemeden "sütunları yeniden eşle" son eşlemeye döner', () async {
    final cubit = await parse(
      'akbank.csv',
      'Tarih;Açıklama;Tutar;Bakiye\n'
          '01.07.2026;ABC;-100,00;900,00\n'
          '02.07.2026;DEF;1.000,00;1.900,00\n',
    );
    expect(cubit.state, isA<BankImportReview>());

    cubit.remap();

    final state = cubit.state;
    expect(state, isA<BankImportMapping>());
    expect((state as BankImportMapping).mapping.amountCol, 2);
    await cubit.close();
  });

  group('kaydedilmiş eşleme', () {
    // Kullanıcı ilk dosyada tarih sırasını "ay-önce" diye onaylıyor
    // (03/04/2026 = 4 Mart). Başlık künyeden sonra, 2. indekste.
    const first = 'Hesap;X\n'
        'IBAN;Y\n'
        'Tarih;Açıklama;Tutar\n'
        '03/04/2026;ABC;-10,00\n'
        '05/04/2026;DEF;-20,00\n';

    Future<void> confirmFirst() async {
      final cubit = await parse('ilk.csv', first);
      final s = cubit.state as BankImportMapping;
      expect(s.assessment.ambiguousDateSample, isNotNull);
      cubit.updateMapping(
          s.mapping.copyWith(dateFormat: StatementDateFormat.monthFirst));
      await cubit.applyMapping();
      final review = cubit.state as BankImportReview;
      expect(review.drafts.first.date, DateTime(2026, 3, 4));
      await cubit.close();
    }

    test(
        'REGRESYON: künye bir satır KISALINCA ilk hareket düşmez '
        '(başlık satırı yeniden bulunur)', () async {
      await confirmFirst();

      // Aynı banka, bu kez künye tek satır: başlık 1. indekste. Eskiden
      // kayıtlı başlık indeksi (2) aynen uygulanıyor, ilk hareket "başlık"
      // sanılıp sessizce düşüyordu.
      final cubit = await parse(
        'ikinci.csv',
        'IBAN;Y\n'
            'Tarih;Açıklama;Tutar\n'
            '03/04/2026;ABC;-10,00\n'
            '07/04/2026;XYZ;-30,00\n'
            '09/04/2026;QQQ;-40,00\n',
      );

      final state = cubit.state;
      expect(state, isA<BankImportReview>(),
          reason: 'aynı başlık + kullanıcının önceki onayı → soru yok');
      final drafts = (state as BankImportReview).drafts;
      expect(drafts, hasLength(3));
      expect(drafts.map((d) => d.date), [
        DateTime(2026, 3, 4),
        DateTime(2026, 7, 4),
        DateTime(2026, 9, 4),
      ]);
      await cubit.close();
    });

    test('REGRESYON: başka başlıklı dosyaya (aynı sütun sayısı) uygulanmaz',
        () async {
      await confirmFirst();

      // 3 sütunlu başka bir banka. Eskiden yalnız sütun sayısına bakılıyor,
      // kayıtlı "ay-önce" ve başlık indeksi buraya da uygulanıyordu: 15.07
      // "15. ay" sayılıp satırlar okunamıyordu.
      final cubit = await parse(
        'baska.csv',
        'Islem Tarihi;Aciklama;Tutar\n'
            '15.07.2026;ABC;-10,00\n'
            '16.07.2026;DEF;-20,00\n',
      );

      final state = cubit.state;
      expect(state, isA<BankImportReview>());
      expect((state as BankImportReview).drafts.map((d) => d.date),
          [DateTime(2026, 7, 15), DateTime(2026, 7, 16)]);
      await cubit.close();
    });
  });
}
