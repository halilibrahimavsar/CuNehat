import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/category_tree.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/category_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/services/transaction_report_service.dart';
import 'package:cunehat/features/wallet/domain/card_cycle.dart';
import 'package:cunehat/features/wallet/domain/entities/credit_card_info.dart';
import 'package:cunehat/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:dartz/dartz.dart';

/// Aylık ve tek seferlik bütçenin ORTAK harcama okuması.
///
/// İki bütçe türü aynı soruyu farklı aralıklarla sorar ("bu kategorilerde bu
/// günler arasında ne harcandı?"). Kural tek yerde durmazsa ikisi zamanla
/// ayrışır — evren kuralının dört kopyası tam olarak böyle doğmuştu (bkz.
/// para doğruluğu denetimi).
class BudgetSpendingReader {
  final TransactionsRepository _transactions;

  /// Kart cüzdanında harcama ÖDEME gününe sayılır (bkz. [cardPaymentDate]).
  /// Verilmezse (yalıtılmış testler) her cüzdan kayıt tarihiyle sayılır.
  final WalletRepository? _wallets;

  const BudgetSpendingReader(this._transactions, [this._wallets]);

  /// [walletId]'nin [start]–[end] (gün bazında, iki uç dahil) giderleri.
  ///
  /// Kart cüzdanı: harcama PARASININ ödendiği güne sayılır (Rapor ve İçgörü
  /// ile aynı kural). 6 Ekim'deki alışveriş 5 Kasım'da ödenir; Ekim bütçesini
  /// değil Kasım'ınkini doldurur. Takvim süzgeci kayıt tarihine baktığı için
  /// kartın tüm giderleri okunur, ödeme gününe göre süzülür.
  Future<Either<Failure, List<TransactionEntity>>> expensesBetween({
    required String userId,
    required String walletId,
    required DateTime start,
    required DateTime end,
  }) async {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final card = await _cardOf(walletId);
    if (card == null) {
      return _transactions.getTransactions(
        userId: userId,
        walletId: walletId,
        startDate: from,
        endDate: to,
        type: TransactionTypeModel.expense,
      );
    }
    final all = await _transactions.getTransactions(
      userId: userId,
      walletId: walletId,
      type: TransactionTypeModel.expense,
    );
    return all.map((list) => [
          for (final t in datedByPayment(list, card))
            if (!t.date.isBefore(from) && !t.date.isAfter(to)) t,
        ]);
  }

  /// [rootIds]'in alt ağaçlarındaki harcamanın kuruşa yuvarlanmış toplamı.
  ///
  /// Birden çok kök verilirse alt ağaçların BİRLEŞİMİ sayılır: "Fatura" ile
  /// "Fatura › Elektrik" birlikte seçilse de bir elektrik ödemesi bir kez
  /// sayılır.
  ///
  /// Evren kuralı burada da geçerli: kuplaj hareketleri (transfer, borç
  /// ödemesi, yatırım alımı) harcama değildir. Bugün bunlar yalnız `tag`leri
  /// Türkçe sabit, kategori kimlikleri ise UUID olduğu için eşleşmiyor —
  /// yani koruma bir AD ÇAKIŞMASI guard'ına (`CashMovementTags.isReserved`)
  /// yaslanıyordu, evren kuralına değil. Bütçe anahtarı bir gün ada dönerse
  /// (eski kayıtlarda `categoryId` adın kendisiydi) o çakışma harcamayı
  /// sessizce şişirirdi.
  ///
  /// Yuvarlama gösterim için değil: harcama "doldu / aşıldı" kararına da
  /// girer (bkz. `BudgetEntity.isFilled`, `BudgetAlertService`), ham fold
  /// artığı burada kesilir.
  static double spentIn(
    Iterable<TransactionEntity> expenses,
    Iterable<String> rootIds,
    List<CategoryEntity> categories,
  ) {
    final ids = <String>{
      for (final root in rootIds) ...subtreeIds(root, categories),
    };
    return roundToCents(expenses
        .where((t) => isSpendingMovement(t) && ids.contains(t.tag))
        .fold(0.0, (sum, t) => sum + t.amount));
  }

  Future<CreditCardInfo?> _cardOf(String walletId) async {
    final repo = _wallets;
    if (repo == null) return null;
    try {
      final result = await repo.getWalletById(walletId);
      return result.fold((_) => null, (w) => w?.creditCard);
    } catch (_) {
      return null;
    }
  }
}
