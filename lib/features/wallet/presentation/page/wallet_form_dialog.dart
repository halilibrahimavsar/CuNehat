// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// **Cüzdan Oluşturma/Düzenleme Dialog'unu Göster**
///
/// [wallet] null ise → Yeni Cüzdan Oluştur
/// [wallet] dolu ise → Mevcut Cüzdanı Düzenle
Future<void> showCreateEditDialog({
  required BuildContext context,
  required String userId,
  WalletEntity? wallet,
  required VoidCallback onSuccess,
  required Function(String error) onError,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: context.read<WalletBloc>(),
        child: _WalletFormDialog(
          userId: userId,
          wallet: wallet,
          onSuccess: onSuccess,
          onError: onError,
        ),
      );
    },
  );
}

/// **Cüzdan Form Dialog Widget**
class _WalletFormDialog extends StatefulWidget {
  final String userId;
  final WalletEntity? wallet;
  final VoidCallback onSuccess;
  final Function(String error) onError;

  const _WalletFormDialog({
    required this.userId,
    this.wallet,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_WalletFormDialog> createState() => _WalletFormDialogState();
}

class _WalletFormDialogState extends State<_WalletFormDialog> {
  // ========== CONTROLLERS ==========
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _debtController;
  late final TextEditingController _creditController;
  late final TextEditingController _saveController;
  final _formKey = GlobalKey<FormState>();

  // ========== STATE ==========
  late String _selectedColorHex;
  late String _selectedIconName;
  bool _isLoading = false;

  // ========== GETTERS ==========
  bool get isEditMode => widget.wallet != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
  }

  /// Controller'ları başlat
  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.wallet?.name ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.wallet?.balance.toStringAsFixed(2) ?? '0.00',
    );
    _debtController = TextEditingController(
      text: widget.wallet?.debt.toStringAsFixed(2) ?? '0.00',
    );
    _creditController = TextEditingController(
      text: widget.wallet?.credit.toStringAsFixed(2) ?? '0.00',
    );
    _saveController = TextEditingController(
      text: widget.wallet?.investment.toStringAsFixed(2) ?? '0.00',
    );
  }

  /// State değerlerini başlat
  void _initializeState() {
    _selectedColorHex = widget.wallet?.colorHex ?? '0xFF2196F3';
    _selectedIconName = widget.wallet?.iconName ?? 'wallet';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _debtController.dispose();
    _creditController.dispose();
    _saveController.dispose();
    super.dispose();
  }

  // ========== UI BUILD ==========
  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: _handleBlocState,
      child: AlertDialog(
        title: Text(isEditMode ? 'Cüzdanı Düzenle' : 'Yeni Cüzdan Ekle'),
        content: _buildForm(),
        actions: _buildActions(),
      ),
    );
  }

  /// Form içeriği
  Widget _buildForm() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameField(),
            const SizedBox(height: 16),
            _buildBalanceField(),
            const SizedBox(height: 16),
            _buildAdditionalInfoFields(),
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 16),
            _buildIconPicker(),
          ],
        ),
      ),
    );
  }

  /// İsim alanı
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Cüzdan Adı *',
        hintText: 'Örn: Ana Cüzdan, Tatil Fonu',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Cüzdan adı boş olamaz';
        }
        if (value.trim().length < 2) {
          return 'Cüzdan adı en az 2 karakter olmalı';
        }
        return null;
      },
      textCapitalization: TextCapitalization.words,
      maxLength: 30,
    );
  }

  /// Bakiye alanı
  Widget _buildBalanceField() {
    return TextFormField(
      controller: _balanceController,
      decoration: InputDecoration(
        labelText: isEditMode ? 'Bakiye *' : 'Başlangıç Bakiyesi *',
        hintText: '0.00',
        border: const OutlineInputBorder(),
        suffixText: '₺',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Bakiye boş olamaz';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null) {
          return 'Geçerli bir sayı girin';
        }
        return null;
      },
    );
  }

  /// Ek Bilgiler (Borç, Alacak, Birikim)
  Widget _buildAdditionalInfoFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ek Bilgiler:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMoneyField(
                  _debtController, 'Borç', Icons.arrow_downward, Colors.red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMoneyField(_creditController, 'Alacak',
                  Icons.arrow_upward, Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMoneyField(
            _saveController, 'Birikim', Icons.savings, Colors.orange),
      ],
    );
  }

  Widget _buildMoneyField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color color,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
        suffixText: '₺',
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Renk seçici
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Renk Seçin:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: WalletColors.presetColors.map((color) {
            final hex = WalletColors.colorToHex(color);
            final isSelected = _selectedColorHex == hex;

            return GestureDetector(
              onTap: () => setState(() => _selectedColorHex = hex),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// İkon seçici
  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İkon Seçin:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: WalletIcons.icons.entries.map((entry) {
            final isSelected = _selectedIconName == entry.key;
            final color = WalletColors.hexToColor(_selectedColorHex);

            return GestureDetector(
              onTap: () => setState(() => _selectedIconName = entry.key),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  entry.value,
                  color: isSelected ? color : Colors.grey,
                  size: 28,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Dialog aksiyonları (butonlar)
  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        child: const Text('İptal'),
      ),
      ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(isEditMode ? 'Kaydet' : 'Oluştur'),
      ),
    ];
  }

  // ========== ACTIONS ==========

  /// Form gönderimini işle
  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final balance = double.parse(_balanceController.text.trim());
    final debt = double.tryParse(_debtController.text.trim()) ?? 0.0;
    final credit = double.tryParse(_creditController.text.trim()) ?? 0.0;
    final save = double.tryParse(_saveController.text.trim()) ?? 0.0;
    final colorHex = _selectedColorHex;
    final iconName = _selectedIconName;
    final createdAt = DateTime.now();
    final sortOrder = DateTime.now().millisecondsSinceEpoch;

    if (isEditMode) {
      final WalletEntity wallet = widget.wallet!.copyWith(
        name: name,
        balance: balance,
        debt: debt,
        credit: credit,
        investment: save,
        colorHex: colorHex,
        iconName: iconName,
      );
      context.read<WalletBloc>().add(UpdateWalletEvent(wallet));
    } else {
      final WalletEntity wallet = WalletEntity(
        id: null, // ID usecase'de oluşturulacak
        userId: widget.userId,
        name: name,
        balance: balance,
        debt: debt,
        credit: credit,
        investment: save,
        colorHex: colorHex,
        iconName: iconName,
        createdAt: createdAt,
        sortOrder: sortOrder,
        isActive: false, // Başlangıçta false
      );
      context.read<WalletBloc>().add(CreateWalletEvent(wallet));
    }
  }

  /// BLoC state değişikliklerini dinle
  void _handleBlocState(BuildContext context, WalletState state) {
    if (state is WalletCreatedSt) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      widget.onSuccess();
    } else if (state is WalletUpdatedSt) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      widget.onSuccess();
    } else if (state is WalletErrorSt) {
      setState(() => _isLoading = false);
      widget.onError(state.err);
    }
  }
}
