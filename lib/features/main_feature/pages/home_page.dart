import 'package:cunehat/core/shared/animations/animated_scaffold_wrapper.dart';
import 'package:cunehat/core/utilities/snackbar_helper.dart';
import 'package:cunehat/features/finance_transactions/presentation/pages/transaction_page.dart';
import 'package:cunehat/core/shared/widgets/error_view.dart';
import 'package:cunehat/core/shared/animations/cube_animation_view.dart';
import 'package:cunehat/core/shared/widgets/build_drawer.dart';
import 'package:cunehat/core/shared/widgets/shared_appbar.dart';
import 'package:cunehat/features/finance_transactions/presentation/widgets/transaction_entry_widgets/transaction_entry_sheet.dart';
import 'package:cunehat/features/investments/presentation/bloc/investment_bloc.dart';
import 'package:cunehat/features/investments/presentation/pages/investment_money_page.dart';
import 'package:cunehat/features/investments/presentation/widgets/add_investment_dialog.dart';
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
        drawer: const ModernSharedDrawer(),
        appBar: PreferredSize(
          preferredSize: const Size(double.maxFinite, 50),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ModernSharedAppbar(currentSliderValue: _controller.value);
            },
          ),
        ),
        child: BlocConsumer<WalletBloc, WalletState>(
          listener: (context, walletState) {
            switch (walletState) {
              case WalletDeletedSt():
                SnackbarHelper.showSuccess(context, 'Cüzdan silindi!');
                _loadWallets();
                break;
              case WalletCreatedSt():
                SnackbarHelper.showSuccess(context, 'Cüzdan oluşturuldu!');
                _loadWallets();
                break;
              case WalletUpdatedSt():
                SnackbarHelper.showSuccess(context, 'Cüzdan güncellendi!');
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
                    return Column(
                      children: [
                        Expanded(
                          child: CubeAnimationView(
                            controller: _controller,
                            firstView: InvestmentMoneyPage(
                              key: const ValueKey('save-view'), // ✅ Unique key
                              activeWallet: walletState.activeWallet!,
                              // investments: investmentState.investments, // Eğer sayfa destekliyorsa buraya ekleyebilirsiniz
                            ),
                            secondView: const Text(" 2. View "),
                            thirdView: TransactionsPage(
                              key: const ValueKey(
                                  'compare-view'), // ✅ Unique key
                              userId: userId,
                              wallet: walletState.activeWallet!,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SliderButtonEnhanced(
                            controller: _controller,
                            miniButtons: {
                              SliderState.savedMoney: [
                                MiniButtonData(
                                  icon: Icons.inventory_sharp,
                                  label: 'Birikim',
                                  color: Colors.red,
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AddInvestmentDialog(
                                        onAddInvestment: (investment) {
                                          context
                                              .read<InvestmentBloc>()
                                              .add(CreateInvestmentEvent(
                                                investment: investment,
                                                userId: userId,
                                                walletId: walletState
                                                    .activeWallet!.id!,
                                              ));
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                              SliderState.transactions: [
                                MiniButtonData(
                                  icon: Icons.remove,
                                  label: 'Gider',
                                  color: Colors.red,
                                  onTap: () {
                                    TransactionSheetHandler.showExpenseSheet(
                                      context,
                                      userId,
                                      walletState.activeWallet!.id!,
                                    );
                                  },
                                ),
                                MiniButtonData(
                                  icon: Icons.add,
                                  label: 'Gelir',
                                  color: Colors.green,
                                  onTap: () {
                                    TransactionSheetHandler.showIncomeSheet(
                                      context,
                                      userId,
                                      walletState.activeWallet!.id!,
                                    );
                                  },
                                ),
                              ],
                              SliderState.debt: [
                                MiniButtonData(
                                  icon: Icons.add,
                                  label: 'Gelir',
                                  color: Colors.green,
                                  onTap: () {},
                                ),
                                MiniButtonData(
                                  icon: Icons.abc,
                                  label: "gid",
                                  color: Colors.yellow,
                                  onTap: () {},
                                )
                              ],
                            },
                            onValueChanged: (action) {},
                            onTap: (value) {},
                          ),
                        ),
                      ],
                    );
                }

              default:
                return const NoWalletView(infoText: "Cüzdan oluşturunuz");
            }
          },
        ),
      ),
    );
  }
}
