import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';

import 'package:cunehat/features/main_feature/utils/app_constants.dart';
import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/page/wallet_managment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/amount_visibility/amount_visibility_cubit.dart';
import 'package:unified_flutter_features/features/amount_visibility/ibo_amount_display.dart';

class AppBarContent extends StatelessWidget {
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
      scale: scaleAnimation,
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
        return FadeTransition(
          opacity: fadeAnimation,
          child: _buildContentByState(context, state),
        );
      },
    );
  }

  Widget _buildContentByState(BuildContext context, WalletState state) {
    if (state is WalletLoadedSt) {
      return _buildWalletContent(context, state, currentSliderValue);
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
          state is NoWalletSt ? "Cüzdan Oluştur" : "Cüzdan Seçin",
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

    if (state.activeWallet != null) {
      if (sliderValue < 0.3) {
        value = state.activeWallet?.investment ?? 0.0;
        valueName = "YATIRIM";
      } else if (sliderValue > 0.7) {
        value = state.activeWallet?.debt ?? 0.0;
        valueName = "BORÇ";
      } else {
        value = state.activeWallet?.balance ?? 0.0;
        valueName = "BAKİYE";
      }
    }

    return GestureDetector(
      onTap: () {
        final scaffoldState =
            context.findAncestorStateOfType<AnimatedScaffoldWrapperState>();
        scaffoldState?.openWalletDialog(
          WalletSheetContent(
            scrollController: ScrollController(),
            userId: FirebaseAuth.instance.currentUser!.uid,
          ),
        );
      },
      child: Container(
        color: AppColors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWalletNameBadge(state.activeWallet, valueName),
            const SizedBox(height: 8),
            _buildAmountDisplay(value),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletNameBadge(activeWallet, String valueName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
        border:
            Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wallet,
              size: 12, color: AppColors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              valueName == "BAKİYE"
                  ? (activeWallet?.name.toUpperCase() ?? "CÜZDAN")
                  : "${activeWallet?.name.toUpperCase() ?? 'CÜZDAN'} • $valueName",
              style: TextStyle(
                fontSize: 11,
                color: AppColors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
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
          animationCurve: Curves.decelerate,
          obscureMode: AmountObscureMode.blur,
          alignment: Alignment.center,
          style: const TextStyle(
            fontSize: 24,
            color: AppColors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            shadows: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        );
      },
    );
  }
}
