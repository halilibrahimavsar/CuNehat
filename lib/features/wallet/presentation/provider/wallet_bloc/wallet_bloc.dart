import 'package:bloc/bloc.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:equatable/equatable.dart';

part 'wallet_events.dart';
part 'wallet_states.dart';

// ============ BLOC ============
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final DataRepository _repository;

  WalletBloc({required DataRepository repository})
      : _repository = repository,
        super(WalletInitial()) {
    on<LoadWalletsEvent>(_onLoadWallets);
    on<CreateWalletEvent>(_onCreateWallet);
    on<UpdateWalletEvent>(_onUpdateWallet);
    on<DeleteWalletEvent>(_onDeleteWallet);
    on<SetActiveWalletEvent>(_onSetActiveWallet);
    on<TransferBetweenWalletsEvent>(_onTransferBetweenWallets);
  }

  Future<void> _onLoadWallets(
    LoadWalletsEvent event,
    Emitter<WalletState> emit,
  ) async {
    emit(WalletLoading());

    try {
      final wallets = await _repository.getAllWallets();
      final activeWalletId = _repository.getActiveWalletId();

      emit(WalletsLoaded(
        wallets: wallets.toList(),
        activeWalletId: activeWalletId,
      ));
    } catch (e) {
      emit(WalletError('Cüzdanlar yüklenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onCreateWallet(
    CreateWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _repository.createWallet(wallet: event.wallet);

      emit(const WalletOperationSuccess(
        message: 'Cüzdan başarıyla oluşturuldu',
        type: WalletOperationType.create,
      ));

      // Reload wallets
      add(LoadWalletsEvent());
    } catch (e) {
      emit(WalletError('Cüzdan oluşturulurken hata: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateWallet(
    UpdateWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _repository.updateWallet(wallet: event.wallet);

      emit(const WalletOperationSuccess(
        message: 'Cüzdan başarıyla güncellendi',
        type: WalletOperationType.update,
      ));

      // Reload wallets
      add(LoadWalletsEvent());
    } catch (e) {
      emit(WalletError('Cüzdan güncellenirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteWallet(
    DeleteWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _repository.deleteWallet(event.walletId);

      emit(const WalletOperationSuccess(
        message: 'Cüzdan başarıyla silindi',
        type: WalletOperationType.delete,
      ));

      // Reload wallets
      add(LoadWalletsEvent());
    } catch (e) {
      emit(WalletError('Cüzdan silinirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onSetActiveWallet(
    SetActiveWalletEvent event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _repository.setActiveWallet(event.walletId);

      emit(const WalletOperationSuccess(
        message: 'Aktif cüzdan değiştirildi',
        type: WalletOperationType.setActive,
      ));

      // Reload wallets
      add(LoadWalletsEvent());
    } catch (e) {
      emit(WalletError('Aktif cüzdan değiştirilirken hata: ${e.toString()}'));
    }
  }

  Future<void> _onTransferBetweenWallets(
    TransferBetweenWalletsEvent event,
    Emitter<WalletState> emit,
  ) async {
    try {
      await _repository.transferBetweenWallets(
        fromWalletId: event.fromWalletId,
        toWalletId: event.toWalletId,
        amount: event.amount,
        note: event.note,
      );

      emit(const WalletOperationSuccess(
        message: 'Transfer başarıyla tamamlandı',
        type: WalletOperationType.transfer,
      ));

      // Reload wallets
      add(LoadWalletsEvent());
    } catch (e) {
      emit(WalletError('Transfer sırasında hata: ${e.toString()}'));
    }
  }
}
