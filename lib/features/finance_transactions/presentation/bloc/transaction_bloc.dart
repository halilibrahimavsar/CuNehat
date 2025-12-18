import 'package:cunehat/core/utils/error_handler.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/transactions_usecases.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/usecase_params.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_event.dart';
import 'package:cunehat/features/finance_transactions/presentation/bloc/transaction_state.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_balance_sync_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final GetTransactionsGroupedUseCase getTransactionsGroupedUseCase;
  final AddTransactionUseCase addTransactionUseCase;
  final UpdateTransactionUseCase updateTransactionUseCase;
  final DeleteTransactionUseCase deleteTransactionUseCase;
  final GetTransactionByIdUseCase getTransactionByIdUseCase;
  final WalletBalanceSyncUseCase walletSyncUseCase;

  TransactionBloc({
    required this.getTransactionsGroupedUseCase,
    required this.addTransactionUseCase,
    required this.updateTransactionUseCase,
    required this.deleteTransactionUseCase,
    required this.getTransactionByIdUseCase,
    required this.walletSyncUseCase,
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
    emit(TransactionLoading());

    try {
      final transactions = await getTransactionsGroupedUseCase(
        GetTransactionsGroupedParams(
          userId: event.userId,
          walletId: event.walletId,
          startDate: event.startDate,
          endDate: event.endDate,
          type: event.type,
        ),
      );

      final List<TransactionEntity> allTransactions =
          transactions.values.expand((group) => group).toList();

      emit(TransactionLoaded(
        groupedTransactions: transactions,
        allTransactions: allTransactions,
      ));
    } catch (e) {
      emit(TransactionError(
          'İşlemler yüklenirken hata oluştu: ${ErrorHandler.handleException(e).message}'));
    }
  }

  Future<void> _onAddTransaction(
    AddTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      // ID oluşturma sorumluluğu Usecase'de.
      // Usecase, ID'yi oluşturup entity'ye ekledikten sonra repoya gönderir.
      // Örnek: final entityWithId = event.transaction.copyWith(id: UidGenerator.generateWithUserId(event.transaction.userId));
      await addTransactionUseCase(event.transaction); // Usecase ID'yi halleder.
      await walletSyncUseCase.updateBalance(
        event.transaction.userId,
        event.transaction.isExpense,
        event.transaction.amount,
      );
      emit(TransactionActionSuccess(
          '${event.transaction.title} başarıyla eklendi'));
    } catch (e) {
      emit(TransactionError(
          'İşlem eklenirken hata oluştu: ${ErrorHandler.handleException(e).message}'));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      // 2. Update transaction in database
      await updateTransactionUseCase(event.transaction);
      await walletSyncUseCase.updateBalance(
        event.transaction.userId,
        event.transaction.isExpense,
        event.transaction.amount,
      );

      emit(TransactionActionSuccess(
          '${event.transaction.title} başarıyla güncellendi'));
    } catch (e) {
      emit(TransactionError(
          'İşlem güncellenirken hata oluştu: ${ErrorHandler.handleException(e).message}'));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<TransactionState> emit,
  ) async {
    try {
      // 1. Get transaction before deleting
      final transaction = await getTransactionByIdUseCase(event.transactionId);

      // 2. Delete from database
      await deleteTransactionUseCase(event.transactionId);

      // 3 Başarılı
      emit(TransactionActionSuccess("${transaction.title} silindi"));
    } catch (e) {
      emit(TransactionError(
          'İşlem silinirken hata oluştu: ${ErrorHandler.handleException(e).message}'));
    }
  }
}
