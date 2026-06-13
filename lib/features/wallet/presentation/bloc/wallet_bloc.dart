import 'package:bloc/bloc.dart';
import 'package:cunehat/core/error/failure.dart';
import 'package:cunehat/core/services/wallet_metrics_service.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletGetUseCase getWalletsUseCase;
  final WalletWatchUseCase watchWalletsUseCase;
  final WalletCreateUseCase createWalletUseCase;
  final WalletUpdateUseCase updateWalletUseCase;
  final WalletDeleteUseCase deleteWalletUseCase;
  final WalletSetActiveUseCase setActiveWalletUseCase;
  final WalletMetricsService walletMetricsService;

  WalletBloc({
    required this.getWalletsUseCase,
    required this.watchWalletsUseCase,
    required this.createWalletUseCase,
    required this.updateWalletUseCase,
    required this.deleteWalletUseCase,
    required this.setActiveWalletUseCase,
    required this.walletMetricsService,
  }) : super(const WalletInitialSt()) {
    on<GetWalletsEvent>((event, emit) async {
      if (state is! WalletLoadedSt) {
        emit(const WalletLoadingSt());
      }

      final result = await getWalletsUseCase.call(event.userId);
      result.fold(
        (failure) => emit(WalletErrorSt(failure.message)),
        (wallets) {
          if (wallets.isEmpty) {
            emit(const NoWalletSt());
          } else {
            var activeWallet = _findActiveWallet(wallets);

            if (activeWallet == null && wallets.isNotEmpty) {
              final fallbackWallet = wallets.first;
              add(SetActiveWalletEvent(
                userId: event.userId,
                walletId: fallbackWallet.id!,
              ));
              _safeSyncBalance(fallbackWallet.id!);
              emit(WalletLoadedSt(wallets, fallbackWallet));
              return;
            }

            if (activeWallet != null) _safeSyncBalance(activeWallet.id!);
            emit(WalletLoadedSt(wallets, activeWallet));
          }
        },
      );
    });

    on<WatchWalletsEvent>((event, emit) async {
      if (state is! WalletLoadedSt) {
        emit(const WalletLoadingSt());
      }

      await emit.forEach<Either<Failure, List<WalletEntity>>>(
        watchWalletsUseCase(event.userId),
        onData: (result) {
          return result.fold(
            (failure) => WalletErrorSt(failure.message),
            (wallets) {
              if (wallets.isEmpty) {
                return const NoWalletSt();
              }

              final activeWallet = _findActiveWallet(wallets);

              if (activeWallet == null && wallets.isNotEmpty) {
                final fallbackWallet = wallets.first;
                // SetActiveWalletEvent users box'a yazar; bu da userSub'ı tetikler.
                // Ancak wallet box'unu DEĞİŞTİRMEZ, bu yüzden walletSub döngüsüne girmez.
                add(SetActiveWalletEvent(
                  userId: event.userId,
                  walletId: fallbackWallet.id!,
                ));
                return WalletLoadedSt(wallets, fallbackWallet);
              }

              // NOT: _safeSyncBalance burada KASTEN ÇAĞRILMIYOR.
              // syncBalance() → walletRepository.updateWallet() → walletBox'a yazar
              // → walletBox.watch() tetiklenir → onData tekrar çağrılır → sonsuz döngü.
              // Bakiye, her para mutasyonundan sonra (işlem CRUD ve
              // recordCashMovement) WalletMetricsService.syncBalance ile defterden
              // yeniden hesaplanıyor; onData hiç yazmadığı ve syncBalance tutarlıyken
              // no-op olduğu için döngü oluşmaz.
              return WalletLoadedSt(wallets, activeWallet);
            },
          );
        },
        onError: (error, _) => WalletErrorSt(error.toString()),
      );
    });

    // ========== CÜZDAN OLUŞTUR ==========
    on<CreateWalletEvent>((event, emit) async {
      final result = await createWalletUseCase.call(event.wallet);
      await result.fold(
        (failure) async =>
            _emitError(emit, 'Cüzdan oluşturulamadı: ${failure.message}'),
        (newWalletId) async {
          final activeResult = await setActiveWalletUseCase.call(
            userId: event.wallet.userId,
            walletId: newWalletId,
          );
          activeResult.fold(
            (f) => _emitError(emit, 'Aktif cüzdan ayarlanamadı: ${f.message}'),
            (_) => _emitSuccess(emit, WalletMessageType.created),
          );
        },
      );
    });

    // ========== CÜZDAN GÜNCELLE ==========
    on<UpdateWalletEvent>((event, emit) async {
      // Manuel bakiye düzenlemesi defter değişmezini (`balance = opening +
      // Σtx`) bozmasın: bakiye farkı opening'e yansıtılır; böylece sonraki
      // syncBalance kullanıcının düzeltmesini geri almaz.
      var toWrite = event.wallet;
      final current = state;
      if (current is WalletLoadedSt) {
        for (final old in current.wallets) {
          if (old.id == event.wallet.id) {
            final newOpening = (old.openingBalance ?? old.balance) +
                (event.wallet.balance - old.balance);
            toWrite = event.wallet.copyWith(openingBalance: newOpening);
            break;
          }
        }
      }
      final result = await updateWalletUseCase.call(toWrite);
      result.fold(
        (failure) =>
            _emitError(emit, 'Cüzdan güncellenemedi: ${failure.message}'),
        (_) => _emitSuccess(emit, WalletMessageType.updated),
      );
    });

    // ========== CÜZDAN SİL ==========
    on<DeleteWalletEvent>((event, emit) async {
      final current = state;
      if (current is WalletLoadedSt) {
        for (final w in current.wallets) {
          if (w.id == event.walletId) {
            await walletMetricsService.purgeWalletData(
                event.walletId, w.userId);
            break;
          }
        }
      }
      final result = await deleteWalletUseCase.call(event.walletId);
      result.fold(
        (failure) => _emitError(emit, 'Cüzdan silinemedi: ${failure.message}'),
        (_) => _emitSuccess(emit, WalletMessageType.deleted),
      );
    });

    // ========== AKTİF CÜZDANI DEĞİŞTİR ==========
    on<SetActiveWalletEvent>((event, emit) async {
      final result = await setActiveWalletUseCase.call(
        userId: event.userId,
        walletId: event.walletId,
      );
      result.fold(
        (failure) => _emitError(
            emit, 'Aktif cüzdan değiştirilemedi: ${failure.message}'),
        (_) => _emitSuccess(emit, WalletMessageType.selected),
      );
    });
  }

  void _emitSuccess(Emitter<WalletState> emit, WalletMessageType type) {
    if (state is WalletLoadedSt) {
      emit((state as WalletLoadedSt)
          .copyWith(messageType: type, clearError: true));
    } else if (state is NoWalletSt) {
      emit(NoWalletSt(messageType: type));
    }
  }

  void _emitError(Emitter<WalletState> emit, String error) {
    if (state is WalletLoadedSt) {
      emit(
          (state as WalletLoadedSt).copyWith(error: error, clearMessage: true));
    } else if (state is NoWalletSt) {
      emit(NoWalletSt(error: error));
    } else {
      emit(WalletErrorSt(error));
    }
  }

  WalletEntity? _findActiveWallet(List<WalletEntity> wallets) {
    for (final wallet in wallets) {
      if (wallet.isActive) return wallet;
    }
    return null;
  }

  void _safeSyncBalance(String walletId) {
    walletMetricsService.syncBalance(walletId).catchError((Object e) {
      debugPrint('Açılış bakiye senkronizasyonu başarısız: $e');
      return false;
    });
  }
}
