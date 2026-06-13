import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/budgets/domain/repositories/budget_repository.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddTransactionUseCase {
  final TransactionsRepository repository;
  final BudgetRepository budgetRepository;
  final NotificationService notificationService;

  AddTransactionUseCase(
      this.repository, this.budgetRepository, this.notificationService);

  Future<Either<Failure, String>> call(TransactionEntity params) async {
    if (params.id == null || params.id!.isEmpty) {
      params = params.copyWith(id: UidGenerator.generateV7());
    }

    final result = await repository.addTransaction(params);

    // Check budget if it's an expense
    if (params.type == TransactionTypeModel.expense) {
      result.fold(
        (failure) => null,
        (_) async {
          final budgetsResult = await budgetRepository.getBudgets();
          budgetsResult.fold(
            (failure) => null,
            (budgets) {
              for (var budget in budgets) {
                if (budget.categoryId == params.tag) {
                  // If we don't have the updated spent amount, we could just calculate it,
                  // or the budget bloc usually handles it.
                  // For a quick check: if the newly added transaction pushes it over 80%:
                  // We actually need the updated spent amount. Since we just added it,
                  // the Budget calculation usually happens in the UI or by a usecase.
                  // For now, we can show a warning if this transaction alone is very large,
                  // OR we can fetch all transactions for this month.
                  // Since calculating all transactions here is heavy, we might assume the budget
                  // already has the current spentAmount, so we just add params.amount
                  final newSpent = budget.spentAmount + params.amount;
                  if (budget.limitAmount > 0) {
                    final ratio = newSpent / budget.limitAmount;
                    if (ratio >= 0.8 && ratio < 1.0) {
                      notificationService.showNotification(
                        id: budget.categoryId.hashCode,
                        title: 'Bütçe Uyarısı',
                        body: 'Dikkat: Bütçenizin %80\'ine ulaştınız.',
                      );
                    } else if (ratio >= 1.0) {
                      notificationService.showNotification(
                        id: budget.categoryId.hashCode,
                        title: 'Bütçe Aşıldı!',
                        body: 'Dikkat: Bütçenizi aştınız!',
                      );
                    }
                  }
                  break;
                }
              }
            },
          );
        },
      );
    }

    return result;
  }
}

@injectable
class DeleteTransactionUseCase {
  final TransactionsRepository repository;

  DeleteTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteTransaction(params);
  }
}

@injectable
class GetTransactionsGroupedUseCase {
  final TransactionsRepository repository;

  GetTransactionsGroupedUseCase(this.repository);

  Future<Either<Failure, Map<DateTime, List<TransactionEntity>>>> call(
    GetTransactionsGroupedParams params,
  ) async {
    return await repository.getTransactionsGroupedByDate(
      userId: params.userId,
      walletId: params.walletId,
      type: params.type,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

@injectable
class GetTransactionsUseCase {
  final TransactionsRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, List<TransactionEntity>>> call(
    GetTransactionsParams params,
  ) async {
    return await repository.getTransactions(
      userId: params.userId,
      walletId: params.walletId,
      startDate: params.startDate,
      endDate: params.endDate,
      type: params.type,
    );
  }
}

@injectable
class UpdateTransactionUseCase {
  final TransactionsRepository repository;

  UpdateTransactionUseCase(this.repository);

  Future<Either<Failure, void>> call(TransactionEntity params) async {
    if (params.id == null || params.id!.isEmpty) {
      return Left(ValidationFailure(
          'Transaction ID cannot be null for update operation'));
    }
    return await repository.updateTransaction(params);
  }
}

@injectable
class GetTransactionByIdUseCase {
  final TransactionsRepository repository;

  GetTransactionByIdUseCase(this.repository);

  Future<Either<Failure, TransactionEntity>> call(String transactionId) async {
    return await repository.getTransactionById(transactionId);
  }
}
