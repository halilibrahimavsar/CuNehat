import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:injectable/injectable.dart';

part 'debt_event.dart';
part 'debt_state.dart';

@injectable
class DebtBloc extends Bloc<DebtEvent, DebtState> with CashCouplingMixin {
  final GetDebtsUseCase getDebtsUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateDebtUseCase updateDebtUseCase;
  final DeleteDebtUseCase deleteDebtUseCase;
  final WalletMetricsService walletMetricsService;

  DebtBloc({
    required this.getDebtsUseCase,
    required this.addDebtUseCase,
    required this.updateDebtUseCase,
    required this.deleteDebtUseCase,
    required this.walletMetricsService,
  }) : super(DebtInitial()) {
    on<GetDebtsEvent>(_onGetDebts);
    on<AddDebtEvent>(_onAddDebt);
    on<UpdateDebtEvent>(_onUpdateDebt);
    on<PayDebtEvent>(_onPayDebt);
    on<DeleteDebtEvent>(_onDeleteDebt);
  }

  Future<void> _onGetDebts(GetDebtsEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await getDebtsUseCase(event.walletId);
    result.fold(
      (failure) => emit(DebtError(failure.message)),
      (debts) => emit(DebtLoaded(debts)),
    );
  }

  Future<void> _onAddDebt(AddDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await addDebtUseCase(event.debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Nakit kuplajı: borç NAKİT alındıysa anapara kadar gelir yazılır.
        // Ürün/hizmet karşılığı borçta (principalToWallet=false) para hiç ele
        // geçmedi → bakiye değişmez; yalnız ödemeler gider olarak düşer.
        var cashOk = true;
        if (event.debt.principalToWallet) {
          cashOk = await walletMetricsService.recordCashMovement(
            walletId: event.debt.walletId,
            userId: event.debt.userId,
            amount: event.debt.principalAmount,
            isIncome: true,
            title: event.debt.title,
            tag: CashMovementTags.debt,
            // Para borcun BAŞLANGIÇ tarihinde ele geçti; silmedeki ters kayıt
            // da oraya yazılır, iki bacak aynı dönemde kapanır.
            date: event.debt.startDate,
          );
        }
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Borç başarıyla eklendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        // Listeyi güncellemek için tekrar çekiyoruz
        add(GetDebtsEvent(event.debt.walletId));
      },
    );
  }

  Future<void> _onPayDebt(PayDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await updateDebtUseCase(event.debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Nakit kuplajı: borç ödendi → ödeme kadar gider.
        final cashOk = await walletMetricsService.recordCashMovement(
          walletId: event.debt.walletId,
          userId: event.debt.userId,
          amount: event.paymentAmount,
          isIncome: false,
          title: 'Ödeme: ${event.debt.title}',
          tag: CashMovementTags.debtPayment,
          // Kullanıcının seçtiği ödeme tarihi; silmedeki iade `Payment.date`'e
          // yazıldığından bugüne düşerse iki dönem birden bozulur.
          date: event.paymentDate,
        );
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Ödeme kaydedildi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(event.debt.walletId));
      },
    );
  }

  Future<void> _onUpdateDebt(
      UpdateDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    // Tutar düzenlemesi isPaid'i geçersiz kılabilir (örn. 600 ödenmişken
    // anapara 500'e indirilirse). isPaid yeniden hesaplanmazsa borç ne aktif
    // listede (remaining ≤ 0) ne geçmişte (isPaid=false) görünür.
    final debt = event.debt.copyWith(
      isPaid: moneyGte(event.debt.totalPaidAmount, event.debt.totalDebtAmount),
    );
    final result = await updateDebtUseCase(debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Mutabakat: anapara hareketi HER ZAMAN başlangıç tarihinde durur;
        // silmedeki ters kayıt da oraya yazıldığından iki bacak aynı dönemde
        // kapanır. Ürün borcunda anapara hiç bakiyeye girmedi → değişimi de
        // girmez.
        var cashOk = true;
        if (event.debt.principalToWallet) {
          final entries = <CashMovement>[];

          if (_isSameDay(event.prevStartDate, event.debt.startDate)) {
            // Tarih yerinde: yalnız farkı yaz, defteri karşılıklı kayıtlarla
            // şişirme.
            final diff = event.debt.principalAmount - event.prevPrincipal;
            if (diff != 0) {
              entries.add(CashMovement(
                userId: event.debt.userId,
                amount: diff.abs(),
                isIncome: diff > 0,
                title: 'Borç güncellendi: ${event.debt.title}',
                tag: CashMovementTags.debt,
                date: event.debt.startDate,
              ));
            }
          } else {
            // Başlangıç tarihi taşındı: eski kayıt eski dönemde bırakılırsa
            // silmedeki ters kayıt YENİ tarihe düşer, iki dönem birden bozulur.
            // Eskisini kendi tarihinde geri al, yenisini yeni tarihe yaz.
            if (event.prevPrincipal != 0) {
              entries.add(CashMovement(
                userId: event.debt.userId,
                amount: event.prevPrincipal,
                isIncome: false,
                title: 'Borç güncellendi: ${event.debt.title}',
                tag: CashMovementTags.debt,
                date: event.prevStartDate,
              ));
            }
            if (event.debt.principalAmount != 0) {
              entries.add(CashMovement(
                userId: event.debt.userId,
                amount: event.debt.principalAmount,
                isIncome: true,
                title: 'Borç güncellendi: ${event.debt.title}',
                tag: CashMovementTags.debt,
                date: event.debt.startDate,
              ));
            }
          }

          if (entries.isNotEmpty) {
            cashOk = await walletMetricsService.recordCashMovements(
              walletId: event.debt.walletId,
              entries: entries,
            );
          }
        }
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Borç güncellendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(event.debt.walletId));
      },
    );
  }

  Future<void> _onDeleteDebt(
      DeleteDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final result = await deleteDebtUseCase(event.id);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Mutabakat: borcun nakit etkisini KAYIT KAYIT geri al.
        //
        // Toplam etki sıfırlanacak şekilde tek bir ters kayıt yazmak bakiyeyi
        // doğru veriyordu ama tamamı BUGÜNE düşüyordu: Ocak'ta alınan kredi
        // Temmuz'da silindiğinde Temmuz raporunda hiç yaşanmamış dev bir gider
        // beliriyordu. Bunun yerine her hareket iptal ettiği kaydın kendi
        // tarihine yazılır → her dönem kendi içinde sıfırlanır.
        final reversals = <CashMovement>[
          if (event.principalToWallet && event.principalAmount != 0)
            CashMovement(
              userId: event.userId,
              amount: event.principalAmount,
              isIncome: false, // anapara girişi geri alınır
              title: 'Borç silindi',
              tag: CashMovementTags.debt,
              date: event.startDate,
            ),
          for (final p in event.payments)
            if (p.amount != 0)
              CashMovement(
                userId: event.userId,
                amount: p.amount,
                isIncome: true, // ödeme gideri geri alınır
                title: 'Borç silindi (ödeme iadesi)',
                tag: CashMovementTags.debtPayment,
                date: p.date,
              ),
        ];

        final cashOk = await walletMetricsService.recordCashMovements(
          walletId: event.walletId,
          entries: reversals,
        );
        await _safeSyncDebt(event.walletId);

        emit(DebtOperationSuccess(
            'Borç silindi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(event.walletId));
      },
    );
  }

  Future<void> _safeSyncDebt(String walletId) =>
      safeSyncMetric(() => walletMetricsService.syncDebt(walletId), 'debt');

  /// Defter dönemi gün çözünürlüğündedir; aynı gün yeniden seçilirse (tarih
  /// seçici gece yarısına sabitler) taşıma sayılmaz.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
