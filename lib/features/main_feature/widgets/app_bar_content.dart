import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/onboarding/onboarding_tour.dart';
import 'package:cunehat/core/onboarding/onboarding_flow.dart';
import 'package:cunehat/core/onboarding/onboarding_keys.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/core/utils/tr_case.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/main_feature/widgets/wallet_headline.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:cunehat/core/config/feature_flags.dart';
import 'package:cunehat/features/credit_card/presentation/card_status.dart';
import 'package:cunehat/features/wallet/domain/card_family.dart';
import 'package:cunehat/features/wallet/domain/entities/wallet_entity.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:cunehat/core/utils/money_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/amount_visibility/ibo_amount_display.dart';
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

  /// Kabuk turunun adımları, sırasıyla: aktif cüzdan (uygulamanın en önemli
  /// kavramı) → menü → ekle/navigasyon kartı. Sonuncusu HomePage'te tanımlıdır
  /// ve turu bir eyleme çağırarak kapatır.
  static final List<GlobalKey> _tourKeys = [
    OnboardingKeys.appBarWalletArea,
    OnboardingKeys.appBarMenuButton,
    OnboardingKeys.addActionSlider,
  ];

  /// Tur ancak en az bir cüzdan varken istenir.
  static bool _hasWallet(WalletState state) =>
      state is WalletLoadedSt && state.wallets.isNotEmpty;

  /// Cüzdan alt-sayfasına verilen kaydırma denetleyicisi. State'e ait: her
  /// dokunuşta `ScrollController()` üretmek dispose edilmeyen denetleyici
  /// bırakıyordu.
  final ScrollController _walletSheetScrollController = ScrollController();

  @override
  void dispose() {
    _walletSheetScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Kabuk turu ilk cüzdan oluştuktan SONRA oynar: ekranda "İlk Cüzdanı
    // Oluştur"dan başka bir şey yokken "işte aktif cüzdanın" demenin anlamı
    // yok. `enabled` false→true olunca OnboardingTour kendini yeniden
    // silahlandırır; ek bir tetikleyiciye gerek yok.
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (prev, curr) => _hasWallet(prev) != _hasWallet(curr),
      builder: (context, walletState) => OnboardingTour(
        flow: OnboardingFlow.shell,
        keys: _tourKeys,
        enabled: _hasWallet(walletState),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              _buildMenuButton(context),
              Expanded(child: _buildCenterContent(context)),
              _buildVisibilityButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Showcase(
      key: OnboardingKeys.appBarMenuButton,
      title: context.l10n.onboardingAppBarMenuTitle,
      description: context.l10n.onboardingAppBarMenuDesc,
      child: ScaleTransition(
        scale: widget.scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppBorderRadius.medium),
          ),
          child: IconButton(
            onPressed: () {
              final scaffoldState = context
                  .findAncestorStateOfType<AnimatedScaffoldWrapperState>();
              scaffoldState?.openDrawer();
            },
            icon: const Icon(Icons.grid_view_rounded,
                color: AppColors.white, size: AppSizes.buttonSize),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilityButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppDurations.extraLong,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const AmountVisibilityButton(),
          ),
        );
      },
    );
  }

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
          state is NoWalletSt
              ? context.l10n.createWallet
              : context.l10n.selectWallet,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }
  }

  Widget _buildWalletContent(
      BuildContext context, WalletLoadedSt state, SliderState st) {
    double value = 0.0;
    String valueName = "";
    final active = state.activeWallet;
    // Aktif cüzdan bağlı bir KARTSA birikim/borç sahibinin verisidir (bkz.
    // `card_family.dart`); rozet de kartı sahibinin içinde gösterir.
    final account = active == null ? null : accountOf(active, state.wallets);
    final shown = st == SliderState.transactions ? active : account;

    if (active != null && account != null) {
      switch (st) {
        case SliderState.savedMoney:
          value = account.investment;
          valueName = upperTr(context.l10n.drawerInvestment);
        case SliderState.transactions:
          // Kart bağlamında eksi bakiye değil BORÇ dili: "3.700 ₺" borç
          // (eksi işaretli büyük rakam "−3.700" bakiye gibi okunuyordu).
          value = active.isCreditCard && active.id != account.id
              ? -active.balance
              : active.balance;
          valueName = upperTr(context.l10n.drawerBalance);
        case SliderState.debt:
          // Kredi/kişisel borç + bağlı kartların borcu (bkz. [debtOverview]).
          // Eskiden yalnız modül sayılıyordu: kart borcu olan kullanıcı
          // Borç sekmesinde "0,00 ₺" görüyordu.
          value = debtOverview(account, state.wallets).total;
          valueName = upperTr(context.l10n.drawerDebt);
      }
    }

    final walletName = shown == null
        ? upperTr(context.l10n.wallet)
        : shown.id != account?.id
            ? '${upperTr(account!.name)} › ${upperTr(shown.name)}'
            : upperTr(shown.name);

    return Showcase(
      key: OnboardingKeys.appBarWalletArea,
      title: context.l10n.onboardingAppBarWalletTitle,
      description: context.l10n.onboardingAppBarWalletDesc,
      child: GestureDetector(
        onTap: () {
          final scaffoldState =
              context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
          final authState = context.read<AppAuthBloc>().state;
          final userId = authState is AppAuthenticated
              ? authState.user.uid
              : (authState is AppAuthLocked
                  ? authState.user.uid
                  : 'local_user');

          scaffoldState?.openWalletDialog(
            WalletSheetContent(
              scrollController: _walletSheetScrollController,
              userId: userId,
            ),
          );
        },
        child: Container(
          color: AppColors.transparent,
          child: _headline(
            context,
            state: state,
            st: st,
            shown: shown,
            account: account,
            badge: st == SliderState.transactions
                ? (shown != null && shown.id != account?.id
                    ? '$walletName • ${upperTr(context.l10n.drawerDebt)}'
                    : walletName)
                : "$walletName • $valueName",
            value: value,
          ),
        ),
      ),
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
  }) {
    Widget build(String? line) => WalletHeadline(
          badgeLabel: badge,
          amount: value,
          currency: shown?.currency ?? context.activeWalletCurrency,
          badgeIcon: (shown?.isCreditCard ?? false)
              ? Icons.credit_card_rounded
              : Icons.wallet,
          secondaryLine: line,
        );
    final fxLine = _tryEquivalentLine(context, state, st, value);
    // Borç sekmesinde toplamın kaynağı: "krediler X · kartlar Y". Yalnız
    // kart borcu varken; yoksa toplam zaten tek kaynaktır.
    if (st == SliderState.debt && account != null) {
      final o = debtOverview(account, state.wallets);
      if (moneyIsPositive(o.cards)) {
        return build(context.l10n.debtBreakdownLine(
          formatMoney(o.loans, currency: account.currency),
          formatMoney(o.cards, currency: account.currency),
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
              formatMoney(limit + shown.balance, currency: shown.currency)));
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
            ? context.l10n.kkKartlarDusulunce(
                formatMoney(shown.balance - due, currency: shown.currency))
            : fxLine);
      },
    );
  }

  /// Döviz cüzdanında bakiyenin son bilinen kurla TL karşılığı; kur yoksa
  /// satır gizlenir.
  String? _tryEquivalentLine(BuildContext context, WalletLoadedSt state,
      SliderState st, double value) {
    if (st != SliderState.transactions) return null;
    final wallet = state.activeWallet;
    if (wallet == null || wallet.currency == kDefaultCurrency) return null;
    if (getIt<ExchangeRateService>().cachedRateToTry(wallet.currency)
        case final double rate) {
      return context.l10n.yaklasikKarsilikFormat(formatMoney(value * rate));
    }
    return null;
  }
}
