import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/l10n/app_strings.dart';
import 'package:cunehat/core/services/budgets_changed_notifier.dart';
import 'package:cunehat/features/budgets/domain/entities/temp_budget_entity.dart';
import 'package:cunehat/features/budgets/domain/repositories/temp_budget_repository.dart';
import 'package:cunehat/features/budgets/domain/services/budget_spending_reader.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/category_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:cunehat/features/recurring_transactions/domain/services/recurring_occurrences.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

/// Cüzdanın tek seferlik bütçelerini, HER BİRİ KENDİ ARALIĞINDA hesaplanmış
/// harcamayla döner (aylık bütçenin "bu ay" varsayımı burada yok).
///
/// Harcama kuralı aylık bütçeyle aynıdır ([BudgetSpendingReader]): alt
/// kategoriler dahil, kuplaj hareketleri hariç, kart cüzdanında ödeme günü.
///
/// Ayrıca aralığa düşecek düzenli şablon vadeleri [TempBudgetEntity.plannedAmount]
/// olarak yazılır (tahmin motoruyla aynı kural): Bütçeler sayfasının günlük
/// payı Gelecek'in "sığması için günde en çok" sayısıyla aynı çıkar (QA O7).
@injectable
class GetTempBudgetsUsecase {
  final TempBudgetRepository _repository;
  final CategoryRepository _categories;
  final BudgetSpendingReader _reader;

  /// Verilmezse (yalıtılmış testler) planlı tutar 0 kalır.
  final RecurringTransactionRepository? _recurring;

  GetTempBudgetsUsecase(
    this._repository,
    TransactionsRepository transactions,
    this._categories, [
    WalletRepository? wallets,
    this._recurring,
  ]) : _reader = BudgetSpendingReader(transactions, wallets);

  Future<Either<Failure, List<TempBudgetEntity>>> call(
      String userId, String walletId,
      {DateTime? today}) async {
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

    final templates = await _templatesOf(walletId);
    final card = templates.isEmpty ? null : await _reader.cardOf(walletId);
    final day = CardCycle.dateOnly(today ?? DateTime.now());

    return expensesResult.map((expenses) {
      final result = [
        for (final b in budgets)
          b.copyWith(
            spentAmount: BudgetSpendingReader.spentIn(
              expenses.where((t) => b.covers(t.date)),
              b.categoryIds,
              categories,
            ),
            plannedAmount:
                plannedIn(b, templates, categories, today: day, card: card),
          ),
      ]..sort((a, b) => a.startDate.compareTo(b.startDate));
      return result;
    });
  }

  /// Cüzdanın gider şablonları; okunamazsa boş (planlı tutar 0 kalır —
  /// bütçe sayfası yine açılır).
  Future<List<RecurringTransactionEntity>> _templatesOf(String walletId) async {
    final repo = _recurring;
    if (repo == null) return const [];
    try {
      final result = await repo.getAllTemplates();
      return result.fold(
          (_) => const [],
          (all) => [
                for (final t in all)
                  if (t.walletId == walletId &&
                      t.type == TransactionTypeModel.expense)
                    t,
              ]);
    } catch (_) {
      return const [];
    }
  }

  /// [b]'nin aralığına düşecek şablon vadelerinin toplamı: bugünden bitişe
  /// kadarki vadeler; kart cüzdanında ÖDEME günü aralıkta olanlar (tahmin
  /// motorunun `_budgetOutlook` kuralı). Bitmiş bütçede 0.
  static double plannedIn(
    TempBudgetEntity b,
    Iterable<RecurringTransactionEntity> templates,
    List<CategoryEntity> categories, {
    required DateTime today,
    CreditCardInfo? card,
  }) {
    final start = CardCycle.dateOnly(b.startDate);
    final end = CardCycle.dateOnly(b.endDate);
    final day = CardCycle.dateOnly(today);
    if (day.isAfter(end)) return 0;
    final tags = <String>{
      for (final r in b.categoryIds) ...subtreeIds(r, categories),
    };
    var sum = 0.0;
    for (final t in templates) {
      if (!tags.contains(t.tag)) continue;
      for (final d
          in RecurringOccurrences.occurrencesBetween(t, from: day, to: end)) {
        final m = card == null ? d : cardPaymentDay(d, card);
        if (!m.isBefore(start) && !m.isAfter(end)) sum += t.amount;
      }
    }
    return roundToCents(sum);
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
