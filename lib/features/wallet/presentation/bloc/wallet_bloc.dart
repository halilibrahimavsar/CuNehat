import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cunehat/features/wallet/data/datasource/get_storage_mod.dart';
import 'package:cunehat/features/wallet/data/repository/wallet_repository_impl.dart';
import 'package:cunehat/features/wallet/domain/model/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:equatable/equatable.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepositoryImpl repository =
      WalletRepositoryImpl(dataSource: GetStorageMod.dataSource);

  // Stream subscription'ı tutmak için
  StreamSubscription<List<WalletModel>>? _walletSubscription;

  WalletBloc() : super(const WalletInitialSt()) {
    // ========== CÜZDANLARI GETİR (STREAM DİNLE) ==========
    on<GetWalletsEvent>((event, emit) async {
      emit(const WalletLoadingSt());

      // Önceki subscription'ı iptal et
      await _walletSubscription?.cancel();

      try {
        // Stream'i dinle
        _walletSubscription =
            WalletGetUseCase(repository).call(event.userId).listen(
          (wallets) {
            if (wallets.isEmpty) {
              add(const _EmitNoDataEvent());
            } else {
              add(_EmitLoadedEvent(wallets));
            }
          },
          onError: (error) {
            add(_EmitErrorEvent(error.toString()));
          },
        );
      } catch (e) {
        emit(WalletErrorSt(e.toString()));
      }
    });

    // ========== İÇ EVENT'LER (STREAM'DEN GELEN DATA) ==========
    on<_EmitLoadedEvent>((event, emit) {
      emit(WalletLoadedSt(event.wallets));
    });

    on<_EmitNoDataEvent>((event, emit) {
      emit(const NoDataSt());
    });

    on<_EmitErrorEvent>((event, emit) {
      emit(WalletErrorSt(event.error));
    });

    // ========== CÜZDAN OLUŞTUR ==========
    on<CreateWalletEvent>((event, emit) async {
      try {
        await WalletCreateUseCase(repository).call(event.wallet);
        emit(const WalletCreatedSt());
      } catch (e) {
        emit(WalletErrorSt('Cüzdan oluşturulamadı: ${e.toString()}'));
      }
    });

    // ========== CÜZDAN GÜNCELLE ==========
    on<UpdateWalletEvent>((event, emit) async {
      try {
        await WalletUpdateUseCase(repository).call(event.wallet);
        emit(const WalletUpdatedSt());
      } catch (e) {
        emit(WalletErrorSt('Cüzdan güncellenemedi: ${e.toString()}'));
      }
    });

    // ========== CÜZDAN SİL ==========
    on<DeleteWalletEvent>((event, emit) async {
      try {
        await WalletDeleteUseCase(repository).call(event.walletId);
        emit(const WalletDeletedSt());
      } catch (e) {
        emit(WalletErrorSt('Cüzdan silinemedi: ${e.toString()}'));
      }
    });

    // ========== AKTİF CÜZDANI DEĞİŞTİR ==========
    on<SetActiveWalletEvent>((event, emit) async {
      try {
        await WalletSetActiveUseCase(repository).call(
          userId: event.userId,
          walletId: event.walletId,
        );
        // Aktif cüzdan değiştikten sonra listeyi yeniden yükle
        add(GetWalletsEvent(event.userId));
      } catch (e) {
        emit(WalletErrorSt('Aktif cüzdan değiştirilemedi: ${e.toString()}'));
      }
    });
  }
}

// ========== İÇ EVENT'LER (Stream sonuçlarını emit etmek için) ==========
class _EmitLoadedEvent extends WalletEvent {
  final List<WalletModel> wallets;

  const _EmitLoadedEvent(this.wallets);

  @override
  List<Object> get props => [wallets];
}

class _EmitNoDataEvent extends WalletEvent {
  const _EmitNoDataEvent();
}

class _EmitErrorEvent extends WalletEvent {
  final String error;

  const _EmitErrorEvent(this.error);

  @override
  List<Object> get props => [error];
}
