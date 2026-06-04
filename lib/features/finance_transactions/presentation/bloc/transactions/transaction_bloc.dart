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

  TransactionBloc({
    required this.getTransactionsGroupedUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.getTransactionByIdUseCase,
    required this.walletMetricsService,
  }) : super(TransactionLoading()) {
    on<GetTransactionsEvent>(_onLoadTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    GetTransactionsEvent event,
    Emitter<TransactionState> emit,
  ) async {
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
        await _safeApplyBalanceDelta(
          walletId: event.transaction.walletId,
          delta: _signedAmount(event.transaction),
        );

        emit(TransactionActionSuccess(
          '${event.transaction.title} başarıyla eklendi',
          transactions: currentData,
        ));
      },
    );
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    final currentData = state.currentTransactions;
    final result = await updateTransactionUseCase(event.newTransaction);

    await result.fold(
      (failure) async => emit(TransactionError(
        'İşlem güncellenirken hata oluştu: ${failure.message}',
        transactions: currentData,
      )),
      (_) async {
        await _safeApplyBalanceDelta(
          walletId: event.newTransaction.walletId,
          delta: _signedAmount(event.newTransaction) -
              _signedAmount(event.previousTransaction),
        );

        emit(TransactionActionSuccess(
          '${event.newTransaction.title} başarıyla güncellendi',
          transactions: currentData,
        ));
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
        // 2. Delete from database
        final deleteResult =
            await deleteTransactionUseCase(event.transactionId);

        await deleteResult.fold(
          (failure) async => emit(TransactionError(
            'İşlem silinirken hata oluştu: ${failure.message}',
            transactions: currentData,
          )),
          (_) async {
            await _safeApplyBalanceDelta(
              walletId: transaction.walletId,
              delta: -_signedAmount(transaction),
            );

            // 3 Başarılı
            emit(TransactionActionSuccess(
              "${transaction.title} silindi",
              transactions: currentData,
            ));
          },
        );
      },
    );
  }

  double _signedAmount(TransactionEntity transaction) {
    return transaction.isIncome ? transaction.amount : -transaction.amount;
  }

  Future<void> _safeApplyBalanceDelta({
    required String walletId,
    required double delta,
  }) async {
    try {
      await walletMetricsService.applyBalanceDelta(
        walletId: walletId,
        delta: delta,
      );
    } catch (e) {
      debugPrint('Wallet balance sync failed: $e');
    }
  }
}
