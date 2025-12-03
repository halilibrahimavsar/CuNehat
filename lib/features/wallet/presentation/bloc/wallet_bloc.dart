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
  WalletBloc() : super(WalletInitialSt()) {
    on<GetEvent>((event, emit) {
      WalletGetUseCase(repository).call(event.wallet.userId);
    });
    on<CreateEvent>((event, emit) {
      WalletCreateUseCase(repository).call(event.wallet);
    });
    on<DeleteEvent>((event, emit) {
      WalletDeleteUseCase(repository).call(event.walletId);
    });
    on<UpdateEvent>((event, emit) {
      WalletUpdateUseCase(repository).call(event.wallet);
    });
  }
}
