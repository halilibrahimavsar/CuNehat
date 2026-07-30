import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_stock_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
import 'package:cunehat/features/main_feature/config/menu_configuration.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

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
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: DynamicSlider(
        controller: controller,
        onValueChanged: (_) => _onSliderInteraction(),
        onStateTap: (_) => _onSliderInteraction(),
        miniButtons: _buildMiniButtons(context),
        subMenuItems: _buildSubMenuItems(context),
        selectedSubIndex: navigationController.selectedSubIndices,
        texts: context.sliderTexts,
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
      icon: config.icon,
      label: _getLocalizedMiniButtonLabel(
          context, config.actionType, config.label),
      color: color,
      onTap: () => _handleAction(config.actionType, context, activeWallet),
    );
  }

  String _getLocalizedMiniButtonLabel(
      BuildContext context, String actionType, String defaultLabel) {
    switch (actionType) {
      case 'add_gold_investment':
        return context.l10n.menuGold;
      case 'add_stock_investment':
        return context.l10n.menuStock;
      case 'add_custom_investment':
        return context.l10n.menuCustom;
      case 'add_income':
        return context.l10n.menuIncome;
      case 'add_expense':
        return context.l10n.menuExpense;
      case 'add_debt':
        return context.l10n.menuDebt;
      case 'add_receivable':
        return context.l10n.menuReceivable;
      default:
        return defaultLabel;
    }
  }

  Color _getActionColor(String actionType) {
    return switch (actionType) {
      'add_income' => Colors.green,
      'add_expense' => Colors.red,
      'add_debt' => Colors.red,
      'add_receivable' => Colors.green,
      'add_gold_investment' => Colors.amber,
      'add_stock_investment' => Colors.blue,
      'add_custom_investment' => Colors.purple,
      _ => Colors.green,
    };
  }

  Map<SliderState, List<SubMenuItem>> _buildSubMenuItems(BuildContext context) {
    return {
      for (final entry in MenuConfigs.configs.entries)
        entry.key: entry.value.subMenus
            .map((config) => _createSubMenuItem(context, entry.key, config))
            .toList(),
    };
  }

  /// Create submenu item using viewIndex from config
  SubMenuItem _createSubMenuItem(
    BuildContext context,
    SliderState sliderState,
    SubMenuConfig config,
  ) {
    return SubMenuItem(
      icon: config.icon,
      label: _getLocalizedSubMenuLabel(context, config.label),
      onTap: () => _handleSubMenuTap(config.viewIndex, sliderState),
    );
  }

  String _getLocalizedSubMenuLabel(BuildContext context, String rawLabel) {
    switch (rawLabel.toLowerCase()) {
      case 'detay':
        return context.l10n.menuDetails;
      case 'rapor':
        return context.l10n.menuReport;
      case 'geçmiş':
      case 'gecmis':
        return context.l10n.menuHistory;
      default:
        return rawLabel;
    }
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

  /// v1 kısıtı: borç/alacak ve yatırım akışları TL'ye bağlı (değerleme ve
  /// nakit kuplajı TL varsayar); döviz cüzdanında mesajla engellenir.
  /// Gelir/gider serbesttir — tutar cüzdanın kendi birimindedir.
  bool _blockIfNonTry(
      BuildContext context, dynamic activeWallet, String message) {
    if (activeWallet.currency == kDefaultCurrency) return false;
    AppMessenger.warning(message);
    return true;
  }

  void _handleAction(
      String actionType, BuildContext context, dynamic activeWallet) {
    debugPrint("DEBUG: _handleAction called with actionType=$actionType");
    switch (actionType) {
      case 'add_gold_investment':
      case 'add_stock_investment':
      case 'add_custom_investment':
        if (_blockIfNonTry(
            context, activeWallet, context.l10n.sadeceTlCuzdanYatirim)) {
          return;
        }
        break;
      case 'add_debt':
      case 'add_receivable':
        if (_blockIfNonTry(
            context, activeWallet, context.l10n.sadeceTlCuzdanBorc)) {
          return;
        }
        break;
    }

    switch (actionType) {
      case 'add_gold_investment':
        _showAddGoldSheet(context, activeWallet);
        break;
      case 'add_stock_investment':
        _showAddStockSheet(context, activeWallet);
        break;
      case 'add_custom_investment':
        _showAddCustomSheet(context, activeWallet);
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
        _showDebtEntrySheet(context, activeWallet, isDebt: true);
        break;
      case 'add_receivable':
        _showDebtEntrySheet(context, activeWallet, isDebt: false);
        break;
    }
  }

  void _showAddGoldSheet(BuildContext context, dynamic activeWallet) {
    AddGoldSheet.show(
      context,
      userId: activeWallet.userId,
      walletId: activeWallet.id!,
      onSave: (investment) {
        context.read<InvestmentBloc>().add(CreateInvestmentEvent(
              investment: investment,
              userId: activeWallet.userId,
              walletId: activeWallet.id!,
            ));
      },
    );
  }

  void _showAddStockSheet(BuildContext context, dynamic activeWallet) {
    AddStockSheet.show(
      context,
      userId: activeWallet.userId,
      walletId: activeWallet.id!,
      onSave: (investment) {
        context.read<InvestmentBloc>().add(CreateInvestmentEvent(
              investment: investment,
              userId: activeWallet.userId,
              walletId: activeWallet.id!,
            ));
      },
    );
  }

  void _showAddCustomSheet(BuildContext context, dynamic activeWallet) {
    AddCustomSheet.show(
      context,
      userId: activeWallet.userId,
      walletId: activeWallet.id!,
      onSave: (investment) {
        context.read<InvestmentBloc>().add(CreateInvestmentEvent(
              investment: investment,
              userId: activeWallet.userId,
              walletId: activeWallet.id!,
            ));
      },
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

  void _showDebtEntrySheet(BuildContext context, dynamic activeWallet,
      {required bool isDebt}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddEntrySheet(
        walletId: activeWallet.id!,
        userId: activeWallet.userId,
        initialIsDebt: isDebt,
      ),
    );
  }
}
