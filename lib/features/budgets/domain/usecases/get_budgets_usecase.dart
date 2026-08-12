import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBudgetsUsecase {
  final BudgetRepository budgetRepository;
  final TransactionsRepository transactionsRepository;
  final CategoryRepository categoryRepository;

  GetBudgetsUsecase(
    this.budgetRepository,
    this.transactionsRepository,
    this.categoryRepository,
  );

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
      return Left(CacheFailure('Kategoriler okunamadı: $e'));
    }

    return budgetsResult.fold(
      (failure) => Left(failure),
      (budgets) async {
        // İçinde bulunulan ayın başı ve sonu
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth =
            DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

        final transactionsResult = await transactionsRepository.getTransactions(
          userId: userId,
          walletId: walletId,
          startDate: startOfMonth,
          endDate: endOfMonth,
          type: TransactionTypeModel.expense,
        );

        return transactionsResult.fold(
          (tFailure) => Left(
              tFailure), // If fetching transactions fails, we return error.
          (transactions) {
            // Her bütçeye dönem harcamasını iliştir
            final updatedBudgets = budgets.map((budget) {
              // spentAmount yalnız gösterime değil, "doldu / aşıldı" kararına da
              // girer (bkz. BudgetEntity.isFilled, BudgetAlertService) — bu
              // yüzden ham fold artığı burada kuruşa yuvarlanarak kesilir.
              final subtree = subtreeIds(budget.categoryId, categories);
              final spent = roundToCents(transactions
                  .where((t) => subtree.contains(t.tag))
                  .fold(0.0, (sum, t) => sum + t.amount));

              return budget.copyWith(spentAmount: spent);
            }).toList();

            return Right(updatedBudgets);
          },
        );
      },
    );
  }
}
