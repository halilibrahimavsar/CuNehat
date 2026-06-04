// lib/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart

import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';

part 'receivable_event.dart';
part 'receivable_state.dart';

@injectable
class ReceivableBloc extends Bloc<ReceivableEvent, ReceivableState> {
  final GetReceivablesUseCase getReceivablesUseCase;
  final AddReceivableUseCase addReceivableUseCase;
  final UpdateReceivableUseCase updateReceivableUseCase;
  final DeleteReceivableUseCase deleteReceivableUseCase;
  final WalletMetricsService walletMetricsService;

  ReceivableBloc({
    required this.getReceivablesUseCase,
    required this.addReceivableUseCase,
    required this.updateReceivableUseCase,
    required this.deleteReceivableUseCase,
    required this.walletMetricsService,
  }) : super(ReceivableInitial()) {
    on<GetReceivablesEvent>(_onGetReceivables);
    on<AddReceivableEvent>(_onAddReceivable);
    on<UpdateReceivableEvent>(_onUpdateReceivable);
    on<DeleteReceivableEvent>(_onDeleteReceivable);
    on<MarkReceivableAsPaidEvent>(_onMarkAsPaid);
  }

  Future<void> _onGetReceivables(
      GetReceivablesEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final result = await getReceivablesUseCase(event.walletId);
    result.fold(
      (failure) => emit(ReceivableError(failure.message)),
      (receivables) => emit(ReceivableLoaded(receivables)),
    );
  }

  Future<void> _onAddReceivable(
      AddReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final result = await addReceivableUseCase(event.receivable);

    await result.fold(
      (failure) async => emit(ReceivableError(failure.message)),
      (_) async {
        // Nakit kuplajı: alacak verildi (para çıktı) → tutar kadar gider.
        await walletMetricsService.recordCashMovement(
          walletId: event.receivable.walletId,
          userId: event.receivable.userId,
          amount: event.receivable.amount,
          isIncome: false,
          title: event.receivable.debtorName,
          tag: CashMovementTags.receivable,
        );
        await _safeSyncCredit(event.receivable.walletId);

        emit(const ReceivableOperationSuccess("Alacak başarıyla eklendi."));
        add(GetReceivablesEvent(event.receivable.walletId));
      },
    );
  }

  Future<void> _onUpdateReceivable(
      UpdateReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final result = await updateReceivableUseCase(event.receivable);

    await result.fold(
      (failure) async => emit(ReceivableError(failure.message)),
      (_) async {
        // Mutabakat: yalnız tahsil edilmemiş alacakta tutar değişimi nakde yansır.
        if (!event.receivable.isPaid) {
          final diff = event.receivable.amount - event.prevAmount;
          if (diff != 0) {
            await walletMetricsService.recordCashMovement(
              walletId: event.receivable.walletId,
              userId: event.receivable.userId,
              amount: diff.abs(),
              isIncome: diff < 0, // daha çok verildi → gider; azaldı → gelir
              title: 'Alacak güncellendi: ${event.receivable.debtorName}',
              tag: CashMovementTags.receivable,
            );
          }
        }
        await _safeSyncCredit(event.receivable.walletId);

        emit(const ReceivableOperationSuccess("Alacak güncellendi."));
        add(GetReceivablesEvent(event.receivable.walletId));
      },
    );
  }

  Future<void> _onDeleteReceivable(
      DeleteReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final result = await deleteReceivableUseCase(event.id);

    await result.fold(
      (failure) async => emit(ReceivableError(failure.message)),
      (_) async {
        // Mutabakat: tahsil edilmemiş alacak silinince verilen para geri döner (gelir).
        if (!event.isPaid && event.amount != 0) {
          await walletMetricsService.recordCashMovement(
            walletId: event.walletId,
            userId: event.userId,
            amount: event.amount,
            isIncome: true,
            title: 'Alacak silindi',
            tag: CashMovementTags.receivable,
          );
        }
        await _safeSyncCredit(event.walletId);

        emit(const ReceivableOperationSuccess("Alacak silindi."));
        add(GetReceivablesEvent(event.walletId));
      },
    );
  }

  /// Alacak ödendiğinde işaretle
  Future<void> _onMarkAsPaid(
      MarkReceivableAsPaidEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());
    final updatedReceivable = event.receivable.copyWith(isPaid: true);
    final result = await updateReceivableUseCase(updatedReceivable);

    await result.fold(
      (failure) async => emit(ReceivableError(failure.message)),
      (_) async {
        // Nakit kuplajı: alacak tahsil edildi (para girdi) → tutar kadar gelir.
        await walletMetricsService.recordCashMovement(
          walletId: event.receivable.walletId,
          userId: event.receivable.userId,
          amount: event.receivable.amount,
          isIncome: true,
          title: 'Tahsilat: ${event.receivable.debtorName}',
          tag: CashMovementTags.receivableCollection,
        );
        await _safeSyncCredit(event.receivable.walletId);

        emit(const ReceivableOperationSuccess(
            "Alacak ödendi olarak işaretlendi."));
        add(GetReceivablesEvent(event.receivable.walletId));
      },
    );
  }

  Future<void> _safeSyncCredit(String walletId) async {
    try {
      await walletMetricsService.syncCredit(walletId);
    } catch (e) {
      debugPrint('Wallet credit sync failed: $e');
    }
  }
}
