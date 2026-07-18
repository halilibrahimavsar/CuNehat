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
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);

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
      (_) async {
        final synced = await _safeSyncBalance(event.transaction.walletId);

        emit(TransactionActionSuccess(
          '${event.transaction.title} başarıyla eklendi',
          transactions: currentData,
          warning: synced ? null : _syncWarning,
        ));
        transactionsChangedNotifier.notify(
          userId: event.transaction.userId,
          walletId: event.transaction.walletId,
        );
      },
    );
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

    final result = await updateTransactionUseCase(event.newTransaction);

    await result.fold(
      (failure) async => emit(TransactionError(
        'İşlem güncellenirken hata oluştu: ${failure.message}',
        transactions: currentData,
      )),
      (_) async {
        final synced = await _safeSyncBalance(event.newTransaction.walletId);

        emit(TransactionActionSuccess(
          '${event.newTransaction.title} başarıyla güncellendi',
          transactions: currentData,
          warning: synced ? null : _syncWarning,
        ));
        transactionsChangedNotifier.notify(
          userId: event.newTransaction.userId,
          walletId: event.newTransaction.walletId,
        );
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

        // 2. Delete from database
        final deleteResult =
            await deleteTransactionUseCase(event.transactionId);

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
              transactions: currentData,
              warning: synced ? null : _syncWarning,
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
