part of 'wallet_form_bloc.dart';

// ============ EVENTS ============

sealed class WalletFormState extends Equatable {
  const WalletFormState();

  @override
  List<Object?> get props => [];
}

/// Form is being edited
class WalletFormEditing extends WalletFormState {
  final String? walletId; // null for create, non-null for edit
  final String name;
  final String balance;
  final String colorHex;
  final String iconName;
  final String? nameError;
  final String? balanceError;

  const WalletFormEditing({
    this.walletId,
    required this.name,
    required this.balance,
    required this.colorHex,
    required this.iconName,
    this.nameError,
    this.balanceError,
  });

  bool get isEditMode => walletId != null;
  bool get hasErrors => nameError != null || balanceError != null;

  @override
  List<Object?> get props => [
        walletId,
        name,
        balance,
        colorHex,
        iconName,
        nameError,
        balanceError,
      ];

  WalletFormEditing copyWith({
    String? name,
    String? balance,
    String? colorHex,
    String? iconName,
    String? nameError,
    String? balanceError,
    bool clearNameError = false,
    bool clearBalanceError = false,
  }) {
    return WalletFormEditing(
      walletId: walletId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      nameError: clearNameError ? null : (nameError ?? this.nameError),
      balanceError:
          clearBalanceError ? null : (balanceError ?? this.balanceError),
    );
  }
}

/// Form is being submitted
class WalletFormSubmitting extends WalletFormState {}

/// Form submitted successfully
class WalletFormSuccess extends WalletFormState {
  final String message;
  const WalletFormSuccess(this.message);

  @override
  List<Object> get props => [message];
}

/// Form submission failed
class WalletFormError extends WalletFormState {
  final String message;
  const WalletFormError(this.message);

  @override
  List<Object> get props => [message];
}
