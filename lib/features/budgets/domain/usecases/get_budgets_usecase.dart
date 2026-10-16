import 'package:cunehat/core/l10n/app_strings.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/budgets/domain/services/budget_spending_reader.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBudgetsUsecase {
  final BudgetRepository budgetRepository;
  final TransactionsRepository transactionsRepository;
  final CategoryRepository categoryRepository;

  /// Kart cüzdanında harcama ÖDEME ayına sayılır (bkz. `cardPaymentDate`);
  /// kartın kesim/son ödeme bilgisi buradan okunur. Verilmezse (yalıtılmış
  /// testler) her cüzdan takvim ayıyla sayılır.
  final WalletRepository? walletRepository;

  GetBudgetsUsecase(
    this.budgetRepository,
    this.transactionsRepository,
    this.categoryRepository, [
    this.walletRepository,
  ]) : _reader = BudgetSpendingReader(transactionsRepository, walletRepository);

  final BudgetSpendingReader _reader;

  Future<Either<Failure, List<BudgetEntity>>> call(
      String userId, String walletId) async {
    final budgetsResult = await budgetRepository.getBudgets(walletId);

    // Ana kategori bütçesi alt kategorilerini KAPSAR: "Fatura"ya konan limit
    // Elektrik + Doğalgaz + doğrudan Fatura harcamasını birlikte sayar.
    //
    // Kategori deposu Either değil EXCEPTION fırlatır (CacheException); burada
    // yakalanmazsa çağıranın `fold`u devreye girmeden dışarı kaçar ve
    // BudgetAlertMonitor'ün stream dinleyicisini oturum boyunca öldürür.
    final List<CategoryEntity> categories;
    try {
      categories = await categoryRepository.getAllCategories();
    } catch (e) {
      return Left(CacheFailure(appStrings.failCategoriesRead('$e')));
    }

    return budgetsResult.fold(
      (failure) => Left(failure),
      (budgets) async {
        // İçinde bulunulan ayın başı ve sonu
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);

        final transactionsResult = await _reader.expensesBetween(
          userId: userId,
          walletId: walletId,
          start: startOfMonth,
          end: endOfMonth,
        );

        return transactionsResult.fold(
          (tFailure) => Left(
              tFailure), // If fetching transactions fails, we return error.
          (transactions) => Right([
            // Her bütçeye dönem harcamasını iliştir (kural:
            // [BudgetSpendingReader.spentIn]).
            for (final budget in budgets)
              budget.copyWith(
                spentAmount: BudgetSpendingReader.spentIn(
                    transactions, [budget.categoryId], categories),
              ),
          ]),
        );
      },
    );
  }
}
