// lib/features/transfer/presentation/widgets/transfer_dialog.dart

// ignore_for_file: deprecated_member_use

import 'package:cunehat/core/constants/app_constants.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/transfer/domain/usecases/transfer_money_usecase.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:flutter/material.dart';

/// **Transfer Money Dialog**
///
/// Shows dialog for transferring money between wallets
Future<bool?> showTransferDialog({
  required BuildContext context,
  required String userId,
  required List<WalletEntity> wallets,
  required TransferMoneyUseCase transferUseCase,
  String? preSelectedWalletId,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => _TransferDialog(
      userId: userId,
      wallets: wallets,
      transferUseCase: transferUseCase,
      preSelectedWalletId: preSelectedWalletId,
    ),
  );
}

class _TransferDialog extends StatefulWidget {
  final String userId;
  final List<WalletEntity> wallets;
  final TransferMoneyUseCase transferUseCase;
  final String? preSelectedWalletId;

  const _TransferDialog({
    required this.userId,
    required this.wallets,
    required this.transferUseCase,
    this.preSelectedWalletId,
  });

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _fromWalletId;
  String? _toWalletId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set pre-selected wallet as source
    _fromWalletId = widget.preSelectedWalletId ?? widget.wallets.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.swap_horiz, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('Para Transferi'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFromWalletSelector(),
            const SizedBox(height: 16),
            _buildTransferIcon(),
            const SizedBox(height: 16),
            _buildToWalletSelector(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildNoteField(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleTransfer,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Transfer Et'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFromWalletSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kaynak Cüzdan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _fromWalletId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance_wallet),
          ),
          items: widget.wallets.map((wallet) {
            return DropdownMenuItem(
              value: wallet.id,
              child: Row(
                children: [
                  Icon(
                    WalletIcons.getIcon(wallet.iconName),
                    color: WalletColors.hexToColor(wallet.colorHex),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${wallet.name} (${wallet.balance.toStringAsFixed(2)} ₺)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _fromWalletId = value;
              // If same as destination, clear destination
              if (_fromWalletId == _toWalletId) {
                _toWalletId = null;
              }
            });
          },
          validator: (value) {
            if (value == null) return 'Kaynak cüzdan seçin';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTransferIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_downward,
          color: Colors.blue,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildToWalletSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hedef Cüzdan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _toWalletId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.account_balance),
          ),
          items: widget.wallets
              .where((w) => w.id != _fromWalletId) // Exclude source wallet
              .map((wallet) {
            return DropdownMenuItem(
              value: wallet.id,
              child: Row(
                children: [
                  Icon(
                    WalletIcons.getIcon(wallet.iconName),
                    color: WalletColors.hexToColor(wallet.colorHex),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${wallet.name} (${wallet.balance.toStringAsFixed(2)} ₺)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _toWalletId = value),
          validator: (value) {
            if (value == null) return 'Hedef cüzdan seçin';
            if (value == _fromWalletId) return 'Farklı cüzdan seçin';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    final fromWallet = widget.wallets.firstWhere((w) => w.id == _fromWalletId);

    return TextFormField(
      controller: _amountController,
      decoration: InputDecoration(
        labelText: 'Tutar *',
        hintText: '0.00',
        border: const OutlineInputBorder(),
        suffixText: '₺',
        helperText: 'Mevcut: ${fromWallet.balance.toStringAsFixed(2)} ₺',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tutar boş olamaz';
        }
        final amount = double.tryParse(value.trim());
        if (amount == null || amount <= 0) {
          return 'Geçerli bir tutar girin';
        }
        if (amount > fromWallet.balance) {
          return 'Yetersiz bakiye';
        }
        return null;
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Açıklama',
        hintText: 'Transfer nedeni (opsiyonel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 2,
      maxLength: 100,
    );
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final note = _noteController.text.trim().isEmpty
          ? 'Transfer'
          : _noteController.text.trim();

      await widget.transferUseCase.call(
        userId: widget.userId,
        fromWalletId: _fromWalletId!,
        toWalletId: _toWalletId!,
        amount: amount,
        note: note,
      );

      if (mounted) {
        // Pop with a success result, let the caller show the snackbar
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Show error inside the dialog, as it remains open
        SnackbarHelper.showError(
            context, '❌ Hata: ${e.toString().replaceAll("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
