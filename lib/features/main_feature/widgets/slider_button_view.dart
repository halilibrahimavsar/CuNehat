import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/widgets/add_entry_sheet.dart';
import 'package:cunehat/features/finance_transactions/domain/entities/transaction_type_enum.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/investments/domain/entities/goal_entity.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_gold_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_stock_sheet.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_sheets/add_custom_sheet.dart';
import 'package:cunehat/features/investments/domain/entities/investment_entity.dart';
import 'package:cunehat/features/investments/presentation/widgets/cash_pots.dart';
import 'package:cunehat/features/main_feature/config/menu_configuration.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/features/main_feature/utils/slider_peek_store.dart';
import 'package:cunehat/features/main_feature/widgets/simple_action_bar.dart';
import 'package:cunehat/core/shared/widgets/row_action_sheet.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/transfer_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/dynamic_slider.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

/// Sade çubuğun "İçgörü ve rapor" sayfasındaki seçenekler.
enum SimpleBarTarget { ledger, insights, report, forecast, transfer }

/// Slider button view with vertical stack navigation
///
/// Submenu items navigate through a vertical stack:
/// Index 0: MainView
/// Index 1+: SubViews
///
/// Tapping a submenu item navigates to that view with vertical animation
class SliderButtonView extends StatefulWidget {
  const SliderButtonView({
    super.key,
    required this.controller,
    required this.navigationController,
    required this.userId,
    required this.walletState,
    required this.subViewFactory,
    required this.peekStore,
    this.enabledStates = const {
      SliderState.savedMoney,
      SliderState.transactions,
      SliderState.debt,
    },
  });

  final AnimationController controller;
  final HomeNavigationController navigationController;
  final String userId;
  final WalletLoadedSt walletState;
  final SubViewFactory subViewFactory;

  /// Dikey navigasyon tanıtımının hangi durumlarda oynayacağını bilen depo.
  final SliderPeekStore peekStore;

  /// Ana ekranda açık olan bölümler (bkz. `SectionVisibility`). Tek bölüm
  /// (yalnız İşlemler) varken kaydırıcı yerine [SimpleActionBar] kurulur.
  final Set<SliderState> enabledStates;

  @override
  State<SliderButtonView> createState() => _SliderButtonViewState();
}

class _SliderButtonViewState extends State<SliderButtonView> {
  late Set<SliderState> _pendingPeeks;

  String get userId => widget.userId;
  WalletLoadedSt get walletState => widget.walletState;
  HomeNavigationController get navigationController =>
      widget.navigationController;

  @override
  void initState() {
    super.initState();
    _pendingPeeks = widget.peekStore.pending();
  }

  /// Tanıtım, interaktif tur oynarken/beklerken ertelenir (bkz.
  /// [isSliderPeekAllowed]).
  bool _canPeek() =>
      !getIt.isRegistered<OnboardingCoordinator>() ||
      isSliderPeekAllowed(getIt<OnboardingCoordinator>());

  void _onPeekPlayed(SliderState state) {
    widget.peekStore.markSeen(state);
    if (!mounted) return;
    setState(() => _pendingPeeks = {..._pendingPeeks}..remove(state));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabledStates.length < 2) return _buildSimpleBar(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: DynamicSlider(
        controller: widget.controller,
        onValueChanged: (_) => _onSliderInteraction(),
        onStateTap: (_) => _onSliderInteraction(),
        miniButtons: _buildMiniButtons(context),
        subMenuItems: _buildSubMenuItems(context),
        selectedSubIndex: navigationController.selectedSubIndices,
        texts: context.sliderTexts,
        peekStates: _pendingPeeks,
        onPeekPlayed: _onPeekPlayed,
        canPeek: _canPeek,
        enabledStates: widget.enabledStates,
      ),
    );
  }

  // ==================== SADE ÇUBUK (yalnız İşlemler) ====================

  Widget _buildSimpleBar(BuildContext context) {
    final activeWallet = walletState.activeWallet;
    return ListenableBuilder(
      // Alt sayfa açılıp kapanınca "İçgörü ve rapor" düğmesinin dolu/boş
      // hâli değişir.
      listenable: navigationController.viewStack,
      builder: (context, _) => SimpleActionBar(
        moreActive: !navigationController.isAtMainView,
        onIncome: () => _handleAction('add_income', context, activeWallet),
        onExpense: () => _handleAction('add_expense', context, activeWallet),
        onMore: () => _showSimpleBarSheet(context),
      ),
    );
  }

  /// Sade çubuğun seçim sayfası: Defter · İçgörü · Rapor, birden çok cüzdan
  /// varsa Transfer. Kaydırıcının dikey çarkının ve Transfer mini düğmesinin
  /// yazıyla okunan karşılığı.
  Future<void> _showSimpleBarSheet(BuildContext context) async {
    final l10n = context.l10n;
    final activeWallet = walletState.activeWallet;
    if (activeWallet == null) return;
    final current = navigationController.viewStack.currentIndex;
    final subMenus = MenuConfigs.configs[SliderState.transactions]!.subMenus;

    final choice = await RowActionSheet.show<SimpleBarTarget>(
      context,
      title: l10n.simpleBarSheetTitle,
      icon: Icons.bar_chart_rounded,
      accent: Theme.of(context).colorScheme.primary,
      keyPrefix: 'simple-bar',
      actions: [
        if (current != 0)
          RowAction(
            value: SimpleBarTarget.ledger,
            icon: Icons.receipt_long_rounded,
            title: l10n.simpleBarLedger,
            subtitle: l10n.simpleBarLedgerSubtitle,
          ),
        for (final menu in subMenus)
          if (menu.viewIndex != current)
            RowAction(
              value: switch (menu.viewIndex) {
                1 => SimpleBarTarget.insights,
                2 => SimpleBarTarget.report,
                _ => SimpleBarTarget.forecast,
              },
              icon: menu.icon,
              title: localizedSubMenuLabel(menu.label, l10n),
              subtitle: switch (menu.viewIndex) {
                1 => l10n.simpleBarInsightsSubtitle,
                2 => l10n.simpleBarReportSubtitle,
                _ => l10n.simpleBarForecastSubtitle,
              },
            ),
        if (walletState.wallets.length >= 2)
          RowAction(
            value: SimpleBarTarget.transfer,
            icon: Icons.swap_horiz_rounded,
            title: l10n.transferKisa,
            subtitle: l10n.simpleBarTransferSubtitle,
          ),
      ],
    );
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case SimpleBarTarget.ledger:
        await navigationController.closeToMain();
      case SimpleBarTarget.insights:
        await navigationController.navigateToView(
          1,
          sliderState: SliderState.transactions,
        );
      case SimpleBarTarget.report:
        await navigationController.navigateToView(
          2,
          sliderState: SliderState.transactions,
        );
      case SimpleBarTarget.forecast:
        await navigationController.navigateToView(
          3,
          sliderState: SliderState.transactions,
        );
      case SimpleBarTarget.transfer:
        _handleAction('transfer', context, activeWallet);
    }
  }

  /// Close all subviews when slider is interacted with
  void _onSliderInteraction() {
    navigationController.closeToMain();
  }

  Map<SliderState, List<MiniButtonData>> _buildMiniButtons(
      BuildContext context) {
    final activeWallet = walletState.activeWallet;
    if (activeWallet == null) return {};
    // Aktif cüzdan bir kartsa birikim/borç eylemleri SAHİBİNE yazar (kartın
    // yatırımı/borç kaydı olmaz); gelir/gider kartın kendisine.
    final account = accountOf(activeWallet, walletState.wallets);

    return {
      for (final entry in MenuConfigs.configs.entries)
        entry.key: visibleMiniButtons(
          entry.value,
          walletCount: walletState.wallets.length,
        )
            .map((config) => _createMiniButton(
                  config,
                  context,
                  _isLedgerAction(config.actionType) ? activeWallet : account,
                ))
            .toList(),
    };
  }

  static bool _isLedgerAction(String actionType) =>
      actionType == 'add_income' ||
      actionType == 'add_expense' ||
      actionType == 'transfer';

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
      case 'add_cash_pot':
        return context.l10n.menuCash;
      case 'add_income':
        return context.l10n.menuIncome;
      case 'add_expense':
        return context.l10n.menuExpense;
      case 'add_debt':
        return context.l10n.menuDebt;
      case 'add_receivable':
        return context.l10n.menuReceivable;
      case 'transfer':
        return context.l10n.transferKisa;
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
      'add_cash_pot' => kCashPotColor,
      'transfer' => Colors.blue,
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
      label: localizedSubMenuLabel(config.label, context.l10n),
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
    debugPrint("DEBUG: _handleAction called with actionType=$actionType");
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
      case 'add_cash_pot':
        showCreateCashPot(
          context,
          bloc: context.read<InvestmentBloc>(),
          userId: activeWallet.userId,
          walletId: activeWallet.id!,
          currency: activeWallet.currency,
          goals: _goalsOf(context),
        );
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
      case 'transfer':
        TransferSheet.show(
          context,
          wallets: walletState.wallets,
          initialFrom: activeWallet,
        );
        break;
    }
  }

  /// Ana menüden açılan formların hedef seçicisini besler. Hedefler bloc
  /// durumundan okunur; birikim sayfası hiç açılmadıysa liste boş gelir ve
  /// seçici "önce hedef oluştur" der.
  List<GoalEntity> _goalsOf(BuildContext context) {
    final state = context.read<InvestmentBloc>().state;
    return state is InvestmentLoaded ? state.goals : const [];
  }

  /// Alım formlarının "nereden ödendi?" seçicisi için nakit kasaları.
  List<InvestmentEntity> _potsOf(BuildContext context) {
    final state = context.read<InvestmentBloc>().state;
    return state is InvestmentLoaded ? cashPotsOf(state.investments) : const [];
  }

  void _showAddGoldSheet(BuildContext context, dynamic activeWallet) {
    AddGoldSheet.show(
      context,
      userId: activeWallet.userId,
      walletId: activeWallet.id!,
      walletCurrency: activeWallet.currency,
      goals: _goalsOf(context),
      pots: _potsOf(context),
      onSave: (investment, cashSource) {
        context.read<InvestmentBloc>().add(CreateInvestmentEvent(
              investment: investment,
              userId: activeWallet.userId,
              walletId: activeWallet.id!,
              cashSource: cashSource,
            ));
      },
    );
  }

  void _showAddStockSheet(BuildContext context, dynamic activeWallet) {
    AddStockSheet.show(
      context,
      userId: activeWallet.userId,
      walletId: activeWallet.id!,
      walletCurrency: activeWallet.currency,
      goals: _goalsOf(context),
      pots: _potsOf(context),
      onSave: (investment, cashSource) {
        context.read<InvestmentBloc>().add(CreateInvestmentEvent(
              investment: investment,
              userId: activeWallet.userId,
              walletId: activeWallet.id!,
              cashSource: cashSource,
            ));
      },
    );
  }

  void _showAddCustomSheet(BuildContext context, dynamic activeWallet) {
    AddCustomSheet.show(
      context,
      userId: activeWallet.userId,
      walletId: activeWallet.id!,
      walletCurrency: activeWallet.currency,
      goals: _goalsOf(context),
      pots: _potsOf(context),
      onSave: (investment, cashSource) {
        context.read<InvestmentBloc>().add(CreateInvestmentEvent(
              investment: investment,
              userId: activeWallet.userId,
              walletId: activeWallet.id!,
              cashSource: cashSource,
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
      // Uzun form ekranı doldurunca başlık durum çubuğunun altına
      // giriyordu; yalnız ÜST payı ekler.
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AddEntrySheet(
        walletId: activeWallet.id!,
        userId: activeWallet.userId,
        currency: activeWallet.currency,
        initialIsDebt: isDebt,
        // Kartla taksitli alışveriş borç olarak girilmesin: gider formu
        // kartta (taksit seçicisiyle) bu bağlamın bloc'larıyla açılır.
        onEnterAsCardExpense: (card) {
          Navigator.pop(sheetContext);
          TransactionSheetHandler.showSheet(
            context: context,
            userId: userId,
            walletId: card.id!,
            type: TransactionTypeModel.expense,
          );
        },
      ),
    );
  }
}
