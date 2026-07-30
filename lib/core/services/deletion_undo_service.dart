import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:cunehat/core/services/receipt_storage_service.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/repositories/transaction_repository.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';

/// Bir silmeyi geri almak için gereken tam bilgi.
///
/// Silme "şimdi yap, geri alınırsa eski hale döndür" modelini kullanır
/// (ertelenmiş silme değil): bakiye ve metrikler defterden türediği için
/// yeniden yazım birebir eski durumu verir, oysa ertelenmiş silme 6 saniye
/// boyunca UI ile defteri birbirinden ayırırdı.
/// Equatable: bloc durumlarının içinde taşındığı için (bkz.
/// `TransactionActionSuccess.undo`) durum karşılaştırmaları kimlik değil
/// değer üzerinden çalışmalı.
sealed class DeletionUndo extends Equatable {
  final String userId;
  final String walletId;

  /// Silme sırasında deftere yazılan TERS nakit kayıtlarının kimlikleri.
  /// Geri alma bunları siler; aksi hâlde kayıt geri gelir ama nakit etkisi
  /// iki kez sayılır.
  final List<String> reversalTransactionIds;

  const DeletionUndo({
    required this.userId,
    required this.walletId,
    this.reversalTransactionIds = const <String>[],
  });
}

final class TransactionDeletionUndo extends DeletionUndo {
  final TransactionEntity transaction;

  const TransactionDeletionUndo({
    required this.transaction,
    required super.userId,
    required super.walletId,
  });

  @override
  List<Object?> get props => [transaction, userId, walletId];
}

final class DebtDeletionUndo extends DeletionUndo {
  final DebtEntity debt;

  const DebtDeletionUndo({
    required this.debt,
    required super.userId,
    required super.walletId,
    required super.reversalTransactionIds,
  });

  @override
  List<Object?> get props => [debt, userId, walletId, reversalTransactionIds];
}

final class ReceivableDeletionUndo extends DeletionUndo {
  final ReceivableEntity receivable;

  const ReceivableDeletionUndo({
    required this.receivable,
    required super.userId,
    required super.walletId,
    required super.reversalTransactionIds,
  });

  @override
  List<Object?> get props =>
      [receivable, userId, walletId, reversalTransactionIds];
}

final class InvestmentDeletionUndo extends DeletionUndo {
  final InvestmentEntity investment;

  const InvestmentDeletionUndo({
    required this.investment,
    required super.userId,
    required super.walletId,
    required super.reversalTransactionIds,
  });

  @override
  List<Object?> get props =>
      [investment, userId, walletId, reversalTransactionIds];
}

/// Silinen kaydı geri yazar ve geri alma penceresi kapanınca kalıcı yan
/// etkileri uygular.
///
/// Neden bloc değil de servis: silme bloc'ları `factory` kayıtlı ve sayfaya
/// bağlı yaşıyor (bkz. injection.config.dart). Kullanıcı silip sayfadan
/// çıktığında snackbar hâlâ ekranda olur; geri alma o kapanmış bloc'a event
/// atmaya dayanırsa sessizce hiçbir şey yapmaz. Bu servis lazySingleton'dır
/// ve doğrudan usecase/repo katmanıyla konuşur.
///
/// Geri yazımın `Add*UseCase` üzerinden yapılması ZORUNLU (bloc'un
/// `Add*Event`'i değil): usecase'ler verilen `id`'yi korur ve nakit kuplajı
/// YAPMAZ. Bloc event'i kullanılsa oluşturma kuplajı bir kez daha yazılır ve
/// defter kalıcı olarak bozulurdu.
@lazySingleton
class DeletionUndoService {
  final AddTransactionUseCase _addTransaction;
  final AddDebtUseCase _addDebt;
  final AddReceivableUseCase _addReceivable;
  final AddInvestmentUseCase _addInvestment;
  final TransactionsRepository _transactionsRepository;
  final WalletMetricsService _walletMetrics;
  final TransactionsChangedNotifier _notifier;
  final ReceiptStorageService _receiptStorage;

  DeletionUndoService(
    this._addTransaction,
    this._addDebt,
    this._addReceivable,
    this._addInvestment,
    this._transactionsRepository,
    this._walletMetrics,
    this._notifier,
    this._receiptStorage,
  );

  /// Kaydı geri yazar. Hiçbir zaman fırlatmaz; `false` → geri alma kısmen ya
  /// da tamamen başarısız (çağıran kullanıcıyı uyarmalı).
  Future<bool> restore(DeletionUndo undo) async {
    try {
      // 1) Ters kayıtları temizle. Kayıt geri gelmeden önce yapılır ki
      // ardından tek bir metrik senkronu her ikisini birlikte görsün.
      var ok = true;
      for (final id in undo.reversalTransactionIds) {
        final result = await _transactionsRepository.deleteTransaction(id);
        ok = result.fold((failure) {
          debugPrint('Geri alma: ters kayıt silinemedi: ${failure.message}');
          return false;
        }, (_) => ok);
      }

      // 2) Kaydın kendisini aynı kimlikle geri yaz.
      ok = await _restoreEntity(undo) && ok;

      // 3) Metrikleri defterden yeniden türet.
      ok = await _walletMetrics.syncBalance(undo.walletId) && ok;
      await _syncOwnMetric(undo);

      _notifier.notify(userId: undo.userId, walletId: undo.walletId);
      return ok;
    } catch (e, st) {
      debugPrint('DeletionUndoService.restore hatası: $e\n$st');
      return false;
    }
  }

  /// Geri alma penceresi kapandı: silme artık kalıcı, geri alınamaz yan
  /// etkiler şimdi uygulanır.
  ///
  /// Fiş görselinin diskten silinmesi silme anında YAPILMAZ, buraya bırakılır:
  /// unlink tek yönlüdür, geri alınan bir işlem eki kopmuş halde geri dönerdi.
  Future<void> commit(DeletionUndo undo) async {
    if (undo is! TransactionDeletionUndo) return;
    final receipt = undo.transaction.receiptFileName;
    if (receipt == null) return;
    try {
      await _receiptStorage.delete(receipt);
    } catch (e) {
      // Yörünge temizliği asıl silmeyi etkilemez; öksüz dosya kalması
      // kullanıcıya görünmez ve tam geri yüklemede budanır.
      debugPrint('Geri alma penceresi kapandı, fiş silinemedi: $e');
    }
  }

  Future<bool> _restoreEntity(DeletionUndo undo) async {
    final result = switch (undo) {
      TransactionDeletionUndo(:final transaction) =>
        await _addTransaction(transaction),
      DebtDeletionUndo(:final debt) => await _addDebt(debt),
      ReceivableDeletionUndo(:final receivable) =>
        await _addReceivable(receivable),
      InvestmentDeletionUndo(:final investment) =>
        await _addInvestment(investment),
    };

    return result.fold((failure) {
      debugPrint('Geri alma: kayıt geri yazılamadı: ${failure.message}');
      return false;
    }, (_) => true);
  }

  /// Kayda özgü cüzdan metriği (`debt`/`credit`/`investment`). Bakiye zaten
  /// [restore] içinde senkronlanır; işlem silmede ek metrik yok.
  Future<void> _syncOwnMetric(DeletionUndo undo) async {
    try {
      switch (undo) {
        case TransactionDeletionUndo():
          break;
        case DebtDeletionUndo():
          await _walletMetrics.syncDebt(undo.walletId);
        case ReceivableDeletionUndo():
          await _walletMetrics.syncCredit(undo.walletId);
        case InvestmentDeletionUndo():
          await _walletMetrics.syncInvestment(undo.walletId);
      }
    } catch (e) {
      debugPrint('Geri alma: metrik senkronu başarısız: $e');
    }
  }
}
