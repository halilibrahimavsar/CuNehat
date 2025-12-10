import 'package:bloc/bloc.dart';
import 'package:cunehat/features/wallet/data/models/wallet_model.dart';
import 'package:cunehat/features/wallet/domain/repository/wallet_repository.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:equatable/equatable.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository repository;
  WalletBloc(this.repository) : super(const NoWalletSt()) {
    on<GetWalletsEvent>((event, emit) async {
      emit(const WalletLoadingSt());

      try {
        await WalletGetUseCase(repository).call(event.userId).then(
          (wallets) {
            if (wallets.isEmpty) {
              emit(const NoWalletSt());
            } else {
              final activeWallet = wallets.firstWhere(
                (wallet) {
                  return wallet.isActive == true;
                },
                orElse: () {
                  return wallets.first;
                },
              );
              emit(WalletLoadedSt(wallets, activeWallet));
            }
          },
          onError: (error) {
            emit(WalletErrorSt(error.toString()));
          },
        );
      } catch (e) {
        emit(WalletErrorSt(e.toString()));
      }
    });

    // ========== CÜZDAN OLUŞTUR ==========
    on<CreateWalletEvent>((event, emit) async {
      try {
        await WalletCreateUseCase(repository).call(event.wallet);
        // after creation, set it as active
        await WalletSetActiveUseCase(repository).call(
          userId: event.userId,
          walletId: event.wallet.id,
        );
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
