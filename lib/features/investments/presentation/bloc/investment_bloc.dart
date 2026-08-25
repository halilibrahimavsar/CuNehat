import 'dart:async';

import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/transactions_changed_notifier.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/core/utils/money_math.dart';
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
      emit(InvestmentLoading());
      final result = await addInvestmentUseCase.call(event.investment);

      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (_) async {
          // Nakit kuplajı: yatırım alımı → maliyet kadar gider.
          //
          // İki incelik:
          // - Yalnız DEFTERE İŞLENECEK kısım yazılır. "Bu varlık zaten bende"
          //   denen tutar (unbookedCost) cüzdandan hiç çıkmadı; bugünün
          //   defterine sahte gider yazmak bakiyeyi olduğundan düşük gösterir.
          // - Gider kaydın TARİHİNE yazılır (bugüne değil): geçmişte alınmış
          //   bir varlık kendi ayında görünür. Yeni kayıtta tarih zaten bugün.
          final bookedCost = event.investment.bookedCost;
          var cashOk = true;
          if (bookedCost > 0) {
            cashOk = await walletMetricsService.recordCashMovement(
              walletId: event.walletId,
              userId: event.userId,
              amount: bookedCost,
              isIncome: false,
              title: event.investment.name,
              tag: CashMovementTags.investmentBuy,
              date: event.investment.dateAdded,
            );
          }
          await _safeSyncInvestment(event.walletId);
          emit(InvestmentActionSuccess(const InvestmentAddedNotice(),
              cashOk: cashOk));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Yatırım Güncelle
    on<UpdateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await updateInvestmentUseCase.call(event.investment);

      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (_) async {
          // Mutabakat: maliyet (anapara) değişimi kadar nakit.
          // Maliyet arttı → gider; azaldı → gelir. (currentValue değişimi
          // gerçekleşmemiş kâr/zarar olduğundan nakdi etkilemez.)
          final costDiff = event.newAmount - event.prevAmount;
          var cashOk = true;
          if (costDiff != 0) {
            cashOk = await walletMetricsService.recordCashMovement(
              walletId: event.walletId,
              userId: event.userId,
              amount: costDiff.abs(),
              isIncome: costDiff < 0,
              title: 'Yatırım güncellendi: ${event.investment.name}',
              tag: CashMovementTags.investmentBuy,
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
      emit(InvestmentLoading());
      final result = await updateInvestmentUseCase.call(event.remaining);

      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
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
                  title: 'Yatırım Satışı',
                  tag: CashMovementTags.investmentSell,
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

      final result = await deleteInvestmentUseCase.call(event.id);

      await result.fold(
        (failure) async => _emitError(emit, RawFailureNotice(failure.message)),
        (_) async {
          // Nakit kuplajı: satışta güncel değer kadar gelir. Satış DEĞİLSE
          // (hatalı kayıt silme) eklemede yazılan alım gideri ters kayıtla
          // dengelenir; yoksa bakiye kalıcı düşük kalır ve sistem işlemi
          // UI'dan silinemediği için kullanıcı bunu düzeltemez.
          var cashResult = const CashWriteResult(ok: true);
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
                  title: 'Yatırım Satışı',
                  tag: CashMovementTags.investmentSell,
                ),
              ],
            );
          } else if (event.amount > 0) {
            // event.amount = deftere İŞLENMİŞ maliyet (alım + Σ maliyet
            // güncellemeleri, "zaten bende" kısmı hariç); kümülatif alım
            // hareketlerini birebir tersine çevirir.
            //
            // Ters kayıt kaydın AÇILIŞ tarihine yazılır, bugüne değil: hatalı
            // girilip silinen kayıt (baskın durum) böylece kendi ayında
            // sıfırlanır. Katkılar tek tek tarihlenmediğinden (entity yalnız
            // kümülatif `amount` tutar), çok katkılı bir birikimde tersleme
            // açılış ayında toplanır — bu bilinçli bir yaklaşıklıktır.
            cashResult = await walletMetricsService.recordCashMovements(
              walletId: event.walletId,
              entries: [
                CashMovement(
                  userId: event.userId,
                  amount: event.amount,
                  isIncome: true,
                  title: 'Yatırım kaydı silindi (düzeltme)',
                  tag: CashMovementTags.investmentCorrection,
                  date: event.dateAdded,
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
