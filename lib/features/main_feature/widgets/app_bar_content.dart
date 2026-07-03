import 'package:cunehat/config/di/injection.dart';
import 'package:cunehat/core/services/exchange_rate_service.dart';
import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/extensions/context_extensions.dart';
import 'package:cunehat/core/utils/currencies.dart';
import 'package:cunehat/core/utils/money_format.dart';
import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/wallet_currency_context.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:cunehat/core/blocs/app_auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';
import 'package:unified_flutter_features/features/amount_visibility/ibo_amount_display.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/helpers/slider_state_helper.dart';
import 'package:unified_flutter_features/features/slider_2d_navigation/models/slider_models.dart';

class AppBarContent extends StatefulWidget {
  final double currentSliderValue;
  final Animation<double> scaleAnimation;
  final Animation<double> fadeAnimation;

  const AppBarContent({
    super.key,
    required this.currentSliderValue,
    required this.scaleAnimation,
    required this.fadeAnimation,
  });

  @override
  State<AppBarContent> createState() => _AppBarContentState();
}

class _AppBarContentState extends State<AppBarContent> {
  WalletLoadedSt? _cachedLoadedState;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          _buildMenuButton(context),
          Expanded(child: _buildCenterContent(context)),
          _buildVisibilityButton(),
        ],
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
                  context,
                  effectiveState,
                  widget.currentSliderValue,
                )
              : _buildContentByState(context, state),
        );
      },
    );
  }

  Widget _buildContentByState(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      return _buildWalletContent(context, state, widget.currentSliderValue);
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
      BuildContext context, WalletLoadedSt state, double sliderValue) {
    double value = 0.0;
    String valueName = "";
    SliderState st = SliderState.transactions;

    if (state.activeWallet != null) {
      // Same source of truth as the navbar/controller (0.25/0.75 boundaries).
      st = SliderStateHelper.getStateFromValue(
        sliderValue,
        SliderState.values.length,
      );
      switch (st) {
        case SliderState.savedMoney:
          value = state.activeWallet?.investment ?? 0.0;
          valueName = context.l10n.drawerInvestment.toUpperCase();
        case SliderState.transactions:
          value = state.activeWallet?.balance ?? 0.0;
          valueName = context.l10n.drawerBalance.toUpperCase();
        case SliderState.debt:
          value = state.activeWallet?.debt ?? 0.0;
          valueName = context.l10n.drawerDebt.toUpperCase();
      }
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
            scrollController: ScrollController(),
            userId: userId,
          ),
        );
      },
      child: Container(
        color: AppColors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWalletNameBadge(context, state.activeWallet, valueName, st),
            const SizedBox(height: 2),
            _buildAmountDisplay(value),
            // Döviz cüzdanında bakiyenin son bilinen kurla TL karşılığı;
            // kur yoksa satır gizlenir.
            if (st == SliderState.transactions &&
                state.activeWallet != null &&
                state.activeWallet!.currency != kDefaultCurrency)
              if (getIt<ExchangeRateService>()
                      .cachedRateToTry(state.activeWallet!.currency)
                  case final double rate)
                Text(
                  context.l10n
                      .yaklasikKarsilikFormat(formatMoney(value * rate)),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletNameBadge(
      BuildContext context, activeWallet, String valueName, SliderState st) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wallet,
              size: 14, color: AppColors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              st == SliderState.transactions
                  ? (activeWallet?.name.toUpperCase() ??
                      context.l10n.wallet.toUpperCase())
                  : "${activeWallet?.name.toUpperCase() ?? context.l10n.wallet.toUpperCase()} • $valueName",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(double value) {
    return BlocBuilder<AmountVisibilityCubit, bool>(
      builder: (context, isVisible) {
        return AmountDisplay(
          amount: value,
          currencySymbol: context.activeWalletCurrencySymbol,
          animationCurve: Curves.decelerate,
          obscureMode: AmountObscureMode.blur,
          alignment: Alignment.center,
          style: const TextStyle(
            fontSize: 34,
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            shadows: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
        );
      },
    );
  }
}
