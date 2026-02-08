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
  final WalletWatchUseCase watchWalletsUseCase;
  final WalletCreateUseCase createWalletUseCase;
  final WalletUpdateUseCase updateWalletUseCase;
  final WalletDeleteUseCase deleteWalletUseCase;
  final WalletSetActiveUseCase setActiveWalletUseCase;

  WalletBloc({
    required this.getWalletsUseCase,
    required this.watchWalletsUseCase,
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
        final wallets = await getWalletsUseCase.call(event.userId);
        if (wallets.isEmpty) {
          emit(const NoWalletSt());
        } else {
          // Find the active wallet from the list
          var activeWallet = _findActiveWallet(wallets);

          // Fallback: If no wallet is marked as active in the retrieved list,
          // it means either no active wallet is set or it was deleted.
          // In this case, we pick the first one and set it as active.
          if (activeWallet == null && wallets.isNotEmpty) {
            final fallbackWallet = wallets.first;
            add(SetActiveWalletEvent(
              userId: event.userId,
              walletId: fallbackWallet.id!,
            ));
            emit(WalletLoadedSt(wallets, fallbackWallet));
            return;
          }

          emit(WalletLoadedSt(wallets, activeWallet));
        }
      } catch (e) {
        emit(WalletErrorSt(e.toString()));
      }
    });

    on<WatchWalletsEvent>((event, emit) async {
      emit(const WalletLoadingSt());
      await emit.forEach<List<WalletEntity>>(
        watchWalletsUseCase(event.userId),
        onData: (wallets) {
          if (wallets.isEmpty) {
            return const NoWalletSt();
          }

          final activeWallet = _findActiveWallet(wallets);

          if (activeWallet == null && wallets.isNotEmpty) {
            final fallbackWallet = wallets.first;
            add(SetActiveWalletEvent(
              userId: event.userId,
              walletId: fallbackWallet.id!,
            ));
            return WalletLoadedSt(wallets, fallbackWallet);
          }

          return WalletLoadedSt(wallets, activeWallet);
        },
        onError: (error, _) => WalletErrorSt(error.toString()),
      );
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
        emit(const WalletOperationSuccessSt("Cüzdan oluşturuldu!"));
      } catch (e) {
        emit(WalletErrorSt('Cüzdan oluşturulamadı: ${e.toString()}'));
      }
    });

    // ========== CÜZDAN GÜNCELLE ==========
    on<UpdateWalletEvent>((event, emit) async {
      try {
        await updateWalletUseCase.call(event.wallet);
        emit(const WalletOperationSuccessSt("Cüzdan güncellendi!"));
      } catch (e) {
        emit(WalletErrorSt('Cüzdan güncellenemedi: ${e.toString()}'));
      }
    });

    // ========== CÜZDAN SİL ==========
    on<DeleteWalletEvent>((event, emit) async {
      try {
        await deleteWalletUseCase.call(event.walletId);
        emit(const WalletOperationSuccessSt("Cüzdan silindi!"));
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
        emit(const WalletOperationSuccessSt("Cüzdan seçildi"));
      } catch (e) {
        emit(WalletErrorSt('Aktif cüzdan değiştirilemedi: ${e.toString()}'));
      }
    });
  }

  WalletEntity? _findActiveWallet(List<WalletEntity> wallets) {
    for (final wallet in wallets) {
      if (wallet.isActive) return wallet;
    }
    return null;
  }
}
