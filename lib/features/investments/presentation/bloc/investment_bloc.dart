import 'dart:async';

import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/id_generate/uid_generator.dart';
import 'package:cunehat/core/services/cash_source.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_entity.dart';
import 'package:cunehat/features/investments/domain/cash_pot_math.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/goal_usecases.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:cunehat/core/services/deletion_undo_service.dart';
import 'package:dartz/dartz.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:flutter/foundation.dart';

part 'investment_event.dart';
part 'investment_state.dart';

@injectable
class InvestmentBloc extends Bloc<InvestmentEvent, InvestmentState>
    with CashCouplingMixin {
  final GetInvestmentsUseCase getInvestmentsUseCase;
  final AddInvestmentUseCase addInvestmentUseCase;
  final UpdateInvestmentUseCase updateInvestmentUseCase;
  final DeleteInvestmentUseCase deleteInvestmentUseCase;
  final GetLiveQuoteUseCase getLiveQuoteUseCase;
  final GetGoalsUseCase getGoalsUseCase;
  final SaveGoalUseCase saveGoalUseCase;
  final DeleteGoalUseCase deleteGoalUseCase;
  final WalletMetricsService walletMetricsService;
  final TransactionsChangedNotifier transactionsChangedNotifier;

  /// Defter dışarıdan değişince aynı listeyi tazelemek için son sorgu.
  String? _lastUserId;
  String? _lastWalletId;

  /// Son başarılı liste. Hata yayınlandıktan sonra geri konur: sayfa yalnız
  /// [InvestmentLoaded] durumunda veri çiziyor, hata durumunda portföyü
  /// SIFIR gösteriyordu — kullanıcı kayıtlarını kaybettiğini sanıyordu.
  InvestmentLoaded? _lastLoaded;
  StreamSubscription<TransactionsChange>? _changedSubscription;

  InvestmentBloc({
    required this.getInvestmentsUseCase,
    required this.addInvestmentUseCase,
    required this.updateInvestmentUseCase,
    required this.deleteInvestmentUseCase,
    required this.getLiveQuoteUseCase,
    required this.getGoalsUseCase,
    required this.saveGoalUseCase,
    required this.deleteGoalUseCase,
    required this.walletMetricsService,
    required this.transactionsChangedNotifier,
  }) : super(InvestmentInitial()) {
    // Portföy listesi defterin türevi: silme/satış geri alındığında (bkz.
    // DeletionUndoService) liste kendi kendine tazelenmeli.
    _changedSubscription = transactionsChangedNotifier.stream.listen((_) {
      final userId = _lastUserId;
      final walletId = _lastWalletId;
      if (userId != null && walletId != null) {
        add(GetInvestmentsEvent(userId: userId, walletId: walletId));
      }
    });
    // Yatırımları Getir
    on<GetInvestmentsEvent>((event, emit) async {
      _lastUserId = event.userId;
      _lastWalletId = event.walletId;
      emit(InvestmentLoading());
      final result = await getInvestmentsUseCase.call(
        userId: event.userId,
        walletId: event.walletId,
      );

      // Hedefler listeyle BİRLİKTE okunur: ilerleme üyelerden hesaplandığı
      // için ikisi ayrı karelerde gelirse hedef kartları bir kare boş çizilir.
      final goalsResult = await getGoalsUseCase(
        userId: event.userId,
        walletId: event.walletId,
      );
      final goals = goalsResult.getOrElse(() => const []);

      result.fold(
        (failure) => _emitError(emit, RawFailureNotice(failure.message)),
        (investments) {
          // Bkz. InvestmentLoaded.totalCurrentValue: maliyet toplamı da
          // kuruşa oturmalı, yoksa kâr/zarar farkı bir kuruş kayıyor.
          final total = roundToCents(
              investments.fold<double>(0, (sum, item) => sum + item.amount));
          final loaded = InvestmentLoaded(
            investments,
            goals: goals,
            totalAmount: total,
          );
          _lastLoaded = loaded;
          emit(loaded);
        },
      );
    });

    // Hedef Kaydet (ekle/güncelle). Defterle ilişkisi YOK: hedef bir kap,
    // para hareketi değil — nakit kuplajı üyelerin kendi kayıtlarında.
    on<SaveGoalEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await saveGoalUseCase(event.goal);
      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (_) async {
          emit(const InvestmentActionSuccess(GoalSavedNotice()));
          add(GetInvestmentsEvent(
            userId: event.goal.userId,
            walletId: event.goal.walletId,
          ));
        },
      );
    });

    // Hedef Sil: üyeler SİLİNMEZ, bağları koparılır.
    on<DeleteGoalEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await deleteGoalUseCase(event.goal);
      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (_) async {
          emit(const InvestmentActionSuccess(GoalDeletedNotice()));
          add(GetInvestmentsEvent(
            userId: event.goal.userId,
            walletId: event.goal.walletId,
          ));
        },
      );
    });

    // Yatırım Ekle
    on<CreateInvestmentEvent>((event, emit) async {
      // Tek ekleme sheet'i açık olabilir; sabit anahtar yeterli.
      if (!_inFlight.add('create-investment')) return;
      try {
        emit(InvestmentLoading());
        // Kimlik burada kesinleşir: benimsenen satır kayda bu kimlikle bağlanır.
        final investment = (event.investment.id?.isNotEmpty ?? false)
            ? event.investment
            : event.investment.copyWith(id: UidGenerator.generateV7());

        // Alımın ödemesi defterde ZATEN duruyorsa (ekstreden gelen satır) o
        // satır benimsenir, ikinci gider yazılmaz. Benimseme kayıttan ÖNCE:
        // satır bu arada değişmiş/silinmiş ya da başka kayda bağlanmışsa
        // kayıt hiç yazılmaz — yazılsaydı nakit bacağı olmayan bir yatırım
        // kalırdı.
        TransactionEntity? adopted;
        final source = event.cashSource;
        // Ödeme bir NAKİT KASASINDAN: cüzdana ve deftere dokunulmaz.
        if (source is FromSavingsPot) {
          await _createFromPot(event, investment, source.potId, emit);
          return;
        }
        if (source is AdoptedCashMovement) {
          adopted = await walletMetricsService.adoptCashMovement(
            walletId: event.walletId,
            transactionId: source.transaction.id ?? '',
            tag: CashMovementTags.investmentBuy,
            linkedRecordId: investment.id!,
            expectIncome: false,
            expectAmount: source.transaction.amount,
          );
          if (adopted == null) {
            _emitError(emit, const AdoptionFailedNotice());
            return;
          }
        }

        final result = await addInvestmentUseCase.call(investment);

        await result.fold(
          (failure) async {
            // Kayıt yazılamadı: benimsenen satır eski düz hâline döner.
            if (adopted != null) {
              await walletMetricsService.releaseAdoptedMovements(
                walletId: event.walletId,
                linkedRecordIds: {investment.id!},
              );
            }
            _emitError(emit, RawFailureNotice(failure.message));
          },
          (_) async {
            // Nakit kuplajı: yatırım alımı → maliyet kadar gider.
            //
            // Üç incelik:
            // - Yalnız DEFTERE İŞLENECEK kısım yazılır. "Bu varlık zaten bende"
            //   denen tutar (unbookedCost) cüzdandan hiç çıkmadı; bugünün
            //   defterine sahte gider yazmak bakiyeyi olduğundan düşük gösterir.
            // - Gider kaydın TARİHİNE yazılır (bugüne değil): geçmişte alınmış
            //   bir varlık kendi ayında görünür. Yeni kayıtta tarih zaten bugün.
            // - Benimsenen satır maliyeti karşılar; kalan (normalde yok: sayfa
            //   tutarı satıra kilitler) yeni hareket olarak yazılır.
            final remainder =
                roundToCents(investment.bookedCost - (adopted?.amount ?? 0));
            var cashOk = true;
            if (remainder > 0) {
              cashOk = await walletMetricsService.recordCashMovement(
                walletId: event.walletId,
                userId: event.userId,
                amount: remainder,
                isIncome: false,
                title: investment.name,
                // Nakit kasasına para koymak bir alım değil, aktarımdır.
                tag: investment.type == InvestmentType.cash
                    ? CashMovementTags.savingsDeposit
                    : CashMovementTags.investmentBuy,
                date: investment.dateAdded,
                linkedRecordId: investment.id,
              );
            }
            await _safeSyncInvestment(event.walletId);
            emit(InvestmentActionSuccess(const InvestmentAddedNotice(),
                cashOk: cashOk));
            add(GetInvestmentsEvent(
                userId: event.userId, walletId: event.walletId));
          },
        );
      } finally {
        _inFlight.remove('create-investment');
      }
    });

    // Yatırım Güncelle
    on<UpdateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());

      // Katkı bir NAKİT KASASINDAN: cüzdana ve deftere dokunulmaz.
      if (event.cashSource case FromSavingsPot(:final potId)) {
        await _contributeFromPot(event, potId, emit);
        return;
      }

      // Katkının ödemesi defterde zaten duruyorsa (ekstre satırı) önce o
      // benimsenir; olmazsa kayıt güncellenmez (bkz. CreateInvestmentEvent).
      TransactionEntity? adopted;
      final source = event.cashSource;
      if (source is AdoptedCashMovement) {
        adopted = await walletMetricsService.adoptCashMovement(
          walletId: event.walletId,
          transactionId: source.transaction.id ?? '',
          tag: CashMovementTags.investmentBuy,
          linkedRecordId: event.investment.id ?? '',
          expectIncome: false,
          expectAmount: source.transaction.amount,
        );
        if (adopted == null) {
          _emitError(emit, const AdoptionFailedNotice());
          return;
        }
      }

      final result = await updateInvestmentUseCase.call(event.investment);

      await result.fold(
        (failure) async {
          if (adopted != null) {
            await walletMetricsService.releaseAdoptedMovements(
              walletId: event.walletId,
              linkedRecordIds: {event.investment.id ?? ''},
            );
          }
          _emitError(emit, RawFailureNotice(failure.message));
        },
        (_) async {
          // Mutabakat: maliyet (anapara) değişimi kadar nakit.
          // Maliyet arttı → gider; azaldı → gelir. (currentValue değişimi
          // gerçekleşmemiş kâr/zarar olduğundan nakdi etkilemez.) Benimsenen
          // satır farkın o kadarını zaten karşılar.
          final costDiff =
              event.newAmount - event.prevAmount - (adopted?.amount ?? 0);
          var cashOk = true;
          // Fark PARA olarak ölçülür: ham `!= 0` bir IEEE-754 artığında
          // deftere 0,00 tutarlı, UI'dan silinemez bir sistem satırı yazardı.
          if (!moneyEquals(costDiff, 0)) {
            cashOk = await walletMetricsService.recordCashMovement(
              walletId: event.walletId,
              userId: event.userId,
              amount: costDiff.abs(),
              isIncome: costDiff < 0,
              title: event.investment.type == InvestmentType.cash
                  ? event.investment.name
                  : 'Yatırım güncellendi: ${event.investment.name}',
              tag: event.investment.type == InvestmentType.cash
                  ? (costDiff < 0
                      ? CashMovementTags.savingsWithdraw
                      : CashMovementTags.savingsDeposit)
                  : CashMovementTags.investmentBuy,
              // Tarihi ÇAĞIRAN söyler: katkıda para bugün çıkar, düzenlemede
              // kaydın özgün maliyeti düzeltilir (bkz. `bookingDate`).
              // Alan yokken ikisi de "şimdi"ye düşüyordu ve silme düzeltmesi
              // aynı tutarı `dateAdded`'a ters çevirdiği için iki ayrı ayın
              // raporu birden bozuluyordu.
              date: event.bookingDate,
              linkedRecordId: event.investment.id,
            );
          }
          await _safeSyncInvestment(event.walletId);
          emit(InvestmentActionSuccess(const InvestmentUpdatedNotice(),
              cashOk: cashOk));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Fiyat Yenile: güncel değer = miktar × canlı fiyat (CÜZDANIN biriminde;
    // fiyat kaynağı başka birimdeyse çapraz kurla çevrilir). Maliyet
    // değişmediği için (costDiff yok) defterde nakit hareketi oluşmaz;
    // yalnızca portföy/birikim metriği senkronlanır.
    on<RefreshPricesEvent>((event, emit) async {
      emit(InvestmentLoading());
      final listResult = await getInvestmentsUseCase.call(
        userId: event.userId,
        walletId: event.walletId,
      );

      await listResult.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (investments) async {
          final targets = investments
              .where((inv) =>
                  inv.canRefreshPrice &&
                  (event.investmentId == null || inv.id == event.investmentId))
              .toList();

          if (targets.isEmpty) {
            _emitError(emit, const NoRefreshablePricesNotice());
            return;
          }

          var updatedCount = 0;
          var failedCount = 0;
          // Sıralı istek: fiyat servislerini boğmamak için bilinçli olarak
          // paralel değil.
          for (final inv in targets) {
            final quoteResult = await getLiveQuoteUseCase(
              symbol: inv.symbol!,
              type: inv.type,
              targetCurrency: event.walletCurrency,
            );
            final ok = await quoteResult.fold(
              (_) async => false,
              (quote) async {
                final updated = inv.copyWith(
                  // convertedPrice cüzdanın biriminde; `amount` (maliyet) de
                  // öyle olduğundan kâr/zarar aynı birimde hesaplanır.
                  //
                  // YUVARLAMA ŞART: miktar × fiyat kuruş altı artık üretir
                  // (510 × 7.184,17… gibi). Ham bırakılırsa portföy toplamı
                  // .085'e denk gelip cüzdan metriği (roundToCents) ile özet
                  // kart (NumberFormat) farklı kuruşa yuvarlıyordu — üst
                  // çubuk 5.968.277,09 ₺ derken kart 5.968.277,08 ₺ diyordu.
                  currentValue:
                      roundToCents(inv.quantity! * quote.convertedPrice),
                  // Kaydedilen birim fiyat KAYNAĞININ birimi (bilgi amaçlı),
                  // değerleme birimi değil.
                  currency: quote.currency,
                );
                final saveResult = await updateInvestmentUseCase.call(updated);
                return saveResult.isRight();
              },
            );
            ok ? updatedCount++ : failedCount++;
          }

          await _safeSyncInvestment(event.walletId);
          if (updatedCount == 0) {
            emit(const InvestmentError(PricesUnavailableNotice()));
            // Bu yol zaten aşağıda listeyi yeniden yüklüyor; _emitError
            // gereksiz ikinci bir kare çizdirirdi.
          } else {
            emit(InvestmentActionSuccess(PricesRefreshedNotice(
              updated: updatedCount,
              failed: failedCount,
            )));
          }
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Kısmi Satış: kayıt kalır, elden çıkan kadarı cüzdana gelir olur.
    on<PartialSellInvestmentEvent>((event, emit) async {
      final key = 'sell:${event.remaining.id}';
      if (!_inFlight.add(key)) return;
      try {
        emit(InvestmentLoading());
        // Bedel bir NAKİT KASASINA: cüzdana gelir yazılmaz.
        final targetPot = event.targetPot;
        if (targetPot != null) {
          await _sellIntoPot(
            emit,
            userId: event.userId,
            walletId: event.walletId,
            potId: targetPot.id!,
            proceeds: event.proceeds,
            bookedMoved:
                roundToCents(event.previous.bookedCost - event.remaining.bookedCost),
            writeAsset: () => updateInvestmentUseCase.call(event.remaining),
            restoreAsset: () => updateInvestmentUseCase.call(event.previous),
            previousAsset: event.previous,
            notice: const InvestmentPartiallySoldNotice(),
          );
          return;
        }
        final result = await updateInvestmentUseCase.call(event.remaining);

        await result.fold(
          (failure) async =>
              _emitError(emit, RawFailureNotice(failure.message)),
          (_) async {
            // Bedelsiz devir (proceeds = 0) defterde 0 tutarlı bir hareket
            // bırakmasın; bkz. CreateInvestmentEvent'teki aynı koruma.
            var cashResult = const CashWriteResult(ok: true);
            if (event.proceeds > 0) {
              cashResult = await walletMetricsService.recordCashMovements(
                walletId: event.walletId,
                entries: [
                  CashMovement(
                    userId: event.userId,
                    amount: event.proceeds,
                    isIncome: true,
                    title: _isPot(event.remaining)
                        ? event.remaining.name
                        : 'Yatırım Satışı',
                    // Kasadan cüzdana çekiş satış değil, aktarımdır.
                    tag: _isPot(event.remaining)
                        ? CashMovementTags.savingsWithdraw
                        : CashMovementTags.investmentSell,
                    linkedRecordId: event.remaining.id,
                  ),
                ],
              );
            }
            await _safeSyncInvestment(event.walletId);
            emit(InvestmentActionSuccess(
              const InvestmentPartiallySoldNotice(),
              cashOk: cashResult.ok,
              // Geri alma kaydı ESKİ hâliyle geri yazar (aynı kimlik → üzerine
              // yazar) ve satış gelirini defterden siler.
              undo: InvestmentDeletionUndo(
                investment: event.previous,
                userId: event.userId,
                walletId: event.walletId,
                reversalTransactionIds: cashResult.transactionIds,
              ),
            ));
            add(GetInvestmentsEvent(
                userId: event.userId, walletId: event.walletId));
          },
        );
      } finally {
        _inFlight.remove(key);
      }
    });

    // Yatırım Sil
    on<DeleteInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());

      // Geri alma kaydın tamamını ister (sembol, adet, renk, katkı maliyeti…);
      // silmeden önce defterdeki hali okunur.
      final snapshot = await _investmentSnapshot(
        userId: event.userId,
        walletId: event.walletId,
        id: event.id,
      );

      // Satış bedeli bir NAKİT KASASINA: cüzdana gelir yazılmaz.
      final targetPot = event.targetPot;
      if (event.recordSale && targetPot != null && snapshot != null) {
        await _sellIntoPot(
          emit,
          userId: event.userId,
          walletId: event.walletId,
          potId: targetPot.id!,
          proceeds: event.currentValue,
          bookedMoved: event.amount,
          writeAsset: () => deleteInvestmentUseCase.call(event.id),
          restoreAsset: () => addInvestmentUseCase.call(snapshot),
          previousAsset: snapshot,
          notice: const InvestmentSoldNotice(),
        );
        return;
      }

      final result = await deleteInvestmentUseCase.call(event.id);

      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (_) async {
          // Nakit kuplajı: satışta güncel değer kadar gelir. Satış DEĞİLSE
          // (hatalı kayıt silme) eklemede yazılan alım gideri ters kayıtla
          // dengelenir; yoksa bakiye kalıcı düşük kalır ve sistem işlemi
          // UI'dan silinemediği için kullanıcı bunu düzeltemez.
          var cashResult = const CashWriteResult(ok: true);
          var released = const <TransactionEntity>[];
          if (event.recordSale) {
            // Çoğul yol: geri alma satış gelirinin kaydını id ile silmek
            // zorunda (tekil çağrı yalnız bool döner).
            cashResult = await walletMetricsService.recordCashMovements(
              walletId: event.walletId,
              entries: [
                CashMovement(
                  userId: event.userId,
                  amount: event.currentValue,
                  isIncome: true,
                  title: snapshot != null && _isPot(snapshot)
                      ? snapshot.name
                      : 'Yatırım Satışı',
                  tag: snapshot != null && _isPot(snapshot)
                      ? CashMovementTags.savingsWithdraw
                      : CashMovementTags.investmentSell,
                  linkedRecordId: event.id,
                ),
              ],
            );
          } else {
            // Hatalı giriş: BENİMSENMİŞ satırlar (ekstreden gelen alım) düz
            // hâllerine bırakılır — bankada para gerçekten çıktı, ters kayıt
            // yazmak cüzdanı bankadan koparırdı. Ters kayıt yalnız kuplajın
            // KENDİ yazdığı kısım için.
            released = await walletMetricsService.releaseAdoptedMovements(
              walletId: event.walletId,
              linkedRecordIds: {event.id},
            );
          }
          final adoptedCost = released.fold<double>(
              0, (sum, t) => sum + (t.isExpense ? t.amount : -t.amount));
          // Kuplajın KENDİ yazdığı net gider = işlenmiş maliyet − benimsenen
          // satır. Genelde pozitiftir; benimsemeden sonra maliyet AŞAĞI
          // düzeltildiyse (düzeltme geliri yazılmıştı) negatif olur ve tersi
          // gider olarak yazılır — aksi hâlde o düzeltme geliri yetim kalırdı.
          final correction = roundToCents(event.amount - adoptedCost);
          if (!event.recordSale && !moneyEquals(correction, 0)) {
            // event.amount = deftere İŞLENMİŞ maliyet (alım + Σ maliyet
            // güncellemeleri, "zaten bende" kısmı hariç); kümülatif alım
            // hareketlerini birebir tersine çevirir.
            //
            // Ters kayıt kaydın AÇILIŞ tarihine yazılır, bugüne değil: hatalı
            // girilip silinen kayıt (baskın durum) böylece kendi ayında
            // sıfırlanır. Maliyet DÜZENLEMELERİ de aynı tarihe yazıldığından
            // (bkz. `UpdateInvestmentEvent.bookingDate`) o bacak simetriktir.
            //
            // KALAN YAKLAŞIKLIK — katkılar: `ContributeSheet` parayı gerçekten
            // çıktığı gün (bugün) deftere yazar, tersleme ise kümülatif
            // `bookedCost`'u tek kalemde açılış tarihine yazar. Yani Ocak'ta
            // açılıp Haziran'da katkı yapılan bir kayıt Temmuz'da silinirse
            // Haziran'ın gideri tersi alınmamış, Ocak'a fazladan gelir yazılmış
            // olur (bakiye yine doğrudur). Düzeltmek için katkıların tek tek
            // TARİHLENMESİ gerekir; entity yalnız kümülatif `amount` tuttuğu
            // için bu bir ŞEMA değişikliğidir ve bilerek ertelenmiştir.
            cashResult = await walletMetricsService.recordCashMovements(
              walletId: event.walletId,
              entries: [
                CashMovement(
                  userId: event.userId,
                  amount: correction.abs(),
                  isIncome: correction > 0,
                  title: 'Yatırım kaydı silindi (düzeltme)',
                  tag: CashMovementTags.investmentCorrection,
                  date: event.dateAdded,
                  linkedRecordId: event.id,
                ),
              ],
            );
          }
          final cashOk = cashResult.ok;
          await _safeSyncInvestment(event.walletId);
          emit(InvestmentActionSuccess(
            event.recordSale
                ? const InvestmentSoldNotice()
                : const InvestmentDeletedNotice(),
            cashOk: cashOk,
            undo: snapshot == null
                ? null
                : InvestmentDeletionUndo(
                    investment: snapshot,
                    userId: event.userId,
                    walletId: event.walletId,
                    reversalTransactionIds: cashResult.transactionIds,
                    releasedAdoptions: released,
                  ),
          ));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
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
  /// Ölçülmüş emsal `PendingRecurringBloc`: onay listesi ekranda kaldığı için
  /// çift dokunma gerçekten iki işlem üretiyordu. Buradaki yollar hemen
  /// kapanan sheet'ten tetiklendiği için risk daha düşük — ama "para iki kez
  /// yazıldı" hatasının bedeli, korumanın maliyetinden büyük.
  final Set<String> _inFlight = <String>{};

  /// Hatayı yayınlar ve ardından son bilinen listeyi geri koyar: mesaj
  /// (snackbar) görülür ama ekran boşalmaz. Liste hiç yüklenmemişse yalnız
  /// hata kalır.
  void _emitError(Emitter<InvestmentState> emit, InvestmentNotice notice) {
    emit(InvestmentError(notice));
    final last = _lastLoaded;
    if (last != null) emit(last);
  }

  Future<void> _safeSyncInvestment(String walletId) => safeSyncMetric(
      () => walletMetricsService.syncInvestment(walletId), 'investment');

  static bool _isPot(InvestmentEntity i) => i.type == InvestmentType.cash;

  /// Kasanın diskteki TAZE hâli (form açıkken başka bir işlemle değişmiş
  /// olabilir); kasa değilse ya da yoksa `null`.
  Future<InvestmentEntity?> _freshPot(
      String userId, String walletId, String potId) async {
    final pot =
        await _investmentSnapshot(userId: userId, walletId: walletId, id: potId);
    return pot != null && _isPot(pot) ? pot : null;
  }

  /// Yeni varlık bir NAKİT KASASINDAN alınır: kasa düşer, varlık yazılır,
  /// defter değişmez. Kasa yazılamazsa varlık geri silinir — yarım işlem
  /// (para iki yerde ya da hiçbir yerde) kalmaz.
  Future<void> _createFromPot(
    CreateInvestmentEvent event,
    InvestmentEntity investment,
    String potId,
    Emitter<InvestmentState> emit,
  ) async {
    final cost = roundToCents(investment.amount);
    final pot = await _freshPot(event.userId, event.walletId, potId);
    if (pot == null || !moneyGte(pot.amount, cost)) {
      _emitError(emit, const PotUnavailableNotice());
      return;
    }
    final take = takeFromPot(pot, cost);
    final asset = bookAssetFromPot(investment,
        cost: cost, movedBooked: take.movedBooked, isNew: true);
    final added = await addInvestmentUseCase.call(asset);
    if (added.isLeft()) {
      _emitError(emit, RawFailureNotice(_failureText(added)));
      return;
    }
    final potSaved = await updateInvestmentUseCase.call(take.pot);
    if (potSaved.isLeft()) {
      await deleteInvestmentUseCase.call(asset.id!);
      _emitError(emit, RawFailureNotice(_failureText(potSaved)));
      return;
    }
    await _safeSyncInvestment(event.walletId);
    emit(const InvestmentActionSuccess(InvestmentAddedNotice()));
    add(GetInvestmentsEvent(userId: event.userId, walletId: event.walletId));
  }

  /// Var olan varlığa KATKI bir nakit kasasından: maliyet artışı
  /// (`newAmount − prevAmount`) kasadan düşer, defter değişmez.
  Future<void> _contributeFromPot(
    UpdateInvestmentEvent event,
    String potId,
    Emitter<InvestmentState> emit,
  ) async {
    final cost = roundToCents(event.newAmount - event.prevAmount);
    final previous = await _investmentSnapshot(
        userId: event.userId,
        walletId: event.walletId,
        id: event.investment.id ?? '');
    final pot = await _freshPot(event.userId, event.walletId, potId);
    if (previous == null ||
        pot == null ||
        cost <= 0 ||
        !moneyGte(pot.amount, cost)) {
      _emitError(emit, const PotUnavailableNotice());
      return;
    }
    final take = takeFromPot(pot, cost);
    final asset = bookAssetFromPot(event.investment,
        cost: cost, movedBooked: take.movedBooked, isNew: false);
    final saved = await updateInvestmentUseCase.call(asset);
    if (saved.isLeft()) {
      _emitError(emit, RawFailureNotice(_failureText(saved)));
      return;
    }
    final potSaved = await updateInvestmentUseCase.call(take.pot);
    if (potSaved.isLeft()) {
      await updateInvestmentUseCase.call(previous);
      _emitError(emit, RawFailureNotice(_failureText(potSaved)));
      return;
    }
    await _safeSyncInvestment(event.walletId);
    emit(const InvestmentActionSuccess(InvestmentUpdatedNotice()));
    add(GetInvestmentsEvent(userId: event.userId, walletId: event.walletId));
  }

  /// Satış bedeli bir NAKİT KASASINA girer: varlık yazılır (kalan hâli ya da
  /// silinir), kasa artar, defter değişmez. Satılan kısmın işlenmiş maliyeti
  /// ([bookedMoved]) kasaya geçer. Geri alma varlığı VE kasayı eski hâline
  /// döndürür.
  Future<void> _sellIntoPot(
    Emitter<InvestmentState> emit, {
    required String userId,
    required String walletId,
    required String potId,
    required double proceeds,
    required double bookedMoved,
    required Future<Either<Failure, dynamic>> Function() writeAsset,
    required Future<Either<Failure, dynamic>> Function() restoreAsset,
    required InvestmentEntity previousAsset,
    required InvestmentNotice notice,
  }) async {
    final pot = await _freshPot(userId, walletId, potId);
    if (pot == null || pot.id == previousAsset.id) {
      _emitError(emit, const PotUnavailableNotice());
      return;
    }
    final written = await writeAsset();
    if (written.isLeft()) {
      _emitError(emit, RawFailureNotice(_failureText(written)));
      return;
    }
    final potSaved = await updateInvestmentUseCase
        .call(putIntoPot(pot, proceeds, booked: bookedMoved));
    if (potSaved.isLeft()) {
      await restoreAsset();
      _emitError(emit, RawFailureNotice(_failureText(potSaved)));
      return;
    }
    await _safeSyncInvestment(walletId);
    emit(InvestmentActionSuccess(
      notice,
      undo: InvestmentDeletionUndo(
        investment: previousAsset,
        userId: userId,
        walletId: walletId,
        reversalTransactionIds: const [],
        alsoRestore: [pot],
      ),
    ));
    add(GetInvestmentsEvent(userId: userId, walletId: walletId));
  }

  static String _failureText(Either<Failure, dynamic> r) =>
      r.fold((f) => f.message, (_) => '');

  /// Silinecek/satılacak yatırımın defterdeki hali; bulunamazsa `null`
  /// (geri alma sunulmaz, silme yine yapılır).
  Future<InvestmentEntity?> _investmentSnapshot({
    required String userId,
    required String walletId,
    required String id,
  }) async {
    final Either<Failure, List<InvestmentEntity>> result;
    try {
      result = await getInvestmentsUseCase.call(
        userId: userId,
        walletId: walletId,
      );
    } catch (e) {
      debugPrint('Geri alma anlık görüntüsü alınamadı (yatırım): $e');
      return null;
    }
    return result.fold(
      (_) => null,
      (investments) {
        for (final i in investments) {
          if (i.id == id) return i;
        }
        return null;
      },
    );
  }
}
