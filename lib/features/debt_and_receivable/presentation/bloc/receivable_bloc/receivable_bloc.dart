// lib/features/debt_and_receivable/presentation/bloc/receivable_bloc/receivable_bloc.dart

import 'dart:async';

import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/receivable_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/receivable_usecases.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:flutter/foundation.dart';

part 'receivable_event.dart';
part 'receivable_state.dart';

@injectable
class ReceivableBloc extends Bloc<ReceivableEvent, ReceivableState>
    with CashCouplingMixin {
  final GetReceivablesUseCase getReceivablesUseCase;
  final AddReceivableUseCase addReceivableUseCase;
  final UpdateReceivableUseCase updateReceivableUseCase;
  final DeleteReceivableUseCase deleteReceivableUseCase;
  final WalletMetricsService walletMetricsService;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  /// Defter dışarıdan değişince aynı listeyi tazelemek için son cüzdan.
  String? _lastWalletId;
  StreamSubscription<TransactionsChange>? _changedSubscription;

  ReceivableBloc({
    required this.getReceivablesUseCase,
    required this.addReceivableUseCase,
    required this.updateReceivableUseCase,
    required this.deleteReceivableUseCase,
    required this.walletMetricsService,
    required this.transactionsChangedNotifier,
  }) : super(ReceivableInitial()) {
    on<GetReceivablesEvent>(_onGetReceivables);
    on<AddReceivableEvent>(_onAddReceivable);
    on<UpdateReceivableEvent>(_onUpdateReceivable);
    on<DeleteReceivableEvent>(_onDeleteReceivable);
    on<MarkReceivableAsPaidEvent>(_onMarkAsPaid);

    // Alacak listesi defterin türevi: silme geri alındığında (bkz.
    // DeletionUndoService) liste kendi kendine tazelenmeli.
    _changedSubscription = transactionsChangedNotifier.stream.listen((_) {
      final walletId = _lastWalletId;
      if (walletId != null) add(GetReceivablesEvent(walletId));
    });
  }

  @override
  Future<void> close() {
    _changedSubscription?.cancel();
    return super.close();
  }

  Future<void> _onGetReceivables(
      GetReceivablesEvent event, Emitter<ReceivableState> emit) async {
    _lastWalletId = event.walletId;
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
        final cashOk = await walletMetricsService.recordCashMovement(
          walletId: event.receivable.walletId,
          userId: event.receivable.userId,
          amount: event.receivable.amount,
          isIncome: false,
          title: event.receivable.debtorName,
          tag: CashMovementTags.receivable,
          // Silmedeki ters kayıt da `createdAt`e yazılır; bugüne düşerse iki
          // bacak farklı dönemlere dağılır.
          date: event.receivable.createdAt,
        );
        await _safeSyncCredit(event.receivable.walletId);

        emit(ReceivableOperationSuccess(
            'Alacak başarıyla eklendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
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
        // Mutabakat: tutar değişimi her hâlükârda deftere yansır.
        //
        // Eskiden tahsil edilmiş alacakta (isPaid) kuplaj TAMAMEN atlanıyordu:
        // 1.000 ₺'lik tahsil edilmiş bir alacak 1.500 ₺'ye çıkarılınca defter
        // hâlâ -1.000/+1.000 gösteriyor, alacak ise 1.500 diyordu. Tahsil
        // edilmişte para hem verilmiş hem geri alınmış olduğundan net etki
        // sıfırdır → iki bacak da yazılır ve defter kalemle tutarlı kalır.
        var cashOk = true;
        final diff = event.receivable.amount - event.prevAmount;
        if (diff != 0) {
          final cashResult = await walletMetricsService.recordCashMovements(
            walletId: event.receivable.walletId,
            entries: [
              CashMovement(
                userId: event.receivable.userId,
                amount: diff.abs(),
                isIncome: diff < 0, // daha çok verildi → gider; azaldı → gelir
                title: 'Alacak güncellendi: ${event.receivable.debtorName}',
                tag: CashMovementTags.receivable,
                date: event.receivable.createdAt,
              ),
              // Tahsil edilmişse tahsilat bacağı da aynı farkla düzeltilir;
              // net etki sıfır kalır ama iki kayıt da gerçek tutarı gösterir.
              // Düzeltme TAHSİLAT tarihine yazılır: bugüne düşerse "net etki
              // sıfır" yalnız bakiye için doğru olur, alacak ayının gideri
              // şişer ve bugünün ayına yoktan bir gelir belirirdi.
              if (event.receivable.isPaid)
                CashMovement(
                  userId: event.receivable.userId,
                  amount: diff.abs(),
                  isIncome: diff > 0,
                  title: 'Tahsilat düzeltmesi: ${event.receivable.debtorName}',
                  tag: CashMovementTags.receivableCollection,
                  date: event.receivable.collectedAt,
                ),
            ],
          );
          cashOk = cashResult.ok;
        }
        await _safeSyncCredit(event.receivable.walletId);

        emit(ReceivableOperationSuccess(
            'Alacak güncellendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetReceivablesEvent(event.receivable.walletId));
      },
    );
  }

  Future<void> _onDeleteReceivable(
      DeleteReceivableEvent event, Emitter<ReceivableState> emit) async {
    emit(ReceivableLoading());

    // Geri alma kaydın tamamını ister (tahsilat durumu, vade, notlar…);
    // silmeden önce defterdeki hali okunur.
    final snapshot = await _receivableSnapshot(event.walletId, event.id);

    final result = await deleteReceivableUseCase(event.id);

    await result.fold(
      (failure) async => emit(ReceivableError(failure.message)),
      (_) async {
        // Mutabakat: tahsil edilmemiş alacak silinince verilen para geri döner.
        // Ters kayıt paranın ÇIKTIĞI tarihe yazılır (bugüne değil): aksi hâlde
        // bakiye doğru çıksa bile o ayın gider toplamı şişik kalırdı.
        // Tahsil edilmişte defter zaten -tutar/+tutar ile sıfırlanmıştır.
        var cashResult = const CashWriteResult(ok: true);
        if (!event.isPaid && event.amount != 0) {
          cashResult = await walletMetricsService.recordCashMovements(
            walletId: event.walletId,
            entries: [
              CashMovement(
                userId: event.userId,
                amount: event.amount,
                isIncome: true,
                title: 'Alacak silindi',
                tag: CashMovementTags.receivable,
                date: event.createdAt,
              ),
            ],
          );
        }
        await _safeSyncCredit(event.walletId);

        emit(ReceivableOperationSuccess(
          'Alacak silindi.'
          '${cashResult.ok ? '' : CashCouplingMixin.cashWarning}',
          undo: snapshot == null
              ? null
              : ReceivableDeletionUndo(
                  receivable: snapshot,
                  userId: event.userId,
                  walletId: event.walletId,
                  reversalTransactionIds: cashResult.transactionIds,
                ),
        ));
        add(GetReceivablesEvent(event.walletId));
      },
    );
  }

  /// Alacak ödendiğinde işaretle
  Future<void> _onMarkAsPaid(
      MarkReceivableAsPaidEvent event, Emitter<ReceivableState> emit) async {
    // İdempotans: zaten tahsil edilmiş alacak ikinci kez işaretlenirse
    // bakiyeye aynı tutar bir daha gelir olarak yazılırdı.
    if (event.receivable.isPaid) {
      add(GetReceivablesEvent(event.receivable.walletId));
      return;
    }
    emit(ReceivableLoading());
    // Tahsilat anı kalemin üstünde SAKLANIR: sonraki bir tutar düzeltmesinin
    // tahsilat bacağı bu tarihe yazılır. Kaydedilmezse düzeltme "bugüne"
    // düşüyor ve iki bacak farklı dönemlere dağılıyordu.
    final collectedAt = DateTime.now();
    final updatedReceivable =
        event.receivable.copyWith(isPaid: true, collectedAt: collectedAt);
    final result = await updateReceivableUseCase(updatedReceivable);

    await result.fold(
      (failure) async => emit(ReceivableError(failure.message)),
      (_) async {
        // Nakit kuplajı: alacak tahsil edildi (para girdi) → tutar kadar gelir.
        final cashOk = await walletMetricsService.recordCashMovement(
          walletId: event.receivable.walletId,
          userId: event.receivable.userId,
          amount: event.receivable.amount,
          isIncome: true,
          title: 'Tahsilat: ${event.receivable.debtorName}',
          tag: CashMovementTags.receivableCollection,
          date: collectedAt,
        );
        await _safeSyncCredit(event.receivable.walletId);

        emit(ReceivableOperationSuccess(
            'Alacak ödendi olarak işaretlendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetReceivablesEvent(event.receivable.walletId));
      },
    );
  }

  Future<void> _safeSyncCredit(String walletId) =>
      safeSyncMetric(() => walletMetricsService.syncCredit(walletId), 'credit');

  /// Silinecek alacağın defterdeki hali; bulunamazsa `null` (geri alma
  /// sunulmaz, silme yine yapılır).
  Future<ReceivableEntity?> _receivableSnapshot(
      String walletId, String id) async {
    final Either<Failure, List<ReceivableEntity>> result;
    try {
      result = await getReceivablesUseCase(walletId);
    } catch (e) {
      debugPrint('Geri alma anlık görüntüsü alınamadı (alacak): $e');
      return null;
    }
    return result.fold(
      (_) => null,
      (receivables) {
        for (final r in receivables) {
          if (r.id == id) return r;
        }
        return null;
      },
    );
  }
}
