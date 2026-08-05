import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:cunehat/core/constants/app_constants.dart';
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
import 'package:cunehat/features/recurring_transactions/domain/entities/recurring_transaction_entity.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_bloc.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_event.dart';
import 'package:cunehat/features/recurring_transactions/presentation/bloc/pending_recurring_state.dart';
import 'package:cunehat/features/recurring_transactions/presentation/widgets/pending_recurring_nudge.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:unified_flutter_features/unified_flutter_features.dart';
import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/notifications/notification_permission_dialog.dart';
import 'package:cunehat/core/notifications/notification_service.dart';
import 'package:cunehat/core/onboarding/backup_offer_prompt.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/services/auto_backup_service.dart';
import 'package:cunehat/core/services/data_serialization_service.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/features/main_feature/widgets/onboarding_navigation_hint_card.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';

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

  /// Kullanıcının "Sonra" dediği bekleyen kümenin imzası. Aynı küme için
  /// hatırlatma tekrar çıkmaz; aksi halde uygulamaya her dönüşte yeniden
  /// gösteriliyordu. Yeni bir vade gelince imza değişir ve tekrar çıkar.
  String? _dismissedPendingSignature;

  /// İlk açılış akışı (gizlilik onamı + bildirim izni gerekçesi) bitene kadar
  /// bekleyen-işlem diyaloğu açılmaz; yoksa üç modal üst üste biniyordu.
  final Completer<void> _firstLaunchGate = Completer<void>();

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
    // Bekleyen işlemleri yükle. Uygulamaya dönüş ve bildirim dokunuşu
    // yollarını NotificationTapListener (app seviyesi) besler.
    context
        .read<PendingRecurringBloc>()
        .add(const LoadPendingTransactionsEvent());

    final coordinator = getIt<OnboardingCoordinator>();
    coordinator.addListener(_onOnboardingCoordinatorChanged);
    // İnteraktif turların "yüzeyim şu an gerçekten ekranda mı" sorusunun
    // kabuk tarafındaki yanıtı: kaydırıcı konumu, alt yığın indeksi, süren
    // geçiş ve drawer/cüzdan dönüşümü. Turlar yalnız kabuk hedef konumunda
    // DURURKEN oynar.
    coordinator.shellStatusProvider = () => OnboardingShellStatus(
          sliderValue: _navController.horizontalController.value,
          stackIndex: _navController.viewStack.currentIndex,
          isAnimating: _navController.isAnimating,
          isTransformed: _scaffoldKey.currentState?.isTransforming ?? false,
        );
    _navController.viewStack.addListener(_pumpOnboarding);

    // İlk açılışta sırayla: gizlilik onamı, ardından bildirim izni gerekçesi.
    // Tek postFrameCallback'te sıralı çalıştırılır ki sistem izin promptu
    // gizlilik diyaloğuyla çakışmasın.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _runFirstLaunchOnboarding();
      _openFirstLaunchGate();
    });
  }

  void _openFirstLaunchGate() {
    if (!_firstLaunchGate.isCompleted) _firstLaunchGate.complete();
  }

  static const String _privacyConsentKey = 'privacy_consent_shown';
  static const String _notificationRationaleKey =
      'notification_permission_explained';

  Future<void> _runFirstLaunchOnboarding() async {
    await _maybeShowPrivacyConsent();
    if (!mounted) return;
    await _maybeRequestNotificationPermission();
    if (!mounted) return;
    await _maybeOfferBackup();
  }

  /// Yedekleme teklifi. Diğer ikisinden farklı olarak ilk açılışa BAĞLI
  /// DEĞİL: sıfır veriyle sorulması anlamsız olduğu için eşiğe ulaşana kadar
  /// her açılışta yeniden değerlendirilir (bkz. [BackupOfferPrompt]).
  Future<void> _maybeOfferBackup() async {
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(BackupOfferPrompt.seenKey) ?? false) return;

    final autoBackup = getIt<AutoBackupService>();
    if (autoBackup.isEnabled) {
      // Kullanıcı yedeklemeyi kendi bulup açmış: teklif gereksiz. Bayrağı
      // yazıyoruz ki sonradan kapatırsa diyalog aylar sonra karşısına
      // çıkmasın.
      await prefs.setBool(BackupOfferPrompt.seenKey, true);
      return;
    }

    final summary = await getIt<DataSerializationService>().currentDataSummary();
    if (!BackupOfferPrompt.shouldOffer(
      alreadyOffered: false,
      autoBackupEnabled: false,
      transactionCount: summary.transactionCount,
    )) {
      return;
    }

    if (!mounted) return;
    await showBackupOfferDialog(context);
    // Bayrak "Kur"a basılıp basılmadığından bağımsız yazılır: kullanıcı
    // Ayarlar'a gidip vazgeçse bile aynı diyalog tekrar açılmamalı.
    await prefs.setBool(BackupOfferPrompt.seenKey, true);
  }

  Future<void> _maybeShowPrivacyConsent() async {
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(_privacyConsentKey) ?? false) return;
    if (!mounted) return;
    await showPrivacyConsentDialog(context);
    await prefs.setBool(_privacyConsentKey, true);
  }

  Future<void> _maybeRequestNotificationPermission() async {
    final prefs = getIt<SharedPreferences>();
    if (prefs.getBool(_notificationRationaleKey) ?? false) return;
    if (!mounted) return;
    final granted = await showNotificationPermissionRationale(context);
    // Bayrak gerekçe GÖSTERİLDİKTEN sonra yazılır. Kullanıcı "Şimdi Değil"
    // dese de açılışta bir daha rahatsız edilmez; izni sonradan vermek
    // isterse Ayarlar > Bildirimler kartından her zaman isteyebilir.
    await prefs.setBool(_notificationRationaleKey, true);
    if (granted) {
      try {
        await getIt<NotificationService>().requestPermissions();
      } catch (e) {
        debugPrint('Failed to request notification permissions: $e');
      }
    }
  }

  /// Ayarlar'dan tetiklenen "turu tekrar göster" isteğini karşılar: yalnızca
  /// kaydırıcıyı ilgili ekrana taşır. Turu BAŞLATMAZ — sayfanın kendi
  /// [OnboardingTour] kapısı, ekran görünür ve durur hale gelince turu
  /// kendiliğinden açar. Settings `context.push` ile açıldığından HomePage
  /// state'i canlı kalır; bu yüzden initState'e değil bu listener'a ihtiyaç
  /// var.
  void _onOnboardingCoordinatorChanged() {
    final coordinator = getIt<OnboardingCoordinator>();
    final flow = coordinator.pendingFlow;
    if (flow == null) return;
    coordinator.consumePendingFlow();
    // Alt sayfa/sheet akışları buraya hiç gelmez; onlar o yüzeye gidildiğinde
    // kendiliğinden tetiklenir.
    if (!flow.isReplayableMainScreen) return;
    final targetValue = switch (flow) {
      OnboardingFlow.investment => 0.0,
      OnboardingFlow.transactions => 0.5,
      _ => 1.0,
    };
    if ((_navController.horizontalController.value - targetValue).abs() >
        0.01) {
      _navController.horizontalController.animateTo(targetValue);
    }
  }

  void _pumpOnboarding() => getIt<OnboardingCoordinator>().notifyMaybeReady();

  /// Slider 0.25/0.75 sınırını geçip durum değiştirdiğinde view stack'in
  /// yeni durumun alt sayfalarıyla yeniden kurulması için rebuild tetikler.
  /// Bu olmadan stack ilk build'deki durumda (transactions) donar ve
  /// Birikim'in "Detay"ı / Borç'un "Geçmiş"i hep işlem sayfasını açar.
  void _onSliderStateMaybeChanged() {
    // Kaydırıcının her tiki bekleyen turlar için yeniden değerlendirme
    // fırsatıdır; bekleyen yoksa çağrı bedelsizdir.
    _pumpOnboarding();
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
    // Kapıyı bekleyen listener'lar askıda kalmasın.
    _openFirstLaunchGate();
    _navController.horizontalController
        .removeListener(_onSliderStateMaybeChanged);
    _navController.viewStack.removeListener(_pumpOnboarding);
    final coordinator = getIt<OnboardingCoordinator>();
    coordinator.removeListener(_onOnboardingCoordinatorChanged);
    coordinator.shellStatusProvider = null;
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
        // Drawer/cüzdan sheet'i açıkken kabuk içeriği ölçeklenip kaydığından
        // hedeflerin ekran konumu geçersizdir; dönüşüm bitince bekleyen
        // turlar yeniden değerlendirilir.
        onTransformChanged: _pumpOnboarding,
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
              listener: _handlePendingRecurringState,
            ),
          ],
          child: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, walletState) => _buildContent(walletState),
          ),
        ),
      ),
    );
  }

  /// Açılış hatırlatmasının (nudge) tek gösterim noktası.
  ///
  /// Onay/atlama/silme burada değil Düzenli İşlemler sayfasında; bu yüzey
  /// sadece "deftere işlenmemiş kalem var" der ve oraya götürür.
  Future<void> _handlePendingRecurringState(
    BuildContext _,
    PendingRecurringState state,
  ) async {
    if (state is! PendingRecurringLoaded) return;

    if (state.pendingTransactions.isEmpty) {
      _dismissedPendingSignature = null;
      return;
    }
    if (_isPendingDialogShowing || state.suppressNudge) return;

    // Ana sayfanın üstünde başka bir sayfa varsa (Ayarlar, Bütçe, Düzenli
    // İşlemler...) hatırlatma onun üstüne fırlamamalı.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    final signature = _pendingSignature(state.pendingTransactions);
    if (signature == _dismissedPendingSignature) return;

    await _firstLaunchGate.future;
    if (!mounted || _isPendingDialogShowing) return;

    _isPendingDialogShowing = true;
    final postponed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PendingRecurringNudge(
        pending: state.pendingTransactions,
      ),
    );
    _isPendingDialogShowing = false;

    // Yalnızca açıkça "İncele" denince gidilir; geri tuşu "Sonra" sayılır —
    // aksi halde geri tuşu beklenmedik bir sayfa açardı.
    if (postponed != false) {
      _dismissedPendingSignature = signature;
      return;
    }
    if (mounted) context.push(AppRoutes.recurringTemplates);
  }

  /// Bekleyen kümenin kimliği. Yeni bir vade geldiğinde (ya da bir kalem
  /// işlendiğinde) imza değişir ve diyalog yeniden açılabilir hale gelir.
  String _pendingSignature(List<RecurringTransactionEntity> pending) {
    final parts = pending
        .map((t) => '${t.id}@${t.nextExecutionDate.toIso8601String()}')
        .toList()
      ..sort();
    return parts.join('|');
  }

  void _handleWalletStateChanges(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      final msg =
          _resolveWalletMessage(context, state.messageType, state.message);
      if (msg != null) AppMessenger.success(msg);
      if (state.error != null) {
        AppMessenger.error(state.error!);
      }
    } else if (state is NoWalletSt) {
      final msg =
          _resolveWalletMessage(context, state.messageType, state.message);
      if (msg != null) AppMessenger.success(msg);
      if (state.error != null) {
        AppMessenger.error(state.error!);
      }
    } else if (state is WalletErrorSt) {
      AppMessenger.error(state.err);
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
    // Birim de karşılaştırılır: boş cüzdanın para birimi değiştirilebiliyor,
    // fabrika yenilenmezse alt sayfalar eski sembolle yazmaya devam ederdi.
    if (_subViewFactory == null ||
        _subViewFactory!.walletId != activeWallet.id ||
        _subViewFactory!.walletCurrency != activeWallet.currency) {
      _subViewFactory = SubViewFactory(
        userId: userId,
        walletId: activeWallet.id!,
        walletCurrency: activeWallet.currency,
      );
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
            builder: (context, _) => Showcase.withWidget(
              key: OnboardingKeys.addActionSlider,
              container: const OnboardingNavigationHintCard(),
              targetShapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: SliderButtonView(
                controller: _navController.horizontalController,
                navigationController: _navController,
                userId: userId,
                walletState: walletState,
                subViewFactory: _subViewFactory!,
              ),
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
        walletCurrency: activeWallet.currency,
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
