import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/data/models/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_investment_dialog.dart';
import 'package:cunehat/features/main_feature/config/menu_configuration.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Slider button view with vertical stack navigation
///
/// Submenu items navigate through a vertical stack:
/// Index 0: MainView
/// Index 1+: SubViews
///
/// Tapping a submenu item navigates to that view with vertical animation
class SliderButtonView extends StatelessWidget {
  const SliderButtonView({
    super.key,
    required this.controller,
    required this.navigationController,
    required this.userId,
    required this.walletState,
    required this.subViewFactory,
  });

  final AnimationController controller;
  final HomeNavigationController navigationController;
  final String userId;
  final WalletLoadedSt walletState;
  final SubViewFactory subViewFactory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: DynamicSlider(
        controller: controller,
        onValueChanged: (_) => _onSliderInteraction(),
        onStateTap: (_) => _onSliderInteraction(),
        miniButtons: _buildMiniButtons(context),
        subMenuItems: _buildSubMenuItems(),
        selectedSubIndex: navigationController.selectedSubIndices,
      ),
    );
  }

  /// Close all subviews when slider is interacted with
  void _onSliderInteraction() {
    navigationController.closeToMain();
  }

  Map<SliderState, List<MiniButtonData>> _buildMiniButtons(
      BuildContext context) {
    final activeWallet = walletState.activeWallet;
    if (activeWallet == null) return {};

    return {
      for (final entry in MenuConfigs.configs.entries)
        entry.key: entry.value.miniButtons
            .map((config) => _createMiniButton(config, context, activeWallet))
            .toList(),
    };
  }

  MiniButtonData _createMiniButton(
    MiniButtonConfig config,
    BuildContext context,
    dynamic activeWallet,
  ) {
    final color = _getActionColor(config.actionType);

    return MiniButtonData(
      icon: config.icon.toFlutterIcon(),
      label: config.label,
      color: color,
      onTap: () => _handleAction(config.actionType, context, activeWallet),
    );
  }

  Color _getActionColor(String actionType) {
    return switch (actionType) {
      'add_income' => Colors.green,
      'add_expense' => Colors.red,
      'add_debt' => Colors.orange,
      _ => Colors.green,
    };
  }

  Map<SliderState, List<SubMenuItem>> _buildSubMenuItems() {
    return {
      for (final entry in MenuConfigs.configs.entries)
        entry.key: entry.value.subMenus
            .map((config) => _createSubMenuItem(entry.key, config))
            .toList(),
    };
  }

  /// Create submenu item using viewIndex from config
  SubMenuItem _createSubMenuItem(
    SliderState sliderState,
    SubMenuConfig config,
  ) {
    return SubMenuItem(
      icon: config.icon.toFlutterIcon(),
      label: config.label,
      onTap: () => _handleSubMenuTap(config.viewIndex, sliderState),
    );
  }

  /// Handle submenu tap - navigate to view in vertical stack
  void _handleSubMenuTap(int viewIndex, SliderState sliderState) async {
    final activeWallet = walletState.activeWallet;
    if (activeWallet == null) return;

    // Navigate to the view
    await navigationController.navigateToView(
      viewIndex,
      sliderState: sliderState,
    );
  }

  void _handleAction(
      String actionType, BuildContext context, dynamic activeWallet) {
    switch (actionType) {
      case 'add_investment':
        _showAddInvestmentDialog(context, activeWallet);
        break;
      case 'add_income':
        _showTransactionSheet(
            context, activeWallet, TransactionTypeModel.income);
        break;
      case 'add_expense':
        _showTransactionSheet(
            context, activeWallet, TransactionTypeModel.expense);
        break;
      case 'add_debt':
        _showAddDebtSheet(context, activeWallet);
        break;
    }
  }

  void _showAddInvestmentDialog(BuildContext context, dynamic activeWallet) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddInvestmentDialog(
        userId: activeWallet.userId,
        walletId: activeWallet.id!,
        onSave: (investment) {
          context.read<InvestmentBloc>().add(CreateInvestmentEvent(
                investment: investment,
                userId: activeWallet.userId,
                walletId: activeWallet.id!,
              ));
        },
      ),
    );
  }

  void _showTransactionSheet(
    BuildContext context,
    dynamic activeWallet,
    TransactionTypeModel type,
  ) {
    TransactionSheetHandler.showSheet(
      context: context,
      userId: userId,
      walletId: activeWallet.id!,
      type: type,
    );
  }

  void _showAddDebtSheet(BuildContext context, dynamic activeWallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AddEntrySheet(
        walletId: activeWallet.id!,
      ),
    );
  }
}
