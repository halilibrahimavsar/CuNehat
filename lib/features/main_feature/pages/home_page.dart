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
import 'package:cunehat/features/main_feature/controllers/home_navigation_requests.dart';
import 'package:cunehat/features/main_feature/factories/sub_view_factory.dart';
import 'package:cunehat/features/main_feature/pages/modern_appbar.dart';
import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/features/main_feature/utils/slider_peek_store.dart';
import 'package:cunehat/features/main_feature/widgets/cube_back_handler.dart';
import 'package:cunehat/features/main_feature/widgets/main_content_swipe.dart';
import 'package:cunehat/features/main_feature/widgets/modern_drawer.dart';
import 'package:cunehat/features/main_feature/widgets/slider_button_view.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:cunehat/features/wallet/presentation/widgets/welcome_view.dart';
import 'package:cunehat/features/wallet/domain/first_wallet_setup.dart';
import 'package:cunehat/features/wallet/domain/usecases/wallet_usecase.dart';
import 'package:cunehat/features/finance_transactions/domain/usecases/install_starter_pack_usecase.dart';
import 'package:cunehat/core/services/reminder_sync_service.dart';
import 'package:cunehat/core/utils/currencies.dart';
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
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/features/main_feature/widgets/onboarding_navigation_hint_card.dart';
import 'package:cunehat/features/settings/presentation/page/privacy_policy_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cunehat/core/messaging/app_messenger.dart';
import 'package:cunehat/core/error/error_handling.dart';

/// İlk açılış akışını çalıştırır ve NE OLURSA OLSUN [openGate]'i çağırır;
/// akışın hatası raporlanır.
///
/// Kapı, bekleyen düzenli işlem hatırlatmasını ilk açılış diyaloglarının
/// arkasında bekletir. Eskiden zincirdeki bir adım (ör. yedek teklifi için
/// cihaz özeti okuması) fırlatınca kapı hiç açılmıyor ve hatırlatma o oturumda
/// bir daha çıkmıyordu.
@visibleForTesting
Future<void> runFirstLaunchThenOpenGate({
  required Future<void> Function() onboarding,
  required VoidCallback openGate,
}) async {
  try {
    await onboarding();
  } catch (e, st) {
    reportError('Ana sayfa · ilk açılış akışı', e, st);
  } finally {
    openGate();
  }
}

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

  /// Ana ekranda hangi bölümlerin açık olduğu (Birikim ve Borç kullandıkça
  /// açılır). Uygulama ömürlü tek örnek; `AppInitialization` kaydeder ve
  /// kayıtlarla eşitler (kaydı olan bölüm kendiliğinden açılır).
  final SectionVisibility _sections = getIt<SectionVisibility>();
  String? _currentWalletId;

  /// Aktif cüzdanın SAHİBİ (kartsa bağlı hesabı). Hesap ↔ kart geçişi aynı
  /// aile içinde kalır; bkz. [_buildLoadedContent].
  String? _currentAccountId;

  /// Gelecek isteği uygulanmayı bekliyor: cüzdanlar yüklenmedi ya da
  /// bildirimin cüzdanına geçiliyor (bkz. [_tryOpenForecast]).
  bool _forecastWaiting = false;

  /// Geçişi istenen cüzdan (aynı geçiş ikinci kez gönderilmesin).
  String? _forecastSwitchTo;
  SubViewFactory? _subViewFactory;
  SliderState? _lastSliderState;
  bool _isPendingDialogShowing = false;

  /// Kullanıcının "Sonra" dediği bekleyen kümenin imzası. Aynı küme için
  /// hatırlatma tekrar çıkmaz; aksi halde uygulamaya her dönüşte yeniden
  /// gösteriliyordu. Yeni bir vade gelince imza değişir ve tekrar çıkar.
  String? _dismissedPendingSignature;

  /// Açılış diyalogları (bildirim izni, yedek teklifi) bitene kadar
  /// bekleyen-işlem diyaloğu açılmaz; yoksa modallar üst üste biniyordu.
  final Completer<void> _firstLaunchGate = Completer<void>();

  /// Build içinde yaratılırsa her rebuild'de key değişir ve scaffold'un tüm
  /// alt ağacı (DynamicSlider dahil) remount olur; bu da slider sürüklenirken
  /// 0.25/0.75 sınırında tetiklenen rebuild'le jesti öldürüp knob'u dondurur.
  final _scaffoldKey = GlobalKey<AnimatedScaffoldWrapperState>();

  @override
  void initState() {
    super.initState();
    _navController = HomeNavigationController(this)
      ..setEnabledStates(_sections.enabledStates);
    _sections.addListener(_onSectionsChanged);
    _lastSliderState = _navController.currentSliderState;
    _navController.horizontalController.addListener(_onSliderStateMaybeChanged);
    if (getIt.isRegistered<HomeNavigationRequests>()) {
      final requests = getIt<HomeNavigationRequests>()
        ..addListener(_onShowTransactions)
        ..sectionHandler = _onSectionRequested
        ..mainHandler = _onMainRequested;
      // Bildirime dokunularak açıldıysa istenen bölüm ilk kareden sonra.
      final pending = requests.takePendingSection();
      if (pending != null) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _onSectionRequested(pending));
      }
    }
    _loadWallets();
    // Bekleyen işlemleri yükle. Uygulamaya dönüş ve bildirim dokunuşu
    // yollarını NotificationTapListener (app seviyesi) besler.
    context
        .read<PendingRecurringBloc>()
        .add(const LoadPendingTransactionsEvent());

    // Kabuk turunun "yüzeyim şu an gerçekten ekranda mı" sorusunun kabuk
    // tarafındaki yanıtı: alt yığın indeksi, süren geçiş ve drawer/cüzdan
    // dönüşümü. Tur yalnız kabuk KÖKTE ve DURURKEN oynar.
    getIt<OnboardingCoordinator>().shellStatusProvider =
        () => OnboardingShellStatus(
              stackIndex: _navController.viewStack.currentIndex,
              isAnimating: _navController.isAnimating,
              isTransformed: _scaffoldKey.currentState?.isTransforming ?? false,
            );
    _navController.viewStack.addListener(_pumpOnboarding);

    // Hatırlatma taşıyan ilk kayıt oluştuğunda bildirim izni sorulur (bkz.
    // [_maybeRequestNotificationPermission]).
    getIt<ReminderSyncService>().reminderWanted.addListener(_onReminderWanted);

    // Açılış diyalogları tek postFrameCallback'te SIRALI çalışır ki sistem
    // izin promptu yedek teklifiyle çakışmasın.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => runFirstLaunchThenOpenGate(
        onboarding: _runFirstLaunchOnboarding,
        openGate: _openFirstLaunchGate,
      ),
    );
  }

  void _openFirstLaunchGate() {
    if (!_firstLaunchGate.isCompleted) _firstLaunchGate.complete();
  }

  Future<void> _runFirstLaunchOnboarding() async {
    await _maybeRequestNotificationPermission();
    if (!mounted) return;
    await _maybeOfferBackup();
  }

  /// Yedekleme teklifi. İlk açılışa BAĞLI DEĞİL: sıfır veriyle sorulması anlamsız olduğu için eşiğe ulaşana kadar
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

    final summary =
        await getIt<DataSerializationService>().currentDataSummary();
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

  bool _askingNotificationPermission = false;

  void _onReminderWanted() {
    // Açılış diyaloglarının arkasına sıralan: `syncAll` açılışta koşar ve
    // yedek teklifiyle aynı anda tetiklenebilir.
    unawaited(_firstLaunchGate.future.then((_) {
      if (mounted) return _maybeRequestNotificationPermission();
    }));
  }

  /// Bildirim iznini, sorunun bir KONUSU olduğunda sorar.
  ///
  /// Eskiden ilk açılışta, kullanıcının elinde hatırlatılacak tek bir kayıt
  /// yokken soruluyordu. Artık hatırlatma taşıyan ilk kayıt (düzenli işlem,
  /// vadeli borç, kart) oluşunca sorulur; yedeğini geri yükleyen kullanıcıda
  /// hatırlatmalar hazır geldiği için ilk açılışta sorulmaya devam eder.
  ///
  /// Ana sayfanın üstünde bir form ya da sayfa varken SORULMAZ: istek
  /// düşmez, üstteki rota kapanınca [didChangeDependencies] yeniden dener.
  Future<void> _maybeRequestNotificationPermission() async {
    if (_askingNotificationPermission || !mounted) return;
    final prefs = getIt<SharedPreferences>();
    if (!shouldAskNotificationPermission(
      alreadyExplained: prefs.getBool(kNotificationRationaleShownKey) ?? false,
      reminderWanted: getIt<ReminderSyncService>().reminderWanted.value,
    )) {
      return;
    }
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    _askingNotificationPermission = true;
    try {
      final service = getIt<NotificationService>();
      if (await service.areNotificationsEnabled()) {
        // İzin zaten var (Android 12 ve altında kurulumla gelir): sorulacak
        // bir şey yok, bir daha da denenmesin.
        await prefs.setBool(kNotificationRationaleShownKey, true);
        return;
      }
      if (!mounted) return;
      final granted = await showNotificationPermissionRationale(context);
      // Bayrak gerekçe GÖSTERİLDİKTEN sonra yazılır. Kullanıcı "Şimdi Değil"
      // dese de bir daha rahatsız edilmez; izni sonradan vermek isterse
      // Ayarlar > Bildirimler kartından her zaman isteyebilir.
      await prefs.setBool(kNotificationRationaleShownKey, true);
      if (granted) {
        try {
          await service.requestPermissions();
        } catch (e, st) {
          reportError('Ana sayfa · bildirim izni', e, st);
        }
      }
    } finally {
      _askingNotificationPermission = false;
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

  String _userId() {
    final authState = context.read<AppAuthBloc>().state;
    return authState is AppAuthenticated
        ? authState.user.uid
        : (authState is AppAuthLocked ? authState.user.uid : 'local_user');
  }

  void _loadWallets() {
    context.read<WalletBloc>().add(WatchWalletsEvent(_userId()));
  }

  /// Karşılama ekranındaki "Başla": ilk cüzdanı ve hazır kategorileri kurar.
  /// Hata iletisi (başarıda `null`) döner; bkz. [WelcomeView.onStart].
  ///
  /// `WalletBloc`'a olay GÖNDERİLMEZ: cüzdan akışı yeni kaydı kendisi görür
  /// ve kabuk karşılamadan doğrudan deftere geçer. Olağan yol
  /// (`CreateWalletEvent`) ayrıca "Cüzdan oluşturuldu!" bildirimi basar; ilk
  /// ekranda kullanıcının yaptığı şey "başlamak", cüzdan oluşturmak değil.
  Future<String?> _startFresh(double openingBalance) async {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    final result = await FirstWalletSetup(
      getIt<WalletCreateUseCase>(),
      getIt<WalletSetActiveUseCase>(),
      getIt<InstallStarterPackUseCase>(),
    )(
      userId: _userId(),
      name: l10n.firstRunDefaultWalletName,
      openingBalance: openingBalance,
      currency: kDefaultCurrency,
      languageCode: languageCode,
    );
    return result.fold(
      (failure) {
        reportError('Ana sayfa · ilk cüzdan', failure.message);
        return l10n.firstRunFailed;
      },
      (_) {
        _markPrivacyNoteSeen();
        return null;
      },
    );
  }

  /// Gizlilik notu karşılama ekranında duruyor; kullanıcı oradan ilerlediğinde
  /// "görüldü" sayılır.
  void _markPrivacyNoteSeen() => unawaited(
      getIt<SharedPreferences>().setBool(kPrivacyConsentShownKey, true));

  void _openRestore() {
    _markPrivacyNoteSeen();
    context.push(AppRoutes.restoreBackup);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navController.reduceMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Rota bağımlılığı: üstteki form/sayfa kapanınca burası yeniden koşar ve
    // bekleyen bildirim izni sorusu o an sorulur.
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onReminderWanted());
    }
  }

  /// Defter · İçgörü · Rapor sekme şeridinden gelen istek.
  void _onSectionRequested(TransactionsSection section) {
    if (!mounted) return;
    if (section == TransactionsSection.ledger) {
      unawaited(_navController.closeToMain());
      return;
    }
    if (section == TransactionsSection.forecast) {
      // Elle istek (İçgörü'deki bağlantı) hemen açılır; bildirimden gelen
      // cüzdan yüklemesini ya da cüzdan geçişini bekleyebilir.
      if (getIt<HomeNavigationRequests>().peekForecastOpen() == null) {
        unawaited(_openForecastView());
        return;
      }
      _forecastWaiting = true;
      _tryOpenForecast();
      return;
    }
    // Enum sırası alt görünüm indeksidir (0 = ana görünüm; bkz.
    // `MenuConfigs` → İçgörü 1, Rapor 2).
    unawaited(_navController.navigateToView(section.index,
        sliderState: SliderState.transactions));
  }

  /// Bekleyen Gelecek isteğini uygular. Gelecek cüzdana özel: bildirim başka
  /// bir cüzdanınsa önce ona geçilir, Gelecek geçiş TAMAMLANINCA açılır
  /// ([_buildLoadedContent] yeniden çağırır). Soğuk açılışta cüzdanlar
  /// yüklenene kadar beklenir: yığın o an boştur ve gezinme sessizce
  /// boşa giderdi.
  void _tryOpenForecast() {
    if (!_forecastWaiting || !mounted) return;
    final requests = getIt<HomeNavigationRequests>();
    final request = requests.peekForecastOpen();
    if (request == null) {
      // Bekleme bildirim isteğinin ömrünü aştı: düşer. Yoksa saatler sonraki
      // bir elle cüzdan değişimi Gelecek'i kendiliğinden açardı.
      _forecastWaiting = false;
      _forecastSwitchTo = null;
      return;
    }
    final state = context.read<WalletBloc>().state;
    final loaded = state is WalletLoadedSt ? state : null;
    final target = request.walletId;
    switch (forecastOpenAction(
      targetWalletId: target,
      walletIds: loaded?.wallets.map((w) => w.id).whereType<String>(),
      activeWalletId: loaded?.activeWallet?.id,
    )) {
      case ForecastOpenAction.wait:
        return;
      case ForecastOpenAction.switchWallet:
        if (_forecastSwitchTo == target) return;
        _forecastSwitchTo = target;
        final wallet = loaded!.wallets.firstWhere((w) => w.id == target);
        context.read<WalletBloc>().add(
            SetActiveWalletEvent(userId: wallet.userId, walletId: target!));
      case ForecastOpenAction.open:
        _forecastWaiting = false;
        _forecastSwitchTo = null;
        final taken = requests.takeForecastOpen();
        if (taken != null) requests.focusForecast(day: taken.day);
        unawaited(_openForecastView());
    }
  }

  /// Gelecek İşlemler'in alt görünümü: başka bir ana bölümdeyken yığında
  /// yoktur (gezinme sessizce boşa giderdi), önce İşlemler'e geçilir.
  Future<void> _openForecastView() async {
    if (_navController.currentSliderState != SliderState.transactions) {
      await _navController.showMain(SliderState.transactions);
      if (!mounted) return;
    }
    await _navController.navigateToView(TransactionsSection.forecast.index,
        sliderState: SliderState.transactions);
  }

  /// Etkin bölümler değişti (bir bölüm açıldı ya da kapatıldı): gezinme
  /// ekseni yeni aralığa çekilir ve alt çubuk (sade çubuk ↔ kaydırıcı)
  /// yeniden kurulur.
  void _onSectionsChanged() {
    _navController.setEnabledStates(_sections.enabledStates);
    if (mounted) setState(() {});
    // Kaydırıcı ilk kez göründüyse tanıtımı oynayabilir hâle geldi.
    _pumpOnboarding();
  }

  /// Çekmeceden gelen "şu bölümü göster" isteği (bkz.
  /// [HomeNavigationRequests.openMain]).
  void _onMainRequested(SliderState state) {
    if (!mounted) return;
    unawaited(_navController.showMain(state));
  }

  /// Dışarıdan "İşlemler'i göster" isteği (bkz. [HomeNavigationRequests]).
  void _onShowTransactions() {
    if (!mounted) return;
    unawaited(_navController.showMain(SliderState.transactions));
  }

  @override
  void dispose() {
    // Kapıyı bekleyen listener'lar askıda kalmasın.
    _openFirstLaunchGate();
    _sections.removeListener(_onSectionsChanged);
    getIt<ReminderSyncService>()
        .reminderWanted
        .removeListener(_onReminderWanted);
    _navController.horizontalController
        .removeListener(_onSliderStateMaybeChanged);
    _navController.viewStack.removeListener(_pumpOnboarding);
    if (getIt.isRegistered<HomeNavigationRequests>()) {
      final requests = getIt<HomeNavigationRequests>()
        ..removeListener(_onShowTransactions);
      if (requests.sectionHandler == _onSectionRequested) {
        requests.sectionHandler = null;
      }
      if (requests.mainHandler == _onMainRequested) {
        requests.mainHandler = null;
      }
    }
    getIt<OnboardingCoordinator>().shellStatusProvider = null;
    _navController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CubeBackHandler(
      controller: _navController,
      // SafeArea BİLEREK kabuğun İÇİNDE: dışarıda olduğunda Scaffold da,
      // drawer da, drawer'ın karartma perdesi de ekranın 48dp yukarısında
      // bitiyor ve altta hiçbir Flutter katmanının boyamadığı bir şerit
      // kalıyordu (ölçüldü: kabuk 0→866, ekran 914). Edge-to-edge zorunlu
      // olduğu için (targetSdk 36) zemin ekranın DİBİNE kadar inmeli;
      // paydan kaçması gereken yalnız İÇERİK.
      child: AnimatedScaffoldWrapper(
        key: _scaffoldKey,
        drawer: const ModernDrawer(),
        // Drawer/cüzdan sheet'i açıkken kabuk içeriği ölçeklenip
        // kaydığından hedeflerin ekran konumu geçersizdir; dönüşüm bitince
        // bekleyen turlar yeniden değerlendirilir.
        onTransformChanged: _pumpOnboarding,
        // AppBar'a denetleyici DOĞRUDAN veriliyor: kare başına yalnız zemin
        // gradyanı yeniden kurulur, başlık ağacı durum değişince.
        appBar: ModernAppbar(
          sliderAnimation: _navController.horizontalController,
        ),
        // top: false — durum çubuğu payını ModernAppbar zaten kendisi
        // uyguluyor (içindeki Material AppBar `primary`).
        child: SafeArea(
          top: false,
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
    // Bildirimin cüzdanına geçilemedi: Gelecek isteği düşer (hata iletisi
    // aşağıda); bekleyen istek sonraki bir elle cüzdan değişiminde Gelecek'i
    // açmasın.
    if (_forecastSwitchTo != null &&
        (state is WalletErrorSt ||
            (state is WalletLoadedSt &&
                state.error != null &&
                state.activeWallet?.id != _forecastSwitchTo))) {
      _forecastWaiting = false;
      _forecastSwitchTo = null;
      getIt<HomeNavigationRequests>().takeForecastOpen();
    }
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
      WalletMessageType.cardCreated => l.kkKartEklendi,
      WalletMessageType.updated => l.cuzdanGuncellendi,
      WalletMessageType.deleted => l.cuzdanSilindi,
      WalletMessageType.selected => l.cuzdanSecildi,
      _ => fallback,
    };
  }

  Widget _buildContent(WalletState walletState) {
    return switch (walletState) {
      // İlk durum da "yükleniyor": eskiden karşılama dalına düşüyor ve cüzdanı
      // OLAN kullanıcı her açılışta bir kare boyunca boş ekranı görüyordu.
      WalletInitialSt() ||
      WalletLoadingSt() =>
        const Center(child: CircularProgressIndicator()),
      WalletErrorSt() => ErrorView(
          message: walletState.err,
          onPressed: _loadWallets,
          buttonText: context.l10n.tekrarDene,
          customIcon:
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
        ),
      WalletLoadedSt() => _buildLoadedContent(walletState),
      NoWalletSt() => WelcomeView(
          currency: kDefaultCurrency,
          onStart: _startFresh,
          onRestore: _openRestore,
          onPrivacyPolicy: () => context.push(AppRoutes.privacyPolicy),
        ),
    };
  }

  Widget _buildLoadedContent(WalletLoadedSt walletState) {
    final userId = walletState.wallets.first.userId;
    final activeWallet = walletState.activeWallet;

    if (_currentWalletId != activeWallet?.id) {
      final nextAccountId = activeWallet == null
          ? null
          : accountOf(activeWallet, walletState.wallets).id;
      // Hesap ↔ kart geçişi (aynı aile) alt görünümü KORUR: kart şeridi
      // artık İçgörü ve Rapor'da da duruyor ve oradan kart seçen kullanıcı
      // defterine atılmamalı. Alt görünümler cüzdana bağlı anahtarla yeniden
      // kurulur (bkz. [SubViewFactory]), yığın indeksi korunur — bayat veri
      // kalmaz. Aile dışı geçişte eskisi gibi ana görünüme dönülür.
      final sameFamily =
          _currentAccountId != null && _currentAccountId == nextAccountId;
      _currentWalletId = activeWallet?.id;
      _currentAccountId = nextAccountId;
      if (_forecastWaiting) {
        // Bildirimden Gelecek bekliyor (soğuk açılış ya da bildirimin
        // cüzdanına geçiş): ana görünüme kapatmak yeni açılan Gelecek'i
        // kapatırdı; doğrudan oraya gidilir.
        WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpenForecast());
      } else if (!sameFamily) {
        // navigateTo → notifyListeners build sırasında patlamasın diye ertele.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _navController.onWalletChanged();
        });
      }
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
    final account = accountOf(activeWallet, walletState.wallets);
    if (_subViewFactory == null ||
        _subViewFactory!.walletId != activeWallet.id ||
        _subViewFactory!.walletCurrency != activeWallet.currency ||
        _subViewFactory!.accountWalletId != account.id ||
        _subViewFactory!.accountCurrency != account.currency) {
      _subViewFactory = SubViewFactory(
        userId: userId,
        walletId: activeWallet.id!,
        walletCurrency: activeWallet.currency,
        accountWalletId: account.id,
        accountCurrency: account.currency,
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildAnimatedContent(userId, activeWallet, account),
        ),
        if (_subViewFactory != null)
          // Klavye açıkken (defterde arama) kaydırıcı klavyenin üstüne
          // biniyordu: küçük telefonda sonuçlara HİÇ yer kalmıyordu. Offstage
          // yer kaplamaz ama durumu (topuz konumu) korur.
          Offstage(
            offstage: MediaQuery.viewInsetsOf(context).bottom > 0,
            // _navController'a bağlı: closeToMain/navigateToView seçim
            // map'ini değiştirip notifyListeners çağırınca
            // DynamicSlider.didUpdateWidget tetiklenir ve knob carousel'i
            // ekranla senkron kalır.
            child: AnimatedBuilder(
              animation: _navController,
              builder: (context, _) {
                final bar = SliderButtonView(
                  peekStore: SliderPeekStore(getIt<SharedPreferences>()),
                  controller: _navController.horizontalController,
                  navigationController: _navController,
                  userId: userId,
                  walletState: walletState,
                  subViewFactory: _subViewFactory!,
                  enabledStates: _sections.enabledStates,
                );
                // Tanıtım hedefi yalnız KAYDIRICI: sade çubukta anlatılacak
                // jest yok, her düğme ne yaptığını yazıyla söylüyor.
                if (_sections.hasOnlyTransactions) return bar;
                return Showcase.withWidget(
                  key: OnboardingKeys.addActionSlider,
                  container: const OnboardingNavigationHintCard(),
                  targetShapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: bar,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedContent(
      String userId, WalletEntity activeWallet, WalletEntity account) {
    // Setup view stack based on current slider state, outside of the AnimatedBuilder
    // to avoid calling notifyListeners() during the build phase.
    _setupViewStack(userId, activeWallet, account);

    return MainContentSwipe(
      controller: _navController,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _navController,
          _navController.viewStack,
        ]),
        builder: (context, child) {
          // Build transition
          return _navController.viewStack.buildTransition();
        },
      ),
    );
  }

  void _setupViewStack(
      String userId, WalletEntity activeWallet, WalletEntity account) {
    // Create main view
    // Cüzdan-bazlı key'ler: cüzdan değişince Element (ve dolayısıyla
    // sayfaların bloc/state'i) tazelensin.
    //
    // Aktif cüzdan bir KARTSA birikim ve borç sayfaları sahibinin verisini
    // gösterir ([account]; kartın yatırımı/borç kaydı olmaz) ve kart ↔ hesap
    // geçişinde yeniden kurulmaz.
    final mainView = HorizontalCubeAnimationView(
      controller: _navController.horizontalController,
      firstView: InvestmentMoneyPage(
        key: ValueKey('investment-${account.id}'),
        activeWallet: account,
      ),
      // Anahtar SAHİBE bağlı: hesap ↔ kart geçişi sayfayı yeniden kurmaz
      // (bağlam şeridinin animasyonu ve seçili dönem korunur); sayfa yeni
      // cüzdanın defterini `didUpdateWidget`'ta yükler.
      secondView: TransactionsPage(
        key: ValueKey('transactions-${account.id}'),
        userId: userId,
        wallet: activeWallet,
      ),
      thirdView: DebtAndReceivablePage(
        key: ValueKey('debt-${account.id}'),
        userId: userId,
        walletId: account.id!,
        walletCurrency: account.currency,
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
