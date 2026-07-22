import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/bank_import/data/category_guesser.dart';
import 'package:cunehat/features/bank_import/data/column_mapper.dart';
import 'package:cunehat/features/bank_import/data/pdf_statement_parser.dart';
import 'package:cunehat/features/bank_import/data/raw_table_reader.dart';
import 'package:cunehat/features/bank_import/domain/import_draft.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_cubit.dart';
import 'package:cunehat/features/bank_import/presentation/bloc/bank_import_state.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReader extends Mock implements RawTableReader {}

class _MockMapper extends Mock implements ColumnMapper {}

class _MockPdf extends Mock implements PdfStatementParser {}

class _MockGuesser extends Mock implements CategoryGuesser {}

class _MockCategoryRepo extends Mock implements CategoryRepository {}

class _MockTxRepo extends Mock implements TransactionsRepository {}

class _MockMetrics extends Mock implements WalletMetricsService {}

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockNotifier extends Mock implements TransactionsChangedNotifier {}

WalletEntity _wallet(double balance) => WalletEntity(
      id: 'w1',
      userId: 'u1',
      name: 'Nakit',
      balance: balance,
      debt: 0,
      credit: 0,
      investment: 0,
      colorHex: '0xFF000000',
      iconName: 'money',
      createdAt: DateTime(2026, 1, 1),
      openingBalance: 0,
    );

ImportDraft _draft(DateTime date, double amount, {bool income = false}) =>
    ImportDraft(
      date: date,
      description: 'X',
      amount: amount,
      type: income ? TransactionTypeModel.income : TransactionTypeModel.expense,
    );

void main() {
  late _MockTxRepo txRepo;
  late _MockMetrics metrics;
  late _MockWalletRepo walletRepo;
  late _MockNotifier notifier;

  setUpAll(() {
    registerFallbackValue(
      TransactionEntity(
        id: 'x',
        userId: 'u1',
        walletId: 'w1',
        title: 'X',
        tag: '',
        amount: 1,
        date: DateTime(2026, 1, 1),
        type: TransactionTypeModel.expense,
      ),
    );
  });

  BankImportCubit build() {
    txRepo = _MockTxRepo();
    metrics = _MockMetrics();
    walletRepo = _MockWalletRepo();
    notifier = _MockNotifier();

    when(() => txRepo.addTransaction(any()))
        .thenAnswer((_) async => const Right('new_id'));
    when(() => txRepo.deleteTransaction(any()))
        .thenAnswer((_) async => const Right(null));
    when(() => metrics.syncBalance(any())).thenAnswer((_) async => true);
    when(() => metrics.walletRepository).thenReturn(walletRepo);
    when(() => walletRepo.getWalletById(any()))
        .thenAnswer((_) async => Right(_wallet(1500.0)));

    return BankImportCubit(
      _MockReader(),
      _MockMapper(),
      _MockPdf(),
      _MockGuesser(),
      // CategoryRepository commit yolunda kullanılmaz.
      _MockCategoryRepo(),
      txRepo,
      metrics,
      notifier,
    );
  }

  group('commit', () {
    test('seçili taslakları yazar: tek syncBalance + tek notify + taze bakiye',
        () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100),
          _draft(DateTime(2026, 7, 11), 50, income: true),
        ],
      );

      await cubit.commit();

      verify(() => txRepo.addTransaction(any())).called(2);
      verify(() => metrics.syncBalance('w1')).called(1);
      verify(() => notifier.notify(userId: 'u1', walletId: 'w1')).called(1);

      final state = cubit.state;
      expect(state, isA<BankImportDone>());
      final done = state as BankImportDone;
      expect(done.added, 2);
      expect(done.balance, 1500.0); // WalletBloc'a değil, defterden taze okundu
      expect(done.walletId, 'w1');
      expect(done.userId, 'u1');
    });

    test('geçmiş aylı satır varsa hasPastMonthRows=true', () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2020, 1, 5), 100), // geçmiş ay
        ],
      );

      await cubit.commit();

      final done = cubit.state as BankImportDone;
      expect(done.hasPastMonthRows, isTrue);
    });

    test('seçili taslak yoksa hiç yazmaz, added=0', () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100).copyWith(selected: false),
        ],
      );

      await cubit.commit();

      verifyNever(() => txRepo.addTransaction(any()));
      final done = cubit.state as BankImportDone;
      expect(done.added, 0);
    });
  });

  group('undoImport', () {
    test('yalnız az önce eklenenleri siler + resync + notify + başa döner',
        () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [
          _draft(DateTime(2026, 7, 10), 100),
          _draft(DateTime(2026, 7, 11), 50),
        ],
      );
      await cubit.commit();

      await cubit.undoImport();

      verify(() => txRepo.deleteTransaction(any())).called(2);
      // Bir commit + bir undo = 2 syncBalance.
      verify(() => metrics.syncBalance('w1')).called(2);
      expect(cubit.state, isA<BankImportInitial>());
    });

    test('ikinci geri alma çağrısı no-op (id listesi boşaldı)', () async {
      final cubit = build();
      cubit.debugSeedReview(
        userId: 'u1',
        walletId: 'w1',
        drafts: [_draft(DateTime(2026, 7, 10), 100)],
      );
      await cubit.commit();

      await cubit.undoImport();
      await cubit.undoImport(); // ikinci

      verify(() => txRepo.deleteTransaction(any())).called(1); // yalnız 1 kez
    });
  });
}
