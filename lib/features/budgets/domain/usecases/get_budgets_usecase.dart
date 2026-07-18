import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/features/budgets/domain/entities/budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBudgetsUsecase {
  final BudgetRepository budgetRepository;
  final TransactionsRepository transactionsRepository;

  GetBudgetsUsecase(this.budgetRepository, this.transactionsRepository);

  Future<Either<Failure, List<BudgetEntity>>> call(
      String userId, String walletId) async {
    final budgetsResult = await budgetRepository.getBudgets(walletId);

    return budgetsResult.fold(
      (failure) => Left(failure),
      (budgets) async {
        // Find start and end of current month
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
            // Map the budgets with their spent amount
            final updatedBudgets = budgets.map((budget) {
              final spent = transactions
                  .where((t) => t.tag == budget.categoryId)
                  .fold(0.0, (sum, t) => sum + t.amount);

              return budget.copyWith(spentAmount: spent);
            }).toList();

            return Right(updatedBudgets);
          },
        );
      },
    );
  }
}
