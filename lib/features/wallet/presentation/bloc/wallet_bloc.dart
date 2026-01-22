import 'package:bloc/bloc.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

// ✅ DOĞRU - UseCase'leri inject et
@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletGetUseCase getWalletsUseCase;
  final WalletCreateUseCase createWalletUseCase;
  final WalletUpdateUseCase updateWalletUseCase;
  final WalletDeleteUseCase deleteWalletUseCase;
  final WalletSetActiveUseCase setActiveWalletUseCase;

  WalletBloc({
    required this.getWalletsUseCase,
    required this.createWalletUseCase,
    required this.updateWalletUseCase,
    required this.deleteWalletUseCase,
    required this.setActiveWalletUseCase,
  }) : super(const NoWalletSt()) {
    on<GetWalletsEvent>((event, emit) async {
      if (state is! WalletLoadedSt) {
        emit(const WalletLoadingSt());
      }

      try {
        await getWalletsUseCase.call(event.userId).then(
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
        // 1. UseCase'i çağır ve oluşturulan yeni ID'yi al.
        final newWalletId = await createWalletUseCase.call(event.wallet);

        // after creation, set it as active
        try {
          // 2. Dönen yeni ID'yi kullanarak cüzdanı aktif yap.
          await setActiveWalletUseCase.call(
            userId: event.wallet.userId,
            walletId: newWalletId,
          );
        } catch (e) {
          emit(WalletErrorSt('Aktif cüzdan ayarlanamadı: ${e.toString()}'));
        }
        emit(const WalletOperationSuccesSt("Cüzdan oluşturuldu!"));
      } catch (e) {
        emit(WalletErrorSt('Cüzdan oluşturulamadı: ${e.toString()}'));
      }
    });

    // ========== CÜZDAN GÜNCELLE ==========
    on<UpdateWalletEvent>((event, emit) async {
      try {
        await updateWalletUseCase.call(event.wallet);
        emit(const WalletOperationSuccesSt("Cüzdan güncellendi!"));
      } catch (e) {
        emit(WalletErrorSt('Cüzdan güncellenemedi: ${e.toString()}'));
      }
    });

    // ========== CÜZDAN SİL ==========
    on<DeleteWalletEvent>((event, emit) async {
      try {
        await deleteWalletUseCase.call(event.walletId);
        emit(const WalletOperationSuccesSt("Cüzdan silindi!"));
      } catch (e) {
        emit(WalletErrorSt('Cüzdan silinemedi: ${e.toString()}'));
      }
    });

    // ========== AKTİF CÜZDANI DEĞİŞTİR ==========
    on<SetActiveWalletEvent>((event, emit) async {
      try {
        await setActiveWalletUseCase.call(
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
