import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/debt_model.dart';
import 'package:cunehat/features/debt_and_receivable/data/models/receivable_model.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_model.dart';
import 'package:cunehat/features/investments/data/models/investment_model.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

/// Onarılacak tek kayıt: hangi box anahtarı, hangi userId'ye çekilecek.
class UserIdRepair {
  final dynamic key;
  final String correctUserId;

  const UserIdRepair({required this.key, required this.correctUserId});
}

/// Saf planlama: cüzdanı MEVCUT olup userId'si cüzdanınkinden farklı kayıtları
/// listeler. Yetimlere (walletId'si bilinmeyen) dokunulmaz. Birim test edilir.
List<UserIdRepair> planUserIdRepairs({
  required Map<String, String> walletUserIds,
  required Iterable<({dynamic key, String userId, String walletId})> records,
}) {
  final repairs = <UserIdRepair>[];
  for (final r in records) {
    final ownerUserId = walletUserIds[r.walletId];
    if (ownerUserId != null && r.userId != ownerUserId) {
      repairs.add(UserIdRepair(key: r.key, correctUserId: ownerUserId));
    }
  }
  return repairs;
}

/// Açılışta koşan kendi-kendini onarım: geçmişte yanlış kimlikle
/// ('unknown_user' vb.) yazılmış kayıtların userId'sini bağlı cüzdanın
/// userId'sine çeker; etkilenen cüzdanların defter metriklerini yeniden
/// hesaplar. İdempotent: ikinci koşuda sıfır yazım. Hata asla açılışı
/// bloklamaz (eski Drive yedeği geri yüklenince de kendiliğinden iyileştirir).
@lazySingleton
class DataRepairService {
  final WalletMetricsService walletMetricsService;

  DataRepairService(this.walletMetricsService);

  /// Gerçek nakit kuplajı (borç/yatırım/alacak) SADECE [CashMovementTags]
  /// sabitlerini `tag` olarak kullanır (bkz. wallet_metrics_service.dart
  /// `recordCashMovement` — tüm çağıranlar tek tek doğrulandı). Bu kümenin
  /// dışında bir tag'le `isSystem=true` olan kayıt, düzenli işlem onayının
  /// eski bir hatasından (bkz. `ApproveRecurringTransactionUsecase`) ya da
  /// CSV içe aktarmadan (bkz. `CsvService`) kalma yanlış kilitli bir
  /// kayıttır; güvenle kilidi açılabilir.
  static const _knownCashMovementTags = {
    CashMovementTags.debt,
    CashMovementTags.debtPayment,
    CashMovementTags.receivable,
    CashMovementTags.receivableCollection,
    CashMovementTags.investmentBuy,
    CashMovementTags.investmentSell,
    CashMovementTags.investmentCorrection,
    CashMovementTags.transfer,
  };

  /// Yanlışlıkla `isSystem=true` işaretlenmiş işlemleri onarır. Bakiyeyi
  /// etkilemez (`syncBalance` `isSystem` ayrımı yapmadan toplar), o yüzden
  /// resync gerekmez; wallet verisinden bağımsız çalışır.
  Future<void> _repairMislockedSystemTransactions() async {
    final box = await _box<TransactionModel>('transactions');
    for (final key in box.keys.toList()) {
      final t = box.get(key);
      if (t == null) continue;
      if (t.isSystem && !_knownCashMovementTags.contains(t.tag)) {
        await box.put(key, t.copyWith(isSystem: false));
        debugPrint(
            'DataRepair: transactions[$key] isSystem=false (tag: ${t.tag})');
      }
    }
  }

  Future<void> run() async {
    try {
      await _repairMislockedSystemTransactions();

      final walletBox = await _box<WalletModel>('wallets');
      final walletUserIds = <String, String>{
        for (final w in walletBox.values)
          if (w.id != null) w.id!: w.userId,
      };
      if (walletUserIds.isEmpty) return;

      final touched = <String>{};

      Future<void> repairBox<T>(
        String boxName,
        ({dynamic key, String userId, String walletId}) Function(
                dynamic key, T m)
            describe,
        T Function(T m, String userId) rewrite,
      ) async {
        final box = await _box<T>(boxName);
        final records = [
          for (final key in box.keys) describe(key, box.get(key) as T),
        ];
        final repairs = planUserIdRepairs(
          walletUserIds: walletUserIds,
          records: records,
        );
        for (final r in repairs) {
          final model = box.get(r.key) as T;
          await box.put(r.key, rewrite(model, r.correctUserId));
          final walletId = describe(r.key, model).walletId;
          touched.add(walletId);
          debugPrint(
              'DataRepair: $boxName[${r.key}] userId → ${r.correctUserId}');
        }
      }

      await repairBox<TransactionModel>(
        'transactions',
        (k, m) => (key: k, userId: m.userId, walletId: m.walletId),
        (m, uid) => m.copyWith(userId: uid),
      );
      await repairBox<DebtModel>(
        'debts',
        (k, m) => (key: k, userId: m.userId, walletId: m.walletId),
        (m, uid) => m.copyWith(userId: uid),
      );
      await repairBox<ReceivableModel>(
        'receivables',
        (k, m) => (key: k, userId: m.userId, walletId: m.walletId),
        (m, uid) => m.copyWith(userId: uid),
      );
      await repairBox<InvestmentModel>(
        'investments_box',
        (k, m) => (key: k, userId: m.userId, walletId: m.walletId),
        (m, uid) => m.copyWith(userId: uid),
      );

      for (final walletId in touched) {
        await walletMetricsService.syncBalance(walletId);
        await walletMetricsService.syncDebt(walletId);
        await walletMetricsService.syncCredit(walletId);
        await walletMetricsService.syncInvestment(walletId);
      }
    } catch (e, st) {
      debugPrint('DataRepairService başarısız (açılış engellenmedi): $e\n$st');
    }
  }

  Future<Box<T>> _box<T>(String name) async {
    if (Hive.isBoxOpen(name)) return Hive.box<T>(name);
    return Hive.openBox<T>(name);
  }
}
