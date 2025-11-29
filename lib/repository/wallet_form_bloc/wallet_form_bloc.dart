import 'package:bloc/bloc.dart';
import 'package:cunehat/constants/app_constants.dart';
import 'package:cunehat/repository/data_repository.dart';
import 'package:cunehat/repository/models/wallet_model.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'wallet_form_event.dart';
part 'wallet_form_state.dart';

// ============ BLOC ============
class WalletFormBloc extends Bloc<WalletFormEvent, WalletFormState> {
  final DataRepository _repository;

  WalletFormBloc({
    required DataRepository repository,
    Wallet? initialWallet,
  })  : _repository = repository,
        super(WalletFormEditing(
          walletId: initialWallet?.id,
          name: initialWallet?.name ?? '',
          balance: initialWallet?.balance.toStringAsFixed(2) ?? '0.00',
          colorHex: initialWallet?.colorHex ?? WalletDefaults.defaultColorHex,
          iconName: initialWallet?.iconName ?? WalletDefaults.defaultIconName,
        )) {
    on<InitializeFormEvent>(_onInitializeForm);
    on<UpdateNameEvent>(_onUpdateName);
    on<UpdateBalanceEvent>(_onUpdateBalance);
    on<UpdateColorEvent>(_onUpdateColor);
    on<UpdateIconEvent>(_onUpdateIcon);
    on<SubmitFormEvent>(_onSubmitForm);
  }

  void _onInitializeForm(
    InitializeFormEvent event,
    Emitter<WalletFormState> emit,
  ) {
    final wallet = event.wallet;

    emit(WalletFormEditing(
      walletId: wallet?.id,
      name: wallet?.name ?? '',
      balance: wallet?.balance.toStringAsFixed(2) ?? '0.00',
      colorHex: wallet?.colorHex ?? WalletDefaults.defaultColorHex,
      iconName: wallet?.iconName ?? WalletDefaults.defaultIconName,
    ));
  }

  void _onUpdateName(
    UpdateNameEvent event,
    Emitter<WalletFormState> emit,
  ) {
    if (state is WalletFormEditing) {
      final currentState = state as WalletFormEditing;
      emit(currentState.copyWith(
        name: event.name,
        clearNameError: true, // Clear error when user types
      ));
    }
  }

  void _onUpdateBalance(
    UpdateBalanceEvent event,
    Emitter<WalletFormState> emit,
  ) {
    if (state is WalletFormEditing) {
      final currentState = state as WalletFormEditing;
      emit(currentState.copyWith(
        balance: event.balance,
        clearBalanceError: true, // Clear error when user types
      ));
    }
  }

  void _onUpdateColor(
    UpdateColorEvent event,
    Emitter<WalletFormState> emit,
  ) {
    if (state is WalletFormEditing) {
      final currentState = state as WalletFormEditing;
      emit(currentState.copyWith(colorHex: event.colorHex));
    }
  }

  void _onUpdateIcon(
    UpdateIconEvent event,
    Emitter<WalletFormState> emit,
  ) {
    if (state is WalletFormEditing) {
      final currentState = state as WalletFormEditing;
      emit(currentState.copyWith(iconName: event.iconName));
    }
  }

  Future<void> _onSubmitForm(
    SubmitFormEvent event,
    Emitter<WalletFormState> emit,
  ) async {
    if (state is! WalletFormEditing) return;

    final currentState = state as WalletFormEditing;

    // Validation
    final name = currentState.name.trim();
    final balanceStr = currentState.balance.trim();
    final balance = double.tryParse(balanceStr);

    String? nameError;
    String? balanceError;

    if (name.isEmpty) {
      nameError = 'Lütfen cüzdan adı girin';
    }

    if (balance == null) {
      balanceError = 'Geçerli bir tutar girin';
    }

    // If validation fails, update state with errors
    if (nameError != null || balanceError != null) {
      emit(currentState.copyWith(
        nameError: nameError,
        balanceError: balanceError,
      ));
      return;
    }

    // Start submission
    emit(WalletFormSubmitting());

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'local_user';

      if (currentState.isEditMode) {
        // ============ UPDATE EXISTING WALLET ============
        final existingWallet = await _repository.getWalletById(
          currentState.walletId!,
        );

        if (existingWallet == null) {
          emit(const WalletFormError('Cüzdan bulunamadı'));
          return;
        }

        final updatedWallet = existingWallet.copyWith(
          name: name,
          balance: balance!,
          colorHex: currentState.colorHex,
          iconName: currentState.iconName,
        );

        await _repository.updateWallet(wallet: updatedWallet);

        emit(const WalletFormSuccess('Cüzdan güncellendi'));
      } else {
        // ============ CREATE NEW WALLET ============
        final allWallets = await _repository.getAllWallets();
        final sortOrder = allWallets.length;

        final newWallet = Wallet.createLocal(
          userId: userId,
          name: name,
          balance: balance!,
          colorHex: currentState.colorHex,
          iconName: currentState.iconName,
          isActive: false,
          sortOrder: sortOrder,
        );

        await _repository.createWallet(wallet: newWallet);

        emit(const WalletFormSuccess('Cüzdan oluşturuldu'));
      }
    } catch (e) {
      emit(WalletFormError('Hata: ${e.toString()}'));
    }
  }
}
