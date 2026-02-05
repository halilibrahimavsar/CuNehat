import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/widgets/dynamic_slider_button.dart';

class SliderButtonView extends StatelessWidget {
  const SliderButtonView({
    super.key,
    required AnimationController controller,
    required this.context,
    required this.userId,
    required this.walletState,
  }) : _controller = controller;

  final AnimationController _controller;
  final BuildContext context;
  final String userId;
  final WalletLoadedSt walletState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: DynamicSlider(
        controller: _controller,
        onValueChanged: (value) {},
        onStateTap: (state) {},
        miniButtons: _buildMiniButtons(),
        subMenuItems: _buildSubMenuItems(),
      ),
    );
  }

  Map<SliderState, List<MiniButtonData>> _buildMiniButtons() {
    return {
      SliderState.savedMoney: [
        MiniButtonData(
          icon: Icons.add,
          label: 'Ekle',
          color: Colors.green,
          onTap: () => _handleAddSavings(),
        ),
        MiniButtonData(
          icon: Icons.remove,
          label: 'Çıkar',
          color: Colors.red,
          onTap: () => _handleRemoveSavings(),
        ),
      ],
      SliderState.transactions: [
        MiniButtonData(
          icon: Icons.send,
          label: 'Gönder',
          color: Colors.blue,
          onTap: () => _handleSendTransaction(),
        ),
        MiniButtonData(
          icon: Icons.download,
          label: 'Al',
          color: Colors.purple,
          onTap: () => _handleReceiveTransaction(),
        ),
      ],
      SliderState.debt: [
        MiniButtonData(
          icon: Icons.add,
          label: 'Borç Ekle',
          color: Colors.orange,
          onTap: () => _handleAddDebt(),
        ),
      ],
    };
  }

  Map<SliderState, List<SubMenuItem>> _buildSubMenuItems() {
    return {
      SliderState.savedMoney: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Kategoriler',
          onTap: () => _handleSavingsCategories(),
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Banka',
          onTap: () => _handleBankSavings(),
        ),
        SubMenuItem(
          icon: Icons.home,
          label: 'Ev',
          onTap: () => _handleHomeSavings(),
        ),
      ],
      SliderState.transactions: [
        SubMenuItem(
          icon: Icons.history,
          label: 'İşlemler',
          onTap: () => _handleTransactionHistory(),
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.history,
          label: 'Geçmiş',
          onTap: () => _handleTransactionHistory(),
        ),
        SubMenuItem(
          icon: Icons.pending,
          label: 'Bekleyen',
          onTap: () => _handlePendingTransactions(),
        ),
      ],
      SliderState.debt: [
        SubMenuItem(
          icon: Icons.account_balance,
          label: 'Borç Türleri',
          onTap: () => _handleDebtCategories(),
          isMainTitle: true,
        ),
        SubMenuItem(
          icon: Icons.person,
          label: 'Kişisel',
          onTap: () => _handlePersonalDebt(),
        ),
        SubMenuItem(
          icon: Icons.business,
          label: 'Kurumsal',
          onTap: () => _handleBusinessDebt(),
        ),
      ],
    };
  }

  // Placeholder methods for functionality - TODO: Implement actual business logic
  void _handleAddSavings() {
    // TODO: Navigate to add savings screen or show dialog
    debugPrint('Add savings functionality not implemented yet');
  }

  void _handleRemoveSavings() {
    // TODO: Navigate to remove savings screen or show dialog
    debugPrint('Remove savings functionality not implemented yet');
  }

  void _handleSendTransaction() {
    // TODO: Navigate to send transaction screen
    debugPrint('Send transaction functionality not implemented yet');
  }

  void _handleReceiveTransaction() {
    // TODO: Navigate to receive transaction screen
    debugPrint('Receive transaction functionality not implemented yet');
  }

  void _handleAddDebt() {
    // TODO: Navigate to add debt screen
    debugPrint('Add debt functionality not implemented yet');
  }

  void _handleSavingsCategories() {
    // TODO: Show savings categories
    debugPrint('Savings categories functionality not implemented yet');
  }

  void _handleBankSavings() {
    // TODO: Filter savings by bank
    debugPrint('Bank savings functionality not implemented yet');
  }

  void _handleHomeSavings() {
    // TODO: Filter savings by home category
    debugPrint('Home savings functionality not implemented yet');
  }

  void _handleTransactionHistory() {
    // TODO: Navigate to transaction history
    debugPrint('Transaction history functionality not implemented yet');
  }

  void _handlePendingTransactions() {
    // TODO: Show pending transactions
    debugPrint('Pending transactions functionality not implemented yet');
  }

  void _handleDebtCategories() {
    // TODO: Show debt categories
    debugPrint('Debt categories functionality not implemented yet');
  }

  void _handlePersonalDebt() {
    // TODO: Show personal debt
    debugPrint('Personal debt functionality not implemented yet');
  }

  void _handleBusinessDebt() {
    // TODO: Show business debt
    debugPrint('Business debt functionality not implemented yet');
  }
}
