import 'package:cunehat/core/l10n/app_strings.dart';
import 'dart:async';

import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transactions/transaction_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';

@injectable
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsGroupedUseCase getTransactionsGroupedUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetTransactionByIdUseCase getTransactionByIdUseCase;
  final WalletMetricsService walletMetricsService;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  /// Defter değiştiğinde aynı sorguyu yenileyebilmek için son yükleme eventi.
  GetTransactionsEvent? _lastQuery;
  StreamSubscription<TransactionsChange>? _changedSubscription;

  TransactionBloc({
    required this.getTransactionsGroupedUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.getTransactionByIdUseCase,
    required this.walletMetricsService,
    required this.transactionsChangedNotifier,
  }) : super(TransactionLoading()) {
    on<GetTransactionsEvent>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<AddTransactionsEvent>(_onAddTransactions);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<ChangeTransactionsCategoryEvent>(_onChangeCategory);
    on<UpdateTransactionsEvent>(_onUpdateTransactions);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
    on<DeleteTransactionsEvent>(_onDeleteTransactions);

    // Defter başka bir yerden değişirse (diğer bloc örneği, recurring onayı,
    // import) açık listeyi/grafiği aynı sorguyla tazele.
    _changedSubscription = transactionsChangedNotifier.stream.listen((_) {
      final last = _lastQuery;
      if (last != null) add(last);
    });
  }

  @override
  Future<void> close() {
    _changedSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadTransactions(
    GetTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    _lastQuery = event;

    // Mevcut veriyi koruyarak loading durumuna geç
    emit(TransactionLoading(previousTransactions: state.currentTransactions));

    final result = await getTransactionsGroupedUseCase(
      GetTransactionsGroupedParams(
        userId: event.userId,
        walletId: event.walletId,
        startDate: event.startDate,
        endDate: event.endDate,
        type: event.type,
      ),
    );

    result.fold(
      (failure) => emit(TransactionError(
        appStrings.blocMsgTxLoadFailed(failure.message),
        transactions: state.currentTransactions,
      )),
      (transactions) {
        final List<TransactionEntity> allTransactions =
            transactions.values.expand((group) => group).toList();

        emit(TransactionLoaded(
          groupedTransactions: transactions,
          allTransactions: allTransactions,
        ));
      },
    );
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;

    final result = await addTransactionUseCase(
        event.transaction); // Usecase ID'yi halleder.

    await result.fold(
      (failure) async => emit(TransactionError(
        appStrings.blocMsgTxAddFailed(failure.message),
        transactions: currentData,
      )),
      (newId) async {
        final synced = await _safeSyncBalance(event.transaction.walletId);

        emit(TransactionActionSuccess(
          appStrings.blocMsgTxAdded(event.transaction.title),
          transactions: [
            ...currentData,
            event.transaction.copyWith(id: newId),
          ],
          warning: synced ? null : _syncWarning,
        ));
        transactionsChangedNotifier.notify(
          userId: event.transaction.userId,
          walletId: event.transaction.walletId,
        );
      },
    );
  }

  /// Taksitler: her satır yazılır, bakiye BİR kez türetilir, dinleyiciler
  /// BİR kez uyarılır (içe aktarım deseni). Bir satır yazılamazsa
  /// yazılabilenler kalır — bakiye defterden türediği için tutarlıdır — ve
  /// hata bildirilir.
  Future<void> _onAddTransactions(
    AddTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    if (event.transactions.isEmpty) return;
    final currentData = state.currentTransactions;
    final added = <TransactionEntity>[];
    String? failure;
    for (final t in event.transactions) {
      final result = await addTransactionUseCase(t);
      result.fold(
        (f) => failure ??= f.message,
        (newId) => added.add(t.copyWith(id: newId)),
      );
    }
    final first = event.transactions.first;
    if (added.isNotEmpty) {
      final synced = await _safeSyncBalance(first.walletId);
      if (failure == null) {
        emit(TransactionActionSuccess(
          appStrings.blocMsgTxAdded(first.title),
          transactions: [...currentData, ...added],
          warning: synced ? null : _syncWarning,
        ));
      }
      transactionsChangedNotifier.notify(
        userId: first.userId,
        walletId: first.walletId,
      );
    }
    if (failure != null) {
      emit(TransactionError(
        appStrings.blocMsgTxAddFailed('$failure'),
        transactions: [...currentData, ...added],
      ));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;

    // Savunma: sistem işlemleri (borç/yatırım kuplajı) bloc üzerinden
    // değiştirilemez; defterle desync olmasın.
    if (event.newTransaction.isSystem || event.previousTransaction.isSystem) {
      emit(TransactionError(
        appStrings.blocMsgTxSystemLocked,
        transactions: currentData,
      ));
      return;
    }

    // Kayıt başka bir cüzdana TAŞINIYOR mu. Depolama tek kutudur (kimlikle
    // yazılır), bakiye ise her cüzdanın kendi defterinden türer: satır eski
    // cüzdanın defterinden çıkar, yenisine girer — İKİ bakiye de yeniden
    // türetilmek zorunda.
    final previous = event.previousTransaction;
    final updated = event.newTransaction;
    final moved = previous.walletId != updated.walletId;
    if (moved && !previous.canMoveWallet) {
      emit(TransactionError(
        appStrings.blocMsgTxMoveBlocked,
        transactions: currentData,
      ));
      return;
    }

    final result = await updateTransactionUseCase(updated);

    await result.fold(
      (failure) async => emit(TransactionError(
        appStrings.blocMsgTxUpdateFailed(failure.message),
        transactions: currentData,
      )),
      (_) async {
        var synced = await _safeSyncBalance(updated.walletId);
        if (moved) {
          synced = await _safeSyncBalance(previous.walletId) && synced;
        }

        emit(TransactionActionSuccess(
          moved
              ? appStrings.blocMsgTxMoved(updated.title)
              : appStrings.blocMsgTxUpdated(updated.title),
          transactions: [
            for (final t in currentData)
              // Taşınan satır bu defterin (eski cüzdanın) listesinden düşer.
              if (t.id != updated.id) t else if (!moved) updated,
          ],
          warning: synced ? null : _syncWarning,
        ));
        transactionsChangedNotifier.notify(
          userId: updated.userId,
          walletId: updated.walletId,
        );
        if (moved) {
          transactionsChangedNotifier.notify(
            userId: previous.userId,
            walletId: previous.walletId,
          );
        }
      },
    );
  }

  /// Toplu kategori değişimi: her satır yazılır, dinleyiciler cüzdan başına
  /// BİR kez uyarılır. Bir satır yazılamazsa yazılabilenler kalır ve hata
  /// bildirilir (taksit ekleme deseni).
  Future<void> _onChangeCategory(
    ChangeTransactionsCategoryEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;
    final targets = [
      for (final t in event.transactions)
        if (t.id != null &&
            !t.isSystem &&
            !t.isAdopted &&
            t.tag != event.categoryId)
          t,
    ];
    if (targets.isEmpty) return;

    final changed = <String, TransactionEntity>{};
    String? failure;
    for (final t in targets) {
      final next = t.copyWith(tag: event.categoryId);
      final result = await updateTransactionUseCase(next);
      result.fold(
        (f) => failure ??= f.message,
        (_) => changed[next.id!] = next,
      );
    }

    final after = [for (final t in currentData) changed[t.id] ?? t];
    if (changed.isNotEmpty) {
      emit(TransactionActionSuccess(
        appStrings.blocMsgTxCategoryChanged(changed.length),
        transactions: after,
      ));
      final wallets = <String>{};
      for (final t in changed.values) {
        if (wallets.add(t.walletId)) {
          transactionsChangedNotifier.notify(
            userId: t.userId,
            walletId: t.walletId,
          );
        }
      }
    }
    if (failure != null) {
      emit(TransactionError(
        appStrings.blocMsgTxCategoryChangePartial('$failure'),
        transactions: after,
      ));
    }
  }

  /// Toplu güncelleme (taksit grubu). Tutarlar değiştiği için bakiye
  /// yeniden türetilir — cüzdan başına BİR kez, satır başına değil.
  Future<void> _onUpdateTransactions(
    UpdateTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;
    final targets = [
      for (final t in event.transactions)
        if (t.id != null && !t.isSystem && !t.isAdopted) t,
    ];
    if (targets.isEmpty) return;

    final changed = <String, TransactionEntity>{};
    String? failure;
    for (final t in targets) {
      final result = await updateTransactionUseCase(t);
      result.fold(
        (f) => failure ??= f.message,
        (_) => changed[t.id!] = t,
      );
    }

    final after = [for (final t in currentData) changed[t.id] ?? t];
    if (changed.isNotEmpty) {
      final wallets = {for (final t in changed.values) t.walletId};
      var synced = true;
      for (final walletId in wallets) {
        synced = await _safeSyncBalance(walletId) && synced;
      }
      emit(TransactionActionSuccess(
        appStrings.blocMsgTxGroupUpdated(event.label, changed.length),
        transactions: after,
        warning: synced ? null : _syncWarning,
      ));
      final first = changed.values.first;
      for (final walletId in wallets) {
        transactionsChangedNotifier.notify(
          userId: first.userId,
          walletId: walletId,
        );
      }
    }
    if (failure != null) {
      emit(TransactionError(
        appStrings.blocMsgTxUpdateFailed('$failure'),
        transactions: after,
      ));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;

    // 1. Get transaction before deleting
    final getResult = await getTransactionByIdUseCase(event.transactionId);

    await getResult.fold(
      (failure) async => emit(TransactionError(
        appStrings.blocMsgTxNotFound(failure.message),
        transactions: currentData,
      )),
      (transaction) async {
        // Savunma: sistem işlemi silinemez (kuplaj kayıtla yönetilir).
        if (transaction.isSystem) {
          emit(TransactionError(
            appStrings.blocMsgTxSystemLocked,
            transactions: currentData,
          ));
          return;
        }

        // 2. Delete from database.
        //
        // Fiş görseli diskte BIRAKILIR: geri alma penceresi boyunca unlink
        // edilirse geri gelen işlemin eki kopmuş olur. Dosyayı silme
        // sorumluluğu DeletionUndoService.commit'e geçer.
        final deleteResult = await deleteTransactionUseCase(
          event.transactionId,
          keepReceiptFile: true,
        );

        await deleteResult.fold(
          (failure) async => emit(TransactionError(
            appStrings.blocMsgTxDeleteFailed(failure.message),
            transactions: currentData,
          )),
          (_) async {
            final synced = await _safeSyncBalance(transaction.walletId);

            // 3 Başarılı
            emit(TransactionActionSuccess(
              appStrings.blocMsgTxDeleted(transaction.title),
              transactions: currentData
                  .where((t) => t.id != event.transactionId)
                  .toList(),
              warning: synced ? null : _syncWarning,
              undo: TransactionDeletionUndo(
                transaction: transaction,
                userId: transaction.userId,
                walletId: transaction.walletId,
              ),
            ));
            transactionsChangedNotifier.notify(
              userId: transaction.userId,
              walletId: transaction.walletId,
            );
          },
        );
      },
    );
  }

  Future<void> _onDeleteTransactions(
    DeleteTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
    if (event.transactionIds.isEmpty) return;
    final currentData = state.currentTransactions;
    final deleted = <TransactionEntity>[];
    String? failure;
    for (final id in event.transactionIds) {
      final read = await getTransactionByIdUseCase(id);
      final t = read.fold((_) => null, (t) => t);
      // Sistem işlemi kayıttan yönetilir; okunamayan satır zaten yok.
      if (t == null || t.isSystem) continue;
      final result = await deleteTransactionUseCase(id, keepReceiptFile: true);
      result.fold((f) => failure ??= f.message, (_) => deleted.add(t));
    }
    if (deleted.isEmpty) {
      emit(TransactionError(
        failure == null
            ? appStrings.blocMsgTxBulkDeleteFailed
            : appStrings.blocMsgTxBulkDeleteFailedDetail('$failure'),
        transactions: currentData,
      ));
      return;
    }
    final first = deleted.first;
    final synced = await _safeSyncBalance(first.walletId);
    final ids = {for (final t in deleted) t.id};
    emit(TransactionActionSuccess(
      appStrings.blocMsgTxBulkDeleted(
          event.label ?? first.title, deleted.length),
      transactions: currentData.where((t) => !ids.contains(t.id)).toList(),
      warning: failure != null
          ? appStrings.blocMsgTxBulkDeletePartial('$failure')
          : (synced ? null : _syncWarning),
      undo: TransactionDeletionUndo(
        transaction: first,
        alsoRestore: deleted.skip(1).toList(),
        userId: first.userId,
        walletId: first.walletId,
      ),
    ));
    transactionsChangedNotifier.notify(
      userId: first.userId,
      walletId: first.walletId,
    );
  }

  static String get _syncWarning => appStrings.blocMsgTxSyncWarning;

  /// Bakiyeyi defterden yeniden hesaplar; asla fırlatmaz.
  /// `false` → işlem kaydedildi ama bakiye güncellenemedi (kullanıcı uyarılmalı).
  Future<bool> _safeSyncBalance(String walletId) async {
    try {
      return await walletMetricsService.syncBalance(walletId);
    } catch (e) {
      debugPrint('Wallet balance sync failed: $e');
      return false;
    }
  }
}
