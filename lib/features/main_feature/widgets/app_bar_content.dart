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
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
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

    if (state.activeWallet != null) {
      switch (st) {
        case SliderState.savedMoney:
          value = state.activeWallet?.investment ?? 0.0;
          valueName = upperTr(context.l10n.drawerInvestment);
        case SliderState.transactions:
          value = state.activeWallet?.balance ?? 0.0;
          valueName = upperTr(context.l10n.drawerBalance);
        case SliderState.debt:
          value = state.activeWallet?.debt ?? 0.0;
          valueName = upperTr(context.l10n.drawerDebt);
      }
    }

    final walletName = upperTr(state.activeWallet?.name ?? context.l10n.wallet);

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
          child: WalletHeadline(
            badgeLabel: st == SliderState.transactions
                ? walletName
                : "$walletName • $valueName",
            amount: value,
            currency: context.activeWalletCurrency,
            secondaryLine: _tryEquivalentLine(context, state, st, value),
          ),
        ),
      ),
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
