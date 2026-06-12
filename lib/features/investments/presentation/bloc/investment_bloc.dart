import 'package:cunehat/core/blocs/cash_coupling_mixin.dart';
import 'package:bloc/bloc.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/domain/usecases/add_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/delete_investment_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_investments_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/get_live_quote_usecase.dart';
import 'package:cunehat/features/investments/domain/usecases/update_investment_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

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
  final WalletMetricsService walletMetricsService;

  InvestmentBloc({
    required this.getInvestmentsUseCase,
    required this.addInvestmentUseCase,
    required this.updateInvestmentUseCase,
    required this.deleteInvestmentUseCase,
    required this.getLiveQuoteUseCase,
    required this.walletMetricsService,
  }) : super(InvestmentInitial()) {
    // Yatırımları Getir
    on<GetInvestmentsEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await getInvestmentsUseCase.call(
        userId: event.userId,
        walletId: event.walletId,
      );

      result.fold(
        (failure) => emit(InvestmentError(failure.message)),
        (investments) {
          final total =
              investments.fold<double>(0, (sum, item) => sum + item.amount);
          emit(InvestmentLoaded(investments, totalAmount: total));
        },
      );
    });

    // Yatırım Ekle
    on<CreateInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await addInvestmentUseCase.call(event.investment);

      await result.fold(
        (failure) async => emit(InvestmentError(failure.message)),
        (_) async {
          // Nakit kuplajı: yatırım alımı → maliyet kadar gider.
          final cashOk = await walletMetricsService.recordCashMovement(
            walletId: event.walletId,
            userId: event.userId,
            amount: event.investment.amount,
            isIncome: false,
            title: event.investment.name,
            tag: CashMovementTags.investmentBuy,
          );
          await _safeSyncInvestment(event.walletId);
          emit(InvestmentActionSuccess(
              'Yatırım başarıyla eklendi${cashOk ? '' : CashCouplingMixin.cashWarning}'));
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
        (failure) async => emit(InvestmentError(failure.message)),
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
          emit(InvestmentActionSuccess(
              'Yatırım güncellendi${cashOk ? '' : CashCouplingMixin.cashWarning}'));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Fiyat Yenile: güncel değer = miktar × canlı TL fiyatı. Maliyet
    // değişmediği için (costDiff yok) defterde nakit hareketi oluşmaz;
    // yalnızca portföy/birikim metriği senkronlanır.
    on<RefreshPricesEvent>((event, emit) async {
      emit(InvestmentLoading());
      final listResult = await getInvestmentsUseCase.call(
        userId: event.userId,
        walletId: event.walletId,
      );

      await listResult.fold(
        (failure) async => emit(InvestmentError(failure.message)),
        (investments) async {
          final targets = investments
              .where((inv) =>
                  inv.canRefreshPrice &&
                  (event.investmentId == null ||
                      inv.id == event.investmentId))
              .toList();

          if (targets.isEmpty) {
            emit(const InvestmentError(
                'Yenilenebilir yatırım yok (sembol ve miktar gerekli)'));
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
            );
            final ok = await quoteResult.fold(
              (_) async => false,
              (quote) async {
                final updated = inv.copyWith(
                  currentValue: inv.quantity! * quote.priceTl,
                  currency: quote.currency,
                );
                final saveResult =
                    await updateInvestmentUseCase.call(updated);
                return saveResult.isRight();
              },
            );
            ok ? updatedCount++ : failedCount++;
          }

          await _safeSyncInvestment(event.walletId);
          if (updatedCount == 0) {
            emit(const InvestmentError(
                'Fiyatlar alınamadı, değerler değiştirilmedi'));
          } else {
            emit(InvestmentActionSuccess(failedCount == 0
                ? '$updatedCount yatırımın fiyatı güncellendi'
                : '$updatedCount güncellendi, $failedCount alınamadı'));
          }
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });

    // Yatırım Sil
    on<DeleteInvestmentEvent>((event, emit) async {
      emit(InvestmentLoading());
      final result = await deleteInvestmentUseCase.call(event.id);

      await result.fold(
        (failure) async => emit(InvestmentError(failure.message)),
        (_) async {
          // Nakit kuplajı: satışta güncel değer kadar gelir. Satış DEĞİLSE
          // (hatalı kayıt silme) eklemede yazılan alım gideri ters kayıtla
          // dengelenir; yoksa bakiye kalıcı düşük kalır ve sistem işlemi
          // UI'dan silinemediği için kullanıcı bunu düzeltemez.
          var cashOk = true;
          if (event.recordSale) {
            cashOk = await walletMetricsService.recordCashMovement(
              walletId: event.walletId,
              userId: event.userId,
              amount: event.currentValue,
              isIncome: true,
              title: 'Yatırım Satışı',
              tag: CashMovementTags.investmentSell,
            );
          } else if (event.amount > 0) {
            // event.amount = güncel maliyet (alım + Σ maliyet güncellemeleri);
            // kümülatif alım hareketlerini birebir tersine çevirir.
            cashOk = await walletMetricsService.recordCashMovement(
              walletId: event.walletId,
              userId: event.userId,
              amount: event.amount,
              isIncome: true,
              title: 'Yatırım kaydı silindi (düzeltme)',
              tag: CashMovementTags.investmentCorrection,
            );
          }
          await _safeSyncInvestment(event.walletId);
          emit(InvestmentActionSuccess(event.recordSale
              ? 'Yatırım satıldı${cashOk ? '' : CashCouplingMixin.cashWarning}'
              : 'Kayıt silindi, alım kaydı düzeltildi'
                  '${cashOk ? '' : CashCouplingMixin.cashWarning}'));
          add(GetInvestmentsEvent(
              userId: event.userId, walletId: event.walletId));
        },
      );
    });
  }

  Future<void> _safeSyncInvestment(String walletId) => safeSyncMetric(
      () => walletMetricsService.syncInvestment(walletId), 'investment');
}
