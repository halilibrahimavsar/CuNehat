import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/shared/animations/horizontal_cube_animation_view.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
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
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:cunehat/features/recurring_transactions/presentation/widgets/pending_recurring_dialog.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/notifications/notification_service.dart';

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
  SliderState? _lastSliderState;
  bool _isPendingDialogShowing = false;

  /// Build içinde yaratılırsa her rebuild'de key değişir ve scaffold'un tüm
  /// alt ağacı (DynamicSlider dahil) remount olur; bu da slider sürüklenirken
  /// 0.25/0.75 sınırında tetiklenen rebuild'le jesti öldürüp knob'u dondurur.
  final _scaffoldKey = GlobalKey<AnimatedScaffoldWrapperState>();

  @override
  void initState() {
    super.initState();
    _navController = HomeNavigationController(this);
    _lastSliderState = _navController.currentSliderState;
    _navController.horizontalController.addListener(_onSliderStateMaybeChanged);
    _loadWallets();
    // Bekleyen işlemleri yükle
    context.read<PendingRecurringBloc>().add(LoadPendingTransactionsEvent());

    // Bildirim izinlerini iste
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      await getIt<NotificationService>().requestPermissions();
    } catch (e) {
      debugPrint('Failed to request notification permissions: $e');
    }
  }

  /// Slider 0.25/0.75 sınırını geçip durum değiştirdiğinde view stack'in
  /// yeni durumun alt sayfalarıyla yeniden kurulması için rebuild tetikler.
  /// Bu olmadan stack ilk build'deki durumda (transactions) donar ve
  /// Birikim'in "Detay"ı / Borç'un "Geçmiş"i hep işlem sayfasını açar.
  void _onSliderStateMaybeChanged() {
    final state = _navController.currentSliderState;
    if (state == _lastSliderState) return;
    _lastSliderState = state;
    if (mounted) setState(() {});
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
    _navController.horizontalController
        .removeListener(_onSliderStateMaybeChanged);
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedScaffoldWrapper(
        key: _scaffoldKey,
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
        child: MultiBlocListener(
          listeners: [
            BlocListener<WalletBloc, WalletState>(
              listener: _handleWalletStateChanges,
            ),
            BlocListener<PendingRecurringBloc, PendingRecurringState>(
              listener: (context, state) async {
                if (state is PendingRecurringLoaded) {
                  if (state.pendingTransactions.isNotEmpty) {
                    if (!_isPendingDialogShowing) {
                      _isPendingDialogShowing = true;
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const PendingRecurringDialog(),
                      );
                      _isPendingDialogShowing = false;
                    }
                  } else if (_isPendingDialogShowing) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                }
              },
            ),
          ],
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, walletState) => _buildContent(walletState),
          ),
        ),
      ),
    );
  }

  void _handleWalletStateChanges(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      final msg =
          _resolveWalletMessage(context, state.messageType, state.message);
      if (msg != null) IboSnackbar.showSuccess(context, msg);
      if (state.error != null) {
        IboSnackbar.showError(context, state.error!);
      }
    } else if (state is NoWalletSt) {
      final msg =
          _resolveWalletMessage(context, state.messageType, state.message);
      if (msg != null) IboSnackbar.showSuccess(context, msg);
      if (state.error != null) {
        IboSnackbar.showError(context, state.error!);
      }
    } else if (state is WalletErrorSt) {
      IboSnackbar.showError(context, state.err);
    }
  }

  /// WalletMessageType enum'unu l10n ile lokalize edilmiş stringe çevirir.
  /// messageType null ise fallback olarak message string'i kullanır.
  String? _resolveWalletMessage(
    BuildContext context,
    WalletMessageType? type,
    String? fallback,
  ) {
    if (type == null) return fallback;
    final l = context.l10n;
    return switch (type) {
      WalletMessageType.created => l.cuzdanOlusturuldu,
      WalletMessageType.updated => l.cuzdanGuncellendi,
      WalletMessageType.deleted => l.cuzdanSilindi,
      WalletMessageType.selected => l.cuzdanSecildi,
      _ => fallback,
    };
  }

  Widget _buildContent(WalletState walletState) {
    return switch (walletState) {
      WalletLoadingSt() => const Center(child: CircularProgressIndicator()),
      WalletErrorSt() => ErrorView(
          message: walletState.err,
          onPressed: _loadWallets,
          buttonText: context.l10n.tekrarDene,
          customIcon:
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
        ),
      WalletLoadedSt() => _buildLoadedContent(walletState),
      _ => NoWalletView(infoText: context.l10n.cuzdanOlusturunuz),
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
      return NoWalletView(
        infoText: context.l10n.cuzdanSeciniz,
        showButton: false,
      );
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
          // _navController'a bağlı: closeToMain/navigateToView seçim map'ini
          // değiştirip notifyListeners çağırınca DynamicSlider.didUpdateWidget
          // tetiklenir ve knob carousel'i ekranla senkron kalır.
          AnimatedBuilder(
            animation: _navController,
            builder: (context, _) => SliderButtonView(
              controller: _navController.horizontalController,
              navigationController: _navController,
              userId: userId,
              walletState: walletState,
              subViewFactory: _subViewFactory!,
            ),
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
