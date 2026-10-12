import 'package:cunehat/features/investments/domain/cash_pot_math.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';

/// Yeni birikim kaydının ödemesi nereden geldi.
enum PurchasePaymentMode {
  /// Cüzdandan düşülür: alım tarihine gider yazılır (her zamanki davranış).
  wallet,

  /// Ödeme defterde ZATEN duruyor (ekstreden gelen ya da elle girilen satır):
  /// o satır kaydın nakit bacağı olur, ikinci gider yazılmaz.
  ledger,

  /// Uygulamadan önce alındı ("bu varlık zaten bende"): cüzdana dokunulmaz.
  alreadyOwned,

  /// Birikimdeki bir NAKİT KASASINDAN: kasa düşer, cüzdana ve deftere
  /// dokunulmaz.
  pot,
}

/// Ödeme kaynağı seçimi + (defterden seçildiyse) seçilen satır.
class PurchasePayment {
  final PurchasePaymentMode mode;

  /// [PurchasePaymentMode.ledger] iken seçilen satır; henüz seçilmediyse
  /// `null` (kayıt bu hâlde kaydedilemez).
  final TransactionEntity? ledgerTransaction;

  /// [PurchasePaymentMode.pot] iken seçilen kasa.
  final InvestmentEntity? pot;

  const PurchasePayment._(this.mode, this.ledgerTransaction, [this.pot]);

  const PurchasePayment.pot(InvestmentEntity this.pot)
      : mode = PurchasePaymentMode.pot,
        ledgerTransaction = null;

  /// Formun açılış seçimi: parası olan ANA KASA (kullanıcı onu açıkça
  /// seçti); yoksa bakiyesi olan kasalardan EN ÇOK parası olan (kullanıcı
  /// bakiyesinden yatırım yapmayı seçti — varsayılan o), o da yoksa cüzdan.
  ///
  /// Ana kasa boşsa atlanır: boş kasayı ön seçmek her alımı "kasada yalnız
  /// 0 var" uyarısıyla açardı.
  factory PurchasePayment.defaultFor(List<InvestmentEntity> pots) {
    final primary = primaryPotOf(pots);
    if (primary != null && primary.amount > 0) {
      return PurchasePayment.pot(primary);
    }
    final funded = [
      for (final p in pots)
        if (p.amount > 0) p,
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return funded.isEmpty
        ? const PurchasePayment.wallet()
        : PurchasePayment.pot(funded.first);
  }

  /// Kasadan ödemede [cost] kasanın bakiyesini aşıyor mu? Kayıt bu hâlde
  /// kaydedilemez.
  bool exceedsPot(double? cost) =>
      mode == PurchasePaymentMode.pot &&
      cost != null &&
      cost > (pot?.amount ?? 0) + 0.005;

  const PurchasePayment.wallet() : this._(PurchasePaymentMode.wallet, null);

  const PurchasePayment.alreadyOwned()
      : this._(PurchasePaymentMode.alreadyOwned, null);

  const PurchasePayment.ledger([TransactionEntity? transaction])
      : this._(PurchasePaymentMode.ledger, transaction);

  bool get isAlreadyOwned => mode == PurchasePaymentMode.alreadyOwned;

  /// Defterden seçilmiş ve satırı belli: maliyet ve tarih o satırdan gelir,
  /// sayfada kilitlenir.
  bool get isLedgerLocked =>
      mode == PurchasePaymentMode.ledger && ledgerTransaction != null;

  /// Defterden seçilmiş ama satır henüz seçilmemiş.
  bool get needsLedgerTransaction =>
      mode == PurchasePaymentMode.ledger && ledgerTransaction == null;

  /// Bloc'a gidecek nakit kaynağı.
  CashSource get cashSource => switch (mode) {
        PurchasePaymentMode.wallet => const NewCashMovement(),
        PurchasePaymentMode.ledger => AdoptedCashMovement(ledgerTransaction!),
        PurchasePaymentMode.alreadyOwned => const OffLedgerCash(),
        PurchasePaymentMode.pot => FromSavingsPot(pot!.id!),
      };
}
