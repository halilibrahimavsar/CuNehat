import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/shared/animations/cube_animation_view.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/debt_and_receivable/presentation/pages/debt_and_receivable_page.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_page.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_money_page.dart';
import 'package:cunehat/features/main_feature/pages/modern_appbar.dart';
import 'package:cunehat/features/main_feature/widgets/modern_drawer.dart';
import 'package:cunehat/features/main_feature/widgets/slider_button_view.dart';

import 'package:cunehat/features/wallet/presentation/bloc/wallet_bloc.dart';
import 'package:cunehat/features/wallet/presentation/widgets/no_wallet_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadWallets();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: 0.5, // Start at Compare view
    );
  }

  void _loadWallets() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Load wallets (will trigger transaction loading in listener)
    context.read<WalletBloc>().add(GetWalletsEvent(userId));
  }

  @override
  void dispose() {
    _controller.dispose();
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
          preferredSize: const Size(double.maxFinite, 50),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ModernAppbar(currentSliderValue: _controller.value);
            },
          ),
        ),
        child: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, walletState) {
            switch (walletState) {
              case WalletOperationSuccesSt():
                SnackbarHelper.showSuccess(context, walletState.message);
                _loadWallets();
                break;
              case WalletErrorSt():
                SnackbarHelper.showError(context, walletState.err);
                break;
              default:
                break;
            }
          },
          builder: (context, walletState) {
            switch (walletState) {
              case WalletLoadingSt():
                return const Center(child: CircularProgressIndicator());

              case WalletErrorSt():
                return ErrorView(
                  message: walletState.err,
                  onPressed: _loadWallets,
                  buttonText: "Tekrar Dene",
                  customIcon: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[400],
                  ),
                );

              case WalletLoadedSt():
                final userId = walletState.wallets.first.userId;

                switch (walletState.activeWallet?.isActive) {
                  case false:
                    return const NoWalletView(infoText: "Cüzdan seçiniz");
                  case null:
                    return const NoWalletView(infoText: "Cüzdan oluşturunuz");
                  case true:
                    return _buildBody(walletState, userId, context);
                }

              default:
                return const NoWalletView(infoText: "Cüzdan oluşturunuz");
            }
          },
        ),
      ),
    );
  }

  Column _buildBody(
      WalletLoadedSt walletState, String userId, BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CubeAnimationView(
            controller: _controller,
            firstView: InvestmentMoneyPage(
              activeWallet: walletState.activeWallet!,
            ),
            secondView: TransactionsPage(
              userId: userId,
              wallet: walletState.activeWallet!,
            ),
            thridView: DebtAndReceivablePage(
              userId: userId,
              walletId: walletState.activeWallet!.id!,
            ),
          ),
        ),
        SliderButtonView(
          controller: _controller,
          context: context,
          userId: userId,
          walletState: walletState,
        ),
      ],
    );
  }
}
