// lib/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/services/recurring_occurrences.dart';
import '../../domain/usecases/get_pending_recurring_transactions_usecase.dart';
import '../../domain/usecases/approve_recurring_transaction_usecase.dart';
import '../../domain/usecases/delete_recurring_transaction_usecase.dart';
import '../../domain/usecases/skip_recurring_transaction_usecase.dart';
import 'pending_recurring_event.dart';
import 'pending_recurring_state.dart';

@injectable
class PendingRecurringBloc
    extends Bloc<PendingRecurringEvent, PendingRecurringState> {
  final GetPendingRecurringTransactionsUsecase getPendingUsecase;
  final ApproveRecurringTransactionUsecase approveUsecase;
  final DeleteRecurringTransactionUsecase deleteUsecase;
  final SkipRecurringTransactionUsecase skipUsecase;
  final WalletMetricsService walletMetricsService;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  /// İşlemi süren şablonlar. Bloc'un varsayılan olay dönüştürücüsü
  /// eşzamanlıdır (flatMap): "Onayla"ya hızlı iki dokunuş iki ayrı onay
  /// akışı başlatıp AYNI vade için İKİ gerçek işlem yaratıyordu.
  final Set<String> _inFlight = <String>{};

  PendingRecurringBloc(
    this.getPendingUsecase,
    this.approveUsecase,
    this.deleteUsecase,
    this.skipUsecase,
    this.walletMetricsService,
    this.transactionsChangedNotifier,
  ) : super(PendingRecurringInitial()) {
    on<LoadPendingTransactionsEvent>(_onLoadPendingTransactions);
    on<ApproveTransactionEvent>(_onApproveTransaction);
    on<ApproveAllOccurrencesEvent>(_onApproveAllOccurrences);
    on<SkipTransactionEvent>(_onSkipTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);
  }

  Future<void> _onLoadPendingTransactions(
    LoadPendingTransactionsEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    emit(PendingRecurringLoading());
    final result = await getPendingUsecase();

    result.fold(
      (failure) => emit(PendingRecurringFailure(failure)),
      (transactions) => emit(
        PendingRecurringLoaded(transactions, forceShow: event.forceShow),
      ),
    );
  }

  Future<void> _onApproveTransaction(
    ApproveTransactionEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    if (!_inFlight.add(event.template.id)) return;
    _emitBusy(emit);
    try {
      final result = await approveUsecase(
        event.template,
        overrideAmount: event.overrideAmount,
      );

      await result.fold(
        (failure) async => emit(PendingRecurringFailure(failure)),
        (_) async => _afterLedgerChange(event.template),
      );
    } finally {
      _inFlight.remove(event.template.id);
    }
  }

  /// Birikmiş tüm vadeleri sırayla işler. Onay tek seferde bir vade
  /// ilerlettiği için 30 günlük birikim aksi halde 30 dokunuş isterdi.
  Future<void> _onApproveAllOccurrences(
    ApproveAllOccurrencesEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    if (!_inFlight.add(event.template.id)) return;
    _emitBusy(emit);
    try {
      final now = DateTime.now();
      var current = event.template;
      var processed = 0;

      while (!current.nextExecutionDate.isAfter(now) &&
          processed < RecurringOccurrences.maxBacklog) {
        final result = await approveUsecase(current);
        final failure = result.fold((f) => f, (_) => null);
        if (failure != null) {
          emit(PendingRecurringFailure(failure));
          return;
        }
        processed++;
        current = current.copyWith(
          nextExecutionDate:
              ApproveRecurringTransactionUsecase.nextExecutionDateAfter(
            current.nextExecutionDate,
            current.frequency,
          ),
        );
      }

      if (processed > 0) {
        await _afterLedgerChange(event.template);
      }
    } finally {
      _inFlight.remove(event.template.id);
    }
  }

  Future<void> _onSkipTransaction(
    SkipTransactionEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    if (!_inFlight.add(event.template.id)) return;
    _emitBusy(emit);
    try {
      final result = await skipUsecase(event.template);
      result.fold(
        (failure) => emit(PendingRecurringFailure(failure)),
        // İşlem yaratılmadığı için bakiye/defter değişmez; sadece listeyi tazele
        (_) => add(const LoadPendingTransactionsEvent()),
      );
    } finally {
      _inFlight.remove(event.template.id);
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransactionEvent event,
    Emitter<PendingRecurringState> emit,
  ) async {
    if (!_inFlight.add(event.id)) return;
    _emitBusy(emit);
    try {
      final result = await deleteUsecase(event.id);
      result.fold(
        (failure) => emit(PendingRecurringFailure(failure)),
        (_) => add(const LoadPendingTransactionsEvent()),
      );
    } finally {
      _inFlight.remove(event.id);
    }
  }

  /// Onay sonrası ortak kuyruk: işlem TransactionBloc yolunun dışında
  /// eklendiğinden bakiyenin defterden yeniden hesaplanması ve açık
  /// liste/grafik/bütçe ekranlarının haberdar edilmesi burada tetiklenir.
  ///
  /// Bildirime cüzdan bağlamı geçilir; bağlamsız `notify()` çağrısında
  /// bütçe uyarı monitörü atlıyor, yani onaylanan düzenli gider bütçeyi
  /// aşırsa uyarı çıkmıyordu.
  Future<void> _afterLedgerChange(RecurringTransactionEntity template) async {
    await walletMetricsService.syncBalance(template.walletId);
    transactionsChangedNotifier.notify(
      userId: template.userId,
      walletId: template.walletId,
    );
    add(const LoadPendingTransactionsEvent());
  }

  void _emitBusy(Emitter<PendingRecurringState> emit) {
    final current = state;
    if (current is! PendingRecurringLoaded) return;
    emit(current.copyWith(busyTemplateIds: Set<String>.of(_inFlight)));
  }
}
