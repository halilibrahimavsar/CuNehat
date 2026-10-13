import 'package:cunehat/features/main_feature/utils/section_visibility.dart';
import 'package:cunehat/core/constants/app_version.dart';
import 'dart:async';

import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_coordinator.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/shared/money_writer.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/utils/slider_peek_store.dart';
import 'package:cunehat/features/main_feature/utils/wallet_carousel_hint_store.dart';
import 'package:cunehat/features/main_feature/widgets/wallet_headline.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
import 'package:cunehat/features/credit_card/presentation/card_switcher_button.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

class AppBarContent extends StatefulWidget {
  /// Aktif ana durum. Eskiden buraya ham kaydırıcı DEĞERİ geçiliyordu ve
  /// AppBar kaydırma boyunca saniyede 60 kez yeniden kuruluyordu — oysa bu
  /// ağaç değerden değil yalnız DURUMDAN etkileniyor (tam sürüşte 2 kez).
  final SliderState currentState;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;

  const AppBarContent({
    super.key,
    required this.currentState,
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  State<AppBarContent> createState() => _AppBarContentState();
}

class _AppBarContentState extends State<AppBarContent> {
  WalletLoadedSt? _cachedLoadedState;

  /// Kabuk turunun TEK hedefi alttaki kaydırıcı: yana, yukarı ve dokunma
  /// jestleri ekranda yazmıyor. Cüzdan başlığı ve menü düğmesi adımları
  /// kaldırıldı — ikisi de ne olduklarını kendileri söylüyor (cüzdanın adı ve
  /// bakiyesi; her uygulamadaki menü düğmesi).
  static final List<GlobalKey> _tourKeys = [OnboardingKeys.addActionSlider];

  /// Tur ancak en az bir cüzdan varken istenir.
  static bool _hasWallet(WalletState state) =>
      state is WalletLoadedSt && state.wallets.isNotEmpty;

  /// Cüzdan alt-sayfasına verilen kaydırma denetleyicisi. State'e ait: her
  /// dokunuşta `ScrollController()` üretmek dispose edilmeyen denetleyici
  /// bırakıyordu.
  final ScrollController _walletSheetScrollController = ScrollController();

  /// Cüzdan karuselinin denetleyicisi. İlk cüzdan listesiyle birlikte, etkin
  /// hesabın sayfasında kurulur (bkz. [_buildWalletContent]).
  PageController? _pages;

  /// Kullanıcının kaydırarak seçtiği, bloc'un henüz onaylamadığı hesap (bkz.
  /// [_syncPage]). Onay gelmezse [_pendingTimer] seçimi düşürür.
  String? _pendingAccountId;
  Timer? _pendingTimer;

  Timer? _hintTimer;
  bool _hintSettled = false;

  /// Bloc'un seçimi onaylaması için tanınan süre; dolarsa başlık etkin
  /// cüzdana geri döner (seçim yazılamadıysa yanlış cüzdanı göstermesin).
  static const _confirmWindow = Duration(seconds: 2);

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _hintTimer?.cancel();
    _pages?.dispose();
    _walletSheetScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kabuk turu ilk cüzdan oluştuktan SONRA oynar: ekranda "İlk Cüzdanı
    // Oluştur"dan başka bir şey yokken "işte aktif cüzdanın" demenin anlamı
    // yok. `enabled` false→true olunca OnboardingTour kendini yeniden
    // silahlandırır; ek bir tetikleyiciye gerek yok.
    final sections = getIt.isRegistered<SectionVisibility>()
        ? getIt<SectionVisibility>()
        : null;
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (prev, curr) => _hasWallet(prev) != _hasWallet(curr),
      builder: (context, walletState) => ListenableBuilder(
        listenable: sections ?? const AlwaysStoppedAnimation<double>(0),
        builder: (context, child) => OnboardingTour(
          flow: OnboardingFlow.shell,
          keys: _tourKeys,
          // Turun son adımı KAYDIRICIYI anlatır. Yalnız İşlemler açıkken
          // kaydırıcı yoktur (sade çubuk); tur, ikinci bölüm açılıp kaydırıcı
          // ilk kez göründüğünde oynar.
          enabled: _hasWallet(walletState) &&
              !(sections?.hasOnlyTransactions ?? false),
          child: child!,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _buildMenuButton(context),
              Expanded(child: _buildCenterContent(context)),
              _buildCardSlot(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return ScaleTransition(
      scale: widget.scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        ),
        child: IconButton(
          onPressed: () {
            final scaffoldState =
                context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
            scaffoldState?.openDrawer();
          },
          icon: const Icon(Icons.grid_view_rounded,
              color: AppColors.white, size: AppSizes.buttonSize),
        ),
      ),
    );
  }

  /// Sağ yuva: hesabın bağlı kartı varsa KART DÜĞMESİ (bkz.
  /// [CardSwitcherButton]); yoksa menü düğmesiyle eş genişlikte boşluk —
  /// başlık her durumda ortada kalır.
  ///
  /// Göz düğmesi eskiden buradaydı; tutarın yanına taşındı (bkz.
  /// `WalletHeadline`). Kart bağlamı yalnız İşlemler'de anlamlıdır: Birikim
  /// ve Borç her zaman HESABIN verisini gösterir, orada düğme yoktur.
  Widget _buildCardSlot(BuildContext context) {
    const empty = SizedBox(width: _sideSlot, height: _sideSlot);
    if (!FeatureFlags.creditCards ||
        widget.currentState != SliderState.transactions) {
      return empty;
    }
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final loaded = state is WalletLoadedSt ? state : _cachedLoadedState;
        final active = loaded?.activeWallet;
        if (loaded == null || active == null) return empty;
        final owner = accountOf(active, loaded.wallets);
        final cards = cardsOf(owner.id, loaded.wallets);
        if (cards.isEmpty) return empty;
        return OnboardingTour(
          flow: OnboardingFlow.cardRail,
          keys: [OnboardingKeys.cardRail],
          child: Showcase(
            key: OnboardingKeys.cardRail,
            title: context.l10n.onboardingCardRailTitle,
            description: context.l10n.onboardingCardRailDesc,
            child: ScaleTransition(
              scale: widget.scaleAnimation,
              child: CardSwitcherButton(
                owner: owner,
                cards: cards,
                active: active,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Yan yuvaların kenarı (menü düğmesi = 48).
  static const double _sideSlot = 48;

  Widget _buildCenterContent(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state is WalletLoadedSt) {
          _cachedLoadedState = state;
        } else if (state is NoWalletSt) {
          _cachedLoadedState = null;
        }

        final effectiveState =
            state is WalletLoadedSt ? state : _cachedLoadedState;

        return FadeTransition(
          opacity: widget.fadeAnimation,
          child: effectiveState != null
              ? _buildWalletContent(
                  context, effectiveState, widget.currentState)
              : _buildContentByState(context, state),
        );
      },
    );
  }

  Widget _buildContentByState(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      return _buildWalletContent(context, state, widget.currentState);
    } else if (state is WalletLoadingSt) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.white,
            strokeWidth: 2,
          ),
        ),
      );
    } else {
      return Center(
        child: Text(
          // Cüzdan yokken ekranda karşılama var; çubuk yalnız uygulamanın
          // adını taşır. Eskiden "Cüzdan Oluştur" yazıyordu: dokunulamayan
          // bir başlık, karşılamadaki "Başla" ile yarışan ikinci bir komut
          // gibi okunuyordu.
          state is NoWalletSt ? kAppName : context.l10n.selectWallet,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
  }

  /// Başlık alanı: üst düzey cüzdanlar arasında YANA KAYDIRILAN bir karusel.
  ///
  /// Eskiden ekranda yalnız etkin cüzdan vardı; ötekileri görmek için sayfa
  /// açmak, listede aşağı inmek, dokunmak ve sayfayı kapatmak gerekiyordu.
  /// Şimdi başlık parmakla kaydırılır: her sayfa bir cüzdanın başlığıdır,
  /// bırakılınca o cüzdan etkinleşir. Dokunmak yine cüzdan sayfasını açar.
  ///
  /// Sayfalar üst düzey cüzdanlardır ([topLevelWallets]); kart bağlamı
  /// SAHİBİNİN sayfasında yaşar ve bugünkü "HESAP › KART" başlığını gösterir.
  Widget _buildWalletContent(
      BuildContext context, WalletLoadedSt state, SliderState st) {
    final active = state.activeWallet;
    // Etkin cüzdan yokken (geçici durum) gösterilecek bir sayfa da yok:
    // karuselsiz, genel başlık.
    final tops = active == null
        ? const <WalletEntity>[]
        : topLevelWallets(state.wallets);
    final accountId =
        active == null ? null : accountOf(active, state.wallets).id;
    final activeIndex = tops.indexWhere((w) => w.id == accountId);

    final Widget content;
    if (activeIndex < 0) {
      content = _headlineFor(context, state: state, st: st, active: active);
    } else {
      final controller = _pages ??= PageController(initialPage: activeIndex);
      _syncPage(activeIndex, accountId);
      _maybeHint(tops.length);
      content = SizedBox(
        // `AppBar` başlığı sınırsız yükseklikte ölçer; yatay görünüm alanı
        // sınırlı bir yükseklik ister.
        height: AppSizes.appBarHeight,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) _onPageSettled(state, tops);
            return false;
          },
          child: PageView.builder(
            key: const ValueKey('wallet-carousel'),
            controller: controller,
            physics:
                tops.length < 2 ? const NeverScrollableScrollPhysics() : null,
            itemCount: tops.length,
            itemBuilder: (context, i) => _headlineFor(
              context,
              state: state,
              st: st,
              // Etkin bağlam bu sayfanın hesabındaysa (hesabın kendisi ya da
              // bağlı kartı) sayfa ONU gösterir; diğer sayfalar kendi
              // cüzdanını, etkin olsaydı görüneceği gibi.
              active: i == activeIndex ? active : tops[i],
              pageIndex: i,
              pageCount: tops.length,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        final scaffoldState =
            context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
        final authState = context.read<AppAuthBloc>().state;
        final userId = authState is AppAuthenticated
            ? authState.user.uid
            : (authState is AppAuthLocked ? authState.user.uid : 'local_user');

        scaffoldState?.openWalletDialog(
          WalletSheetContent(
            scrollController: _walletSheetScrollController,
            userId: userId,
          ),
        );
      },
      child: Container(color: AppColors.transparent, child: content),
    );
  }

  /// Karusel bir sayfada durdu: o sayfanın cüzdanı etkin değilse etkinleştir.
  /// Sessizdir (`announce: false`) — başlığın kendisi zaten değişti.
  void _onPageSettled(WalletLoadedSt state, List<WalletEntity> tops) {
    final controller = _pages;
    if (controller == null || !controller.hasClients || tops.isEmpty) return;
    final index = (controller.page ?? 0).round().clamp(0, tops.length - 1);
    final target = tops[index];
    final active = state.activeWallet;
    final currentId =
        active == null ? null : accountOf(active, state.wallets).id;
    if (target.id == null || target.id == currentId) return;
    if (target.id == _pendingAccountId) return;

    _dismissHint();
    _pendingAccountId = target.id;
    _pendingTimer?.cancel();
    _pendingTimer = Timer(_confirmWindow, () {
      if (mounted) setState(() => _pendingAccountId = null);
    });
    context.read<WalletBloc>().add(SetActiveWalletEvent(
          userId: target.userId,
          walletId: target.id!,
          announce: false,
        ));
  }

  /// Karuseli etkin hesabın sayfasında tutar: cüzdan başka bir yerden
  /// değiştiğinde (cüzdan sayfası, kart şeridi, silme) başlık da oraya gider.
  ///
  /// Kullanıcının bıraktığı an ile bloc'un yeni durumu yaydığı an arasında
  /// etkin hesap HÂLÂ eskisidir; o aralıkta eşitlemek sayfayı geri sektirirdi.
  /// Bekleyen seçim onaylanana (ya da süresi dolana) kadar eşitleme durur.
  void _syncPage(int activeIndex, String? accountId) {
    if (_pendingAccountId != null) {
      if (_pendingAccountId != accountId) return;
      _pendingAccountId = null;
      _pendingTimer?.cancel();
    }
    final controller = _pages;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      if (controller.position.isScrollingNotifier.value) return;
      if (controller.page?.round() != activeIndex) {
        controller.jumpToPage(activeIndex);
      }
    });
  }

  /// Kullanıcı başlığı KENDİ kaydırdı: ipucunun öğreteceği şeyi zaten
  /// biliyor. Kabuk turu sürerken ipucu bekletildiği için, turdan sonraki
  /// ilk kaydırmanın ARDINDAN oynuyor ve yeni oturmuş başlığı yerinden
  /// oynatıyordu (cihazda görüldü).
  void _dismissHint() {
    _hintTimer?.cancel();
    if (_hintSettled && _hintTimer == null) return;
    _hintSettled = true;
    _hintTimer = null;
    if (getIt.isRegistered<SharedPreferences>()) {
      unawaited(WalletCarouselHintStore(getIt<SharedPreferences>()).markSeen());
    }
  }

  /// Tek seferlik ipucu: ikinci cüzdan kurulduğunda başlık komşu cüzdana
  /// doğru bir kez kıpırdar (bkz. [WalletCarouselHintStore]). Kabuk turu
  /// sürerken oynamaz — overlay'in arkasında harcanırdı.
  void _maybeHint(int count) {
    if (_hintSettled || count < 2) return;
    if (!getIt.isRegistered<SharedPreferences>() ||
        !getIt.isRegistered<OnboardingCoordinator>()) {
      return;
    }
    final store = WalletCarouselHintStore(getIt<SharedPreferences>());
    if (store.seen) {
      _hintSettled = true;
      return;
    }
    if (!isSliderPeekAllowed(getIt<OnboardingCoordinator>())) return;
    _hintSettled = true;
    _hintTimer = Timer(const Duration(milliseconds: 1400), () async {
      final controller = _pages;
      if (!mounted || controller == null || !controller.hasClients) return;
      final position = controller.position;
      if (position.isScrollingNotifier.value) return;
      final home = position.pixels;
      // Komşu hangi yandaysa oraya doğru.
      final nudge = home < position.maxScrollExtent ? 36.0 : -36.0;
      await store.markSeen();
      await controller.animateTo(
        home + nudge,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      if (!mounted || !controller.hasClients) return;
      if (controller.position.isScrollingNotifier.value) return;
      await controller.animateTo(
        home,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    });
  }

  /// [active] bağlamının başlığı — rozet, tutar ve ikincil satır.
  Widget _headlineFor(
    BuildContext context, {
    required WalletLoadedSt state,
    required SliderState st,
    required WalletEntity? active,
    int pageIndex = 0,
    int pageCount = 1,
  }) {
    double value = 0.0;
    String valueName = "";
    // Bağlam bağlı bir KARTSA birikim/borç sahibinin verisidir (bkz.
    // `card_family.dart`); rozet de kartı sahibinin içinde gösterir.
    final account = active == null ? null : accountOf(active, state.wallets);
    final shown = st == SliderState.transactions ? active : account;

    if (active != null && account != null) {
      switch (st) {
        case SliderState.savedMoney:
          value = account.investment;
          valueName = context.l10n.drawerInvestment;
        case SliderState.transactions:
          // Kart bağlamında eksi bakiye değil BORÇ dili: "3.700 ₺" borç
          // (eksi işaretli büyük rakam "−3.700" bakiye gibi okunuyordu).
          value = active.isCreditCard && active.id != account.id
              ? -active.balance
              : active.balance;
          valueName = context.l10n.drawerBalance;
        case SliderState.debt:
          // Kredi/kişisel borç + bağlı kartların borcu (bkz. [debtOverview]).
          // Eskiden yalnız modül sayılıyordu: kart borcu olan kullanıcı
          // Borç sekmesinde "0,00 ₺" görüyordu.
          value = debtOverview(account, state.wallets).total;
          valueName = context.l10n.drawerDebt;
      }
    }

    // Ad, kullanıcının yazdığı gibi gösterilir. Rozet eskiden BÜYÜK HARFE
    // çeviriyordu ("BANKA KARTM"): uygulamanın geri kalanı cümle düzenine
    // geçince bağıran tek yer burası kalmıştı.
    final walletName = shown == null
        ? context.l10n.wallet
        : shown.id != account?.id
            ? '${account!.name} › ${shown.name}'
            : shown.name;

    return _headline(
      context,
      state: state,
      st: st,
      shown: shown,
      account: account,
      badge: st == SliderState.transactions
          ? (shown != null && shown.id != account?.id
              ? '$walletName • ${context.l10n.drawerDebt}'
              : walletName)
          : "$walletName • $valueName",
      value: value,
      pageIndex: pageIndex,
      pageCount: pageCount,
    );
  }

  /// Başlık + ikincil satır. İkincil satırın önceliği:
  /// 1. kart bağlamı → "Kullanılabilir limit …" (limit biliniyorsa);
  /// 2. kartı olan hesap → "Kart ödemeleri düşülünce: …" (kalan dönem
  ///    borçları; yalnız ödenecek bir şey varsa — defter okunur, canlı);
  /// 3. döviz cüzdanı → TL karşılığı.
  Widget _headline(
    BuildContext context, {
    required WalletLoadedSt state,
    required SliderState st,
    required WalletEntity? shown,
    required WalletEntity? account,
    required String badge,
    required double value,
    int pageIndex = 0,
    int pageCount = 1,
  }) {
    Widget build(String? line) => WalletHeadline(
          badgeLabel: badge,
          amount: value,
          currency: shown?.currency ?? context.activeWalletCurrency,
          badgeIcon: (shown?.isCreditCard ?? false)
              ? Icons.credit_card_rounded
              : Icons.wallet,
          secondaryLine: line,
          pageIndex: pageIndex,
          pageCount: pageCount,
        );
    // İkincil satır da TUTAR yazar: göz düğmesi başlığı gizlerken hemen
    // altındaki "Kullanılabilir limit: 33.500 ₺" açıkta kalıyordu (cihaz
    // turu, 12 Eki 2026).
    final visible = context.amountsVisible;
    String money(double v, String currency) =>
        MoneyWriter(currency: currency, visible: visible)(v);
    final fxLine = _tryEquivalentLine(context, shown, st, value, visible);
    // Borç sekmesinde toplamın kaynağı: "krediler X · kartlar Y". Yalnız
    // kart borcu varken; yoksa toplam zaten tek kaynaktır.
    if (st == SliderState.debt && account != null) {
      final o = debtOverview(account, state.wallets);
      if (moneyIsPositive(o.cards)) {
        return build(context.l10n.debtBreakdownLine(
          money(o.loans, account.currency),
          money(o.cards, account.currency),
        ));
      }
    }
    if (!FeatureFlags.creditCards ||
        st != SliderState.transactions ||
        shown == null) {
      return build(fxLine);
    }
    if (shown.id != account?.id) {
      final limit = shown.creditCard?.limit;
      return build(limit == null
          ? fxLine
          : context.l10n.kkKullanilabilirLimitSatiri(
              money(limit + shown.balance, shown.currency)));
    }
    final cards = cardsOf(shown.id, state.wallets)
        .where((c) => c.currency == shown.currency)
        .toList();
    if (cards.isEmpty) return build(fxLine);
    return CardsStatusBuilder(
      cards: cards,
      builder: (context, statuses, _) {
        final due = totalRemainingStatementDebt(statuses.values);
        return build(due > 0
            ? context.l10n
                .kkKartlarDusulunce(money(shown.balance - due, shown.currency))
            : fxLine);
      },
    );
  }

  /// Döviz cüzdanında bakiyenin son bilinen kurla TL karşılığı; kur yoksa
  /// satır gizlenir.
  String? _tryEquivalentLine(BuildContext context, WalletEntity? wallet,
      SliderState st, double value, bool visible) {
    if (st != SliderState.transactions) return null;
    if (wallet == null || wallet.currency == kDefaultCurrency) return null;
    if (getIt<ExchangeRateService>().cachedRateToTry(wallet.currency)
        case final double rate) {
      return context.l10n.yaklasikKarsilikFormat(MoneyWriter(
          currency: kDefaultCurrency, visible: visible)(value * rate));
    }
    return null;
  }
}
