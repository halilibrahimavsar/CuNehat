import 'dart:async';

import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:equatable/equatable.dart';
import 'package:cunehat/features/debt_and_receivable/domain/entities/debt_entity.dart';
import 'package:cunehat/features/debt_and_receivable/domain/services/overdue_interest.dart';
import 'package:cunehat/features/debt_and_receivable/domain/usecases/debt_usecases.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:flutter/foundation.dart';

part 'debt_event.dart';
part 'debt_state.dart';

@injectable
class DebtBloc extends Bloc<DebtEvent, DebtState> with CashCouplingMixin {
  final GetDebtsUseCase getDebtsUseCase;
  final AddDebtUseCase addDebtUseCase;
  final UpdateDebtUseCase updateDebtUseCase;
  final DeleteDebtUseCase deleteDebtUseCase;
  final WalletMetricsService walletMetricsService;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  /// Defter dışarıdan değişince aynı listeyi tazelemek için son cüzdan.
  String? _lastWalletId;
  StreamSubscription<TransactionsChange>? _changedSubscription;

  DebtBloc({
    required this.getDebtsUseCase,
    required this.addDebtUseCase,
    required this.updateDebtUseCase,
    required this.deleteDebtUseCase,
    required this.walletMetricsService,
    required this.transactionsChangedNotifier,
  }) : super(DebtInitial()) {
    on<GetDebtsEvent>(_onGetDebts);
    on<AddDebtEvent>(_onAddDebt);
    on<UpdateDebtEvent>(_onUpdateDebt);
    on<PayDebtEvent>(_onPayDebt);
    on<UpdateDebtPaymentEvent>(_onUpdateDebtPayment);
    on<DeleteDebtPaymentEvent>(_onDeleteDebtPayment);
    on<DeleteDebtEvent>(_onDeleteDebt);

    // Borç listesi defterin türevi: silme geri alındığında (bkz.
    // DeletionUndoService) ya da kuplaj kaydı başka bir akıştan yazıldığında
    // liste kendi kendine tazelenmeli. Aksi hâlde geri alınan borç, sayfa
    // yeniden kurulana kadar ekranda görünmüyordu.
    _changedSubscription = transactionsChangedNotifier.stream.listen((_) {
      final walletId = _lastWalletId;
      if (walletId != null) add(GetDebtsEvent(walletId));
    });
  }

  @override
  Future<void> close() {
    _changedSubscription?.cancel();
    return super.close();
  }

  /// İşlenmekte olan para yazımlarının anahtarları.
  ///
  /// bloc'un varsayılan olay dönüştürücüsü EŞZAMANLIDIR: aynı olay iki kez
  /// gelirse iki handler paralel çalışır ve deftere İKİ kayıt yazılır.
  /// Ölçülmüş emsal `PendingRecurringBloc`: onay listesi ekranda kaldığı
  /// için çift dokunma gerçekten iki işlem üretiyordu ve oraya aynı kalıp
  /// eklendi. Buradaki yollar hemen kapanan diyalog/sheet'ten tetiklendiği
  /// için risk daha düşük — ama "para iki kez yazıldı" hatasının bedeli,
  /// korumanın maliyetinden büyük.
  final Set<String> _inFlight = <String>{};

  Future<void> _onGetDebts(GetDebtsEvent event, Emitter<DebtState> emit) async {
    _lastWalletId = event.walletId;
    emit(DebtLoading());
    final result = await getDebtsUseCase(event.walletId);
    result.fold(
      (failure) => emit(DebtError(failure.message)),
      (debts) => emit(DebtLoaded(debts)),
    );
  }

  Future<void> _onAddDebt(AddDebtEvent event, Emitter<DebtState> emit) async {
    // Tek sheet açık olabilir; sabit anahtar yeterli.
    if (!_inFlight.add('add-debt')) return;
    try {
      await _addDebt(event, emit);
    } finally {
      _inFlight.remove('add-debt');
    }
  }

  Future<void> _addDebt(AddDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    // Kimlik burada kesinleşir: benimsenen anapara satırı ona bağlanır.
    final debt = (event.debt.id?.isNotEmpty ?? false)
        ? event.debt
        : event.debt.copyWith(id: UidGenerator.generateV7());

    // Anapara defterde ZATEN duruyorsa ("KREDI KULLANDIRIM +50.000") o satır
    // benimsenir; kayıttan ÖNCE — olmazsa borç hiç yazılmaz.
    TransactionEntity? adopted;
    final source = event.principalSource;
    if (debt.principalToWallet && source is AdoptedCashMovement) {
      adopted = await walletMetricsService.adoptCashMovement(
        walletId: debt.walletId,
        transactionId: source.transaction.id ?? '',
        tag: CashMovementTags.debt,
        linkedRecordId: debt.id!,
        expectIncome: true,
        expectAmount: source.transaction.amount,
      );
      if (adopted == null) {
        emit(const DebtError(_adoptFailedMessage));
        return;
      }
    }

    final result = await addDebtUseCase(debt);

    await result.fold(
      (failure) async {
        if (adopted != null) {
          await walletMetricsService.releaseAdoptedMovements(
            walletId: debt.walletId,
            linkedRecordIds: {debt.id!},
          );
        }
        emit(DebtError(failure.message));
      },
      (_) async {
        // Nakit kuplajı: borç NAKİT alındıysa anapara kadar gelir yazılır.
        // Ürün/hizmet karşılığı borçta (principalToWallet=false) para hiç ele
        // geçmedi → bakiye değişmez; yalnız ödemeler gider olarak düşer.
        // Benimsenen satır anaparayı karşılar; fark (normalde yok) yazılır.
        var cashOk = true;
        final remainder =
            roundToCents(debt.principalAmount - (adopted?.amount ?? 0));
        if (debt.principalToWallet && !moneyEquals(remainder, 0)) {
          cashOk = await walletMetricsService.recordCashMovement(
            walletId: debt.walletId,
            userId: debt.userId,
            amount: remainder.abs(),
            isIncome: remainder > 0,
            title: debt.title,
            tag: CashMovementTags.debt,
            // Para borcun BAŞLANGIÇ tarihinde ele geçti; silmedeki ters kayıt
            // da oraya yazılır, iki bacak aynı dönemde kapanır.
            date: debt.startDate,
            linkedRecordId: debt.id,
          );
        }
        await _safeSyncDebt(debt.walletId);

        emit(DebtOperationSuccess(
            'Borç başarıyla eklendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        // Listeyi güncellemek için tekrar çekiyoruz
        add(GetDebtsEvent(debt.walletId));
      },
    );
  }

  /// Kaydın türev alanlarını tek noktada tazeler: ödemelerin gecikme faizi
  /// payları kronolojik olarak yeniden dağıtılır, `isPaid` bunun üzerinden
  /// yeniden hesaplanır.
  ///
  /// Ödeme ekleme/düzenleme/silme ve borcun kendisinin düzenlenmesi — dördü de
  /// buradan geçmeli. Borcun vadesi, başlangıcı ya da toplamı değişince taksit
  /// planı kayar ve eski faiz payları geçersizleşir; yalnız `isPaid`'i
  /// tazelemek yetmez.
  DebtEntity _normalize(DebtEntity debt) {
    final withSplits = debt.copyWith(payments: reallocatePayments(debt));
    return withSplits.copyWith(
      isPaid: moneyGte(
              withSplits.principalPaidAmount, withSplits.totalDebtAmount) &&
          !moneyIsPositive(outstandingOverdueInterest(withSplits)),
    );
  }

  Future<void> _onPayDebt(PayDebtEvent event, Emitter<DebtState> emit) async {
    final key = 'pay:${event.debt.id}';
    if (!_inFlight.add(key)) return;
    try {
      await _payDebt(event, emit);
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<void> _payDebt(PayDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());

    // Ödeme defterde ZATEN duruyorsa ("KREDI TAKSIT −2.500") o satır
    // benimsenir; kayıttan ÖNCE — olmazsa ödeme hiç yazılmaz.
    TransactionEntity? adopted;
    final source = event.cashSource;
    if (source is AdoptedCashMovement) {
      final paymentId = event.paymentId;
      adopted = paymentId == null
          ? null
          : await walletMetricsService.adoptCashMovement(
              walletId: event.debt.walletId,
              transactionId: source.transaction.id ?? '',
              tag: CashMovementTags.debtPayment,
              linkedRecordId: paymentId,
              expectIncome: false,
              expectAmount: source.transaction.amount,
            );
      if (adopted == null) {
        emit(const DebtError(_adoptFailedMessage));
        return;
      }
    }

    final result = await updateDebtUseCase(_normalize(event.debt));

    await result.fold(
      (failure) async {
        if (adopted != null) {
          await walletMetricsService.releaseAdoptedMovements(
            walletId: event.debt.walletId,
            linkedRecordIds: {event.paymentId!},
          );
        }
        emit(DebtError(failure.message));
      },
      (_) async {
        // Nakit kuplajı: borç ödendi → ödeme kadar gider. Benimsenen satır
        // ödemeyi zaten karşılar; fark (normalde yok) yazılır.
        final remainder =
            roundToCents(event.paymentAmount - (adopted?.amount ?? 0));
        var cashOk = true;
        if (!moneyEquals(remainder, 0)) {
          cashOk = await walletMetricsService.recordCashMovement(
            walletId: event.debt.walletId,
            userId: event.debt.userId,
            amount: remainder.abs(),
            isIncome: remainder < 0,
            title: 'Ödeme: ${event.debt.title}',
            tag: CashMovementTags.debtPayment,
            // Kullanıcının seçtiği ödeme tarihi; silmedeki iade
            // `Payment.date`'e yazıldığından bugüne düşerse iki dönem birden
            // bozulur.
            date: event.paymentDate,
            linkedRecordId: event.paymentId,
          );
        }
        await _safeSyncDebt(event.debt.walletId);

        emit(DebtOperationSuccess(
            'Ödeme kaydedildi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(event.debt.walletId));
      },
    );
  }

  Future<void> _onUpdateDebtPayment(
      UpdateDebtPaymentEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    // Nakit bacağı benimsenmiş satırsa tutar ve tarih bankanın satırından
    // gelir: değişirse ödeme kaydı bankayla, defterle ve kendi satırıyla
    // ayrı üç şey söylerdi. (Not düzenlemesi serbest.)
    final paymentId = event.paymentId;
    if (paymentId != null &&
        (!moneyEquals(event.prevAmount, event.newAmount) ||
            !_isSameDay(event.prevDate, event.newDate))) {
      final adopted = await walletMetricsService.adoptedOwners(
        walletId: event.debt.walletId,
        recordIds: {paymentId},
      );
      if (adopted.isNotEmpty) {
        emit(const DebtError(_adoptedPaymentLockedMessage));
        add(GetDebtsEvent(event.debt.walletId));
        return;
      }
    }
    final debt = _normalize(event.debt);
    final result = await updateDebtUseCase(debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Mutabakat, borç güncellemesindeki desenin aynısı — YALNIZ İŞARET
        // TERS: anapara girişi GELİR, ödeme ise GİDERdir. Tutar arttıysa
        // deftere ek gider, azaldıysa iade yazılır.
        final entries = <CashMovement>[];
        if (_isSameDay(event.prevDate, event.newDate)) {
          final diff = event.newAmount - event.prevAmount;
          // Fark PARA olarak ölçülür: ham `!= 0` bir IEEE-754 artığında
          // (1e-13) deftere 0,00 tutarlı ve UI'dan SİLİNEMEZ bir sistem
          // satırı yazardı — sistem işlemleri yalnız kaydından yönetilir.
          if (!moneyEquals(diff, 0)) {
            entries.add(CashMovement(
              userId: debt.userId,
              amount: diff.abs(),
              isIncome: diff < 0,
              title: 'Ödeme güncellendi: ${debt.title}',
              tag: CashMovementTags.debtPayment,
              date: event.newDate,
              linkedRecordId: paymentId,
            ));
          }
        } else {
          // Tarih taşındı: eskisini KENDİ döneminde iade et, yenisini yeni
          // döneme yaz. Aksi hâlde iki dönemin gider toplamı birden bozulur.
          if (moneyIsPositive(event.prevAmount)) {
            entries.add(CashMovement(
              userId: debt.userId,
              amount: event.prevAmount,
              isIncome: true,
              title: 'Ödeme güncellendi: ${debt.title}',
              tag: CashMovementTags.debtPayment,
              date: event.prevDate,
              linkedRecordId: paymentId,
            ));
          }
          if (moneyIsPositive(event.newAmount)) {
            entries.add(CashMovement(
              userId: debt.userId,
              amount: event.newAmount,
              isIncome: false,
              title: 'Ödeme güncellendi: ${debt.title}',
              tag: CashMovementTags.debtPayment,
              date: event.newDate,
              linkedRecordId: paymentId,
            ));
          }
        }

        var cashOk = true;
        if (entries.isNotEmpty) {
          cashOk = (await walletMetricsService.recordCashMovements(
            walletId: debt.walletId,
            entries: entries,
          ))
              .ok;
        }
        await _safeSyncDebt(debt.walletId);

        emit(DebtOperationSuccess(
            'Ödeme güncellendi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(debt.walletId));
      },
    );
  }

  Future<void> _onDeleteDebtPayment(
      DeleteDebtPaymentEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    final debt = _normalize(event.debt);
    final result = await updateDebtUseCase(debt);

    await result.fold(
      (failure) async => emit(DebtError(failure.message)),
      (_) async {
        // Nakit bacağı benimsenmiş satırsa o satır özgün düz hâline döner
        // (bankada para gerçekten çıktı; ters kayıt cüzdanı bankadan
        // koparırdı). İade yalnız kuplajın KENDİ yazdığı kısım içindir:
        // ödeme − benimsenen satır (normalde 0).
        final removedId = event.removedPaymentId;
        final released = removedId == null
            ? const <TransactionEntity>[]
            : await walletMetricsService.releaseAdoptedMovements(
                walletId: debt.walletId,
                linkedRecordIds: {removedId},
              );
        final net = roundToCents(event.removedAmount -
            released.fold<double>(0, (sum, t) => sum + t.amount));
        var cashOk = true;
        if (!moneyEquals(net, 0)) {
          // İade, silinen ödemenin KENDİ tarihine yazılır: bugüne yazılsaydı
          // geçmiş ayda iadesiz gider, bu ayda gidersiz iade kalırdı.
          cashOk = await walletMetricsService.recordCashMovement(
            walletId: debt.walletId,
            userId: debt.userId,
            amount: net.abs(),
            isIncome: net > 0,
            title: 'Ödeme silindi: ${debt.title}',
            tag: CashMovementTags.debtPayment,
            date: event.removedDate,
            linkedRecordId: removedId,
          );
        }
        await _safeSyncDebt(debt.walletId);

        emit(DebtOperationSuccess(
            'Ödeme silindi.${cashOk ? '' : CashCouplingMixin.cashWarning}'));
        add(GetDebtsEvent(debt.walletId));
      },
    );
  }

  Future<void> _onUpdateDebt(
      UpdateDebtEvent event, Emitter<DebtState> emit) async {
    emit(DebtLoading());
    // Anaparası BENİMSENMİŞ borçta (ekstredeki kredi girişi) anaparanın tutarı
    // ve başlangıç tarihi bankanın satırından gelir. Değişirse aşağıdaki
    // mutabakat eski tarihe ters kayıt + yeni tarihe yeni gelir yazar; banka
    // satırı da yerinde durduğu için gelir İKİ KEZ sayılırdı.
    final debtId = event.debt.id;
    if (event.debt.principalToWallet &&
        debtId != null &&
        (!moneyEquals(event.prevPrincipal, event.debt.principalAmount) ||
            !_isSameDay(event.prevStartDate, event.debt.startDate))) {
      final adopted = await walletMetricsService.adoptedOwners(
        walletId: event.debt.walletId,
        recordIds: {debtId},
      );
      if (adopted.isNotEmpty) {
        emit(const DebtError(_adoptedPrincipalLockedMessage));
        add(GetDebtsEvent(event.debt.walletId));
        return;
      }
    }
    // Tutar düzenlemesi isPaid'i geçersiz kılabilir (örn. 600 ödenmişken
    // anapara 500'e indirilirse). isPaid yeniden hesaplanmazsa borç ne aktif
    // listede (remaining ≤ 0) ne geçmişte (isPaid=false) görünür. Vade/
    // başlangıç düzenlemesi ayrıca taksit planını kaydırdığından ödemelerin
    // gecikme faizi payları da yeniden dağıtılmalı.
    final debt = _normalize(event.debt);
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
            if (!moneyEquals(diff, 0)) {
              entries.add(CashMovement(
                userId: event.debt.userId,
                amount: diff.abs(),
                isIncome: diff > 0,
                title: 'Borç güncellendi: ${event.debt.title}',
                tag: CashMovementTags.debt,
                linkedRecordId: debtId,
                date: event.debt.startDate,
              ));
            }
          } else {
            // Başlangıç tarihi taşındı: eski kayıt eski dönemde bırakılırsa
            // silmedeki ters kayıt YENİ tarihe düşer, iki dönem birden bozulur.
            // Eskisini kendi tarihinde geri al, yenisini yeni tarihe yaz.
            if (moneyIsPositive(event.prevPrincipal)) {
              entries.add(CashMovement(
                userId: event.debt.userId,
                amount: event.prevPrincipal,
                isIncome: false,
                title: 'Borç güncellendi: ${event.debt.title}',
                tag: CashMovementTags.debt,
                linkedRecordId: debtId,
                date: event.prevStartDate,
              ));
            }
            if (moneyIsPositive(event.debt.principalAmount)) {
              entries.add(CashMovement(
                userId: event.debt.userId,
                amount: event.debt.principalAmount,
                isIncome: true,
                title: 'Borç güncellendi: ${event.debt.title}',
                tag: CashMovementTags.debt,
                linkedRecordId: debtId,
                date: event.debt.startDate,
              ));
            }
          }

          if (entries.isNotEmpty) {
            cashOk = (await walletMetricsService.recordCashMovements(
              walletId: event.debt.walletId,
              entries: entries,
            ))
                .ok;
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

    // Geri alma kaydın TAMAMINI ister (ödeme geçmişi, faiz, vade…); event
    // yalnız mutabakat alanlarını taşıyor. Silmeden önce defterdeki hali
    // okunur — UI'ın elindeki kopya değil, gerçekten saklanan kayıt.
    final snapshot = await _debtSnapshot(event.walletId, event.id);

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
        //
        // BENİMSENMİŞ satırlar (ekstreden gelen anapara girişi ya da taksit
        // ödemesi) tersine çevrilmez, özgün düz hâllerine BIRAKILIR: bankada
        // o para gerçekten girdi/çıktı; ters kayıt cüzdanı bankadan koparırdı.
        // Ters kayıt yalnız kuplajın KENDİ yazdığı kısım içindir: kayıt
        // tutarı − benimsenen satır (normalde 0; işaretiyle birlikte).
        final released = await walletMetricsService.releaseAdoptedMovements(
          walletId: event.walletId,
          linkedRecordIds: {
            event.id,
            for (final p in event.payments) p.id,
          },
        );
        final releasedByOwner = <String, double>{};
        for (final t in released) {
          final owner = t.linkedRecordId;
          if (owner == null) continue;
          releasedByOwner[owner] = (releasedByOwner[owner] ?? 0) + t.amount;
        }
        double rest(String id, double amount) =>
            roundToCents(amount - (releasedByOwner[id] ?? 0));
        final principalRest = rest(event.id, event.principalAmount);
        final reversals = <CashMovement>[
          if (event.principalToWallet && !moneyEquals(principalRest, 0))
            CashMovement(
              userId: event.userId,
              amount: principalRest.abs(),
              // anapara girişi geri alınır
              isIncome: principalRest < 0,
              title: 'Borç silindi',
              tag: CashMovementTags.debt,
              date: event.startDate,
              linkedRecordId: event.id,
            ),
          for (final p in event.payments)
            if (!moneyEquals(rest(p.id, p.amount), 0))
              CashMovement(
                userId: event.userId,
                amount: rest(p.id, p.amount).abs(),
                // ödeme gideri geri alınır
                isIncome: rest(p.id, p.amount) > 0,
                title: 'Borç silindi (ödeme iadesi)',
                tag: CashMovementTags.debtPayment,
                date: p.date,
                linkedRecordId: p.id,
              ),
        ];

        final cashResult = await walletMetricsService.recordCashMovements(
          walletId: event.walletId,
          entries: reversals,
        );
        await _safeSyncDebt(event.walletId);

        emit(DebtOperationSuccess(
          'Borç silindi.${cashResult.ok ? '' : CashCouplingMixin.cashWarning}',
          undo: snapshot == null
              ? null
              : DebtDeletionUndo(
                  debt: snapshot,
                  userId: event.userId,
                  walletId: event.walletId,
                  reversalTransactionIds: cashResult.transactionIds,
                  releasedAdoptions: released,
                ),
        ));
        add(GetDebtsEvent(event.walletId));
      },
    );
  }

  /// Borç bloc'u hazır cümle yayınlıyor (bkz. yatırım modülünün
  /// `InvestmentNotice` deseni — borç tarafı henüz taşınmadı).
  static const _adoptFailedMessage =
      'Seçilen işlem bağlanamadı: bu arada değişmiş, silinmiş ya da başka bir '
      'kayda bağlanmış olabilir. Kayıt eklenmedi.';
  static const _adoptedPaymentLockedMessage =
      'Bu ödeme ekstredeki bir satıra bağlı: tutarı ve tarihi o satırdan '
      'gelir. Yanlış satırsa ödemeyi silip doğru satırla yeniden ekle.';
  static const _adoptedPrincipalLockedMessage =
      'Bu borcun anaparası ekstredeki bir satıra bağlı: tutarı ve başlangıç '
      'tarihi o satırdan gelir. Diğer bilgiler kaydedilmedi; yanlış satırsa '
      'borcu silip doğru satırla yeniden ekle.';

  Future<void> _safeSyncDebt(String walletId) =>
      safeSyncMetric(() => walletMetricsService.syncDebt(walletId), 'debt');

  /// Silinecek borcun defterdeki hali; bulunamazsa `null` (geri alma sunulmaz,
  /// silme yine yapılır — okunamayan bir kayıt yüzünden silme engellenmemeli).
  Future<DebtEntity?> _debtSnapshot(String walletId, String id) async {
    final Either<Failure, List<DebtEntity>> result;
    try {
      result = await getDebtsUseCase(walletId);
    } catch (e) {
      debugPrint('Geri alma anlık görüntüsü alınamadı (borç): $e');
      return null;
    }
    return result.fold(
      (_) => null,
      (debts) {
        for (final d in debts) {
          if (d.id == id) return d;
        }
        return null;
      },
    );
  }

  /// Defter dönemi gün çözünürlüğündedir; aynı gün yeniden seçilirse (tarih
  /// seçici gece yarısına sabitler) taşıma sayılmaz.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
