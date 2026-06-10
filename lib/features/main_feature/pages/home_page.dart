import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/shared/animations/horizontal_cube_animation_view.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_and_receivable_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_page.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_money_page.dart';
import 'package:cunehat/features/main_feature/controllers/home_navigation_controller.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:cunehat/features/main_feature/pages/modern_appbar.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/modern_drawer.dart';
import 'package:cunehat/features/main_feature/widgets/slider_button_view.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';

/// HomePage with vertical list navigation
///
/// Navigation Model:
/// - Horizontal swipe: Main menu (Yatırım ↔ İşlemler ↔ Borç)
/// - Vertical navigation: View stack (Main ↓ Sub1 ↓ Sub2 ↑ Main)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final HomeNavigationController _navController;
  String? _currentWalletId;
  SubViewFactory? _subViewFactory;

  @override
  void initState() {
    super.initState();
    _navController = HomeNavigationController(this);
    _loadWallets();
  }

  void _loadWallets() {
    final authState = context.read<AppAuthBloc>().state;
    final userId = authState is AppAuthenticated
        ? authState.user.uid
        : (authState is AppAuthLocked ? authState.user.uid : 'local_user');
    context.read<WalletBloc>().add(WatchWalletsEvent(userId));
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<AnimatedScaffoldWrapperState>();

    return SafeArea(
      top: false,
      child: AnimatedScaffoldWrapper(
        key: scaffoldKey,
        drawer: const ModernDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size(double.maxFinite, AppSizes.appBarHeight),
          child: AnimatedBuilder(
            animation: _navController.horizontalController,
            builder: (context, child) {
              return ModernAppbar(
                currentSliderValue: _navController.horizontalController.value,
              );
            },
          ),
        ),
        child: BlocConsumer<WalletBloc, WalletState>(
          listener: _handleWalletStateChanges,
          builder: (context, walletState) => _buildContent(walletState),
        ),
      ),
    );
  }

  void _handleWalletStateChanges(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      if (state.message != null) {
        IboSnackbar.showSuccess(context, state.message!);
      }
      if (state.error != null) {
        IboSnackbar.showError(context, state.error!);
      }
    } else if (state is NoWalletSt) {
      if (state.message != null) {
        IboSnackbar.showSuccess(context, state.message!);
      }
      if (state.error != null) {
        IboSnackbar.showError(context, state.error!);
      }
    } else if (state is WalletErrorSt) {
      IboSnackbar.showError(context, state.err);
    }
  }

  Widget _buildContent(WalletState walletState) {
    return switch (walletState) {
      WalletLoadingSt() => const Center(child: CircularProgressIndicator()),
      WalletErrorSt() => ErrorView(
          message: walletState.err,
          onPressed: _loadWallets,
          buttonText: "Tekrar Dene",
          customIcon:
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
        ),
      WalletLoadedSt() => _buildLoadedContent(walletState),
      _ => const NoWalletView(infoText: "Cüzdan oluşturunuz"),
    };
  }

  Widget _buildLoadedContent(WalletLoadedSt walletState) {
    final userId = walletState.wallets.first.userId;
    final activeWallet = walletState.activeWallet;

    if (_currentWalletId != activeWallet?.id) {
      _currentWalletId = activeWallet?.id;
      // navigateTo → notifyListeners build sırasında patlamasın diye ertele.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navController.onWalletChanged();
      });
    }

    if (activeWallet == null) {
      return const NoWalletView(infoText: "Cüzdan seçiniz", showButton: false);
    }

    // Cüzdan değişiminde fabrika YENİDEN kurulmalı; yoksa alt sayfalar
    // (detay/rapor/borç geçmişi...) sonsuza dek ilk cüzdanın walletId'siyle
    // veri çeker (cüzdan verileri karışıyor hatasının kökü buydu).
    if (_subViewFactory == null ||
        _subViewFactory!.walletId != activeWallet.id) {
      _subViewFactory =
          SubViewFactory(userId: userId, walletId: activeWallet.id!);
    }

    return Column(
      children: [
        Expanded(
          child: _buildAnimatedContent(userId, activeWallet),
        ),
        if (_subViewFactory != null)
          SliderButtonView(
            controller: _navController.horizontalController,
            navigationController: _navController,
            userId: userId,
            walletState: walletState,
            subViewFactory: _subViewFactory!,
          ),
      ],
    );
  }

  Widget _buildAnimatedContent(String userId, dynamic activeWallet) {
    // Setup view stack based on current slider state, outside of the AnimatedBuilder
    // to avoid calling notifyListeners() during the build phase.
    _setupViewStack(userId, activeWallet);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _navController,
        _navController.viewStack,
      ]),
      builder: (context, child) {
        // Build transition
        return _navController.viewStack.buildTransition();
      },
    );
  }

  void _setupViewStack(String userId, dynamic activeWallet) {
    // Create main view
    // Cüzdan-bazlı key'ler: cüzdan değişince Element (ve dolayısıyla
    // sayfaların bloc/state'i) tazelensin.
    final mainView = HorizontalCubeAnimationView(
      controller: _navController.horizontalController,
      firstView: InvestmentMoneyPage(
        key: ValueKey('investment-${activeWallet.id}'),
        activeWallet: activeWallet,
      ),
      secondView: TransactionsPage(
        key: ValueKey('transactions-${activeWallet.id}'),
        userId: userId,
        wallet: activeWallet,
      ),
      thirdView: DebtAndReceivablePage(
        key: ValueKey('debt-${activeWallet.id}'),
        userId: userId,
        walletId: activeWallet.id!,
      ),
    );

    // Create subviews based on current slider state
    final stateType = _getStateType(_navController.currentSliderState);
    final subViews = _subViewFactory?.createSubViewsForState(stateType) ?? [];

    // Update stack
    _navController.setupViewStack(
      mainView: mainView,
      subViews: subViews,
    );
  }

  String _getStateType(SliderState state) {
    return switch (state) {
      SliderState.savedMoney => 'savedMoney',
      SliderState.transactions => 'transactions',
      SliderState.debt => 'debt',
    };
  }
}
