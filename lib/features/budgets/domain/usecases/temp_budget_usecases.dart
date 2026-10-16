import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_strings.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/temp_budget_repository.dart';
import 'package:cunehat/features/budgets/domain/services/budget_spending_reader.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Cüzdanın tek seferlik bütçelerini, HER BİRİ KENDİ ARALIĞINDA hesaplanmış
/// harcamayla döner (aylık bütçenin "bu ay" varsayımı burada yok).
///
/// Harcama kuralı aylık bütçeyle aynıdır ([BudgetSpendingReader]): alt
/// kategoriler dahil, kuplaj hareketleri hariç, kart cüzdanında ödeme günü.
@injectable
class GetTempBudgetsUsecase {
  final TempBudgetRepository _repository;
  final CategoryRepository _categories;
  final BudgetSpendingReader _reader;

  GetTempBudgetsUsecase(
    this._repository,
    TransactionsRepository transactions,
    this._categories, [
    WalletRepository? wallets,
  ]) : _reader = BudgetSpendingReader(transactions, wallets);

  Future<Either<Failure, List<TempBudgetEntity>>> call(
      String userId, String walletId) async {
    final budgetsResult = await _repository.getTempBudgets(walletId);
    final budgets = budgetsResult.fold((_) => null, (b) => b);
    if (budgets == null) {
      return budgetsResult;
    }
    if (budgets.isEmpty) return const Right([]);

    // Kategori deposu Either değil EXCEPTION fırlatır (bkz. GetBudgetsUsecase).
    final List<CategoryEntity> categories;
    try {
      categories = await _categories.getAllCategories();
    } catch (e) {
      return Left(CacheFailure(appStrings.failCategoriesRead('$e')));
    }

    // Tek okuma: tüm bütçelerin aralıklarını kapsayan pencere. Bütçe başına
    // ayrı okuma, kart cüzdanında defterin tamamını N kez taşırdı.
    var from = budgets.first.startDate;
    var to = budgets.first.endDate;
    for (final b in budgets) {
      if (b.startDate.isBefore(from)) from = b.startDate;
      if (b.endDate.isAfter(to)) to = b.endDate;
    }
    final expensesResult = await _reader.expensesBetween(
      userId: userId,
      walletId: walletId,
      start: from,
      end: to,
    );

    return expensesResult.map((expenses) {
      final result = [
        for (final b in budgets)
          b.copyWith(
            spentAmount: BudgetSpendingReader.spentIn(
              expenses.where((t) => b.covers(t.date)),
              b.categoryIds,
              categories,
            ),
          ),
      ]..sort((a, b) => a.startDate.compareTo(b.startDate));
      return result;
    });
  }
}

@injectable
class SaveTempBudgetUsecase {
  final TempBudgetRepository _repository;
  final BudgetsChangedNotifier _notifier;

  SaveTempBudgetUsecase(this._repository, this._notifier);

  Future<Either<Failure, void>> call(TempBudgetEntity budget) async {
    final result = await _repository.saveTempBudget(budget);
    result.fold((_) {}, (_) => _notifier.notify());
    return result;
  }
}

@injectable
class DeleteTempBudgetUsecase {
  final TempBudgetRepository _repository;
  final BudgetsChangedNotifier _notifier;

  DeleteTempBudgetUsecase(this._repository, this._notifier);

  Future<Either<Failure, void>> call(String id) async {
    final result = await _repository.deleteTempBudget(id);
    result.fold((_) {}, (_) => _notifier.notify());
    return result;
  }
}
