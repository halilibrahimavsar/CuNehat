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
}

/// Ödeme kaynağı seçimi + (defterden seçildiyse) seçilen satır.
class PurchasePayment {
  final PurchasePaymentMode mode;

  /// [PurchasePaymentMode.ledger] iken seçilen satır; henüz seçilmediyse
  /// `null` (kayıt bu hâlde kaydedilemez).
  final TransactionEntity? ledgerTransaction;

  const PurchasePayment._(this.mode, this.ledgerTransaction);

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
        PurchasePaymentMode.ledger =>
          AdoptedCashMovement(ledgerTransaction!),
        PurchasePaymentMode.alreadyOwned => const OffLedgerCash(),
      };
}
