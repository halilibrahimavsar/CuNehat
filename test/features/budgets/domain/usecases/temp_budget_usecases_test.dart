import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/temp_budget_repository.dart';
import 'package:cunehat/features/budgets/domain/usecases/temp_budget_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/forecast/domain/forecast_engine.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_frequency_enum.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTempRepo extends Mock implements TempBudgetRepository {}

class _MockCategoryRepository extends Mock implements CategoryRepository {}

class _MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

class _MockWalletRepository extends Mock implements WalletRepository {}

class _MockRecurringRepository extends Mock
    implements RecurringTransactionRepository {}

void main() {
  late _MockTempRepo repo;
  late _MockTransactionsRepository txRepo;
  late _MockCategoryRepository categoryRepo;
  late GetTempBudgetsUsecase usecase;

  const categories = [
    CategoryEntity(
        id: 'travel', name: 'Seyahat', iconName: 'flight', isExpense: true),
    CategoryEntity(
        id: 'hotel',
        name: 'Otel',
        iconName: 'hotel',
        isExpense: true,
        parentId: 'travel'),
    CategoryEntity(
        id: 'food', name: 'Yeme', iconName: 'restaurant', isExpense: true),
    CategoryEntity(
        id: 'market', name: 'Market', iconName: 'cart', isExpense: true),
  ];

  TransactionEntity expense(
    String id,
    String tag,
    double amount,
    DateTime date, {
    bool isSystem = false,
    String walletId = 'w',
  }) =>
      TransactionEntity(
        id: id,
        userId: 'u',
        walletId: walletId,
        title: id,
        tag: tag,
        amount: amount,
        date: date,
        type: TransactionTypeModel.expense,
        isSystem: isSystem,
      );

  TempBudgetEntity holiday({
    String id = 'tb',
    List<String> categoryIds = const ['travel', 'food'],
    DateTime? start,
    DateTime? end,
  }) =>
      TempBudgetEntity(
        id: id,
        walletId: 'w',
        name: 'Tatil',
        limitAmount: 15000,
        startDate: start ?? DateTime(2026, 11, 10),
        endDate: end ?? DateTime(2026, 11, 20),
        categoryIds: categoryIds,
      );

  void stubTransactions(List<TransactionEntity> txs) {
    when(() => txRepo.getTransactions(
          userId: any(named: 'userId'),
          walletId: any(named: 'walletId'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          type: any(named: 'type'),
        )).thenAnswer((_) async => Right(txs));
  }

  setUp(() {
    repo = _MockTempRepo();
    txRepo = _MockTransactionsRepository();
    categoryRepo = _MockCategoryRepository();
    when(() => categoryRepo.getAllCategories())
        .thenAnswer((_) async => categories);
    usecase = GetTempBudgetsUsecase(repo, txRepo, categoryRepo);
  });

  group('GetTempBudgetsUsecase', () {
    test('aralığın İKİ UCU da dahil; dışındaki gün sayılmaz', () async {
      when(() => repo.getTempBudgets('w'))
          .thenAnswer((_) async => Right([holiday()]));
      stubTransactions([
        expense('before', 'travel', 100, DateTime(2026, 11, 9, 23, 59)),
        expense('first', 'travel', 200, DateTime(2026, 11, 10, 0, 1)),
        expense('last', 'food', 300, DateTime(2026, 11, 20, 23, 59)),
        expense('after', 'food', 400, DateTime(2026, 11, 21, 0, 1)),
      ]);

      final result = await usecase('u', 'w');

      expect(result.getOrElse(() => const []).single.spentAmount, 500);
    });

    test('okuma penceresi aralığın ilk gününün başından son gününün sonuna',
        () async {
      when(() => repo.getTempBudgets('w'))
          .thenAnswer((_) async => Right([holiday()]));
      stubTransactions(const []);

      await usecase('u', 'w');

      verify(() => txRepo.getTransactions(
            userId: 'u',
            walletId: 'w',
            startDate: DateTime(2026, 11, 10),
            endDate: DateTime(2026, 11, 20, 23, 59, 59, 999),
            type: TransactionTypeModel.expense,
          )).called(1);
    });

    test('ana kategori alt kategorisini kapsar; ikisi seçilse de ÇİFT SAYILMAZ',
        () async {
      when(() => repo.getTempBudgets('w')).thenAnswer((_) async => Right([
            holiday(categoryIds: const ['travel', 'hotel']),
          ]));
      stubTransactions([
        expense('hotel', 'hotel', 4000, DateTime(2026, 11, 11)),
        expense('flight', 'travel', 2500, DateTime(2026, 11, 10)),
        expense('market', 'market', 999, DateTime(2026, 11, 12)),
      ]);

      final result = await usecase('u', 'w');

      expect(result.getOrElse(() => const []).single.spentAmount, 6500);
    });

    test('kuplaj hareketi (transfer, borç ödemesi) harcama SAYILMAZ', () async {
      when(() => repo.getTempBudgets('w'))
          .thenAnswer((_) async => Right([holiday()]));
      stubTransactions([
        expense('meal', 'food', 300, DateTime(2026, 11, 12)),
        expense('move', 'food', 5000, DateTime(2026, 11, 12), isSystem: true),
      ]);

      final result = await usecase('u', 'w');

      expect(result.getOrElse(() => const []).single.spentAmount, 300);
    });

    test('birden çok bütçe TEK okumayla hesaplanır, başlangıca göre sıralanır',
        () async {
      when(() => repo.getTempBudgets('w')).thenAnswer((_) async => Right([
            holiday(
                id: 'late',
                start: DateTime(2026, 12, 1),
                end: DateTime(2026, 12, 3)),
            holiday(id: 'early'),
          ]));
      stubTransactions([
        expense('a', 'food', 100, DateTime(2026, 11, 15)),
        expense('b', 'food', 70, DateTime(2026, 12, 2)),
      ]);

      final result = await usecase('u', 'w');
      final list = result.getOrElse(() => const []);

      expect(list.map((b) => b.id), ['early', 'late']);
      expect(list.map((b) => b.spentAmount), [100, 70]);
      verify(() => txRepo.getTransactions(
            userId: 'u',
            walletId: 'w',
            startDate: DateTime(2026, 11, 10),
            endDate: DateTime(2026, 12, 3, 23, 59, 59, 999),
            type: TransactionTypeModel.expense,
          )).called(1);
    });

    test('bütçe yoksa defter OKUNMAZ', () async {
      when(() => repo.getTempBudgets('w'))
          .thenAnswer((_) async => const Right([]));

      final result = await usecase('u', 'w');

      expect(result.getOrElse(() => [holiday()]), isEmpty);
      verifyNever(() => txRepo.getTransactions(
            userId: any(named: 'userId'),
            walletId: any(named: 'walletId'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            type: any(named: 'type'),
          ));
    });

    test('kategori deposu FIRLATIRSA hata Left olarak döner (dışarı kaçmaz)',
        () async {
      when(() => repo.getTempBudgets('w'))
          .thenAnswer((_) async => Right([holiday()]));
      when(() => categoryRepo.getAllCategories()).thenThrow(Exception('boom'));

      final result = await usecase('u', 'w');

      expect(result.isLeft(), isTrue);
    });

    test('kart cüzdanında harcama ÖDEME gününe sayılır', () async {
      // Kesim 1'i, son ödeme 15'i: 2 Kas harcaması 1 Ara'da kesilir, 15 Ara'da
      // ödenir. 1–20 Ara bütçesi onu sayar; 1–20 Kas bütçesi saymaz.
      final wallets = _MockWalletRepository();
      when(() => wallets.getWalletById('card')).thenAnswer((_) async => Right(
            WalletEntity(
              id: 'card',
              userId: 'u',
              name: 'Bonus',
              balance: -500,
              debt: 0,
              credit: 0,
              investment: 0,
              colorHex: '0xFF000000',
              iconName: 'credit_card',
              createdAt: DateTime(2020),
              openingBalance: 0,
              creditCard: const CreditCardInfo(closingDay: 1, dueDay: 15),
            ),
          ));
      when(() => repo.getTempBudgets('card')).thenAnswer((_) async => Right([
            holiday(
                id: 'nov',
                start: DateTime(2026, 11, 1),
                end: DateTime(2026, 11, 20)),
            holiday(
                id: 'dec',
                start: DateTime(2026, 12, 1),
                end: DateTime(2026, 12, 20)),
          ]));
      stubTransactions([
        expense('meal', 'food', 300, DateTime(2026, 11, 2, 12),
            walletId: 'card'),
      ]);

      final result = await GetTempBudgetsUsecase(
          repo, txRepo, categoryRepo, wallets)('u', 'card');
      final list = result.getOrElse(() => const []);

      expect(list.firstWhere((b) => b.id == 'nov').spentAmount, 0);
      expect(list.firstWhere((b) => b.id == 'dec').spentAmount, 300);
    });
  });

  // QA O7: Bütçeler sayfası "günde X" derken Gelecek "sığması için günde
  // en çok Y" diyordu — biri planlı şablonları düşmüyordu. Aynı veriyle iki
  // sayı artık EŞİT.
  group('günlük pay = Gelecek requiredDaily', () {
    final today = DateTime(2026, 11, 12);

    RecurringTransactionEntity template(
            String id, String tag, double amount, DateTime next,
            {String walletId = 'w'}) =>
        RecurringTransactionEntity(
          id: id,
          userId: 'u',
          walletId: walletId,
          title: id,
          tag: tag,
          amount: amount,
          type: TransactionTypeModel.expense,
          frequency: RecurringFrequency.monthly,
          nextExecutionDate: next,
          anchorDay: next.day,
        );

    WalletEntity wallet(String id, {CreditCardInfo? card}) => WalletEntity(
          id: id,
          userId: 'u',
          name: id,
          balance: 0,
          debt: 0,
          credit: 0,
          investment: 0,
          colorHex: '0xFF000000',
          iconName: 'wallet',
          createdAt: DateTime(2020),
          openingBalance: 0,
          creditCard: card,
        );

    Future<(TempBudgetEntity, double?)> both({
      required WalletEntity w,
      required TempBudgetEntity budget,
      required List<TransactionEntity> ledger,
      required List<RecurringTransactionEntity> templates,
    }) async {
      final id = w.id!;
      final wallets = _MockWalletRepository();
      when(() => wallets.getWalletById(id)).thenAnswer((_) async => Right(w));
      final recurring = _MockRecurringRepository();
      when(() => recurring.getAllTemplates())
          .thenAnswer((_) async => Right(templates));
      when(() => repo.getTempBudgets(id))
          .thenAnswer((_) async => Right([budget]));
      stubTransactions(ledger);

      final result = await GetTempBudgetsUsecase(
              repo, txRepo, categoryRepo, wallets, recurring)('u', id,
          today: today);
      final mine = result.getOrElse(() => const []).single;

      final outlook = ForecastEngine(
        today: today,
        period: DateTimeRange(
            start: DateTime(2026, 11, 1), end: DateTime(2026, 11, 30)),
        categories: categories,
      )
          .projectAll([
            WalletForecastInput(
              wallet: w,
              ledger: ledger,
              templates: templates,
              tempBudgets: [budget],
            ),
          ])[id]!
          .budgets
          .single;
      return (mine, outlook.requiredDaily);
    }

    test('düz cüzdan: planlı şablon düşülür, iki sayı aynı', () async {
      final (budget, required) = await both(
        w: wallet('w'),
        budget: holiday(start: DateTime(2026, 11, 10)),
        ledger: [
          expense('meal', 'food', 2000, DateTime(2026, 11, 11, 12)),
          // İleri tarihli kayıt: Bütçeler "harcanan"a, Gelecek "planlı"ya.
          expense('ticket', 'travel', 1000, DateTime(2026, 11, 15, 9)),
          expense('market', 'market', 500, DateTime(2026, 11, 13, 9)),
        ],
        templates: [
          template('Otel', 'hotel', 3000, DateTime(2026, 11, 18)),
          template('Market', 'market', 400, DateTime(2026, 11, 14)),
        ],
      );

      expect(budget.plannedAmount, 3000);
      // (15.000 − 3.000 − 3.000) / 9 gün = 1.000.
      expect(budget.dailyAllowanceOn(today), 1000);
      expect(budget.dailyAllowanceOn(today), required);
    });

    test('kart cüzdanı: ödeme günü kuralıyla da iki sayı aynı', () async {
      // Kesim 1, son ödeme 15: 18 Kas vadesi 15 Ara'da ödenir (aralıkta);
      // 18 Ara vadesi 15 Oca'da (dışında).
      final (budget, required) = await both(
        w: wallet('card',
            card: const CreditCardInfo(closingDay: 1, dueDay: 15)),
        budget:
            holiday(start: DateTime(2026, 12, 1), end: DateTime(2026, 12, 20))
                .copyWith(walletId: 'card'),
        ledger: [
          expense('meal', 'food', 300, DateTime(2026, 11, 2, 12),
              walletId: 'card'),
          expense('ticket', 'travel', 1000, DateTime(2026, 11, 20, 9),
              walletId: 'card'),
        ],
        templates: [
          template('Otel', 'hotel', 3000, DateTime(2026, 11, 18),
              walletId: 'card'),
        ],
      );

      expect(budget.plannedAmount, 3000);
      // (15.000 − 1.300 − 3.000) / 20 gün = 535.
      expect(budget.dailyAllowanceOn(today), 535);
      expect(budget.dailyAllowanceOn(today), required);
    });
  });

  group('Save/DeleteTempBudgetUsecase', () {
    setUpAll(() => registerFallbackValue(holiday()));

    test('yalnız başarıda değişim yayınlanır', () async {
      final notifier = BudgetsChangedNotifier();
      final events = <void>[];
      final sub = notifier.stream.listen(events.add);
      when(() => repo.saveTempBudget(any()))
          .thenAnswer((_) async => const Right(null));
      when(() => repo.deleteTempBudget('x'))
          .thenAnswer((_) async => const Left(CacheFailure('no')));

      await SaveTempBudgetUsecase(repo, notifier)(holiday());
      await DeleteTempBudgetUsecase(repo, notifier)('x');
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      await sub.cancel();
      notifier.dispose();
    });
  });
}
