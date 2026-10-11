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
        'İşlemler yüklenirken hata oluştu: ${failure.message}',
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
        'İşlem eklenirken hata oluştu: ${failure.message}',
        transactions: currentData,
      )),
      (newId) async {
        final synced = await _safeSyncBalance(event.transaction.walletId);

        emit(TransactionActionSuccess(
          '${event.transaction.title} başarıyla eklendi',
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
          '${first.title} başarıyla eklendi',
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
        'İşlem eklenirken hata oluştu: $failure',
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
        'Sistem işlemi; ilgili kayıttan yönetilir',
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
        'Bu kayıt başka bir kayda bağlı; cüzdanı değiştirilemez',
        transactions: currentData,
      ));
      return;
    }

    final result = await updateTransactionUseCase(updated);

    await result.fold(
      (failure) async => emit(TransactionError(
        'İşlem güncellenirken hata oluştu: ${failure.message}',
        transactions: currentData,
      )),
      (_) async {
        var synced = await _safeSyncBalance(updated.walletId);
        if (moved) {
          synced = await _safeSyncBalance(previous.walletId) && synced;
        }

        emit(TransactionActionSuccess(
          moved
              ? '${updated.title} diğer cüzdana taşındı'
              : '${updated.title} başarıyla güncellendi',
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

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;

    // 1. Get transaction before deleting
    final getResult = await getTransactionByIdUseCase(event.transactionId);

    await getResult.fold(
      (failure) async => emit(TransactionError(
        'İşlem bulunamadı: ${failure.message}',
        transactions: currentData,
      )),
      (transaction) async {
        // Savunma: sistem işlemi silinemez (kuplaj kayıtla yönetilir).
        if (transaction.isSystem) {
          emit(TransactionError(
            'Sistem işlemi; ilgili kayıttan yönetilir',
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
            'İşlem silinirken hata oluştu: ${failure.message}',
            transactions: currentData,
          )),
          (_) async {
            final synced = await _safeSyncBalance(transaction.walletId);

            // 3 Başarılı
            emit(TransactionActionSuccess(
              "${transaction.title} silindi",
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
      final result =
          await deleteTransactionUseCase(id, keepReceiptFile: true);
      result.fold((f) => failure ??= f.message, (_) => deleted.add(t));
    }
    if (deleted.isEmpty) {
      emit(TransactionError(
        'İşlemler silinemedi${failure == null ? '' : ': $failure'}',
        transactions: currentData,
      ));
      return;
    }
    final first = deleted.first;
    final synced = await _safeSyncBalance(first.walletId);
    final ids = {for (final t in deleted) t.id};
    emit(TransactionActionSuccess(
      '${event.label ?? first.title}: ${deleted.length} işlem silindi',
      transactions: currentData.where((t) => !ids.contains(t.id)).toList(),
      warning: failure != null
          ? 'Bazı işlemler silinemedi: $failure'
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

  static const _syncWarning =
      'Bakiye senkronizasyonu başarısız; cüzdan ekranına dönüp tekrar deneyin.';

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
