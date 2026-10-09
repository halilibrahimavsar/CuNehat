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
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
class GetBudgetsUsecase {
  final BudgetRepository budgetRepository;
  final TransactionsRepository transactionsRepository;
  final CategoryRepository categoryRepository;

  /// Kart cüzdanında harcama ÖDEME ayına sayılır (bkz. [cardPaymentDate]);
  /// kartın kesim/son ödeme bilgisi buradan okunur. Verilmezse (yalıtılmış
  /// testler) her cüzdan takvim ayıyla sayılır.
  final WalletRepository? walletRepository;

  GetBudgetsUsecase(
    this.budgetRepository,
    this.transactionsRepository,
    this.categoryRepository, [
    this.walletRepository,
  ]);

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

        // Kart cüzdanı: harcama PARASININ ödendiği aya sayılır (Rapor ve
        // İçgörü ile aynı kural). 6 Ekim'deki alışveriş 5 Kasım'da ödenir;
        // Ekim bütçesini değil Kasım'ınkini doldurur. Takvim süzgeci kayıt
        // tarihine baktığı için kartın tüm giderleri okunur, ödeme gününe
        // göre süzülür.
        final card = await _cardOf(walletId);
        final transactionsResult = card == null
            ? await transactionsRepository.getTransactions(
                userId: userId,
                walletId: walletId,
                startDate: startOfMonth,
                endDate: endOfMonth,
                type: TransactionTypeModel.expense,
              )
            : (await transactionsRepository.getTransactions(
                userId: userId,
                walletId: walletId,
                type: TransactionTypeModel.expense,
              ))
                .map((all) => [
                      for (final t in datedByPayment(all, card))
                        if (!t.date.isBefore(startOfMonth) &&
                            !t.date.isAfter(endOfMonth))
                          t,
                    ]);

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
              // Evren kuralı BURADA da geçerli: kuplaj hareketleri (transfer,
              // borç ödemesi, yatırım alımı) harcama değildir. Bugün bunlar
              // yalnız `tag`leri Türkçe sabit, kategori kimlikleri ise UUID
              // olduğu için eşleşmiyor — yani koruma bir AD ÇAKIŞMASI
              // guard'ına (`CashMovementTags.isReserved`) yaslanıyordu, evren
              // kuralına değil. Bütçe anahtarı bir gün ada dönerse (eski
              // kayıtlarda `categoryId` adın kendisiydi) o çakışma harcamayı
              // sessizce şişirirdi.
              final spent = roundToCents(transactions
                  .where(
                      (t) => isSpendingMovement(t) && subtree.contains(t.tag))
                  .fold(0.0, (sum, t) => sum + t.amount));

              return budget.copyWith(spentAmount: spent);
            }).toList();

            return Right(updatedBudgets);
          },
        );
      },
    );
  }

  Future<CreditCardInfo?> _cardOf(String walletId) async {
    final repo = walletRepository;
    if (repo == null) return null;
    try {
      final result = await repo.getWalletById(walletId);
      return result.fold((_) => null, (w) => w?.creditCard);
    } catch (_) {
      return null;
    }
  }
}
